--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                  UTILITAIRE DE COORDONNÉES                    ║
    ║          Script pour obtenir facilement vos positions         ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    UTILISATION:
    1. Ajoutez ce fichier dans client_scripts du fxmanifest.lua
    2. Utilisez les commandes en jeu pour obtenir vos coordonnées
    3. Copiez-collez directement dans config.lua
    
    ATTENTION: Retirez ce fichier en production !


-- ═══════════════════════════════════════════════════════════════
--  COMMANDE: /getcoords
--  Affiche les coordonnées actuelles du joueur
-- ═══════════════════════════════════════════════════════════════

RegisterCommand("getcoords", function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    print("^2═══════════════════════════════════════════════════════^0")
    print("^3[COORDONNÉES]^0 Position actuelle du joueur")
    print("^2═══════════════════════════════════════════════════════^0")
    print("")
    print("^5Vector3:^0")
    print(string.format("vector3(%.6f, %.6f, %.6f)", coords.x, coords.y, coords.z))
    print("")
    print("^5Vector4:^0")
    print(string.format("vector4(%.6f, %.6f, %.6f, %.6f)", coords.x, coords.y, coords.z, heading))
    print("")
    print("^5Rotation (pour config.lua):^0")
    print(string.format("vector3(0.0, 0.0, %.6f)", heading))
    print("")
    print("^5Position (séparé):^0")
    print(string.format("X: %.6f", coords.x))
    print(string.format("Y: %.6f", coords.y))
    print(string.format("Z: %.6f", coords.z))
    print(string.format("Heading: %.6f", heading))
    print("")
    print("^2═══════════════════════════════════════════════════════^0")
    
    -- Notification en jeu
    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        local vehModel = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
        SetNotificationTextEntry("STRING")
        AddTextComponentString(string.format("Coordonnées copiées ! (Véhicule: %s)", vehModel))
        DrawNotification(false, false)
    else
        SetNotificationTextEntry("STRING")
        AddTextComponentString("Coordonnées affichées dans F8")
        DrawNotification(false, false)
    end
end, false)

-- Suggestion de commande
TriggerEvent('chat:addSuggestion', '/getcoords', 'Affiche vos coordonnées actuelles dans la console F8')

-- ═══════════════════════════════════════════════════════════════
--  COMMANDE: /savecoords [nom]
--  Sauvegarde les coordonnées avec un nom (format config.lua)
-- ═══════════════════════════════════════════════════════════════

local savedCoords = {}

RegisterCommand("savecoords", function(source, args)
    local name = args[1] or ("Position_" .. #savedCoords + 1)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    table.insert(savedCoords, {
        name = name,
        position = coords,
        heading = heading
    })
    
    print(string.format("^2[SAUVEGARDE]^0 Position ^3%s^0 sauvegardée", name))
    
    SetNotificationTextEntry("STRING")
    AddTextComponentString(string.format("Position '%s' sauvegardée", name))
    DrawNotification(false, false)
end, false)

TriggerEvent('chat:addSuggestion', '/savecoords', 'Sauvegarde vos coordonnées avec un nom', {
    { name = "nom", help = "Nom de la position (optionnel)" }
})

-- ═══════════════════════════════════════════════════════════════
--  COMMANDE: /listcoords
--  Affiche toutes les coordonnées sauvegardées
-- ═══════════════════════════════════════════════════════════════

RegisterCommand("listcoords", function()
    if #savedCoords == 0 then
        print("^1[ERREUR]^0 Aucune coordonnée sauvegardée")
        return
    end
    
    print("^2═══════════════════════════════════════════════════════^0")
    print("^3[COORDONNÉES SAUVEGARDÉES]^0 Format pour config.lua")
    print("^2═══════════════════════════════════════════════════════^0")
    print("")
    
    for i, data in ipairs(savedCoords) do
        print(string.format("^5-- Position %d: %s^0", i, data.name))
        print("{")
        print(string.format("    name = \"%s\",", data.name))
        print("    model = \"prop_boxpile_07d\",  -- Changez le modèle")
        print(string.format("    position = vector3(%.6f, %.6f, %.6f),", data.position.x, data.position.y, data.position.z))
        print(string.format("    rotation = vector3(0.0, 0.0, %.6f),", data.heading))
        print("    zOffset = 0.0,")
        print("    scale = vector3(1.0, 1.0, 1.0),")
        print("    alpha = 255,")
        print("    stackedProps = {}")
        print("},")
        print("")
    end
    
    print("^2═══════════════════════════════════════════════════════^0")
end, false)

TriggerEvent('chat:addSuggestion', '/listcoords', 'Affiche toutes les coordonnées sauvegardées')

