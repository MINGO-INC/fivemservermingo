---@class Warehouse:WarehouseDB
---@field production_time number
---@field production_count number

--[[ require ]]

local db = require 'modules.mysql.server'
local Inventory = require 'modules.inventory.server'

---@type table<BusinessTheme, ThemeInterior>
local ThemeInteriors = lib.load('data.theme_interiors')

--[[ state ]]

---@type WarehouseData[]
local warehousesData = lib.load('data.warehouses')

WAREHOUSE_MIN_EMPLOYEE_FOR_WORK = 3

Warehouse = {
    ---@type Warehouse[]
    sold = {},
    soldKeys = {}
}

---@type table<integer, integer[]>
local playersInWarehouses = {}

---@type table<integer, integer>
local playersInviteCache = {}

--[[ helper functions ]]

---@param exp number -- experience count
local function getWarehouseLevel(exp)
    local level = 1
    local required_exp = 1000 -- Başlangıç seviyesindeki gereksinim

    -- EXP'yi geçene kadar seviyeleri arttır
    while exp >= required_exp do
        exp = exp - required_exp
        level = level + 1
        required_exp = math.floor(required_exp * 1.2) -- Her seviyede EXP %20 artar
    end

    return level
end

---@param exp number -- experience count
local function getWarehouseNextLevel(exp)
    local level = getWarehouseLevel(exp)
    local required_exp = 1000 -- Başlangıç seviyesindeki gereksinim
    local next_level_exp = 0

    -- Gelecek seviyenin gereksinimini hesapla
    for i = 1, level do
        next_level_exp = next_level_exp + required_exp
        required_exp = math.floor(required_exp * 1.2) -- Her seviyede EXP %20 artar
    end

    return next_level_exp
end

local function getWarehouseProductionCount(level, employeeCount)
    local start_count = 30
    local employeeFactor = 1 + (employeeCount - 1) * 0.05 -- For example, each employee increases production by 5%
    return math.floor(start_count * (1.02) ^ (level - 1) * employeeFactor)
end

local function getWarehouseProductionTime(level, employeeCount)
    local start_time = 60 * 60 -- 60 minutes (1 hour)
    local min_time = 5 * 60    -- 5 minutes (minimum time)
    local max_time = 60 * 60   -- 60 minutes (maximum time)

    -- Çalışan sayısına göre üretim süresi
    local employeeFactor = 1 - (employeeCount - 1) * 0.02 -- Her çalışan sürenin %2 azalmasını sağlar.

    -- Seviye arttıkça üretim süresi azalacak
    local time = start_time - (start_time - min_time) * (level - 1) / 29

    -- Çalışan faktörünü uygula ve minimum 5 dakika, maksimum 60 dakika olmasını sağla
    time = time * employeeFactor

    -- Sürenin minimum 5 dakika, maksimum 60 dakika olmasını sağla
    return math.floor(math.max(math.min(time, max_time), min_time))
end

--[[ functions ]]

function Warehouse.loadDatabase()
    ---@type Warehouse[]
    local soldWarehouses = db.getSoldWarehouses()

    for _, value in pairs(soldWarehouses) do
        value.managers = value.managers and
            json.decode(value.managers) or {}
        value.meta = value.meta and json.decode(value.meta) or {}

        value.level = getWarehouseLevel(value.experience)
        value.nextLeveLExp = getWarehouseNextLevel(value.experience)

        value.production_count = getWarehouseProductionCount(value.level, value.employee_count or 0)
        value.production_time = getWarehouseProductionTime(value.level, value.employee_count or 0)
        if value.last_processed then
            value.last_processed = tonumber(value.last_processed)
        end

        value.dirty_money = tonumber(value.dirty_money)
        value.clean_money = tonumber(value.clean_money)

        value.meta.max_package_stock = Config.PackagedProduct.maxStock
        value.meta.max_raw_materials_stock = Config.RawMaterials.stockUpgrades
            [value.meta.raw_materials_stock_level or 1].maxStockCount

        Warehouse.soldKeys[value.warehouse_index] = true
    end

    Warehouse.sold = soldWarehouses
end

function Warehouse.isSold(warehouseIndex)
    return Warehouse.soldKeys[warehouseIndex]
