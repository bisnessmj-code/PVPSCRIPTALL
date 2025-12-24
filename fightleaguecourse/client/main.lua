--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║          FIGHTLEAGUE COURSE - CLIENT PRINCIPAL                ║
    ║              Ultra-Optimisé - Performance First               ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    OBJECTIF PERFORMANCE :
    - Idle : 0.00-0.05 ms
    - Actif (près du PED) : 0.1-0.3 ms
    - En recherche : 0.05-0.15 ms
    
    ARCHITECTURE :
    - Thread principal : Vérifie la distance toutes les 1000ms
    - Thread marker : Actif seulement si proche du PED
    - Events : Utilisés pour le matchmaking (pas de polling)
]]

-- ═════════════════════════════════════════════════════════════════
-- VARIABLES LOCALES (Performance)
-- ═════════════════════════════════════════════════════════════════
local playerState = {
    ped = nil,                  -- Cache du PlayerPedId
    coords = nil,               -- Cache des coordonnées
    inQueue = false,            -- En file d'attente ?
    inGame = false,             -- En partie ?
    nearPed = false,            -- Proche du PED d'inscription ?
    canInteract = false,        -- Peut interagir ?
    
    -- Système de rounds
    currentRound = 0,           -- Round actuel
    role = nil,                 -- 'runner' ou 'chaser'
    captureProgress = 0,        -- Progression de capture (0-100)
}

local pedEntity = nil           -- Entité du PED d'inscription
local markerThread = nil        -- Référence du thread marker
local searchThread = nil        -- Référence du thread de recherche
local captureThread = nil       -- Référence du thread de capture
local lastInteraction = 0       -- Timestamp dernière interaction (cooldown)

-- ═════════════════════════════════════════════════════════════════
-- FONCTIONS UTILITAIRES
-- ═════════════════════════════════════════════════════════════════

--[[
    Met à jour le cache des données joueur
    APPELÉ : Toutes les 1000ms par le thread principal
    
    Impact CPU : ~0.02ms (2 natives seulement)
]]
local function UpdatePlayerCache()
    playerState.ped = PlayerPedId()
    playerState.coords = GetEntityCoords(playerState.ped)
end

--[[
    Vérifie la distance avec le PED d'inscription
    APPELÉ : Toutes les 1000ms par le thread principal
    
    Impact CPU : ~0.01ms (calcul distance simple)
    Retour : bool - true si dans la zone de draw
    
    NOTE : Utilise une zone de tolérance (hysteresis) pour éviter le clignotement
]]
local function CheckPedDistance()
    if not playerState.coords then return false end
    
    local distance = #(playerState.coords - Config.Ped.Coords.xyz)
    
    -- Zone de tolérance pour éviter le clignotement
    -- Si on était loin et qu'on s'approche : activation à DrawDistance
    -- Si on était proche et qu'on s'éloigne : désactivation à DrawDistance + ToleranceZone
    local activationDistance = Config.Ped.DrawDistance
    local deactivationDistance = Config.Ped.DrawDistance + Config.Ped.ToleranceZone
    
    -- Mise à jour du flag nearPed avec hysteresis
    if not playerState.nearPed then
        -- On était loin, on active si on entre dans la zone
        playerState.nearPed = distance <= activationDistance
    else
        -- On était proche, on désactive si on sort de la zone (+ tolérance)
        playerState.nearPed = distance <= deactivationDistance
    end
    
    -- Flag d'interaction (sans hysteresis car distance courte)
    playerState.canInteract = distance <= Config.Ped.InteractDistance
    
    return playerState.nearPed
end

-- ═════════════════════════════════════════════════════════════════
-- SPAWN DU PED D'INSCRIPTION
-- ═════════════════════════════════════════════════════════════════

--[[
    Créé le PED d'inscription
    APPELÉ : Une seule fois au démarrage
    
    Impact CPU : Ponctuel (création unique)
]]
local function CreateRegistrationPed()
    Utils.Log('Client', 'Création du PED d\'inscription...', 'info')
    
    -- Charger le modèle
    local model = GetHashKey(Config.Ped.Model)
    RequestModel(model)
    
    while not HasModelLoaded(model) do
        Wait(100)
    end
    
    -- Créer le PED
    local coords = Config.Ped.Coords
    pedEntity = CreatePed(4, model, coords.x, coords.y, coords.z, coords.w, false, true)
    
    -- Configuration du PED
    SetEntityInvincible(pedEntity, true)
    SetBlockingOfNonTemporaryEvents(pedEntity, true)
    FreezeEntityPosition(pedEntity, true)
    
    -- Libérer le modèle
    SetModelAsNoLongerNeeded(model)
    
    Utils.Log('Client', 'PED d\'inscription créé avec succès', 'info')
