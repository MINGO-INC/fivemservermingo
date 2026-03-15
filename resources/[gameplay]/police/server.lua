-- police: server.lua
-- Server-side event handling for police resource

local policeOnDuty = {}

RegisterNetEvent('police:dutyChange')
AddEventHandler('police:dutyChange', function(onDuty)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    policeOnDuty[src] = onDuty
    local status     = onDuty and "ON DUTY" or "OFF DUTY"
    print(("[Police] %s (id %d) is now %s"):format(playerName, src, status))
end)

RegisterNetEvent('police:logCuff')
AddEventHandler('police:logCuff', function(targetId, cuffed)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    local action     = cuffed and "cuffed" or "uncuffed"
    print(("[Police] %s (id %d) %s player id %d"):format(playerName, src, action, targetId))
end)

RegisterNetEvent('police:logPatrolCar')
AddEventHandler('police:logPatrolCar', function(modelName)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[Police] %s (id %d) spawned patrol car: %s"):format(playerName, src, modelName))
end)

RegisterNetEvent('police:logSpike')
AddEventHandler('police:logSpike', function()
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[Police] %s (id %d) deployed a spike strip"):format(playerName, src))
end)