end

function Warehouse.getDataByIndex(warehouseIndex)
    return warehousesData[warehouseIndex]
end

---@param warehouseIndex integer
---@return Warehouse
function Warehouse.getSoldByIndex(warehouseIndex)
    for key, value in pairs(Warehouse.sold) do
        if value.warehouse_index == warehouseIndex then
            return Warehouse.sold[key]
        end
    end
    return false
end

function Warehouse.onWarehouseSold(warehouseIndex, ownerServerId, warehouseName)
    TriggerClientEvent(_e('client:warehouse:onWarehouseSold'), -1, warehouseIndex)
    TriggerClientEvent(_e('client:warehouse:onWarehouseBought'), ownerServerId, warehouseIndex, warehouseName)
    TriggerClientEvent(_e('client:profile:updateWarehouses'), ownerServerId, Warehouse.getPlayerWarehouses(ownerServerId))
end

function Warehouse.getPlayerWarehouses(source)
    local playerIdentifier = server.getPlayerIdentifier(source)
    local playerWarehouses = {}

    for _, warehouse in pairs(Warehouse.sold) do
        if warehouse.owner_id == playerIdentifier then
            table.insert(playerWarehouses, warehouse)
        else
            for _, manager in ipairs(warehouse.managers) do
                if manager.identifier == playerIdentifier then
                    table.insert(playerWarehouses, warehouse)
                    break
                end
            end
        end
    end

    return playerWarehouses
end

function Warehouse.isPlayerManager(warehouseIndex, identifier)
    if type(identifier) == 'number' then
        identifier = server.getPlayerIdentifier(identifier)
    end

    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then return false end
    if warehouse.owner_id == identifier then return true end
    for _, manager in pairs(warehouse.managers) do
        if manager.identifier == identifier then return true end
    end

    return false
end

function Warehouse.onUpdate(warehouseIndex, reloadInterior)
    local playersInside = playersInWarehouses[warehouseIndex]
    if not playersInside then return end

    local updatedWarehouse = Warehouse.getSoldByIndex(warehouseIndex)

    for source, inside in pairs(playersInside) do
        if inside then
            TriggerClientEvent(_e('client:warehouse:onUpdate'), source, updatedWarehouse, reloadInterior)
        end
    end
end

function Warehouse.isPlayerOwner(warehouseIndex, identifier)
    if type(identifier) == 'number' then
        identifier = server.getPlayerIdentifier(identifier)
    end

    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then return false end

    return warehouse.owner_id == identifier
end

function Warehouse.playerGetOutside(source, warehouseIndex)
    local exitCoords = Config.FallbackExitCoord
    local warehouseData = Warehouse.getDataByIndex(warehouseIndex)
    if warehouseData then
        exitCoords = warehouseData.entranceCoords
    end

    local xPlayerPed = GetPlayerPed(source)
    SetEntityCoords(xPlayerPed, exitCoords.x, exitCoords.y, exitCoords.z)
    if exitCoords.w then
        SetEntityHeading(xPlayerPed, exitCoords.w)
    end
    SetPlayerRoutingBucket(source, 0)

    server.setPlayerMeta(source, 'inwarehouseindex', nil)

    if not playersInWarehouses[warehouseIndex] then
        playersInWarehouses[warehouseIndex] = {}
    end
    playersInWarehouses[warehouseIndex][source] = nil

    TriggerClientEvent(_e('client:warehouse:onPlayerGetOutside'), source, warehouseIndex)
end

