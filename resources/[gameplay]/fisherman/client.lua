-- fisherman: client.lua
-- Commands: /fisherduty, /fish, /sellfish

-- Fisherman duty state
local fishermanOnDuty = false

-- Caught fish inventory
local fishInventory = 0

-- Active map blips (created on duty, removed off duty)
local fishermanBlips = {}

-- Fish type definitions
local FISH_TYPES = {
    { name = "bass",   label = "Bass",   value = 25  },
    { name = "trout",  label = "Trout",  value = 40  },
    { name = "salmon", label = "Salmon", value = 75  },
    { name = "tuna",   label = "Tuna",   value = 100 },
}

-- Build a quick lookup by fish name
local FISH_TYPE_BY_NAME = {}
for _, f in ipairs(FISH_TYPES) do
    FISH_TYPE_BY_NAME[f.name] = f
end

-- Fishing job sites (spots where fish can be caught or sold)
local FISH_SPOTS = {
    { label = "Vespucci Pier",  coords = vector3(-764.8,  -1415.7,  0.5)  },
    { label = "Alamo Sea",      coords = vector3(1387.9,   3607.1,  35.1) },
    { label = "Zancudo River",  coords = vector3(-2521.2,  2635.7, -1.0)  },
    { label = "Del Perro Pier", coords = vector3(-1520.9,  -733.0,  27.0) },
}

-- Add / remove map blips for fishing spots
local function setFishermanBlips(enable)
    if enable then
        for _, spot in ipairs(FISH_SPOTS) do
            local blip = AddBlipForCoord(spot.coords.x, spot.coords.y, spot.coords.z)
            SetBlipSprite(blip, 68)
            SetBlipColour(blip, 3)
            SetBlipScale(blip, 0.8)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(spot.label)
            EndTextCommandSetBlipName(blip)
            table.insert(fishermanBlips, blip)
        end
    else
        for _, blip in ipairs(fishermanBlips) do
            RemoveBlip(blip)
        end
        fishermanBlips = {}
    end
end

-- /fisherduty — toggle fisherman on-duty status
RegisterCommand("fisherduty", function(source, args, rawCommand)
    fishermanOnDuty = not fishermanOnDuty
    local status    = fishermanOnDuty and "^2ON DUTY^7" or "^1OFF DUTY^7"
    TriggerEvent("chat:addMessage", {
        color = {0, 180, 220},
        args  = {"[Fisherman]", ("You are now %s"):format(status)},
    })
    setFishermanBlips(fishermanOnDuty)
    TriggerServerEvent('fisherman:dutyChange', fishermanOnDuty)
end, false)

-- /fish — catch a random fish at a fishing spot
RegisterCommand("fish", function(source, args, rawCommand)
    if not fishermanOnDuty then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Fisherman]", "You must be on fisherman duty to fish."} })
        return
    end

    local roll     = math.random(1, #FISH_TYPES)
    local fishType = FISH_TYPES[roll]
    fishInventory  = fishInventory + 1
    TriggerEvent("chat:addMessage", {
        color = {100, 220, 100},
        args  = {"[Fisherman]", ("Caught a %s! Inventory: %d fish."):format(fishType.label, fishInventory)},
    })
    TriggerServerEvent('fisherman:logFish', fishType.name, fishType.value)
end, false)

-- /sellfish — sell all caught fish
RegisterCommand("sellfish", function(source, args, rawCommand)
    if not fishermanOnDuty then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Fisherman]", "You must be on fisherman duty to sell fish."} })
        return
    end

    if fishInventory < 1 then
        TriggerEvent("chat:addMessage", { color = {255, 165, 0}, args = {"[Fisherman]", "You have no fish to sell."} })
        return
    end

    local count   = fishInventory
    fishInventory = 0
    TriggerEvent("chat:addMessage", {
        color = {100, 220, 100},
        args  = {"[Fisherman]", ("Sold %d fish!"):format(count)},
    })
    TriggerServerEvent('fisherman:logSell', count)
end, false)
