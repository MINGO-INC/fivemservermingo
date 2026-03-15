-- car-spawner: client.lua
-- Commands: /car <model>, /dv (delete vehicle), /cars (list available cars)

-- Curated list of nice vehicle models available on the server
local NICE_CARS = {
    -- Super Cars
    "adder",        -- Truffade Adder (Bugatti Veyron)
    "entityxf",     -- Overflod Entity XF
    "infernus",     -- Pegassi Infernus (Lamborghini)
    "osiris",       -- Pegassi Osiris
    "t20",          -- Progen T20
    "zentorno",     -- Pegassi Zentorno
    "cheetah",      -- Grotti Cheetah (Ferrari)
    "turismor",     -- Grotti Turismo R
    "fmj",          -- Progen FMJ
    "reaper",       -- Pegassi Reaper
    -- Sports Cars
    "sultan",       -- Karin Sultan (Subaru)
    "jester",       -- Dinka Jester
    "elegy2",       -- Annis Elegy RH8 (Nissan GT-R)
    "comet2",       -- Pfister Comet (Porsche 911)
    "feltzer2",     -- Merryweather Feltzer
    "carbonizzare", -- Grotti Carbonizzare (Ferrari 458)
    -- Muscle Cars
    "dominator",    -- Vapid Dominator (Ford Mustang)
    "gauntlet",     -- Bravado Gauntlet (Dodge Challenger)
    "vigero",       -- Declasse Vigero (Chevy Camaro)
    -- Luxury
    "cognoscenti",  -- Enus Cognoscenti (Bentley)
    "supervolito",  -- Buckingham SuperVolito
    "jackal",       -- Enus Jackal (Rolls-Royce)
    -- Motorcycles
    "akuma",        -- Dinka Akuma (Honda)
    "bati",         -- Pegassi Bati 801 (Ducati)
    "shotaro",      -- Nagasaki Shotaro (light cycle)
}

-- Build a quick lookup set for validation
local ALLOWED_MODELS = {}
for _, model in ipairs(NICE_CARS) do
    ALLOWED_MODELS[model] = true
end

-- Helper: request and load a model hash
local function loadModel(modelName)
    local hash = GetHashKey(modelName)
    if not IsModelValid(hash) then
        return nil, ("^1[car-spawner] Model '%s' is not valid on this server.^7"):format(modelName)
    end
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) do
        Wait(100)
        timeout = timeout + 100
        if timeout > 10000 then
            return nil, ("^1[car-spawner] Timed out loading model '%s'.^7"):format(modelName)
        end
    end
    return hash, nil
end

-- Helper: delete the player's current vehicle
local function deleteCurrentVehicle()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)
        return true
    end
    return false
end

-- /car <model> — spawn a vehicle from the allowed list
RegisterCommand("car", function(source, args, rawCommand)
    if #args < 1 then
        TriggerEvent("chat:addMessage", { color = {255, 165, 0}, args = {"[cars]", "Usage: /car <model>  |  Type /cars to see available models."} })
        return
    end

    local modelName = string.lower(args[1])

    if not ALLOWED_MODELS[modelName] then
        TriggerEvent("chat:addMessage", {
            color = {255, 80, 80},
            args = {"[cars]", ("'%s' is not in the allowed car list. Type /cars to see available models."):format(modelName)}
        })
        return
    end

    local hash, err = loadModel(modelName)
    if not hash then
        TriggerEvent("chat:addMessage", { color = {255, 80, 80}, args = {"[cars]", err} })
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    -- Delete the player's old vehicle first
    deleteCurrentVehicle()

    local veh = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)
    SetVehicleOnGroundProperly(veh)
    SetPedIntoVehicle(ped, veh, -1)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleEngineOn(veh, true, true, false)

    -- Make the car look nice: full health, no damage
    SetVehicleBodyHealth(veh, 1000.0)
    SetVehicleEngineHealth(veh, 1000.0)
    SetVehicleFixed(veh)

    SetModelAsNoLongerNeeded(hash)

    TriggerEvent("chat:addMessage", {
        color = {100, 220, 100},
        args = {"[cars]", ("Spawned: %s"):format(modelName)}
    })
    TriggerServerEvent('car-spawner:logSpawn', modelName)
end, false)

-- /dv — delete the vehicle the player is currently in
RegisterCommand("dv", function(source, args, rawCommand)
    if deleteCurrentVehicle() then
        TriggerEvent("chat:addMessage", { color = {100, 220, 100}, args = {"[cars]", "Vehicle deleted."} })
    else
        TriggerEvent("chat:addMessage", { color = {255, 165, 0}, args = {"[cars]", "You are not in a vehicle."} })
    end
end, false)

-- /cars — list all available car models in chat
RegisterCommand("cars", function(source, args, rawCommand)
    TriggerEvent("chat:addMessage", { color = {100, 200, 255}, args = {"[cars]", "Available models:"} })
    local chunks = {}
    local current = {}
    for _, name in ipairs(NICE_CARS) do
        table.insert(current, name)
        if #current == 6 then
            table.insert(chunks, table.concat(current, ", "))
            current = {}
        end
    end
    if #current > 0 then
        table.insert(chunks, table.concat(current, ", "))
    end
    for _, line in ipairs(chunks) do
        TriggerEvent("chat:addMessage", { color = {200, 200, 200}, args = {"", line} })
    end
end, false)
