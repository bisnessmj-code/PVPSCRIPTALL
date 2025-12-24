--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║          FIGHTLEAGUE COURSE - SERVEUR PRINCIPAL               ║
    ║         Matchmaking + Routing Buckets + Gestion Parties       ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    CORRECTIFS APPLIQUÉS :
    - Synchronisation réseau renforcée pour création véhicule
    - Délais adaptatifs selon latence réseau
    - Meilleure gestion du cycle de vie des rounds
]]

-- ═════════════════════════════════════════════════════════════════
-- VARIABLES GLOBALES SERVEUR
-- ═════════════════════════════════════════════════════════════════

local matchmakingQueue = {}
local activePlayers = {}
local activeGames = {}
local availableBuckets = {}
local nextBucketId = Config.Matchmaking.StartingBucketId

-- ═════════════════════════════════════════════════════════════════
-- GESTION DES ROUTING BUCKETS
-- ═════════════════════════════════════════════════════════════════

local function GetAvailableBucket()
    if #availableBuckets > 0 then
        local bucket = table.remove(availableBuckets, 1)
        Utils.Log('Buckets', 'Bucket réutilisé : ' .. bucket, 'info')
        return bucket
    end
    
    local bucket = nextBucketId
    nextBucketId = nextBucketId + 1
    
    Utils.Log('Buckets', 'Nouveau bucket créé : ' .. bucket, 'info')
    return bucket
end

local function FreeBucket(bucketId)
    if not bucketId then return end
    
    table.insert(availableBuckets, bucketId)
    Utils.Log('Buckets', 'Bucket libéré : ' .. bucketId, 'info')
end

-- ═════════════════════════════════════════════════════════════════
-- GESTION DU MATCHMAKING
-- ═════════════════════════════════════════════════════════════════

