--[[ require ]]

local db = require 'modules.mysql.server'

--[[ state ]]

RawMaterials = {
    taskStartedWarehouses = {}
}

--[[ events ]]

RegisterNetEvent(_e('server:rawmaterials:onTaskStarted'), function(warehouseIndex)
    RawMaterials.taskStartedWarehouses[warehouseIndex] = true
end)

RegisterNetEvent(_e('server:rawmaterials:onTaskCancelled'), function(warehouseIndex)
    RawMaterials.taskStartedWarehouses[warehouseIndex] = nil
end)

lib.callback.register(_e('server:rawmaterials:onTaskFinished'), function(source, warehouseIndex, packageCount)
    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if warehouse then
        local quantityPackage = Config.RawMaterials.quantityRawMaterialsInPackage * packageCount
        local newStock = warehouse.raw_materials_stock + quantityPackage

        if newStock > warehouse.meta.max_raw_materials_stock then
            warehouse.raw_materials_stock = warehouse.meta.max_raw_materials_stock
        else
            warehouse.raw_materials_stock = newStock
        end

        Warehouse.onUpdate(warehouseIndex)

        db.updateWarehouseRawMaterial(warehouseIndex, warehouse.raw_materials_stock)
    end

    RawMaterials.taskStartedWarehouses[warehouseIndex] = false
    return true
end)

lib.callback.register(_e('server:rawmaterials:IsTaskAlreadyBeing'), function(source, warehouseIndex)
    return RawMaterials.taskStartedWarehouses[warehouseIndex]
end)

lib.callback.register(_e('server:rawmaterials:upgradeVehicle'), function(source, warehouseIndex)
    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then return { error = locale('warehouse_not_found') } end

    local xPlayerBankAccountMoney = server.getPlayerBalance(source, 'bank')

    if #Config.RawMaterials.vehicleUpgrades <= warehouse.meta.rm_task_vehicle_level then return {} end

    local configVehicleDetail = Config.RawMaterials.vehicleUpgrades[warehouse.meta.rm_task_vehicle_level + 1]

    if xPlayerBankAccountMoney < configVehicleDetail.price then
        return { error = locale('not_enough_money_in_bank') }
    end

    server.playerRemoveMoney(source, 'bank', configVehicleDetail.price)

    warehouse.meta.rm_task_vehicle_level = warehouse.meta.rm_task_vehicle_level + 1

    Warehouse.onUpdate(warehouseIndex)
    db.updateWarehouseMeta(warehouseIndex, warehouse.meta)

    return {}
end)

lib.callback.register(_e('server:rawmaterials:upgradeMaxStock'), function(source, warehouseIndex)
    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then return { error = locale('warehouse_not_found') } end

    local xPlayerBankAccountMoney = server.getPlayerBalance(source, 'bank')

    if #Config.RawMaterials.stockUpgrades <= warehouse.meta.raw_materials_stock_level then return {} end

    local configDetails = Config.RawMaterials.stockUpgrades[warehouse.meta.raw_materials_stock_level + 1]

    if xPlayerBankAccountMoney < configDetails.price then
        return { error = locale('not_enough_money_in_bank') }
    end

    server.playerRemoveMoney(source, 'bank', configDetails.price)

    warehouse.meta.max_raw_materials_stock = configDetails.maxStockCount
    warehouse.meta.raw_materials_stock_level = warehouse.meta.raw_materials_stock_level + 1

    Warehouse.onUpdate(warehouseIndex)
    db.updateWarehouseMeta(warehouseIndex, warehouse.meta)

    return {}
end)

RegisterNetEvent(_e('server:rawmaterials:createTemporaryCollectionPoints'), function(warehouseIndex, coords)
    local owned = source
    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then return end
    -- # TODO
end)

RegisterNetEvent(_e('server:rawmaterials:deletePointPedByIndex'), function(warehouseIndex, pointIndex)
    local owned = source
    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then return end
    -- # TODO
end)
