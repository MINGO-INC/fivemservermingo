--[[ state ]]

Profile = {}

--[[ functions ]]

--[[ events ]]

lib.callback.register(_e('server:profile:GetPlayerProfile'), function(source)
    if not server.load then
        while not server.load do Citizen.Wait(1) end
    end
    
    return {
        name = server.getPlayerCharacterName(source),
        identifier = server.getPlayerIdentifier(source),
        warehouses = Warehouse.getPlayerWarehouses(source),
    }
end)
