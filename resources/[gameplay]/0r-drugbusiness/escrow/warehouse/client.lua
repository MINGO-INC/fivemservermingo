--[[ require ]]

local Utils = require 'modules.utils.client'
local Target = require 'modules.target.client'
local Weather = require 'modules.weather.client'

---@type table<BusinessTheme, ThemeInterior>
local ThemeInteriors = lib.load('data.theme_interiors')

--[[ state ]]

---@type WarehouseData[]
local warehousesData = lib.load('data.warehouses')

Warehouse = {
    soldKeys = {},
    ownedBlips = {},
    salesBlips = {},
    ---@type CPoint[]
    ownedPoints = {},
    ---@type CPoint[]
    salesPoints = {},
}

local labPanelTargetzone = nil

local isPlayerInPoint = false

--[[ helper functions ]]

local function deletePanelTarget()
    if labPanelTargetzone then
        Target.removeZone('drugbusiness_lab_panel')
        labPanelTargetzone = false
    end
end

local function removeSaleBlip(warehouseIndex)
    local saleBlip = Warehouse.salesBlips[warehouseIndex]
    if not saleBlip then return end
    if DoesBlipExist(saleBlip) then
        RemoveBlip(saleBlip)
    end
    Warehouse.salesBlips[warehouseIndex] = nil
end

local function removeOwnedBlip(warehouseIndex)
    local ownedBlip = Warehouse.ownedBlips[warehouseIndex]
    if not ownedBlip then return end
    if DoesBlipExist(ownedBlip) then
        RemoveBlip(ownedBlip)
    end
    Warehouse.ownedBlips[warehouseIndex] = nil
end

local function createSalesBlip(warehouseIndex)
    local value = warehousesData[warehouseIndex]
    local salesBlip = Config.Warehouse.salesBlip
    if value and not Warehouse.soldKeys[value.index] and salesBlip and salesBlip.active then
        salesBlip.text = ('%s: %s'):format(locale('for_sale'), value.label)
        local blip = Utils.addBlip(value.entranceCoords, salesBlip)
        Warehouse.salesBlips[value.index] = blip
    end
end

local function createSalesBlips()
    for key, value in pairs(warehousesData) do
        createSalesBlip(key)
    end
end

local function createOwnedWarehouseBlip(warehouseIndex, name)
    local warehouseData = warehousesData[warehouseIndex]
    if not warehouseData then return false end
    local ownedBlip = Config.Warehouse.ownedBlip

    if ownedBlip then
        ownedBlip.text = name
        local blip = Utils.addBlip(warehouseData.entranceCoords, ownedBlip)
        Warehouse.ownedBlips[warehouseIndex] = blip
        return blip
    end
    return false
end

local function createOwnedBlips()
    local ownedWarehouses = Profile.warehouses
    for _, value in pairs(ownedWarehouses) do
        local warehouseData = warehousesData[value.warehouse_index]
        if warehouseData then
            local ownedWarehouseBlip = createOwnedWarehouseBlip(value.warehouse_index, value.name)
            if ownedWarehouseBlip then
                local blipDisplay = 0
                if Config.Warehouse.ownedBlip.active then blipDisplay = 2 end
                if value.meta and value.meta.blip_hidden then blipDisplay = 0 end
                local blipColor = value.meta and value.meta.blip_color

                SetBlipDisplay(ownedWarehouseBlip, blipDisplay)
                if blipColor then
                    SetBlipColour(ownedWarehouseBlip, blipColor)
                end
            end
        end
    end
end

