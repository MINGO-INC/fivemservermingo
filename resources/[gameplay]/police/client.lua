-- police: client.lua
-- Commands: /policeduty, /cuff, /uncuff, /patrolcar, /spike

-- Police duty state
local policeOnDuty  = false
local cuffedPlayers = {}

-- Curated list of available police vehicles
local POLICE_VEHICLES = {
    { model = "police",   label = "Police Cruiser"     },
    { model = "police2",  label = "Police Buffalo"     },
    { model = "police3",  label = "Police Interceptor" },
    { model = "policeb",  label = "Police Bike"        },
    { model = "fbi",      label = "FBI SUV"            },
    { model = "fbi2",     label = "FBI Tactical"       },
    { model = "sheriff",  label = "Sheriff Cruiser"    },
    { model = "sheriff2", label = "Sheriff SUV"        },
}

-- Build a quick lookup by model name
local POLICE_VEHICLE_BY_MODEL = {}
for _, v in ipairs(POLICE_VEHICLES) do
    POLICE_VEHICLE_BY_MODEL[v.model] = v
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

-- /policeduty — toggle police on-duty status
RegisterCommand("policeduty", function(source, args, rawCommand)
    policeOnDuty = not policeOnDuty
    local status = policeOnDuty and "^2ON DUTY^7" or "^1OFF DUTY^7"
    TriggerEvent("chat:addMessage", {
        color = {0, 100, 255},
        args  = {"[Police]", ("You are now %s"):format(status)},
    })
    TriggerServerEvent('police:dutyChange', policeOnDuty)
end, false)

-- /cuff — cuff the nearest player
RegisterCommand("cuff", function(source, args, rawCommand)
    if not policeOnDuty then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Police]", "You must be on police duty to use this command."} })
        return
    end

    local target = getNearestPlayer(3.0)
    if not target then
        TriggerEvent("chat:addMessage", { color = {255, 165, 0}, args = {"[Police]", "No player within cuff range (3m)."} })
        return
    end
    if cuffedPlayers[target] then
        TriggerEvent("chat:addMessage", { color = {255, 165, 0}, args = {"[Police]", "That player is already cuffed."} })
        return
    end

    cuffedPlayers[target] = true
    local targetPed = GetPlayerPed(target)
    SetPedCanRagdoll(targetPed, false)
    TaskPlayAnim(targetPed, "mp_arresting", "idle", 8.0, -8.0, -1, 49, 0, false, false, false)

    TriggerEvent("chat:addMessage", { color = {100, 220, 100}, args = {"[Police]", "Player cuffed."} })
    TriggerServerEvent('police:logCuff', GetPlayerServerId(target), true)
end, false)

-- /uncuff — uncuff the nearest cuffed player
RegisterCommand("uncuff", function(source, args, rawCommand)
    if not policeOnDuty then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Police]", "You must be on police duty to use this command."} })
        return
    end

    local target = getNearestPlayer(3.0)
    if not target then
        TriggerEvent("chat:addMessage", { color = {255, 165, 0}, args = {"[Police]", "No player within uncuff range (3m)."} })
        return
    end
    if not cuffedPlayers[target] then
        TriggerEvent("chat:addMessage", { color = {255, 165, 0}, args = {"[Police]", "That player is not cuffed."} })
        return
    end

    cuffedPlayers[target] = nil
    local targetPed = GetPlayerPed(target)
    SetPedCanRagdoll(targetPed, true)
    ClearPedTasks(targetPed)

    TriggerEvent("chat:addMessage", { color = {100, 220, 100}, args = {"[Police]", "Player uncuffed."} })
    TriggerServerEvent('police:logCuff', GetPlayerServerId(target), false)
end, false)

-- /patrolcar [model] — spawn a police patrol vehicle
RegisterCommand("patrolcar", function(source, args, rawCommand)
    if not policeOnDuty then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Police]", "You must be on police duty to spawn a patrol car."} })
        return
    end

    local modelName = args[1] and string.lower(args[1]) or "police"
    if not POLICE_VEHICLE_BY_MODEL[modelName] then
        TriggerEvent("chat:addMessage", {
            color = {255, 165, 0},
            args  = {"[Police]", ("Unknown police vehicle '%s'. Valid models: police, police2, police3, policeb, fbi, fbi2, sheriff, sheriff2"):format(modelName)},
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
            TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Police]", "Failed to load vehicle model."} })
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
        args  = {"[Police]", ("Spawned: %s"):format(POLICE_VEHICLE_BY_MODEL[modelName].label)},
    })
    TriggerServerEvent('police:logPatrolCar', modelName)
end, false)

-- /spike — deploy a spike strip in front of the player
RegisterCommand("spike", function(source, args, rawCommand)
    if not policeOnDuty then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Police]", "You must be on police duty to deploy spikes."} })
        return
    end

    local ped     = PlayerPedId()
    local coords  = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local fwd     = GetEntityForwardVector(ped)
    local spawnX  = coords.x + fwd.x * 4.0
    local spawnY  = coords.y + fwd.y * 4.0

    local obj = CreateObject(GetHashKey("p_ld_stinger_s"), spawnX, spawnY, coords.z, true, true, false)
    SetEntityRotation(obj, 0.0, 0.0, heading, 2, true)
    PlaceObjectOnGroundProperly(obj)

    TriggerEvent("chat:addMessage", { color = {100, 220, 100}, args = {"[Police]", "Spike strip deployed."} })
    TriggerServerEvent('police:logSpike')
end, false)
