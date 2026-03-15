-- mechanic: server.lua
-- Server-side event handling for mechanic resource

local mechanicOnDuty = {}

RegisterNetEvent('mechanic:dutyChange')
AddEventHandler('mechanic:dutyChange', function(onDuty)
    local src           = source
    local playerName    = GetPlayerName(src) or "unknown"
    mechanicOnDuty[src] = onDuty
    local status        = onDuty and "ON DUTY" or "OFF DUTY"
    print(("[Mechanic] %s (id %d) is now %s"):format(playerName, src, status))
end)

RegisterNetEvent('mechanic:logRepair')
AddEventHandler('mechanic:logRepair', function()
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[Mechanic] %s (id %d) repaired a vehicle"):format(playerName, src))
end)

RegisterNetEvent('mechanic:logTowTruck')
AddEventHandler('mechanic:logTowTruck', function()
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[Mechanic] %s (id %d) spawned a tow truck"):format(playerName, src))
end)
