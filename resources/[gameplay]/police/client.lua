-- police: client.lua
-- Commands: /policeduty, /cuff, /uncuff, /patrolcar, /spike, /fine, /search, /backup

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
    { model = "polmav",   label = "Police Maverick"    },
    { model = "riot",     label = "Riot Van"           },
    { model = "prison",   label = "Prison Bus"         },
}

-- Known police patrol zones around Los Santos
local POLICE_PATROL_ZONES = {
    { name = "LSPD Mission Row",    x = 441.1,   y = -982.0,  z = 30.7  },
    { name = "LSPD Vinewood Hills", x = -448.6,  y = 601.3,   z = 88.7  },
    { name = "Sandy Shores Sheriff",x = 1853.0,  y = 3686.2,  z = 34.3  },
    { name = "Paleto Bay Sheriff",  x = -448.2,  y = 6008.4,  z = 31.7  },
    { name = "Davis Police Post",   x = 366.9,   y = -1611.2, z = 29.3  },
    { name = "Airport Security",    x = -1096.1, y = -2715.4, z = 13.8  },
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

-- /fine [amount] — issue a monetary fine to the nearest player
RegisterCommand("fine", function(source, args, rawCommand)
    if not policeOnDuty then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Police]", "You must be on police duty to issue a fine."} })
        return
    end

    local amount = tonumber(args[1]) or 500
    if amount < 1 then
        TriggerEvent("chat:addMessage", { color = {255, 165, 0}, args = {"[Police]", "Fine amount must be at least $1."} })
        return
    end

    local target = getNearestPlayer(5.0)
    if not target then
        TriggerEvent("chat:addMessage", { color = {255, 165, 0}, args = {"[Police]", "No player within range (5m) to fine."} })
        return
    end

    TriggerEvent("chat:addMessage", {
        color = {100, 220, 100},
        args  = {"[Police]", ("Issued a $%d fine."):format(amount)},
    })
    TriggerServerEvent('police:logFine', GetPlayerServerId(target), amount)
end, false)

-- /search — search the nearest player for contraband
RegisterCommand("search", function(source, args, rawCommand)
    if not policeOnDuty then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Police]", "You must be on police duty to search a player."} })
        return
    end

    local target = getNearestPlayer(3.0)
    if not target then
        TriggerEvent("chat:addMessage", { color = {255, 165, 0}, args = {"[Police]", "No player within search range (3m)."} })
        return
    end

    local contraband = { "drugs", "illegal weapon", "stolen goods", "nothing" }
    local found      = contraband[math.random(#contraband)]

    TriggerEvent("chat:addMessage", {
        color = {100, 220, 100},
        args  = {"[Police]", ("Search complete — found: %s."):format(found)},
    })
    TriggerServerEvent('police:logSearch', GetPlayerServerId(target), found)
end, false)

-- /backup — broadcast an officer backup request
RegisterCommand("backup", function(source, args, rawCommand)
    if not policeOnDuty then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Police]", "You must be on police duty to call for backup."} })
        return
    end

    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)

    TriggerEvent("chat:addMessage", {
        color = {255, 100, 0},
        args  = {"[Police]", ("BACKUP REQUESTED at %.1f, %.1f!"):format(coords.x, coords.y)},
    })
    TriggerServerEvent('police:logBackup', coords.x, coords.y, coords.z)
end, false)
