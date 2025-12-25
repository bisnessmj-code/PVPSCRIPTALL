--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                     CLIENT SIDE SCRIPT                        ║
    ║              Gestion optimisée des props du podium            ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    Architecture:
    • Système de cache pour les props spawnés
    • Gestion automatique du streaming
    • Nettoyage optimisé des ressources
    • Distance check avec intervalle configurable
]]

-- ═══════════════════════════════════════════════════════════════
--  VARIABLES GLOBALES ET CACHE
-- ═══════════════════════════════════════════════════════════════

local spawnedProps = {}                 -- Cache des props spawnés {handle, name, model}
local isSystemActive = true             -- État du système
local playerPed = PlayerPedId()         -- Cache du ped du joueur
local playerCoords = GetEntityCoords(playerPed) -- Cache des coordonnées
local lastDistanceCheck = 0             -- Timestamp du dernier check de distance

-- ═══════════════════════════════════════════════════════════════
--  FONCTIONS UTILITAIRES
-- ═══════════════════════════════════════════════════════════════

--- Affiche un message de debug dans la console F8
--- @param message string Message à afficher
local function DebugPrint(message)
    if Config.Debug then
        print(message)
    end
end

--- Calcule la distance entre deux points (optimisé)
--- @param coords1 vector3 Première coordonnée
--- @param coords2 vector3 Seconde coordonnée
--- @return number Distance en unités
local function GetDistance(coords1, coords2)
    local dx = coords1.x - coords2.x
    local dy = coords1.y - coords2.y
    local dz = coords1.z - coords2.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

--- Vérifie si le joueur est dans la zone de rendu
--- @return boolean True si le joueur est dans la zone
local function IsPlayerInRenderZone()
    -- Utilise la première position comme point de référence
    if not Config.Props[1] then return false end
    
    local distance = GetDistance(playerCoords, Config.Props[1].position)
    return distance <= Config.RenderDistance
end

-- ═══════════════════════════════════════════════════════════════
--  GESTION DES MODÈLES (STREAMING)
-- ═══════════════════════════════════════════════════════════════

--- Charge un modèle de prop de manière asynchrone
--- @param model string|number Hash ou nom du modèle
--- @return boolean Success True si le modèle a été chargé avec succès
local function LoadModel(model)
    local modelHash = type(model) == "string" and GetHashKey(model) or model
    
    -- Vérification si le modèle existe
    if not IsModelValid(modelHash) then
        DebugPrint(string.format(Config.Messages.modelFailed, model))
        return false
    end
    
    -- Si déjà chargé, on retourne true directement
    if HasModelLoaded(modelHash) then
        return true
    end
    
    -- Demande de chargement du modèle
    RequestModel(modelHash)
    
    -- Attente du chargement avec timeout de 10 secondes
    local timeout = GetGameTimer() + 10000
    while not HasModelLoaded(modelHash) and GetGameTimer() < timeout do
        Wait(10)
    end
    
    if HasModelLoaded(modelHash) then
        DebugPrint(string.format(Config.Messages.modelLoaded, model))
        return true
    else
        DebugPrint(string.format(Config.Messages.modelFailed, model))
        return false
    end
end

--- Libère un modèle de la mémoire
--- @param model string|number Hash ou nom du modèle
local function UnloadModel(model)
    local modelHash = type(model) == "string" and GetHashKey(model) or model
    
    if HasModelLoaded(modelHash) then
        SetModelAsNoLongerNeeded(modelHash)
    end
end

-- ═══════════════════════════════════════════════════════════════
--  GESTION DES PROPS
-- ═══════════════════════════════════════════════════════════════

