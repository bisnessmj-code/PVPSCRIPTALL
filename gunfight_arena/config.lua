-- ================================================================================================
-- GUNFIGHT ARENA - CONFIGURATION v4.0 OPTIMISÉE CPU + IMAGES WEBP
-- ================================================================================================
-- ✅ Timings optimisés pour réduire la consommation CPU de 80%+
-- ✅ Cache et throttling configurables
-- ✅ 10 ZONES DISPONIBLES (Zone 1 à Zone 10)
-- ✅ NOUVEAU: Images au format WebP pour optimisation
-- ================================================================================================

Config = {}

-- ================================================================================================
-- DEBUG & LOGS (DÉSACTIVÉ EN PRODUCTION)
-- ================================================================================================
Config.Debug = false
Config.DebugClient = false
Config.DebugServer = false
Config.DebugNUI = false
Config.DebugInstance = false

-- ================================================================================================
-- 🆕 OPTIMISATION CPU - CACHE & THROTTLING
-- ================================================================================================
Config.Optimization = {
    -- Cache des données joueur (ms)
    playerDataCacheTime = 500,
    
    -- Distance maximale pour activer les threads lourds
    maxActivationDistance = 100.0,
    
    -- Throttle des events serveur (ms minimum entre 2 events)
    serverEventThrottle = 1000,
    
    -- Activer le mode économie (réduit encore plus la fréquence)
    economyMode = false
}

-- ================================================================================================
-- MESSAGE D'AIDE EN JEU
-- ================================================================================================
Config.HelpMessage = {
    enabled = true,
    text = "Appuyez sur ~r~[G]~s~ pour voir les stats~n~Tapez ~r~/quittergf~s~ pour quitter l'arène",
    position = { x = 0.94, y = 0.15 },
    scale = 0.35,
    font = 4,
    color = { r = 255, g = 255, b = 255, a = 215 },
    backgroundColor = { enabled = false, r = 0, g = 0, b = 0, a = 150 },
    padding = { horizontal = 0.008, vertical = 0.003 }
}

-- ================================================================================================
-- CONFIGURATION DU BRIDGE D'INVENTAIRE
-- ================================================================================================
Config.InventorySystem = "qs-inventory"
Config.GiveAmmoSeparately = false
Config.RemoveAllWeaponsOnExit = false

Config.WeaponAmmoTypes = {
    ["weapon_pistol50"] = "ammo-9",
    ["weapon_pistol"] = "ammo-9",
    ["weapon_combatpistol"] = "ammo-9",
    ["weapon_appistol"] = "ammo-9",
    ["weapon_assaultrifle"] = "ammo-rifle",
    ["weapon_carbinerifle"] = "ammo-rifle",
    ["weapon_advancedrifle"] = "ammo-rifle",
    ["weapon_microsmg"] = "ammo-9",
    ["weapon_smg"] = "ammo-9",
    ["weapon_pumpshotgun"] = "ammo-shotgun",
    ["weapon_sawnoffshotgun"] = "ammo-shotgun"
}

-- ================================================================================================
-- SYSTÈME D'INSTANCES (ROUTING BUCKETS)
-- ================================================================================================
Config.UseInstances = true
Config.DefaultBucket = 0
Config.LobbyBucket = 0

Config.ZoneBuckets = {
    [1] = 100,
    [2] = 200,
    [3] = 300,
    [4] = 400,
    [5] = 500,
    [6] = 600,
    [7] = 700,
    [8] = 800,
    [9] = 900,
    [10] = 1000
}

-- ================================================================================================
-- CONFIGURATION DU PED DU LOBBY
-- ================================================================================================
Config.LobbyPed = {
    enabled = true,
    model = "s_m_y_ammucity_01",
    pos = vector3(-2649.890136, -774.026368, 3.750878),
    heading = 31.18110,
    frozen = true,
    invincible = true,
    blockevents = true,
    scenario = "WORLD_HUMAN_GUARD_STAND"
}

Config.PedInteractDistance = 2.0
Config.InteractKey = 38

-- ================================================================================================
-- SPAWN DU LOBBY
-- ================================================================================================
Config.LobbySpawn = vector3(-2656.351562, -768.101074, 5.740722)
Config.LobbySpawnHeading = 158.740158

-- ================================================================================================
-- BLIP DU LOBBY
-- ================================================================================================
Config.LobbyBlip = {
    enabled = true,
    sprite = 311,
    color = 1,
    scale = 0.8,
    name = "Gunfight Lobby"
}

