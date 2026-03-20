--[[ require ]]

local Utils = require 'modules.utils.client'

---@type vector[]
local packageLocations = lib.load('data.raw_material_locations')

--[[ state ]]

RawMaterials = {}

---@type Warehouse
local lastWarehouse = nil

local isTaskStarted = false

local createdTaskVehicle = nil
local amountPackagesInVehicle = 0

local pointPeds = {}

local boxInPlayerHand = nil

local taskObjects = {}

--[[ helper functions ]]

---@param coords vector[]
---@param centerIndex integer
---@param max integer
---@return vector[]
local function selectCoordsAroundIndex(coords, centerIndex, max)
    local selected = {}
    local numCoords = #coords
    local left = centerIndex
    local right = centerIndex

    table.insert(selected, coords[centerIndex])

    while #selected < max do
        if left > 1 then
            left = left - 1
            table.insert(selected, coords[left])
        end

        if #selected < max and right < numCoords then
            right = right + 1
            table.insert(selected, coords[right])
        end

        if left <= 1 and right >= numCoords then
            break
        end
    end

    return selected
end

local function deleteTaskVehicle()
    if DoesEntityExist(createdTaskVehicle) then
        SetEntityAsMissionEntity(createdTaskVehicle, true, true)
        DeleteVehicle(createdTaskVehicle)
    end
    createdTaskVehicle = nil
end

local function removeBoxFromPlayerHand()
    if boxInPlayerHand then
        ClearPedTasks(cache.ped)
        if DoesEntityExist(boxInPlayerHand) then
            DeleteEntity(boxInPlayerHand)
        end
    end
    boxInPlayerHand = true
end

local function deletePointPeds()
    for _, v in pairs(pointPeds) do
        if DoesEntityExist(v.box) then DeleteEntity(v.box) end
        if DoesEntityExist(v.entity) then DeletePed(v.entity) end
    end
    pointPeds = {}
end

local function deletePointPed(entity, k)
    for index, v in pairs(pointPeds) do
        if v and v.entity == entity then
            local pointPed = pointPeds[index]
            if DoesEntityExist(pointPed.box) then
                DeleteEntity(pointPed.box)
            end
            if DoesEntityExist(pointPed.entity) then
                ClearPedTasks(pointPed.entity)
                SetEntityAsNoLongerNeeded(pointPed.entity)
            end
            if DoesBlipExist(pointPed.blip) then
                RemoveBlip(pointPed.blip)
            end
            pointPeds[index] = nil
            break
        end
    end
    TriggerServerEvent(_e('server:rawmaterials:deletePointPedByIndex'),
        lastWarehouse.warehouse_index, k)
end

local function deleteTaskObjects()
    for _, v in pairs(taskObjects) do
        if DoesEntityExist(v) then DeleteEntity(v) end
    end
    taskObjects = {}
end

local function createTaskVehicle(spawnCoords, vehicleDetails)
    local model = vehicleDetails.model
    local color = vehicleDetails.color
    lib.requestModel(model)

    local veh = CreateVehicle(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w or 0.0, true, true)
    if not DoesEntityExist(veh) then return false end

    SetVehicleColours(veh, color, color)
    SetEntityCoords(veh, spawnCoords.x, spawnCoords.y, spawnCoords.z)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehicleFuelLevel(veh, 100.0)
    SetVehicleDirtLevel(veh, 0.0)
    SetVehicleDeformationFixed(veh)
    SetModelAsNoLongerNeeded(model)

    Utils.giveVehicleKey(GetVehicleNumberPlateText(veh), veh)

    return veh
end

