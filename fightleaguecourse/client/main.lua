--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║          FIGHTLEAGUE COURSE - CLIENT PRINCIPAL                ║
    ║              Ultra-Optimisé - Performance First               ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    CORRECTIFS APPLIQUÉS :
    - Synchronisation véhicule améliorée avec timeout intelligent
    - Hystérésis renforcée pour le marker
    - Arrêt propre de la boucle de téléportation
]]

-- ═════════════════════════════════════════════════════════════════
-- VARIABLES LOCALES (Performance)
-- ═════════════════════════════════════════════════════════════════
local playerState = {
    ped = nil,
    coords = nil,
    inQueue = false,
    inGame = false,
    nearPed = false,
    canInteract = false,
    currentRound = 0,
    role = nil,
    captureProgress = 0,
    isTeleporting = false,  -- FLAG pour éviter boucle infinie
}

local pedEntity = nil
local markerThread = nil
local searchThread = nil
local captureThread = nil
local lastInteraction = 0

-- ═════════════════════════════════════════════════════════════════
-- FONCTIONS UTILITAIRES
-- ═════════════════════════════════════════════════════════════════

local function UpdatePlayerCache()
    playerState.ped = PlayerPedId()
    playerState.coords = GetEntityCoords(playerState.ped)
end

--[[
    CORRECTIF : Hystérésis renforcée avec debouncing
]]
local lastDistanceCheck = 0
local function CheckPedDistance()
    if not playerState.coords then return false end
    
    -- Debouncing : ne vérifie que toutes les 500ms pour éviter clignotement
    local currentTime = GetGameTimer()
    if currentTime - lastDistanceCheck < 500 then
        return playerState.nearPed -- Retourne l'état précédent
    end
    lastDistanceCheck = currentTime
    
    local distance = #(playerState.coords - Config.Ped.Coords.xyz)
    
    -- Hystérésis avec zone de tolérance agrandie
    local activationDistance = Config.Ped.DrawDistance
    local deactivationDistance = Config.Ped.DrawDistance + Config.Ped.ToleranceZone
    
    if not playerState.nearPed then
        playerState.nearPed = distance <= activationDistance
    else
        playerState.nearPed = distance <= deactivationDistance
    end
    
    -- Interaction (zone très proche, pas d'hystérésis)
    playerState.canInteract = distance <= Config.Ped.InteractDistance
    
    return playerState.nearPed
end

-- ═════════════════════════════════════════════════════════════════
-- SPAWN DU PED D'INSCRIPTION
-- ═════════════════════════════════════════════════════════════════

local function CreateRegistrationPed()
    Utils.Log('Client', 'Création du PED d\'inscription...', 'info')
    
    local model = GetHashKey(Config.Ped.Model)
    RequestModel(model)
    
    while not HasModelLoaded(model) do
        Wait(100)
    end
    
    local coords = Config.Ped.Coords
    pedEntity = CreatePed(4, model, coords.x, coords.y, coords.z, coords.w, false, true)
    
    SetEntityInvincible(pedEntity, true)
    SetBlockingOfNonTemporaryEvents(pedEntity, true)
    FreezeEntityPosition(pedEntity, true)
    
    SetModelAsNoLongerNeeded(model)
    
    Utils.Log('Client', 'PED d\'inscription créé avec succès', 'info')
end

-- ═════════════════════════════════════════════════════════════════
-- THREAD PRINCIPAL - VÉRIFICATION DE DISTANCE
-- ═════════════════════════════════════════════════════════════════

CreateThread(function()
    Utils.Log('Client', 'Thread principal démarré', 'info')
    
    while true do
        Wait(Config.Timings.PedCheckInterval)
        
        UpdatePlayerCache()
        
        if playerState.inGame then
            goto continue
        end
        
        CheckPedDistance()
        
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

function MarkerThread()
    Utils.Log('Client', 'Thread marker démarré', 'info')
    
    while playerState.nearPed and not playerState.inGame do
        Wait(Config.Timings.MarkerUpdateRate)
        
        if not playerState.nearPed or playerState.inGame then
            break
        end
        
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
        
        -- CORRECTIF : Affichage du texte avec debouncing
        if playerState.canInteract and not playerState.inQueue then
            Utils.ShowHelpText(Config.Ped.HelpText)
            
            local currentTime = GetGameTimer()
            if IsControlJustPressed(0, 38) and (currentTime - lastInteraction) > 500 then
                lastInteraction = currentTime
                TriggerServerEvent('fightleague:joinQueue')
            end
        elseif playerState.canInteract and playerState.inQueue then
            Utils.ShowHelpText("Recherche en cours... Appuyez sur ~INPUT_CONTEXT~ pour annuler")
            
            local currentTime = GetGameTimer()
            if IsControlJustPressed(0, 38) and (currentTime - lastInteraction) > 500 then
                lastInteraction = currentTime
                TriggerServerEvent('fightleague:leaveQueue')
            end
        end
    end
    
    Utils.Log('Client', 'Thread marker arrêté', 'info')
    markerThread = nil
end

-- ═════════════════════════════════════════════════════════════════
-- THREAD DE RECHERCHE - UI
-- ═════════════════════════════════════════════════════════════════

local function StartSearchUI()
    if searchThread then return end
    
    searchThread = CreateThread(function()
        Utils.Log('Client', 'UI de recherche activée', 'info')
        
        local dots = 0
        local maxDots = 3
        
        while playerState.inQueue do
            Wait(500)
            
            dots = (dots + 1) % (maxDots + 1)
            local dotString = string.rep('.', dots)
            
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

function CaptureThread()
    Utils.Log('Client', 'Thread de capture activé', 'info')
    
    local isCaptureUIShown = false
    
    while playerState.role == 'chaser' do
        Wait(Config.Rounds.CaptureCheckInterval)
        
        if playerState.role ~= 'chaser' then break end
        if not playerState.inGame then break end
        
        local ped = PlayerPedId()
        local myVehicle = GetVehiclePedIsIn(ped, false)
        
        if myVehicle == 0 then goto continue end
        
        local myPos = GetEntityCoords(myVehicle)
        local closestVehicle = nil
        local closestDistance = 999999.0
        
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
        
        if closestVehicle and closestDistance <= Config.Rounds.CaptureDistance then
            local runnerSpeed = GetEntitySpeed(closestVehicle) * 3.6
            
            if runnerSpeed <= Config.Rounds.CaptureSpeed then
                if not isCaptureUIShown then
                    SendNUIMessage({ action = 'showCapture' })
                    isCaptureUIShown = true
                end
                
                local increment = (100 / Config.Rounds.CaptureTime) * (Config.Rounds.CaptureCheckInterval / 1000)
                playerState.captureProgress = math.min(100, playerState.captureProgress + increment)
                
                SendNUIMessage({
                    action = 'updateCapture',
                    progress = playerState.captureProgress
                })
                
                if playerState.captureProgress >= 100 then
                    Utils.Log('Client', 'Capture complète !', 'info')
                    
                    SendNUIMessage({ action = 'hideCapture' })
                    isCaptureUIShown = false
                    
                    TriggerServerEvent('fightleague:captureComplete')
                    playerState.captureProgress = 0
                    break
                end
            else
                if playerState.captureProgress > 0 then
                    Utils.Log('Client', 'Capture annulée - cible en mouvement', 'info')
                end
                playerState.captureProgress = 0
                
                if isCaptureUIShown then
                    SendNUIMessage({ action = 'hideCapture' })
                    isCaptureUIShown = false
                end
            end
        else
            if playerState.captureProgress > 0 then
                Utils.Log('Client', 'Capture annulée - trop loin', 'info')
            end
            playerState.captureProgress = 0
            
            if isCaptureUIShown then
                SendNUIMessage({ action = 'hideCapture' })
                isCaptureUIShown = false
            end
        end
        
        ::continue::
    end
    
    if isCaptureUIShown then
        SendNUIMessage({ action = 'hideCapture' })
    end
    
    Utils.Log('Client', 'Thread de capture arrêté', 'info')
    captureThread = nil
end

-- ═════════════════════════════════════════════════════════════════
-- EVENTS RÉSEAU
-- ═════════════════════════════════════════════════════════════════

RegisterNetEvent('fightleague:queueJoined', function()
    playerState.inQueue = true
    Utils.Notify(Config.Lang.JoinedQueue, 'success')
    Utils.Log('Client', 'Joueur en file d\'attente', 'info')
    
    StartSearchUI()
end)

RegisterNetEvent('fightleague:queueLeft', function()
    playerState.inQueue = false
    Utils.Notify(Config.Lang.LeftQueue, 'info')
    Utils.Log('Client', 'Joueur sorti de la file d\'attente', 'info')
end)

RegisterNetEvent('fightleague:matchFound', function()
    playerState.inQueue = false
    Utils.Notify(Config.Lang.MatchFound, 'success')
    Utils.Log('Client', 'Match trouvé !', 'info')
end)

--[[
    CORRECTIF MAJEUR : Synchronisation véhicule améliorée avec timeout intelligent
]]
RegisterNetEvent('fightleague:teleportToVehicle', function(vehicleNetId)
    -- CORRECTIF : Empêcher les téléportations multiples simultanées
    if playerState.isTeleporting then
        Utils.Log('Client', 'Téléportation déjà en cours, ignorée', 'warn')
        return
    end
    
    playerState.isTeleporting = true
    playerState.inGame = true
    
    Utils.Log('Client', 'Téléportation vers le véhicule (NetID: ' .. vehicleNetId .. ')...', 'info')
    
    -- CORRECTIF : Attente avec vérification réseau intelligente
    local vehicle = nil
    local attempts = 0
    local maxAttempts = 150 -- 15 secondes max (150 * 100ms)
    local waitTime = 100
    
    while attempts < maxAttempts and playerState.isTeleporting do
        -- CORRECTIF : Vérifier NetworkIsEntityANetworkObject avant NetToVeh
        if NetworkDoesNetworkIdExist(vehicleNetId) then
            vehicle = NetToVeh(vehicleNetId)
            
            if vehicle ~= 0 and DoesEntityExist(vehicle) then
                -- DOUBLE VÉRIFICATION : Le véhicule est-il vraiment synchronisé ?
                if NetworkGetEntityIsNetworked(vehicle) then
                    local netId = NetworkGetNetworkIdFromEntity(vehicle)
                    if netId == vehicleNetId then
                        Utils.Log('Client', 'Véhicule trouvé après ' .. (attempts * waitTime) .. 'ms', 'info')
                        break
                    end
                end
            end
        end
        
        Wait(waitTime)
        attempts = attempts + 1
        
        -- Log toutes les 2 secondes
        if attempts % 20 == 0 then
            Utils.Log('Client', 'Attente véhicule... (' .. (attempts * waitTime) .. 'ms écoulées)', 'warn')
        end
    end
    
    -- CORRECTIF : Vérification finale robuste
    if not playerState.isTeleporting then
        Utils.Log('Client', 'Téléportation annulée (round terminé)', 'warn')
        return
    end
    
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        Utils.Log('Client', 'ERREUR: Impossible de trouver le véhicule après ' .. (attempts * waitTime) .. 'ms', 'error')
        playerState.isTeleporting = false
        return
    end
    
    -- Attendre stabilisation réseau
    Wait(500)
    
    -- Téléportation
    local ped = PlayerPedId()
    
    local currentVeh = GetVehiclePedIsIn(ped, false)
    if currentVeh ~= 0 and currentVeh ~= vehicle then
        TaskLeaveVehicle(ped, currentVeh, 0)
        Wait(500)
    end
    
    TaskWarpPedIntoVehicle(ped, vehicle, -1)
    
    Wait(500)
    
    SetVehicleDoorsLocked(vehicle, 4)
    
    Utils.Log('Client', 'Joueur téléporté dans le véhicule', 'info')
    
    -- CORRECTIF : Reset du flag
    playerState.isTeleporting = false
end)

RegisterNetEvent('fightleague:roundStart', function(data)
    playerState.currentRound = data.round
    playerState.role = data.role
    playerState.captureProgress = 0
    
    local roleText = (data.role == 'runner') and 'FUYEZ !' or 'CAPTUREZ !'
    Utils.Notify(string.format('Round %d/%d - %s', data.round, data.totalRounds, roleText), 'success')
    
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if DoesEntityExist(vehicle) then
        SetVehicleDoorsLocked(vehicle, 1)
    end
    
    if data.role == 'chaser' then
        if captureThread then return end
        captureThread = CreateThread(CaptureThread)
    end
    
    Utils.Log('Client', string.format('Round %d démarré - Rôle: %s', data.round, data.role), 'info')
end)

RegisterNetEvent('fightleague:roundEnd', function(data)
    -- CORRECTIF : Arrêter immédiatement la téléportation si en cours
    playerState.isTeleporting = false
    
    SendNUIMessage({ action = 'hideCapture' })
    
    SendNUIMessage({
        action = 'showRoundResult',
        round = data.round,
        won = data.won,
        reason = data.reason,
        score = data.score
    })
    
    playerState.role = nil
    playerState.captureProgress = 0
    
    local resultText = data.won and 'VICTOIRE !' or 'DÉFAITE'
    Utils.Log('Client', string.format('Round %d terminé - %s (Raison: %s)', 
        data.round, resultText, data.reason), 'info')
end)

RegisterNetEvent('fightleague:gameEnd', function(data)
    -- CORRECTIF : Arrêter toute téléportation
    playerState.isTeleporting = false
    
    playerState.inGame = false
    playerState.inQueue = false
    playerState.currentRound = 0
    playerState.role = nil
    
    SendNUIMessage({ action = 'hideCapture' })
    SendNUIMessage({ action = 'hideRoundResult' })
    
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

RegisterNetEvent('fightleague:teleportToEnd', function(coords)
    local ped = PlayerPedId()
    
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle ~= 0 then
        TaskLeaveVehicle(ped, vehicle, 0)
        Wait(1000)
    end
    
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, coords.w)
    
    Utils.Notify('Partie terminée ! Merci d\'avoir joué.', 'info')
    Utils.Log('Client', 'Téléporté au point final', 'info')
end)

RegisterNetEvent('fightleague:endGame', function()
    playerState.isTeleporting = false
    playerState.inGame = false
    playerState.inQueue = false
    
    Utils.Notify(Config.Lang.KickedFromGame, 'info')
    Utils.Log('Client', 'Partie terminée', 'info')
end)

-- ═════════════════════════════════════════════════════════════════
-- INITIALISATION
-- ═════════════════════════════════════════════════════════════════

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(100)
    end
    
    Utils.Log('Client', 'Initialisation du script...', 'info')
    
    CreateRegistrationPed()
    
    Utils.Log('Client', 'Script initialisé avec succès', 'info')
end)

-- ═════════════════════════════════════════════════════════════════
-- NETTOYAGE À LA DÉCONNEXION
-- ═════════════════════════════════════════════════════════════════

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    Utils.Log('Client', 'Arrêt du script - Nettoyage...', 'warn')
    
    if DoesEntityExist(pedEntity) then
        DeleteEntity(pedEntity)
    end
end)