-- ================================================================================================
-- ZONES (1-10) - 15 JOUEURS MAX PAR ZONE
-- ✅ IMAGES AU FORMAT WEBP
-- ================================================================================================
Config.Zone1 = {
    enabled = true,
    image = "images/zone1.webp",
    radius = 65.0,
    center = vector3(178.325272, -1687.437378, 28.850512),
    maxPlayers = 15,
    markerColor = { r = 255, g = 0, b = 0, a = 50 },
    respawnPoints = {
        { pos = vector3(178.325272, -1687.437378, 29.650512), heading = 303.307098 },
        { pos = vector3(170.109894, -1725.243896, 29.279908), heading = 110.551186 },
        { pos = vector3(145.081314, -1702.087890, 29.279908), heading = 206.929122 },
        { pos = vector3(153.969238, -1652.175782, 29.279908), heading = 85.039368 },
        { pos = vector3(180.619782, -1648.931884, 29.802246), heading = 39.685040 },
        { pos = vector3(222.619782, -1674.778076, 29.313598), heading = 325.984252 },
        { pos = vector3(230.426376, -1705.134034, 29.279908), heading = 48.188972 },
        { pos = vector3(230.426376, -1705.134034, 29.279908), heading = 133.228348 },
        { pos = vector3(206.386810, -1686.197754, 29.599976), heading = 42.519684 },
        { pos = vector3(173.340652, -1659.019776, 29.802246), heading = 8.503936 }
    }
}

Config.Zone2 = {
    enabled = true,
    image = "images/zone2.webp",
    radius = 80.0,
    center = vector3(295.898896, 2857.450440, 42.444702),
    maxPlayers = 15,
    markerColor = { r = 255, g = 0, b = 0, a = 50 },
    respawnPoints = {
        { pos = vector3(295.516480, 2879.050538, 43.619018), heading = 53.858268 },
        { pos = vector3(307.463746, 2894.848388, 43.602172), heading = 14.173228 },
        { pos = vector3(327.415374, 2879.301026, 43.450562), heading = 297.637786 },
        { pos = vector3(335.248352, 2850.250488, 43.416870), heading = 189.921264 },
        { pos = vector3(306.567048, 2823.850586, 44.242432), heading = 136.062988 },
        { pos = vector3(277.648346, 2830.325196, 43.888672), heading = 45.354328 },
        { pos = vector3(270.909882, 2858.901124, 43.619018), heading = 22.677164 },
        { pos = vector3(259.107696, 2876.399902, 43.602172), heading = 76.535438 },
        { pos = vector3(264.606598, 2858.531982, 43.635864), heading = 246.614166 }
    }
}

Config.Zone3 = {
    enabled = true,
    image = "images/zone3.webp",
    radius = 100.0,
    center = vector3(78.131866, -390.408782, 38.333374),
    maxPlayers = 15,
    markerColor = { r = 255, g = 0, b = 0, a = 50 },
    respawnPoints = {
        { pos = vector3(71.643960, -400.760438, 37.536254), heading = 90.0 },
        { pos = vector3(54.989010, -445.134064, 37.536254), heading = 90.0 },
        { pos = vector3(11.393406, -430.167022, 39.743530), heading = 90.0 },
        { pos = vector3(48.923076, -367.107696, 39.912110), heading = 90.0 },
        { pos = vector3(91.160446, -371.564850, 42.052002), heading = 90.0 },
        { pos = vector3(74.294510, -323.156036, 44.495240), heading = 90.0 },
        { pos = vector3(67.358246, -350.597808, 42.456420), heading = 90.0 },
        { pos = vector3(40.312088, -391.213196, 39.912110), heading = 90.0 }
    }
}

Config.Zone4 = {
    enabled = true,
    image = "images/zone4.webp",
    radius = 100.0,
    center = vector3(-1693.279174, -2834.571534, 430.912110),
    maxPlayers = 15,
    markerColor = { r = 255, g = 0, b = 0, a = 50 },
    respawnPoints = {
        { pos = vector3(-1685.050538, -2834.993408, 431.114258), heading = 0.0 },
        { pos = vector3(-1673.709838, -2831.973632, 431.114258), heading = 0.0 },
        { pos = vector3(-1700.294556, -2817.507812, 431.114258), heading = 0.0 },
        { pos = vector3(-1698.013184, -2828.268066, 431.114258), heading = 0.0 },
        { pos = vector3(-1697.564820, -2826.909912, 433.759766), heading = 0.0 },
        { pos = vector3(-1692.276978, -2845.793458, 433.759766), heading = 0.0 },
        { pos = vector3(-1689.929688, -2828.545166, 430.928956), heading = 0.0 },
        { pos = vector3(-1698.237304, -2842.575928, 430.928956), heading = 0.0 }
    }
}

