-- ems: server.lua
-- Server-side event handling for EMS resource

local emsOnDuty = {}

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

RegisterNetEvent('ems:dutyChange')
AddEventHandler('ems:dutyChange', function(onDuty)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    emsOnDuty[src]   = onDuty
    local status     = onDuty and "ON DUTY" or "OFF DUTY"
    print(("[EMS] %s (id %d) is now %s"):format(playerName, src, status))
    logActivity(src, 'ems:dutyChange', { on_duty = onDuty })
end)

RegisterNetEvent('ems:logRevive')
AddEventHandler('ems:logRevive', function(targetId)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[EMS] %s (id %d) revived player id %d"):format(playerName, src, targetId))
    logActivity(src, 'ems:logRevive', { target_id = targetId })
end)

RegisterNetEvent('ems:logHeal')
AddEventHandler('ems:logHeal', function(targetId, amount)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[EMS] %s (id %d) healed player id %d for %d HP"):format(playerName, src, targetId, amount))
    logActivity(src, 'ems:logHeal', { target_id = targetId, amount = amount })
end)

RegisterNetEvent('ems:logAmbulance')
AddEventHandler('ems:logAmbulance', function()
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[EMS] %s (id %d) spawned an ambulance"):format(playerName, src))
    logActivity(src, 'ems:logAmbulance', {})
end)

RegisterNetEvent('ems:logTriage')
AddEventHandler('ems:logTriage', function(targetId, level)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[EMS] %s (id %d) triaged player id %d as %s"):format(playerName, src, targetId, level))
    logActivity(src, 'ems:logTriage', { target_id = targetId, level = level })
end)

RegisterNetEvent('ems:logStretcher')
AddEventHandler('ems:logStretcher', function(targetId)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[EMS] %s (id %d) placed player id %d on a stretcher"):format(playerName, src, targetId))
    logActivity(src, 'ems:logStretcher', { target_id = targetId })
end)
