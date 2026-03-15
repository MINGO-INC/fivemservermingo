-- police: server.lua
-- Server-side event handling for police resource

local policeOnDuty = {}

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

RegisterNetEvent('police:dutyChange')
AddEventHandler('police:dutyChange', function(onDuty)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    policeOnDuty[src] = onDuty
    local status     = onDuty and "ON DUTY" or "OFF DUTY"
    print(("[Police] %s (id %d) is now %s"):format(playerName, src, status))
    logActivity(src, 'police:dutyChange', { on_duty = onDuty })
end)

RegisterNetEvent('police:logCuff')
AddEventHandler('police:logCuff', function(targetId, cuffed)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    local action     = cuffed and "cuffed" or "uncuffed"
    print(("[Police] %s (id %d) %s player id %d"):format(playerName, src, action, targetId))
    logActivity(src, 'police:logCuff', { target_id = targetId, cuffed = cuffed })
end)

RegisterNetEvent('police:logPatrolCar')
AddEventHandler('police:logPatrolCar', function(modelName)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[Police] %s (id %d) spawned patrol car: %s"):format(playerName, src, modelName))
    logActivity(src, 'police:logPatrolCar', { model = modelName })
end)

RegisterNetEvent('police:logSpike')
AddEventHandler('police:logSpike', function()
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[Police] %s (id %d) deployed a spike strip"):format(playerName, src))
    logActivity(src, 'police:logSpike', {})
end)
