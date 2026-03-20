---!!! We do not want you to edit this file.
---!!! There is no need for that.
---!!! Please don't change it if you don't know

---@alias TaskType string

---@class Employee
---@field coords vector4
---@field task TaskType

---@class ThemeInterior
---@field coords vector3
---@field entities table
---@field employees Employee[]

---@type table<BusinessTheme, ThemeInterior>
return {
    ['weed'] = {
        coords = vector3(1051.491, -3196.536, -39.14842),
        employees = {
            { coords = vector4(1053.0112, -3204.7217, -39.1259, 186.7081), task = 'gathering' },
            { coords = vector4(1037.45, -3205.9646, -36.6887, 270.0),      task = 'processing' },
            { coords = vector4(1055.6902, -3192.3442, -39.1447, 323.8720), task = 'gathering' },
            { coords = vector4(1039.2660, -3205.9919, -38.6931, 90.0),     task = 'processing' },
            { coords = vector4(1057.5918, -3197.1665, -39.1299, 169.9108), task = 'gathering' },
            { coords = vector4(1034.8, -3206.2244, -37.6963, 90.0),        task = 'processing' },
            { coords = vector4(1061.0153, -3202.9333, -39.1491, 265.5640), task = 'gathering' },
            { coords = vector4(1032.85, -3206.0364, -37.6948, -90.0),      task = 'processing' },
            { coords = vector4(1060.7415, -3195.7976, -39.1613, 319.5818), task = 'gathering' },
            { coords = vector4(1053.4169, -3198.2385, -39.1273, 35.5979),  task = 'gathering' },
        },
        entities = {
            security = { 'weed_security_upgrade' },
            upgrades = {
                [1] = (function()
                    local level1Upgrades = { 'weed_standard_equip', 'weed_low_security' }
                    return level1Upgrades
                end)(),
                [2] = (function()
                    local level2Upgrades = {
                        'weed_low_security',
                        'weed_standard_equip',
                        'weed_set_up',
                        'weed_chairs',
                        'weed_production',
                    }

                    for _, stage in ipairs({ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i' }) do
                        table.insert(level2Upgrades, 'weed_hose' .. stage)
                        table.insert(level2Upgrades, 'weed_growth' .. stage .. '_stage3')
                        table.insert(level2Upgrades, 'light_growth' .. stage .. '_stage23_standard')
                    end
                    return level2Upgrades
                end)(),
                [3] = (function()
                    local level3Upgrades = {
                        'weed_low_security',
                        'weed_upgrade_equip',
                        'weed_set_up',
                        'weed_chairs',
                        'weed_production',
                    }

                    for _, stage in ipairs({ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i' }) do
                        table.insert(level3Upgrades, 'weed_hose' .. stage)
                        table.insert(level3Upgrades, 'weed_growth' .. stage .. '_stage3')
                        table.insert(level3Upgrades, 'light_growth' .. stage .. '_stage23_upgrade')
                    end
                    return level3Upgrades
                end)(),
            },
            hide = (function()
                local hiddenEntities = {
                    'weed_standard_equip',
                    'weed_upgrade_equip',
                    'weed_low_security',
                    'weed_security_upgrade',
                    'weed_set_up',
                    'weed_chairs',
                    'weed_production',
                    'weed_drying',
                }

                -- Weed growth & light stages
                for _, stage in ipairs({ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i' }) do
                    table.insert(hiddenEntities, 'weed_hose' .. stage)
                    table.insert(hiddenEntities, 'weed_growth' .. stage .. '_stage1')
                    table.insert(hiddenEntities, 'weed_growth' .. stage .. '_stage2')
                    table.insert(hiddenEntities, 'weed_growth' .. stage .. '_stage3')
                    table.insert(hiddenEntities, 'light_growth' .. stage .. '_stage23_standard')
                    table.insert(hiddenEntities, 'light_growth' .. stage .. '_stage23_upgrade')
                end

                return hiddenEntities
            end)(),
        },
    },
    ['cocaine'] = {
        coords = vector3(1093.6, -3196.6, -38.99841),
        employees = {
            { coords = vector4(1090.3922, -3194.9170, -38.9935, 180.0), task = 'unpack' },
            { coords = vector4(1093.1151, -3194.8386, -38.9935, 180.0), task = 'cutter' },
            { coords = vector4(1101.245, -3198.82, -38.99, 180.0),      task = 'packing' },
            { coords = vector4(1095.3453, -3194.8259, -38.9935, 180.0), task = 'unpack' },
            { coords = vector4(1095.2307, -3196.6558, -38.9935, 0.0),   task = 'cutter' },
            { coords = vector4(1092.9817, -3196.6887, -38.9935, 0.0),   task = 'unpack' },
            { coords = vector4(1090.4581, -3196.5686, -38.9935, 0.0),   task = 'cutter' },
            { coords = vector4(1100.0848, -3198.7798, -38.9935, 180.0), task = 'cutter' },
        },
        entities = {
            security = { 'security_high' },
            upgrades = {
                [1] = (function()
                    local level1Upgrades = { 'set_up', 'equipment_basic', 'security_low' }

                    return level1Upgrades
                end)(),
                [2] = (function()
                    local level2Upgrades = {
                        'set_up', 'equipment_basic', 'security_low',
                        'production_basic',
                        'coke_press_basic',
                        'table_equipment',
                    }

                    for _, stage in ipairs({ '1', '2', '3' }) do
                        table.insert(level2Upgrades, 'coke_cut_0' .. stage)
                    end

                    return level2Upgrades
                end)(),
                [3] = (function()
                    local level3Upgrades = {
                        'security_low',
                        'set_up',
                        'table_equipment',
                        'equipment_upgrade',
                        'production_upgrade',
                        'coke_press_upgrade',
                        'table_equipment_upgrade',
                    }

                    for _, stage in ipairs({ '1', '2', '3', '4', '5' }) do
                        table.insert(level3Upgrades, 'coke_cut_0' .. stage)
                    end

                    return level3Upgrades
                end)(),
            },
            hide = (function()
                local hiddenEntities = {
                    'set_up',
                    'security_low',
                    'equipment_basic',
                    'production_basic',
                    'coke_press_basic',
                    'table_equipment',
                    'security_high',
                    'equipment_upgrade',
                    'production_upgrade',
                    'coke_press_upgrade',
                    'table_equipment_upgrade',
                }

                for _, stage in ipairs({ '1', '2', '3', '4', '5' }) do
                    table.insert(hiddenEntities, 'coke_cut_0' .. stage)
                end

                return hiddenEntities
            end)(),
        },
    },
    ['meth'] = {
        coords = vector3(1009.5, -3196.6, -38.99682),
        employees = {
            { coords = vector4(1005.74, -3200.39, -38.52, 180.0),         task = 'cook' },
            { coords = vector4(1016.44, -3194.87, -38.99, 0.0),           task = 'hammer' },
            { coords = vector4(1012.07, -3194.95, -38.99, 0.0),           task = 'packing' },

            { coords = vector4(1014.2224, -3194.9583, -38.9932, 0.0),     task = 'packing' },
            { coords = vector4(1010.4529, -3200.2759, -38.9931, 0.0) },
            { coords = vector4(1003.1205, -3199.9402, -38.9931, 126.2496) },
            { coords = vector4(998.2529, -3199.9995, -38.9931, 93.8284) },
        },
        entities = {
            security = { 'meth_lab_security_high' },
            upgrades = {
                [1] = (function()
                    local level1Upgrades = { 'meth_lab_empty', 'weed_low_security' }
                    return level1Upgrades
                end)(),
                [2] = (function()
                    local level2Upgrades = {
                        'weed_low_security',
                        'meth_lab_basic',
                        'meth_lab_setup',
                        'meth_lab_production',
                    }
                    return level2Upgrades
                end)(),
                [3] = (function()
                    local level3Upgrades = {
                        'weed_low_security',
                        'meth_lab_setup',
                        'meth_lab_production',
                        'meth_lab_upgrade',
                    }
                    return level3Upgrades
                end)(),
            },
            hide = (function()
                local hiddenEntities = {
                    'meth_lab_basic',
                    'meth_lab_upgrade',
                    'meth_lab_production',
                    'meth_lab_security_high',
                    'meth_lab_setup',
                    'meth_lab_empty',
                }
                return hiddenEntities
            end)(),
        },
    },
}
