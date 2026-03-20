-- Money Washing Script
-- Developed for handling money laundering operations within a game environment

local Utils = require 'modules.utils.client'

-- State Management
MoneyWashing = {}
local createdEmployeePeds = {}

-- IPL (Interior Prop List) Configuration
local iplPropList = {
    ['counterfeit_setup'] = true,
    ['counterfeit_standard_equip'] = false,
    ['counterfeit_standard_equip_no_prod'] = false,
    ['counterfeit_low_security'] = true,
    ['counterfeit_security'] = false,
    ['counterfeit_upgrade_equip'] = true,
    ['counterfeit_upgrade_equip_no_prod'] = true,
    ['money_cutter'] = true,
    ['special_chairs'] = true,
    ['dryera_off'] = false,
    ['dryera_on'] = false,
    ['dryera_open'] = true,
    ['dryerb_off'] = false,
    ['dryerb_on'] = true,
    ['dryerb_open'] = false,
    ['dryerc_off'] = false,
    ['dryerc_on'] = true,
    ['dryerc_open'] = false,
    ['dryerd_off'] = false,
    ['dryerd_on'] = true,
    ['dryerd_open'] = false,
    ['counterfeit_cashpile10a'] = true,
    ['counterfeit_cashpile10b'] = true,
    ['counterfeit_cashpile10c'] = true,
    ['counterfeit_cashpile10d'] = true,
    ['counterfeit_cashpile20a'] = true,
    ['counterfeit_cashpile20b'] = true,
    ['counterfeit_cashpile20c'] = true,
    ['counterfeit_cashpile20d'] = true,
    ['counterfeit_cashpile100a'] = true,
    ['counterfeit_cashpile100b'] = true,
    ['counterfeit_cashpile100c'] = true,
    ['counterfeit_cashpile100d'] = true,
}

-- Helper Functions

