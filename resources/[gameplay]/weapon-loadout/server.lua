-- weapon-loadout: server.lua
-- Server-side logging for weapon events.

RegisterNetEvent('weapon-loadout:logLoadout')
AddEventHandler('weapon-loadout:logLoadout', function()
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[weapon-loadout] %s (id %d) received a full weapon loadout."):format(playerName, src))
end)

RegisterNetEvent('weapon-loadout:logGun')
AddEventHandler('weapon-loadout:logGun', function(weaponName)
    local src        = source
    local playerName = GetPlayerName(src) or "unknown"
    print(("[weapon-loadout] %s (id %d) received weapon: %s"):format(playerName, src, weaponName))
end)