---@param source integer
---@param warehouseIndex integer
---@return Warehouse
function Warehouse.createDataForDB(source, warehouseIndex)
    local xPlayerIdentifier = server.getPlayerIdentifier(source)
    local xPlayerName = server.getPlayerCharacterName(source)

    return {
        id = nil,
        warehouse_index = warehouseIndex,
        name = locale('personal_warehouse', xPlayerName),
        owner_id = xPlayerIdentifier,
        business_theme = 'weed',
        clean_money = 0,
        dirty_money = 0,
        experience = 0,
        managers = {
            { identifier = xPlayerIdentifier, name = xPlayerName }
        },
        meta = {
            max_package_stock = Config.PackagedProduct.maxStock,
            max_raw_materials_stock = Config.RawMaterials.stockUpgrades[1].maxStockCount,
            blip_hidden = false,
            interior_light = true,
            security_system = false,
            is_working = false,
            rm_task_vehicle_level = 1,
            last_employee_salary_paid_at = os.time(),
            interior_level = 1,
            last_working_at = nil,
            raw_materials_stock_level = 1,
            money_washing_level = 0,
        },
        level = getWarehouseLevel(0),
        nextLevelExp = getWarehouseNextLevel(0),
        employee_count = 3,
        packaged_product_stock = 0,
        raw_materials_stock = 0,
        electricity_stock = 500,
        gas_stock = 500,
        water_stock = 500,
        created_at = os.date('%x'),
        production_count = getWarehouseProductionCount(1, 3),
        production_time = getWarehouseProductionTime(1, 3),
        last_processed = nil,
    }
end

function Warehouse.stopWorking(warehouseIndex)
    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    warehouse.meta.is_working = false
    Warehouse.onUpdate(warehouseIndex)
    db.updateWarehouseMeta(warehouseIndex, warehouse.meta)
end

--[[ events ]]

lib.callback.register(_e('server:warehouse:GetSoldKeys'), function()
    if not server.load then
        while not server.load do Citizen.Wait(100) end
    end
    return Warehouse.soldKeys
end)

lib.callback.register(_e('server:warehouse:BuyNew'), function(source, warehouseIndex)
    if Warehouse.isSold(warehouseIndex) then
        return { error = locale('is_already_sold') }
    end
    local warehouseData = Warehouse.getDataByIndex(warehouseIndex)
    local xPlayerBankAccountMoney = server.getPlayerBalance(source, 'bank')

    if xPlayerBankAccountMoney < warehouseData.price then
        return { error = locale('not_enough_money_in_bank') }
    end

    local newWarehouseDB = Warehouse.createDataForDB(source, warehouseIndex)

    local insertedWarehouseId = db.insertWarehouse(newWarehouseDB)

    if not insertedWarehouseId or
        insertedWarehouseId <= 0
    then
        return { error = locale('db_error_insert') }
    end

    server.playerRemoveMoney(source, 'bank', warehouseData.price)
    newWarehouseDB.id = insertedWarehouseId

    table.insert(Warehouse.sold, newWarehouseDB)
    Warehouse.soldKeys[warehouseIndex] = true

    Warehouse.onWarehouseSold(warehouseIndex, source, newWarehouseDB.name)

    return {}
end)

lib.callback.register(_e('server:warehouse:GetInsideByIndex'), function(source, warehouseIndex)
    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then
        return { error = locale('warehouse_not_found') }
    end

    local warehouseTheme = warehouse.business_theme
    local entranceCoords = Config.Labs[warehouseTheme].coords.entrance

    local xPlayerPed = GetPlayerPed(source)
    SetEntityCoords(xPlayerPed, entranceCoords.x, entranceCoords.y, entranceCoords.z)
    if entranceCoords.w then
        SetEntityHeading(xPlayerPed, entranceCoords.w)
    end

    SetPlayerRoutingBucket(source, tonumber(1 .. '' .. warehouseIndex))
    server.setPlayerMeta(source, 'inwarehouseindex', warehouseIndex)
    if not playersInWarehouses[warehouseIndex] then
        playersInWarehouses[warehouseIndex] = {}
    end
    playersInWarehouses[warehouseIndex][source] = true

    TriggerClientEvent(_e('client:warehouse:onPlayerGetInside'), source, warehouseIndex, warehouse)

    return {}
end)

lib.callback.register(_e('server:warehouse:HasPlayerInsideMeta'), function(source)
    return server.getPlayerMeta(source, 'inwarehouseindex')
end)

---@param warehouseIndex integer
RegisterNetEvent(_e('server:warehouse:GetOutsideByIndex'), function(warehouseIndex)
    local source = source

    Warehouse.playerGetOutside(source, warehouseIndex)
end)

