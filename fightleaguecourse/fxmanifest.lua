fx_version 'cerulean'
game 'gta5'

author 'FightLeague'
description 'Script 1v1 Course/Poursuite avec Routing Buckets - Ultra Optimisé'
version '1.0.0'

-- Shared
shared_scripts {
    'shared/config.lua',
    'shared/utils.lua'
}

-- Client
client_scripts {
    'client/main.lua'
}

-- UI Files
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

-- Server
server_scripts {
    'server/main.lua',
    'server/commands.lua'
}

-- Dépendances
dependencies {
    '/server:5104',  -- Minimum version serveur pour routing buckets
}

lua54 'yes'
