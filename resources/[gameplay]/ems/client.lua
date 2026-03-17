-- ems: client.lua
-- Commands: /emsduty, /revive, /heal, /ambulance, /triage, /stretcher

-- EMS duty state
local emsOnDuty = false

-- EMS medical kit definitions
local EMS_ITEMS = {
    { name = "defibrillator", label = "Defibrillator", heal = 100, range = 3.0 },
    { name = "medkit",        label = "Med Kit",        heal = 50,  range = 5.0 },
    { name = "bandage",       label = "Bandage",        heal = 25,  range = 3.0 },
    { name = "painkillers",   label = "Painkillers",    heal = 15,  range = 2.0 },
    { name = "oxygenmask",    label = "Oxygen Mask",    heal = 30,  range = 2.0 },
    { name = "splint",        label = "Splint",         heal = 20,  range = 2.0 },
}

-- Known hospital and medical centre locations
local HOSPITAL_LOCATIONS = {
    { name = "Central Los Santos Medical",  x = 357.8,   y = -593.4,  z = 28.8  },
    { name = "Pillbox Hill Medical Centre", x = 295.8,   y = -1442.4, z = 29.9  },
    { name = "Mount Zonah Medical Center",  x = -449.6,  y = -340.1,  z = 34.5  },
    { name = "Sandy Shores Medical",        x = 1839.6,  y = 3672.9,  z = 34.3  },
    { name = "Paleto Bay Medical",          x = -246.5,  y = 6331.9,  z = 32.4  },
}

-- Triage severity levels
local TRIAGE_LEVELS = {
    { name = "critical", label = "Critical",  color = {220, 50,  50}  },
    { name = "moderate", label = "Moderate",  color = {255, 165, 0}   },
    { name = "minor",    label = "Minor",     color = {100, 220, 100} },
}

local TRIAGE_LEVEL_BY_NAME = {}
for _, t in ipairs(TRIAGE_LEVELS) do
    TRIAGE_LEVEL_BY_NAME[t.name] = t
end

-- Ambulance vehicle models available
local AMBULANCE_MODELS = {
    { model = "ambulance", label = "Ambulance"          },
    { model = "lguard",    label = "Lifeguard Vehicle"  },
}

local AMBULANCE_MODEL_BY_NAME = {}
for _, a in ipairs(AMBULANCE_MODELS) do
    AMBULANCE_MODEL_BY_NAME[a.model] = a
end

-- Ambulance vehicle model (default)
local AMBULANCE_MODEL = "ambulance"

-- Build quick lookups by name and label
local EMS_ITEM_BY_NAME  = {}
local EMS_ITEM_BY_LABEL = {}
for _, item in ipairs(EMS_ITEMS) do
    EMS_ITEM_BY_NAME[item.name]                 = item
    EMS_ITEM_BY_LABEL[string.lower(item.label)] = item
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

-- /emsduty — toggle EMS on-duty status
RegisterCommand("emsduty", function(source, args, rawCommand)
    emsOnDuty  = not emsOnDuty
    local status = emsOnDuty and "^2ON DUTY^7" or "^1OFF DUTY^7"
    TriggerEvent("chat:addMessage", {
        color = {100, 200, 255},
        args  = {"[EMS]", ("You are now %s"):format(status)},
    })
    TriggerServerEvent('ems:dutyChange', emsOnDuty)
end, false)

-- /revive — revive nearest downed player
RegisterCommand("revive", function(source, args, rawCommand)
    if not emsOnDuty then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[EMS]", "You must be on EMS duty to use this command."} })
        return
    end

    local target = getNearestPlayer(5.0)
    if not target then
        TriggerEvent("chat:addMessage", { color = {255, 165, 0}, args = {"[EMS]", "No player within revive range (5m)."} })
        return
    end

    local targetPed = GetPlayerPed(target)
    SetEntityHealth(targetPed, 200)
    TriggerEvent("chat:addMessage", { color = {100, 220, 100}, args = {"[EMS]", "Player revived."} })
    TriggerServerEvent('ems:logRevive', GetPlayerServerId(target))
end, false)

