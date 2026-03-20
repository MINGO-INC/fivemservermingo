--[[ Main Client File]]

client = {
    framework = shared.getFrameworkObject(),
    load = false,
    uiLoad = false,
    uiOpen = false,
    ---@type WarehouseDB
    inWarehouse = nil,
}

--[[ require ]]

require 'modules.bridge.client'

local Utils = require 'modules.utils.client'

--[[ helper functions ]]

local function hideFrame()
    client.sendReactMessage('ui:setVisible', false)
    SetNuiFocus(false, false)
    client.uiOpen = false
end

local function clearClient()
    if client.uiOpen then hideFrame() end
    client.uiOpen = false
    Warehouse.clear()
    SecuritySystem.clear()
    RawMaterials.clear()
    Employee.clear()
    MoneyWashing.clear()
    SaleMission.clear()
    Unauthorized.clear()
end

---Prepare the frontend and send the data
local function setupUI()
    if client.uiLoad then return end
    local defaultLocale = GetConvar('ox:locale', 'en')
    client.sendReactMessage('ui:setupUI', {
        setLocale = lib.loadJson(('locales.%s'):format(defaultLocale)).ui,
        setConfig = {
            BusinessTypes = Config.BusinessTypes,
            SecuritySystemPrice = Config.SecuritySystem.price,
            Stock = Config.Stock,
            Employee = Config.Employee,
            VehicleUpgrades = Config.RawMaterials.vehicleUpgrades,
            RawMaterialStockUpgrades = Config.RawMaterials.stockUpgrades,
            MoneyWashingUpgrades = Config.MoneyWashing.upgrades,
        },
    }, true)
end

--[[ functions ]]

---Sends message to the ReactUI.
---@param action string
---@param data any
function client.sendReactMessage(action, data)
    SendNUIMessage({ action = action, data = data })
end

function client.onPlayerLoad(isLoggedIn)
    if isLoggedIn then
        Profile.load()
        Warehouse.load()
        Unauthorized.load()
    else
        clearClient()
        Utils.hideTextUI()
    end
    client.load = isLoggedIn
end

function client.setHeadingToObject(entity, model)
    local playerpedId = cache.ped
    local playerCoords = GetEntityCoords(playerpedId)
    if model then
        entity = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z,
            2.0, model, false, false, false)
    end
    if not DoesEntityExist(entity) then return end
    local targetEntCoords = GetEntityCoords(entity)
    local heading = GetHeadingFromVector_2d(targetEntCoords.x - playerCoords.x, targetEntCoords.y - playerCoords.y)
    SetEntityHeading(playerpedId, heading)
    Citizen.Wait(100)
end

function client.hideUI()
    hideFrame()
end

---@param ic vector3
---@param entitySets table<entitySetName, boolean>
function client.loadInteriorEntities(ic, entitySets)
    local interiorID = GetInteriorAtCoords(ic.x, ic.y, ic.z)
    if not IsValidInterior(interiorID) then return end

    PinInteriorInMemory(interiorID)

    for key, value in pairs(entitySets) do
        if value then
            ActivateInteriorEntitySet(interiorID, key)
        else
            DeactivateInteriorEntitySet(interiorID, key)
        end
    end

    RefreshInterior(interiorID)
end

--[[ events ]]

RegisterNUICallback('nui:loadUI', function(_, resultCallback)
    resultCallback(true)
    setupUI()
end)

RegisterNUICallback('nui:onLoadUI', function(_, resultCallback)
    resultCallback(true)
    client.uiLoad = true
end)

RegisterNUICallback('nui:hideFrame', function(_, resultCallback)
    hideFrame()
    resultCallback(true)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= shared.resource then return end
    Citizen.Wait(2000)
    if not client.isPlayerLoaded() then return end
    client.onPlayerLoad(true)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= shared.resource then return end
    client.onPlayerLoad(false)
end)
