shared_script '@WaveShield/resource/include.lua'

fx_version 'cerulean'
game 'gta5'

shared_script '@es_extended/imports.lua'

description 'Gunfight Arena - v4.1 SÉCURISÉ'
author 'kichta'
version '4.1.0'

-- ================================================================================================
-- MODULE DE SÉCURITÉ (Chargé en premier - IMPORTANT L'ORDRE)
-- ================================================================================================
server_script 'security_module.lua'

-- ================================================================================================
-- CONFIGURATIONS (L'ordre est important)
-- ================================================================================================
shared_scripts {
    'config.lua'
}

-- Configuration Discord sécurisée (chargée APRÈS security_module.lua)
server_script 'config_discord_secure.lua'

-- ================================================================================================
-- SCRIPTS CLIENT
-- ================================================================================================
client_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/EntityZone.lua',
    '@PolyZone/CircleZone.lua',
    '@PolyZone/ComboZone.lua',
    'bridge_inventory.lua',
    'client.lua',
    'custom_revive.lua'
}

-- ================================================================================================
-- SCRIPTS SERVEUR (L'ordre est important)
-- ================================================================================================
server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'bridge_inventory_server.lua',
    'server.lua',
    'server_security.lua',           -- Commandes admin sécurisées
    'discord_leaderboard_secure.lua' -- Version sécurisée du leaderboard
}

-- ================================================================================================
-- INTERFACE (NUI)
-- ================================================================================================
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/images/zone1.png',
    'html/images/zone2.png',
    'html/images/zone3.png',
    'html/images/zone4.png',
    'html/images/zone5.png',
    'html/images/zone6.png',
    'html/images/zone7.png',
    'html/images/zone8.png',
    'html/images/zone9.png',
    'html/images/zone10.png',
    'html/images/logo.png',
    'html/images/default.png'
}

-- ================================================================================================
-- DÉPENDANCES
-- ================================================================================================
dependencies {
    'es_extended',
    'PolyZone'
}