end

-- ═════════════════════════════════════════════════════════════════
-- THREAD PRINCIPAL - VÉRIFICATION DE DISTANCE
-- ═════════════════════════════════════════════════════════════════

--[[
    Thread principal de détection de proximité
    
    FRÉQUENCE : 1000ms (1 seconde)
    Impact CPU : ~0.02-0.03ms toutes les secondes
    
    LOGIQUE :
    1. Met à jour le cache des données joueur
    2. Vérifie la distance avec le PED
    3. Active/désactive le thread marker selon la distance
]]
CreateThread(function()
    Utils.Log('Client', 'Thread principal démarré', 'info')
    
    while true do
        Wait(Config.Timings.PedCheckInterval) -- 1000ms par défaut
        
        -- Mise à jour du cache
        UpdatePlayerCache()
        
        -- Si en partie, on skip la vérification du PED
        if playerState.inGame then
            -- Le marker sera désactivé par playerState.nearPed = false
            goto continue
        end
        
        -- Vérifier la distance (met à jour playerState.nearPed avec hysteresis)
        CheckPedDistance()
        
        -- Activer le thread marker si nécessaire
        -- Important : on vérifie que markerThread est bien nil (pas juste falsy)
        if playerState.nearPed and markerThread == nil then
            Utils.Log('Client', 'Activation du thread marker', 'info')
            markerThread = CreateThread(MarkerThread)
        end
        
        ::continue::
    end
end)

-- ═════════════════════════════════════════════════════════════════
-- THREAD MARKER - AFFICHAGE CONDITIONNEL
-- ═════════════════════════════════════════════════════════════════

--[[
    Thread d'affichage du marker
    
    FRÉQUENCE : Actif seulement si joueur proche (< 50m)
    Wait : 100ms quand actif (pour fluidité visuelle)
    Impact CPU : ~0.1-0.2ms seulement quand proche
    
    AUTO-DÉSACTIVATION : Se stoppe automatiquement si joueur s'éloigne
]]
function MarkerThread()
    Utils.Log('Client', 'Thread marker démarré', 'info')
    
    -- Boucle tant que le joueur est proche ET pas en partie
    while playerState.nearPed and not playerState.inGame do
        Wait(Config.Timings.MarkerUpdateRate) -- 100ms par défaut
        
        -- Double vérification de sécurité
        if not playerState.nearPed or playerState.inGame then
            break
        end
        
        -- Dessiner le marker
        local marker = Config.Ped.Marker
        local coords = Config.Ped.Coords
        
        DrawMarker(
            marker.Type,
            coords.x, coords.y, coords.z - 1.0,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            marker.Size.x, marker.Size.y, marker.Size.z,
            marker.Color.r, marker.Color.g, marker.Color.b, marker.Color.a,
            marker.BobUpDown,
            false,
            2,
            marker.Rotate,
            nil,
            nil,
            false
        )
        
        -- Afficher le texte d'aide si très proche
        if playerState.canInteract and not playerState.inQueue then
            Utils.ShowHelpText(Config.Ped.HelpText)
            
            -- Détection de la touche E avec cooldown (éviter spam)
            local currentTime = GetGameTimer()
            if IsControlJustPressed(0, 38) and (currentTime - lastInteraction) > 500 then -- E
                lastInteraction = currentTime
                TriggerServerEvent('fightleague:joinQueue')
            end
        elseif playerState.canInteract and playerState.inQueue then
            Utils.ShowHelpText("Recherche en cours... Appuyez sur ~INPUT_CONTEXT~ pour annuler")
            
            -- Annuler la recherche avec cooldown
            local currentTime = GetGameTimer()
            if IsControlJustPressed(0, 38) and (currentTime - lastInteraction) > 500 then -- E
                lastInteraction = currentTime
                TriggerServerEvent('fightleague:leaveQueue')
            end
        end
    end
    
    -- Thread terminé, reset du flag
    Utils.Log('Client', 'Thread marker arrêté', 'info')
    markerThread = nil -- Important : reset à nil pour permettre réactivation
end

-- ═════════════════════════════════════════════════════════════════
-- THREAD DE RECHERCHE - UI
-- ═════════════════════════════════════════════════════════════════