---@param warehouseData WarehouseData
---@param text string
---@param actionCallback function
---@param deleteAfterSale boolean
local function createWarehousePoint(warehouseData, text, actionCallback, forSale)
    local textUI = false

    local point = lib.points.new({
        coords = warehouseData.entranceCoords,
        warehouseIndex = warehouseData.index,
        distance = 10.0,
        nearby = function(self)
            DrawMarker(20, self.coords.x, self.coords.y, self.coords.z - .25, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                .5, .25, 0.5, 255, 255, 0, 255,
                false, true, 2, true, nil, nil, false)

            if self.currentDistance < 2.0 then
                if not textUI then
                    textUI = true
                    Utils.showTextUI('[E] ' .. text)
                end

                if IsControlJustPressed(0, 38) then
                    actionCallback(warehouseData)
                    Citizen.Wait(1000)
                end
            elseif textUI then
                textUI = false
                Utils.hideTextUI()
            end
        end,
        onEnter = function(self)
            isPlayerInPoint = self.warehouseIndex
        end,
        onExit = function()
            isPlayerInPoint = false
            if textUI then
                textUI = false
                Utils.hideTextUI()
            end
        end,
    })

    if not forSale then
        Warehouse.ownedPoints[warehouseData.index] = point
    else
        Warehouse.salesPoints[warehouseData.index] = point
    end
end

local function createSalesPoints()
    for _, warehouse in pairs(warehousesData) do
        if not Warehouse.soldKeys[warehouse.index] then
            createWarehousePoint(warehouse, locale('buy_warehouse'), Warehouse.openBuyMenu, true)
        end
    end
end

local function createOwnedPoints()
    local ownedWarehouses = Profile.warehouses
    for _, ownedWarehouse in pairs(ownedWarehouses) do
        local warehouse = warehousesData[ownedWarehouse.warehouse_index]
        if warehouse then
            createWarehousePoint(warehouse, locale('get_inside'), Warehouse.getInside)
        end
    end
end

local function setKeys()
    for key, value in pairs(warehousesData) do
        value.index = key
    end
end

--[[ functions ]]

function Warehouse.load()
    setKeys()
    Warehouse.soldKeys = lib.callback.await(_e('server:warehouse:GetSoldKeys'), false)
    createSalesBlips()
    createOwnedBlips()
    createSalesPoints()
    createOwnedPoints()

    Profile.hasInsideMeta()
end

function Warehouse.clear()
    deletePanelTarget()
    for _, value in pairs(Warehouse.salesPoints) do
        value:remove()
    end
    for _, value in pairs(Warehouse.ownedPoints) do
        value:remove()
    end
    for _, value in pairs(Warehouse.salesBlips) do
        if DoesBlipExist(value) then RemoveBlip(value) end
    end
    for _, value in pairs(Warehouse.ownedBlips) do
        if DoesBlipExist(value) then RemoveBlip(value) end
    end

    Warehouse.soldKeys = {}
    Warehouse.salesPoints = {}
    Warehouse.salesBlips = {}
    Warehouse.ownedPoints = {}
    Warehouse.ownedBlips = {}
    isPlayerInPoint = false
end

---@param data Warehouse
function Warehouse.openBuyMenu(data)
    client.sendReactMessage('ui:setBuyWarehouse', data)
    client.sendReactMessage('ui:setPage', 'buy-warehouse')
    client.sendReactMessage('ui:setVisible', true)
    SetNuiFocus(true, true)
end

function Warehouse.buyNew(warehouseIndex)
    local response = lib.callback.await(_e('server:warehouse:BuyNew'), false, warehouseIndex)
    if response.error then
        Utils.notify(response.error, 'error')
        return false
    end
    Utils.notify(locale('you_bought_warehouse'), 'success')
    return true
end

---@param data Warehouse
function Warehouse.getInside(data)
    if RawMaterials.isTaskStarted() then
        return Utils.notify(locale('raw_material_task_in_progress'), 'error')
    end
    if SaleMission.isTaskStarted() then
        return Utils.notify(locale('sale_mission_in_progress'), 'error')
    end
    local warehouseIndex = data.index

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(1) end

    local response = lib.callback.await(_e('server:warehouse:GetInsideByIndex'), false, warehouseIndex)

    if response.error then
        DoScreenFadeIn(500)
        return Utils.notify(response.error, 'error')
    end
end

