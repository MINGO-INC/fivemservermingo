RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    client.onPlayerLoad(true)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    client.onPlayerLoad(false)
end)

-- Checks if the player is logged in based on local player state
---@return boolean isLoggedIn
function client.isPlayerLoaded()
    return LocalPlayer.state.isLoggedIn
end
