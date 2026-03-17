-- house-robbery: server.lua
-- Server-side event handling for house robbery resource

local activeHouseRobberies = {}

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

RegisterNetEvent('house-robbery:casing')
AddEventHandler('house-robbery:casing', function(houseName)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    activeHouseRobberies[src] = { house = houseName, stage = 1 }
    print(("[House Robbery] %s (id %d) is casing: %s"):format(playerName, src, houseName))
    logActivity(src, 'house-robbery:casing', { house = houseName })
end)

RegisterNetEvent('house-robbery:breakInComplete')
AddEventHandler('house-robbery:breakInComplete', function()
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    if activeHouseRobberies[src] then activeHouseRobberies[src].stage = 2 end
    print(("[House Robbery] %s (id %d) broke into the house"):format(playerName, src))
    logActivity(src, 'house-robbery:breakInComplete', {})
end)

RegisterNetEvent('house-robbery:complete')
AddEventHandler('house-robbery:complete', function(loot)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    activeHouseRobberies[src] = nil
    print(("[House Robbery] %s (id %d) looted $%d"):format(playerName, src, loot))
    logActivity(src, 'house-robbery:complete', { loot = loot })
end)
