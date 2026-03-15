-- store-robbery: server.lua
-- Server-side event handling for store robbery resource

local activeRobberies = {}

RegisterNetEvent('store-robbery:started')
AddEventHandler('store-robbery:started', function(storeName)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    activeRobberies[src] = { store = storeName, stage = 1 }
    print(("[Store Robbery] %s (id %d) started robbing: %s"):format(playerName, src, storeName))
end)

RegisterNetEvent('store-robbery:intimidateComplete')
AddEventHandler('store-robbery:intimidateComplete', function()
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    if activeRobberies[src] then activeRobberies[src].stage = 2 end
    print(("[Store Robbery] %s (id %d) intimidated the clerk"):format(playerName, src))
end)

RegisterNetEvent('store-robbery:complete')
AddEventHandler('store-robbery:complete', function(reward)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    activeRobberies[src] = nil
    print(("[Store Robbery] %s (id %d) completed robbery and collected $%d"):format(playerName, src, reward))
end)
