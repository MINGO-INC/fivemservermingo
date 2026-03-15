-- weapon-loadout: client.lua
-- Commands: /weapons (full loadout), /gun <weapon> (single weapon), /guns (list)
-- Features: per-weapon recoil applied via camera shake on fire

-- ─── Weapon definitions ───────────────────────────────────────────────────────
-- Each entry:  { hash_name, ammo, recoil_strength, recoil_shake }
--   recoil_strength : float applied to SetCamShakeAmplitude
--   recoil_shake    : shake type string
local WEAPONS = {
    -- Pistols (light recoil)
    { name = "WEAPON_PISTOL",           label = "Pistol",            ammo = 250,  recoil = 0.15, shake = "HAND_SHAKE" },
    { name = "WEAPON_PISTOL_MK2",       label = "Pistol Mk II",      ammo = 250,  recoil = 0.18, shake = "HAND_SHAKE" },
    { name = "WEAPON_COMBATPISTOL",     label = "Combat Pistol",     ammo = 250,  recoil = 0.16, shake = "HAND_SHAKE" },
    { name = "WEAPON_APPISTOL",         label = "AP Pistol",         ammo = 300,  recoil = 0.20, shake = "HAND_SHAKE" },
    { name = "WEAPON_HEAVYPISTOL",      label = "Heavy Pistol",      ammo = 200,  recoil = 0.22, shake = "HAND_SHAKE" },
    { name = "WEAPON_REVOLVER",         label = "Revolver",          ammo = 100,  recoil = 0.35, shake = "HAND_SHAKE" },
    -- SMGs (medium recoil)
    { name = "WEAPON_MICROSMG",         label = "Micro SMG",         ammo = 500,  recoil = 0.22, shake = "HAND_SHAKE" },
    { name = "WEAPON_SMG",              label = "SMG",               ammo = 500,  recoil = 0.20, shake = "SMALL_EXPLOSION_SHAKE" },
    { name = "WEAPON_SMG_MK2",          label = "SMG Mk II",         ammo = 500,  recoil = 0.22, shake = "SMALL_EXPLOSION_SHAKE" },
    { name = "WEAPON_COMBATPDW",        label = "Combat PDW",        ammo = 450,  recoil = 0.18, shake = "SMALL_EXPLOSION_SHAKE" },
    { name = "WEAPON_MACHINEPISTOL",    label = "Machine Pistol",    ammo = 500,  recoil = 0.25, shake = "SMALL_EXPLOSION_SHAKE" },
    -- Rifles / Assault (medium-heavy recoil)
    { name = "WEAPON_ASSAULTRIFLE",     label = "Assault Rifle",     ammo = 600,  recoil = 0.28, shake = "SMALL_EXPLOSION_SHAKE" },
    { name = "WEAPON_ASSAULTRIFLE_MK2", label = "Assault Rifle Mk II", ammo = 600, recoil = 0.30, shake = "SMALL_EXPLOSION_SHAKE" },
    { name = "WEAPON_CARBINERIFLE",     label = "Carbine Rifle",     ammo = 600,  recoil = 0.26, shake = "SMALL_EXPLOSION_SHAKE" },
    { name = "WEAPON_CARBINERIFLE_MK2", label = "Carbine Rifle Mk II", ammo = 600, recoil = 0.28, shake = "SMALL_EXPLOSION_SHAKE" },
    { name = "WEAPON_ADVANCEDRIFLE",    label = "Advanced Rifle",    ammo = 600,  recoil = 0.25, shake = "SMALL_EXPLOSION_SHAKE" },
    { name = "WEAPON_SPECIALCARBINE",   label = "Special Carbine",   ammo = 600,  recoil = 0.27, shake = "SMALL_EXPLOSION_SHAKE" },
    { name = "WEAPON_BULLPUPRIFLE",     label = "Bullpup Rifle",     ammo = 600,  recoil = 0.27, shake = "SMALL_EXPLOSION_SHAKE" },
    -- LMGs (heavy recoil)
    { name = "WEAPON_MG",               label = "MG",                ammo = 1000, recoil = 0.40, shake = "MEDIUM_EXPLOSION_SHAKE" },
    { name = "WEAPON_COMBATMG",         label = "Combat MG",         ammo = 1000, recoil = 0.38, shake = "MEDIUM_EXPLOSION_SHAKE" },
    { name = "WEAPON_COMBATMG_MK2",     label = "Combat MG Mk II",   ammo = 1000, recoil = 0.42, shake = "MEDIUM_EXPLOSION_SHAKE" },
    -- Sniper Rifles (very heavy recoil)
    { name = "WEAPON_SNIPERRIFLE",      label = "Sniper Rifle",      ammo = 100,  recoil = 0.55, shake = "MEDIUM_EXPLOSION_SHAKE" },
    { name = "WEAPON_HEAVYSNIPER",      label = "Heavy Sniper",      ammo = 80,   recoil = 0.70, shake = "LARGE_EXPLOSION_SHAKE" },
    { name = "WEAPON_HEAVYSNIPER_MK2",  label = "Heavy Sniper Mk II",ammo = 80,   recoil = 0.72, shake = "LARGE_EXPLOSION_SHAKE" },
    { name = "WEAPON_MARKSMANRIFLE",    label = "Marksman Rifle",    ammo = 150,  recoil = 0.45, shake = "MEDIUM_EXPLOSION_SHAKE" },
    -- Shotguns (heavy recoil)
    { name = "WEAPON_PUMPSHOTGUN",      label = "Pump Shotgun",      ammo = 200,  recoil = 0.50, shake = "MEDIUM_EXPLOSION_SHAKE" },
    { name = "WEAPON_PUMPSHOTGUN_MK2",  label = "Pump Shotgun Mk II",ammo = 200,  recoil = 0.52, shake = "MEDIUM_EXPLOSION_SHAKE" },
    { name = "WEAPON_SAWNOFFSHOTGUN",   label = "Sawn-Off Shotgun",  ammo = 150,  recoil = 0.55, shake = "MEDIUM_EXPLOSION_SHAKE" },
    { name = "WEAPON_ASSAULTSHOTGUN",   label = "Assault Shotgun",   ammo = 200,  recoil = 0.45, shake = "MEDIUM_EXPLOSION_SHAKE" },
    { name = "WEAPON_BULLPUPSHOTGUN",   label = "Bullpup Shotgun",   ammo = 200,  recoil = 0.45, shake = "MEDIUM_EXPLOSION_SHAKE" },
    { name = "WEAPON_HEAVYSHOTGUN",     label = "Heavy Shotgun",     ammo = 150,  recoil = 0.60, shake = "LARGE_EXPLOSION_SHAKE" },
    -- Launchers (extreme recoil)
    { name = "WEAPON_RPG",              label = "RPG",               ammo = 20,   recoil = 1.00, shake = "LARGE_EXPLOSION_SHAKE" },
    { name = "WEAPON_GRENADELAUNCHER",  label = "Grenade Launcher",  ammo = 30,   recoil = 0.80, shake = "LARGE_EXPLOSION_SHAKE" },
    { name = "WEAPON_MINIGUN",          label = "Minigun",           ammo = 2000, recoil = 0.60, shake = "LARGE_EXPLOSION_SHAKE" },
    -- Thrown weapons
    { name = "WEAPON_GRENADE",          label = "Grenade",           ammo = 20,   recoil = 0.00, shake = "HAND_SHAKE" },
    { name = "WEAPON_SMOKEGRENADE",     label = "Smoke Grenade",     ammo = 10,   recoil = 0.00, shake = "HAND_SHAKE" },
    { name = "WEAPON_MOLOTOV",          label = "Molotov",           ammo = 10,   recoil = 0.00, shake = "HAND_SHAKE" },
    { name = "WEAPON_STICKYBOMB",       label = "Sticky Bomb",       ammo = 10,   recoil = 0.00, shake = "HAND_SHAKE" },
    -- Melee
    { name = "WEAPON_KNIFE",            label = "Knife",             ammo = 1,    recoil = 0.00, shake = "HAND_SHAKE" },
    { name = "WEAPON_BAT",              label = "Baseball Bat",      ammo = 1,    recoil = 0.00, shake = "HAND_SHAKE" },
    { name = "WEAPON_CROWBAR",          label = "Crowbar",           ammo = 1,    recoil = 0.00, shake = "HAND_SHAKE" },
}

