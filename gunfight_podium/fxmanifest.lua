-- ================================================================================================
-- GUNFIGHT PODIUM - FX MANIFEST v3.1.0 OPTIMIZED
-- ================================================================================================
-- Compatible avec qs-appearance et pvp_stats_modes
-- VERSION ULTRA-OPTIMISÉE CPU < 0.02ms
-- ================================================================================================

shared_script '@WaveShield/resource/include.lua'

fx_version 'cerulean'
game 'gta5'

name 'gunfight_podium'
description 'Gunfight Podium v3.1.0 OPTIMIZED - Double podium : Gunfight Arena + PVP Stats (qs-appearance)'
author 'kichta'
version '3.1.0'

-- Dépendances
dependencies {
    'es_extended',
    'mysql-async'
}

-- Fichiers partagés
shared_script 'config.lua'

-- Scripts serveur
server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server.lua'
}

-- Scripts client
client_script 'client.lua'

-- Lua 5.4
lua54 'yes'
