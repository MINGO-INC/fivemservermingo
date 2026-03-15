-- taxi: client.lua
-- Commands: /taxiduty, /fare, /taxicab

-- Taxi duty state
local taxiOnDuty = false

-- Taxi vehicle definitions
local TAXI_VEHICLES = {
    { model = "taxi",    label = "Taxi Cab"     },
    { model = "cabby",   label = "Cabby Van"    },
    { model = "stretch", label = "Stretch Limo" },
}

-- Build a quick lookup by model name
local TAXI_VEHICLE_BY_MODEL = {}
for _, v in ipairs(TAXI_VEHICLES) do
    TAXI_VEHICLE_BY_MODEL[v.model] = v
end

-- Helper: find nearest player ped within range (returns playerId or nil)
local function getNearestPlayer(range)
    local myPed    = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local nearest, nearestDist = nil, range

    for _, playerId in ipairs(GetActivePlayers()) do
        if GetPlayerPed(playerId) ~= myPed then
            local ped  = GetPlayerPed(playerId)
            local dist = #(myCoords - GetEntityCoords(ped))
            if dist < nearestDist then
                nearest     = playerId
                nearestDist = dist
            end
        end
    end
    return nearest
end

-- /taxiduty — toggle taxi on-duty status
RegisterCommand("taxiduty", function(source, args, rawCommand)
    taxiOnDuty   = not taxiOnDuty
    local status = taxiOnDuty and "^2ON DUTY^7" or "^1OFF DUTY^7"
    TriggerEvent("chat:addMessage", {
        color = {255, 220, 0},
        args  = {"[Taxi]", ("You are now %s"):format(status)},
    })
    TriggerServerEvent('taxi:dutyChange', taxiOnDuty)
end, false)

-- /fare [amount] — charge the nearest player a fare
RegisterCommand("fare", function(source, args, rawCommand)
    if not taxiOnDuty then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Taxi]", "You must be on taxi duty to use this command."} })
        return
    end

    local amount = tonumber(args[1]) or 10
    if amount < 1 or amount > 500 then
        TriggerEvent("chat:addMessage", { color = {255, 165, 0}, args = {"[Taxi]", "Fare amount must be between 1 and 500."} })
        return
    end

    local target = getNearestPlayer(5.0)
    if not target then
        TriggerEvent("chat:addMessage", { color = {255, 165, 0}, args = {"[Taxi]", "No passenger within range (5m)."} })
        return
    end

    TriggerEvent("chat:addMessage", {
        color = {100, 220, 100},
        args  = {"[Taxi]", ("Charged $%d fare."):format(amount)},
    })
    TriggerServerEvent('taxi:logFare', GetPlayerServerId(target), amount)
end, false)

-- /taxicab [model] — spawn a taxi vehicle
RegisterCommand("taxicab", function(source, args, rawCommand)
    if not taxiOnDuty then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Taxi]", "You must be on taxi duty to spawn a taxi."} })
        return
    end

    local modelName = args[1] and string.lower(args[1]) or "taxi"
    if not TAXI_VEHICLE_BY_MODEL[modelName] then
        TriggerEvent("chat:addMessage", {
            color = {255, 165, 0},
            args  = {"[Taxi]", ("Unknown taxi vehicle '%s'. Valid models: taxi, cabby, stretch"):format(modelName)},
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
            TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Taxi]", "Failed to load vehicle model."} })
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
        args  = {"[Taxi]", ("Spawned: %s"):format(TAXI_VEHICLE_BY_MODEL[modelName].label)},
    })
    TriggerServerEvent('taxi:logTaxicab', modelName)
end, false)
