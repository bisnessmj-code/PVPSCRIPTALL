--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║         FIGHTLEAGUE COURSE - CONFIGURATION PRINCIPALE         ║
    ║                   Performance First Design                     ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    IMPORTANT : Toutes les valeurs de ce fichier sont configurables
    Aucune valeur hardcodée dans le code principal
]]

Config = {}

-- ═════════════════════════════════════════════════════════════════
-- DEBUG & LOGS
-- ═════════════════════════════════════════════════════════════════
Config.Debug = {
    Enabled = true,          -- Active/désactive tous les logs
    Client = true,           -- Logs client
    Server = true,           -- Logs serveur
    Matchmaking = true,      -- Logs matchmaking
    Buckets = true,          -- Logs routing buckets
    Commands = true          -- Logs commandes admin
}

-- ═════════════════════════════════════════════════════════════════
-- SYSTÈME DE MATCHMAKING
-- ═════════════════════════════════════════════════════════════════
Config.Matchmaking = {
    MinPlayers = 2,                  -- Nombre de joueurs minimum pour lancer une partie
    MaxWaitTime = 300,               -- Temps max d'attente en secondes (5 min)
    StartingBucketId = 2000,         -- ID de départ des routing buckets
    MaxConcurrentGames = 50,         -- Nombre max de parties simultanées
    PreStartDelay = 2000,            -- Délai avant le départ (ms) - pour connexions lentes
}

-- ═════════════════════════════════════════════════════════════════
-- SYSTÈME DE ROUNDS
-- ═════════════════════════════════════════════════════════════════
Config.Rounds = {
    TotalRounds = 4,                 -- Nombre total de rounds par partie
    RoundDuration = 105,             -- Durée max d'un round en secondes (1min 45s)
    
    -- Vérification de distance pour fuite réussie
    DistanceCheckInterval = 15,      -- Vérification toutes les 15 secondes
    EscapeDistance = 100.0,          -- Distance minimale pour fuite réussie (mètres)
    
    -- Système de capture
    CaptureDistance = 5.0,           -- Distance max pour être "collé" (mètres)
    CaptureSpeed = 2.0,              -- Vitesse max pour considérer "à l'arrêt" (km/h)
    CaptureTime = 5.0,               -- Temps pour compléter la capture (secondes)
    CaptureCheckInterval = 100,      -- Intervalle de vérification capture (ms)
    
    -- Délais entre rounds
    RoundEndDelay = 5000,            -- Délai après fin round avant nouveau round (ms)
    RespawnDelay = 1000,             -- Délai pour supprimer véhicules et respawn (ms)
}

-- ═════════════════════════════════════════════════════════════════
-- POINT FINAL
-- ═════════════════════════════════════════════════════════════════
Config.EndPoint = vector4(241.041764, -885.468140, 30.476196, 70.86614)

-- ═════════════════════════════════════════════════════════════════
-- PED D'INSCRIPTION
-- ═════════════════════════════════════════════════════════════════
Config.Ped = {
    Model = 'a_m_y_business_03',     -- Modèle du PED
    Coords = vector4(230.637360, -869.986816, 30.476196, 345.826782),
    
    -- Distance d'interaction (optimisation CPU)
    DrawDistance = 50.0,             -- Distance pour afficher le marker
    InteractDistance = 2.5,          -- Distance pour afficher le texte d'aide
    ToleranceZone = 10.0,            -- Zone de tolérance pour éviter le clignotement (hysteresis)
    
    -- Marker visuel
    Marker = {
        Type = 1,                    -- Type de marker (1 = cylindre)
        Color = {r = 0, g = 255, b = 0, a = 100},
        Size = {x = 1.5, y = 1.5, z = 1.0},
        BobUpDown = true,
        Rotate = false
    },
    
    -- Texte d'interaction
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
    Model = 'adder',                 -- Modèle de véhicule (changeable)
    Plate = 'FIGHTLG',              -- Plaque d'immatriculation
    Locked = true,                   -- Véhicule verrouillé (empêche de sortir)
    Invincible = false,              -- Véhicule invincible ?
    GodMode = false                  -- Mode dieu ?
}

-- ═════════════════════════════════════════════════════════════════
-- TIMINGS & PERFORMANCE
-- ═════════════════════════════════════════════════════════════════
Config.Timings = {
    -- Client
    PedCheckInterval = 1000,         -- Intervalle de vérification de distance du PED (ms)
    MarkerUpdateRate = 100,          -- Taux de rafraîchissement du marker quand proche (ms)
    
    -- Server
    MatchmakingCheckInterval = 2000, -- Intervalle de vérification du matchmaking (ms)
    GameCleanupDelay = 5000,         -- Délai avant nettoyage d'une partie terminée (ms)
}

-- ═════════════════════════════════════════════════════════════════
-- PERMISSIONS ADMIN
-- ═════════════════════════════════════════════════════════════════
Config.Permissions = {
    KickAll = 'admin',               -- Permission pour /kickallcourse
    KickById = 'admin',              -- Permission pour /kickbyid
    ViewStatus = 'admin'             -- Permission pour voir le statut
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

-- Récupère un spawn aléatoire
function Config.GetRandomSpawn()
    return Config.Spawns[math.random(#Config.Spawns)]
end

-- Vérifie si le debug est actif pour un module
function Config.IsDebugEnabled(module)
    if not Config.Debug.Enabled then return false end
    if module and Config.Debug[module] ~= nil then
        return Config.Debug[module]
    end
    return true
end