-- Creates an employee ped at the specified coordinates
local function createEmployeePed(data)
    local models = { 'mp_m_weed_01', 'mp_f_weed_01' }
    local model = models[math.random(#models)]
    local newIndex = #createdEmployeePeds + 1

    lib.requestModel(model)
    local ped = CreatePed(4, model, data.coords.x, data.coords.y, data.coords.z, data.coords.w, false, false)
    if not DoesEntityExist(ped) then return false, nil end

    local groundZ = Utils.getGroundZ(data.coords)
    SetEntityCoords(ped, data.coords.x, data.coords.y, groundZ)
    SetEntityHeading(ped, data.coords.w)
    SetPedDefaultComponentVariation(ped)
    SetPedDiesWhenInjured(ped, false)
    SetEntityInvincible(ped, true)
    TaskSetBlockingOfNonTemporaryEvents(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)

    local response = { entityId = ped, sceneObjects = {} }
    createdEmployeePeds[newIndex] = response
    SetModelAsNoLongerNeeded(model)
    return response, newIndex
end

-- Deletes a ped and its associated scene objects
local function deletePedEntities(ped)
    if not ped then return end
    if DoesEntityExist(ped.entityId) then DeleteEntity(ped.entityId) end
    for _, obj in pairs(ped.sceneObjects) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
end

-- Creates an exit area interaction point
local function createExitAreaPoint()
    local exitArea = Config.MoneyWashing.interior.exitArea
    lib.points.new({
        coords = exitArea,
        distance = 1.5,
        onEnter = function()
            Utils.showTextUI('[E] ' .. locale('get_outside'))
        end,
        warehouseIndex = client.inWarehouse.warehouse_index,
        nearby = function(self)
            DrawMarker(20, self.coords.x, self.coords.y, self.coords.z - 0.25, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.5, 0.25, 0.5, 255, 255, 0, 255, false, true, 2, true, nil, nil, false)
            if IsControlJustPressed(0, 38) then
                MoneyWashing.getOutside(self.warehouseIndex)
                self:remove()
                Utils.hideTextUI()
            end
        end,
        onExit = function()
            Utils.hideTextUI()
        end
    })
end

-- Scene Creation Functions

-- Plays the paper placement animation
local function playPlacePaper()
    local data = {
        { coords = vector4(1131.3628, -3197.2800, -39.6657, 180.0) },
        { coords = vector4(1128.5715, -3197.3057, -39.6648, 180.0) },
    }
    for _, value in pairs(data) do
        local ped, _ = createEmployeePed(value)
        local animDict = 'anim@amb@business@cfm@cfm_machine_oversee@'
        local animName = 'stop_blockage_operator'
        Citizen.SetTimeout(math.random(1500), function()
            lib.playAnim(ped.entityId, animDict, animName, nil, nil, -1, 1)
        end)
    end
end

-- Plays the drying scene with props
local function playDryingScene()
    local data = { { coords = vector4(1122.51, -3194.62, -40.4, 90.0) } }
    local sceneObjects = {
        { model = 'bkr_prop_money_pokerbucket', offset = vector3(-0.1, 0.8, -1.0), rotation = vector3(0.0, 0.0, 0.0) }
    }
    for _, value in pairs(data) do
        local ped, index = createEmployeePed(value)
        local animDict = 'anim@amb@business@cfm@cfm_drying_notes@'
        local animName = 'loading_v3_worker'
        for _, so in pairs(sceneObjects) do
            local coords = GetOffsetFromEntityInWorldCoords(ped.entityId, so.offset.x, so.offset.y, so.offset.z)
            local sceneObject = Utils.createObject(so.model, coords, so.rotation, true, false, false)
            createdEmployeePeds[index].sceneObjects[#createdEmployeePeds[index].sceneObjects + 1] = sceneObject
        end
        lib.playAnim(ped.entityId, animDict, animName, nil, nil, -1, 1)
    end
end

-- Plays the packing scene
local function playPackingScene()
    local data = {
        { coords = vector4(1116.6, -3196.25, -40.4, 90.0) },
        { coords = vector4(1116.6, -3194.9, -40.4, 90.0) },
    }
    for _, value in pairs(data) do
        local ped, _ = createEmployeePed(value)
        local animDict = 'anim@amb@business@cfm@cfm_counting_notes@'
        local animName = 'note_counting_v2_counter'
        lib.playAnim(ped.entityId, animDict, animName, nil, nil, -1, 1)
    end
end

-- Initializes all employee scenes
local function createEmployees()
    playPlacePaper()
    playDryingScene()
    playPackingScene()
end

-- Cleans up all employee peds and objects
local function deleteEmployees()
    for _, ped in pairs(createdEmployeePeds) do
        deletePedEntities(ped)
    end
    createdEmployeePeds = {}
end

-- MoneyWashing Core Functions

function MoneyWashing.getInside(warehouseIndex)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(1) end
    TriggerServerEvent(_e('server:moneywashing:GetInside'))
end

function MoneyWashing.getOutside(warehouseIndex)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(1) end
    deleteEmployees()
    TriggerServerEvent(_e('server:moneywashing:GetOutside'), warehouseIndex)
end

function MoneyWashing.clear()
    deleteEmployees()
end

-- Event Handlers

RegisterNUICallback('nui:moneywashing:upgrade', function(_, resultCallback)
    local response = lib.callback.await(_e('server:moneywashing:upgrade'), false, client.inWarehouse?.warehouse_index)
    if response.error then
        Utils.notify(response.error, 'error')
        return resultCallback(false)
    end
    resultCallback(true)
end)

RegisterNetEvent(_e('client:moneywashing:onPlayerGetInside'), function()
    createExitAreaPoint()
    SetArtificialLightsState(false)
    Employee.clear()
    createEmployees()
    client.loadInteriorEntities(Config.MoneyWashing.interior.coords, iplPropList)
    Citizen.Wait(500)
    DoScreenFadeIn(1000)
end)

RegisterNetEvent(_e('client:moneywashing:onPlayerGetOutside'), function()
    SetArtificialLightsState(not client.inWarehouse.meta.interior_light)
    Warehouse.createOutsidePoint(client.inWarehouse.business_theme, client.inWarehouse.warehouse_index)
    Log.loadCurrentWarehouseLogs()
    Citizen.Wait(1000)
    Employee.onGetInside()
    DoScreenFadeIn(500)
end)
