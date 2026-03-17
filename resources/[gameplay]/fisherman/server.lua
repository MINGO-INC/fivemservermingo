-- fisherman: server.lua
-- Server-side event handling for fisherman resource

local fishermanOnDuty = {}

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

RegisterNetEvent('fisherman:dutyChange')
AddEventHandler('fisherman:dutyChange', function(onDuty)
    local src            = source
    local playerName     = GetPlayerName(src) or "unknown"
    fishermanOnDuty[src] = onDuty
    local status         = onDuty and "ON DUTY" or "OFF DUTY"
    print(("[Fisherman] %s (id %d) is now %s"):format(playerName, src, status))
    logActivity(src, 'fisherman:dutyChange', { on_duty = onDuty })
end)

RegisterNetEvent('fisherman:logFish')
AddEventHandler('fisherman:logFish', function(fishName, fishValue)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[Fisherman] %s (id %d) caught a %s (value: $%d)"):format(playerName, src, fishName, fishValue))
    logActivity(src, 'fisherman:logFish', { fish = fishName, value = fishValue })
end)

RegisterNetEvent('fisherman:logSell')
AddEventHandler('fisherman:logSell', function(count)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[Fisherman] %s (id %d) sold %d fish"):format(playerName, src, count))
    logActivity(src, 'fisherman:logSell', { count = count })
end)
