-- bank-heist: server.lua
-- Server-side event handling for bank heist resource

local activeHeists = {}

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

RegisterNetEvent('bank-heist:started')
AddEventHandler('bank-heist:started', function(roleName)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    activeHeists[src] = { role = roleName, stage = 1 }
    print(("[Bank Heist] %s (id %d) started a heist as: %s"):format(playerName, src, roleName))
    logActivity(src, 'bank-heist:started', { role = roleName })
end)

RegisterNetEvent('bank-heist:drillComplete')
AddEventHandler('bank-heist:drillComplete', function()
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    if activeHeists[src] then activeHeists[src].stage = 2 end
    print(("[Bank Heist] %s (id %d) completed drilling"):format(playerName, src))
    logActivity(src, 'bank-heist:drillComplete', {})
end)

RegisterNetEvent('bank-heist:hackComplete')
AddEventHandler('bank-heist:hackComplete', function()
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    if activeHeists[src] then activeHeists[src].stage = 3 end
    print(("[Bank Heist] %s (id %d) hacked the alarm"):format(playerName, src))
    logActivity(src, 'bank-heist:hackComplete', {})
end)

RegisterNetEvent('bank-heist:complete')
AddEventHandler('bank-heist:complete', function(loot)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    activeHeists[src] = nil
    print(("[Bank Heist] %s (id %d) completed heist and collected $%d"):format(playerName, src, loot))
    logActivity(src, 'bank-heist:complete', { loot = loot })
end)