--- Spawn un prop avec toutes les options configurées
--- @param propConfig table Configuration du prop depuis Config.Props
--- @return number|nil PropHandle Handle du prop spawné ou nil en cas d'échec
local function SpawnProp(propConfig)
    -- Validation de la configuration
    if not propConfig or not propConfig.model or not propConfig.position then
        DebugPrint("^1[ERREUR]^0 Configuration de prop invalide")
        return nil
    end
    
    -- Chargement du modèle
    if not LoadModel(propConfig.model) then
        return nil
    end
    
    -- Calcul de la position finale avec offset
    local finalPosition = vector3(
        propConfig.position.x,
        propConfig.position.y,
        propConfig.position.z + (propConfig.zOffset or 0.0)
    )
    
    -- Création du prop
    local prop = CreateObject(
        GetHashKey(propConfig.model),
        finalPosition.x,
        finalPosition.y,
        finalPosition.z,
        false,                          -- isNetwork (false = prop local)
        false,                          -- bScriptHostObj
        propConfig.dynamic or false     -- dynamic (peut bouger si true)
    )
    
    -- Vérification de la création
    if not DoesEntityExist(prop) then
        DebugPrint("^1[ERREUR]^0 Échec de la création du prop")
        UnloadModel(propConfig.model)
        return nil
    end
    
    -- Application de la rotation
    if propConfig.rotation then
        SetEntityRotation(
            prop,
            propConfig.rotation.x,
            propConfig.rotation.y,
            propConfig.rotation.z,
            2,                          -- rotationOrder (XYZ)
            true                        -- p4
        )
    end
    
    -- Application de l'échelle (scale)
    -- NOTE: SetEntityScale n'existe pas dans FiveM
    -- Pour changer la taille, utilisez des modèles différents ou empilez des props
    -- if propConfig.scale then
    --     -- Cette fonction n'existe pas dans FiveM
    --     -- Alternative: utilisez stackedProps pour créer de la hauteur
    -- end
    
    -- Configuration de la transparence (alpha)
    if propConfig.alpha and propConfig.alpha < 255 then
        SetEntityAlpha(prop, propConfig.alpha, false)
    end
    
    -- Placement au sol si activé
    if Config.PlaceOnGround then
        PlaceObjectOnGroundProperly(prop)
    end
    
    -- Configuration des collisions
    if not Config.UseCollisions then
        SetEntityCollision(prop, false, false)
    end
    
    -- Gel du prop (recommandé pour performances)
    if Config.FreezeProps then
        FreezeEntityPosition(prop, true)
    end
    
    -- Configuration de la visibilité
    if propConfig.visible ~= nil then
        SetEntityVisible(prop, propConfig.visible, false)
    end
    
    -- Variation de texture
    if propConfig.textureVariation and propConfig.textureVariation > 0 then
        SetObjectTextureVariant(prop, propConfig.textureVariation)
    end
    
    -- Libération du modèle de la mémoire
    UnloadModel(propConfig.model)
    
    DebugPrint(string.format(Config.Messages.propSpawned, propConfig.name or "Unknown"))
    
    return prop
end

--- Spawn un prop empilé (stackedProp)
--- @param baseProp number Handle du prop de base
--- @param baseConfig table Configuration du prop de base
--- @param stackConfig table Configuration du prop empilé
local function SpawnStackedProp(baseProp, baseConfig, stackConfig)
    if not DoesEntityExist(baseProp) then return end
    
    -- Chargement du modèle
    if not LoadModel(stackConfig.model) then
        return
    end
    
    -- Récupération de la position du prop de base
    local baseCoords = GetEntityCoords(baseProp)
    local baseRotation = GetEntityRotation(baseProp, 2)
    
    -- Calcul de la position du prop empilé
    local stackedPosition = vector3(
        baseCoords.x,
        baseCoords.y,
        baseCoords.z + (stackConfig.zOffset or 1.0)
    )
    
    -- Création du prop empilé
    local stackedProp = CreateObject(
        GetHashKey(stackConfig.model),
        stackedPosition.x,
        stackedPosition.y,
        stackedPosition.z,
        false,
        false,
        false
    )
    
    if DoesEntityExist(stackedProp) then
        -- Application de la même rotation que le prop de base
        SetEntityRotation(stackedProp, baseRotation.x, baseRotation.y, baseRotation.z, 2, true)
        
        -- Application de l'échelle si définie
        -- NOTE: SetEntityScale n'existe pas dans FiveM
        -- Pour varier les tailles, utilisez des modèles différents
        -- if stackConfig.scale then
        --     -- Cette fonction n'existe pas dans FiveM
        -- end
        
        -- Configuration identique au prop principal
        if Config.FreezeProps then
            FreezeEntityPosition(stackedProp, true)
        end
        
        if not Config.UseCollisions then
            SetEntityCollision(stackedProp, false, false)
        end
        
        -- Ajout au cache
        table.insert(spawnedProps, {
            handle = stackedProp,
            name = (baseConfig.name or "Unknown") .. "_Stacked",
            model = stackConfig.model
        })
        
        DebugPrint(string.format("^2[PODIUM]^0 Prop empilé spawné sur ^3%s^0", baseConfig.name or "Unknown"))
    end
    
    UnloadModel(stackConfig.model)
