
-- ========================================
-- PVP GUNFIGHT - FX MANIFEST
-- Version 4.2.0 - SYSTÈME DE PERMISSIONS
-- ========================================

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'PVP GunFight'
description 'Système PVP GunFight Ultra-Optimisé + Système de Permissions - v4.2.0'
version '4.2.0'

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
    'server/webhook_manager.lua',
    'server/permissions.lua',          -- ✅ NOUVEAU: Système de permissions
    'server/main.lua',
    'server/discord_leaderboard.lua'
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
