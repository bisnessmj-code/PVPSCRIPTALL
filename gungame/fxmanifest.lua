shared_script '@WaveShield/resource/include.lua'

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                           GUNGAME - FiveM/ESX                             ║
    ║                        Script Ultra-Optimisé                               ║
    ║                    100+ Joueurs - Zero CPU Overhead                        ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

fx_version 'cerulean'
game 'gta5'

author 'GunGame Pro'
description 'GunGame ESX - Script haute performance, 40 armes, événementiel'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@es_extended/imports.lua',
    'config/config.lua',
    'config/weapons.lua',
    'config/maps.lua'
}

client_scripts {
    'client/main.lua',
    'client/ui.lua',
    'client/debug.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/game.lua',
    'server/kills.lua'
}

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/style.css',
    'nui/script.js'
}

dependencies {
    'es_extended'
}