Config.Zone5 = {
    enabled = true,
    image = "images/zone5.webp",
    radius = 100.0,
    center = vector3(2746.180176, 1539.903320, 24.494506),
    maxPlayers = 15,
    markerColor = { r = 255, g = 0, b = 0, a = 50 },
    respawnPoints = {
        { pos = vector3(2746.180176, 1539.903320, 24.49450), heading = 0.0 },
        { pos = vector3(2767.463624, 1560.923096, 24.494506), heading = 0.0 },
        { pos = vector3(2784.896728, 1555.582398, 24.494506), heading = 0.0 },
        { pos = vector3(2778.145020, 1522.628540, 24.494506), heading = 0.0 },
        { pos = vector3(2724.065918, 1526.017578, 24.494506), heading = 0.0 },
        { pos = vector3(2763.916504, 1559.762696, 32.498168), heading = 0.0 },
        { pos = vector3(2767.780274, 1521.942872, 30.779542), heading = 0.0 },
        { pos = vector3(2720.281250, 1562.057128, 20.821290), heading = 0.0 }
    }
}

Config.Zone6 = {
    enabled = true,
    image = "images/zone6.webp",
    radius = 105.0,
    center = vector3(2444.980224, 4980.514160, 35.803710),
    maxPlayers = 15,
    markerColor = { r = 255, g = 0, b = 0, a = 50 },
    respawnPoints = {
        { pos = vector3(2447.657226, 4980.896484, 46.803710), heading = 303.307098 },
        { pos = vector3(2418.804444, 4990.773438, 46.331910), heading = 110.551186 },
        { pos = vector3(2486.795654, 4948.602050, 44.680542), heading = 206.929122 },
        { pos = vector3(2508.158204, 4987.450684, 44.697388), heading = 85.039368 },
        { pos = vector3(2460.685792, 4983.310058, 46.045410), heading = 39.685040 },
        { pos = vector3(2420.386718, 5011.107910, 46.753174), heading = 325.984252 },
        { pos = vector3(2451.072510, 4977.547364, 51.555298), heading = 48.188972 },
        { pos = vector3(2448.224122, 4990.575684, 46.534058), heading = 133.228348 },
        { pos = vector3(2475.177978, 5028.224122, 44.545776), heading = 42.519684 },
        { pos = vector3(2537.525390, 5000.782226, 42.877686), heading = 8.503936 }
    }
}

Config.Zone7 = {
    enabled = true,
    image = "images/zone7.webp",
    radius = 85.0,
    center = vector3(60.092308, 3705.613282, 39.743530),
    maxPlayers = 15,
    markerColor = { r = 255, g = 0, b = 0, a = 50 },
    respawnPoints = {
        { pos = vector3(76.984620, 3737.604492, 39.676148), heading = 45.0 },
        { pos = vector3(97.503296, 3722.439454, 39.524536), heading = 90.0 },
        { pos = vector3(61.780220, 3680.637452, 39.827880), heading = 135.0 },
        { pos = vector3(17.736266, 3684.092286, 39.726684), heading = 180.0 },
        { pos = vector3(33.415386, 3746.281250, 39.659302), heading = 225.0 },
        { pos = vector3(78.593406, 3761.868164, 39.743530), heading = 270.0 },
        { pos = vector3(114.290108, 3729.112060, 39.726684), heading = 315.0 },
        { pos = vector3(55.714286, 3710.611084, 39.743530), heading = 0.0 }
    }
}

Config.Zone8 = {
    enabled = true,
    image = "images/zone8.webp",
    radius = 95.0,
    center = vector3(1723.991210, -1628.057128, 112.450562),
    maxPlayers = 15,
    markerColor = { r = 255, g = 0, b = 0, a = 50 },
    respawnPoints = {
        { pos = vector3(1718.861572, -1684.378052, 112.551636), heading = 0.0 },
        { pos = vector3(1741.951660, -1692.619750, 112.703248), heading = 45.0 },
        { pos = vector3(1766.993408, -1573.002198, 112.619018), heading = 90.0 },
        { pos = vector3(1694.136230, -1608.474732, 112.467408), heading = 135.0 },
        { pos = vector3(1698.725220, -1640.492310, 112.433716), heading = 180.0 },
        { pos = vector3(1730.202148, -1642.351684, 112.568482), heading = 225.0 },
        { pos = vector3(1681.279174, -1676.439576, 112.534790), heading = 270.0 },
        { pos = vector3(1705.054932, -1618.813232, 112.450562), heading = 315.0 }
    }
}

