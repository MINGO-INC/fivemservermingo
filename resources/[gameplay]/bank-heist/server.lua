-- bank-heist: server.lua
-- Server-side event handling for bank heist resource

local activeHeists = {}

RegisterNetEvent('bank-heist:started')
AddEventHandler('bank-heist:started', function(roleName)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    activeHeists[src] = { role = roleName, stage = 1 }
    print(("[Bank Heist] %s (id %d) started a heist as: %s"):format(playerName, src, roleName))
end)

RegisterNetEvent('bank-heist:drillComplete')
AddEventHandler('bank-heist:drillComplete', function()
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    if activeHeists[src] then activeHeists[src].stage = 2 end
    print(("[Bank Heist] %s (id %d) completed drilling"):format(playerName, src))
end)

RegisterNetEvent('bank-heist:hackComplete')
AddEventHandler('bank-heist:hackComplete', function()
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    if activeHeists[src] then activeHeists[src].stage = 3 end
    print(("[Bank Heist] %s (id %d) hacked the alarm"):format(playerName, src))
end)

RegisterNetEvent('bank-heist:complete')
AddEventHandler('bank-heist:complete', function(loot)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    activeHeists[src] = nil
    print(("[Bank Heist] %s (id %d) completed heist and collected $%d"):format(playerName, src, loot))
end)
