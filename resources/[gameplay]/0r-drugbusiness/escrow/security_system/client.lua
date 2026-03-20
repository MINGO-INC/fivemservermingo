--[[ require ]]

local Utils = require 'modules.utils.client'
local Weather = require 'modules.weather.client'

--[[ state ]]

SecuritySystem = {}

local outsideCamera = nil

--[[ helper functions ]]

---@param data {coords:vector3, rot: vector3}
---@return integer
local function createOutsideCamera(data)
    local cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA',
        data.coords.x, data.coords.y, data.coords.z,
        data.rot.x, data.rot.y, data.rot.z,
        70.0)

    SetCamActive(cam, true)
    RenderScriptCams(true, false, 1, false, true)

    SetTimecycleModifier('scanline_cam_cheap')
    SetTimecycleModifierStrength(2.0)

    SetFocusPosAndVel(data.coords.x, data.coords.y, data.coords.z, 0.0, 0.0, 0.0)

    Utils.toggleHud(false)
    outsideCamera = cam

    return cam
end

local function checkCamRotationInput(cam)
    local rightAxisX = GetDisabledControlNormal(0, 220)
    local rightAxisY = GetDisabledControlNormal(0, 221)
    local rotation = GetCamRot(cam, 2)

    if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
        local new_z = rotation.z + rightAxisX * -1.0 * 2.0 * (4.0 + 0.1)
        local new_x = math.max(-60.0, math.min(60.0, rotation.x + rightAxisY * -1.0 * 2.0 * (4.0 + 0.1)))
        SetCamRot(cam, new_x, 0.0, new_z, 2)
    end
end

local function handleControls(cam)
    DisableAllControlActions(0)
    HideHudAndRadarThisFrame()

    EnableControlAction(0, 249)

    checkCamRotationInput(cam)

    if IsDisabledControlPressed(0, 97) and GetCamFov(cam) < 100 then
        SetCamFov(cam, GetCamFov(cam) + 2.0)
    elseif IsDisabledControlPressed(0, 96) and GetCamFov(cam) > 10 then
        SetCamFov(cam, GetCamFov(cam) - 2.0)
    end

    if IsDisabledControlJustPressed(0, 194) or
        IsDisabledControlJustPressed(0, 202)
    then
        SecuritySystem.clear()
    end
end

local function cleanUp()
    Utils.toggleHud(true)

    if outsideCamera and DoesCamExist(outsideCamera) then
        DestroyCam(outsideCamera)
        ClearFocus()
        RenderScriptCams(false, false, 0, false, false)
        ClearTimecycleModifier()
        ClearExtraTimecycleModifier()

        local insideBucketId = tonumber(1 .. '' .. client.inWarehouse.warehouse_index)
        TriggerServerEvent(_e('server:setPlayerBucket'), insideBucketId)
    end

    outsideCamera = nil
end

--[[ functions ]]

function SecuritySystem.clear()
    cleanUp()
end

--[[ events ]]

RegisterNUICallback('nui:security:buySecuritySystem', function(_, resultCallback)
    local response = lib.callback.await(_e('server:security:BuySystem'), false,
        client.inWarehouse.warehouse_index)

    if response.error then
        client.sendReactMessage('ui:setAlert', { text = response.error, type = 'error' })
    end

    resultCallback(true)
end)

RegisterNUICallback('nui:security:openCameras', function(_, resultCallback)
    if not client.inWarehouse.meta.security_system then
        return resultCallback(false)
    end

    client.hideUI()

    local warehouse = Warehouse.getDataByIndex(client.inWarehouse.warehouse_index)
    if not warehouse then return resultCallback(false) end

    createOutsideCamera(warehouse.outsideCamera)
    Weather.enableSync()
    TriggerServerEvent(_e('server:setPlayerBucket'), 0)

    Citizen.CreateThread(function()
        while outsideCamera do
            handleControls(outsideCamera)
            Citizen.Wait(1)
        end
        Weather.disableSync()
        cleanUp()
    end)

    resultCallback(true)
end)
