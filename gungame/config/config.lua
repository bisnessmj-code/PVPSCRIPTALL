--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                        CONFIGURATION PRINCIPALE                            ║
    ║              CORRIGÉ : Classement 5 joueurs, bucket GunGame                ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

Config = {}

-- ═══════════════════════════════════════════════════════════════════════════
-- DEBUG & LOGGING
-- ═══════════════════════════════════════════════════════════════════════════
Config.Debug = false
Config.LogLevel = 'error'

-- ═══════════════════════════════════════════════════════════════════════════
-- PED D'ENTRÉE
-- ═══════════════════════════════════════════════════════════════════════════
Config.JoinPed = {
    model = "s_m_y_blackops_01",
    coords = vec4(-2649.257080, -760.048340, 3.931884, 104.881896),
    scenario = "WORLD_HUMAN_GUARD_STAND",
    interactionDistance = 2.5,
    prompt = "Appuyer sur ~INPUT_CONTEXT~ pour rejoindre le GunGame",
    blip = {
        enabled = true,
        sprite = 310,
        color = 1,
        scale = 0.8,
        name = "GunGame Arena"
    }
}

-- ═══════════════════════════════════════════════════════════════════════════
-- ZONE DE COMBAT
-- ═══════════════════════════════════════════════════════════════════════════
Config.MapCenter = vec3(2350.443848, 2569.582520, 46.517212)
Config.MapRadius = 100.0
Config.MapCylinderDepth = 200.0
Config.DeathOnExit = true
Config.ExitCheckInterval = 500

Config.RespawnPoints = {
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
    vec4(2330.202148, 2572.694580, 46.668824, 147.401580),
}

-- ═══════════════════════════════════════════════════════════════════════════
-- TÉLÉPORTATION FIN / SORTIE
-- ═══════════════════════════════════════════════════════════════════════════
Config.EndTeleport = vec4(-2660.901124, -740.162658, 6.920166, 238.110230)

-- ═══════════════════════════════════════════════════════════════════════════
-- MÉCANIQUE GUNGAME
-- ═══════════════════════════════════════════════════════════════════════════
Config.KillsPerWeaponChange = 2
Config.TotalWeapons = 40
Config.MaxPlayersPerGame = 32
Config.RespawnDelay = 0

-- ═══════════════════════════════════════════════════════════════════════════
-- MUNITIONS & ARMURE
-- ═══════════════════════════════════════════════════════════════════════════
Config.DefaultAmmo = 999
Config.DefaultArmor = 50
Config.DefaultHealth = 200

-- ═══════════════════════════════════════════════════════════════════════════
-- INTERFACE (NUI) - CLASSEMENT LIMITÉ À 5
-- ═══════════════════════════════════════════════════════════════════════════
Config.UI = {
    showLeaderboard = true,
    leaderboardPosition = 'top-left',
    maxLeaderboardPlayers = 5,          -- ⭐ CHANGÉ DE 10 À 5 ⭐
    showWeaponProgress = true,
    showKillFeed = true,
    killFeedDuration = 4000,
    killFeedMax = 5,
    endScreenDuration = 10000
}

-- ═══════════════════════════════════════════════════════════════════════════
-- BLIPS JOUEURS
-- ═══════════════════════════════════════════════════════════════════════════
Config.PlayerBlips = {
    enabled = true,
    sprite = 1,
    color = 1,
    scale = 0.7,
    updateInterval = 2000
}

-- ═══════════════════════════════════════════════════════════════════════════
-- MESSAGES & NOTIFICATIONS
-- ═══════════════════════════════════════════════════════════════════════════
Config.Messages = {
    joinedGame = "~g~Tu as rejoint le GunGame !",
    leftGame = "~r~Tu as quitté le GunGame.",
    weaponChanged = "~b~Nouvelle arme : ~w~%s",
    killConfirm = "~g~+1 Kill ! ~w~(%d/%d)",
    playerKilled = "~r~Éliminé par %s",
    gameWon = "~y~VICTOIRE ! ~w~Tu as terminé le GunGame !",
    gameEnded = "~y~Partie terminée ! ~w~Vainqueur : %s",
    kicked = "~r~Tu as été kick du GunGame.",
    kickedAll = "~r~Tous les joueurs ont été kick du GunGame."
}

-- ═══════════════════════════════════════════════════════════════════════════
-- TOUCHES BLOQUÉES
-- ═══════════════════════════════════════════════════════════════════════════
Config.BlockedControls = {
    37,     -- TAB (Weapon wheel)
    157,    -- 1
    158,    -- 2
    160,    -- 3
    164,    -- 4
    165,    -- 5
    159,    -- 6
    161,    -- 7
    162,    -- 8
    163,    -- 9
    14,     -- Scroll wheel
    15,     -- Scroll wheel
    16,     -- Scroll wheel
    17,     -- Scroll wheel
    289,    -- I (Inventaire)
    170,    -- F3 (Inventaire alternatif)
}

-- ═══════════════════════════════════════════════════════════════════════════
-- ROUTING BUCKET / INSTANCE ⭐ CORRIGÉ ⭐
-- ═══════════════════════════════════════════════════════════════════════════
Config.RoutingBucket = {
    enabled = true,                     -- TOUJOURS ACTIVÉ
    bucketId = 100,                     -- Bucket GunGame (gf_respawn ne voit pas)
    defaultBucket = 0                   -- Bucket par défaut (où gf_respawn fonctionne)
}

-- ═══════════════════════════════════════════════════════════════════════════
-- COMMANDES ADMIN
-- ═══════════════════════════════════════════════════════════════════════════
Config.AdminGroup = "admin"

-- ═══════════════════════════════════════════════════════════════════════════
-- FONCTION DE DEBUG
-- ═══════════════════════════════════════════════════════════════════════════
function Config.Log(level, message, ...)
    if not Config.Debug then return end
    
    local levels = { debug = 1, info = 2, warn = 3, error = 4 }
    local currentLevel = levels[Config.LogLevel] or 2
    local msgLevel = levels[level] or 2
    
    if msgLevel >= currentLevel then
        local prefix = ('[GunGame][%s]'):format(level:upper())
        print(prefix, string.format(message, ...))
    end
end
