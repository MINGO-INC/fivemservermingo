-- ems: server.lua
-- Server-side event handling for EMS resource

local emsOnDuty = {}

RegisterNetEvent('ems:dutyChange')
AddEventHandler('ems:dutyChange', function(onDuty)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    emsOnDuty[src]   = onDuty
    local status     = onDuty and "ON DUTY" or "OFF DUTY"
    print(("[EMS] %s (id %d) is now %s"):format(playerName, src, status))
end)

RegisterNetEvent('ems:logRevive')
AddEventHandler('ems:logRevive', function(targetId)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[EMS] %s (id %d) revived player id %d"):format(playerName, src, targetId))
end)

RegisterNetEvent('ems:logHeal')
AddEventHandler('ems:logHeal', function(targetId, amount)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[EMS] %s (id %d) healed player id %d for %d HP"):format(playerName, src, targetId, amount))
end)

RegisterNetEvent('ems:logAmbulance')
AddEventHandler('ems:logAmbulance', function()
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[EMS] %s (id %d) spawned an ambulance"):format(playerName, src))
end)
