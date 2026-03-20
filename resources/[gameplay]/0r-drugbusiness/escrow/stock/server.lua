--[[ require ]]

local db = require 'modules.mysql.server'

--[[ state ]]

Stock = {}

--[[ functions  ]]

---@param warehouse Warehouse
---@param type any
---@return integer
function Stock.getQuantity(warehouse, type)
    local quantity = 0
    if type == 'water' then
        quantity = warehouse.water_stock
    elseif type == 'gas' then
        quantity = warehouse.gas_stock
    elseif type == 'electricity' then
        quantity = warehouse.electricity_stock
    end

    return quantity
end

---@param warehouse Warehouse
---@param type any
---@param newQuantity integer
function Stock.addQuantity(warehouse, type, quantity)
    if type == 'water' then
        warehouse.water_stock = warehouse.water_stock + quantity
    elseif type == 'gas' then
        warehouse.gas_stock = warehouse.gas_stock + quantity
    elseif type == 'electricity' then
        warehouse.electricity_stock = warehouse.electricity_stock + quantity
    end
end

--[[ events ]]

lib.callback.register(_e('server:stock:PurchaseByType'), function(source, warehouseIndex, data)
    ---@type 'water'|'gas'|'electricity'
    local stockType = data.type
    local stockAmount = data.amount

    if not Config.Stock[stockType].unit_price then
        return { error = 'server:stock:PurchaseByType->unknown stockType' }
    end

    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then return { error = locale('warehouse_not_found') } end

    local currentQuantity = Stock.getQuantity(warehouse, stockType)
    if currentQuantity >= 1000 then
        return { error = locale('can_not_be_bought_more') }
    end

    if stockAmount + currentQuantity > 1000 then
        stockAmount = 1000 - currentQuantity
    end

    local totalPrice = math.max(1, math.floor(stockAmount * (Config.Stock[stockType].unit_price or 1)))

    local xPlayerBankAccountMoney = server.getPlayerBalance(source, 'bank')

    if xPlayerBankAccountMoney < totalPrice then
        return { error = locale('not_enough_money_in_bank') }
    end

    Stock.addQuantity(warehouse, stockType, stockAmount)

    server.playerRemoveMoney(source, 'bank', totalPrice)

    Warehouse.onUpdate(warehouseIndex)

    db.updateWarehouseStocks(warehouseIndex,
        warehouse.water_stock, warehouse.gas_stock, warehouse.electricity_stock)

    return {}
end)