-- ═══════════════════════════════════════════════════════════════
--  COMMANDE: /clearcoords
--  Efface toutes les coordonnées sauvegardées
-- ═══════════════════════════════════════════════════════════════

RegisterCommand("clearcoords", function()
    savedCoords = {}
    print("^3[NETTOYAGE]^0 Toutes les coordonnées sauvegardées ont été effacées")
    
    SetNotificationTextEntry("STRING")
    AddTextComponentString("Coordonnées effacées")
    DrawNotification(false, false)
end, false)

TriggerEvent('chat:addSuggestion', '/clearcoords', 'Efface toutes les coordonnées sauvegardées')

-- ═══════════════════════════════════════════════════════════════
--  COMMANDE: /showprop [model]
--  Affiche temporairement un prop devant le joueur (test visuel)
-- ═══════════════════════════════════════════════════════════════

local testProp = nil

RegisterCommand("showprop", function(source, args)
    local model = args[1] or "prop_boxpile_07d"
    
    -- Supprime l'ancien prop de test si existant
    if testProp and DoesEntityExist(testProp) then
        DeleteEntity(testProp)
    end
    
    -- Charge le modèle
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)
    
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(modelHash) and GetGameTimer() < timeout do
        Wait(10)
    end
    
    if not HasModelLoaded(modelHash) then
        print(string.format("^1[ERREUR]^0 Le modèle ^3%s^0 n'existe pas ou n'a pas pu être chargé", model))
        return
    end
    
    -- Spawn le prop devant le joueur
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local forward = GetEntityForwardVector(ped)
    
    local spawnCoords = vector3(
        coords.x + forward.x * 2.0,
        coords.y + forward.y * 2.0,
        coords.z
    )
    
    testProp = CreateObject(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false)
    SetEntityHeading(testProp, heading)
    PlaceObjectOnGroundProperly(testProp)
    
    print(string.format("^2[TEST PROP]^0 Prop ^3%s^0 affiché devant vous", model))
    print("^3Utilisez /delprop pour le supprimer^0")
    
    SetModelAsNoLongerNeeded(modelHash)
end, false)

TriggerEvent('chat:addSuggestion', '/showprop', 'Affiche temporairement un prop devant vous pour test', {
    { name = "model", help = "Nom du modèle (ex: prop_boxpile_07d)" }
})

-- ═══════════════════════════════════════════════════════════════
--  COMMANDE: /delprop
--  Supprime le prop de test
-- ═══════════════════════════════════════════════════════════════

RegisterCommand("delprop", function()
    if testProp and DoesEntityExist(testProp) then
        DeleteEntity(testProp)
        testProp = nil
        print("^3[TEST PROP]^0 Prop de test supprimé")
    else
        print("^1[ERREUR]^0 Aucun prop de test à supprimer")
    end
end, false)

TriggerEvent('chat:addSuggestion', '/delprop', 'Supprime le prop de test')

-- ═══════════════════════════════════════════════════════════════
--  AFFICHAGE AU DÉMARRAGE
-- ═══════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(2000)
    print("^2═══════════════════════════════════════════════════════^0")
    print("^3[UTILITAIRE COORDONNÉES]^0 Script de développement activé")
    print("^2═══════════════════════════════════════════════════════^0")
    print("")
    print("^5Commandes disponibles:^0")
    print("  ^3/getcoords^0       - Affiche vos coordonnées actuelles")
    print("  ^3/savecoords [nom]^0 - Sauvegarde une position avec un nom")
    print("  ^3/listcoords^0      - Liste toutes les positions sauvegardées")
    print("  ^3/clearcoords^0     - Efface les positions sauvegardées")
    print("  ^3/showprop [model]^0 - Test visuel d'un prop")
    print("  ^3/delprop^0         - Supprime le prop de test")
    print("")
    print("^1⚠️  ATTENTION: Désactivez ce script en production!^0")
    print("^2═══════════════════════════════════════════════════════^0")
end)

--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                      NOTES IMPORTANTES                        ║
    ╠═══════════════════════════════════════════════════════════════╣
    ║                                                               ║
    ║  Ce fichier est un OUTIL DE DÉVELOPPEMENT uniquement         ║
    ║                                                               ║
    ║  À FAIRE AVANT MISE EN PRODUCTION:                            ║
    ║  1. Commentez la ligne dans fxmanifest.lua                    ║
    ║  2. Ou supprimez complètement ce fichier                      ║
    ║                                                               ║
    ║  Les commandes sont accessibles à tous les joueurs            ║
    ║  Ne les laissez PAS actives sur un serveur public !          ║
    ║                                                               ║
    ╚═══════════════════════════════════════════════════════════════╝
]]