---@param theme BusinessTheme
---@param meta Meta
function Warehouse.loadThemeEntities(theme, meta)
    local themeInterior = ThemeInteriors[theme]
    if not themeInterior then return end

    local newEntities = {}

    for _, entity in pairs(themeInterior.entities.hide or {}) do
        newEntities[entity] = false
    end

    if meta.interior_level then
        for _, entity in pairs(themeInterior.entities.upgrades[meta.interior_level] or {}) do
            newEntities[entity] = true
        end
    end

    if meta.security_system then
        for _, entity in pairs(themeInterior.entities.security or {}) do
            newEntities[entity] = true
        end
    end

    client.loadInteriorEntities(themeInterior.coords, newEntities)
end

---@param theme BusinessTheme
function Warehouse.createPanelTargetZone(theme)
    if labPanelTargetzone and labPanelTargetzone == theme then return end
    deletePanelTarget()
    local lab = Config.Labs[theme]
    if not lab then return end

    local zoneCenter = lab.coords.panel
    Target.addBoxZone('drugbusiness_lab_panel', {
        coords = zoneCenter,
        size = vector3(1.0, 1.0, 1.0),
        rotation = 0.0,
        debug = Config.debugZone,
        canInteract = function()
            return client.inWarehouse
        end,
        options = {
            [1] = {
                icon = 'fa-solid fa-desktop',
                label = locale('open_menu'),
                onSelect = Warehouse.openUI,
                distance = 1.5,
            },
        }
    })
    labPanelTargetzone = theme
end

function Warehouse.openUI()
    client.sendReactMessage('ui:setPage', 'business')
    client.sendReactMessage('ui:setVisible', true)
    SetNuiFocus(true, true)
end

function Warehouse.getOutside(warehouseIndex)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(1) end

    TriggerServerEvent(_e('server:warehouse:GetOutsideByIndex'), warehouseIndex)
end

function Warehouse.createOutsidePoint(theme, warehouseIndex)
    local lab = Config.Labs[theme]
    if not lab then return end

    local exitArea = lab.coords.exitArea

    lib.points.new({
        coords = exitArea,
        distance = 1.5,
        warehouseIndex = warehouseIndex,
        nearby = function(self)
            DrawMarker(20, self.coords.x, self.coords.y, self.coords.z - .25, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                .5, .25, 0.5, 255, 255, 0, 255,
                false, true, 2, true, nil, nil, false)

            if IsControlJustPressed(0, 38) then
                Warehouse.getOutside(self.warehouseIndex)
                self:remove()
                Utils.hideTextUI()
                return
            end

            if IsControlJustPressed(0, 74) and
                client.inWarehouse.meta?.money_washing_level > 0
            then
                MoneyWashing.getInside(self.warehouseIndex)
                self:remove()
                Utils.hideTextUI()
                return
            end
        end,
        onEnter = function()
            local text = '[E] ' .. locale('get_outside')
            if client.inWarehouse.meta?.money_washing_level > 0 then
                text = text .. ' • ' .. '[H] ' .. locale('money_washing')
            end
            Utils.showTextUI(text)
        end,
        onExit = function()
            Utils.hideTextUI()
        end
    })
end

function Warehouse.getDataByIndex(warehouseIndex)
    return warehousesData[warehouseIndex]
end

function Warehouse.getData()
    return warehousesData
end

function Warehouse.isManager(warehouseIndex)
    local ownedWarehouses = Profile.warehouses

    for key, value in pairs(ownedWarehouses) do
        if value.warehouse_index == warehouseIndex then
            return true
        end
    end
    return false
end

--[[ events ]]

RegisterNUICallback('nui:onCancelBuyWarehouse', function(_, resultCallback)
    client.hideUI()
    resultCallback(true)
end)

RegisterNUICallback('nui:buyNewWarehouse', function(warehouseIndex, resultCallback)
    client.hideUI()
    Warehouse.buyNew(warehouseIndex)
    resultCallback(true)
end)

