--- Meta class definition
---@class Meta
---@field blip_hidden boolean
---@field blip_color integer
---@field max_package_stock number
---@field max_raw_materials_stock number
---@field interior_light boolean
---@field security_system boolean
---@field last_employee_salary_paid_at number
---@field rm_task_vehicle_level number
---@field interior_level number
---@field is_working boolean
---@field last_working_at number
---@field raw_materials_stock_level integer
---@field money_washing_level integer

--- Manager class definition
---@class Manager
---@field identifier string
---@field name string

---@alias BusinessTheme 'weed'|'cocaine'|'meth'

--- Warehouse database structure
---@class WarehouseDB
---@field id number
---@field warehouse_index number
---@field name string
---@field owner_id string
---@field business_theme BusinessTheme
---@field experience number
---@field managers Manager[]
---@field clean_money number
---@field dirty_money number
---@field raw_materials_stock number
---@field water_stock number
---@field gas_stock number
---@field electricity_stock number
---@field packaged_product_stock number
---@field employee_count number
---@field meta Meta
---@field last_processed string
---@field created_at string

-- Optimized Query table with constants and prepared statements
local Query = {
    SELECT_PLAYER_WAREHOUSES = 'SELECT * FROM `0r_drugbusiness_warehouses` WHERE owner_id = ?',
    SELECT_SOLD_WAREHOUSES = 'SELECT * FROM `0r_drugbusiness_warehouses`',
    INSERT_WAREHOUSE =
    'INSERT IGNORE INTO `0r_drugbusiness_warehouses` (warehouse_index,name,owner_id,managers,meta,water_stock,electricity_stock,employee_count,gas_stock) VALUES (?,?,?,?,?,?,?,?,?)',
    UPDATE_WAREHOUSE_NAME = 'UPDATE `0r_drugbusiness_warehouses` SET name = ? WHERE warehouse_index = ?',
    UPDATE_WAREHOUSE_META = 'UPDATE `0r_drugbusiness_warehouses` SET meta = ? WHERE warehouse_index = ?',
    UPDATE_WAREHOUSE_MANAGERS = 'UPDATE `0r_drugbusiness_warehouses` SET managers = ? WHERE warehouse_index = ?',
    DELETE_WAREHOUSE = 'DELETE FROM `0r_drugbusiness_warehouses` WHERE warehouse_index = ? AND owner_id = ?',
    UPDATE_WAREHOUSE_OWNER = 'UPDATE `0r_drugbusiness_warehouses` SET owner_id = ? WHERE warehouse_index = ?',
    UPDATE_WAREHOUSE_STOCKS =
    'UPDATE `0r_drugbusiness_warehouses` SET water_stock = ?, gas_stock = ?, electricity_stock = ? WHERE warehouse_index = ?',
    UPDATE_WAREHOUSE_EMPLOYEE_COUNT =
    'UPDATE `0r_drugbusiness_warehouses` SET employee_count = ? WHERE warehouse_index = ?',
    UPDATE_WAREHOUSE_RAW_MATERIAL =
    'UPDATE `0r_drugbusiness_warehouses` SET raw_materials_stock = ? WHERE warehouse_index = ?',
    UPDATE_WAREHOUSE_AFTER_PROCESSED =
    'UPDATE `0r_drugbusiness_warehouses` SET last_processed = ?, experience = ?, packaged_product_stock = ?, raw_materials_stock = ?, water_stock = ?, gas_stock = ?, electricity_stock = ? WHERE warehouse_index = ?',
    UPDATE_WAREHOUSE_SAFE =
    'UPDATE `0r_drugbusiness_warehouses` SET packaged_product_stock = ?, dirty_money = ?, clean_money = ? WHERE warehouse_index = ?',
    UPDATE_WAREHOUSE_THEME =
    'UPDATE `0r_drugbusiness_warehouses` SET packaged_product_stock = 0, raw_materials_stock = 0, last_processed = NULL, business_theme = ?, meta = ? WHERE warehouse_index = ?',
    SELECT_WAREHOUSE_LOGS =
    'SELECT * FROM `0r_drugbusiness_warehouse_logs` WHERE warehouse_id = ?',
    INSERT_LOG =
    'insert ignore into `0r_drugbusiness_warehouse_logs` (warehouse_id, log_message, log_type) values (?,?,?)'
}

-- Database module with optimized functions
local db = {}

-- Cache frequently used JSON encoding
local jsonEncode = json.encode

