---@class Blip
---@field active boolean -- Whether the blip is active on the map.
---@field scale number -- Scale of the blip.
---@field color number -- Color of the blip.
---@field sprite number -- Sprite ID of the blip.

---@class WarehouseData
---@field index number -- Unique - is set using the table index. No need to add.
---@field entranceCoords vector
---@field label string
---@field price number
---@field salesBlip Blip
---@field ownedBlip Blip
---@field outsideCamera {coords:vector3, rot:vector3}
---@field taskVehicleSpawnCoords vector

---Here you can organise all the warehouses you can buy and use.
---It is indexed by order.
---Do not add another warehouse before a previously purchased warehouse in the table.
---Add all new warehouses at the end!

---@type WarehouseData[]
return {
    {
        label = 'Warehouse',
        entranceCoords = vector3(1738.5105, 3029.1851, 63.1488),
        price = 50000,
        outsideCamera = {
            coords = vector3(1739.223, 3028.679, 64.758),
            rot = vector3(-31.5, 0.0, 51.0),
        },
        taskVehicleSpawnCoords = vector4(1740.3048, 3040.2085, 61.5328, 77.9931),
    },
    {
        label = 'Warehouse',
        entranceCoords = vector3(2393.1226, 3320.6599, 48.2382),
        price = 50000,
        outsideCamera = {
            coords = vector3(2398.887, 3313.656, 50.165),
            rot = vector3(-16.144, 0.0, 17.33),
        },
        taskVehicleSpawnCoords = vector4(2403.3857, 3312.9871, 47.6671, 317.1753),
    },
}
