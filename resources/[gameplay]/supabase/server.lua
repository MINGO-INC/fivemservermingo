-- supabase: server.lua
-- Supabase REST API client for FiveM
--
-- Credentials are read from convars set in server.cfg:
--   set supabase_url  "https://<project-ref>.supabase.co"
--   set supabase_key  "<service_role_key>"
--
-- Exported functions (call from any other server-side resource):
--   exports['supabase']:Insert(table, data [, callback])
--   exports['supabase']:Select(table, query [, callback])
--   exports['supabase']:Upsert(table, data [, callback])
--   exports['supabase']:Update(table, query, data [, callback])
--   exports['supabase']:isConfigured()

local SUPABASE_URL = GetConvar('supabase_url', '')
local SUPABASE_KEY = GetConvar('supabase_key', '')

if SUPABASE_URL == '' or SUPABASE_KEY == '' then
    print('^3[Supabase] WARNING: supabase_url or supabase_key convar is not set. '
        .. 'Supabase integration is disabled. Set them in server.cfg.^0')
end

local function isConfigured()
    return SUPABASE_URL ~= '' and SUPABASE_KEY ~= ''
end

-- Build the common request headers for every Supabase REST call.
local function buildHeaders()
    return {
        ['apikey']        = SUPABASE_KEY,
        ['Authorization'] = 'Bearer ' .. SUPABASE_KEY,
        ['Content-Type']  = 'application/json',
        ['Prefer']        = 'return=representation',
    }
end

-- Insert one row into a Supabase table.
-- @param tableName  string   – target table
-- @param data       table    – Lua table to insert (JSON-encoded automatically)
-- @param callback   function – optional: called with (row, statusCode)
local function Insert(tableName, data, callback)
    if not isConfigured() then return end

    local url  = ('%s/rest/v1/%s'):format(SUPABASE_URL, tableName)
    local body = json.encode(data)

    PerformHttpRequest(url, function(statusCode, responseText, _responseHeaders)
        if statusCode ~= 201 then
            print(('[Supabase] INSERT %s failed (%d): %s'):format(tableName, statusCode, responseText or ''))
        end
        if callback then
            callback(statusCode == 201 and json.decode(responseText) or nil, statusCode)
        end
    end, 'POST', body, buildHeaders())
end

-- Select rows from a Supabase table using PostgREST query syntax.
-- @param tableName  string   – target table
-- @param query      string   – query string, e.g. 'id=eq.5'  (may be empty or nil)
-- @param callback   function – called with (rows, statusCode); rows is nil on error
local function Select(tableName, query, callback)
    if not isConfigured() then
        if callback then callback(nil, 0) end
        return
    end

    local url     = query ~= nil and query ~= ''
        and ('%s/rest/v1/%s?%s'):format(SUPABASE_URL, tableName, query)
        or  ('%s/rest/v1/%s'):format(SUPABASE_URL, tableName)
    local headers = buildHeaders()
    headers['Prefer'] = 'count=exact'

    PerformHttpRequest(url, function(statusCode, responseText, _responseHeaders)
        if statusCode ~= 200 then
            print(('[Supabase] SELECT %s failed (%d): %s'):format(tableName, statusCode, responseText or ''))
            if callback then callback(nil, statusCode) end
            return
        end
        if callback then callback(json.decode(responseText), statusCode) end
    end, 'GET', '', headers)
end

-- Upsert (insert or update) a row using Supabase's conflict resolution.
-- @param tableName  string   – target table
-- @param data       table    – Lua table to upsert
-- @param callback   function – optional: called with (row, statusCode)
local function Upsert(tableName, data, callback)
    if not isConfigured() then return end

    local url     = ('%s/rest/v1/%s'):format(SUPABASE_URL, tableName)
    local body    = json.encode(data)
    local headers = buildHeaders()
    headers['Prefer'] = 'resolution=merge-duplicates,return=representation'

    PerformHttpRequest(url, function(statusCode, responseText, _responseHeaders)
        if statusCode ~= 200 and statusCode ~= 201 then
            print(('[Supabase] UPSERT %s failed (%d): %s'):format(tableName, statusCode, responseText or ''))
        end
        if callback then
            callback((statusCode == 200 or statusCode == 201) and json.decode(responseText) or nil, statusCode)
        end
    end, 'POST', body, headers)
end

-- Update rows matching a PostgREST query.
-- @param tableName  string   – target table
-- @param query      string   – filter, e.g. 'id=eq.5'
-- @param data       table    – Lua table with fields to update
-- @param callback   function – optional: called with (rows, statusCode)
local function Update(tableName, query, data, callback)
    if not isConfigured() then return end

    local url  = ('%s/rest/v1/%s?%s'):format(SUPABASE_URL, tableName, query)
    local body = json.encode(data)

    PerformHttpRequest(url, function(statusCode, responseText, _responseHeaders)
        if statusCode ~= 200 then
            print(('[Supabase] UPDATE %s failed (%d): %s'):format(tableName, statusCode, responseText or ''))
        end
        if callback then
            callback(statusCode == 200 and json.decode(responseText) or nil, statusCode)
        end
    end, 'PATCH', body, buildHeaders())
end

exports('Insert',       Insert)
exports('Select',       Select)
exports('Upsert',       Upsert)
exports('Update',       Update)
exports('isConfigured', isConfigured)
