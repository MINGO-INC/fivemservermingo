--[[ require ]]

local Utils = require 'modules.utils.client'

--[[ state ]]

--[[ functions ]]

--[[ events ]]

RegisterNUICallback('nui:safeactions:withdraw', function(data, resultCallback)
    if not client.inWarehouse then return resultCallback(false) end

    local response = lib.callback.await(_e('server:safeactions:withdrawFromVault'), false,
        client.inWarehouse.warehouse_index, data)

    if response.error then
        client.sendReactMessage('ui:setAlert', { text = response.error, type = 'error' })
        return resultCallback(false)
    end

    resultCallback(true)
end)

RegisterNUICallback('nui:safeactions:deposit', function(data, resultCallback)
    if not client.inWarehouse then return resultCallback(false) end

    local response = lib.callback.await(_e('server:safeactions:depositToVault'), false,
        client.inWarehouse.warehouse_index, data)

    if response.error then
        client.sendReactMessage('ui:setAlert', { text = response.error, type = 'error' })
        return resultCallback(false)
    end

    resultCallback(true)
end)
