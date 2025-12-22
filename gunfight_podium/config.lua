-- ================================================================================================
-- GUNFIGHT PODIUM - CONFIGURATION v3.0.0
-- ================================================================================================
-- Système d'affichage des 3 meilleurs joueurs sur DEUX podiums distincts
-- Compatible avec qs-appearance et pvp_stats_modes
-- Podium 1 : Gunfight Arena (gunfight_stats)
-- Podium 2 : PVP Stats par mode (pvp_stats_modes)
-- ================================================================================================

Config = {}

-- ================================================================================================
-- DEBUG
-- ================================================================================================
Config.Debug = false -- Mettre à false en production

-- ================================================================================================
-- PODIUMS ACTIVÉS
-- ================================================================================================
Config.Podiums = {
    gunfight = true,  -- Activer le podium Gunfight Arena
    pvp = true        -- Activer le podium PVP Stats
}

-- ================================================================================================
-- POSITIONS DU PODIUM GUNFIGHT ARENA
-- ================================================================================================
Config.PodiumGunfight = {
    -- 🥇 PREMIÈRE PLACE
    [1] = {
        pos = vector3(-2649.718750, -775.951660, 5.263062),
        heading = 31.181102,
        label = "🥇",
        color = { r = 255, g = 215, b = 0 }, -- Or
    },
    
    -- 🥈 DEUXIÈME PLACE
    [2] = {
        pos = vector3(-2648.571534, -775.714294, 5.263062),
        heading = 39.685040,
        label = "🥈",
        color = { r = 192, g = 192, b = 192 }, -- Argent
    },
    
    -- 🥉 TROISIÈME PLACE
    [3] = {
        pos = vector3(-2650.140625, -776.940674, 5.263062),
        heading = 28.346456,
        label = "🥉",
        color = { r = 205, g = 127, b = 50 }, -- Bronze
    }
}

-- ================================================================================================
-- POSITIONS DU PODIUM PVP STATS
-- ================================================================================================
Config.PodiumPVP = {
    -- 🥇 PREMIÈRE PLACE
    [1] = {
        pos = vector3(-2648.703370, -767.261536, 5.161866),
        heading = 110.551186,
        label = "🥇",
        color = { r = 255, g = 215, b = 0 }, -- Or
    },
    
    -- 🥈 DEUXIÈME PLACE
    [2] = {
        pos = vector3(-2647.780274, -768.567016, 5.161866),
        heading = 96.377944,
        label = "🥈",
        color = { r = 192, g = 192, b = 192 }, -- Argent
    },
    
    -- 🥉 TROISIÈME PLACE
    [3] = {
        pos = vector3(-2648.175782, -766.008790, 5.161866),
        heading = 96.377944,
        label = "🥉",
        color = { r = 205, g = 127, b = 50 }, -- Bronze
    }
}

-- ================================================================================================
-- TEXTE 3D
-- ================================================================================================
Config.Text3D = {
    enabled = true,
    drawDistance = 16.5, -- Distance d'affichage
    scale = 0.35,
    font = 4,
    refreshRate = 0, -- Thread refresh en ms (0 = chaque frame pour affichage fluide)
    
    -- Activation globale des éléments
    showLabel = true,    -- Afficher le label (🥇, 🥈, 🥉)
    showName = true,     -- Afficher le nom du joueur
    showStats = false,    -- Afficher les statistiques (voir Config.StatsDisplay)
    
    -- Espacement vertical entre les textes (en unités GTA)
    spacing = {
        label = 1,      -- Espace entre le haut et le label (1ère place, etc.)
        name = 0.6,     -- Espace entre le label et le nom
        stats = 0.4     -- Espace entre chaque ligne de stats
    }
}