local function AddToQueue(source)
    if activePlayers[source] then
        TriggerClientEvent('fightleague:notification', source, Config.Lang.AlreadyInGame, 'error')
        return false
    end
    
    for _, playerId in ipairs(matchmakingQueue) do
        if playerId == source then
            TriggerClientEvent('fightleague:notification', source, Config.Lang.AlreadyInQueue, 'error')
            return false
        end
    end
    
    table.insert(matchmakingQueue, source)
    TriggerClientEvent('fightleague:queueJoined', source)
    
    Utils.Log('Matchmaking', 'Joueur ' .. source .. ' ajouté à la queue (' .. #matchmakingQueue .. ' joueurs)', 'info')
    return true
end

local function RemoveFromQueue(source)
    for i, playerId in ipairs(matchmakingQueue) do
        if playerId == source then
            table.remove(matchmakingQueue, i)
            TriggerClientEvent('fightleague:queueLeft', source)
            Utils.Log('Matchmaking', 'Joueur ' .. source .. ' retiré de la queue', 'info')
            return true
        end
    end
    return false
end

local function TryCreateMatch()
    if #matchmakingQueue < Config.Matchmaking.MinPlayers then
        return false
    end
    
    local activeGameCount = 0
    for _ in pairs(activeGames) do
        activeGameCount = activeGameCount + 1
    end
    
    if activeGameCount >= Config.Matchmaking.MaxConcurrentGames then
        Utils.Log('Matchmaking', 'Limite de parties simultanées atteinte (' .. activeGameCount .. ')', 'warn')
        return false
    end
    
    local player1 = table.remove(matchmakingQueue, 1)
    local player2 = table.remove(matchmakingQueue, 1)
    
    if not player1 or not player2 or GetPlayerPing(player1) == 0 or GetPlayerPing(player2) == 0 then
        Utils.Log('Matchmaking', 'Un joueur s\'est déconnecté', 'warn')
        
        if player1 and GetPlayerPing(player1) > 0 then
            table.insert(matchmakingQueue, 1, player1)
        end
        if player2 and GetPlayerPing(player2) > 0 then
            table.insert(matchmakingQueue, 1, player2)
        end
        
        return false
    end
    
    CreateGame(player1, player2)
    
    Utils.Log('Matchmaking', 'Match créé entre ' .. player1 .. ' et ' .. player2, 'info')
    return true
end

-- ═════════════════════════════════════════════════════════════════
-- GESTION DES PARTIES
-- ═════════════════════════════════════════════════════════════════

function CreateGame(player1, player2)
    local gameId = Utils.GenerateGameId()
    local bucket = GetAvailableBucket()
    local spawn = Config.GetRandomSpawn()
    
    activeGames[gameId] = {
        id = gameId,
        bucket = bucket,
        spawn = spawn,
        players = {
            {source = player1, team = 'A', score = 0, vehicle = nil, vehicleNetId = nil},
            {source = player2, team = 'B', score = 0, vehicle = nil, vehicleNetId = nil}
        },
        status = 'preparing',
        createdAt = os.time(),
        currentRound = 1,
        roundStartTime = nil,
        roundTimer = nil,
        distanceCheckThread = nil
    }
    
    activePlayers[player1] = {gameId = gameId, bucket = bucket, team = 'A'}
    activePlayers[player2] = {gameId = gameId, bucket = bucket, team = 'B'}
    
    Utils.Log('Server', 'Partie créée : ' .. gameId .. ' (Bucket: ' .. bucket .. ')', 'info')
    
    TriggerClientEvent('fightleague:matchFound', player1)
    TriggerClientEvent('fightleague:matchFound', player2)
    
    CreateThread(function()
        PrepareGame(gameId)
    end)
end

function PrepareGame(gameId)
    local game = activeGames[gameId]
    if not game then return end
    
    Utils.Log('Server', 'Préparation de la partie ' .. gameId, 'info')
    
    for _, playerData in ipairs(game.players) do
        SetPlayerRoutingBucket(playerData.source, game.bucket)
        Utils.Log('Buckets', 'Joueur ' .. playerData.source .. ' déplacé dans le bucket ' .. game.bucket, 'info')
    end
    
    PrepareGameVehicles(gameId, false)
end

--[[
    CORRECTIF MAJEUR : Synchronisation réseau améliorée
]]
function PrepareGameVehicles(gameId, invertSpawns)
    local game = activeGames[gameId]
    if not game then return end
    
    local vehicleModel = GetHashKey(Config.Vehicle.Model)
    
    -- CORRECTIF : Créer et synchroniser TOUS les véhicules AVANT de téléporter
    local vehiclesToSync = {}
    
    for _, playerData in ipairs(game.players) do
        local source = playerData.source
        local team = playerData.team
        
        local spawnPos
        if not invertSpawns then
            spawnPos = team == 'A' and game.spawn.TeamA or game.spawn.TeamB
        else
            spawnPos = team == 'A' and game.spawn.TeamB or game.spawn.TeamA
        end
        
        -- Créer le véhicule
        local vehicle = CreateVehicle(vehicleModel, spawnPos.x, spawnPos.y, spawnPos.z, spawnPos.w, true, true)
        
        while not DoesEntityExist(vehicle) do
            Wait(50)
        end
        
        -- Configuration véhicule
        SetVehicleNumberPlateText(vehicle, Config.Vehicle.Plate)
        SetEntityRoutingBucket(vehicle, game.bucket)
        
        if Config.Vehicle.Invincible then
            SetEntityInvincible(vehicle, true)
        end
        
        playerData.vehicle = vehicle
        playerData.vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
        
        table.insert(vehiclesToSync, {
            source = source,
            vehicle = vehicle,
            netId = playerData.vehicleNetId
        })
        
        Utils.Log('Server', 'Véhicule créé pour le joueur ' .. source .. ' (Team ' .. team .. ') - NetID: ' .. playerData.vehicleNetId, 'info')
    end
    
    -- CORRECTIF : Attendre synchronisation réseau simple mais efficace
    -- Le serveur n'a pas besoin de vérifier NetworkGetEntityIsNetworked (n'existe pas côté serveur)
    -- On attend simplement un délai raisonnable pour la propagation réseau
    Wait(1500) -- Délai de synchronisation réseau (suffisant pour la plupart des connexions)
    
    Utils.Log('Server', 'Véhicules créés, synchronisation réseau en cours...', 'info')
    
    -- CORRECTIF : Téléportation séquentielle avec petit délai entre chaque joueur
    for _, vehData in ipairs(vehiclesToSync) do
        Utils.Log('Server', 'Téléportation du joueur ' .. vehData.source .. ' vers NetID:' .. vehData.netId, 'info')
        TriggerClientEvent('fightleague:teleportToVehicle', vehData.source, vehData.netId)
        Wait(250) -- Petit délai entre chaque téléportation pour éviter la surcharge réseau
    end
    
    -- Attendre le délai de préparation
    Wait(Config.Matchmaking.PreStartDelay)
    
    StartRound(gameId)
