--[[ Contains client-side helper functions. ]]

local Utils = {}

---Custom notifications with options.
---@param title string
---@param type 'inform'|'error'|'success'|'warning'
---@param duration number
---@param description string
function Utils.notify(title, type, duration, description)
    lib.notify({
        title = title,
        description = description,
        duration = duration,
        position = 'top-right',
        type = type,
    })
end

--[[ Show the TextUI window ]]
function Utils.showTextUI(text, options)
    lib.showTextUI(text, options)
end

--[[ Hide the TextUI window ]]
function Utils.hideTextUI()
    lib.hideTextUI()
end

--[[ There are situations where you need to hide the Hud script ]]
function Utils.toggleHud(state)
    if shared.isResourceStart('0r-hud-v3') then
        exports['0r-hud-v3']:ToggleVisible(state)
    else
        -- # Your hud script export
    end
end

---@param _type 'on_sale_delivery_completed'
function Utils.triggerPoliceAlert(_type)
    local message = nil
    local areaCoords = GetEntityCoords(cache.ped)
    if _type == 'on_sale_delivery_completed' then
        message = 'An illegal delivery took place in this area'
    end

    -- ? Use your own alert dispatch script export/event
end

function Utils.giveVehicleKey(plate, entity)
    if shared.framework ~= 'esx' then --[[Qb or Qbox]]
        TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
    else
        -- ? Use your vehicle key script export
    end
end

--[[!!! It is not recommended to change the functions from here on if you are not familiar with them !!!]]

---Creates an object with the specified params
---@param model string
---@param coords vector3
---@param rotation vector3
---@param freeze boolean
---@param isNetwork boolean
---@param doorFlag boolean
---@return integer
function Utils.createObject(model, coords, rotation, freeze, isNetwork, doorFlag)
    if freeze == nil then freeze = true end
    if isNetwork == nil then isNetwork = false end
    if doorFlag == nil then doorFlag = false end
    lib.requestModel(model)
    local object = CreateObject(model, coords.x, coords.y, coords.z, isNetwork, isNetwork, doorFlag)
    SetEntityCoords(object, coords.x, coords.y, coords.z, false, false, false, true)
    if rotation then
        if type(rotation) == 'number' then
            rotation = vector3(0.0, 0.0, rotation)
        end
        SetEntityRotation(object, rotation.x, rotation.y, rotation.z, 2, false)
    end
    FreezeEntityPosition(object, freeze)
    SetModelAsNoLongerNeeded(model)
    return object
end

function Utils.getGroundZ(coords)
    local x, y, z = table.unpack(coords)
    local groundCheckHeights = { z, z + 1.0, z + 2.0, z + 3.0, z + 4.0, z + 5.0 }

    for i, height in ipairs(groundCheckHeights) do
        local foundGround, z = GetGroundZFor_3dCoord(x, y, height)

        if foundGround then
            return z, true
        end
    end

    return z, false
end

---Add blip with the specified params
---@param target number|vector3
---@param options object
---@param route boolean
function Utils.addBlip(target, options, route)
    local blip = type(target) == 'number' and
        AddBlipForEntity(target) or
        AddBlipForCoord(vector3(target))

    SetBlipDisplay(blip, 4)
    SetBlipSprite(blip, options.sprite or 469)
    SetBlipColour(blip, options.color or 0)
    SetBlipScale(blip, options.scale or 0.85)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(options.text or 'Undefined')
    EndTextCommandSetBlipName(blip)

    if route then
        local coords = type(target) == 'number' and GetEntityCoords(target) or vector3(target)
        SetNewWaypoint(coords.x, coords.y)
    end

    return blip
end

return Utils
