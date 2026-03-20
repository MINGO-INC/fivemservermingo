--[[ require ]]

local db = require 'modules.mysql.server'

--[[ state ]]

SecuritySystem = {}

--[[ functions ]]

--[[ events ]]

lib.callback.register(_e('server:security:BuySystem'), function(source, warehouseIndex)
    if not Warehouse.isPlayerManager(warehouseIndex, source) then
        return { error = locale('only_owner_can_do') }
    end

    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then return { error = locale('warehouse_not_found') } end

    if warehouse.meta.security_system then return {} end

    local xPlayerBankAccountMoney = server.getPlayerBalance(source, 'bank')

    if xPlayerBankAccountMoney < Config.SecuritySystem.price then
        return { error = locale('not_enough_money_in_bank') }
    end

    server.playerRemoveMoney(source, 'bank', Config.SecuritySystem.price)

    warehouse.meta.security_system = true

    Warehouse.onUpdate(warehouseIndex, true)
    db.updateWarehouseMeta(warehouseIndex, warehouse.meta)

    return {}
end)
