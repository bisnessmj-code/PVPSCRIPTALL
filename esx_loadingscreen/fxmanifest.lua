shared_script '@WaveShield/resource/include.lua'

fx_version 'cerulean'
game 'gta5'

author 'FOLIEEEEE'
description 'Loading Screen Custom pour GunFight'
version '4.0.0'

-- ════════════════════════════════════════════════════════════════
-- LOADING SCREEN
-- ════════════════════════════════════════════════════════════════

loadscreen 'index.html'
loadscreen_manual_shutdown 'yes'

-- ════════════════════════════════════════════════════════════════
-- FICHIERS
-- ════════════════════════════════════════════════════════════════

files {
    'index.html',
    'css/*.css',
    'js/*.js',
    'images/*.*',
    'audio/*.*'
}

-- ════════════════════════════════════════════════════════════════
-- SCRIPTS
-- ════════════════════════════════════════════════════════════════

shared_script 'config.lua'

client_script 'client/client.lua'

-- ════════════════════════════════════════════════════════════════
-- LUA 5.4
-- ════════════════════════════════════════════════════════════════

lua54 'yes'