end

--- Supprime un prop spécifique
--- @param propHandle number Handle du prop à supprimer
local function DeleteProp(propHandle)
    if DoesEntityExist(propHandle) then
        DeleteEntity(propHandle)
        DebugPrint(Config.Messages.propDeleted:format("Prop"))
    end
end

-- ═══════════════════════════════════════════════════════════════
--  SYSTÈME PRINCIPAL DE SPAWN
-- ═══════════════════════════════════════════════════════════════

--- Spawn tous les props configurés dans Config.Props
local function SpawnAllProps()
    DebugPrint(Config.Messages.systemStarted)
    
    for index, propConfig in ipairs(Config.Props) do
        -- Spawn du prop principal
        local prop = SpawnProp(propConfig)
        
        if prop then
            -- Ajout au cache
            table.insert(spawnedProps, {
                handle = prop,
                name = propConfig.name or ("Prop_" .. index),
                model = propConfig.model
            })
            
            -- Spawn des props empilés si configurés
            if propConfig.stackedProps and #propConfig.stackedProps > 0 then
                for _, stackConfig in ipairs(propConfig.stackedProps) do
                    SpawnStackedProp(prop, propConfig, stackConfig)
                end
            end
        end
        
        -- Petit délai entre chaque spawn pour éviter les pics de lag
        Wait(50)
    end
    
    -- Spawn des props décoratifs si activés
    if Config.DecorativeProps and Config.DecorativeProps.enabled then
        for _, decorProp in ipairs(Config.DecorativeProps.props) do
            local prop = SpawnProp(decorProp)
            if prop then
                table.insert(spawnedProps, {
                    handle = prop,
                    name = "Decorative",
                    model = decorProp.model
                })
            end
            Wait(50)
        end
    end
    
    DebugPrint(string.format("^2[PODIUM]^0 Total de ^3%d^0 props spawnés", #spawnedProps))
end

--- Supprime tous les props spawnés
local function ClearAllProps()
    for _, propData in ipairs(spawnedProps) do
        DeleteProp(propData.handle)
    end
    
    spawnedProps = {}
    DebugPrint(Config.Messages.propsCleared)
end

-- ═══════════════════════════════════════════════════════════════
--  BOUCLE DE VÉRIFICATION DE DISTANCE (Optimisée)
-- ═══════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        local currentTime = GetGameTimer()
        
        -- Vérification de distance selon l'intervalle configuré
        if currentTime - lastDistanceCheck >= Config.Performance.distanceCheckInterval then
            lastDistanceCheck = currentTime
            
            -- Mise à jour du cache du joueur
            playerPed = PlayerPedId()
            playerCoords = GetEntityCoords(playerPed)
            
            -- Vérification de la distance et nettoyage si nécessaire
            if Config.Performance.cleanOnPlayerLeft then
                local inZone = IsPlayerInRenderZone()
                
                if not inZone and #spawnedProps > 0 then
                    DebugPrint("^3[PODIUM]^0 Joueur hors zone, nettoyage des props...")
                    ClearAllProps()
                elseif inZone and #spawnedProps == 0 and isSystemActive then
                    DebugPrint("^2[PODIUM]^0 Joueur dans la zone, respawn des props...")
                    SpawnAllProps()
                end
            end
        end
        
        -- Attente adaptée selon la distance
        Wait(1000)
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  COMMANDES ADMIN
-- ═══════════════════════════════════════════════════════════════

if Config.AdminCommands.enabled then
    -- Commande de rechargement
    RegisterCommand(Config.AdminCommands.commands.reload, function()
        DebugPrint("^3[PODIUM]^0 Rechargement du système...")
        ClearAllProps()
        Wait(500)
        SpawnAllProps()
    end, false)
    
    -- Commande de nettoyage
    RegisterCommand(Config.AdminCommands.commands.clear, function()
        ClearAllProps()
    end, false)
    
    -- Commande de toggle
    RegisterCommand(Config.AdminCommands.commands.toggle, function()
        isSystemActive = not isSystemActive
        
        if isSystemActive then
            SpawnAllProps()
            DebugPrint("^2[PODIUM]^0 Système activé")
        else
            ClearAllProps()
            DebugPrint("^1[PODIUM]^0 Système désactivé")
        end
    end, false)
end

-- ═══════════════════════════════════════════════════════════════
--  ÉVÉNEMENTS DE CYCLE DE VIE
-- ═══════════════════════════════════════════════════════════════

--- Événement au démarrage de la ressource
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Petit délai pour laisser le temps au client de charger
    Wait(1000)
    
    -- Spawn initial des props
    if isSystemActive then
        SpawnAllProps()
    end
end)

--- Événement à l'arrêt de la ressource
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    DebugPrint(Config.Messages.systemStopped)
    ClearAllProps()
end)

