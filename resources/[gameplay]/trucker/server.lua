-- trucker: server.lua
-- Server-side event handling for trucker resource

local truckerOnDuty = {}

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

RegisterNetEvent('trucker:dutyChange')
AddEventHandler('trucker:dutyChange', function(onDuty)
    local src          = source
    local playerName   = GetPlayerName(src) or "unknown"
    truckerOnDuty[src] = onDuty
    local status       = onDuty and "ON DUTY" or "OFF DUTY"
    print(("[Trucker] %s (id %d) is now %s"):format(playerName, src, status))
    logActivity(src, 'trucker:dutyChange', { on_duty = onDuty })
end)

RegisterNetEvent('trucker:logLoadCargo')
AddEventHandler('trucker:logLoadCargo', function()
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[Trucker] %s (id %d) loaded cargo"):format(playerName, src))
    logActivity(src, 'trucker:logLoadCargo', {})
end)

RegisterNetEvent('trucker:logDeliverCargo')
AddEventHandler('trucker:logDeliverCargo', function()
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[Trucker] %s (id %d) delivered cargo"):format(playerName, src))
    logActivity(src, 'trucker:logDeliverCargo', {})
end)

RegisterNetEvent('trucker:logVehicle')
AddEventHandler('trucker:logVehicle', function(modelName)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[Trucker] %s (id %d) spawned truck: %s"):format(playerName, src, modelName))
    logActivity(src, 'trucker:logVehicle', { model = modelName })
end)