lib.callback.register(_e('server:warehouse:UpdateName'), function(source, warehouseIndex, newWarehouseName)
    if not Warehouse.isPlayerManager(warehouseIndex, source) then return end

    Warehouse.getSoldByIndex(warehouseIndex).name = newWarehouseName

    Warehouse.onUpdate(warehouseIndex)
    db.updateWarehouseName(warehouseIndex, newWarehouseName)

    return true
end)

lib.callback.register(_e('server:warehouse:ToggleBlipHidden'), function(source, warehouseIndex)
    if not Warehouse.isPlayerManager(warehouseIndex, source) then return end

    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    warehouse.meta.blip_hidden = not warehouse.meta.blip_hidden

    Warehouse.onUpdate(warehouseIndex)
    db.updateWarehouseMeta(warehouseIndex, warehouse.meta)

    return true
end)

lib.callback.register(_e('server:warehouse:UpdateBlipColor'), function(source, warehouseIndex, newBlipColor)
    if not Warehouse.isPlayerManager(warehouseIndex, source) then return end

    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    warehouse.meta.blip_color = newBlipColor

    Warehouse.onUpdate(warehouseIndex)
    db.updateWarehouseMeta(warehouseIndex, warehouse.meta)

    return true
end)

lib.callback.register(_e('server:warehouse:RemovePlayerToWarehouse'), function(source, warehouseIndex, targetIdentifier)
    if not Warehouse.isPlayerOwner(warehouseIndex, source) then
        return { error = locale('only_owner_can_do') }
    end

    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then
        return { error = locale('warehouse_not_found') }
    end

    if not Warehouse.isPlayerManager(warehouseIndex, targetIdentifier) then
        return { error = locale('player_not_found') }
    end

    for key, manager in pairs(warehouse.managers) do
        if manager.identifier == targetIdentifier then
            table.remove(warehouse.managers, key)
            break
        end
    end

    local xTargetSource = server.getPlayerSourceByIdentifier(targetIdentifier)
    if xTargetSource then
        TriggerClientEvent(_e('client:warehouse:onManagerAuthRemoved'), xTargetSource, warehouseIndex)
    end

    Warehouse.onUpdate(warehouseIndex)
    db.updateWarehouseManagers(warehouseIndex, warehouse.managers)

    return {}
end)

lib.callback.register(_e('server:warehouse:InvitePlayerToWarehouse'), function(source, warehouseIndex, targetSourceId)
    if not Warehouse.isPlayerOwner(warehouseIndex, source) then
        return { error = locale('only_owner_can_do') }
    end
    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then
        return { error = locale('warehouse_not_found') }
    end

    local xTargetPlayer = server.getPlayer(targetSourceId)
    if not xTargetPlayer then
        return { error = locale('player_not_found') }
    end

    if Warehouse.isPlayerManager(warehouseIndex, targetSourceId) then
        return { error = locale('player_is_already_manager') }
    end

    playersInviteCache[targetSourceId] = warehouseIndex

    local inviteText = locale('received_manager_invite',
        server.getPlayerCharacterName(source), warehouse.name)

    TriggerClientEvent(_e('client:warehouse:onPlayerInviteReceived'), targetSourceId, warehouseIndex, inviteText)

    return { success = locale('invite_sent', server.getPlayerCharacterName(targetSourceId)) }
end)

RegisterNetEvent(_e('server:warehouse:onInviteCanceled'), function()
    local source = source
    playersInviteCache[source] = nil
end)

RegisterNetEvent(_e('server:warehouse:onInviteConfirmed'), function(warehouseIndex)
    local source = source
    if playersInviteCache[source] ~= warehouseIndex then return end
    playersInviteCache[source] = nil

    if Warehouse.isPlayerManager(warehouseIndex, source) then return end

    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then return end

    table.insert(warehouse.managers, {
        identifier = server.getPlayerIdentifier(source),
        name = server.getPlayerCharacterName(source),
    })

    Warehouse.onUpdate(warehouseIndex)
    db.updateWarehouseManagers(warehouseIndex, warehouse.managers)

    TriggerClientEvent(_e('client:warehouse:onInviteConfirmed'), source, warehouseIndex, warehouse.name)
    TriggerClientEvent(_e('client:profile:updateWarehouses'), source, Warehouse.getPlayerWarehouses(source))
end)