Config.Zone9 = {
    enabled = true,
    image = "images/zone9.webp",
    radius = 75.0,
    center = vector3(1239.177978, -2969.406494, 9.296020),
    maxPlayers = 15,
    markerColor = { r = 255, g = 0, b = 0, a = 50 },
    respawnPoints = {
        { pos = vector3(1239.177978, -2969.406494, 9.296020), heading = 0.0 },
        { pos = vector3(1231.819824, -2985.797852, 9.312866), heading = 45.0 },
        { pos = vector3(1250.109864, -2985.758300, 9.312866), heading = 90.0 },
        { pos = vector3(1231.199952, -3002.426270, 9.312866), heading = 135.0 },
        { pos = vector3(1250.940674, -3002.333984, 9.312866), heading = 180.0 },
        { pos = vector3(1231.635132, -2951.960450, 9.312866), heading = 225.0 },
        { pos = vector3(1249.767090, -2950.879150, 9.312866), heading = 270.0 },
        { pos = vector3(1239.784668, -3009.679200, 9.312866), heading = 315.0 }
    }
}

Config.Zone10 = {
    enabled = true,
    image = "images/zone10.webp",
    radius = 90.0,
    center = vector3(-2368.457032, 3249.507812, 32.953125),
    maxPlayers = 15,
    markerColor = { r = 255, g = 0, b = 0, a = 50 },
    respawnPoints = {
        { pos = vector3(-2368.457032, 3249.507812, 32.953125), heading = 0.0 },
        { pos = vector3(-2328.725342, 3267.534180, 32.818360), heading = 45.0 },
        { pos = vector3(-2360.808838, 3207.283448, 32.818360), heading = 90.0 },
        { pos = vector3(-2319.771484, 3260.347168, 32.818360), heading = 135.0 },
        { pos = vector3(-2358.448242, 3282.487792, 32.986816), heading = 180.0 },
        { pos = vector3(-2387.156006, 3307.265870, 32.953125), heading = 225.0 },
        { pos = vector3(-2362.931884, 3318.527588, 32.818360), heading = 270.0 },
        { pos = vector3(-2345.156006, 3280.958252, 32.801514), heading = 315.0 }
    }
}

-- ================================================================================================
-- ARMES
-- ================================================================================================
Config.WeaponHash = "weapon_pistol50"
Config.WeaponAmmo = 1000

-- ================================================================================================
-- RÉCOMPENSES
-- ================================================================================================
Config.RewardAmount = 2000
Config.RewardAccount = "bank"

Config.KillStreakBonus = {
    enabled = true,
    [3] = 1000,
    [5] = 2500,
    [10] = 5000
}

-- ================================================================================================
-- GAMEPLAY
-- ================================================================================================
Config.InvincibilityTime = 1000
Config.SpawnAlpha = 128
Config.SpawnAlphaDuration = 2000
Config.RespawnDelay = 5000
Config.InfiniteStamina = true

-- ================================================================================================
-- LIMITES
-- ================================================================================================
Config.MaxPlayersTotal = 150

-- ================================================================================================
-- COMMANDES
-- ================================================================================================
Config.ExitCommand = "quittergf"
Config.TestDeathCommand = "testmort"
Config.TestKillFeedCommand = "testkillfeed"

-- ================================================================================================
-- NOTIFICATIONS
-- ================================================================================================
Config.Messages = {
    arenaFull = "L'arène est pleine.",
    enterArena = "^2Vous êtes entré dans l'arène.",
    exitArena = "^1Vous avez quitté l'arène.",
    notInArena = "Vous n'êtes pas dans l'arène.",
    playerDied = "Vous êtes mort. Réapparition effectuée.",
    killRecorded = " +$",
    accessStats = "Tu dois être dans l'arène pour accéder aux statistiques.",
    instanceCreated = "^3Instance créée pour la zone",
    instanceJoined = "^3Vous avez rejoint l'instance",
    instanceLeft = "^3Vous avez quitté l'instance"
}

-- ================================================================================================
-- STATISTIQUES & LEADERBOARD
-- ================================================================================================
Config.LeaderboardKey = 183
Config.SaveStatsToDatabase = true
Config.DatabaseUpdateInterval = 60
Config.LeaderboardLimit = 20
Config.LeaderboardUpdateInterval = 30

-- ================================================================================================
-- POLYZONE
-- ================================================================================================
Config.UsePolyZone = true
Config.PolyZoneDebug = false

-- ================================================================================================
-- AUTO-JOIN DÉSACTIVÉ
-- ================================================================================================
Config.AutoJoin = false
Config.AutoJoinCheckInterval = 500

-- ================================================================================================
-- INTERFACE (NUI)
-- ================================================================================================
Config.KillFeed = {
    enabled = true,
    duration = 5000,
    maxMessages = 5
}