RegisterNUICallback('nui:updateCurrentWarehouseBlipColor', function(newColor, resultCallback)
    lib.callback.await(_e('server:warehouse:UpdateBlipColor'), false, client.inWarehouse.warehouse_index, newColor)
    resultCallback(true)
end)

RegisterNUICallback('nui:updateCurrentWarehouseBlipHidden', function(_, resultCallback)
    lib.callback.await(_e('server:warehouse:ToggleBlipHidden'), false, client.inWarehouse.warehouse_index)
    resultCallback(true)
end)

RegisterNUICallback('nui:updateCurrentWarehouseName', function(newWarehouseName, resultCallback)
    lib.callback.await(_e('server:warehouse:UpdateName'), false, client.inWarehouse.warehouse_index, newWarehouseName)
    resultCallback(true)
end)

RegisterNUICallback('nui:inviteManagerToCurrentWarehouse', function(targetSourceId, resultCallback)
    targetSourceId = tonumber(targetSourceId)

    local response = lib.callback.await(_e('server:warehouse:InvitePlayerToWarehouse'), false,
        client.inWarehouse.warehouse_index, targetSourceId)

    if response.error then
        client.sendReactMessage('ui:setAlert', { text = response.error, type = 'error' })
    end

    resultCallback(true)
end)

RegisterNUICallback('nui:removeManagerFromCurrentWarehouse', function(targetManager, resultCallback)
    local response = lib.callback.await(_e('server:warehouse:RemovePlayerToWarehouse'), false,
        client.inWarehouse.warehouse_index, targetManager.identifier)

    if response.error then
        client.sendReactMessage('ui:setAlert', { text = response.error, type = 'error' })
    else
        client.sendReactMessage('ui:setAlert', { text = response.success, type = 'success' })
    end

    resultCallback(true)
end)

RegisterNUICallback('nui:changeWarehouseInteriorLightState', function(_, resultCallback)
    lib.callback.await(_e('server:warehouse:ChangeInteriorLightState'), false, client.inWarehouse.warehouse_index)
    resultCallback(true)
end)

RegisterNUICallback('nui:terminateWarehouse', function(_, resultCallback)
    local response = lib.callback.await(_e('server:warehouse:TerminateWarehouse'), false,
        client.inWarehouse.warehouse_index)

    if response.error then
        client.sendReactMessage('ui:setAlert', { text = response.error, type = 'error' })
        resultCallback(false)
    else
        client.hideUI()
        resultCallback(true)
    end
end)

---@param manager Manager
---@param resultCallback function
RegisterNUICallback('nui:transferWarehouseToManager', function(manager, resultCallback)
    local response = lib.callback.await(_e('server:warehouse:TransferOwnershipToManager'), false,
        client.inWarehouse.warehouse_index, manager)

    if response.error then
        client.sendReactMessage('ui:setAlert', { text = response.error, type = 'error' })
        resultCallback(false)
    else
        resultCallback(true)
    end
end)

---@param data {theme:BusinessTheme,level:integer}
---@param resultCallback function
RegisterNUICallback('nui:warehouse:getInteriorUpgradePrice', function(data, resultCallback)
    local theme = data.theme
    local level = data.level
    if Config.Labs[theme] and
        Config.Labs[theme].upgrades[level]
    then
        return resultCallback(Config.Labs[theme].upgrades[level].price)
    end
    resultCallback(false)
end)

RegisterNUICallback('nui:warehouse:upgradeInterior', function(_, resultCallback)
    local warehouseIndex = client.inWarehouse.warehouse_index

    local response = lib.callback.await(_e('server:warehouse:upgradeInterior'), false,
        client.inWarehouse.warehouse_index)

    if response.error then
        client.sendReactMessage('ui:setAlert', { text = response.error, type = 'error' })
    end

    resultCallback(true)
end)

