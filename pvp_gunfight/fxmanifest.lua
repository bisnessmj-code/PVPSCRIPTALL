

-- ========================================
-- PVP GUNFIGHT - FX MANIFEST
-- Version 4.1.1 - WEBHOOKS SÉCURISÉS
-- ========================================

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'PVP GunFight'
description 'Système PVP GunFight Ultra-Optimisé + Webhooks Sécurisés - v4.1.1'
version '4.1.1'

-- ========================================
-- SCRIPTS PARTAGÉS
-- ========================================
shared_scripts {
    '@es_extended/imports.lua',
    'config.lua',
    'shared/debug.lua',
    'config_discord_leaderboard.lua'
}

-- ========================================
-- SCRIPTS CLIENT
-- ========================================
client_scripts {
    'client/cache.lua',
    'client/inventory_bridge.lua',
    'client/damage_system.lua',
    'client/main.lua',
    'client/zones.lua',
    'client/teammate_hud.lua'
}

-- ========================================
-- SCRIPTS SERVEUR
-- ========================================
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/elo.lua',
    'server/groups.lua',
    'server/discord.lua',
    'server/inventory_bridge.lua',
    'server/webhook_manager.lua',      -- 🔒 NOUVEAU: Gestionnaire de webhooks sécurisés
    'server/main.lua',
    'server/discord_leaderboard.lua'   -- 🔒 MODIFIÉ: Utilise les webhooks sécurisés
}

-- ========================================
-- INTERFACE NUI
-- ========================================
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

-- ========================================
-- DÉPENDANCES
-- ========================================
dependencies {
    'es_extended',
    'oxmysql'
}
