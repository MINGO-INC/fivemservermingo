--[[ Contains server-side helper functions. ]]

local Utils = {}

function Utils.getPoliceCount()
    local count = 0
    for _, playerId in ipairs(GetPlayers()) do
        local xPlayerJob = server.getPlayerJob(tonumber(playerId))
        if xPlayerJob and Config.PoliceJobName[string.lower(xPlayerJob.name)] then
            count = count + 1
        end
    end
    return count
end

return Utils
