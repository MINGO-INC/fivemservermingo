-- car-spawner: server.lua
-- Server-side logging for vehicle spawn events.

-- Log vehicle spawns for server admins
RegisterNetEvent('car-spawner:logSpawn')
AddEventHandler('car-spawner:logSpawn', function(modelName)
    local src = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[car-spawner] %s (id %d) spawned: %s"):format(playerName, src, modelName))
end)
