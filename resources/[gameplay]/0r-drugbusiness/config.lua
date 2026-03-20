--[[
    All script settings are found and edited in this file.
    Make sure to configure everything properly before running the script.
]]

Config = {}

---[[ Money Configuration ]]
Config.CleanMoney = {
    isItem = false,       -- If set to true, clean money will be treated as an item.
    itemName = 'money',   -- The name of the clean money item (if isItem is true).
    accountName = 'cash', -- The account name used for clean money transactions.
}

Config.DirtyMoney = {
    isItem = false,              -- If set to true, dirty money will be treated as an item.
    itemName = 'black_money',    -- The name of the dirty money item (if isItem is true).
    accountName = 'black_money', -- The account name used for dirty money transactions.
}

Config.PackagedProduct = {
    -- Max. number of packaged products that can be stocked in the warehouse. This is the default for everyone.
    maxStock = 200,
    ['weed'] = { itemName = 'packaged_weed' },
    ['cocaine'] = { itemName = 'packaged_cocaine' },
    ['meth'] = { itemName = 'packaged_meth' },
}

---[[ Police Jobs ]]
Config.PoliceJobName = {
    ['police'] = true,  -- Police job name.
    ['sheriff'] = true, -- Sheriff job name.
}

---[[ Business Types ]]
-- YOU CAN ONLY CHANGE PRICE, LABEL, AND LEVEL. DO NOT MODIFY OTHER FIELDS!
Config.BusinessTypes = {
    [1] = { key = 'weed', label = 'Weed', requiredLevel = 1, price = 50000 },
    [2] = { key = 'cocaine', label = 'Cocaine', requiredLevel = 10, price = 100000 },
    [3] = { key = 'meth', label = 'Meth', requiredLevel = 15, price = 200000 },
}

--[[ Warehoue Options ]]
Config.Warehouse = {
    salesBlip = { active = true, color = 1, scale = 0.7, sprite = 474 },
    ownedBlip = { active = true, color = 5, scale = 0.7, sprite = 473 },
}

--[[ Unauthorized Entry ]]
Config.UnauthorizedEntry = {
    requiredItemName = 'lockpick',
}

---[[ Security System ]]
Config.SecuritySystem = {
    price = 5000, -- Cost to install the security system.
}

---[[ Stock Prices ]]
Config.Stock = {
    ['water'] = { unit_price = 20.0 },       -- Unit price for water.
    ['gas'] = { unit_price = 15.0 },         -- Unit price for gas.
    ['electricity'] = { unit_price = 22.0 }, -- Unit price for electricity.
}

---[[ Employee Management ]]
Config.Employee = {
    recruitment_fee = 5000, -- Fee for hiring an employee.
    salary_fee = 1000,      -- Salary paid to employees every 24 hours.
}