-- Build lookup maps
local WEAPON_BY_NAME  = {}   -- "WEAPON_PISTOL" -> entry
local WEAPON_BY_LABEL = {}   -- lowercase "pistol" -> entry

for _, w in ipairs(WEAPONS) do
    WEAPON_BY_NAME[w.name] = w
    WEAPON_BY_LABEL[string.lower(w.label)] = w
    -- Also allow short names without "WEAPON_" prefix
    local short = string.lower(w.name:gsub("^WEAPON_", ""))
    WEAPON_BY_NAME[short] = w
end

-- ─── Recoil system ────────────────────────────────────────────────────────────
-- Track last-fire state per weapon hash to avoid duplicate shake
local lastAmmo        = {}
local recoilEnabled   = true

-- Returns the weapon entry for the currently held weapon, or nil
local function getCurrentWeaponEntry()
    local ped  = PlayerPedId()
    local hash = GetSelectedPedWeapon(ped)
    -- Try direct hash match first
    for _, w in ipairs(WEAPONS) do
        if GetHashKey(w.name) == hash then
            return w
        end
    end
    return nil
end

-- Per-frame recoil thread: detects shots fired and shakes camera
CreateThread(function()
    while true do
        Wait(0)
        if not recoilEnabled then goto continue end

        local ped    = PlayerPedId()
        local hash   = GetSelectedPedWeapon(ped)
        local entry  = getCurrentWeaponEntry()

        if entry and entry.recoil > 0 then
            local _, ammo = GetAmmoInClip(ped, hash)
            local prev = lastAmmo[hash]

            if prev ~= nil and ammo < prev then
                -- A shot was fired
                local cam = GetRenderingCam()
                if cam ~= -1 then
                    ShakeCam(cam, entry.shake, entry.recoil)
                else
                    -- Fallback: shake the gameplay camera
                    ShakeGameplayCam(entry.shake, entry.recoil)
                end
            end
            lastAmmo[hash] = ammo
        end

        ::continue::
    end
end)

