-- taxi: server.lua
-- Server-side event handling for taxi resource

local taxiOnDuty = {}

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

RegisterNetEvent('taxi:dutyChange')
AddEventHandler('taxi:dutyChange', function(onDuty)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    taxiOnDuty[src]  = onDuty
    local status     = onDuty and "ON DUTY" or "OFF DUTY"
    print(("[Taxi] %s (id %d) is now %s"):format(playerName, src, status))
    logActivity(src, 'taxi:dutyChange', { on_duty = onDuty })
end)

RegisterNetEvent('taxi:logFare')
AddEventHandler('taxi:logFare', function(targetId, amount)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[Taxi] %s (id %d) charged player id %d a fare of $%d"):format(playerName, src, targetId, amount))
    logActivity(src, 'taxi:logFare', { target_id = targetId, amount = amount })
end)

RegisterNetEvent('taxi:logTaxicab')
AddEventHandler('taxi:logTaxicab', function(modelName)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[Taxi] %s (id %d) spawned taxi: %s"):format(playerName, src, modelName))
    logActivity(src, 'taxi:logTaxicab', { model = modelName })
end)
