--[[ require ]]

local Utils = require 'modules.utils.client'

--[[ state ]]

Stock = {}

--[[ functions  ]]

--[[ events ]]

RegisterNUICallback('nui:stock:purchaseByType', function(data, resultCallback)
    local stockType = data.id
    local stockAmount = data.amount
    if not stockType or
        not stockAmount or
        type(stockAmount) ~= 'number' or
        stockAmount < 0
    then
        return resultCallback(false)
    end

    local response = lib.callback.await(_e('server:stock:PurchaseByType'), false,
        client.inWarehouse.warehouse_index, { type = stockType, amount = stockAmount })

    if response.error then
        client.sendReactMessage('ui:setAlert', { text = response.error, type = 'error' })
        return resultCallback(false)
    end

    resultCallback(true)
end)