lib.callback.register(_e('server:warehouse:ChangeInteriorLightState'), function(source, warehouseIndex)
    if not Warehouse.isPlayerManager(warehouseIndex, source) then return false end

    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    warehouse.meta.interior_light = not warehouse.meta.interior_light

    Warehouse.onUpdate(warehouseIndex)
    db.updateWarehouseMeta(warehouseIndex, warehouse.meta)

    return true
end)

lib.callback.register(_e('server:warehouse:TerminateWarehouse'), function(source, warehouseIndex)
    if not Warehouse.isPlayerOwner(warehouseIndex, source) then
        return { error = locale('only_owner_can_do') }
    end

    local playersInside = playersInWarehouses[warehouseIndex]
    if not playersInside then return {} end

    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then return { error = locale('warehouse_not_found') } end

    for source, inside in pairs(playersInside) do
        if inside then
            Warehouse.playerGetOutside(source, warehouseIndex)
        end
    end

    for key, value in pairs(Warehouse.sold) do
        if value.warehouse_index == warehouseIndex then
            table.remove(Warehouse.sold, key)
            break
        end
    end

    Warehouse.soldKeys[warehouseIndex] = false

    TriggerClientEvent(_e('client:warehouse:onWarehouseTerminated'), -1, warehouseIndex)

    db.deleteWarehouseByIndex(warehouseIndex, server.getPlayerIdentifier(source))

    return {}
end)

---@param source any
---@param warehouseIndex any
---@param targetManager Manager
---@return table
lib.callback.register(_e('server:warehouse:TransferOwnershipToManager'), function(source, warehouseIndex, targetManager)
    if not Warehouse.isPlayerOwner(warehouseIndex, source) then
        return { error = locale('only_owner_can_do') }
    end
    if not Warehouse.isPlayerManager(warehouseIndex, targetManager.identifier) then
        return { error = locale('player_not_found') }
    end

    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then return { error = locale('warehouse_not_found') } end

    warehouse.owner_id = targetManager.identifier

    Warehouse.onUpdate(warehouseIndex)
    db.updateWarehouseOwner(warehouseIndex, targetManager.identifier)

    return {}
end)

lib.callback.register(_e('server:warehouse:upgradeInterior'), function(source, warehouseIndex)
    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then return { error = locale('warehouse_not_found') } end

    if not Warehouse.isPlayerManager(warehouseIndex, source) then return {} end

    local xPlayerBankAccountMoney = server.getPlayerBalance(source, 'bank')

    local upgrades = Config.Labs[warehouse.business_theme].upgrades

    if not upgrades[warehouse.meta.interior_level + 1] then return {} end

    local configUpgradeDetail = upgrades[warehouse.meta.interior_level + 1]

    if xPlayerBankAccountMoney < configUpgradeDetail.price then
        return { error = locale('not_enough_money_in_bank') }
    end

    server.playerRemoveMoney(source, 'bank', configUpgradeDetail.price)

    warehouse.meta.interior_level = warehouse.meta.interior_level + 1

    Warehouse.onUpdate(warehouseIndex, true)
    db.updateWarehouseMeta(warehouseIndex, warehouse.meta)

    return {}
end)

lib.callback.register(_e('server:warehouse:toggleWorkingState'), function(source, warehouseIndex)
    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then return { error = locale('warehouse_not_found') } end

    if not Warehouse.isPlayerManager(warehouseIndex, source) then return {} end

    if not warehouse.meta.is_working then
        if warehouse.meta.interior_level < 2 then
            return { error = locale('need_upgrade_interior_to_start_work') }
        end
        if warehouse.employee_count < WAREHOUSE_MIN_EMPLOYEE_FOR_WORK then
            return { error = locale('need_least_employees_to_start_work', 3) }
        end
        local minStockAmount = 50
        if warehouse.raw_materials_stock < warehouse.production_count * 2 or
            warehouse.water_stock < minStockAmount or
            warehouse.gas_stock < minStockAmount or
            warehouse.electricity_stock < minStockAmount
        then
            return { error = locale('stocks_are_very_low') }
        end
        if warehouse.packaged_product_stock >= warehouse.meta.max_package_stock then
            return { error = locale('warehouse_full') }
        end
    end

    warehouse.meta.is_working = not warehouse.meta.is_working
    if warehouse.meta.is_working then
        warehouse.meta.last_working_at = os.time()
    end

    Warehouse.onUpdate(warehouseIndex)

    db.updateWarehouseMeta(warehouseIndex, warehouse.meta)

    return {}
end)

