--[[ Main Server File]]

server = {
    framework = shared.getFrameworkObject(),
    load = false,
}

--[[ require ]]

require 'modules.bridge.server'

local Inventory = require 'modules.inventory.server'
local Utils = require 'modules.utils.server'

AddEventHandler('onResourceStart', function(resource)
    if resource ~= shared.resource then return end
    Citizen.Wait(1000)
    Warehouse.loadDatabase()
    Log.clearOldLogs()
    --[[ ok ]]
    server.load = true
end)

--[[ events ]]

---@param newBucketId integer
---@param coords vector
RegisterNetEvent(_e('server:setPlayerBucket'), function(newBucketId, coords)
    local source = source
    if newBucketId then
        SetPlayerRoutingBucket(source, newBucketId)
    end
    if coords then
        local xPlayerPed = GetPlayerPed(source)
        SetEntityCoords(xPlayerPed, coords.x, coords.y, coords.z)
        if coords.w then SetEntityHeading(xPlayerPed, coords.w) end
    end
end)
