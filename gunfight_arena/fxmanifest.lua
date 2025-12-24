shared_script '@WaveShield/resource/include.lua'

fx_version 'cerulean'
game 'gta5'

shared_script '@es_extended/imports.lua'

description 'Gunfight Arena - v4.3 OPTIMISÉ WEBP'
author 'kichta'
version '4.3.0'

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
    'server_security.lua',
    'discord_leaderboard_secure.lua'
}

-- ================================================================================================
-- INTERFACE (NUI) - IMAGES AU FORMAT WEBP
-- ================================================================================================
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    -- ✅ Images optimisées au format WebP
    'html/images/zone1.webp',
    'html/images/zone2.webp',
    'html/images/zone3.webp',
    'html/images/zone4.webp',
    'html/images/zone5.webp',
    'html/images/zone6.webp',
    'html/images/zone7.webp',
    'html/images/zone8.webp',
    'html/images/zone9.webp',
    'html/images/zone10.webp',
    -- Logo (peut rester en PNG ou passer en WebP)
    'html/images/logo.wep',
    -- Image par défaut
    'html/images/default.webp'
}

-- ================================================================================================
-- DÉPENDANCES
-- ================================================================================================
dependencies {
    'es_extended',
    'PolyZone'
}
