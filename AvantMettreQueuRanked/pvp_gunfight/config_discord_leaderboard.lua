-- ========================================
-- PVP GUNFIGHT - CONFIGURATION CLASSEMENTS DISCORD
-- Version 4.1 - WEBHOOKS SÉCURISÉS (SANS URLS EN CLAIR)
-- ========================================

ConfigDiscordLeaderboard = {}

-- ========================================
-- 🔒 SÉCURITÉ WEBHOOKS
-- ========================================
--[[
    ⚠️ IMPORTANT : LES WEBHOOKS NE SONT PLUS STOCKÉS ICI !
    
    Pour configurer vos webhooks Discord de manière sécurisée:
    
    1. Ajoutez dans votre server.cfg:
       setr gfranked_webhook_key "VOTRE_CLE_SECRETE_LONGUE_ET_COMPLEXE"
    
    2. Installez la table SQL:
       Exécutez sql/install.sql dans votre base de données
    
    3. Configurez vos webhooks in-game avec la commande:
       /gfrankedsetwebhook 1v1 https://discord.com/api/webhooks/...
       /gfrankedsetwebhook 2v2 https://discord.com/api/webhooks/...
       /gfrankedsetwebhook 3v3 https://discord.com/api/webhooks/...
       /gfrankedsetwebhook 4v4 https://discord.com/api/webhooks/...
    
    4. Vérifiez vos webhooks:
       /gfrankedshowwebhooks
    
    5. Testez un webhook:
       /gfrankedtestwebhook 1v1
    
    ✅ Avantages:
    - Webhooks chiffrés dans la base de données
    - Impossible de les lire depuis les fichiers
    - Même si quelqu'un vole vos fichiers, vos webhooks restent protégés
    - Gestion facile via commandes in-game
]]

-- ========================================
-- ⚠️ ANCIEN SYSTÈME (NE PLUS UTILISER)
-- ========================================
ConfigDiscordLeaderboard.Webhooks = {
    ['1v1'] = nil, -- ⚠️ Utilisez /gfrankedsetwebhook 1v1 [url]
    ['2v2'] = nil, -- ⚠️ Utilisez /gfrankedsetwebhook 2v2 [url]
    ['3v3'] = nil, -- ⚠️ Utilisez /gfrankedsetwebhook 3v3 [url]
    ['4v4'] = nil, -- ⚠️ Utilisez /gfrankedsetwebhook 4v4 [url]
    ['general'] = nil,
    ['logs'] = nil
}

-- ========================================
-- CONFIGURATION GÉNÉRALE
-- ========================================
ConfigDiscordLeaderboard.TopPlayersCount = 10      -- ✅ Limité à 10 joueurs
ConfigDiscordLeaderboard.ShowAllPlayers = false
ConfigDiscordLeaderboard.MinGamesRequired = 1

-- ========================================
-- ENVOI AUTOMATIQUE
-- ========================================
ConfigDiscordLeaderboard.AutoSend = true
ConfigDiscordLeaderboard.AutoSendInterval = 24     -- Heures entre chaque envoi
ConfigDiscordLeaderboard.AutoSendTime = {
    hour = 20,
    minute = 0
}
ConfigDiscordLeaderboard.SendAllModesAtOnce = true
ConfigDiscordLeaderboard.DelayBetweenModes = 2     -- Secondes entre chaque mode

-- ========================================
-- STYLE VISUEL (GUNFIGHT ARENA)
-- ========================================

-- Titre principal de l'embed
ConfigDiscordLeaderboard.TitleFormat = '🏆 **FIGHT LEAGUE RANKINGS • SEASON 1**'

-- Sous-titre avec le mode
ConfigDiscordLeaderboard.SubtitleFormat = '━━━━━━━━━━ **{mode}** ━━━━━━━━━━'

-- Séparateur entre joueurs
ConfigDiscordLeaderboard.Separator = '— — — — — — — —'

-- ========================================
-- AFFICHAGE DES SECTIONS
-- ========================================
ConfigDiscordLeaderboard.ShowGlobalStatsTop = true      -- Stats globales en haut (6 fields)
ConfigDiscordLeaderboard.ShowFooterInfo = true          -- Infos en bas (leader, meilleur ELO, etc.)
ConfigDiscordLeaderboard.ShowHeader = false