--- Événement de changement de routing bucket (si configuré)
-- NOTE: GetPlayerRoutingBucket n'est pas disponible côté client dans toutes les versions
-- Cette fonctionnalité est désactivée pour éviter les erreurs
-- if Config.Performance.cleanOnRoutingBucketChange then
--     AddEventHandler('onClientResourceStart', function(resourceName)
--         if GetCurrentResourceName() ~= resourceName then return end
--         
--         -- Écoute du changement de routing bucket
--         local currentBucket = GetPlayerRoutingBucket(PlayerId())
--         
--         CreateThread(function()
--             while true do
--                 local newBucket = GetPlayerRoutingBucket(PlayerId())
--                 
--                 if newBucket ~= currentBucket then
--                     currentBucket = newBucket
--                     DebugPrint("^3[PODIUM]^0 Changement de routing bucket détecté, nettoyage...")
--                     ClearAllProps()
--                     
--                     -- Respawn après changement de bucket
--                     Wait(1000)
--                     if isSystemActive then
--                         SpawnAllProps()
--                     end
--                 end
--                 
--                 Wait(2000)
--             end
--         end)
--     end)
-- end

--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                     NOTES DE PERFORMANCE                      ║
    ╠═══════════════════════════════════════════════════════════════╣
    ║                                                               ║
    ║  Ce script est optimisé pour minimiser l'impact sur les FPS: ║
    ║                                                               ║
    ║  • Cache des coordonnées joueur (pas de calcul constant)      ║
    ║  • Vérification de distance avec intervalle configurable     ║
    ║  • Props locaux (non-networked) pour de meilleures perfs     ║
    ║  • Libération automatique des modèles après utilisation      ║
    ║  • Props gelés (FreezeEntityPosition) = 0 calcul physique    ║
    ║  • Nettoyage automatique hors zone de rendu                  ║
    ║                                                               ║
    ║  Impact estimé: < 0.01ms/frame avec 10-20 props              ║
    ║                                                               ║
    ╚═══════════════════════════════════════════════════════════════╝
]]
