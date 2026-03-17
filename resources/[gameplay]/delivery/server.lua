-- delivery: server.lua
-- Server-side event handling for delivery resource

local deliveryOnDuty = {}

-- Log an activity event to Supabase asynchronously.
local function logActivity(src, eventType, data)
    local ok, supabase = pcall(function() return exports['supabase'] end)
    if not ok or not supabase then return end
    local playerName = GetPlayerName(src) or "unknown"
    local playerId   = nil
    local pidOk, pid = pcall(function() return exports['player-data']:getPlayerId(tostring(src)) end)
    if pidOk then playerId = pid end
    supabase:Insert('activity_logs', {
        player_id   = playerId,
        player_name = playerName,
        event_type  = eventType,
        data        = data,
    })
end

RegisterNetEvent('delivery:dutyChange')
AddEventHandler('delivery:dutyChange', function(onDuty)
    local src           = source
    local playerName    = GetPlayerName(src) or "unknown"
    deliveryOnDuty[src] = onDuty
    local status        = onDuty and "ON DUTY" or "OFF DUTY"
    print(("[Delivery] %s (id %d) is now %s"):format(playerName, src, status))
    logActivity(src, 'delivery:dutyChange', { on_duty = onDuty })
end)

RegisterNetEvent('delivery:logPickup')
AddEventHandler('delivery:logPickup', function()
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[Delivery] %s (id %d) picked up a package"):format(playerName, src))
    logActivity(src, 'delivery:logPickup', {})
end)

RegisterNetEvent('delivery:logDeliver')
AddEventHandler('delivery:logDeliver', function()
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[Delivery] %s (id %d) completed a delivery"):format(playerName, src))
    logActivity(src, 'delivery:logDeliver', {})
end)

RegisterNetEvent('delivery:logVehicle')
AddEventHandler('delivery:logVehicle', function(modelName)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[Delivery] %s (id %d) spawned vehicle: %s"):format(playerName, src, modelName))
    logActivity(src, 'delivery:logVehicle', { model = modelName })
end)
