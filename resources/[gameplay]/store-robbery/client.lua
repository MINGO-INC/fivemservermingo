-- store-robbery: client.lua
-- Commands: /robstore, /intimidate, /cashout
-- Two-stage robbery: intimidate the clerk to 100% → cash out

-- Robbery state
local robberyActive  = false
local robberyStage   = 0    -- 0=none, 1=intimidating, 2=looting, 3=complete
local intimidateLevel = 0.0

-- Convenience stores available to rob
local STORE_LOCATIONS = {
    { name = "24/7 Vespucci",  x = -706.3,  y = -906.2,  z = 19.2,  reward = 800  },
    { name = "24/7 Downtown",  x = 24.8,    y = -1346.9, z = 29.5,  reward = 1000 },
    { name = "Rob's Liquor",   x = -2966.2, y = 385.7,   z = 14.7,  reward = 600  },
    { name = "Discount Store", x = 1161.3,  y = -322.6,  z = 69.2,  reward = 750  },
    { name = "Dream On Drugs", x = -1830.0, y = 795.7,   z = 138.4, reward = 900  },
}

-- Weapons usable to intimidate (informational — determines fear-gain multiplier)
local ROBBERY_TOOLS = {
    { name = "pistol",       label = "Pistol",        intimidate = 0.60 },
    { name = "smg",          label = "SMG",           intimidate = 0.80 },
    { name = "assaultrifle", label = "Assault Rifle", intimidate = 1.00 },
    { name = "knife",        label = "Knife",         intimidate = 0.40 },
    { name = "bat",          label = "Baseball Bat",  intimidate = 0.30 },
}

-- Build quick lookups by name and label
local ROBBERY_TOOL_BY_NAME  = {}
local ROBBERY_TOOL_BY_LABEL = {}
for _, tool in ipairs(ROBBERY_TOOLS) do
    ROBBERY_TOOL_BY_NAME[tool.name]                 = tool
    ROBBERY_TOOL_BY_LABEL[string.lower(tool.label)] = tool
end

-- Currently targeted store
local currentStore = nil

-- /robstore [index] — start robbing the store at the given index (default: 1)
RegisterCommand("robstore", function(source, args, rawCommand)
    if robberyActive then
        TriggerEvent("chat:addMessage", { color = {255, 165, 0}, args = {"[Robbery]", "You are already robbing a store!"} })
        return
    end

    local idx = tonumber(args[1]) or 1
    if idx < 1 or idx > #STORE_LOCATIONS then
        TriggerEvent("chat:addMessage", {
            color = {255, 80, 80},
            args  = {"[Robbery]", ("Invalid store index. Choose 1-%d."):format(#STORE_LOCATIONS)},
        })
        return
    end

    currentStore   = STORE_LOCATIONS[idx]
    robberyActive  = true
    robberyStage   = 1
    intimidateLevel = 0.0

    TriggerEvent("chat:addMessage", {
        color = {255, 140, 0},
        args  = {"[Robbery]", ("Robbing: %s. Use /intimidate to frighten the clerk."):format(currentStore.name)},
    })
    TriggerServerEvent('store-robbery:started', currentStore.name)
end, false)

-- /intimidate — raise the clerk's fear level by 25% each use
RegisterCommand("intimidate", function(source, args, rawCommand)
    if not robberyActive or robberyStage ~= 1 then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Robbery]", "Start a store robbery first with /robstore."} })
        return
    end

    intimidateLevel = math.min(intimidateLevel + 0.25, 1.0)

    TriggerEvent("chat:addMessage", {
        color = {255, 140, 0},
        args  = {"[Robbery]", ("Clerk fear level: %d%%"):format(math.floor(intimidateLevel * 100))},
    })

    if intimidateLevel >= 1.0 then
        robberyStage = 2
        TriggerEvent("chat:addMessage", { color = {100, 220, 100}, args = {"[Robbery]", "Clerk fully intimidated! Use /cashout to grab the money."} })
        TriggerServerEvent('store-robbery:intimidateComplete')
    end
end, false)

-- /cashout — grab the cash from the register (only after full intimidation)
RegisterCommand("cashout", function(source, args, rawCommand)
    if not robberyActive or robberyStage ~= 2 then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Robbery]", "Intimidate the clerk first with /intimidate."} })
        return
    end

    local reward = currentStore and currentStore.reward or 500

    robberyActive = false
    robberyStage  = 3

    TriggerEvent("chat:addMessage", {
        color = {255, 215, 0},
        args  = {"[Robbery]", ("You grabbed $%d from the register! Get out!"):format(reward)},
    })
    TriggerServerEvent('store-robbery:complete', reward)
end, false)
