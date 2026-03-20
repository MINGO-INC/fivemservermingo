local Target = {}

function Target.addBoxZone(key, parameters)
    if shared.isResourceStart('ox_target') then
        parameters.name = key
        parameters.drawSprite = false
        return exports.ox_target:addBoxZone(parameters)
    elseif shared.isResourceStart('qb-target') then
        for _, option in pairs(parameters.options) do
            option.action = option.onSelect
        end
        exports['qb-target']:AddBoxZone(key, parameters.coords, parameters.size.x, parameters.size.y,
            {
                name = key,
                heading = parameters.rotation,
                debugPoly = parameters.debug,
                minZ = parameters.coords - 1.0,
                maxZ = parameters.coords + 1.0,
            }, { options = parameters.options, distance = 2.5, })
        return key
    else
        -- ? Use your target script export
        return key
    end
end

function Target.removeZone(id)
    if shared.isResourceStart('ox_target') then
        exports.ox_target:removeZone(id)
    elseif shared.isResourceStart('qb-target') then
        exports['qb-target']:RemoveZone(id)
    else
        -- ? Use your target script export
    end
end

return Target
