-- store-robbery: server.lua
-- Server-side event handling for store robbery resource

local activeRobberies = {}

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

RegisterNetEvent('store-robbery:started')
AddEventHandler('store-robbery:started', function(storeName)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    activeRobberies[src] = { store = storeName, stage = 1 }
    print(("[Store Robbery] %s (id %d) started robbing: %s"):format(playerName, src, storeName))
    logActivity(src, 'store-robbery:started', { store = storeName })
end)

RegisterNetEvent('store-robbery:intimidateComplete')
AddEventHandler('store-robbery:intimidateComplete', function()
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    if activeRobberies[src] then activeRobberies[src].stage = 2 end
    print(("[Store Robbery] %s (id %d) intimidated the clerk"):format(playerName, src))
    logActivity(src, 'store-robbery:intimidateComplete', {})
end)

RegisterNetEvent('store-robbery:complete')
AddEventHandler('store-robbery:complete', function(reward)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    activeRobberies[src] = nil
    print(("[Store Robbery] %s (id %d) completed robbery and collected $%d"):format(playerName, src, reward))
    logActivity(src, 'store-robbery:complete', { reward = reward })
end)
