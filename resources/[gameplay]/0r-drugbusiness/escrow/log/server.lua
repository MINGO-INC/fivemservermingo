--[[ require ]]

local db = require 'modules.mysql.server'

--[[ state ]]

Log = {}

local warehouseLogs = {}

--[[ functions ]]

function Log.clearOldLogs()
    db.clearOldLogs()
end

---@param warehouseIndex integer
---@param warehouseId integer
---@param text string
function Log.insert(warehouseIndex, warehouseId, text)
    if not warehouseLogs[warehouseIndex] then
        warehouseLogs[warehouseIndex] = {}
    end
    table.insert(warehouseLogs[warehouseIndex], {
        created_at = os.date(), log_message = text
    })
    db.insertLog(warehouseId, text)
end

--[[ events ]]

lib.callback.register(_e('server:log:getWarehouseLog'), function(source, warehouseIndex)
    if warehouseLogs[warehouseIndex] then return warehouseLogs[warehouseIndex] end
    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then return {} end
    local logs = db.getWarehouseLogs(warehouse.id)
    warehouseLogs[warehouseIndex] = logs or {}

    return logs or {}
end)