---@param warehouse Warehouse
---@return table
local function getTaskVehicleDetails(warehouse)
    warehouse = warehouse or lastWarehouse
    local configTaskVehicle = Config.RawMaterials.vehicleUpgrades[warehouse.meta.rm_task_vehicle_level or 1]
    if not configTaskVehicle then
        configTaskVehicle = Config.RawMaterials.vehicleUpgrades[#Config.RawMaterials.vehicleUpgrades]
    end
    return {
        model = configTaskVehicle.model,
        color = configTaskVehicle.color or 1,
        maxPackageCount = configTaskVehicle.maxPackageCount,
        boxOffsets = Config.RawMaterials.vehicleBoxesOffsets[configTaskVehicle.model] or {},
    }
end

local function giveBoxToPed(entity, loop)
    local holdProp = {
        model = 'prop_cs_cardbox_01', coords = vector3(0.05, 0.1, -0.3), rot = vector3(300.0, 250.0, 20.0)
    }

    local model = holdProp.model
    local object = Utils.createObject(model, vector3(0.0, 0.0, 0.0), nil, not loop, not loop, false)
    local pedId = entity or cache.ped
    local boneIndex = GetPedBoneIndex(pedId, 57005)

    AttachEntityToEntity(object, pedId, boneIndex,
        holdProp.coords.x, holdProp.coords.y, holdProp.coords.z,
        holdProp.rot.x, holdProp.rot.y, holdProp.rot.z,
        true, true, false, true, 1, true)

    local animDict = 'anim@heists@box_carry@'
    local animName = 'idle'

    local flag = nil

    local animDict = 'anim@heists@box_carry@'
    local animName = 'idle'
    lib.requestAnimDict(animDict)
    TaskPlayAnim(pedId, animDict, animName, 8.0, 8.0, -1, 49, 0.0, false, false, false)
    RemoveAnimDict(animDict)

    return object
end

local function createTaskPed(coords, rotateBlip)
    local models = {
        'u_m_m_aldinapoli', 'a_f_m_eastsa_02', 'a_m_m_farmer_01', 'a_f_y_business_02',
        'a_m_m_hasjew_01', 'a_f_y_yoga_01', 'g_f_y_vagos_01', 'g_m_y_korlieut_01',
        'g_f_y_ballas_01', 'g_m_y_mexgoon_03',
    }

    local model = models[math.random(#models)]

    if IsModelValid(model) then
        lib.requestModel(model)
        local createdPed = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, false)

        if DoesEntityExist(createdPed) then
            SetEntityRotation(createdPed, 0.0, 0.0, coords.w)
            SetPedDefaultComponentVariation(createdPed)
            SetPedDiesWhenInjured(createdPed, false)
            SetEntityInvincible(createdPed, true)
            FreezeEntityPosition(createdPed, true)
            TaskSetBlockingOfNonTemporaryEvents(createdPed, true)
            SetBlockingOfNonTemporaryEvents(createdPed, true)
            SetModelAsNoLongerNeeded(model)
            local npcBlip = Utils.addBlip(createdPed,
                { scale = 0.7, color = 5, sprite = 270, text = locale('raw_material') }, rotateBlip)

            local object = giveBoxToPed(createdPed, true)
            pointPeds[#pointPeds + 1] = { entity = createdPed, box = object, blip = npcBlip }
            return createdPed
        end
        return false
    end
    return false
end

local function createCollectionPoints(max)
    local locations = packageLocations
    local centerIndex = math.random(1, #locations)
    local pointCount = math.min(max, #locations)

    local selectedCoords = selectCoordsAroundIndex(locations, centerIndex, pointCount)

    for k, value in pairs(selectedCoords) do
        local npc = createTaskPed(value, k == 1)
        if npc then
            lib.points.new({
                npc = npc,
                coords = value,
                distance = 1.5,
                onEnter = function()
                    Utils.showTextUI('[E] ' .. locale('take_package'))
                end,
                nearby = function(self)
                    if IsControlJustPressed(0, 38) then
                        deletePointPed(self.npc, k)
                        boxInPlayerHand = giveBoxToPed(cache.ped)
                        RawMaterials.onPlayerPickUpBox()
                        Utils.hideTextUI()
                        self:remove()
                        return
                    end
                end,
                onExit = function()
                    Utils.hideTextUI()
                end
            })
        end
    end
    TriggerServerEvent(_e('server:rawmaterials:createTemporaryCollectionPoints'),
        lastWarehouse.warehouse_index, selectedCoords)
end

local function createEndCoordinatePoint(pointCenter)
    local groundZ = Utils.getGroundZ(pointCenter)
    pointCenter = vector3(pointCenter.x, pointCenter.y, groundZ)
    lib.points.new({
        coords = pointCenter,
        distance = 15.0,
        onEnter = function()
            if amountPackagesInVehicle > 0 then
                Utils.showTextUI('[E] ' .. locale('finish_task'))
            end
        end,
        nearby = function(self)
            if amountPackagesInVehicle > 0 then
                DrawMarker(30, self.coords.x, self.coords.y, self.coords.z + .1, 0.0, 0.0, 0.0, 90.0,
                    0.0, 0.0, 2.0, 1.0, 3.5, 232, 14, 68, 100, false, false, 2, false)

                if self.currentDistance < 5.0 and IsControlJustPressed(0, 38) then
                    RawMaterials.onTaskFinished()
                    Utils.hideTextUI()
                    self:remove()
                    return
                end
            end
        end,
        onExit = function()
            Utils.hideTextUI()
        end
    })
end

--[[ functions ]]

function RawMaterials.onTaskFinished()
    lib.callback.await(_e('server:rawmaterials:onTaskFinished'), false,
        lastWarehouse.warehouse_index, amountPackagesInVehicle)
    RawMaterials.clear()

    Utils.notify(locale('raw_materials_putin_storage'), 'success')
end

function RawMaterials.onBoxPutInVehicle()
    local taskVehicle = createdTaskVehicle
    if DoesEntityExist(taskVehicle) then
        local nextBoxIndex = amountPackagesInVehicle + 1
        local holdCoords = getTaskVehicleDetails().boxOffsets
        local newHoldCoord = holdCoords[nextBoxIndex]

        if not newHoldCoord then
            newHoldCoord = vector3(holdCoords[1])
        end

        local model = 'prop_cs_cardbox_01'
        local object = Utils.createObject(model, newHoldCoord, nil, true, false, false)

        AttachEntityToEntity(object, taskVehicle, nil,
            newHoldCoord.x, newHoldCoord.y, newHoldCoord.z,
            0.0, 0.0, 90.0,
            false, false, false, false, 0, true
        )

        table.insert(taskObjects, object)
        amountPackagesInVehicle = amountPackagesInVehicle + 1

        for i = 2, 3 do SetVehicleDoorShut(taskVehicle, i) end

        if amountPackagesInVehicle >= getTaskVehicleDetails().maxPackageCount then
            Utils.notify(locale('raw_material_vehicle_full'), 'inform', 5000)
        end
    end
end

function RawMaterials.onPlayerPickUpBox()
    Citizen.CreateThread(function()
        local taskVehicle = createdTaskVehicle
        if DoesEntityExist(taskVehicle) then
            local textUI = false

            for i = 2, 3 do SetVehicleDoorOpen(taskVehicle, i, false, false) end

            while boxInPlayerHand do
                local wait = 500
                local playerPed, playerPos = cache.ped, GetEntityCoords(cache.ped)

                local targetPos = GetOffsetFromEntityInWorldCoords(taskVehicle, 0.0, -3.5, 0.0)
                local distFromTarget = #(playerPos - targetPos)
                local nearTarget = distFromTarget < 1.5

                if nearTarget and not textUI then
                    Utils.showTextUI('[E] ' .. locale('put_box'))
                    textUI = true
                elseif not nearTarget and textUI then
                    Utils.hideTextUI()
                    textUI = false
                end

                if nearTarget then
                    wait = 5
                    if IsControlJustPressed(0, 38) then
                        removeBoxFromPlayerHand()
                        Utils.hideTextUI()
                        RawMaterials.onBoxPutInVehicle()
                        break
                    end
                end

                Citizen.Wait(wait)
            end
        else
            removeBoxFromPlayerHand()
            Utils.hideTextUI()
            RawMaterials.onBoxPutInVehicle()
        end
    end)
end

function RawMaterials.clear()
    if isTaskStarted then
        TriggerServerEvent(_e('server:rawmaterials:onTaskCancelled'), lastWarehouse.warehouse_index)
    end
    removeBoxFromPlayerHand()
    deleteTaskObjects()
    deletePointPeds()
    deleteTaskVehicle()
    amountPackagesInVehicle = 0
    lastWarehouse = nil
    isTaskStarted = false
end

function RawMaterials.isTaskStarted()
    return isTaskStarted
end

---@param lWh Warehouse
---@return table
function RawMaterials.getTaskVehicleDetails(lWh)
    return getTaskVehicleDetails(lWh)
end

---@param spawnCoords vector4
---@param lWh Warehouse
---@return boolean|integer
function RawMaterials.createTaskVehicle(spawnCoords, lWh)
    return createTaskVehicle(spawnCoords, getTaskVehicleDetails(lWh))
end

--[[ events ]]

RegisterNUICallback('nui:rawmaterials:startCollection', function(_, resultCallback)
    local warehouseIndex = client.inWarehouse.warehouse_index
    if lib.callback.await(_e('server:rawmaterials:IsTaskAlreadyBeing'), false, warehouseIndex) then
        client.sendReactMessage('ui:setAlert',
            { text = locale('raw_material_task_already_being'), type = 'error' })
        return resultCallback(false)
    end

    isTaskStarted = true
    TriggerServerEvent(_e('server:rawmaterials:onTaskStarted'), warehouseIndex)

    client.hideUI()
    lastWarehouse = client.inWarehouse
    Warehouse.getOutside(warehouseIndex)

    while client.inWarehouse do Citizen.Wait(1) end

    local taskVehicleCoords = Warehouse.getDataByIndex(warehouseIndex).taskVehicleSpawnCoords
    local taskVehicleDetails = getTaskVehicleDetails()
    createdTaskVehicle = createTaskVehicle(taskVehicleCoords, taskVehicleDetails)

    amountPackagesInVehicle = 0

    Utils.addBlip(createdTaskVehicle, { color = 15, scale = 0.7, sprite = 67, text = locale('task_vehicle') }, true)
    Utils.notify(locale('rawmaterial_task_started'), 'success', 3000)

    createEndCoordinatePoint(taskVehicleCoords)
    createCollectionPoints(taskVehicleDetails.maxPackageCount)

    resultCallback(true)
end)

RegisterNUICallback('nui:rawmaterials:upgradeVehicle', function(_, resultCallback)
    local warehouseIndex = client.inWarehouse.warehouse_index

    local response = lib.callback.await(_e('server:rawmaterials:upgradeVehicle'), false,
        client.inWarehouse.warehouse_index)

    if response.error then
        client.sendReactMessage('ui:setAlert', { text = response.error, type = 'error' })
    end

    resultCallback(true)
end)

RegisterNUICallback('nui:rawmaterials:upgradeMaxStock', function(_, resultCallback)
    local warehouseIndex = client.inWarehouse.warehouse_index

    local response = lib.callback.await(_e('server:rawmaterials:upgradeMaxStock'), false,
        client.inWarehouse.warehouse_index)

    if response.error then
        client.sendReactMessage('ui:setAlert', { text = response.error, type = 'error' })
    end

    resultCallback(true)
end)
