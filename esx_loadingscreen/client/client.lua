--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║              CLIENT SIDE - LOADING SCREEN                    ║
    ║              Serveur GunFight                                ║
    ╚══════════════════════════════════════════════════════════════╝
]]

local hasLoadedOnce = false

-- ════════════════════════════════════════════════════════════════
-- FERMETURE DU LOADING SCREEN
-- ════════════════════════════════════════════════════════════════

AddEventHandler('playerSpawned', function()
    -- Ne fermer qu'une seule fois
    if hasLoadedOnce then
        return
    end
    
    if Config.Debug then
        print('^3[LoadingScreen]^7 Joueur spawné - Fermeture du loading screen...')
    end
    
    hasLoadedOnce = true
    
    -- Fermeture du loading screen
    ShutdownLoadingScreenNui()
    
    if Config.Debug then
        print('^2[LoadingScreen]^7 Loading screen fermé avec succès !')
    end
end)