--- Get all sold warehouses
---@return WarehouseDB[]
function db.getSoldWarehouses()
    return MySQL.query.await(Query.SELECT_SOLD_WAREHOUSES)
end

--- Insert new warehouse
---@param warehouse Warehouse
---@return any
function db.insertWarehouse(warehouse)
    return MySQL.insert.await(Query.INSERT_WAREHOUSE, {
        warehouse.warehouse_index,
        warehouse.name,
        warehouse.owner_id,
        jsonEncode(warehouse.managers),
        jsonEncode(warehouse.meta),
        warehouse.water_stock,
        warehouse.electricity_stock,
        warehouse.employee_count,
        warehouse.gas_stock,
    })
end

--- Get warehouses by owner
function db.getPlayerWarehouses(owner_id)
    return MySQL.query.await(Query.SELECT_PLAYER_WAREHOUSES, { owner_id })
end

--- Update warehouse name
function db.updateWarehouseName(warehouse_index, newName)
    return MySQL.prepare(Query.UPDATE_WAREHOUSE_NAME, { newName, warehouse_index })
end

--- Update warehouse meta data
function db.updateWarehouseMeta(warehouse_index, newMeta)
    return MySQL.prepare(Query.UPDATE_WAREHOUSE_META, { jsonEncode(newMeta), warehouse_index })
end

--- Update warehouse managers
function db.updateWarehouseManagers(warehouse_index, newManagers)
    return MySQL.prepare(Query.UPDATE_WAREHOUSE_MANAGERS, { jsonEncode(newManagers), warehouse_index })
end

--- Delete warehouse by index and owner
function db.deleteWarehouseByIndex(warehouse_index, owner_id)
    return MySQL.prepare(Query.DELETE_WAREHOUSE, { warehouse_index, owner_id })
end

--- Update warehouse owner
function db.updateWarehouseOwner(warehouse_index, new_owner_id)
    return MySQL.prepare(Query.UPDATE_WAREHOUSE_OWNER, { new_owner_id, warehouse_index })
end

--- Update warehouse utility stocks
function db.updateWarehouseStocks(warehouse_index, water, gas, electricity)
    return MySQL.prepare(Query.UPDATE_WAREHOUSE_STOCKS, { water, gas, electricity, warehouse_index })
end

--- Update employee count
function db.updateWarehouseEmployeeCount(warehouse_index, newEmployeeCount)
    return MySQL.prepare(Query.UPDATE_WAREHOUSE_EMPLOYEE_COUNT, { newEmployeeCount, warehouse_index })
end

--- Update raw material stock
function db.updateWarehouseRawMaterial(warehouse_index, newRawMaterialStock)
    return MySQL.prepare(Query.UPDATE_WAREHOUSE_RAW_MATERIAL, { newRawMaterialStock, warehouse_index })
end

---@param warehouse Warehouse
function db.onWarehouseProcessed(warehouse, currentTime)
    return MySQL.prepare(Query.UPDATE_WAREHOUSE_AFTER_PROCESSED,
        { currentTime,
            warehouse.experience,
            warehouse.packaged_product_stock, warehouse.raw_materials_stock, warehouse.water_stock,
            warehouse.gas_stock, warehouse.electricity_stock, warehouse.warehouse_index })
end

---@param warehouse Warehouse
function db.updateWarehouseSafe(warehouse)
    return MySQL.prepare(Query.UPDATE_WAREHOUSE_SAFE,
        { warehouse.packaged_product_stock, warehouse.dirty_money, warehouse.clean_money, warehouse.warehouse_index })
end

--- Update theme
function db.updateWarehouseTheme(warehouse_index, newTheme, meta)
    return MySQL.prepare(Query.UPDATE_WAREHOUSE_THEME,
        { newTheme, jsonEncode(meta), warehouse_index })
end

function db.getWarehouseLogs(warehouse_index)
    return MySQL.query.await(Query.SELECT_WAREHOUSE_LOGS, { warehouse_index })
end

function db.insertLog(warehouse_index, log_message, log_type)
    return MySQL.insert(Query.INSERT_LOG, { warehouse_index, log_message, log_type })
end

function db.clearOldLogs()
    MySQL.query([[
        DELETE FROM `0r_drugbusiness_warehouse_logs`
        WHERE id NOT IN (
            SELECT id FROM (
                SELECT id FROM `0r_drugbusiness_warehouse_logs`
                WHERE warehouse_id = @warehouse_id
                ORDER BY created_at DESC
                LIMIT 50
            ) AS subquery
        )
        AND warehouse_id = @warehouse_id;
    ]])
end

return db