RegisterNUICallback('nui:warehouse:toggleWorking', function(_, resultCallback)
    local warehouseIndex = client.inWarehouse.warehouse_index

    local response = lib.callback.await(_e('server:warehouse:toggleWorkingState'), false,
        client.inWarehouse.warehouse_index)

    if response.error then
        client.sendReactMessage('ui:setAlert', { text = response.error, type = 'error' })
    end

    resultCallback(true)
end)

---@param newTheme BusinessTheme
---@param resultCallback function
RegisterNUICallback('nui:updateCurrentWarehouseTheme', function(newTheme, resultCallback)
    local response = lib.callback.await(_e('server:warehouse:updateTheme'), false,
        client.inWarehouse.warehouse_index, newTheme)

    if response.error then
        client.sendReactMessage('ui:setAlert', { text = response.error, type = 'error' })
        return resultCallback(false)
    end

    client.hideUI()
    resultCallback(true)
end)

RegisterNetEvent(_e('client:warehouse:onWarehouseSold'), function(warehouseIndex)
    local warehouse = warehousesData[warehouseIndex]
    if not warehouse then return end

    if isPlayerInPoint and isPlayerInPoint == warehouseIndex then
        Utils.hideTextUI()
    end

    Warehouse.soldKeys[warehouseIndex] = true
    removeSaleBlip(warehouseIndex)

    if Warehouse.salesPoints[warehouseIndex] then
        Warehouse.salesPoints[warehouseIndex]:remove()
        Warehouse.salesPoints[warehouseIndex] = nil
    end
end)

RegisterNetEvent(_e('client:warehouse:onWarehouseBought'), function(warehouseIndex, warehouseName)
    local warehouse = warehousesData[warehouseIndex]
    if not warehouse then return end

    createOwnedWarehouseBlip(warehouseIndex, warehouseName)
    createWarehousePoint(warehouse, locale('get_inside'), Warehouse.getInside)
end)

---@param warehouseIndex integer
---@param warehouse WarehouseDB
RegisterNetEvent(_e('client:warehouse:onPlayerGetInside'), function(warehouseIndex, warehouse)
    client.inWarehouse = warehouse
    client.sendReactMessage('ui:setCurrentWarehouse', client.inWarehouse)

    SetArtificialLightsState(not warehouse.meta.interior_light)
    Warehouse.loadThemeEntities(warehouse.business_theme, warehouse.meta or {})
    Warehouse.createPanelTargetZone(warehouse.business_theme)
    Warehouse.createOutsidePoint(warehouse.business_theme, warehouseIndex)
    Weather.disableSync()
    Log.loadCurrentWarehouseLogs()
    Citizen.Wait(1000)
    Employee.onGetInside()
    DoScreenFadeIn(1000)
end)

---@param warehouseIndex integer
---@param warehouse WarehouseDB
RegisterNetEvent(_e('client:warehouse:onPlayerGetOutside'), function(warehouseIndex, warehouse)
    client.inWarehouse = nil
    Weather.enableSync()
    Employee.clear()
    Citizen.Wait(500)
    DoScreenFadeIn(1000)
end)