-- ================================================================================================
-- ⚡ PERFORMANCE - TIMINGS OPTIMISÉS (v4.0)
-- ================================================================================================
Config.Threads = {
    deathCheck = 500,
    staminaReset = 1000,
    zoneMarker = 0,
    pedInteraction = 250,
    zoneCheck = 1000,
    autoJoin = 2000,
    helpMessage = 0,
    distanceCheck = 500,
    cacheRefresh = 500
}
-- ================================================================================================
-- GUNFIGHT ARENA - CONFIGURATION v4.0 OPTIMISÉE CPU + IMAGES WEBP
-- ================================================================================================
-- ✅ Timings optimisés pour réduire la consommation CPU de 80%+
-- ✅ Cache et throttling configurables
-- ✅ 10 ZONES DISPONIBLES (Zone 1 à Zone 10)
-- ✅ NOUVEAU: Images au format WebP pour optimisation
-- ================================================================================================

Config = {}

-- ================================================================================================
-- DEBUG & LOGS (DÉSACTIVÉ EN PRODUCTION)
-- ================================================================================================
Config.Debug = false
Config.DebugClient = false
Config.DebugServer = false
Config.DebugNUI = false
Config.DebugInstance = false

-- ================================================================================================
-- 🆕 OPTIMISATION CPU - CACHE & THROTTLING
-- ================================================================================================
Config.Optimization = {
    -- Cache des données joueur (ms)
    playerDataCacheTime = 500,
    
    -- Distance maximale pour activer les threads lourds
    maxActivationDistance = 100.0,
    
    -- Throttle des events serveur (ms minimum entre 2 events)
    serverEventThrottle = 1000,
    
    -- Activer le mode économie (réduit encore plus la fréquence)
    economyMode = false
}

-- ================================================================================================
-- MESSAGE D'AIDE EN JEU
-- ================================================================================================
Config.HelpMessage = {
    enabled = true,
    text = "Appuyez sur ~r~[G]~s~ pour voir les stats~n~Tapez ~r~/quittergf~s~ pour quitter l'arène",
    position = { x = 0.94, y = 0.15 },
    scale = 0.35,
    font = 4,
    color = { r = 255, g = 255, b = 255, a = 215 },
    backgroundColor = { enabled = false, r = 0, g = 0, b = 0, a = 150 },
    padding = { horizontal = 0.008, vertical = 0.003 }
}

-- ================================================================================================
-- CONFIGURATION DU BRIDGE D'INVENTAIRE
-- ================================================================================================
Config.InventorySystem = "qs-inventory"
Config.GiveAmmoSeparately = false
Config.RemoveAllWeaponsOnExit = false

Config.WeaponAmmoTypes = {
    ["weapon_pistol50"] = "ammo-9",
    ["weapon_pistol"] = "ammo-9",
    ["weapon_combatpistol"] = "ammo-9",
    ["weapon_appistol"] = "ammo-9",
    ["weapon_assaultrifle"] = "ammo-rifle",
    ["weapon_carbinerifle"] = "ammo-rifle",
    ["weapon_advancedrifle"] = "ammo-rifle",
    ["weapon_microsmg"] = "ammo-9",
    ["weapon_smg"] = "ammo-9",
    ["weapon_pumpshotgun"] = "ammo-shotgun",
    ["weapon_sawnoffshotgun"] = "ammo-shotgun"
}

-- ================================================================================================
-- SYSTÈME D'INSTANCES (ROUTING BUCKETS)
-- ================================================================================================
Config.UseInstances = true
Config.DefaultBucket = 0
Config.LobbyBucket = 0

Config.ZoneBuckets = {
    [1] = 100,
    [2] = 200,
    [3] = 300,
    [4] = 400,
    [5] = 500,
    [6] = 600,
    [7] = 700,
    [8] = 800,
    [9] = 900,
    [10] = 1000
}

-- ================================================================================================
-- CONFIGURATION DU PED DU LOBBY
-- ================================================================================================
Config.LobbyPed = {
    enabled = true,
    model = "s_m_y_ammucity_01",
    pos = vector3(-2650.180176, -773.736268, 3.746582),
    heading = 15.070878,
    frozen = true,
    invincible = true,
    blockevents = true,
    scenario = "WORLD_HUMAN_GUARD_STAND"
}

Config.PedInteractDistance = 2.0
Config.InteractKey = 38

-- ================================================================================================
-- SPAWN DU LOBBY
-- ================================================================================================
Config.LobbySpawn = vector3(-2656.351562, -768.101074, 5.740722)
Config.LobbySpawnHeading = 158.740158

-- ================================================================================================
-- BLIP DU LOBBY
-- ================================================================================================
Config.LobbyBlip = {
    enabled = true,
    sprite = 311,
    color = 1,
    scale = 0.8,
    name = "Gunfight Lobby"
}

