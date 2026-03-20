--[[ require ]]

local db = require 'modules.mysql.server'

--[[ events ]]

lib.callback.register(_e('server:moneywashing:upgrade'), function(source, warehouseIndex)
    if not Warehouse.isPlayerOwner(warehouseIndex, source) then
        return { error = locale('only_owner_can_do') }
    end

    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then return { error = locale('warehouse_not_found') } end

    local configMoneyWashing = Config.MoneyWashing.upgrades

    if warehouse.meta.money_washing_level >= #configMoneyWashing then return {} end
    if not configMoneyWashing[warehouse.meta.money_washing_level + 1] then return {} end

    local upgradePrice = configMoneyWashing[warehouse.meta.money_washing_level + 1].price
    local xPlayerBankAccountMoney = server.getPlayerBalance(source, 'bank')

    if xPlayerBankAccountMoney < upgradePrice then
        return { error = locale('not_enough_money_in_bank') }
    end

    server.playerRemoveMoney(source, 'bank', upgradePrice)

    warehouse.meta.money_washing_level += 1

    Warehouse.onUpdate(warehouseIndex)
    db.updateWarehouseMeta(warehouseIndex, warehouse.meta)

    return {}
end)

RegisterNetEvent(_e('server:moneywashing:GetInside'), function()
    local source = source
    local coords = Config.MoneyWashing.interior.entrance
    local xPlayerPed = GetPlayerPed(source)
    SetEntityCoords(xPlayerPed, coords.x, coords.y, coords.z)
    if coords.w then SetEntityHeading(xPlayerPed, coords.w) end

    TriggerClientEvent(_e('client:moneywashing:onPlayerGetInside'), source)
end)

RegisterNetEvent(_e('server:moneywashing:GetOutside'), function(warehouseIndex)
    local source = source
    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then
        SetPlayerRoutingBucket(source, 0)
        local coords = Config.FallbackExitCoord
        local xPlayerPed = GetPlayerPed(source)
        SetEntityCoords(xPlayerPed, coords.x, coords.y, coords.z)
        TriggerClientEvent(_e('client:warehouse:onPlayerGetOutside'), source, warehouseIndex)
        return
    end
    local coords = Config.Labs[warehouse.business_theme].coords.entrance
    local xPlayerPed = GetPlayerPed(source)
    SetEntityCoords(xPlayerPed, coords.x, coords.y, coords.z)
    if coords.w then SetEntityHeading(xPlayerPed, coords.w) end
    TriggerClientEvent(_e('client:moneywashing:onPlayerGetOutside'), source)
end)
