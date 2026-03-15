-- bank-heist: client.lua
-- Commands: /startbankheist, /drillbank, /hackbank, /grabcash
-- Three-stage heist: drill the vault → hack the alarm → grab the cash

-- Heist state
local heistActive = false
local heistStage  = 0  -- 0=none, 1=drilling, 2=hacking, 3=grabbing, 4=complete

-- Known bank locations
local BANK_LOCATIONS = {
    { name = "Fleeca Bank",      x = 149.3,  y = -1044.2, z = 29.4  },
    { name = "Pacific Standard", x = 247.4,  y = 224.8,   z = 106.3 },
    { name = "Blaine County",    x = -99.5,  y = 6213.5,  z = 31.4  },
    { name = "Union Depository", x = 243.0,  y = 215.0,   z = 106.3 },
}

-- Heist crew roles and their loot multipliers
local HEIST_ROLES = {
    { name = "hacker",      label = "Hacker",      bonus = 1.30 },
    { name = "driller",     label = "Driller",     bonus = 1.20 },
    { name = "gunman",      label = "Gunman",      bonus = 1.10 },
    { name = "driver",      label = "Driver",       bonus = 1.15 },
    { name = "coordinator", label = "Coordinator", bonus = 1.25 },
}

-- Build quick lookups by name and label
local HEIST_ROLE_BY_NAME  = {}
local HEIST_ROLE_BY_LABEL = {}
for _, role in ipairs(HEIST_ROLES) do
    HEIST_ROLE_BY_NAME[role.name]                  = role
    HEIST_ROLE_BY_LABEL[string.lower(role.label)]  = role
end

-- Base loot value before role bonus is applied
local HEIST_LOOT_BASE = 50000

-- Currently active role
local currentRole = nil

-- /startbankheist [role] — kick off a bank heist and pick a role
RegisterCommand("startbankheist", function(source, args, rawCommand)
    if heistActive then
        TriggerEvent("chat:addMessage", { color = {255, 165, 0}, args = {"[Heist]", "A bank heist is already in progress."} })
        return
    end

    local roleName = args[1] and string.lower(args[1]) or "gunman"
    if not HEIST_ROLE_BY_NAME[roleName] then
        TriggerEvent("chat:addMessage", {
            color = {255, 80, 80},
            args  = {"[Heist]", ("Unknown role '%s'. Valid roles: hacker, driller, gunman, driver, coordinator"):format(roleName)},
        })
        return
    end

    currentRole = HEIST_ROLE_BY_NAME[roleName]
    heistActive = true
    heistStage  = 1

    TriggerEvent("chat:addMessage", {
        color = {255, 215, 0},
        args  = {"[Heist]", ("Bank heist started! Role: %s. Use /drillbank to begin."):format(currentRole.label)},
    })
    TriggerServerEvent('bank-heist:started', roleName)
end, false)

-- /drillbank — stage 1: drill the vault door
RegisterCommand("drillbank", function(source, args, rawCommand)
    if not heistActive or heistStage ~= 1 then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Heist]", "Start a bank heist first with /startbankheist."} })
        return
    end

    TriggerEvent("chat:addMessage", { color = {255, 215, 0}, args = {"[Heist]", "Drilling vault door... (10 seconds)"} })
    heistStage = 2

    CreateThread(function()
        Wait(10000)
        if heistActive and heistStage == 2 then
            TriggerEvent("chat:addMessage", { color = {100, 220, 100}, args = {"[Heist]", "Vault drilled! Use /hackbank to bypass the alarm."} })
            TriggerServerEvent('bank-heist:drillComplete')
        end
    end)
end, false)

-- /hackbank — stage 2: hack the alarm system
RegisterCommand("hackbank", function(source, args, rawCommand)
    if not heistActive or heistStage ~= 2 then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Heist]", "Drill the vault first with /drillbank."} })
        return
    end

    TriggerEvent("chat:addMessage", { color = {255, 215, 0}, args = {"[Heist]", "Hacking alarm system... (8 seconds)"} })
    heistStage = 3

    CreateThread(function()
        Wait(8000)
        if heistActive and heistStage == 3 then
            TriggerEvent("chat:addMessage", { color = {100, 220, 100}, args = {"[Heist]", "Alarm bypassed! Use /grabcash to collect the loot."} })
            TriggerServerEvent('bank-heist:hackComplete')
        end
    end)
end, false)

-- /grabcash — stage 3: collect the cash from the vault
RegisterCommand("grabcash", function(source, args, rawCommand)
    if not heistActive or heistStage ~= 3 then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[Heist]", "Hack the alarm first with /hackbank."} })
        return
    end

    local bonus = currentRole and currentRole.bonus or 1.0
    local loot  = math.floor(HEIST_LOOT_BASE * bonus)

    heistActive = false
    heistStage  = 4

    TriggerEvent("chat:addMessage", {
        color = {255, 215, 0},
        args  = {"[Heist]", ("Heist complete! You collected $%d!"):format(loot)},
    })
    TriggerServerEvent('bank-heist:complete', loot)
end, false)
