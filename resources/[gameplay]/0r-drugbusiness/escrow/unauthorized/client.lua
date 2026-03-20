--require

local Utils = require 'modules.utils.client'
local Target = require 'modules.target.client'
local Weather = require 'modules.weather.client'

--state

Unauthorized = {}

local labPanelTargetzone = nil

--helper functions

local function deletePanelTarget()
    if labPanelTargetzone then
        Target.removeZone('drugbusiness_lab_panel')
        labPanelTargetzone = false
    end
end

---@param warehouse WarehouseData
local function createUnauthorizedEntryPoint(warehouse)
    local newPoint = lib.points.new({
        coords = warehouse.entranceCoords,
        warehouseIndex = warehouse.index,
        distance = 2.0,
        nearby = function(self)
            DrawMarker(20, self.coords.x, self.coords.y, self.coords.z - .25, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                .5, .25, 0.5, 200, 20, 20, 255,
                false, true, 2, true, nil, nil, false)

            if IsControlJustPressed(0, 38) then
                if Warehouse.isManager(warehouse.index) then
                    return self:remove()
                end
                Unauthorized.getWarehouseInside(warehouse)
                Citizen.Wait(1000)
            end
        end,
        onEnter = function(self)
            if Warehouse.isManager(warehouse.index) then
                return self:remove()
            end
            Utils.showTextUI('[E] ' .. locale('get_unauthorized_inside'))
        end,
        onExit = function()
            Utils.hideTextUI()
        end,
    })
end

local function confiscate_everything()
    local response = lib.callback.await(_e('server:unauthorized:confiscate'), false, client.inWarehouse.warehouse_index)
    Utils.notify(response, 'inform', 5000)
end

--functions

---@param warehouse WarehouseData
function Unauthorized.getWarehouseInside(warehouse)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(1) end
    local warehouseIndex = warehouse.index
    local response = lib.callback.await(_e('server:warehouse:UnauthorizedEntryByIndex'), false, warehouseIndex)
    if response.error then
        DoScreenFadeIn(500)
        return Utils.notify(response.error, 'error')
    end
end

function Unauthorized.clear()
    deletePanelTarget()
end

function Unauthorized.load()
    local warehousesData = Warehouse.getData()
    local soldKeys = lib.callback.await(_e('server:warehouse:GetSoldKeys'), false)

    for key, warehouse in pairs(warehousesData) do
        if soldKeys[warehouse.index] and
            not Warehouse.isManager(warehouse.index)
        then
            createUnauthorizedEntryPoint(warehouse)
        end
    end
end

---@param theme BusinessTheme
function Unauthorized.createPanelTargetZone(theme)
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
                label = locale('confiscate_everything'),
                onSelect = confiscate_everything,
                distance = 1.5,
            },
        }
    })
    labPanelTargetzone = theme
end

function Unauthorized.getOutside(warehouseIndex)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(1) end
    deletePanelTarget()
    TriggerServerEvent(_e('server:warehouse:UnauthorizedExitByIndex'), warehouseIndex)
end

function Unauthorized.createOutsidePoint(theme, warehouseIndex)
    local lab = Config.Labs[theme]
    if not lab then return end

    local exitArea = lab.coords.exitArea

    lib.points.new({
        coords = exitArea,
        distance = 1.5,
        onEnter = function()
            Utils.showTextUI('[E] ' .. locale('get_outside'))
        end,
        warehouseIndex = warehouseIndex,
        nearby = function(self)
            DrawMarker(20, self.coords.x, self.coords.y, self.coords.z - .25, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                .5, .25, 0.5, 255, 255, 0, 255,
                false, true, 2, true, nil, nil, false)

            if IsControlJustPressed(0, 38) then
                Unauthorized.getOutside(self.warehouseIndex)
                self:remove()
                Utils.hideTextUI()
                return
            end
        end,
        onExit = function()
            Utils.hideTextUI()
        end
    })
end

--events

RegisterNetEvent(_e('client:unauthorized:onPlayerGetInside'), function(warehouseIndex, warehouse)
    client.inWarehouse = warehouse
    client.sendReactMessage('ui:setCurrentWarehouse', client.inWarehouse)

    SetArtificialLightsState(not warehouse.meta.interior_light)
    Warehouse.loadThemeEntities(warehouse.business_theme, warehouse.meta or {})
    Unauthorized.createOutsidePoint(warehouse.business_theme, warehouseIndex)
    Unauthorized.createPanelTargetZone(warehouse.business_theme)
    Weather.disableSync()
    Citizen.Wait(1000)
    Employee.onGetInside()
    DoScreenFadeIn(1000)
end)

---@param warehouseIndex integer
---@param warehouse WarehouseDB
RegisterNetEvent(_e('client:unauthorized:onPlayerGetOutside'), function(warehouseIndex, warehouse)
    client.inWarehouse = nil
    Weather.enableSync()
    Employee.clear()
    Citizen.Wait(500)
    DoScreenFadeIn(1000)
end)
