---@class Profile
---@field name string
---@field identifier string
---@field warehouses WarehouseDB[]

--[[ require ]]

--[[ state ]]

---@type Profile
Profile = {
    name = nil,
    identifier = nil,
    warehouses = {}
}

--[[ functions ]]

function Profile.hasInsideMeta()
    lib.callback(_e('server:warehouse:HasPlayerInsideMeta'), false, function(warehouseIndex)
        if not warehouseIndex then return end
        TriggerServerEvent(_e('server:warehouse:GetOutsideByIndex'), warehouseIndex)
    end)
end

function Profile.updateUI()
    client.sendReactMessage('ui:setPlayer', {
        identifier = Profile.identifier,
        name = Profile.name,
    })
end

function Profile.load()
    local fetchedProfile = lib.callback.await(_e('server:profile:GetPlayerProfile'), false)
    Profile.name = fetchedProfile.name
    Profile.identifier = fetchedProfile.identifier
    Profile.warehouses = fetchedProfile.warehouses
    Profile.updateUI()
end

--[[ events ]]

RegisterNetEvent(_e('client:profile:updateWarehouses'), function(warehouses)
    Profile.warehouses = warehouses
end)
