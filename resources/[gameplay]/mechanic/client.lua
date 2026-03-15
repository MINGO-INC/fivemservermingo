-- mechanic: client.lua
-- Commands: /mechanicduty, /repairvehicle, /towtruck

-- Mechanic duty state
local mechanicOnDuty = false

-- Mechanic repair tool definitions
local MECHANIC_TOOLS = {
    { name = "toolbox",  label = "Toolbox",        repairAmount = 500.0, range = 5.0 },
    { name = "jack",     label = "Hydraulic Jack",  repairAmount = 250.0, range = 3.0 },
    { name = "wrench",   label = "Wrench",          repairAmount = 100.0, range = 2.0 },
}

-- Build a quick lookup by tool name
local MECHANIC_TOOL_BY_NAME = {}
for _, t in ipairs(MECHANIC_TOOLS) do
    MECHANIC_TOOL_BY_NAME[t.name] = t
end

-- Tow truck vehicle model
local TOWTRUCK_MODEL = "towtruck"

-- Helper: find the nearest vehicle within range (returns vehicle handle or nil)
local function getNearestVehicle(range)
    local myPed    = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local nearest, nearestDist = nil, range

    local veh = GetVehiclePedIsIn(myPed, false)
    if veh ~= 0 then
        return veh
    end

    local veh2 = GetClosestVehicle(myCoords.x, myCoords.y, myCoords.z, range, 0, 70)
    if DoesEntityExist(veh2) then
        nearest = veh2
    end
    return nearest
end

-- /mechanicduty — toggle mechanic on-duty status
RegisterCommand("mechanicduty", function(source, args, rawCommand)
    mechanicOnDuty = not mechanicOnDuty
    local status   = mechanicOnDuty and "^2ON DUTY^7" or "^1OFF DUTY^7"
    TriggerEvent("chat:addMessage", {
        color = {200, 140, 0},
        args  = {"[Mechanic]", ("You are now %s"):format(status)},
    })
    TriggerServerEvent('mechanic:dutyChange', mechanicOnDuty)
end, false)

-- /repairvehicle — repair the nearest or occupied vehicle
RegisterCommand("repairvehicle", function(source, args, rawCommand)
    if not mechanicOnDuty then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Mechanic]", "You must be on mechanic duty to use this command."} })
        return
    end

    local veh = getNearestVehicle(5.0)
    if not veh then
        TriggerEvent("chat:addMessage", { color = {255, 165, 0}, args = {"[Mechanic]", "No vehicle within repair range (5m)."} })
        return
    end

    SetVehicleBodyHealth(veh, 1000.0)
    SetVehicleEngineHealth(veh, 1000.0)
    SetVehicleFixed(veh)

    TriggerEvent("chat:addMessage", { color = {100, 220, 100}, args = {"[Mechanic]", "Vehicle repaired."} })
    TriggerServerEvent('mechanic:logRepair')
end, false)

-- /towtruck — spawn a tow truck
RegisterCommand("towtruck", function(source, args, rawCommand)
    if not mechanicOnDuty then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Mechanic]", "You must be on mechanic duty to spawn a tow truck."} })
        return
    end

    local hash = GetHashKey(TOWTRUCK_MODEL)
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) do
        Wait(100)
        timeout = timeout + 100
        if timeout > 10000 then
            TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Mechanic]", "Failed to load tow truck model."} })
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

    TriggerEvent("chat:addMessage", { color = {100, 220, 100}, args = {"[Mechanic]", "Tow truck spawned."} })
    TriggerServerEvent('mechanic:logTowTruck')
end, false)