---@param updatedWarehouse WarehouseDB
---@param reloadInterior boolean
RegisterNetEvent(_e('client:warehouse:onUpdate'), function(updatedWarehouse, reloadInterior)
    local configOwnedBlip = Config.Warehouse.ownedBlip

    client.sendReactMessage('ui:setCurrentWarehouse', updatedWarehouse)

    if updatedWarehouse.meta.blip_hidden ~= client.inWarehouse.meta.blip_hidden or
        updatedWarehouse.meta.blip_color ~= client.inWarehouse.meta.blip_color
    then
        local ownedBlip = Warehouse.ownedBlips[updatedWarehouse.warehouse_index]
        if ownedBlip and DoesBlipExist(ownedBlip) then
            SetBlipDisplay(ownedBlip, updatedWarehouse.meta.blip_hidden and 0 or 2)
            SetBlipColour(ownedBlip, updatedWarehouse.meta.blip_color or configOwnedBlip.color)

            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(updatedWarehouse.name or 'Undefined')
            EndTextCommandSetBlipName(ownedBlip)
        end
    end

    if updatedWarehouse.meta.interior_light ~= client.inWarehouse.meta.interior_light then
        SetArtificialLightsState(not updatedWarehouse.meta.interior_light)
        if updatedWarehouse.meta.interior_light then
            Weather.enableSync()
        else
            Weather.disableSync()
        end
    end

    if updatedWarehouse.meta.interior_level == 2 and client.inWarehouse.meta.interior_level == 1 then
        Employee.onGetInside(true)
    end

    if reloadInterior then
        Warehouse.loadThemeEntities(updatedWarehouse.business_theme, updatedWarehouse.meta)
    end

    if updatedWarehouse.meta.is_working ~= client.inWarehouse.meta.is_working then
        if updatedWarehouse.meta.is_working then
            Employee.onWorkStarted()
        else
            Employee.OnWorkStopped()
        end
    end

    client.sendReactMessage('ui:setAlert', { text = locale('warehouse_updated'), type = 'success' })
    client.inWarehouse = updatedWarehouse
end)

RegisterNetEvent(_e('client:warehouse:onPlayerInviteReceived'), function(warehouseIndex, inviteText)
    local alert = lib.alertDialog({
        header = locale('manager_invite'),
        content = inviteText,
        centered = true,
        cancel = true
    })
    if alert == 'confirm' then
        TriggerServerEvent(_e('server:warehouse:onInviteConfirmed'), warehouseIndex)
    else
        TriggerServerEvent(_e('server:warehouse:onInviteCanceled'))
    end
end)

RegisterNetEvent(_e('client:warehouse:onInviteConfirmed'), function(warehouseIndex, warehouseName)
    local warehouse = warehousesData[warehouseIndex]
    if not warehouse then return end
    createOwnedWarehouseBlip(warehouseIndex, warehouseName)
    createWarehousePoint(warehouse, locale('get_inside'), Warehouse.getInside)
end)

RegisterNetEvent(_e('client:warehouse:onWarehouseTerminated'), function(warehouseIndex)
    local warehouse = warehousesData[warehouseIndex]
    if not warehouse then return end

    deletePanelTarget()

    Warehouse.soldKeys[warehouseIndex] = nil

    removeOwnedBlip(warehouseIndex)
    createSalesBlip(warehouseIndex)

    if Warehouse.ownedPoints[warehouseIndex] then
        Warehouse.ownedPoints[warehouseIndex]:remove()
    end

    createWarehousePoint(warehouse, locale('buy_warehouse'), Warehouse.openBuyMenu, true)
end)

RegisterNetEvent(_e('client:warehouse:onManagerAuthRemoved'), function(warehouseIndex)
    if isPlayerInPoint and isPlayerInPoint == warehouseIndex then
        Utils.hideTextUI()
    end

    if client.inWarehouse and client.inWarehouse.warehouse_index == warehouseIndex then
        Warehouse.getOutside(warehouseIndex)
    end

    removeOwnedBlip(warehouseIndex)

    if Warehouse.ownedPoints[warehouseIndex] then
        Warehouse.ownedPoints[warehouseIndex]:remove()
        Warehouse.ownedPoints[warehouseIndex] = nil
    end
end)

RegisterNetEvent(_e('client:warehouse:onPackageProcessed'), function(updatedWarehouse)
    client.sendReactMessage('ui:setCurrentWarehouse', updatedWarehouse)
    client.inWarehouse = updatedWarehouse
    Utils.notify(locale('production_completed'), 'success', 3000)
end)

RegisterNetEvent(_e('client:warehouse:onMoneyWashingCompleted'), function(updatedWarehouse)
    client.sendReactMessage('ui:setCurrentWarehouse', updatedWarehouse)
    client.inWarehouse = updatedWarehouse
end)

RegisterNetEvent(_e('client:warehouse:onThemeUpdate'), function()
    deletePanelTarget()
    client.hideUI()
end)