---@param source integer
---@param warehouseIndex integer
---@param newTheme BusinessTheme
---@return table
lib.callback.register(_e('server:warehouse:updateTheme'), function(source, warehouseIndex, newTheme)
    if not Warehouse.isPlayerOwner(warehouseIndex, source) then
        return { error = locale('only_owner_can_do') }
    end

    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then return { error = locale('warehouse_not_found') } end

    if warehouse.business_theme == newTheme then
        return {}
    end

    local themeConfig = nil
    for _, businessType in pairs(Config.BusinessTypes) do
        if businessType.key == newTheme then
            themeConfig = businessType
            break
        end
    end
    if not themeConfig then return {} end

    local xPlayerBankAccountMoney = server.getPlayerBalance(source, 'bank')

    if xPlayerBankAccountMoney < themeConfig.price then
        return { error = locale('not_enough_money_in_bank') }
    end

    server.playerRemoveMoney(source, 'bank', themeConfig.price)

    warehouse.business_theme = newTheme
    warehouse.packaged_product_stock = 0
    warehouse.raw_materials_stock = 0
    warehouse.meta.interior_level = 1
    warehouse.meta.is_working = false
    warehouse.meta.last_employee_salary_paid_at = os.time()
    warehouse.meta.security_system = false
    warehouse.last_processed = nil
    warehouse.meta.last_working_at = nil

    if playersInWarehouses[warehouseIndex] then
        for playerSource, _ in pairs(playersInWarehouses[warehouseIndex]) do
            TriggerClientEvent(_e('client:warehouse:onThemeUpdate'), playerSource, warehouseIndex, newTheme)
            Warehouse.playerGetOutside(playerSource, warehouseIndex)
        end
    end

    db.updateWarehouseTheme(warehouseIndex, newTheme, warehouse.meta)

    return {}
end)

lib.callback.register(_e('server:warehouse:UnauthorizedEntryByIndex'), function(source, warehouseIndex)
    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then
        return { error = locale('warehouse_not_found') }
    end
    if Warehouse.isPlayerManager(warehouseIndex, source) then
        return { error = locale('player_is_already_manager') }
    end
    if not Inventory.hasItem(source, Config.UnauthorizedEntry.requiredItemName, 1) then
        return { error = locale('need_lockpick') }
    end
    if not Config.PoliceJobName[server.getPlayerJob(source)?.name or ''] and
        warehouse.meta.security_system
    then
        return { error = locale('cannot_enter_sec_system') }
    end

    Inventory.removeItem(source, Config.UnauthorizedEntry.requiredItemName, 1)

    local warehouseTheme = warehouse.business_theme
    local entranceCoords = Config.Labs[warehouseTheme].coords.entrance

    local xPlayerPed = GetPlayerPed(source)
    SetEntityCoords(xPlayerPed, entranceCoords.x, entranceCoords.y, entranceCoords.z)
    if entranceCoords.w then
        SetEntityHeading(xPlayerPed, entranceCoords.w)
    end

    SetPlayerRoutingBucket(source, tonumber(1 .. '' .. warehouseIndex))
    server.setPlayerMeta(source, 'inwarehouseindex', warehouseIndex)
    if not playersInWarehouses[warehouseIndex] then
        playersInWarehouses[warehouseIndex] = {}
    end
    playersInWarehouses[warehouseIndex][source] = true

    TriggerClientEvent(_e('client:unauthorized:onPlayerGetInside'), source, warehouseIndex, warehouse)

    return {}
end)

