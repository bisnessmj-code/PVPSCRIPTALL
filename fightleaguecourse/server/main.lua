--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║          FIGHTLEAGUE COURSE - SERVEUR PRINCIPAL               ║
    ║         Matchmaking + Routing Buckets + Gestion Parties       ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    OBJECTIF PERFORMANCE :
    - Idle : 0.00-0.01 ms
    - Matchmaking actif : 0.1-0.2 ms
    
    ARCHITECTURE :
    - Queue de matchmaking (table simple)
    - Attribution automatique des routing buckets
    - Gestion complète du cycle de vie des parties
    - Nettoyage automatique des ressources
]]

-- ═════════════════════════════════════════════════════════════════
-- VARIABLES GLOBALES SERVEUR
-- ═════════════════════════════════════════════════════════════════

local matchmakingQueue = {}      -- File d'attente : {source1, source2, ...}
local activePlayers = {}         -- Joueurs actifs : [source] = {gameId, bucket, team, ...}
local activeGames = {}           -- Parties actives : [gameId] = {players, bucket, spawn, ...}
local availableBuckets = {}      -- Buckets disponibles (pool)
local nextBucketId = Config.Matchmaking.StartingBucketId

-- ═════════════════════════════════════════════════════════════════
-- GESTION DES ROUTING BUCKETS
-- ═════════════════════════════════════════════════════════════════

--[[
    Récupère un routing bucket disponible
    
    Impact CPU : Négligeable (accès table)
    Retour : int - ID du bucket alloué
]]
local function GetAvailableBucket()
    -- Réutiliser un bucket libéré si disponible
    if #availableBuckets > 0 then
        local bucket = table.remove(availableBuckets, 1)
        Utils.Log('Buckets', 'Bucket réutilisé : ' .. bucket, 'info')
        return bucket
    end
    
    -- Créer un nouveau bucket
    local bucket = nextBucketId
    nextBucketId = nextBucketId + 1
    
    Utils.Log('Buckets', 'Nouveau bucket créé : ' .. bucket, 'info')
    return bucket
end

--[[
    Libère un routing bucket
    
    Impact CPU : Négligeable (insertion table)
]]
local function FreeBucket(bucketId)
    if not bucketId then return end
    
    table.insert(availableBuckets, bucketId)
    Utils.Log('Buckets', 'Bucket libéré : ' .. bucketId, 'info')
end

-- ═════════════════════════════════════════════════════════════════
-- GESTION DU MATCHMAKING
-- ═════════════════════════════════════════════════════════════════