-- ========================================
-- IMAGES
-- ========================================
ConfigDiscordLeaderboard.ModeThumbnails = {
    ['1v1'] = 'https://i.imgur.com/Oq5gxWS.png',
    ['2v2'] = 'https://i.imgur.com/Oq5gxWS.png',
    ['3v3'] = 'https://i.imgur.com/Oq5gxWS.png',
    ['4v4'] = 'https://i.imgur.com/Oq5gxWS.png'
}

ConfigDiscordLeaderboard.BannerImage = 'https://i.imgur.com/Oq5gxWS.png'
ConfigDiscordLeaderboard.BotAvatar = 'https://i.imgur.com/Oq5gxWS.png'

ConfigDiscordLeaderboard.Footer = {
    text = 'Voici le classement du serveur',
    icon_url = 'https://i.imgur.com/Oq5gxWS.png'
}

-- ========================================
-- COULEURS PAR MODE (Décimal)
-- ========================================
ConfigDiscordLeaderboard.Colors = {
    ['1v1'] = 15158332,     -- Rouge
    ['2v2'] = 3447003,      -- Bleu
    ['3v3'] = 16750848,     -- Orange
    ['4v4'] = 5763719,      -- Vert
    ['general'] = 65535,    -- Cyan
    ['success'] = 5763719,
    ['warning'] = 16705372,
    ['info'] = 3447003
}

-- ========================================
-- NOMS DES MODES
-- ========================================
ConfigDiscordLeaderboard.ModeNames = {
    ['1v1'] = 'SOLO 1v1',
    ['2v2'] = 'DUO 2v2',
    ['3v3'] = 'TRIO 3v3',
    ['4v4'] = 'SQUAD 4v4',
    ['general'] = 'GENERAL'
}

ConfigDiscordLeaderboard.ModeDescriptions = {
    ['1v1'] = 'Combat singulier',
    ['2v2'] = 'Combat en duo',
    ['3v3'] = 'Combat en trio',
    ['4v4'] = 'Combat d\'escouade',
    ['general'] = 'Classement general'
}

-- ========================================
-- SYSTÈME DE RANGS PAR ELO
-- ========================================
ConfigDiscordLeaderboard.RankSystem = {
    enabled = true,
    ranks = {
        {name = 'MASTER',   min_elo = 2000, emoji = '👑', color = '[1;35m'},
        {name = 'DIAMOND',  min_elo = 1800, emoji = '💎', color = '[1;36m'},
        {name = 'PLATINUM', min_elo = 1600, emoji = '💠', color = '[1;37m'},
        {name = 'GOLD',     min_elo = 1400, emoji = '🥇', color = '[1;33m'},
        {name = 'SILVER',   min_elo = 1200, emoji = '🥈', color = '[2;37m'},
        {name = 'BRONZE',   min_elo = 0,    emoji = '🥉', color = '[2;33m'}
    }
}

-- ========================================
-- EMOJIS
-- ========================================
ConfigDiscordLeaderboard.Emojis = {
    -- Podium
    first = '🥇',
    second = '🥈',
    third = '🥉',
    
    -- Stats
    players = '👥',
    kills = '💀',
    deaths = '☠️',
    kd_ratio = '🎯',
    elo = '⚡',
    record = '🔥',
    
    -- Rangs
    bronze = '🥉',
    silver = '🥈',
    gold = '🥇',
    platinum = '💠',
    diamond = '💎',
    master = '👑',
    
    -- Divers
    trophy = '🏆',
    star = '⭐',
    crown = '👑',
    fire = '🔥'
}

-- ========================================
-- MÉDAILLES PODIUM
-- ========================================
ConfigDiscordLeaderboard.RankMedals = {
    [1] = '🥇',
    [2] = '🥈', 
    [3] = '🥉'
}

-- ========================================
-- MENTIONS (DÉSACTIVÉES)
-- ========================================
ConfigDiscordLeaderboard.RoleMentions = {
    enabled = false,
    roles = {
        top1 = nil,
        top3 = nil,
        top10 = nil
    }
}

-- ========================================
-- COMMANDES
-- ========================================
ConfigDiscordLeaderboard.AdminAce = 'admin'

ConfigDiscordLeaderboard.Commands = {
    sendLeaderboard = 'pvpleaderboard',     -- /pvpleaderboard : Envoie les 4 modes
    sendMode = 'pvpsendmode',               -- /pvpsendmode 1v1 : Envoie un mode spécifique
    forceUpdate = 'pvpupdate',
    playerStats = 'pvpstats',
    resetStats = 'pvpreset'
}