-- ─── Give weapon helper ───────────────────────────────────────────────────────
-- Gives a single weapon (defined by an entry from the WEAPONS table) to the
-- local player and prints a confirmation message in chat.
local function giveWeapon(entry)
    local ped = PlayerPedId()
    GiveWeaponToPed(ped, GetHashKey(entry.name), entry.ammo, false, false)
    TriggerEvent("chat:addMessage", {
        color  = {100, 220, 100},
        args   = {"[weapons]", ("Given: %s (%d rounds)"):format(entry.label, entry.ammo)}
    })
end

-- ─── Commands ─────────────────────────────────────────────────────────────────

-- /weapons — give the player the full loadout
RegisterCommand("weapons", function(source, args, rawCommand)
    local ped = PlayerPedId()
    RemoveAllPedWeapons(ped, true)
    for _, entry in ipairs(WEAPONS) do
        GiveWeaponToPed(ped, GetHashKey(entry.name), entry.ammo, false, false)
    end
    TriggerEvent("chat:addMessage", {
        color = {100, 220, 100},
        args  = {"[weapons]", ("Full loadout given (%d weapons). Recoil is active."):format(#WEAPONS)}
    })
    TriggerServerEvent('weapon-loadout:logLoadout')
end, false)

-- /gun <weapon> — give a single weapon by name or label
RegisterCommand("gun", function(source, args, rawCommand)
    if #args < 1 then
        TriggerEvent("chat:addMessage", { color = {255, 165, 0}, args = {"[weapons]", "Usage: /gun <weapon>  |  Type /guns to see available weapons."} })
        return
    end

    local input = string.lower(table.concat(args, " "))
    -- Try label first, then short name, then full name
    local entry = WEAPON_BY_LABEL[input]
                  or WEAPON_BY_NAME[input]
                  or WEAPON_BY_NAME["weapon_" .. input]

    if not entry then
        TriggerEvent("chat:addMessage", {
            color = {255, 80, 80},
            args  = {"[weapons]", ("Unknown weapon '%s'. Type /guns to see available weapons."):format(input)}
        })
        return
    end

    giveWeapon(entry)
    TriggerServerEvent('weapon-loadout:logGun', entry.name)
end, false)

-- /guns — list all available weapons
RegisterCommand("guns", function(source, args, rawCommand)
    TriggerEvent("chat:addMessage", { color = {100, 200, 255}, args = {"[weapons]", "Available weapons (use /gun <name>):"} })

    local categories = {
        { label = "Pistols",   match = "PISTOL|REVOLVER" },
        { label = "SMGs",      match = "SMG|PDW|MACHINEPISTOL" },
        { label = "Rifles",    match = "RIFLE|CARBINE" },
        { label = "LMGs",      match = "_MG" },
        { label = "Snipers",   match = "SNIPER|MARKSMAN" },
        { label = "Shotguns",  match = "SHOTGUN" },
        { label = "Launchers", match = "RPG|LAUNCHER|MINIGUN" },
        { label = "Thrown",    match = "GRENADE|MOLOTOV|STICKY" },
        { label = "Melee",     match = "KNIFE|BAT|CROWBAR" },
    }

    for _, cat in ipairs(categories) do
        local names = {}
        for _, w in ipairs(WEAPONS) do
            if w.name:match(cat.match) then
                table.insert(names, w.label)
            end
        end
        if #names > 0 then
            TriggerEvent("chat:addMessage", {
                color = {180, 180, 255},
                args  = {cat.label, table.concat(names, ", ")}
            })
        end
    end
end, false)

-- /recoil — toggle recoil on/off
RegisterCommand("recoil", function(source, args, rawCommand)
    recoilEnabled = not recoilEnabled
    local status = recoilEnabled and "^2ENABLED^7" or "^1DISABLED^7"
    TriggerEvent("chat:addMessage", {
        color = {255, 220, 100},
        args  = {"[weapons]", ("Recoil %s"):format(status)}
    })
end, false)