--[[
    Ajoute un joueur à la file d'attente
    
    Impact CPU : Négligeable (insertion table)
]]
local function AddToQueue(source)
    -- Vérifications
    if activePlayers[source] then
        TriggerClientEvent('fightleague:notification', source, Config.Lang.AlreadyInGame, 'error')
        return false
    end
    
    -- Vérifier si déjà en queue
    for _, playerId in ipairs(matchmakingQueue) do
        if playerId == source then
            TriggerClientEvent('fightleague:notification', source, Config.Lang.AlreadyInQueue, 'error')
            return false
        end
    end
    
    -- Ajouter à la queue
    table.insert(matchmakingQueue, source)
    TriggerClientEvent('fightleague:queueJoined', source)
    
    Utils.Log('Matchmaking', 'Joueur ' .. source .. ' ajouté à la queue (' .. #matchmakingQueue .. ' joueurs)', 'info')
    return true
end

--[[
    Retire un joueur de la file d'attente
    
    Impact CPU : Négligeable (parcours table)
]]
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

--[[
    Tente de créer un match
    
    Impact CPU : Faible (appelé toutes les 2 secondes)
    Retour : bool - true si un match a été créé
]]
local function TryCreateMatch()
    -- Vérifier s'il y a assez de joueurs
    if #matchmakingQueue < Config.Matchmaking.MinPlayers then
        return false
    end
    
    -- Vérifier la limite de parties simultanées
    local activeGameCount = 0
    for _ in pairs(activeGames) do
        activeGameCount = activeGameCount + 1
    end
    
    if activeGameCount >= Config.Matchmaking.MaxConcurrentGames then
        Utils.Log('Matchmaking', 'Limite de parties simultanées atteinte (' .. activeGameCount .. ')', 'warn')
        return false
    end
    
    -- Prendre les 2 premiers joueurs de la queue
    local player1 = table.remove(matchmakingQueue, 1)
    local player2 = table.remove(matchmakingQueue, 1)
    
    -- Vérifier que les joueurs sont toujours connectés
    if not player1 or not player2 or GetPlayerPing(player1) == 0 or GetPlayerPing(player2) == 0 then
        Utils.Log('Matchmaking', 'Un joueur s\'est déconnecté', 'warn')
        
        -- Remettre les joueurs valides en queue
        if player1 and GetPlayerPing(player1) > 0 then
            table.insert(matchmakingQueue, 1, player1)
        end
        if player2 and GetPlayerPing(player2) > 0 then
            table.insert(matchmakingQueue, 1, player2)
        end
        
        return false
    end
    
    -- Créer la partie
    CreateGame(player1, player2)
    
    Utils.Log('Matchmaking', 'Match créé entre ' .. player1 .. ' et ' .. player2, 'info')
    return true
end

-- ═════════════════════════════════════════════════════════════════
-- GESTION DES PARTIES
-- ═════════════════════════════════════════════════════════════════

--[[
    Créé une nouvelle partie
    
    Impact CPU : Ponctuel (création unique par partie)
]]
function CreateGame(player1, player2)
    -- Générer un ID de partie
    local gameId = Utils.GenerateGameId()
    
    -- Allouer un routing bucket
    local bucket = GetAvailableBucket()
    
    -- Choisir un spawn aléatoire
    local spawn = Config.GetRandomSpawn()
    
    -- Créer l'objet partie
    activeGames[gameId] = {
        id = gameId,
        bucket = bucket,
        spawn = spawn,
        players = {
            {source = player1, team = 'A', score = 0, vehicle = nil, vehicleNetId = nil},
            {source = player2, team = 'B', score = 0, vehicle = nil, vehicleNetId = nil}
        },
        status = 'preparing',        -- preparing, playing, roundEnd, finished
        createdAt = os.time(),
        
        -- Système de rounds
        currentRound = 1,
        roundStartTime = nil,
        roundTimer = nil,
        distanceCheckThread = nil
    }
    
    -- Enregistrer les joueurs
    activePlayers[player1] = {gameId = gameId, bucket = bucket, team = 'A'}
    activePlayers[player2] = {gameId = gameId, bucket = bucket, team = 'B'}
    
    Utils.Log('Server', 'Partie créée : ' .. gameId .. ' (Bucket: ' .. bucket .. ')', 'info')
    
    -- Notifier les joueurs
    TriggerClientEvent('fightleague:matchFound', player1)
    TriggerClientEvent('fightleague:matchFound', player2)
    
    -- Démarrer la préparation (téléportation, spawn véhicules)
    CreateThread(function()
        PrepareGame(gameId)
    end)
end

--[[
    Prépare une partie (téléportation + spawn véhicules)
    
    Impact CPU : Ponctuel (une fois par partie)
]]
function PrepareGame(gameId)
    local game = activeGames[gameId]
    if not game then return end
    
    Utils.Log('Server', 'Préparation de la partie ' .. gameId, 'info')
    
    -- Déplacer les joueurs dans le routing bucket
    for _, playerData in ipairs(game.players) do
        SetPlayerRoutingBucket(playerData.source, game.bucket)
        Utils.Log('Buckets', 'Joueur ' .. playerData.source .. ' déplacé dans le bucket ' .. game.bucket, 'info')
    end
    
    -- Spawn les véhicules
    PrepareGameVehicles(gameId, false) -- false = positions normales (pas inversées)
end

--[[
    Spawn les véhicules pour un round
    
    @param gameId          string   ID de la partie
    @param invertSpawns    boolean  Inverser les positions TeamA/TeamB
]]
function PrepareGameVehicles(gameId, invertSpawns)
    local game = activeGames[gameId]
    if not game then return end
    
    -- Charger le modèle de véhicule
    local vehicleModel = GetHashKey(Config.Vehicle.Model)
    
    -- Pour chaque joueur
    for _, playerData in ipairs(game.players) do
        local source = playerData.source
        local team = playerData.team
        
        -- Déterminer la position de spawn
        local spawnPos
        if not invertSpawns then
            -- Positions normales
            spawnPos = team == 'A' and game.spawn.TeamA or game.spawn.TeamB
        else
            -- Positions inversées
            spawnPos = team == 'A' and game.spawn.TeamB or game.spawn.TeamA
        end
        
        -- Créer le véhicule côté serveur
        local vehicle = CreateVehicle(vehicleModel, spawnPos.x, spawnPos.y, spawnPos.z, spawnPos.w, true, true)
        
        -- Attendre que le véhicule soit créé
        while not DoesEntityExist(vehicle) do
            Wait(50)
        end
        
        -- Configuration du véhicule
        SetVehicleNumberPlateText(vehicle, Config.Vehicle.Plate)
        SetEntityRoutingBucket(vehicle, game.bucket)
        
        if Config.Vehicle.Invincible then
            SetEntityInvincible(vehicle, true)
        end
        
        -- Stocker le véhicule dans les données du joueur
        playerData.vehicle = vehicle
        playerData.vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
        
        Utils.Log('Server', 'Véhicule créé pour le joueur ' .. source .. ' (Team ' .. team .. ')', 'info')
        
        -- Téléporter le joueur dans le véhicule (côté client)
        TriggerClientEvent('fightleague:teleportToVehicle', source, playerData.vehicleNetId)
    end
    
    -- Attendre le délai de préparation (pour les connexions lentes)
    Wait(Config.Matchmaking.PreStartDelay)
    
    -- Démarrer le round
    StartRound(gameId)
end

--[[
    Démarre un round
    
    Impact CPU : Ponctuel (activation unique par round)
]]
function StartRound(gameId)
    local game = activeGames[gameId]
    if not game then return end
    
    local roundNum = game.currentRound
    
    Utils.Log('Server', string.format('Démarrage du round %d/%d pour la partie %s', 
        roundNum, Config.Rounds.TotalRounds, gameId), 'info')
    
    game.status = 'playing'
    game.roundStartTime = os.time()
    
    -- Déterminer les rôles (inversion à chaque round)
    local runnerTeam, chaserTeam
    if roundNum % 2 == 1 then
        -- Rounds impairs (1, 3) : TeamA fuit, TeamB poursuit
        runnerTeam = 'A'
        chaserTeam = 'B'
    else
        -- Rounds pairs (2, 4) : TeamB fuit, TeamA poursuit
        runnerTeam = 'B'
        chaserTeam = 'A'
    end
    
    -- Notifier les joueurs
    for _, playerData in ipairs(game.players) do
        local role = (playerData.team == runnerTeam) and 'runner' or 'chaser'
        TriggerClientEvent('fightleague:roundStart', playerData.source, {
            round = roundNum,
            totalRounds = Config.Rounds.TotalRounds,
            role = role,
            duration = Config.Rounds.RoundDuration
        })
    end
    
    -- Thread de vérification de distance (toutes les 15s)
    CreateThread(function()
        DistanceCheckThread(gameId, runnerTeam, chaserTeam)
    end)
    
    -- Thread de timeout du round (1min45s)
    CreateThread(function()
        RoundTimeoutThread(gameId)
    end)
end

--[[
    Thread de vérification de distance pour fuite réussie
    Vérifie toutes les 15 secondes si le fuyard est assez loin
    
    Impact CPU : ~0.01ms toutes les 15 secondes
]]
function DistanceCheckThread(gameId, runnerTeam, chaserTeam)
    local game = activeGames[gameId]
    if not game then return end
    
    Utils.Log('Server', 'Thread de vérification distance démarré pour ' .. gameId, 'info')
    
    while game.status == 'playing' do
        Wait(Config.Rounds.DistanceCheckInterval * 1000) -- 15 secondes
        
        game = activeGames[gameId]
        if not game or game.status ~= 'playing' then break end
        
        -- Récupérer les joueurs
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
        
        -- Vérifier si les joueurs sont connectés
        if GetPlayerPing(runner.source) == 0 or GetPlayerPing(chaser.source) == 0 then
            EndGame(gameId, 'disconnect')
            break
        end
        
        -- Récupérer les positions des véhicules
        local runnerVeh = runner.vehicle
        local chaserVeh = chaser.vehicle
        
        if not runnerVeh or not chaserVeh then break end
        if not DoesEntityExist(runnerVeh) or not DoesEntityExist(chaserVeh) then break end
        
        local runnerPos = GetEntityCoords(runnerVeh)
        local chaserPos = GetEntityCoords(chaserVeh)
        
        local distance = #(runnerPos - chaserPos)
        
        Utils.Log('Server', string.format('Distance entre joueurs : %.2fm', distance), 'info')
        
        -- Vérifier si fuite réussie
        if distance >= Config.Rounds.EscapeDistance then
            Utils.Log('Server', 'Fuite réussie ! Distance : ' .. distance .. 'm', 'info')
            EndRound(gameId, runnerTeam, 'escape')
            break
        end
    end
    
    Utils.Log('Server', 'Thread de vérification distance arrêté', 'info')
end

--[[
    Thread de timeout du round
    Termine le round après 1min45s si aucune condition de victoire
    
    Impact CPU : Ponctuel (une vérification après 105s)
]]
function RoundTimeoutThread(gameId)
    local game = activeGames[gameId]
    if not game then return end
    
    Wait(Config.Rounds.RoundDuration * 1000) -- 105 secondes
    
    game = activeGames[gameId]
    if not game or game.status ~= 'playing' then return end
    
    Utils.Log('Server', 'Timeout du round pour ' .. gameId, 'warn')
    
    -- En cas de timeout, le poursuiveur perd (fuite réussie par défaut)
    local roundNum = game.currentRound
    local runnerTeam = (roundNum % 2 == 1) and 'A' or 'B'
    
    EndRound(gameId, runnerTeam, 'timeout')
end

--[[
    Termine un round
    
    @param gameId      string  ID de la partie
    @param winnerTeam  string  'A' ou 'B'
    @param reason      string  'escape', 'capture', 'timeout'
]]
function EndRound(gameId, winnerTeam, reason)
    local game = activeGames[gameId]
    if not game or game.status ~= 'playing' then return end
    
    game.status = 'roundEnd'
    
    Utils.Log('Server', string.format('Fin du round %d pour %s - Vainqueur: Team%s (Raison: %s)', 
        game.currentRound, gameId, winnerTeam, reason), 'info')
    
    -- Ajouter un point au vainqueur
    for _, playerData in ipairs(game.players) do
        if playerData.team == winnerTeam then
            playerData.score = playerData.score + 1
        end
    end
    
    -- Notifier les joueurs
    for _, playerData in ipairs(game.players) do
        local won = playerData.team == winnerTeam
        TriggerClientEvent('fightleague:roundEnd', playerData.source, {
            round = game.currentRound,
            won = won,
            reason = reason,
            score = playerData.score
        })
    end
    
    -- Attendre avant de passer au round suivant
    Wait(Config.Rounds.RoundEndDelay)
    
    game = activeGames[gameId]
    if not game then return end
    
    -- Vérifier si c'était le dernier round
    if game.currentRound >= Config.Rounds.TotalRounds then
        EndGame(gameId, 'finished')
    else
        -- Passer au round suivant
        game.currentRound = game.currentRound + 1
        PrepareNextRound(gameId)
    end
end

--[[
    Prépare le round suivant
    Supprime les véhicules, inverse les positions, respawn
]]
function PrepareNextRound(gameId)
    local game = activeGames[gameId]
    if not game then return end
    
    Utils.Log('Server', 'Préparation du round ' .. game.currentRound, 'info')
    
    -- Supprimer les véhicules du round précédent
    for _, playerData in ipairs(game.players) do
        if playerData.vehicle and DoesEntityExist(playerData.vehicle) then
            DeleteEntity(playerData.vehicle)
            playerData.vehicle = nil
            playerData.vehicleNetId = nil
        end
    end
    
    Wait(Config.Rounds.RespawnDelay)
    
    -- Inverser les positions de spawn
    -- Round impair : TeamA au spawn TeamA, TeamB au spawn TeamB
    -- Round pair : TeamA au spawn TeamB, TeamB au spawn TeamA
    local useInvertedSpawns = (game.currentRound % 2 == 0)
    
    -- Respawn les véhicules avec nouvelles positions
    PrepareGameVehicles(gameId, useInvertedSpawns)
end

--[[
    Termine une partie et nettoie les ressources
    
    Impact CPU : Ponctuel (nettoyage unique)
]]
function EndGame(gameId, reason)
    local game = activeGames[gameId]
    if not game then return end
    
    Utils.Log('Server', 'Fin de la partie ' .. gameId .. ' (Raison: ' .. (reason or 'inconnu') .. ')', 'info')
    
    local isNormalEnd = (reason == 'finished')
    
    -- Calculer le vainqueur si partie terminée normalement
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
    
    -- Nettoyer les joueurs
    for _, playerData in ipairs(game.players) do
        local source = playerData.source
        
        -- Supprimer le véhicule
        if playerData.vehicle and DoesEntityExist(playerData.vehicle) then
            DeleteEntity(playerData.vehicle)
        end
        
        -- Retirer des joueurs actifs
        activePlayers[source] = nil
        
        -- Si fin normale, téléporter au point final
        if isNormalEnd then
            local won = (winner == playerData.team)
            local otherPlayerData = nil
            
            -- Trouver le score de l'autre joueur
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
            
            -- Attendre un peu pour la notification (5 secondes pour l'animation)
            Wait(5000)
            
            -- Remettre dans le bucket principal
            SetPlayerRoutingBucket(source, 0)
            
            -- Téléporter au point final
            TriggerClientEvent('fightleague:teleportToEnd', source, Config.EndPoint)
        else
            -- Fin anormale (déconnexion, etc.)
            SetPlayerRoutingBucket(source, 0)
            TriggerClientEvent('fightleague:endGame', source)
        end
        
        Utils.Log('Server', 'Joueur ' .. source .. ' nettoyé', 'info')
    end
    
    -- Libérer le routing bucket
    FreeBucket(game.bucket)
    
    -- Supprimer la partie
    activeGames[gameId] = nil
end

-- ═════════════════════════════════════════════════════════════════
-- THREAD DE MATCHMAKING
-- ═════════════════════════════════════════════════════════════════

--[[
    Thread de matchmaking automatique
    
    FRÉQUENCE : 2000ms (2 secondes)
    Impact CPU : ~0.05-0.1ms toutes les 2 secondes
    
    AUTO-RÉGULATION : Si la queue est vide, le thread reste actif
    mais ne fait rien (impact minimal)
]]
CreateThread(function()
    Utils.Log('Matchmaking', 'Thread de matchmaking démarré', 'info')
    
    while true do
        Wait(Config.Timings.MatchmakingCheckInterval) -- 2000ms par défaut
        
        -- Tenter de créer un match
        if #matchmakingQueue >= Config.Matchmaking.MinPlayers then
            TryCreateMatch()
        end
    end
end)

-- ═════════════════════════════════════════════════════════════════
-- EVENTS RÉSEAU
-- ═════════════════════════════════════════════════════════════════

--[[
    Event : Joueur rejoint la queue
]]
RegisterNetEvent('fightleague:joinQueue', function()
    local source = source
    AddToQueue(source)
end)

--[[
    Event : Joueur quitte la queue
]]
RegisterNetEvent('fightleague:leaveQueue', function()
    local source = source
    RemoveFromQueue(source)
end)

--[[
    Event : Capture réussie (envoyé par le client poursuiveur)
]]
RegisterNetEvent('fightleague:captureComplete', function()
    local source = source
    
    -- Vérifier que le joueur est bien en partie
    local playerData = activePlayers[source]
    if not playerData then return end
    
    local gameId = playerData.gameId
    local game = activeGames[gameId]
    
    if not game or game.status ~= 'playing' then return end
    
    -- Déterminer qui est le poursuiveur dans ce round
    local roundNum = game.currentRound
    local chaserTeam = (roundNum % 2 == 1) and 'B' or 'A'
    
    -- Vérifier que c'est bien le poursuiveur qui envoie l'event
    if playerData.team ~= chaserTeam then
        Utils.Log('Server', 'Tentative de capture invalide par Team' .. playerData.team, 'warn')
        return
    end
    
    Utils.Log('Server', 'Capture réussie par Team' .. chaserTeam .. ' dans la partie ' .. gameId, 'info')
    
    -- Terminer le round avec victoire du poursuiveur
    EndRound(gameId, chaserTeam, 'capture')
end)

-- ═════════════════════════════════════════════════════════════════
-- GESTION DES DÉCONNEXIONS
-- ═════════════════════════════════════════════════════════════════

--[[
    Nettoyage automatique quand un joueur se déconnecte
    
    Impact CPU : Événementiel (seulement à la déconnexion)
]]
AddEventHandler('playerDropped', function(reason)
    local source = source
    
    Utils.Log('Server', 'Joueur ' .. source .. ' déconnecté (Raison: ' .. reason .. ')', 'warn')
    
    -- Retirer de la queue
    RemoveFromQueue(source)
    
    -- Vérifier s'il est en partie
    local playerData = activePlayers[source]
    if playerData then
        local gameId = playerData.gameId
        
        -- Terminer la partie
        EndGame(gameId, 'disconnect')
    end
end)

-- ═════════════════════════════════════════════════════════════════
-- NETTOYAGE À L'ARRÊT DU SCRIPT
-- ═════════════════════════════════════════════════════════════════

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    Utils.Log('Server', 'Arrêt du script - Nettoyage de toutes les parties...', 'warn')
    
    -- Terminer toutes les parties actives
    for gameId, _ in pairs(activeGames) do
        EndGame(gameId, 'resource_stop')
    end
    
    -- Vider la queue
    matchmakingQueue = {}
    
    Utils.Log('Server', 'Nettoyage terminé', 'info')
end)

-- ═════════════════════════════════════════════════════════════════
-- EXPORTS (pour utilisation externe)
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
