-- car-spawner: server.lua
-- Server-side logging for vehicle spawn events.

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

-- Log vehicle spawns for server admins
RegisterNetEvent('car-spawner:logSpawn')
AddEventHandler('car-spawner:logSpawn', function(modelName)
    local src = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[car-spawner] %s (id %d) spawned: %s"):format(playerName, src, modelName))
    logActivity(src, 'car-spawner:logSpawn', { model = modelName })
end)
