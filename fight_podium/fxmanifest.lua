shared_script '@WaveShield/resource/include.lua'

--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                     FIGHT LEAGUE PODIUM                       ║
    ║                  Système de Podium Modulable                  ║
    ║                      Version 1.0.0 - 2025                     ║
    ╚═══════════════════════════════════════════════════════════════╝

    Description: Système optimisé de placement de props pour podium
    Auteur: Fight League Dev Team
    Licence: MIT
]]

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Fight League'
description 'Système de podium avec props optimisé - Architecture modulable'
version '1.0.0'

-- ═══════════════════════════════════════════════════════════════
--  CONFIGURATION DES FICHIERS
-- ═══════════════════════════════════════════════════════════════

shared_scripts {
    'config/*.lua'
}

client_scripts {
    'client/*.lua'
}

-- Optionnel: Scripts serveur pour synchronisation multi-joueurs
-- server_scripts {
--     'server/*.lua'
-- }

-- ═══════════════════════════════════════════════════════════════
--  DÉPENDANCES (si nécessaire)
-- ═══════════════════════════════════════════════════════════════

-- dependencies {
--     'es_extended'
-- }

-- ═══════════════════════════════════════════════════════════════
--  METADATA
-- ═══════════════════════════════════════════════════════════════

files {
    'README.md'
}
