--[[ require ]]

--[[ state ]]

Log = {}

--[[ functions ]]

function Log.loadCurrentWarehouseLogs()
    lib.callback(_e('server:log:getWarehouseLog'), false, function(data)
        client.sendReactMessage('ui:setLogs', data)
    end, client.inWarehouse.warehouse_index)
end

--[[ events ]]
