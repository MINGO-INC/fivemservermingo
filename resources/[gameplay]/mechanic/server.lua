-- mechanic: server.lua
-- Server-side event handling for mechanic resource

local mechanicOnDuty = {}

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

RegisterNetEvent('mechanic:dutyChange')
AddEventHandler('mechanic:dutyChange', function(onDuty)
    local src           = source
    local playerName    = GetPlayerName(src) or "unknown"
    mechanicOnDuty[src] = onDuty
    local status        = onDuty and "ON DUTY" or "OFF DUTY"
    print(("[Mechanic] %s (id %d) is now %s"):format(playerName, src, status))
    logActivity(src, 'mechanic:dutyChange', { on_duty = onDuty })
end)

RegisterNetEvent('mechanic:logRepair')
AddEventHandler('mechanic:logRepair', function()
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[Mechanic] %s (id %d) repaired a vehicle"):format(playerName, src))
    logActivity(src, 'mechanic:logRepair', {})
end)

RegisterNetEvent('mechanic:logTowTruck')
AddEventHandler('mechanic:logTowTruck', function()
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[Mechanic] %s (id %d) spawned a tow truck"):format(playerName, src))
    logActivity(src, 'mechanic:logTowTruck', {})
end)