---[[ Raw Materials & Vehicle Upgrades ]]
Config.RawMaterials = {
    -- Vehicle upgrade levels sorted by level.
    vehicleUpgrades = {
        [1] = { model = 'speedo', color = 14, maxPackageCount = 5 },
        [2] = { model = 'speedo', color = 88, maxPackageCount = 10, price = 50000 },
        [3] = { model = 'speedo', color = 27, maxPackageCount = 15, price = 50000 },
    },
    -- Quantity of raw materials per package multiplied by the total number of packages in the vehicle.
    quantityRawMaterialsInPackage = 10,
    -- Max raw material quantities that can be stocked in the warehouse
    stockUpgrades = {
        [1] = { price = 50000, maxStockCount = 200 },
        [2] = { price = 50000, maxStockCount = 300 },
        [3] = { price = 50000, maxStockCount = 400 },
        [4] = { price = 50000, maxStockCount = 500 },
    },
    -- Box placement offsets inside the vehicle. | No Need to Edit
    vehicleBoxesOffsets = {
        ['speedo'] = {
            vector3(-0.6, 0.0, 0.0),
            vector3(-0.2, 0.0, 0.0),
            vector3(0.2, 0.0, 0.0),
            vector3(0.6, 0.0, 0.0),
            vector3(-0.6, -0.45, 0.0),
            vector3(-0.2, -0.45, 0.0),
            vector3(0.2, -0.45, 0.0),
            vector3(0.6, -0.45, 0.0),
            vector3(-0.6, -0.90, 0.0),
            vector3(-0.2, -0.90, 0.0),
            vector3(0.2, -0.90, 0.0),
            vector3(0.6, -0.90, 0.0),
            vector3(-0.2, -1.35, 0.0),
            vector3(0.2, -1.35, 0.0),
            vector3(-0.2, -1.8, 0.0),
            vector3(0.2, -1.8, 0.0),
        },
        ['burrito3'] = {
            vector3(-0.6, 0.0, -0.20),
            vector3(-0.2, 0.0, -0.20),
            vector3(0.2, 0.0, -0.20),
            vector3(0.6, 0.0, -0.20),
            vector3(-0.6, -0.45, -0.20),
            vector3(-0.2, -0.45, -0.20),
            vector3(0.2, -0.45, -0.20),
            vector3(0.6, -0.45, -0.20),
            vector3(-0.6, -0.90, -0.20),
            vector3(-0.2, -0.90, -0.20),
            vector3(0.2, -0.90, -0.20),
            vector3(0.6, -0.90, -0.20),
            vector3(-0.2, -1.35, -0.20),
            vector3(0.2, -1.35, -0.20),
            vector3(-0.2, -1.8, -0.20),
            vector3(0.2, -1.8, -0.20),
            vector3(-0.6, 0.0, 0.15),
            vector3(-0.2, 0.0, 0.15),
            vector3(0.2, 0.0, 0.15),
            vector3(0.6, 0.0, 0.15),
        },
    },
}

--[[ Money Washing & Upgrades ]]
Config.MoneyWashing = {
    upgrades = {
        [1] = { price = 50000, productionPerMin = 1000 },
        [2] = { price = 60000, productionPerMin = 2000 },
        [3] = { price = 70000, productionPerMin = 3000 },
        [4] = { price = 80000, productionPerMin = 5000 },
    },
    interior = {
        coords = vector3(1121.897, -3195.338, -40.4025),
        entrance = vector4(1136.6128, -3197.2837, -39.6658, 72.8951),
        exitArea = vector3(1138.0, -3198.96, -39.68),
    },
}

--[[ Sale Mission ]]
Config.SaleMission = {
    ---The amount of black money you earn when you deliver a package
    feePerPackage = 5000,
}

---[[ Drug Labs Configuration ]]
Config.Labs = {
    ['weed'] = {
        coords = {
            entrance = vector4(1042.8270, -3194.8193, -39.25, 214.0925),
            exitArea = vector3(1039.4702, -3194.8481, -38.1693),
            panel = vector3(1045.25, -3194.85, -38.36),
        },
        upgrades = {
            [2] = { price = 10000 },
            [3] = { price = 50000 },
        },
    },
    ['cocaine'] = {
        coords = {
            entrance = vector4(1088.5780, -3190.3882, -39.5, 185.2210),
            exitArea = vector3(1088.6932, -3187.5713, -38.9935),
            panel = vector3(1086.52, -3194.28, -39.19),
        },
        upgrades = {
            [2] = { price = 10000 },
            [3] = { price = 50000 },
        },
    },
    ['meth'] = {
        coords = {
            entrance = vector4(997.7157, -3198.7317, -37.3937, 347.3677),
            exitArea = vector3(996.89, -3200.64, -36.39),
            panel = vector3(1001.95, -3194.20, -39.19),
        },
        upgrades = {
            [2] = { price = 10000 },
            [3] = { price = 50000 },
        },
    },
}

---[[ Default Fallback Exit Coordinate ]]
Config.FallbackExitCoord = vector4(-1019.7207, -1518.1963, 5.5910, 126.5541)

---[[ Debug Mode ]]
Config.debug = false     -- Enable or disable debug mode.
Config.debugZone = false -- Enable or disable debug zone mode.