-- ================================================================================================
-- STATISTIQUES À AFFICHER
-- ================================================================================================
Config.StatsDisplay = {
    -- Pour le podium Gunfight
    gunfight = {
        -- Activation individuelle de chaque stat
        showKD = false,           -- Afficher le K/D ratio
        showKills = false,        -- Afficher Kills/Deaths
        showStreak = false,       -- Afficher Best Streak
        
        -- Format d'affichage (personnalisable)
        formatKD = "K/D: %.2f",
        formatKills = "Kills: %d | Deaths: %d",
        formatStreak = "Best Streak: %d"
    },
    
    -- Pour le podium PVP
    pvp = {
        -- Activation individuelle de chaque stat
        showElo = false,          -- Afficher l'ELO
        showWinLoss = false,      -- Afficher Wins/Losses
        showWinRate = false,      -- Afficher le Win Rate %
        showMatches = false,     -- Afficher le nombre de matchs joués
        showBestElo = false,     -- Afficher le meilleur ELO atteint
        showWinStreak = false,   -- Afficher la série de victoires actuelle
        showBestStreak = false,  -- Afficher la meilleure série de victoires
        showRankId = false,      -- Afficher l'ID du rang
        
        -- Format d'affichage (personnalisable)
        formatElo = "ELO: %d",
        formatWinLoss = "W/L: %d/%d",
        formatWinRate = "Win Rate: %.1f%%",
        formatMatches = "Matchs: %d",
        formatBestElo = "Best ELO: %d",
        formatWinStreak = "Streak: %d",
        formatBestStreak = "Best Streak: %d",
        formatRankId = "Rank: %d"
    }
}

-- ================================================================================================
-- MISE À JOUR AUTOMATIQUE
-- ================================================================================================
Config.AutoUpdate = {
    enabled = true,
    interval = 300000 -- Mise à jour toutes les 5 minutes (300000ms)
}

-- ================================================================================================
-- ANIMATIONS
-- ================================================================================================
Config.Animations = {
    enabled = true,
    scenarios = {
        [1] = "WORLD_HUMAN_MUSCLE_FLEX",    -- 1ère place : flex
        [2] = "WORLD_HUMAN_STAND_IMPATIENT", -- 2ème place : impatient
        [3] = "WORLD_HUMAN_GUARD_STAND"     -- 3ème place : garde
    }
}

-- ================================================================================================
-- BLIPS (OPTIONNEL)
-- ================================================================================================
Config.Blips = {
    gunfight = {
        enabled = false,
        pos = vector3(-2649.8, -764.6, 4.9),
        sprite = 304,
        color = 46,
        scale = 0.8,
        name = "🏆 Podium Gunfight"
    },
    
    pvp = {
        enabled = true,
        pos = vector3(-2648.2, -767.6, 6.1),
        sprite = 304,
        color = 3,
        scale = 0.8,
        name = "⚔️ Podium PVP"
    }
}

-- ================================================================================================
-- BASE DE DONNÉES
-- ================================================================================================
Config.DatabaseTables = {
    gunfight = "gunfight_stats",
    pvp = "pvp_stats_modes",  -- Nouvelle table avec modes
    users = "users"           -- Table users pour récupérer le skin
}

-- ================================================================================================
-- CONFIGURATION PVP MODES
-- ================================================================================================
Config.PVPMode = "1v1" -- Mode à afficher sur le podium : "1v1", "2v2", "3v3", "4v4"

-- ================================================================================================
-- CRITÈRES DE CLASSEMENT
-- ================================================================================================
Config.RankingCriteria = {
    gunfight = "kd",  -- "kd" (K/D ratio) ou "kills" (nombre de kills)
    pvp = "elo"       -- "elo" (classement ELO) ou "wins" (nombre de victoires)
}

-- ================================================================================================
-- OPTIMISATION
-- ================================================================================================
Config.Optimization = {
    cleanupOldPeds = true,
    freezePeds = true,
    invincible = true,
    blockEvents = true,
    disablePhysics = true,
    disableCollisions = true,
    notCulpable = true
}

-- ================================================================================================
-- MESSAGES
-- ================================================================================================
Config.Messages = {
    podiumUpdated = "^2[Podium]^0 Classement mis à jour !",
    gunfightUpdated = "^2[Podium]^0 Podium Gunfight mis à jour !",
    pvpUpdated = "^2[Podium]^0 Podium PVP mis à jour !",
    noPodiumData = "^1[Podium]^0 Aucune donnée disponible.",
    pedCreated = "^2[Podium]^0 PED créé pour la place %s : %s",
    errorCreatingPed = "^1[Podium]^0 Erreur lors de la création du PED pour la place %s"
}

-- ================================================================================================
-- FIN DE LA CONFIGURATION
-- ================================================================================================
print("^2[Gunfight Podium v3.1.0 OPTIMIZED]^0 Configuration chargée - Compatible qs-appearance")
