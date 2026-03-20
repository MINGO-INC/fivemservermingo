--[[ All helper functions and variables are defined here ]]

---@alias FrameworkType 'esx'|'qb'|'qbx'

--[[ Start ox_lib.locale ]]
lib.locale()

shared = {}
shared.resource = GetCurrentResourceName()

---Checks if the given resource is started.
---@param resourceName string
---@return boolean
function shared.isResourceStart(resourceName)
    return GetResourceState(resourceName) == 'started'
end

---Returns the name of the active framework ('qb', 'esx', 'qbx').
---@return FrameworkType|nil
function shared.getFrameworkName()
    if shared.isResourceStart('es_extended') then
        return 'esx'
    elseif shared.isResourceStart('qbx_core') then
        return 'qbx'
    elseif shared.isResourceStart('qb-core') then
        return 'qb'
    end
    return nil
end

---Retrieves the core object of the active framework.
---@return table|nil
function shared.getFrameworkObject()
    local frameworkName = shared.getFrameworkName()
    if not frameworkName then return nil end
    if frameworkName == 'esx' then
        return exports['es_extended']:getSharedObject()
    elseif frameworkName == 'qbx' then
        return exports['qb-core']:GetCoreObject()
    elseif frameworkName == 'qb' then
        return exports['qb-core']:GetCoreObject()
    end
end

---Formats and returns a string combining the script name and event.
---Created for the convenience of the developer.
---@param event string
---@return string
function _e(event)
    return shared.resource .. ':' .. event
end

function shuffleTable(tbl)
    math.randomseed(IsDuplicityVersion() and os.time() or GetGameTimer())
    local len = #tbl
    for i = len, 2, -1 do
        local j = math.random(1, i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

function shared.deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[shared.deepCopy(orig_key)] = shared.deepCopy(orig_value)
        end
        setmetatable(copy, shared.deepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function shared.debug(...)
    if not Config.debug then return end
    lib.print.info(...)
end

function shared.useExport(resource, export, ...)
    return exports[resource][export](nil, ...)
end

shared.framework = shared.getFrameworkName()