--[[
    Thread d'affichage de l'interface de recherche
    
    FRÉQUENCE : Actif seulement si en recherche
    Wait : 500ms (pas besoin de rafraîchir souvent)
    Impact CPU : ~0.05-0.1ms seulement quand en recherche
    
    AUTO-DÉSACTIVATION : Se stoppe quand partie trouvée ou annulation
]]
local function StartSearchUI()
    if searchThread then return end
    
    searchThread = CreateThread(function()
        Utils.Log('Client', 'UI de recherche activée', 'info')
        
        local dots = 0
        local maxDots = 3
        
        while playerState.inQueue do
            Wait(500) -- Pas besoin de rafraîchir rapidement
            
            -- Animation des points
            dots = (dots + 1) % (maxDots + 1)
            local dotString = string.rep('.', dots)
            
            -- Affichage simple (remplacer par votre UI custom si besoin)
            SetTextFont(4)
            SetTextProportional(1)
            SetTextScale(0.5, 0.5)
            SetTextColour(255, 255, 255, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry('STRING')
            AddTextComponentString('Recherche d\'adversaire' .. dotString)
            DrawText(0.5, 0.9)
        end
        
        Utils.Log('Client', 'UI de recherche désactivée', 'info')
        searchThread = nil
    end)
end

-- ═════════════════════════════════════════════════════════════════
-- THREAD DE CAPTURE - POURSUIVEUR
-- ═════════════════════════════════════════════════════════════════

--[[
    Thread de vérification de capture
    
    FRÉQUENCE : Actif seulement si joueur est poursuiveur
    Wait : 100ms (besoin de réactivité pour la capture)
    Impact CPU : ~0.1-0.2ms seulement quand poursuiveur
    
    AUTO-DÉSACTIVATION : Se stoppe à la fin du round
]]
function CaptureThread()
    Utils.Log('Client', 'Thread de capture activé', 'info')
    
    local isCaptureUIShown = false
    
    while playerState.role == 'chaser' do
        Wait(Config.Rounds.CaptureCheckInterval) -- 100ms par défaut
        
        -- Vérifications de sécurité
        if playerState.role ~= 'chaser' then break end
        if not playerState.inGame then break end
        
        local ped = PlayerPedId()
        local myVehicle = GetVehiclePedIsIn(ped, false)
        
        if myVehicle == 0 then goto continue end
        
        -- Trouver le véhicule du fuyard (l'autre véhicule proche)
        local myPos = GetEntityCoords(myVehicle)
        local closestVehicle = nil
        local closestDistance = 999999.0
        
        -- Scanner les véhicules proches
        local vehicles = GetGamePool('CVehicle')
        for _, veh in ipairs(vehicles) do
            if veh ~= myVehicle then
                local vehPos = GetEntityCoords(veh)
                local distance = #(myPos - vehPos)
                
                if distance < closestDistance then
                    closestDistance = distance
                    closestVehicle = veh
                end
            end
        end
        
        -- Vérifier si on est assez proche pour capturer
        if closestVehicle and closestDistance <= Config.Rounds.CaptureDistance then
            -- Vérifier si le fuyard est à l'arrêt
            local runnerSpeed = GetEntitySpeed(closestVehicle) * 3.6 -- Convertir en km/h
            
            if runnerSpeed <= Config.Rounds.CaptureSpeed then
                -- Afficher l'UI si pas encore visible
                if not isCaptureUIShown then
                    SendNUIMessage({ action = 'showCapture' })
                    isCaptureUIShown = true
                end
                
                -- Le fuyard est à l'arrêt et proche : progression de la capture
                local increment = (100 / Config.Rounds.CaptureTime) * (Config.Rounds.CaptureCheckInterval / 1000)
                playerState.captureProgress = math.min(100, playerState.captureProgress + increment)
                
                -- Mettre à jour l'UI
                SendNUIMessage({
                    action = 'updateCapture',
                    progress = playerState.captureProgress
                })
                
                -- Vérifier si capture complète
                if playerState.captureProgress >= 100 then
                    Utils.Log('Client', 'Capture complète !', 'info')
                    
                    -- Masquer l'UI
                    SendNUIMessage({ action = 'hideCapture' })
                    isCaptureUIShown = false
                    
                    -- Envoyer au serveur
                    TriggerServerEvent('fightleague:captureComplete')
                    playerState.captureProgress = 0
                    break
                end
            else
                -- Le fuyard bouge : réinitialiser la progression
                if playerState.captureProgress > 0 then
                    Utils.Log('Client', 'Capture annulée - cible en mouvement', 'info')
                end
                playerState.captureProgress = 0
                
                -- Masquer l'UI
                if isCaptureUIShown then
                    SendNUIMessage({ action = 'hideCapture' })
                    isCaptureUIShown = false
                end
            end
        else
            -- Trop loin : réinitialiser la progression
            if playerState.captureProgress > 0 then
                Utils.Log('Client', 'Capture annulée - trop loin', 'info')
            end
            playerState.captureProgress = 0
            
            -- Masquer l'UI
            if isCaptureUIShown then
                SendNUIMessage({ action = 'hideCapture' })
                isCaptureUIShown = false
            end
        end
        
        ::continue::
    end
    
    -- Masquer l'UI à la fin du thread
    if isCaptureUIShown then
        SendNUIMessage({ action = 'hideCapture' })
    end
    
    Utils.Log('Client', 'Thread de capture arrêté', 'info')
    captureThread = nil
end

-- ═════════════════════════════════════════════════════════════════
-- EVENTS RÉSEAU
-- ═════════════════════════════════════════════════════════════════

--[[
    Event : Confirmation d'entrée en file d'attente
    Impact CPU : Événementiel (pas de boucle)
]]
RegisterNetEvent('fightleague:queueJoined', function()
    playerState.inQueue = true
    Utils.Notify(Config.Lang.JoinedQueue, 'success')
    Utils.Log('Client', 'Joueur en file d\'attente', 'info')
    
    -- Démarrer l'UI de recherche
    StartSearchUI()
end)

--[[
    Event : Sortie de la file d'attente
    Impact CPU : Événementiel (pas de boucle)
]]
RegisterNetEvent('fightleague:queueLeft', function()
    playerState.inQueue = false
    Utils.Notify(Config.Lang.LeftQueue, 'info')
    Utils.Log('Client', 'Joueur sorti de la file d\'attente', 'info')
end)

--[[
    Event : Match trouvé
    Impact CPU : Événementiel (pas de boucle)
]]
RegisterNetEvent('fightleague:matchFound', function()
    playerState.inQueue = false
    Utils.Notify(Config.Lang.MatchFound, 'success')
    Utils.Log('Client', 'Match trouvé !', 'info')
end)

--[[
    Event : Téléportation dans le véhicule
    Impact CPU : Ponctuel (téléportation unique)
]]
RegisterNetEvent('fightleague:teleportToVehicle', function(vehicleNetId)
    playerState.inGame = true
    
    Utils.Log('Client', 'Téléportation vers le véhicule (NetID: ' .. vehicleNetId .. ')...', 'info')
    
    -- Attendre que le véhicule soit synchronisé avec le client
    local vehicle = nil
    local timeout = 0
    local maxTimeout = 100 -- 10 secondes max
    
    while timeout < maxTimeout do
        vehicle = NetToVeh(vehicleNetId)
        
        -- Vérifier que le véhicule existe ET est valide
        if vehicle ~= 0 and DoesEntityExist(vehicle) then
            -- Double vérification que c'est bien notre véhicule
            local netId = NetworkGetNetworkIdFromEntity(vehicle)
            if netId == vehicleNetId then
                Utils.Log('Client', 'Véhicule trouvé après ' .. (timeout * 100) .. 'ms', 'info')
                break
            end
        end
        
        Wait(100)
        timeout = timeout + 1
    end
    
    -- Vérification finale
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        Utils.Log('Client', 'Impossible de trouver le véhicule après ' .. (timeout * 100) .. 'ms', 'error')
        return
    end
    
    -- Attendre encore un peu pour être sûr que le véhicule est stable
    Wait(500)
    
    -- Mettre le joueur dans le véhicule
    local ped = PlayerPedId()
    
    -- S'assurer que le joueur n'est pas déjà dans un véhicule
    local currentVeh = GetVehiclePedIsIn(ped, false)
    if currentVeh ~= 0 and currentVeh ~= vehicle then
        TaskLeaveVehicle(ped, currentVeh, 0)
        Wait(500)
    end
    
    -- Téléporter dans le véhicule
    TaskWarpPedIntoVehicle(ped, vehicle, -1) -- -1 = siège conducteur
    
    -- Attendre que le joueur soit bien dans le véhicule
    Wait(500)
    
    -- Verrouiller le véhicule (empêcher de sortir)
    SetVehicleDoorsLocked(vehicle, 4) -- 4 = verrouillé
    
    Utils.Log('Client', 'Joueur téléporté dans le véhicule', 'info')
end)

--[[
    Event : Départ du round
    Impact CPU : Ponctuel (activation unique par round)
]]
RegisterNetEvent('fightleague:roundStart', function(data)
    playerState.currentRound = data.round
    playerState.role = data.role
    playerState.captureProgress = 0
    
    local roleText = (data.role == 'runner') and 'FUYEZ !' or 'CAPTUREZ !'
    Utils.Notify(string.format('Round %d/%d - %s', data.round, data.totalRounds, roleText), 'success')
    
    -- Déverrouiller le véhicule (permettre la conduite libre)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if DoesEntityExist(vehicle) then
        SetVehicleDoorsLocked(vehicle, 1) -- 1 = déverrouillé
    end
    
    -- Démarrer le thread de capture si on est le poursuiveur
    if data.role == 'chaser' then
        if captureThread then return end -- Thread déjà actif
        captureThread = CreateThread(CaptureThread)
    end
    
    Utils.Log('Client', string.format('Round %d démarré - Rôle: %s', data.round, data.role), 'info')
end)

--[[
    Event : Fin de round
    Impact CPU : Ponctuel
]]
RegisterNetEvent('fightleague:roundEnd', function(data)
    -- Masquer l'UI de capture si active
    SendNUIMessage({ action = 'hideCapture' })
    
    -- Afficher le résultat du round
    SendNUIMessage({
        action = 'showRoundResult',
        round = data.round,
        won = data.won,
        reason = data.reason,
        score = data.score
    })
    
    -- Reset de l'état
    playerState.role = nil
    playerState.captureProgress = 0
    
    local resultText = data.won and 'VICTOIRE !' or 'DÉFAITE'
    Utils.Log('Client', string.format('Round %d terminé - %s (Raison: %s)', 
        data.round, resultText, data.reason), 'info')
end)

--[[
    Event : Fin de partie complète
    Impact CPU : Ponctuel
]]
RegisterNetEvent('fightleague:gameEnd', function(data)
    playerState.inGame = false
    playerState.inQueue = false
    playerState.currentRound = 0
    playerState.role = nil
    
    -- Masquer toutes les UIs actives
    SendNUIMessage({ action = 'hideCapture' })
    SendNUIMessage({ action = 'hideRoundResult' })
    
    -- Afficher l'écran de fin de partie
    SendNUIMessage({
        action = 'showGameEnd',
        won = data.won,
        winner = data.winner,
        finalScore = data.finalScore,
        finalScoreText = data.finalScoreText
    })
    
    local resultText
    if data.winner == 'draw' then
        resultText = 'ÉGALITÉ !'
    else
        resultText = data.won and 'VOUS AVEZ GAGNÉ !' or 'VOUS AVEZ PERDU'
    end
    
    Utils.Log('Client', 'Partie terminée - ' .. resultText, 'info')
end)

--[[
    Event : Téléportation au point final
    Impact CPU : Ponctuel
]]
RegisterNetEvent('fightleague:teleportToEnd', function(coords)
    local ped = PlayerPedId()
    
    -- Sortir du véhicule si encore dedans
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle ~= 0 then
        TaskLeaveVehicle(ped, vehicle, 0)
        Wait(1000)
    end
    
    -- Téléporter au point final
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, coords.w)
    
    Utils.Notify('Partie terminée ! Merci d\'avoir joué.', 'info')
    Utils.Log('Client', 'Téléporté au point final', 'info')
end)

--[[
    Event : Fin de partie / Éjection
    Impact CPU : Ponctuel (nettoyage unique)
]]
RegisterNetEvent('fightleague:endGame', function()
    playerState.inGame = false
    playerState.inQueue = false
    
    Utils.Notify(Config.Lang.KickedFromGame, 'info')
    Utils.Log('Client', 'Partie terminée', 'info')
end)

-- ═════════════════════════════════════════════════════════════════
-- INITIALISATION
-- ═════════════════════════════════════════════════════════════════

CreateThread(function()
    -- Attendre que le joueur soit spawn
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(100)
    end
    
    Utils.Log('Client', 'Initialisation du script...', 'info')
    
    -- Créer le PED d'inscription
    CreateRegistrationPed()
    
    Utils.Log('Client', 'Script initialisé avec succès', 'info')
end)

-- ═════════════════════════════════════════════════════════════════
-- NETTOYAGE À LA DÉCONNEXION
-- ═════════════════════════════════════════════════════════════════

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    Utils.Log('Client', 'Arrêt du script - Nettoyage...', 'warn')
    
    -- Supprimer le PED
    if DoesEntityExist(pedEntity) then
        DeleteEntity(pedEntity)
    end
end)