--[[ require ]]

local db = require 'modules.mysql.server'
local Inventory = require 'modules.inventory.server'

--[[ helper functions ]]

-- Helper function to validate initial conditions
local function validatePlayerAndWarehouse(source, warehouseIndex)
    if not Warehouse.isPlayerOwner(warehouseIndex, source) then
        return nil, { error = locale('only_owner_can_do') }
    end

    local xPlayer = server.getPlayer(source)
    if not xPlayer then
        return nil, { error = locale('player_not_found') }
    end

    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then
        return nil, { error = locale('warehouse_not_found') }
    end

    return xPlayer, warehouse
end

-- Helper function to handle money transactions
local function handleMoneyTransaction(source, config, warehouse, amount, field, isWithdraw)
    local isItem = config.isItem
    local accountName = config.accountName
    local itemName = config.itemName

    if isWithdraw then
        if warehouse[field] < amount then
            return false
        end
        warehouse[field] -= amount
        if isItem then
            Inventory.giveItem(source, itemName, amount)
        else
            server.playerAddMoney(source, accountName, amount)
        end
    else -- deposit
        if isItem then
            if not Inventory.hasItem(source, itemName, amount) then
                return false
            end
            Inventory.removeItem(source, itemName, amount)
        else
            if server.getPlayerBalance(source, accountName) < amount then
                return false
            end
            server.playerRemoveMoney(source, accountName, amount)
        end
        warehouse[field] += amount
    end
    return true
end

-- Main transaction processor
local function processTransaction(source, warehouseIndex, data, isWithdraw)
    local xPlayer, warehouse = validatePlayerAndWarehouse(source, warehouseIndex)
    if not xPlayer then return warehouse end -- Error response is in warehouse variable

    local amount = tonumber(data.amount or '0')
    if amount <= 0 then return {} end

    local itemType = data.type
    local success = false

    if itemType == 'dirty_money' then
        success = handleMoneyTransaction(source, Config.DirtyMoney, warehouse, amount, 'dirty_money', isWithdraw)
    elseif itemType == 'clean_money' then
        success = handleMoneyTransaction(source, Config.CleanMoney, warehouse, amount, 'clean_money', isWithdraw)
    elseif itemType == 'packaged_product' then
        if isWithdraw then
            if warehouse.packaged_product_stock < amount then
                return { error = locale('can_not_be_bought_more') }
            end
            warehouse.packaged_product_stock -= amount
            Inventory.giveItem(source, Config.PackagedProduct[warehouse.business_theme].itemName, amount)
        else
            local itemName = Config.PackagedProduct[warehouse.business_theme].itemName
            if not Inventory.hasItem(source, itemName, amount) then
                return { error = locale('can_not_be_bought_more') }
            end
            warehouse.packaged_product_stock += amount
            Inventory.removeItem(source, itemName, amount)
        end
        success = true
    end

    if not success then
        return { error = locale('can_not_be_bought_more') }
    end

    Warehouse.onUpdate(warehouseIndex)
    db.updateWarehouseSafe(warehouse)
    return {}
end

--[[ events ]]

-- Register callbacks
lib.callback.register(_e('server:safeactions:withdrawFromVault'), function(source, warehouseIndex, data)
    return processTransaction(source, warehouseIndex, data, true)
end)

lib.callback.register(_e('server:safeactions:depositToVault'), function(source, warehouseIndex, data)
    return processTransaction(source, warehouseIndex, data, false)
end)
