-- delivery: client.lua
-- Commands: /deliveryduty, /deliveryveh, /pickup, /deliver

-- Delivery duty state
local deliveryOnDuty = false

-- Active map blips (created on duty, removed off duty)
local deliveryBlips = {}

-- Delivery vehicle definitions
local DELIVERY_VEHICLES = {
    { model = "boxville", label = "Box Ville" },
    { model = "mule",     label = "Mule"      },
    { model = "speedo",   label = "Speedo"    },
}

-- Build a quick lookup by model name
local DELIVERY_VEHICLE_BY_MODEL = {}
for _, v in ipairs(DELIVERY_VEHICLES) do
    DELIVERY_VEHICLE_BY_MODEL[v.model] = v
end

-- Delivery job sites (package pickup and drop-off locations)
local DELIVERY_SITES = {
    { label = "Airport Cargo",    coords = vector3(-1066.7, -3174.5, 13.8) },
    { label = "Downtown Depot",   coords = vector3(96.9,    -1803.4, 29.5) },
    { label = "Vinewood Post",    coords = vector3(-401.0,  -930.5,  29.7) },
    { label = "Strawberry Depot", coords = vector3(-701.7,  -956.4,  19.2) },
}

-- Add / remove map blips for delivery sites
local function setDeliveryBlips(enable)
    if enable then
        for _, site in ipairs(DELIVERY_SITES) do
            local blip = AddBlipForCoord(site.coords.x, site.coords.y, site.coords.z)
            SetBlipSprite(blip, 478)
            SetBlipColour(blip, 5)
            SetBlipScale(blip, 0.8)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(site.label)
            EndTextCommandSetBlipName(blip)
            table.insert(deliveryBlips, blip)
        end
    else
        for _, blip in ipairs(deliveryBlips) do
            RemoveBlip(blip)
        end
        deliveryBlips = {}
    end
end

-- /deliveryduty — toggle delivery on-duty status
RegisterCommand("deliveryduty", function(source, args, rawCommand)
    deliveryOnDuty = not deliveryOnDuty
    local status   = deliveryOnDuty and "^2ON DUTY^7" or "^1OFF DUTY^7"
    TriggerEvent("chat:addMessage", {
        color = {255, 200, 0},
        args  = {"[Delivery]", ("You are now %s"):format(status)},
    })
    setDeliveryBlips(deliveryOnDuty)
    TriggerServerEvent('delivery:dutyChange', deliveryOnDuty)
end, false)

-- /deliveryveh [model] — spawn a delivery vehicle
RegisterCommand("deliveryveh", function(source, args, rawCommand)
    if not deliveryOnDuty then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Delivery]", "You must be on delivery duty to spawn a vehicle."} })
        return
    end

    local modelName = args[1] and string.lower(args[1]) or "boxville"
    if not DELIVERY_VEHICLE_BY_MODEL[modelName] then
        TriggerEvent("chat:addMessage", {
            color = {255, 165, 0},
            args  = {"[Delivery]", ("Unknown vehicle '%s'. Valid models: boxville, mule, speedo"):format(modelName)},
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
            TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Delivery]", "Failed to load vehicle model."} })
            return
        end
    end

    local ped     = PlayerPedId()
    local coords  = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local veh = CreateVehicle(hash, coords.x + 3.0, coords.y, coords.z, heading, true, false)
    SetVehicleOnGroundProperly(veh)
    SetVehicleBodyHealth(veh, 1000.0)
    SetVehicleEngineHealth(veh, 1000.0)
    SetModelAsNoLongerNeeded(hash)

    TriggerEvent("chat:addMessage", {
        color = {100, 220, 100},
        args  = {"[Delivery]", ("Spawned: %s"):format(DELIVERY_VEHICLE_BY_MODEL[modelName].label)},
    })
    TriggerServerEvent('delivery:logVehicle', modelName)
end, false)

-- /pickup — log picking up a delivery package
RegisterCommand("pickup", function(source, args, rawCommand)
    if not deliveryOnDuty then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Delivery]", "You must be on delivery duty to pick up packages."} })
        return
    end
    TriggerEvent("chat:addMessage", { color = {100, 220, 100}, args = {"[Delivery]", "Package picked up. Deliver it to the next site."} })
    TriggerServerEvent('delivery:logPickup')
end, false)

-- /deliver — log completing a delivery
RegisterCommand("deliver", function(source, args, rawCommand)
    if not deliveryOnDuty then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Delivery]", "You must be on delivery duty to complete a delivery."} })
        return
    end
    TriggerEvent("chat:addMessage", { color = {100, 220, 100}, args = {"[Delivery]", "Delivery complete! Good work."} })
    TriggerServerEvent('delivery:logDeliver')
end, false)
