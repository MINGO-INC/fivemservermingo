-- house-robbery: client.lua
-- Commands: /caseHouse, /breakIn, /lootHouse
-- Three-stage robbery: case the house → break in → loot valuables

-- Robbery state
local houseRobberyActive = false
local houseRobberyStage  = 0  -- 0=none, 1=casing, 2=breaking in, 3=looting, 4=complete

-- Houses available to rob around Los Santos
local HOUSE_LOCATIONS = {
    { name = "Vinewood Hills Mansion", x = -177.4, y = 497.9,   z = 137.5, loot = 8000  },
    { name = "Rockford Hills Estate",  x = -839.7, y = -14.9,   z = 39.7,  loot = 6000  },
    { name = "Del Perro Apartment",    x = -1279.0, y = -830.4,  z = 17.0,  loot = 2500  },
    { name = "Sandy Shores Shack",     x = 1750.5, y = 3712.6,  z = 34.3,  loot = 800   },
    { name = "Paleto Bay Cabin",       x = -300.8, y = 6289.1,  z = 31.4,  loot = 1200  },
    { name = "East LS Townhouse",      x = 380.5,  y = -1956.0, z = 24.0,  loot = 1800  },
    { name = "Morningwood Bungalow",   x = -1231.3, y = -377.6,  z = 37.9,  loot = 3500  },
    { name = "Burton Penthouse",       x = -323.2, y = 131.4,   z = 87.7,  loot = 5000  },
}

-- Currently targeted house
local currentHouse = nil

-- /caseHouse [index] — scope out a house before breaking in (default: 1)
RegisterCommand("caseHouse", function(source, args, rawCommand)
    if houseRobberyActive then
        TriggerEvent("chat:addMessage", { color = {255, 165, 0}, args = {"[House Robbery]", "You are already casing or robbing a house!"} })
        return
    end

    local idx = tonumber(args[1]) or 1
    if idx < 1 or idx > #HOUSE_LOCATIONS then
        TriggerEvent("chat:addMessage", {
            color = {255, 80, 80},
            args  = {"[House Robbery]", ("Invalid house index. Choose 1-%d."):format(#HOUSE_LOCATIONS)},
        })
        return
    end

    currentHouse       = HOUSE_LOCATIONS[idx]
    houseRobberyActive = true
    houseRobberyStage  = 1

    TriggerEvent("chat:addMessage", {
        color = {180, 140, 80},
        args  = {"[House Robbery]", ("Casing: %s. Use /breakIn when ready."):format(currentHouse.name)},
    })
    TriggerServerEvent('house-robbery:casing', currentHouse.name)
end, false)

-- /breakIn — stage 2: break into the cased house (15-second lockpick)
RegisterCommand("breakIn", function(source, args, rawCommand)
    if not houseRobberyActive or houseRobberyStage ~= 1 then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[House Robbery]", "Case a house first with /caseHouse."} })
        return
    end

    TriggerEvent("chat:addMessage", { color = {180, 140, 80}, args = {"[House Robbery]", "Breaking in... (15 seconds)"} })
    houseRobberyStage = 2

    CreateThread(function()
        Wait(15000)
        if houseRobberyActive and houseRobberyStage == 2 then
            TriggerEvent("chat:addMessage", { color = {100, 220, 100}, args = {"[House Robbery]", "Inside! Use /lootHouse to grab the valuables."} })
            TriggerServerEvent('house-robbery:breakInComplete')
        end
    end)
end, false)

-- /lootHouse — stage 3: grab the valuables from the house
RegisterCommand("lootHouse", function(source, args, rawCommand)
    if not houseRobberyActive or houseRobberyStage ~= 2 then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[House Robbery]", "Break into the house first with /breakIn."} })
        return
    end

    local loot = currentHouse and currentHouse.loot or 1000

    houseRobberyActive = false
    houseRobberyStage  = 4

    TriggerEvent("chat:addMessage", {
        color = {255, 215, 0},
        args  = {"[House Robbery]", ("You looted $%d worth of valuables! Now get out!"):format(loot)},
    })
    TriggerServerEvent('house-robbery:complete', loot)
end, false)
