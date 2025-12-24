--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║         FIGHTLEAGUE COURSE - CONFIGURATION PRINCIPALE         ║
    ║                   Performance First Design                     ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    CORRECTIFS APPLIQUÉS :
    - Hystérésis renforcée pour éviter clignotement marker
    - Délais réseau augmentés pour synchronisation véhicule
]]

Config = {}

-- ═════════════════════════════════════════════════════════════════
-- DEBUG & LOGS
-- ═════════════════════════════════════════════════════════════════
Config.Debug = {
    Enabled = true,
    Client = true,
    Server = true,
    Matchmaking = true,
    Buckets = true,
    Commands = true
}

-- ═════════════════════════════════════════════════════════════════
-- SYSTÈME DE MATCHMAKING
-- ═════════════════════════════════════════════════════════════════
Config.Matchmaking = {
    MinPlayers = 2,
    MaxWaitTime = 300,
    StartingBucketId = 2000,
    MaxConcurrentGames = 50,
    PreStartDelay = 3000,            -- CORRECTIF : Augmenté à 3s pour meilleure sync
}

-- ═════════════════════════════════════════════════════════════════
-- SYSTÈME DE ROUNDS
-- ═════════════════════════════════════════════════════════════════
Config.Rounds = {
    TotalRounds = 4,
    RoundDuration = 105,
    
    DistanceCheckInterval = 15,
    EscapeDistance = 100.0,
    
    CaptureDistance = 5.0,
    CaptureSpeed = 2.0,
    CaptureTime = 5.0,
    CaptureCheckInterval = 100,
    
    RoundEndDelay = 5000,
    RespawnDelay = 2000,             -- CORRECTIF : Augmenté à 2s pour meilleure suppression véhicule
}

-- ═════════════════════════════════════════════════════════════════
-- POINT FINAL
-- ═════════════════════════════════════════════════════════════════
Config.EndPoint = vector4(241.041764, -885.468140, 30.476196, 70.86614)

-- ═════════════════════════════════════════════════════════════════
-- PED D'INSCRIPTION
-- ═════════════════════════════════════════════════════════════════
Config.Ped = {
    Model = 'a_m_y_business_03',
    Coords = vector4(230.637360, -869.986816, 29.476196, 345.826782),
    
    -- CORRECTIF : Hystérésis renforcée
    DrawDistance = 10.0,
    InteractDistance = 2.5,
    ToleranceZone = 15.0,            -- CORRECTIF : Augmenté de 10 à 15 pour éviter clignotement
    
    Marker = {
        Type = 1,
        Color = {r = 0, g = 255, b = 0, a = 100},
        Size = {x = 1.5, y = 1.5, z = 1.0},
        BobUpDown = true,
        Rotate = false
    },
    
    HelpText = "Appuyez sur ~INPUT_CONTEXT~ pour rejoindre la file d'attente"
}

-- ═════════════════════════════════════════════════════════════════
-- SPAWNS DES VÉHICULES
-- ═════════════════════════════════════════════════════════════════
Config.Spawns = {
    {
        Name = "spawn1",
        TeamA = vector4(254.109894, -857.894532, 29.465210, 243.779526),
        TeamB = vector4(243.890106, -854.426392, 29.717896, 243.779526)
    },
    {
        Name = "spawn2",
        TeamA = vector4(263.195618, -900.883544, 28.976562, 158.740158),
        TeamB = vector4(267.745056, -888.791198, 29.027100, 161.574798)
    }
}

-- ═════════════════════════════════════════════════════════════════
-- VÉHICULES
-- ═════════════════════════════════════════════════════════════════
Config.Vehicle = {
    Model = 'adder',
    Plate = 'FIGHTLG',
    Locked = true,
    Invincible = false,
    GodMode = false
}

-- ═════════════════════════════════════════════════════════════════
-- TIMINGS & PERFORMANCE
-- ═════════════════════════════════════════════════════════════════
Config.Timings = {
    -- Client
    PedCheckInterval = 1000,
    MarkerUpdateRate = 100,
    
    -- Server
    MatchmakingCheckInterval = 2000,
    GameCleanupDelay = 5000,
}

-- ═════════════════════════════════════════════════════════════════
-- PERMISSIONS ADMIN
-- ═════════════════════════════════════════════════════════════════
Config.Permissions = {
    KickAll = 'admin',
    KickById = 'admin',
    ViewStatus = 'admin'
}

-- ═════════════════════════════════════════════════════════════════
-- TEXTES & NOTIFICATIONS
-- ═════════════════════════════════════════════════════════════════
Config.Lang = {
    -- Matchmaking
    JoinedQueue = "Vous avez rejoint la file d'attente...",
    LeftQueue = "Vous avez quitté la file d'attente",
    MatchFound = "Adversaire trouvé ! Préparation...",
    Searching = "Recherche d'adversaire en cours...",
    GameStarting = "La partie commence dans %s secondes !",
    
    -- Rounds
    RoundStart = "Round %d/%d - %s",
    RoundWin = "Round %d - VICTOIRE !",
    RoundLose = "Round %d - DÉFAITE",
    YouAreRunner = "Vous êtes le FUYEUR !",
    YouAreChaser = "Vous êtes le POURSUIVEUR !",
    EscapeSuccess = "Fuite réussie !",
    CaptureSuccess = "Capture réussie !",
    RoundTimeout = "Temps écoulé !",
    
    -- Fin de partie
    GameWin = "VICTOIRE - Vous avez gagné la partie !",
    GameLose = "DÉFAITE - Vous avez perdu la partie",
    GameDraw = "ÉGALITÉ - Match nul !",
    GameFinished = "Partie terminée ! Merci d'avoir joué.",
    
    -- Erreurs
    AlreadyInQueue = "Vous êtes déjà en file d'attente !",
    AlreadyInGame = "Vous êtes déjà en partie !",
    NoActiveGame = "Vous n'êtes pas en partie",
    
    -- Admin
    KickedFromGame = "Vous avez été éjecté de la partie",
    AllPlayersKicked = "Tous les joueurs ont été éjectés",
    PlayerKicked = "Le joueur %s a été éjecté",
    PlayerNotFound = "Joueur introuvable",
    NoPermission = "Vous n'avez pas la permission d'utiliser cette commande"
}

-- ═════════════════════════════════════════════════════════════════
-- FONCTIONS UTILITAIRES DE CONFIG
-- ═════════════════════════════════════════════════════════════════

function Config.GetRandomSpawn()
    return Config.Spawns[math.random(#Config.Spawns)]
end

function Config.IsDebugEnabled(module)
    if not Config.Debug.Enabled then return false end
    if module and Config.Debug[module] ~= nil then
        return Config.Debug[module]
    end
    return true
end