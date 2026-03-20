local Weather = {}

function Weather.disableSync()
    if shared.framework == 'qbx' then
        TriggerEvent('qb-weathersync:client:DisableSync')
    elseif shared.framework == 'qb' then
        TriggerEvent('qb-weathersync:client:DisableSync')
    elseif shared.framework == 'esx' then
        TriggerEvent('vSync:toggle', false)
    end

    -- ? Use Your weather script export/event
end

function Weather.enableSync()
    if shared.framework == 'qbx' then
        TriggerEvent('qb-weathersync:client:EnableSync')
    elseif shared.framework == 'qb' then
        TriggerEvent('qb-weathersync:client:EnableSync')
    elseif shared.framework == 'esx' then
        TriggerEvent('vSync:toggle', true)
    end

    -- ? Use Your weather script export/event
end

return Weather