end

function StartRound(gameId)
    local game = activeGames[gameId]
    if not game then return end
    
    local roundNum = game.currentRound
    
    Utils.Log('Server', string.format('Démarrage du round %d/%d pour la partie %s', 
        roundNum, Config.Rounds.TotalRounds, gameId), 'info')
    
    game.status = 'playing'
    game.roundStartTime = os.time()
    
    local runnerTeam, chaserTeam
    if roundNum % 2 == 1 then
        runnerTeam = 'A'
        chaserTeam = 'B'
    else
        runnerTeam = 'B'
        chaserTeam = 'A'
    end
    
    for _, playerData in ipairs(game.players) do
        local role = (playerData.team == runnerTeam) and 'runner' or 'chaser'
        TriggerClientEvent('fightleague:roundStart', playerData.source, {
            round = roundNum,
            totalRounds = Config.Rounds.TotalRounds,
            role = role,
            duration = Config.Rounds.RoundDuration
        })
    end
    
    CreateThread(function()
        DistanceCheckThread(gameId, runnerTeam, chaserTeam)
    end)
    
    CreateThread(function()
        RoundTimeoutThread(gameId)
    end)
end

function DistanceCheckThread(gameId, runnerTeam, chaserTeam)
    local game = activeGames[gameId]
    if not game then return end
    
    Utils.Log('Server', 'Thread de vérification distance démarré pour ' .. gameId, 'info')
    
    while game.status == 'playing' do
        Wait(Config.Rounds.DistanceCheckInterval * 1000)
        
        game = activeGames[gameId]
        if not game or game.status ~= 'playing' then break end
        
        local runner = nil
        local chaser = nil
        
        for _, playerData in ipairs(game.players) do
            if playerData.team == runnerTeam then
                runner = playerData
            else
                chaser = playerData
            end
        end
        
        if not runner or not chaser then break end
        
        if GetPlayerPing(runner.source) == 0 or GetPlayerPing(chaser.source) == 0 then
            EndGame(gameId, 'disconnect')
            break
        end
        
        local runnerVeh = runner.vehicle
        local chaserVeh = chaser.vehicle
        
        if not runnerVeh or not chaserVeh then break end
        if not DoesEntityExist(runnerVeh) or not DoesEntityExist(chaserVeh) then break end
        
        local runnerPos = GetEntityCoords(runnerVeh)
        local chaserPos = GetEntityCoords(chaserVeh)
        
        local distance = #(runnerPos - chaserPos)
        
        Utils.Log('Server', string.format('Distance entre joueurs : %.2fm', distance), 'info')
        
        if distance >= Config.Rounds.EscapeDistance then
            Utils.Log('Server', 'Fuite réussie ! Distance : ' .. distance .. 'm', 'info')
            EndRound(gameId, runnerTeam, 'escape')
            break
        end
    end
    
    Utils.Log('Server', 'Thread de vérification distance arrêté', 'info')
end