---@param warehouseIndex integer
RegisterNetEvent(_e('server:warehouse:UnauthorizedExitByIndex'), function(warehouseIndex)
    local source = source

    local exitCoords = Config.FallbackExitCoord
    local warehouseData = Warehouse.getDataByIndex(warehouseIndex)
    if warehouseData then
        exitCoords = warehouseData.entranceCoords
    end

    local xPlayerPed = GetPlayerPed(source)
    SetEntityCoords(xPlayerPed, exitCoords.x, exitCoords.y, exitCoords.z)
    if exitCoords.w then
        SetEntityHeading(xPlayerPed, exitCoords.w)
    end
    SetPlayerRoutingBucket(source, 0)

    server.setPlayerMeta(source, 'inwarehouseindex', nil)

    if not playersInWarehouses[warehouseIndex] then
        playersInWarehouses[warehouseIndex] = {}
    end
    playersInWarehouses[warehouseIndex][source] = nil

    TriggerClientEvent(_e('client:unauthorized:onPlayerGetOutside'), source, warehouseIndex)
end)

--[[ cron ]]

lib.cron.new('*/5 * * * *', function()
    if not server.load then return end

    local currentTime = os.time()

    for _, warehouse in pairs(Warehouse.sold) do
        local lastProcessedTime = warehouse.last_processed or warehouse.meta.last_working_at
        if warehouse.meta.is_working and lastProcessedTime then
            local diffTime = currentTime - lastProcessedTime
            if diffTime >= warehouse.production_time then
                local productionCount = warehouse.production_count

                local quantityRawMaterialsRequired = productionCount * 2
                local amountWaterRequired = math.random(25, 50)
                local amountGasRequired = math.random(25, 50)
                local amountElectricityRequired = math.random(25, 50)

                --- Gerekli stok yok üretim dursun
                if warehouse.raw_materials_stock < quantityRawMaterialsRequired or
                    warehouse.water_stock < amountWaterRequired or
                    warehouse.gas_stock < amountGasRequired or
                    warehouse.electricity_stock < amountElectricityRequired or
                    warehouse.packaged_product_stock >= warehouse.meta.max_package_stock
                then
                    warehouse.meta.is_working = false
                    db.updateWarehouseMeta(warehouse.warehouse_index, warehouse.meta)
                    Log.insert(warehouse.warehouse_index, warehouse.id, locale('production_stopped'))
                else
                    warehouse.gas_stock -= amountGasRequired
                    warehouse.water_stock -= amountWaterRequired
                    warehouse.electricity_stock -= amountElectricityRequired
                    warehouse.raw_materials_stock -= quantityRawMaterialsRequired

                    warehouse.packaged_product_stock = math.min(warehouse.meta.max_package_stock,
                        warehouse.packaged_product_stock + warehouse.production_count)

                    warehouse.last_processed = currentTime

                    warehouse.experience += math.random(75, 100)

                    db.onWarehouseProcessed(warehouse, currentTime)
                    Log.insert(warehouse.warehouse_index, warehouse.id, locale('production_completed'))
                end

                if playersInWarehouses[warehouse.warehouse_index] then
                    for source, _ in pairs(playersInWarehouses[warehouse.warehouse_index]) do
                        TriggerClientEvent(_e('client:warehouse:onPackageProcessed'), source, warehouse)
                    end
                end
            end
        end
    end
end, { debug = Config.debug })

lib.cron.new('*/10 * * * *', function()
    if not server.load then return end
    local currentTime = os.time()
    for _, warehouse in pairs(Warehouse.sold) do
        if warehouse.meta.is_working and
            warehouse.meta.money_washing_level > 0 and
            warehouse.dirty_money > 0
        then
            local index = math.min(#Config.MoneyWashing.upgrades, warehouse.meta.money_washing_level)
            local configMoneyWashing = Config.MoneyWashing.upgrades[index]
            local washPerMin = math.min(configMoneyWashing.productionPerMin * 10, warehouse.dirty_money)

            warehouse.clean_money += washPerMin
            warehouse.dirty_money -= washPerMin

            db.updateWarehouseSafe(warehouse)
            Log.insert(warehouse.warehouse_index, warehouse.id, locale('warehouse_completed', washPerMin))

            if playersInWarehouses[warehouse.warehouse_index] then
                for source, _ in pairs(playersInWarehouses[warehouse.warehouse_index]) do
                    TriggerClientEvent(_e('client:warehouse:onMoneyWashingCompleted'), source, warehouse)
                end
            end
        end
    end
end, { debug = Config.debug })
