-- trucker: client.lua
-- Commands: /truckerduty, /truckerveh, /loadcargo, /delivercargo

-- Trucker duty state
local truckerOnDuty = false

-- Active map blips (created on duty, removed off duty)
local truckerBlips = {}

-- Trucker vehicle definitions
local TRUCKER_VEHICLES = {
    { model = "hauler",  label = "Hauler"  },
    { model = "phantom", label = "Phantom" },
    { model = "mule",    label = "Mule"    },
}

-- Build a quick lookup by model name
local TRUCKER_VEHICLE_BY_MODEL = {}
for _, v in ipairs(TRUCKER_VEHICLES) do
    TRUCKER_VEHICLE_BY_MODEL[v.model] = v
end

-- Trucker job sites (cargo pickup and delivery locations)
local TRUCKER_SITES = {
    { label = "Port of LS",        coords = vector3(-170.6,  -2638.8,  6.0)  },
    { label = "Sandy Shores Yard", coords = vector3(1725.4,   3274.7,  40.7) },
    { label = "Paleto Bay Depot",  coords = vector3(-386.0,   6055.8,  31.5) },
    { label = "Del Perro Freight", coords = vector3(-482.1,  -1334.0,  33.3) },
}

-- Add / remove map blips for trucker sites
local function setTruckerBlips(enable)
    if enable then
        for _, site in ipairs(TRUCKER_SITES) do
            local blip = AddBlipForCoord(site.coords.x, site.coords.y, site.coords.z)
            SetBlipSprite(blip, 67)
            SetBlipColour(blip, 46)
            SetBlipScale(blip, 0.8)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(site.label)
            EndTextCommandSetBlipName(blip)
            table.insert(truckerBlips, blip)
        end
    else
        for _, blip in ipairs(truckerBlips) do
            RemoveBlip(blip)
        end
        truckerBlips = {}
    end
end

-- /truckerduty — toggle trucker on-duty status
RegisterCommand("truckerduty", function(source, args, rawCommand)
    truckerOnDuty = not truckerOnDuty
    local status  = truckerOnDuty and "^2ON DUTY^7" or "^1OFF DUTY^7"
    TriggerEvent("chat:addMessage", {
        color = {255, 140, 0},
        args  = {"[Trucker]", ("You are now %s"):format(status)},
    })
    setTruckerBlips(truckerOnDuty)
    TriggerServerEvent('trucker:dutyChange', truckerOnDuty)
end, false)

-- /truckerveh [model] — spawn a truck
RegisterCommand("truckerveh", function(source, args, rawCommand)
    if not truckerOnDuty then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Trucker]", "You must be on trucker duty to spawn a truck."} })
        return
    end

    local modelName = args[1] and string.lower(args[1]) or "hauler"
    if not TRUCKER_VEHICLE_BY_MODEL[modelName] then
        TriggerEvent("chat:addMessage", {
            color = {255, 165, 0},
            args  = {"[Trucker]", ("Unknown vehicle '%s'. Valid models: hauler, phantom, mule"):format(modelName)},
        })
        return
    end

    local hash = GetHashKey(modelName)
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) do
        Wait(100)
        timeout = timeout + 100
        if timeout > 10000 then
            TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Trucker]", "Failed to load vehicle model."} })
            return
        end
    end

    local ped     = PlayerPedId()
    local coords  = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local veh = CreateVehicle(hash, coords.x + 5.0, coords.y, coords.z, heading, true, false)
    SetVehicleOnGroundProperly(veh)
    SetVehicleBodyHealth(veh, 1000.0)
    SetVehicleEngineHealth(veh, 1000.0)
    SetModelAsNoLongerNeeded(hash)

    TriggerEvent("chat:addMessage", {
        color = {100, 220, 100},
        args  = {"[Trucker]", ("Spawned: %s"):format(TRUCKER_VEHICLE_BY_MODEL[modelName].label)},
    })
    TriggerServerEvent('trucker:logVehicle', modelName)
end, false)

-- /loadcargo — log loading cargo at a freight site
RegisterCommand("loadcargo", function(source, args, rawCommand)
    if not truckerOnDuty then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Trucker]", "You must be on trucker duty to load cargo."} })
        return
    end
    TriggerEvent("chat:addMessage", { color = {100, 220, 100}, args = {"[Trucker]", "Cargo loaded. Drive to the delivery site."} })
    TriggerServerEvent('trucker:logLoadCargo')
end, false)

-- /delivercargo — log delivering cargo at the destination
RegisterCommand("delivercargo", function(source, args, rawCommand)
    if not truckerOnDuty then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Trucker]", "You must be on trucker duty to deliver cargo."} })
        return
    end
    TriggerEvent("chat:addMessage", { color = {100, 220, 100}, args = {"[Trucker]", "Cargo delivered! Nice work."} })
    TriggerServerEvent('trucker:logDeliverCargo')
end, false)
