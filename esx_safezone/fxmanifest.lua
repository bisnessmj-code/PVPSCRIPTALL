shared_script '@WaveShield/resource/include.lua'

-- # # # # # # # # # # # # # # # # # # # # # # # # # # #
-- #                                                   #
-- #             ESX SAFEZONE SCRIPT                   #
-- #           Professional FiveM Resource             #
-- #                                                   #
-- #  Author: Professional Lua Developer               #
-- #  Version: 2.0.0                                   #
-- #  Framework: ESX Legacy                            #
-- #  Description: Système de zones sécurisées avec    #
-- #               optimisation CPU ultra-poussée      #
-- #                                                   #
-- # # # # # # # # # # # # # # # # # # # # # # # # # # #

fx_version 'cerulean'
game 'gta5'

author 'Professional Lua Developer'
description 'Système de safe zones ultra-optimisé pour ESX Legacy (v2.0.0 - FIX freeze serveur)'
version '2.0.0'
lua54 'yes'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'es_extended'
}