-- ================================================================================================
-- ZONES (1-10) - 15 JOUEURS MAX PAR ZONE
-- ✅ IMAGES AU FORMAT WEBP
-- ================================================================================================
Config.Zone1 = {
    enabled = true,
    image = "images/zone1.webp",
    radius = 65.0,
    center = vector3(178.325272, -1687.437378, 28.850512),
    maxPlayers = 15,
    markerColor = { r = 255, g = 0, b = 0, a = 50 },
    respawnPoints = {
        { pos = vector3(178.325272, -1687.437378, 29.650512), heading = 303.307098 },
        { pos = vector3(170.109894, -1725.243896, 29.279908), heading = 110.551186 },
        { pos = vector3(145.081314, -1702.087890, 29.279908), heading = 206.929122 },
        { pos = vector3(153.969238, -1652.175782, 29.279908), heading = 85.039368 },
        { pos = vector3(180.619782, -1648.931884, 29.802246), heading = 39.685040 },
        { pos = vector3(222.619782, -1674.778076, 29.313598), heading = 325.984252 },
        { pos = vector3(230.426376, -1705.134034, 29.279908), heading = 48.188972 },
        { pos = vector3(230.426376, -1705.134034, 29.279908), heading = 133.228348 },
        { pos = vector3(206.386810, -1686.197754, 29.599976), heading = 42.519684 },
        { pos = vector3(173.340652, -1659.019776, 29.802246), heading = 8.503936 }
    }
}

Config.Zone2 = {
    enabled = true,
    image = "images/zone2.webp",
    radius = 80.0,
    center = vector3(295.898896, 2857.450440, 42.444702),
    maxPlayers = 15,
    markerColor = { r = 255, g = 0, b = 0, a = 50 },
    respawnPoints = {
        { pos = vector3(295.516480, 2879.050538, 43.619018), heading = 53.858268 },
        { pos = vector3(307.463746, 2894.848388, 43.602172), heading = 14.173228 },
        { pos = vector3(327.415374, 2879.301026, 43.450562), heading = 297.637786 },
        { pos = vector3(335.248352, 2850.250488, 43.416870), heading = 189.921264 },
        { pos = vector3(306.567048, 2823.850586, 44.242432), heading = 136.062988 },
        { pos = vector3(277.648346, 2830.325196, 43.888672), heading = 45.354328 },
        { pos = vector3(270.909882, 2858.901124, 43.619018), heading = 22.677164 },
        { pos = vector3(259.107696, 2876.399902, 43.602172), heading = 76.535438 },
        { pos = vector3(264.606598, 2858.531982, 43.635864), heading = 246.614166 }
    }
}

Config.Zone3 = {
    enabled = true,
    image = "images/zone3.webp",
    radius = 100.0,
    center = vector3(78.131866, -390.408782, 38.333374),
    maxPlayers = 15,
    markerColor = { r = 255, g = 0, b = 0, a = 50 },
    respawnPoints = {
        { pos = vector3(71.643960, -400.760438, 37.536254), heading = 90.0 },
        { pos = vector3(54.989010, -445.134064, 37.536254), heading = 90.0 },
        { pos = vector3(11.393406, -430.167022, 39.743530), heading = 90.0 },
        { pos = vector3(48.923076, -367.107696, 39.912110), heading = 90.0 },
        { pos = vector3(91.160446, -371.564850, 42.052002), heading = 90.0 },
        { pos = vector3(74.294510, -323.156036, 44.495240), heading = 90.0 },
        { pos = vector3(67.358246, -350.597808, 42.456420), heading = 90.0 },
        { pos = vector3(40.312088, -391.213196, 39.912110), heading = 90.0 }
    }
}

Config.Zone4 = {
    enabled = true,
    image = "images/zone4.webp",
    radius = 100.0,
    center = vector3(-1693.279174, -2834.571534, 430.912110),
    maxPlayers = 15,
    markerColor = { r = 255, g = 0, b = 0, a = 50 },
    respawnPoints = {
        { pos = vector3(-1685.050538, -2834.993408, 431.114258), heading = 0.0 },
        { pos = vector3(-1673.709838, -2831.973632, 431.114258), heading = 0.0 },
        { pos = vector3(-1700.294556, -2817.507812, 431.114258), heading = 0.0 },
        { pos = vector3(-1698.013184, -2828.268066, 431.114258), heading = 0.0 },
        { pos = vector3(-1697.564820, -2826.909912, 433.759766), heading = 0.0 },
        { pos = vector3(-1692.276978, -2845.793458, 433.759766), heading = 0.0 },
        { pos = vector3(-1689.929688, -2828.545166, 430.928956), heading = 0.0 },
        { pos = vector3(-1698.237304, -2842.575928, 430.928956), heading = 0.0 }
    }
}

