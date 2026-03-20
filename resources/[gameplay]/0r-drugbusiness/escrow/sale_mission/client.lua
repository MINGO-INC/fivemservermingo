--[[ require ]]

local Utils = require 'modules.utils.client'

---@type vector4[]
local deliveryLocations = lib.load('data.sale_mission_locations')

--[[ state ]]

SaleMission = {}

local AGGRESSIVE_GROUP = 'AGGRESSIVE'

local isTaskStarted = false
---@type Warehouse
local lastWarehouse = nil

local amountPackagesInVehicle = 0
local maxPackageAmount = 0
local createdTaskVehicle = nil

local lastPointLocationIndex = 0
local pointPeds = {}
local pointVehicle = nil

local boxInPlayerHand = nil
local taskObjects = {}

--[[ helper functions ]]

local function deleteTaskObjects()
    for _, v in pairs(taskObjects) do
        if DoesEntityExist(v.entity) then DeleteEntity(v.entity) end
    end
    taskObjects = {}
end

local function createEndCoordinatePoint(pointCenter)
    local groundZ = Utils.getGroundZ(pointCenter)
    pointCenter = vector3(pointCenter.x, pointCenter.y, groundZ)
    lib.points.new({
        coords = pointCenter,
        distance = 15.0,
        onEnter = function()
            if amountPackagesInVehicle < maxPackageAmount then
                Utils.showTextUI('[E] ' .. locale('finish_task'))
            end
        end,
        nearby = function(self)
            if amountPackagesInVehicle < maxPackageAmount then
                DrawMarker(30, self.coords.x, self.coords.y, self.coords.z + .1, 0.0, 0.0, 0.0, 90.0,
                    0.0, 0.0, 2.0, 1.0, 3.5, 232, 14, 68, 100, false, false, 2, false)

                if self.currentDistance < 5.0 and IsControlJustPressed(0, 38) then
                    SaleMission.onTaskFinished()
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

local function deleteTaskVehicle()
    if DoesEntityExist(createdTaskVehicle) then
        SetEntityAsMissionEntity(createdTaskVehicle, true, true)
        DeleteVehicle(createdTaskVehicle)
    end
    createdTaskVehicle = nil
end

local function deletePointPeds()
    for _, v in pairs(pointPeds) do
        if DoesEntityExist(v.entity) then
            DeletePed(v.entity)
        end
    end
    pointPeds = {}
end

local function deletePointVehicle(noLonger)
    if DoesEntityExist(pointVehicle) then
        SetEntityAsMissionEntity(pointVehicle, true, true)
        if not noLonger then
            DeleteEntity(pointVehicle)
        else
            SetEntityAsNoLongerNeeded(pointVehicle)
        end
    end
    pointVehicle = nil
end

local function removeBoxFromPlayerHand()
    if boxInPlayerHand then
        ClearPedTasks(cache.ped)
        if DoesEntityExist(boxInPlayerHand) then
            DeleteEntity(boxInPlayerHand)
        end
    end
    boxInPlayerHand = nil
end

local function removeBoxFromVehicle()
    for key, value in pairs(taskObjects) do
        if value.type == 'vehicle_box' then
            DeleteEntity(value.entity)
            table.remove(taskObjects, key)
            break
        end
    end
    amountPackagesInVehicle -= 1
end

local function giveBoxToPed(entity)
    local holdProp = {
        model = 'prop_cs_cardbox_01', coords = vector3(0.05, 0.1, -0.3), rot = vector3(300.0, 250.0, 20.0)
    }

    local model = holdProp.model
    local object = Utils.createObject(model, vector3(0.0, 0.0, 0.0), nil, true, false, false)
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

local function createPointPed(model, coords)
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
            pointPeds[#pointPeds + 1] = { entity = createdPed }
            return createdPed
        end
        return false
    end
    return false
end

local function createPointVehicle(model, spawnCoords)
    lib.requestModel(model)

    local vehicle = CreateVehicle(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w or 0.0, false, false)
    if not DoesEntityExist(vehicle) then return false end
    FreezeEntityPosition(vehicle, true)
    SetEntityInvincible(vehicle, true)
    SetEntityCoords(vehicle, spawnCoords.x, spawnCoords.y, spawnCoords.z)
    SetVehicleDoorOpen(vehicle, 5, false, false)
    SetModelAsNoLongerNeeded(model)
    Utils.addBlip(vehicle,
        { scale = 0.7, color = 5, sprite = 270, text = locale('sale_mission') }, true)
    pointVehicle = vehicle
end

local function createBoxesInVehicle(model, coords)
    local taskVehicleDetails = RawMaterials.getTaskVehicleDetails(lastWarehouse)
    local stock = lastWarehouse.packaged_product_stock
    local packageCount = math.min(taskVehicleDetails.maxPackageCount, math.floor(stock / 10))
    maxPackageAmount = packageCount
    amountPackagesInVehicle = packageCount
    local packageCoords = taskVehicleDetails.boxOffsets
    local taskVehicle = createdTaskVehicle

    local boxModel = 'prop_cs_cardbox_01'
    for i = 1, packageCount, 1 do
        local newHoldCoord = packageCoords[i]
        if newHoldCoord then
            local object = Utils.createObject(boxModel, newHoldCoord, nil, true, false, false)

            AttachEntityToEntity(object, taskVehicle, nil,
                newHoldCoord.x, newHoldCoord.y, newHoldCoord.z,
                0.0, 0.0, 90.0,
                false, false, false, false, 0, true
            )
            table.insert(taskObjects, { entity = object, type = 'vehicle_box' })
        end
    end
end

local function doPayment()
    local amount = Config.SaleMission.feePerPackage
    local chance = math.random()
    if chance > .95 then
        AddRelationshipGroup(AGGRESSIVE_GROUP)
        for _, value in pairs(pointPeds) do
            local ped = value.entity
            FreezeEntityPosition(ped, false)
            TaskSetBlockingOfNonTemporaryEvents(ped, false)
            SetBlockingOfNonTemporaryEvents(ped, false)
            SetPedDiesWhenInjured(createdPed, true)
            SetEntityInvincible(createdPed, false)
            SetPedCombatAttributes(ped, 46, 1)
            SetPedFleeAttributes(ped, 0, 0)
            SetPedCombatRange(ped, 2)

            SetPedRelationshipGroupHash(ped, GetHashKey(AGGRESSIVE_GROUP))
            SetEntityCanBeDamagedByRelationshipGroup(ped, false, GetHashKey(AGGRESSIVE_GROUP))
            SetRelationshipBetweenGroups(4, GetHashKey('PLAYER'), GetHashKey(AGGRESSIVE_GROUP))
            SetRelationshipBetweenGroups(4, GetHashKey(AGGRESSIVE_GROUP), GetHashKey('PLAYER'))
            TaskCombatPed(ped, cache.ped, 0, 16)
            SetPedKeepTask(ped, true)
            SetPedHasAiBlip(ped, true)
            SetPedAiBlipHasCone(ped, false)
            GiveWeaponToPed(ped, GetHashKey('WEAPON_PISTOL'), 999, false, true)
        end
        Utils.notify(locale('no_payment_salemission'), 'error', 3000)
        return false
    elseif chance > .75 then
        amount -= amount * .20
    elseif chance > .55 then
        amount += amount * .20
    end
    lib.callback.await(_e('server:salemission:doPayment'), false, amount)
    Utils.notify(locale('customer_made_payment'), 'success', 3000)
    return true
end

local function createDeliveryPoint()
    if amountPackagesInVehicle <= 0 then
        return Utils.notify(locale('salemission_vehicle_empty'), 'inform', 3000)
    end
    Utils.notify(locale('sale_mission_started'), 'success', 3000)
    local newLocationIndex = lastPointLocationIndex + 1
    local location = deliveryLocations[newLocationIndex]
    if not location then
        location = deliveryLocations[1]
        newLocationIndex = 1
    end
    lastPointLocationIndex = newLocationIndex

    local guards = { 's_m_m_bouncer_01', 'cs_joeminuteman' }
    local boss = 'ig_siemonyetarian'
    local vehicle = 'tailgater'
    for key, model in pairs(guards) do
        local offset = key == 1 and vector3(2.5, -2.5, 0.0) or vector3(-2.5, -2.5, 0.0)
        local offsetLocation = GetOffsetFromCoordAndHeadingInWorldCoords(location.x, location.y, location.z, location.w,
            offset.x, offset.y, offset.z)
        createPointPed(model, vector4(offsetLocation.x, offsetLocation.y, offsetLocation.z, location.w))
    end
    local offsetLocation = GetOffsetFromCoordAndHeadingInWorldCoords(location.x, location.y, location.z, location.w,
        2.5, 0.0, 0.0)
    createPointPed(boss, vector4(offsetLocation.x, offsetLocation.y, offsetLocation.z, location.w))
    offsetLocation = GetOffsetFromCoordAndHeadingInWorldCoords(location.x, location.y, location.z, location.w,
        0.0, -2.5, -1.0)
    createPointVehicle(vehicle, vector4(offsetLocation.x, offsetLocation.y, offsetLocation.z, (location.w + 180.0) % 360))

    lib.points.new({
        coords = GetOffsetFromEntityInWorldCoords(pointVehicle, 0.0, -3.0, 0.0),
        distance = 1.0,
        nearby = function(self)
            if boxInPlayerHand and IsControlJustPressed(0, 38) then
                Utils.hideTextUI()
                removeBoxFromPlayerHand()
                SetVehicleDoorShut(pointVehicle, 5, false)
                SetVehicleDoorShut(createdTaskVehicle, 2, false)
                SetVehicleDoorShut(createdTaskVehicle, 3, false)
                local getinVehicle = doPayment()
                if getinVehicle then
                    local targetCoords = vector3(100.0, 200.0, 20.0)
                    local driveStyle = 786603
                    FreezeEntityPosition(pointVehicle, false)
                    for _, v in pairs(pointPeds) do
                        FreezeEntityPosition(v.entity, false)
                    end
                    local driverPed = nil
                    local lastPed = nil
                    for i, v in pairs(pointPeds) do
                        local ped = v.entity
                        if DoesEntityExist(ped) and not IsPedInAnyVehicle(ped, false) then
                            local seatIndex = (i == 1) and -1 or (i - 1)
                            if seatIndex == -1 then
                                driverPed = ped
                            end
                            lastPed = ped
                            TaskEnterVehicle(ped, pointVehicle, 5000, seatIndex, 3, 1, 0)
                        end
                    end
                    local timeout = 0
                    while lastPed and not IsPedInVehicle(lastPed, pointVehicle, false) and timeout < 5000 do
                        Citizen.Wait(100)
                        timeout = timeout + 100
                    end
                    Citizen.Wait(2500)
                    SetVehicleDoorsShut(pointVehicle, true)
                    SetVehicleDoorsLocked(pointVehicle, 2)
                    if IsPedInVehicle(driverPed, pointVehicle, false) then
                        TaskVehicleDriveToCoord(driverPed, pointVehicle,
                            targetCoords.x, targetCoords.y, targetCoords.z,
                            20.0, 0, GetEntityModel(pointVehicle), driveStyle, 5.0, true)
                    end
                    Citizen.Wait(1000)
                end
                for i, v in pairs(pointPeds) do
                    if i ~= 1 then
                        DeleteEntity(v.entity)
                    else
                        SetEntityAsNoLongerNeeded(v.entity)
                    end
                end
                deletePointVehicle(true)
                pointPeds = {}
                if math.random() < .20 then
                    Utils.triggerPoliceAlert('on_sale_delivery_completed')
                end
                createDeliveryPoint()
                self:remove()
                return
            end
        end,
        onEnter = function()
            if boxInPlayerHand then Utils.showTextUI('[E] ' .. locale('deliver_package')) end
        end,
        onExit = function() Utils.hideTextUI() end
    })

    Citizen.CreateThread(function()
        while isTaskStarted do
            local allFound = true
            local pointVehicleCoords = GetEntityCoords(pointVehicle)
            local groundZ, found = Utils.getGroundZ(pointVehicleCoords)
            if found then
                SetEntityCoords(pointVehicle, pointVehicleCoords.x, pointVehicleCoords.y, groundZ)
            end
            for _, pointPed in pairs(pointPeds) do
                local pointPedCoords = GetEntityCoords(pointPed.entity)
                local pedGroundZ, pedFound = Utils.getGroundZ(pointPedCoords)
                if pedFound then
                    SetEntityCoords(pointPed.entity, pointPedCoords.x, pointPedCoords.y, pedGroundZ)
                else
                    allFound = false
                end
            end
            if allFound then return end
            Citizen.Wait(500)
        end
    end)
end

local function giveBoxThread()
    Citizen.CreateThread(function()
        local textUI = false
        while isTaskStarted and amountPackagesInVehicle > 0 and DoesEntityExist(createdTaskVehicle) do
            local wait = 1000
            local pedCoords = GetEntityCoords(cache.ped)
            local bootCoords = GetOffsetFromEntityInWorldCoords(createdTaskVehicle, 0.0, -3.0, 0.0)

            if #(pedCoords - bootCoords) < 1.0 and not boxInPlayerHand then
                wait = 5
                if not textUI then
                    textUI = true
                    Utils.showTextUI('[E] ' .. locale('take_package'))
                end
                if IsControlJustPressed(0, 38) then
                    SetVehicleDoorOpen(createdTaskVehicle, 2, false, false)
                    SetVehicleDoorOpen(createdTaskVehicle, 3, false, false)
                    Citizen.Wait(500)
                    boxInPlayerHand = giveBoxToPed(cache.ped)
                    removeBoxFromVehicle()
                end
            elseif textUI then
                textUI = false
                Utils.hideTextUI()
            end

            Citizen.Wait(wait)
        end
        deleteTaskObjects()
        if textUI then Utils.hideTextUI() end
    end)
end

--[[ functions ]]

function SaleMission.clear()
    if isTaskStarted then
        TriggerServerEvent(_e('server:salemission:onTaskCancelled'), lastWarehouse.warehouse_index)
    end
    deleteTaskObjects()
    deleteTaskVehicle()
    deletePointVehicle()
    deletePointPeds()
    removeBoxFromPlayerHand()
    amountPackagesInVehicle = 0
    maxPackageAmount = 0
    lastWarehouse = nil
    isTaskStarted = false
    lastPointLocationIndex = 0
end

function SaleMission.onTaskFinished()
    lib.callback.await(_e('server:salemission:onTaskFinished'), false,
        lastWarehouse.warehouse_index)
    SaleMission.clear()
    Utils.notify(locale('sale_mission_finished'), 'success')
end

function SaleMission.isTaskStarted()
    return isTaskStarted
end

--[[ events ]]

RegisterNUICallback('nui:salemission:start', function(_, resultCallback)
    local response = lib.callback.await(_e('server:salemission:start'), false, client.inWarehouse.warehouse_index)
    if response.error then
        Utils.notify(response.error, 'error')
        return resultCallback(false)
    end

    isTaskStarted = true
    client.hideUI()
    lastWarehouse = client.inWarehouse
    Warehouse.getOutside(client.inWarehouse.warehouse_index)
    while client.inWarehouse do Citizen.Wait(1) end

    local taskVehicleCoords = Warehouse.getDataByIndex(lastWarehouse.warehouse_index).taskVehicleSpawnCoords
    createdTaskVehicle = RawMaterials.createTaskVehicle(taskVehicleCoords, lastWarehouse)
    Utils.addBlip(createdTaskVehicle, { color = 15, scale = 0.7, sprite = 67, text = locale('task_vehicle') }, true)

    createBoxesInVehicle()
    createEndCoordinatePoint(taskVehicleCoords)
    shuffleTable(deliveryLocations)
    createDeliveryPoint()
    giveBoxThread()
    lib.callback.await(_e('server:salemission:onStart'), false, lastWarehouse.warehouse_index)
    resultCallback(true)
end)
