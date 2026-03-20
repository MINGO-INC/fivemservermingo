---@class EmployeePed
---@field entityId integer
---@field sceneObjects integer[]
---@field taskCoords vector4
---@field taskType TaskType
---@field theme BusinessTheme

--[[ require ]]

local Utils = require 'modules.utils.client'

---@type table<BusinessTheme, ThemeInterior>
local ThemeInteriors = lib.load('data.theme_interiors')

--[[ state ]]

Employee = {}

---@type table<key, EmployeePed>
local createdEmployeePeds = {}

--[[ helper functions ]]

---@param theme BusinessTheme
local function createEmployeePed(theme)
    if not theme then return false end
    local models = { 'mp_m_weed_01', 'mp_f_weed_01' }
    if theme == 'cocaine' then
        models = { 'mp_f_cocaine_01', 'mp_m_cocaine_01' }
    elseif theme == 'meth' then
        models = { 'mp_f_meth_01', 'mp_m_meth_01' }
    end
    local model = models[math.random(#models)]
    local newIndex = #createdEmployeePeds + 1
    local data = ThemeInteriors[theme].employees[newIndex]
    if not data then return false end
    lib.requestModel(model)
    local response = false
    local ped = CreatePed(4, model, data.coords.x, data.coords.y, data.coords.z, data.coords.w, false, false)
    if DoesEntityExist(ped) then
        SetPedDefaultComponentVariation(ped)
        SetPedDiesWhenInjured(ped, false)
        SetEntityInvincible(ped, true)
        TaskSetBlockingOfNonTemporaryEvents(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        TaskWanderStandard(ped, 10.0, 10)
        response = { entityId = ped, taskCoords = data.coords, taskType = data.task, theme = theme, sceneObjects = {} }
        createdEmployeePeds[newIndex] = response
    end
    SetModelAsNoLongerNeeded(model)
    return response, newIndex
end

---@param ped EmployeePed
local function deletePedEntities(ped)
    if ped then
        if DoesEntityExist(ped.entityId) then DeleteEntity(ped.entityId) end
        for _, v in pairs(ped.sceneObjects) do
            if DoesEntityExist(v) then DeleteEntity(v) end
        end
    end
end

local function deleteEmployeePed(count)
    for _ = 1, count do
        local lastIndex = #createdEmployeePeds
        if lastIndex > 0 then
            deletePedEntities(createdEmployeePeds[lastIndex])
            table.remove(createdEmployeePeds, lastIndex)
        else
            break
        end
    end
end

---@param index integer
---@param v EmployeePed
local function playWeedGathering(index, v)
    local animDict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@'
    local animName = 'weed_spraybottle_stand_kneeling_01_inspector'
    local objectModel01 = 'bkr_prop_weed_spray_01a'
    lib.requestAnimDict(animDict)
    lib.requestModel(objectModel01)

    local coords = GetEntityCoords(v.entityId)

    local sceneObject01 = CreateObject(objectModel01, coords.x, coords.y, coords.z, false, false)
    createdEmployeePeds[index].sceneObjects[#createdEmployeePeds[index].sceneObjects + 1] = sceneObject01

    AttachEntityToEntity(sceneObject01, v.entityId, GetPedBoneIndex(v.entityId, 57005),
        0.1, -0.025, -0.12, -35.0, -10.0, 0.0,
        true, true, false, true, 1, true)

    lib.playAnim(v.entityId, animDict, animName, nil, nil, -1, 1)
end

---@param index integer
---@param v EmployeePed
local function playWeedProcessing(index, v)
    local animDict = 'anim@amb@business@weed@weed_sorting_seated@'
    local animName = 'sorter_right_sort_v3_sorter02'
    lib.playAnim(v.entityId, animDict, animName, nil, nil, -1, 1)
end

---@param index integer
---@param v EmployeePed
local function playCocaineUnpack(index, v)
    local animDict = 'anim@amb@business@coc@coc_unpack_cut@'
    local animName = 'fullcut_cycle_v2_cokepacker'
    lib.playAnim(v.entityId, animDict, animName, nil, nil, -1, 1)
end

---@param index integer
---@param v EmployeePed
local function playCocaineCutter(index, v)
    local animDict = 'anim@amb@business@coc@coc_unpack_cut_left@'
    local animName = 'coke_cut_v5_coccutter'
    lib.playAnim(v.entityId, animDict, animName, nil, nil, -1, 1)
end

---@param index integer
---@param v EmployeePed
local function playCocainePack(index, v)
    local animDict = 'anim@amb@business@coc@coc_packing_hi@'
    local animName = 'full_cycle_v3_pressoperator'
    lib.playAnim(v.entityId, animDict, animName, nil, nil, -1, 1)
end

---@param index integer
---@param v EmployeePed
local function playMethCook(index, v)
    local animDict = 'anim@amb@business@meth@meth_monitoring_cooking@cooking@'
    local animName = 'chemical_pour_short_cooker'
    lib.playAnim(v.entityId, animDict, animName, nil, nil, -1, 1)

    local sceneObjects = {
        { model = 'bkr_prop_meth_ammonia', offset = vector3(-0.5, 0.0, -1.0), rotation = 90.0 },
        { model = 'bkr_prop_meth_sacid',   offset = vector3(0.5, 0.0, -1.0),  rotation = 90.0 },
    }
    for _, so in pairs(sceneObjects) do
        local coords = GetOffsetFromEntityInWorldCoords(v.entityId,
            so.offset.x, so.offset.y, so.offset.z)

        local sceneObject = Utils.createObject(so.model, coords, so.rotation, true, false, false)
        createdEmployeePeds[index].sceneObjects[#createdEmployeePeds[index].sceneObjects + 1] = sceneObject
    end
end

---@param index integer
---@param v EmployeePed
local function playMethHammer(index, v)
    local animDict = 'anim@amb@business@meth@meth_smash_weight_check@'
    local animName = 'break_weigh_char02'
    lib.playAnim(v.entityId, animDict, animName, nil, nil, -1, 1)

    local sceneObjects = {
        { model = 'bkr_prop_meth_smashedtray_01_frag_', offset = vector3(0.1, 0.8, -0.2),  rotation = 0.0 },
        { model = 'bkr_prop_meth_tray_01a',             offset = vector3(-0.6, 0.8, -0.2), rotation = 0.0 },
        { model = 'bkr_prop_meth_bigbag_02a',           offset = vector3(0.75, 0.9, -0.2), rotation = 90.0 },
    }
    for _, so in pairs(sceneObjects) do
        local coords = GetOffsetFromEntityInWorldCoords(v.entityId,
            so.offset.x, so.offset.y, so.offset.z)

        local sceneObject = Utils.createObject(so.model, coords, so.rotation, true, false, false)
        createdEmployeePeds[index].sceneObjects[#createdEmployeePeds[index].sceneObjects + 1] = sceneObject

        if so.attach then
            AttachEntityToEntity(sceneObject, v.entityId, GetPedBoneIndex(v.entityId, 57005),
                so.offset.x, so.offset.y, so.offset.z, so.rotation.x, so.rotation.y, so.rotation.z,
                true, true, false, true, 1, true)
        end
    end
end

---@param index integer
---@param v EmployeePed
local function playMethPack(index, v)
    local animDict = 'anim@amb@business@meth@meth_smash_weight_check@'
    local animName = 'break_weigh_v3_char01'
    lib.playAnim(v.entityId, animDict, animName, nil, nil, -1, 1)

    local sceneObjects = {
        { model = 'bkr_prop_meth_bigbag_04a',      offset = vector3(0.75, 0.9, -0.2),  rotation = 90.0 },
        { model = 'bkr_prop_meth_bigbag_03a',      offset = vector3(-0.6, 0.8, -0.2),  rotation = 90.0 },
        { model = 'bkr_prop_meth_scoop_01a',       offset = vector3(0.14, 0.1, -0.05), rotation = vector3(-30.0, 0.0, 160.0), attach = true },
        { model = 'bkr_prop_coke_scale_01',        offset = vector3(0.1, 0.65, -0.2),  rotation = 0.0 },
        { model = 'bkr_prop_meth_openbag_02',      offset = vector3(0.1, 0.7, -0.1),   rotation = 0.0 },
        { model = 'bkr_prop_fakeid_clipboard_01a', offset = vector3(0.4, 0.7, -0.2),   rotation = 0.0 },
    }
    for _, so in pairs(sceneObjects) do
        local coords = GetOffsetFromEntityInWorldCoords(v.entityId,
            so.offset.x, so.offset.y, so.offset.z)

        local sceneObject = Utils.createObject(so.model, coords, so.rotation, true, false, false)
        createdEmployeePeds[index].sceneObjects[#createdEmployeePeds[index].sceneObjects + 1] = sceneObject

        if so.attach then
            AttachEntityToEntity(sceneObject, v.entityId, GetPedBoneIndex(v.entityId, 57005),
                so.offset.x, so.offset.y, so.offset.z, so.rotation.x, so.rotation.y, so.rotation.z,
                true, true, false, true, 1, true)
        end
    end
end

---@param index integer
---@param v EmployeePed
local function playMethNote(index, v)
    local animDict = 'missfam4'
    local animName = 'base'
    lib.playAnim(v.entityId, animDict, animName, nil, nil, -1, 1)

    local sceneObjects = {
        { model = 'p_amb_clipboard_01', offset = vector3(0.16, 0.08, 0.1), rotation = vector3(-130.0, -50.0, 0.0), attach = true },
    }
    for _, so in pairs(sceneObjects) do
        local coords = GetOffsetFromEntityInWorldCoords(v.entityId,
            so.offset.x, so.offset.y, so.offset.z)

        local sceneObject = Utils.createObject(so.model, coords, so.rotation, true, false, false)
        createdEmployeePeds[index].sceneObjects[#createdEmployeePeds[index].sceneObjects + 1] = sceneObject

        if so.attach then
            AttachEntityToEntity(sceneObject, v.entityId, GetPedBoneIndex(v.entityId, 36029),
                so.offset.x, so.offset.y, so.offset.z, so.rotation.x, so.rotation.y, so.rotation.z,
                true, true, false, true, 1, true)
        end
    end
end

---@param k integer
---@param v EmployeePed
local function playTaskScene(k, v)
    local animDict, animName
    local theme = v.theme
    local taskType = v.taskType

    local targetFunc = function() end

    if theme == 'weed' then
        if taskType == 'gathering' then
            targetFunc = playWeedGathering
        elseif taskType == 'processing' then
            targetFunc = playWeedProcessing
        end
    elseif theme == 'cocaine' then
        if taskType == 'unpack' then
            targetFunc = playCocaineUnpack
        elseif taskType == 'cutter' then
            targetFunc = playCocaineCutter
        elseif taskType == 'packing' then
            targetFunc = playCocainePack
        end
    elseif theme == 'meth' then
        if taskType == 'cook' then
            targetFunc = playMethCook
        elseif taskType == 'hammer' then
            targetFunc = playMethHammer
        elseif taskType == 'packing' then
            targetFunc = playMethPack
        else
            targetFunc = playMethNote
        end
    end

    targetFunc(k, v)
end

---@param v EmployeePed
local function startWork(k, v)
    if v.theme == 'weed' then
        if v.taskType == 'processing' then
            local chair = GetClosestObjectOfType(v.taskCoords.x, v.taskCoords.y, v.taskCoords.z, 2.0,
                'bkr_prop_weed_chair_01a', false, false, false)
            if DoesEntityExist(chair) then SetEntityCollision(chair, false, false) end
        end
    end
    ClearPedTasksImmediately(v.entityId)
    FreezeEntityPosition(v.entityId, true)
    local groundZ = Utils.getGroundZ(v.taskCoords)
    SetEntityCoords(v.entityId, v.taskCoords.x, v.taskCoords.y, groundZ)
    SetEntityHeading(v.entityId, v.taskCoords.w)
    playTaskScene(k, v)
end

--[[ functions ]]

function Employee.clear()
    for _, ped in pairs(createdEmployeePeds) do
        deletePedEntities(ped)
    end
    createdEmployeePeds = {}
end

function Employee.onWorkStarted()
    for k, v in pairs(createdEmployeePeds) do startWork(k, v) end
end

function Employee.OnWorkStopped()
    for _, v in pairs(createdEmployeePeds) do
        ClearPedTasksImmediately(v.entityId)
        FreezeEntityPosition(v.entityId, false)
        TaskWanderStandard(v.entityId, 10.0, 10)
    end
end

function Employee.onGetInside(pass)
    local warehouse = client.inWarehouse
    if not pass and warehouse.meta.interior_level < 2 then return end
    local employeeCount = warehouse.employee_count
    if employeeCount <= 0 then return end
    for i = 1, employeeCount do createEmployeePed(warehouse.business_theme) end
    if warehouse.meta.is_working then Employee.onWorkStarted() end
end

--[[ events ]]

RegisterNUICallback('nui:employee:haveToPay', function(_, resultCallback)
    resultCallback(lib.callback.await(_e('server:employee:haveToPaySalaries'), false,
        client.inWarehouse.warehouse_index))
end)

RegisterNUICallback('nui:employee:paySalaries', function(_, resultCallback)
    local response = lib.callback.await(_e('server:employee:paySalaries'), false,
        client.inWarehouse.warehouse_index)

    if response.error then
        client.sendReactMessage('ui:setAlert', { text = response.error, type = 'error' })
        return resultCallback(false)
    end

    resultCallback(true)
end)

RegisterNUICallback('nui:employee:recruitment', function(amount, resultCallback)
    local response = lib.callback.await(_e('server:employee:newRecruitment'), false,
        client.inWarehouse.warehouse_index, amount)

    if response.error then
        client.sendReactMessage('ui:setAlert', { text = response.error, type = 'error' })
        return resultCallback(false)
    end

    for i = 1, response.amount do
        local v, k = createEmployeePed(client.inWarehouse.business_theme)
        if v and client.inWarehouse.meta.is_working then startWork(k, v) end
    end

    resultCallback(true)
end)

RegisterNUICallback('nui:employee:dismiss', function(amount, resultCallback)
    local response = lib.callback.await(_e('server:employee:dismiss'), false,
        client.inWarehouse.warehouse_index, amount)

    if response.error then
        client.sendReactMessage('ui:setAlert', { text = response.error, type = 'error' })
        return resultCallback(false)
    end

    deleteEmployeePed(response.removed)

    resultCallback(true)
end)