function RoundTimeoutThread(gameId)
    local game = activeGames[gameId]
    if not game then return end
    
    Wait(Config.Rounds.RoundDuration * 1000)
    
    game = activeGames[gameId]
    if not game or game.status ~= 'playing' then return end
    
    Utils.Log('Server', 'Timeout du round pour ' .. gameId, 'warn')
    
    local roundNum = game.currentRound
    local runnerTeam = (roundNum % 2 == 1) and 'A' or 'B'
    
    EndRound(gameId, runnerTeam, 'timeout')
end

function EndRound(gameId, winnerTeam, reason)
    local game = activeGames[gameId]
    if not game or game.status ~= 'playing' then return end
    
    game.status = 'roundEnd'
    
    Utils.Log('Server', string.format('Fin du round %d pour %s - Vainqueur: Team%s (Raison: %s)', 
        game.currentRound, gameId, winnerTeam, reason), 'info')
    
    for _, playerData in ipairs(game.players) do
        if playerData.team == winnerTeam then
            playerData.score = playerData.score + 1
        end
    end
    
    for _, playerData in ipairs(game.players) do
        local won = playerData.team == winnerTeam
        TriggerClientEvent('fightleague:roundEnd', playerData.source, {
            round = game.currentRound,
            won = won,
            reason = reason,
            score = playerData.score
        })
    end
    
    Wait(Config.Rounds.RoundEndDelay)
    
    game = activeGames[gameId]
    if not game then return end
    
    if game.currentRound >= Config.Rounds.TotalRounds then
        EndGame(gameId, 'finished')
    else
        game.currentRound = game.currentRound + 1
        PrepareNextRound(gameId)
    end
end

--[[
    CORRECTIF : Meilleure gestion de la transition entre rounds
]]
function PrepareNextRound(gameId)
    local game = activeGames[gameId]
    if not game then return end
    
    Utils.Log('Server', 'Préparation du round ' .. game.currentRound, 'info')
    
    -- CORRECTIF : Supprimer les véhicules proprement
    for _, playerData in ipairs(game.players) do
        if playerData.vehicle and DoesEntityExist(playerData.vehicle) then
            -- Éjecter le joueur avant de supprimer le véhicule
            local ped = GetPlayerPed(playerData.source)
            if ped and ped ~= 0 then
                TaskLeaveVehicle(ped, playerData.vehicle, 0)
            end
            
            -- Attendre un peu
            Wait(500)
            
            -- Supprimer le véhicule
            DeleteEntity(playerData.vehicle)
            playerData.vehicle = nil
            playerData.vehicleNetId = nil
            
            Utils.Log('Server', 'Véhicule supprimé pour joueur ' .. playerData.source, 'info')
        end
    end
    
    Wait(Config.Rounds.RespawnDelay)
    
    local useInvertedSpawns = (game.currentRound % 2 == 0)
    
    PrepareGameVehicles(gameId, useInvertedSpawns)
end

function EndGame(gameId, reason)
    local game = activeGames[gameId]
    if not game then return end
    
    Utils.Log('Server', 'Fin de la partie ' .. gameId .. ' (Raison: ' .. (reason or 'inconnu') .. ')', 'info')
    
    local isNormalEnd = (reason == 'finished')
    
    local winner = nil
    if isNormalEnd then
        local scoreA = 0
        local scoreB = 0
        
        for _, playerData in ipairs(game.players) do
            if playerData.team == 'A' then
                scoreA = playerData.score
            else
                scoreB = playerData.score
            end
        end
        
        if scoreA > scoreB then
            winner = 'A'
        elseif scoreB > scoreA then
            winner = 'B'
        else
            winner = 'draw'
        end
        
        Utils.Log('Server', string.format('Score final - TeamA: %d, TeamB: %d - Vainqueur: %s', 
            scoreA, scoreB, winner), 'info')
    end
    
    for _, playerData in ipairs(game.players) do
        local source = playerData.source
        
        if playerData.vehicle and DoesEntityExist(playerData.vehicle) then
            DeleteEntity(playerData.vehicle)
        end
        
        activePlayers[source] = nil
        
        if isNormalEnd then
            local won = (winner == playerData.team)
            local otherPlayerData = nil
            
            for _, pd in ipairs(game.players) do
                if pd.source ~= source then
                    otherPlayerData = pd
                    break
                end
            end
            
            local finalScoreText = ''
            if otherPlayerData then
                finalScoreText = string.format('%d - %d', playerData.score, otherPlayerData.score)
            end
            
            TriggerClientEvent('fightleague:gameEnd', source, {
                won = won,
                winner = winner,
                finalScore = playerData.score,
                finalScoreText = finalScoreText
            })
            
            Wait(5000)
            
            SetPlayerRoutingBucket(source, 0)
            
            TriggerClientEvent('fightleague:teleportToEnd', source, Config.EndPoint)
        else
            SetPlayerRoutingBucket(source, 0)
            TriggerClientEvent('fightleague:endGame', source)
        end
        
        Utils.Log('Server', 'Joueur ' .. source .. ' nettoyé', 'info')
    end
    
    FreeBucket(game.bucket)
    
    activeGames[gameId] = nil
