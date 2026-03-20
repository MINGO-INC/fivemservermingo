--[[ require ]]

local db = require 'modules.mysql.server'
local inventory = require 'modules.inventory.server'

local confiscateWarehouses = {}

--[[ events ]]

lib.callback.register(_e('server:unauthorized:confiscate'), function(source, warehouseIndex)
    if not server.getPlayer(source) then
        return locale('player_not_found')
    end
    if not Config.PoliceJobName[server.getPlayerJob(source)?.name or ''] then
        return locale('warehouse_not_found')
    end
    if confiscateWarehouses[warehouseIndex] then
        return locale('nothing_else_left_here')
    end

    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    local anyUp = false

    if warehouse.packaged_product_stock > 0 then
        inventory.giveItem(source, Config.PackagedProduct[warehouse.business_theme].itemName,
            warehouse.packaged_product_stock)
        warehouse.packaged_product_stock = 0
        anyUp = true
    end
    if warehouse.clean_money > 0 then
        inventory.giveItem(source, Config.CleanMoney.itemName,
            warehouse.clean_money)
        warehouse.clean_money = 0
        anyUp = true
    end
    if warehouse.dirty_money > 0 then
        inventory.giveItem(source, Config.DirtyMoney.itemName,
            warehouse.dirty_money)
        warehouse.dirty_money = 0
        anyUp = true
    end
    if warehouse.employee_count > 0 then
        warehouse.employee_count = 0
        anyUp = true
    end
    if anyUp then
        Warehouse.onUpdate(warehouseIndex)
        Log.insert(warehouseIndex, warehouse.id, locale('raid_warehouse'))
        db.updateWarehouseSafe(warehouse)
        db.updateWarehouseEmployeeCount(warehouseIndex, 0)
    end
    confiscateWarehouses[warehouseIndex] = true
    return locale('confiscate_warehouse')
end)