-- /heal [amount] — heal the nearest player (or self) by an amount
RegisterCommand("heal", function(source, args, rawCommand)
    if not emsOnDuty then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[EMS]", "You must be on EMS duty to use this command."} })
        return
    end

    local amount = tonumber(args[1]) or 50
    if amount < 1 or amount > 100 then
        TriggerEvent("chat:addMessage", { color = {255, 165, 0}, args = {"[EMS]", "Heal amount must be between 1 and 100."} })
        return
    end

    local target = getNearestPlayer(5.0)
    local ped    = target and GetPlayerPed(target) or PlayerPedId()
    local currentHealth = GetEntityHealth(ped)
    SetEntityHealth(ped, math.min(currentHealth + amount * 2, 200))

    TriggerEvent("chat:addMessage", {
        color = {100, 220, 100},
        args  = {"[EMS]", ("Applied %d HP of healing."):format(amount)},
    })
    TriggerServerEvent('ems:logHeal', target and GetPlayerServerId(target) or -1, amount)
end, false)

-- /ambulance — spawn an ambulance near the player
RegisterCommand("ambulance", function(source, args, rawCommand)
    if not emsOnDuty then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[EMS]", "You must be on EMS duty to spawn an ambulance."} })
        return
    end

    local hash = GetHashKey(AMBULANCE_MODEL)
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) do
        Wait(100)
        timeout = timeout + 100
        if timeout > 10000 then
            TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[EMS]", "Failed to load ambulance model."} })
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

    TriggerEvent("chat:addMessage", { color = {100, 220, 100}, args = {"[EMS]", "Ambulance spawned."} })
    TriggerServerEvent('ems:logAmbulance')
end, false)

-- /triage [level] — triage the nearest patient (critical/moderate/minor)
RegisterCommand("triage", function(source, args, rawCommand)
    if not emsOnDuty then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[EMS]", "You must be on EMS duty to triage a patient."} })
        return
    end

    local levelName = args[1] and string.lower(args[1]) or "moderate"
    local level     = TRIAGE_LEVEL_BY_NAME[levelName]
    if not level then
        TriggerEvent("chat:addMessage", {
            color = {255, 165, 0},
            args  = {"[EMS]", "Invalid triage level. Use: critical, moderate, or minor."},
        })
        return
    end

    local target = getNearestPlayer(5.0)
    if not target then
        TriggerEvent("chat:addMessage", { color = {255, 165, 0}, args = {"[EMS]", "No patient within triage range (5m)."} })
        return
    end

    TriggerEvent("chat:addMessage", {
        color = level.color,
        args  = {"[EMS]", ("Patient triaged as: %s."):format(level.label)},
    })
    TriggerServerEvent('ems:logTriage', GetPlayerServerId(target), levelName)
end, false)

-- /stretcher — place the nearest patient on a stretcher (animation)
RegisterCommand("stretcher", function(source, args, rawCommand)
    if not emsOnDuty then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[EMS]", "You must be on EMS duty to use a stretcher."} })
        return
    end

    local target = getNearestPlayer(3.0)
    if not target then
        TriggerEvent("chat:addMessage", { color = {255, 165, 0}, args = {"[EMS]", "No patient within stretcher range (3m)."} })
        return
    end

    local targetPed = GetPlayerPed(target)
    TaskPlayAnim(targetPed, "amb@medic@standing@tendtodead@idle_a", "idle_a", 8.0, -8.0, -1, 1, 0, false, false, false)

    TriggerEvent("chat:addMessage", { color = {100, 220, 100}, args = {"[EMS]", "Patient placed on stretcher."} })
    TriggerServerEvent('ems:logStretcher', GetPlayerServerId(target))
end, false)