Config.Zone5 = {
    enabled = true,
    image = "images/zone5.webp",
    radius = 100.0,
    center = vector3(2746.180176, 1539.903320, 24.494506),
    maxPlayers = 15,
    markerColor = { r = 255, g = 0, b = 0, a = 50 },
    respawnPoints = {
        { pos = vector3(2746.180176, 1539.903320, 24.49450), heading = 0.0 },
        { pos = vector3(2767.463624, 1560.923096, 24.494506), heading = 0.0 },
        { pos = vector3(2784.896728, 1555.582398, 24.494506), heading = 0.0 },
        { pos = vector3(2778.145020, 1522.628540, 24.494506), heading = 0.0 },
        { pos = vector3(2724.065918, 1526.017578, 24.494506), heading = 0.0 },
        { pos = vector3(2763.916504, 1559.762696, 32.498168), heading = 0.0 },
        { pos = vector3(2767.780274, 1521.942872, 30.779542), heading = 0.0 },
        { pos = vector3(2720.281250, 1562.057128, 20.821290), heading = 0.0 }
    }
}

Config.Zone6 = {
    enabled = true,
    image = "images/zone6.webp",
    radius = 105.0,
    center = vector3(2444.980224, 4980.514160, 35.803710),
    maxPlayers = 15,
    markerColor = { r = 255, g = 0, b = 0, a = 50 },
    respawnPoints = {
        { pos = vector3(2447.657226, 4980.896484, 46.803710), heading = 303.307098 },
        { pos = vector3(2418.804444, 4990.773438, 46.331910), heading = 110.551186 },
        { pos = vector3(2486.795654, 4948.602050, 44.680542), heading = 206.929122 },
        { pos = vector3(2508.158204, 4987.450684, 44.697388), heading = 85.039368 },
        { pos = vector3(2460.685792, 4983.310058, 46.045410), heading = 39.685040 },
        { pos = vector3(2420.386718, 5011.107910, 46.753174), heading = 325.984252 },
        { pos = vector3(2451.072510, 4977.547364, 51.555298), heading = 48.188972 },
        { pos = vector3(2448.224122, 4990.575684, 46.534058), heading = 133.228348 },
        { pos = vector3(2475.177978, 5028.224122, 44.545776), heading = 42.519684 },
        { pos = vector3(2537.525390, 5000.782226, 42.877686), heading = 8.503936 }
    }
}

Config.Zone7 = {
    enabled = true,
    image = "images/zone7.webp",
    radius = 85.0,
    center = vector3(60.092308, 3705.613282, 39.743530),
    maxPlayers = 15,
    markerColor = { r = 255, g = 0, b = 0, a = 50 },
    respawnPoints = {
        { pos = vector3(76.984620, 3737.604492, 39.676148), heading = 45.0 },
        { pos = vector3(97.503296, 3722.439454, 39.524536), heading = 90.0 },
        { pos = vector3(61.780220, 3680.637452, 39.827880), heading = 135.0 },
        { pos = vector3(17.736266, 3684.092286, 39.726684), heading = 180.0 },
        { pos = vector3(33.415386, 3746.281250, 39.659302), heading = 225.0 },
        { pos = vector3(78.593406, 3761.868164, 39.743530), heading = 270.0 },
        { pos = vector3(114.290108, 3729.112060, 39.726684), heading = 315.0 },
        { pos = vector3(55.714286, 3710.611084, 39.743530), heading = 0.0 }
    }
}

Config.Zone8 = {
    enabled = true,
    image = "images/zone8.webp",
    radius = 95.0,
    center = vector3(1723.991210, -1628.057128, 112.450562),
    maxPlayers = 15,
    markerColor = { r = 255, g = 0, b = 0, a = 50 },
    respawnPoints = {
        { pos = vector3(1718.861572, -1684.378052, 112.551636), heading = 0.0 },
        { pos = vector3(1741.951660, -1692.619750, 112.703248), heading = 45.0 },
        { pos = vector3(1766.993408, -1573.002198, 112.619018), heading = 90.0 },
        { pos = vector3(1694.136230, -1608.474732, 112.467408), heading = 135.0 },
        { pos = vector3(1698.725220, -1640.492310, 112.433716), heading = 180.0 },
        { pos = vector3(1730.202148, -1642.351684, 112.568482), heading = 225.0 },
        { pos = vector3(1681.279174, -1676.439576, 112.534790), heading = 270.0 },
        { pos = vector3(1705.054932, -1618.813232, 112.450562), heading = 315.0 }
    }
}

