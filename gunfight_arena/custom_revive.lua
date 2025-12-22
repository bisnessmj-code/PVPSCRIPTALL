-- ================================================================================================
-- GUNFIGHT ARENA - CUSTOM REVIVE v2.0 OPTIMISÉ CPU
-- ================================================================================================
-- ✅ SUPPRESSION du double Wait(0) - économie CPU majeure
-- ✅ Utilisation du cache global pour éviter les appels natifs
-- ✅ Thread à intervalle contrôlé (500ms)
-- ================================================================================================

ESX = exports["es_extended"]:getSharedObject()

local deathHandled = false

-- ================================================================================================
-- FONCTION : LOG DEBUG (Conditionnel)
-- ================================================================================================
local function DebugLog(message, logType)
    if not Config.DebugClient then return end
    
    local prefixes = {
        error = "^1[GF-Revive ERROR]^0",
        success = "^2[GF-Revive OK]^0"
    }
    
    print((prefixes[logType] or "^6[GF-Revive]^0") .. " " .. message)
end

-- ================================================================================================
-- NOTE: La gestion de la mort est maintenant dans client.lua (thread deathCheck)
-- Ce fichier est conservé pour la commande de test uniquement
-- ================================================================================================

-- ================================================================================================
-- COMMANDE : TEST DE MORT (DÉVELOPPEMENT)
-- ================================================================================================
RegisterCommand(Config.TestDeathCommand, function(source, args, rawCommand)
    DebugLog("=== COMMANDE TEST MORT ===")
    
    if not isInArena then
        TriggerEvent('chat:addMessage', {
            args = { "^1Erreur :", "Vous devez être dans l'arène pour tester." }
        })
        return
    end
    
    local playerPed = PlayerPedId()
    SetEntityHealth(playerPed, 0)
    DebugLog("Joueur tué (test)", "success")
    
    TriggerEvent('chat:addMessage', {
        args = { "^3Test :", "Mort simulée." }
    })
end, false)

-- ================================================================================================
-- INITIALISATION
-- ================================================================================================
Citizen.CreateThread(function()
    Citizen.Wait(1000)
    
    if Config.DebugClient then
        print("^2[GF-Revive v2.0-OPT]^0 Chargé")
        print("^3[GF-Revive v2.0-OPT]^0 Commande test: /" .. Config.TestDeathCommand)
    end
end)
