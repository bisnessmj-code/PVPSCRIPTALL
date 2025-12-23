--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                        CONFIGURATION DES MAPS                              ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

Config.Maps = {
    ["legion_square"] = {
        name = "Legion Square Arena",
        enabled = true,
        center = vec3(2350.443848, 2569.582520, 46.517212),
        radius = 80.0,
        respawnPoints = {
          vec4(2359.279052, 2592.553956, 46.651978, 119.055114),
          vec4(2367.837402, 2577.758300, 46.651978, 189.921264),
          vec4(2366.505372, 2561.512208, 46.651978, 138.897628),
          vec4(2361.534180, 2541.903320, 47.679810, 204.094482),
          vec4(2349.006592, 2526.843994, 46.651978, 348.661408),
          vec4(2357.116456, 2513.037354, 46.668824, 116.220474),
          vec4(2331.032958, 2515.978028, 46.803710, 104.881896),
          vec4(2325.534180, 2527.833008, 46.651978, 334.488190),
          vec4(2314.377930, 2524.602294, 46.651978, 68.031494),
          vec4(2307.454834, 2551.028564, 46.651978, 17.007874),
          vec4(2323.450440, 2592.210938, 46.601440, 331.653534),
          vec4(2330.782470, 2614.879150, 46.668824, 291.968506),
          vec4(2366.215332, 2612.861572, 46.651978, 147.401580),
          vec4(2349.402100, 2619.375732, 46.651978, 286.299194),
          vec4(2330.202148, 2572.694580, 46.668824, 147.401580)
        }
    }
}

Config.ActiveMap = "legion_square"

function Config.GetActiveMap()
    return Config.Maps[Config.ActiveMap]
end

function Config.GetRandomRespawn()
    local map = Config.GetActiveMap()
    if map and map.respawnPoints then
        local index = math.random(1, #map.respawnPoints)
        return map.respawnPoints[index]
    end
    local index = math.random(1, #Config.RespawnPoints)
    return Config.RespawnPoints[index]
end

function Config.IsInCombatZone(coords)
    local map = Config.GetActiveMap()
    if not map then return false end
    
    local dx = coords.x - map.center.x
    local dy = coords.y - map.center.y
    local distance2D = math.sqrt(dx * dx + dy * dy)
    
    return distance2D <= map.radius
end