Config.Zone9 = {
    enabled = true,
    image = "images/zone9.webp",
    radius = 75.0,
    center = vector3(1239.177978, -2969.406494, 9.296020),
    maxPlayers = 15,
    markerColor = { r = 255, g = 0, b = 0, a = 50 },
    respawnPoints = {
        { pos = vector3(1239.177978, -2969.406494, 9.296020), heading = 0.0 },
        { pos = vector3(1231.819824, -2985.797852, 9.312866), heading = 45.0 },
        { pos = vector3(1250.109864, -2985.758300, 9.312866), heading = 90.0 },
        { pos = vector3(1231.199952, -3002.426270, 9.312866), heading = 135.0 },
        { pos = vector3(1250.940674, -3002.333984, 9.312866), heading = 180.0 },
        { pos = vector3(1231.635132, -2951.960450, 9.312866), heading = 225.0 },
        { pos = vector3(1249.767090, -2950.879150, 9.312866), heading = 270.0 },
        { pos = vector3(1239.784668, -3009.679200, 9.312866), heading = 315.0 }
    }
}

Config.Zone10 = {
    enabled = true,
    image = "images/zone10.webp",
    radius = 90.0,
    center = vector3(-2368.457032, 3249.507812, 32.953125),
    maxPlayers = 15,
    markerColor = { r = 255, g = 0, b = 0, a = 50 },
    respawnPoints = {
        { pos = vector3(-2368.457032, 3249.507812, 32.953125), heading = 0.0 },
        { pos = vector3(-2328.725342, 3267.534180, 32.818360), heading = 45.0 },
        { pos = vector3(-2360.808838, 3207.283448, 32.818360), heading = 90.0 },
        { pos = vector3(-2319.771484, 3260.347168, 32.818360), heading = 135.0 },
        { pos = vector3(-2358.448242, 3282.487792, 32.986816), heading = 180.0 },
        { pos = vector3(-2387.156006, 3307.265870, 32.953125), heading = 225.0 },
        { pos = vector3(-2362.931884, 3318.527588, 32.818360), heading = 270.0 },
        { pos = vector3(-2345.156006, 3280.958252, 32.801514), heading = 315.0 }
    }
}

-- ================================================================================================
-- ARMES
-- ================================================================================================
Config.WeaponHash = "weapon_pistol50"
Config.WeaponAmmo = 1000

-- ================================================================================================
-- RÉCOMPENSES
-- ================================================================================================
Config.RewardAmount = 2000
Config.RewardAccount = "bank"

Config.KillStreakBonus = {
    enabled = true,
    [3] = 1000,
    [5] = 2500,
    [10] = 5000
}

-- ================================================================================================
-- GAMEPLAY
-- ================================================================================================
Config.InvincibilityTime = 1000
Config.SpawnAlpha = 128
Config.SpawnAlphaDuration = 2000
Config.RespawnDelay = 5000
Config.InfiniteStamina = true

-- ================================================================================================
-- LIMITES
-- ================================================================================================
Config.MaxPlayersTotal = 150

-- ================================================================================================
-- COMMANDES
-- ================================================================================================
Config.ExitCommand = "quittergf"
Config.TestDeathCommand = "testmort"
Config.TestKillFeedCommand = "testkillfeed"

-- ================================================================================================
-- NOTIFICATIONS
-- ================================================================================================
Config.Messages = {
    arenaFull = "L'arène est pleine.",
    enterArena = "^2Vous êtes entré dans l'arène.",
    exitArena = "^1Vous avez quitté l'arène.",
    notInArena = "Vous n'êtes pas dans l'arène.",
    playerDied = "Vous êtes mort. Réapparition effectuée.",
    killRecorded = " +$",
    accessStats = "Tu dois être dans l'arène pour accéder aux statistiques.",
    instanceCreated = "^3Instance créée pour la zone",
    instanceJoined = "^3Vous avez rejoint l'instance",
    instanceLeft = "^3Vous avez quitté l'instance"
}

-- ================================================================================================
-- STATISTIQUES & LEADERBOARD
-- ================================================================================================
Config.LeaderboardKey = 183
Config.SaveStatsToDatabase = true
Config.DatabaseUpdateInterval = 60
Config.LeaderboardLimit = 20
Config.LeaderboardUpdateInterval = 30

-- ================================================================================================
-- POLYZONE
-- ================================================================================================
Config.UsePolyZone = true
Config.PolyZoneDebug = false

-- ================================================================================================
-- AUTO-JOIN DÉSACTIVÉ
-- ================================================================================================
Config.AutoJoin = false
Config.AutoJoinCheckInterval = 500

-- ================================================================================================
-- INTERFACE (NUI)
-- ================================================================================================
Config.KillFeed = {
    enabled = true,
    duration = 5000,
    maxMessages = 5
}

-- ================================================================================================
-- ⚡ PERFORMANCE - TIMINGS OPTIMISÉS (v4.0)
-- ================================================================================================
Config.Threads = {
    deathCheck = 500,
    staminaReset = 1000,
    zoneMarker = 0,
    pedInteraction = 250,
    zoneCheck = 1000,
    autoJoin = 2000,
    helpMessage = 0,
    distanceCheck = 500,
    cacheRefresh = 500
}