-- ========================================
-- RATE LIMIT
-- ========================================
ConfigDiscordLeaderboard.RateLimit = {
    enabled = true,
    maxRequestsPerMinute = 5,
    cooldownSeconds = 60
}

-- ========================================
-- NOTIFICATIONS TEMPS RÉEL (DÉSACTIVÉES)
-- ========================================
ConfigDiscordLeaderboard.RealtimeNotifications = {
    enabled = false,
    newTopPlayer = false,
    newKillRecord = false,
    winStreak = {
        enabled = false,
        threshold = 5
    }
}

-- ========================================
-- STATISTIQUES À AFFICHER
-- ========================================
ConfigDiscordLeaderboard.StatsToShow = {
    wins = false,
    losses = false,
    kills = true,
    deaths = true,
    kd_ratio = true,
    win_rate = false,
    total_games = false,
    win_streak = false,
    best_streak = true,
    elo = true
}

-- ========================================
-- RESET PÉRIODIQUE (DÉSACTIVÉ)
-- ========================================
ConfigDiscordLeaderboard.AutoReset = {
    enabled = false,
    type = 'monthly',
    resetDay = 1,
    resetTime = {hour = 0, minute = 0},
    saveBeforeReset = true,
    sendFinalLeaderboard = true
}

-- ========================================
-- MESSAGES PERSONNALISÉS
-- ========================================
ConfigDiscordLeaderboard.Messages = {
    noData = 'Aucun joueur dans le classement pour le moment.',
    newTopPlayer = '🎉 **NOUVEAU CHAMPION !**\n{player} est desormais #1 en {mode} !',
    newRecord = '🔥 **NOUVEAU RECORD !**\n{player} : {value} en {mode}',
    winStreak = '⚡ **SERIE INCROYABLE !**\n{player} : {streak} victoires consecutives !'
}

-- ========================================
-- DEBUG
-- ========================================
ConfigDiscordLeaderboard.Debug = false
ConfigDiscordLeaderboard.ShowErrors = true
ConfigDiscordLeaderboard.TestWebhook = nil
ConfigDiscordLeaderboard.TestMode = false

-- ========================================
-- FONCTIONS UTILITAIRES
-- ========================================

-- Formater le K/D
function ConfigDiscordLeaderboard.FormatKD(kills, deaths)
    if deaths == 0 then
        return string.format("%.2f", kills)
    end
    return string.format("%.2f", kills / deaths)
end

-- Obtenir le rang par ELO
function ConfigDiscordLeaderboard.GetRankByElo(elo)
    for _, rank in ipairs(ConfigDiscordLeaderboard.RankSystem.ranks) do
        if elo >= rank.min_elo then
            return rank
        end
    end
    return ConfigDiscordLeaderboard.RankSystem.ranks[#ConfigDiscordLeaderboard.RankSystem.ranks]
end

return ConfigDiscordLeaderboard

--[[
============================================
NOTES DE CONFIGURATION v4.1 - WEBHOOKS SÉCURISÉS
============================================

🔒 SÉCURITÉ:
- Les webhooks ne sont PLUS stockés dans ce fichier
- Utilisez le système de commandes pour configurer vos webhooks
- Les webhooks sont chiffrés dans la base de données
- Même si quelqu'un vole vos fichiers, vos webhooks restent protégés

📋 INSTALLATION:
1. Exécutez sql/install.sql dans votre base de données
2. Ajoutez dans server.cfg: setr gfranked_webhook_key "CLE_SECRETE"
3. Configurez vos webhooks: /gfrankedsetwebhook [mode] [url]

🎮 COMMANDES DISPONIBLES:
- /gfrankedsetwebhook [mode] [url] : Définir un webhook
- /gfrankedshowwebhooks : Voir les webhooks configurés
- /gfrankeddeletewebhook [mode] : Supprimer un webhook
- /gfrankedtestwebhook [mode] : Tester un webhook
- /gfrankedwebhookhelp : Aide sur les commandes

✅ AVANTAGES:
- Protection totale contre le vol de webhooks
- Gestion facile via commandes
- Chiffrement automatique
- Webhooks masqués dans l'interface

============================================
]]
