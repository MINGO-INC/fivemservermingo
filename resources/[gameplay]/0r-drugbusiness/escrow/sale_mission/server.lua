--[[ require ]]

local Inventory = require 'modules.inventory.server'
local db = require 'modules.mysql.server'

--[[ state ]]

SaleMission = {
    taskStartedWarehouses = {}
}

--[[ events ]]

RegisterNetEvent(_e('server:salemission:onTaskCancelled'), function(warehouseIndex)
    SaleMission.taskStartedWarehouses[warehouseIndex] = nil
end)

lib.callback.register(_e('server:salemission:onTaskFinished'), function(source, warehouseIndex)
    SaleMission.taskStartedWarehouses[warehouseIndex] = false
end)

lib.callback.register(_e('server:salemission:start'), function(source, warehouseIndex)
    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then
        return { error = locale('warehouse_not_found') }
    end
    if SaleMission.taskStartedWarehouses[warehouseIndex] then
        return { error = locale('salemission_already_started') }
    end
    if not Warehouse.isPlayerManager(warehouseIndex, source) then
        return { error = locale('only_owner_can_do') }
    end
    if warehouse.packaged_product_stock < 10 then
        return { error = locale('stocks_are_very_low') }
    end

    return {}
end)

lib.callback.register(_e('server:salemission:doPayment'), function(source, amount)
    if Config.DirtyMoney.isItem then
        Inventory.giveItem(source, Config.DirtyMoney.itemName, amount)
    else
        server.playerAddMoney(source, Config.DirtyMoney.accountName, amount)
    end
    return true
end)

lib.callback.register(_e('server:salemission:onStart'), function(source, warehouseIndex)
    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then return end
    local configTaskVehicle = Config.RawMaterials.vehicleUpgrades[warehouse.meta.rm_task_vehicle_level or 1]
    if not configTaskVehicle then
        configTaskVehicle = Config.RawMaterials.vehicleUpgrades[#Config.RawMaterials.vehicleUpgrades]
    end

    local packageCount = math.min(configTaskVehicle.maxPackageCount, math.floor(warehouse.packaged_product_stock / 10))
    warehouse.packaged_product_stock -= packageCount * 10

    SaleMission.taskStartedWarehouses[warehouseIndex] = true
    Warehouse.onUpdate(warehouseIndex)
    db.updateWarehouseSafe(warehouse)
end)
