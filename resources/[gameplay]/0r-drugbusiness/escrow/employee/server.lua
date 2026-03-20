--[[ require ]]

local db = require 'modules.mysql.server'

--[[ state ]]

Employee = {}

--[[ functions ]]

---@param warehouse Warehouse
function Employee.areSalariesPaid(warehouse)
    local latestPay = warehouse.meta.last_employee_salary_paid_at
    if not latestPay then return false end

    local timeDifference = os.time() - latestPay
    return -1 < timeDifference and timeDifference <= 60 * 60 * 24
end

---@param warehouse Warehouse
function Employee.getTotalSalaries(warehouse)
    local totalEmployee = warehouse.employee_count
    local unitSalaryFee = Config.Employee.salary_fee
    return totalEmployee * unitSalaryFee
end

--[[ events ]]

lib.callback.register(_e('server:employee:haveToPaySalaries'), function(source, warehouseIndex)
    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then return false end
    if Employee.areSalariesPaid(warehouse) then
        return false
    end
    return Employee.getTotalSalaries(warehouse)
end)

lib.callback.register(_e('server:employee:paySalaries'), function(source, warehouseIndex)
    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then return { error = locale('warehouse_not_found') } end

    if warehouse.employee_count < 1 then return {} end

    if Employee.areSalariesPaid(warehouse) then
        return {}
    end

    local totalSalaries = Employee.getTotalSalaries(warehouse)

    local xPlayerBankAccountMoney = server.getPlayerBalance(source, 'bank')

    if xPlayerBankAccountMoney < totalSalaries then
        return { error = locale('not_enough_money_in_bank') }
    end

    server.playerRemoveMoney(source, 'bank', totalSalaries)

    warehouse.meta.last_employee_salary_paid_at = os.time()

    Warehouse.onUpdate(warehouseIndex)
    db.updateWarehouseMeta(warehouseIndex, warehouse.meta)

    return {}
end)

lib.callback.register(_e('server:employee:newRecruitment'), function(source, warehouseIndex, amount)
    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then return { error = locale('warehouse_not_found') } end

    local maxEmployeesCount = 10

    if warehouse.employee_count >= maxEmployeesCount or
        warehouse.employee_count + amount > maxEmployeesCount
    then
        return { error = locale('can_not_be_bought_more') }
    end

    if warehouse.employee_count > 0 and not Employee.areSalariesPaid(warehouse) then
        return { error = locale('first_have_to_pay_salaries') }
    end

    local xPlayerBankAccountMoney = server.getPlayerBalance(source, 'bank')

    local recruitmentFee = Config.Employee.recruitment_fee * amount

    if xPlayerBankAccountMoney < recruitmentFee then
        return { error = locale('not_enough_money_in_bank') }
    end

    server.playerRemoveMoney(source, 'bank', recruitmentFee)

    warehouse.employee_count = warehouse.employee_count + amount
    Warehouse.onUpdate(warehouseIndex)

    db.updateWarehouseEmployeeCount(warehouseIndex, warehouse.employee_count)

    return { amount = amount }
end)

lib.callback.register(_e('server:employee:dismiss'), function(source, warehouseIndex, amount)
    local warehouse = Warehouse.getSoldByIndex(warehouseIndex)
    if not warehouse then return { error = locale('warehouse_not_found') } end

    local previousCount = warehouse.employee_count
    warehouse.employee_count = math.max(0, previousCount - amount)

    if warehouse.employee_count < WAREHOUSE_MIN_EMPLOYEE_FOR_WORK then
        Warehouse.stopWorking(warehouseIndex)
    else
        Warehouse.onUpdate(warehouseIndex)
    end

    db.updateWarehouseEmployeeCount(warehouseIndex, warehouse.employee_count)

    local removedAmount = previousCount - warehouse.employee_count

    return { removed = removedAmount }
end)
