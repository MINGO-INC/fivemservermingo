-- taxi: server.lua
-- Server-side event handling for taxi resource

local taxiOnDuty = {}

RegisterNetEvent('taxi:dutyChange')
AddEventHandler('taxi:dutyChange', function(onDuty)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    taxiOnDuty[src]  = onDuty
    local status     = onDuty and "ON DUTY" or "OFF DUTY"
    print(("[Taxi] %s (id %d) is now %s"):format(playerName, src, status))
end)

RegisterNetEvent('taxi:logFare')
AddEventHandler('taxi:logFare', function(targetId, amount)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[Taxi] %s (id %d) charged player id %d a fare of $%d"):format(playerName, src, targetId, amount))
end)

RegisterNetEvent('taxi:logTaxicab')
AddEventHandler('taxi:logTaxicab', function(modelName)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[Taxi] %s (id %d) spawned taxi: %s"):format(playerName, src, modelName))
end)