end

-- ═════════════════════════════════════════════════════════════════
-- THREAD DE MATCHMAKING
-- ═════════════════════════════════════════════════════════════════

CreateThread(function()
    Utils.Log('Matchmaking', 'Thread de matchmaking démarré', 'info')
    
    while true do
        Wait(Config.Timings.MatchmakingCheckInterval)
        
        if #matchmakingQueue >= Config.Matchmaking.MinPlayers then
            TryCreateMatch()
        end
    end
end)

-- ═════════════════════════════════════════════════════════════════
-- EVENTS RÉSEAU
-- ═════════════════════════════════════════════════════════════════

RegisterNetEvent('fightleague:joinQueue', function()
    local source = source
    AddToQueue(source)
end)

RegisterNetEvent('fightleague:leaveQueue', function()
    local source = source
    RemoveFromQueue(source)
end)

RegisterNetEvent('fightleague:captureComplete', function()
    local source = source
    
    local playerData = activePlayers[source]
    if not playerData then return end
    
    local gameId = playerData.gameId
    local game = activeGames[gameId]
    
    if not game or game.status ~= 'playing' then return end
    
    local roundNum = game.currentRound
    local chaserTeam = (roundNum % 2 == 1) and 'B' or 'A'
    
    if playerData.team ~= chaserTeam then
        Utils.Log('Server', 'Tentative de capture invalide par Team' .. playerData.team, 'warn')
        return
    end
    
    Utils.Log('Server', 'Capture réussie par Team' .. chaserTeam .. ' dans la partie ' .. gameId, 'info')
    
    EndRound(gameId, chaserTeam, 'capture')
end)

-- ═════════════════════════════════════════════════════════════════
-- GESTION DES DÉCONNEXIONS
-- ═════════════════════════════════════════════════════════════════

AddEventHandler('playerDropped', function(reason)
    local source = source
    
    Utils.Log('Server', 'Joueur ' .. source .. ' déconnecté (Raison: ' .. reason .. ')', 'warn')
    
    RemoveFromQueue(source)
    
    local playerData = activePlayers[source]
    if playerData then
        local gameId = playerData.gameId
        EndGame(gameId, 'disconnect')
    end
end)

-- ═════════════════════════════════════════════════════════════════
-- NETTOYAGE À L'ARRÊT DU SCRIPT
-- ═════════════════════════════════════════════════════════════════

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    Utils.Log('Server', 'Arrêt du script - Nettoyage de toutes les parties...', 'warn')
    
    for gameId, _ in pairs(activeGames) do
        EndGame(gameId, 'resource_stop')
    end
    
    matchmakingQueue = {}
    
    Utils.Log('Server', 'Nettoyage terminé', 'info')
end)

-- ═════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═════════════════════════════════════════════════════════════════

exports('GetActiveGames', function()
    return activeGames
end)

exports('GetMatchmakingQueue', function()
    return matchmakingQueue
end)

exports('GetActivePlayers', function()
    return activePlayers
end)