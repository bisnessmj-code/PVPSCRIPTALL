-- ========================================
-- PVP GUNFIGHT SERVER MAIN
-- Version 4.13.0 - MORTS SIMULTANÉES + ÉCHANGE SPAWNS
-- ========================================

DebugServer('Chargement systeme PVP (ULTRA-OPTIMISÉ + SPAWN SWAP + MORTS SIMULTANÉES)...')

-- ========================================
-- ÉTATS DE MATCH
-- ========================================
local MATCH_STATE = {
    CREATING = 'creating',
    STARTING = 'starting',
    PLAYING = 'playing',
    ROUND_END = 'round_end',
    FINISHING = 'finishing',
    CANCELLED = 'cancelled',
    FINISHED = 'finished'
}

-- Variables
local queues = {
    ['1v1'] = {},
    ['2v2'] = {},
    ['3v3'] = {},
    ['4v4'] = {}
}

local activeMatches = {}
local playersInQueue = {}
local playerCurrentMatch = {}
local playerCurrentBucket = {}
local playerWasSoloBeforeMatch = {}
local nextBucketId = 100

-- Systeme de heartbeat pour detecter les crashes
local playerLastHeartbeat = {}
local HEARTBEAT_TIMEOUT = 10000

-- 🆕 SYSTÈME DE DÉTECTION MORTS SIMULTANÉES
local SIMULTANEOUS_DEATH_WINDOW = 500 -- 500ms de fenêtre pour détecter morts simultanées

-- 🆕 CACHE DES STATS QUEUES (évite recalculs)
local cachedQueueStats = {
    ['1v1'] = 0,
    ['2v2'] = 0,
    ['3v3'] = 0,
    ['4v4'] = 0
}

-- ========================================
-- 🆕 FONCTION OPTIMISÉE: OBTENIR STATS DES QUEUES (AVEC CACHE)
-- ========================================
local function GetQueueStats()
    local stats = {
        ['1v1'] = 0,
        ['2v2'] = 0,
        ['3v3'] = 0,
        ['4v4'] = 0
    }
    
    -- Compter TOUS les joueurs en recherche par mode
    for mode, queue in pairs(queues) do
        stats[mode] = #queue
    end
    
    return stats
end

-- 🆕 FONCTION: VÉRIFIER SI STATS ONT CHANGÉ
local function HasStatsChanged(newStats)
    for mode, count in pairs(newStats) do
        if cachedQueueStats[mode] ~= count then
            return true
        end
    end
    return false
end

-- 🆕 FONCTION: BROADCAST UNIQUEMENT SI CHANGEMENT
local function BroadcastQueueStatsIfChanged()
    local newStats = GetQueueStats()
    
    -- ✅ OPTIMISATION: Ne broadcaster QUE si changement
    if not HasStatsChanged(newStats) then
        return
    end
    
    DebugServer('📊 Stats queues changées - Broadcast: %s', json.encode(newStats))
    
    -- Mettre à jour le cache
    cachedQueueStats = newStats
    
    -- Broadcaster à tous les joueurs
    local players = GetPlayers()
    for i = 1, #players do
        local playerId = tonumber(players[i])
        if playerId and playerId > 0 and GetPlayerPing(playerId) > 0 then
            TriggerClientEvent('pvp:updateQueueStats', playerId, newStats)
        end
    end
end

-- TABLE DES NOMS D'ARMES (POUR KILLFEED)
local WEAPON_NAMES = {
    [GetHashKey('WEAPON_PISTOL')] = 'Pistol',
    [GetHashKey('WEAPON_PISTOL50')] = 'Pistol .50',
    [GetHashKey('WEAPON_COMBATPISTOL')] = 'Combat Pistol',
    [GetHashKey('WEAPON_APPISTOL')] = 'AP Pistol',
    [GetHashKey('WEAPON_HEAVYPISTOL')] = 'Heavy Pistol',
    [GetHashKey('WEAPON_SNSPISTOL')] = 'SNS Pistol',
    [GetHashKey('WEAPON_VINTAGEPISTOL')] = 'Vintage Pistol',
    [GetHashKey('WEAPON_ASSAULTRIFLE')] = 'AK-47',
    [GetHashKey('WEAPON_CARBINERIFLE')] = 'M4A1',
    [GetHashKey('WEAPON_SMG')] = 'SMG',
    [GetHashKey('WEAPON_MICROSMG')] = 'Micro SMG',
    [GetHashKey('WEAPON_PUMPSHOTGUN')] = 'Pump Shotgun',
    [GetHashKey('WEAPON_KNIFE')] = 'Knife',
    [GetHashKey('WEAPON_NIGHTSTICK')] = 'Nightstick',
    [GetHashKey('WEAPON_HAMMER')] = 'Hammer',
    [GetHashKey('WEAPON_BAT')] = 'Baseball Bat',
}

-- ========================================
-- 🔄 NOUVEAU: FONCTION D'ÉCHANGE DE SPAWNS
-- ========================================
local function ShouldSwapSpawns(roundNumber)
    -- Échanger les spawns tous les rounds PAIRS (2, 4, 6...)
    return (roundNumber % 2) == 0
end

-- ========================================
-- VÉRIFIER VALIDITÉ MATCH
-- ========================================
local function IsMatchValid(matchId)
    if not matchId then return false end
    local match = activeMatches[matchId]
    if not match then return false end
    if match.status == MATCH_STATE.CANCELLED or match.status == MATCH_STATE.FINISHED then
        return false
    end
    return true
end

-- ========================================
-- OBTENIR MATCH SÉCURISÉ
-- ========================================
local function GetMatchSafe(matchId)
    if not matchId then 
        DebugError('GetMatchSafe: matchId nil')
        return nil 
    end
    
    local match = activeMatches[matchId]
    
    if not match then
        DebugError('GetMatchSafe: match %s introuvable', tostring(matchId))
        return nil
    end
    
    if match.status == MATCH_STATE.CANCELLED then
        DebugWarn('GetMatchSafe: match %s annulé', matchId)
        return nil
    end
    
    if match.status == MATCH_STATE.FINISHED then
        DebugWarn('GetMatchSafe: match %s terminé', matchId)
        return nil
    end
    
    return match
end

-- ========================================
-- ANNULER MATCH
-- ========================================
local function CancelMatch(matchId, reason)
    local match = activeMatches[matchId]
    if not match then return end
    
    DebugWarn('🚫 ANNULATION MATCH %d - Raison: %s', matchId, reason)
    
    match.status = MATCH_STATE.CANCELLED
    
    for i = 1, #match.players do
        local playerId = match.players[i]
        if playerId > 0 and GetPlayerPing(playerId) > 0 then
            TriggerClientEvent('pvp:forceReturnToLobby', playerId)
            TriggerClientEvent('esx:showNotification', playerId, '~r~Match annulé: ' .. reason)
            
            playerCurrentMatch[playerId] = nil
            playerLastHeartbeat[playerId] = nil
            ResetPlayerBucket(playerId)
        end
    end
    
    Wait(1000)
    activeMatches[matchId] = nil
    
    DebugSuccess('✅ Match %d annulé et nettoyé', matchId)
end

-- ========================================
-- FONCTION: OBTENIR NOM FIVEM + ID
-- ========================================
local function GetPlayerFiveMNameWithID(playerId)
    if not playerId or playerId <= 0 then
        return "Joueur inconnu"
    end
    
    if GetPlayerPing(playerId) <= 0 then
        return "Joueur déconnecté"
    end
    
    local playerName = GetPlayerName(playerId)
    
    if playerName then
        playerName = playerName:gsub("%^%d", "")
    else
        playerName = "Joueur"
    end
    
    return string.format("%s [%d]", playerName, playerId)
end

-- ========================================
-- FONCTION: ANNULER RECHERCHE GROUPE COMPLET
-- ========================================
local function CancelGroupSearch(groupMembers, mode, reason)
    if not groupMembers or #groupMembers == 0 then return end
    
    DebugWarn('🚫 Annulation recherche groupe - Raison: %s', reason)
    
    for i = 1, #groupMembers do
        local memberId = groupMembers[i]
        
        for j = #queues[mode], 1, -1 do
            if queues[mode][j] == memberId then
                table.remove(queues[mode], j)
                break
            end
        end
        
        playersInQueue[memberId] = nil
        playerLastHeartbeat[memberId] = nil
        
        if GetPlayerPing(memberId) > 0 then
            TriggerClientEvent('pvp:searchCancelled', memberId)
            TriggerClientEvent('esx:showNotification', memberId, '~r~' .. reason)
        end
    end
    
    -- ✅ BROADCAST UNIQUEMENT SI CHANGEMENT
    BroadcastQueueStatsIfChanged()
    
    DebugSuccess('✅ Recherche annulée pour %d joueurs', #groupMembers)
end

-- ========================================
-- FONCTION: DÉCONNEXION JOUEUR EN RECHERCHE
-- ========================================
local function HandlePlayerDisconnectFromQueue(playerId)
    if not playersInQueue[playerId] then return end
    
    local queueData = playersInQueue[playerId]
    local mode = queueData.mode
    local groupMembers = queueData.groupMembers or {playerId}
    
    DebugWarn('⚠️ Joueur %d déconnecté pendant recherche %s', playerId, mode)
    
    if #groupMembers > 1 then
        DebugWarn('🚨 DÉCONNEXION MEMBRE GROUPE - %d joueurs affectés', #groupMembers)
        CancelGroupSearch(groupMembers, mode, 'Recherche annulée: Un membre a quitté')
    else
        for j = #queues[mode], 1, -1 do
            if queues[mode][j] == playerId then
                table.remove(queues[mode], j)
                break
            end
        end
        
        playersInQueue[playerId] = nil
        playerLastHeartbeat[playerId] = nil
        
        -- ✅ BROADCAST UNIQUEMENT SI CHANGEMENT
        BroadcastQueueStatsIfChanged()
        
        DebugServer('Recherche solo annulée pour joueur %d', playerId)
    end
end

-- THREAD DETECTION CRASH
CreateThread(function()
    while true do
        Wait(5000)
        
        local currentTime = GetGameTimer()
        local crashedPlayers = {}
        
        for playerId, matchId in pairs(playerCurrentMatch) do
            if activeMatches[matchId] then
                local lastHeartbeat = playerLastHeartbeat[playerId] or 0
                local timeSinceHeartbeat = currentTime - lastHeartbeat
                
                if timeSinceHeartbeat > HEARTBEAT_TIMEOUT then
                    local ping = GetPlayerPing(playerId)
                    
                    if ping <= 0 or timeSinceHeartbeat > HEARTBEAT_TIMEOUT then
                        DebugError('CRASH DETECTE Joueur %d (Ping: %d, Timeout: %dms)', 
                            playerId, ping, timeSinceHeartbeat)
                        
                        crashedPlayers[#crashedPlayers + 1] = playerId
                    end
                end
            end
        end
        
        for i = 1, #crashedPlayers do
            local playerId = crashedPlayers[i]
            DebugWarn('Traitement crash joueur %d...', playerId)
            HandlePlayerDisconnect(playerId)
        end
    end
end)

-- EVENT HEARTBEAT CLIENT
RegisterNetEvent('pvp:heartbeat', function()
    local src = source
    playerLastHeartbeat[src] = GetGameTimer()
end)

-- GESTION ROUTING BUCKETS
local function CreateMatchBucket()
    local bucketId = nextBucketId
    nextBucketId = nextBucketId + 1
    
    SetRoutingBucketPopulationEnabled(bucketId, true)
    SetRoutingBucketEntityLockdownMode(bucketId, 'strict')
    
    DebugBucket('Bucket %d cree', bucketId)
    return bucketId
end

local function SetPlayerBucket(playerId, bucketId)
    if playerId <= 0 then return end
    
    SetPlayerRoutingBucket(playerId, bucketId)
    playerCurrentBucket[playerId] = bucketId
    Wait(100)
end

local function ResetPlayerBucket(playerId)
    if playerId <= 0 then return end
    
    SetPlayerRoutingBucket(playerId, 0)
    playerCurrentBucket[playerId] = nil
end

-- ========================================
-- SYNC SÉCURISÉ
-- ========================================
local function SyncAllPlayersInMatch(matchId)
    local match = GetMatchSafe(matchId)
    if not match then 
        DebugWarn('SyncAllPlayersInMatch: match %s invalide', tostring(matchId))
        return 
    end
    
    for i = 1, #match.players do
        local playerId = match.players[i]
        if playerId > 0 and GetPlayerPing(playerId) > 0 then
            local currentBucket = GetPlayerRoutingBucket(playerId)
            if currentBucket ~= match.bucketId then
                SetPlayerBucket(playerId, match.bucketId)
            end
        end
    end
end

RegisterNetEvent('pvp:requestTeammateRefresh', function()
    local src = source
    local matchId = playerCurrentMatch[src]
    
    if not IsMatchValid(matchId) then
        DebugWarn('Joueur %d n\'est pas en match valide', src)
        return
    end
    
    local teammates = GetTeammatesForPlayer(matchId, src)
    
    TriggerClientEvent('pvp:setTeammates', src, teammates)
end)

function GetTeammatesForPlayer(matchId, playerId)
    local match = GetMatchSafe(matchId)
    if not match then 
        return {} 
    end
    
    local playerTeam = match.playerTeams[playerId]
    if not playerTeam then 
        return {} 
    end
    
    local teammates = {}
    local teamPlayers = playerTeam == 'team1' and match.team1 or match.team2
    
    for i = 1, #teamPlayers do
        if teamPlayers[i] ~= playerId and teamPlayers[i] > 0 then
            teammates[#teammates + 1] = teamPlayers[i]
        end
    end
    
    return teammates
end

local function GetRandomArena()
    local arenaKeys = {}
    for key in pairs(Config.Arenas) do
        arenaKeys[#arenaKeys + 1] = key
    end
    
    local randomIndex = math.random(1, #arenaKeys)
    local arenaKey = arenaKeys[randomIndex]
    
    return arenaKey, Config.Arenas[arenaKey]
end

local function BroadcastKillfeed(matchId, killerId, victimId, weaponHash, isHeadshot)
    local match = GetMatchSafe(matchId)
    if not match then return end
    
    local killerName = nil
    local victimName = "Unknown"
    
    if killerId and killerId > 0 then
        killerName = GetPlayerFiveMNameWithID(killerId)
    end
    
    victimName = GetPlayerFiveMNameWithID(victimId)
    
    local weaponName = WEAPON_NAMES[weaponHash] or "Unknown Weapon"
    
    if not killerId or killerId == victimId then
        killerName = nil
        weaponName = "Suicide"
    end
    
    for i = 1, #match.players do
        local playerId = match.players[i]
        if playerId > 0 and GetPlayerPing(playerId) > 0 then
            TriggerClientEvent('pvp:showKillfeed', playerId, killerName, victimName, weaponName, isHeadshot)
        end
    end
end

-- ========================================
-- MATCHMAKING
-- ========================================
RegisterNetEvent('pvp:joinQueue', function(mode)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    local playerDisplayName = GetPlayerFiveMNameWithID(src)
    DebugMatchmaking('%s rejoint queue %s', playerDisplayName, mode)
    
    if playersInQueue[src] then
        TriggerClientEvent('esx:showNotification', src, '~r~Deja en file d\'attente!')
        return
    end
    
    playerLastHeartbeat[src] = GetGameTimer()
    
    local group = exports['pvp_gunfight']:GetPlayerGroup(src)
    local playersToQueue = {}
    local isSoloQueue = false
    
    if group then
        if group.leaderId ~= src then
            TriggerClientEvent('esx:showNotification', src, '~r~Seul le leader peut lancer!')
            return
        end
        
        local playersNeededPerTeam = tonumber(mode:sub(1, 1))
        
        if #group.members ~= playersNeededPerTeam then
            TriggerClientEvent('esx:showNotification', src, 
                string.format('~r~Il faut %d joueur(s) pour le mode %s!', playersNeededPerTeam, mode))
            return
        end
        
        local allReady = true
        for memberId, isReady in pairs(group.ready) do
            if not isReady then
                allReady = false
                break
            end
        end
        
        if not allReady then
            TriggerClientEvent('esx:showNotification', src, '~r~Tous les membres doivent etre prets!')
            return
        end
        
        for i = 1, #group.members do
            playersToQueue[#playersToQueue + 1] = group.members[i]
            playerLastHeartbeat[group.members[i]] = GetGameTimer()
        end
        
        isSoloQueue = false
    else
        if mode ~= '1v1' then
            TriggerClientEvent('esx:showNotification', src, '~r~Creez un groupe pour les modes 2v2+!')
            return
        end
        playersToQueue[1] = src
        isSoloQueue = true
    end
    
    -- Ajout des joueurs en queue
    for i = 1, #playersToQueue do
        local playerId = playersToQueue[i]
        queues[mode][#queues[mode] + 1] = playerId
        playersInQueue[playerId] = {
            mode = mode,
            startTime = os.time(),
            groupMembers = playersToQueue,
            isSolo = isSoloQueue
        }
        
        TriggerClientEvent('pvp:searchStarted', playerId, mode)
        TriggerClientEvent('esx:showNotification', playerId, '~b~Recherche ' .. mode .. '...')
    end
    
    -- ✅ BROADCAST UNIQUEMENT SI CHANGEMENT
    BroadcastQueueStatsIfChanged()
    
    CheckAndCreateMatch(mode)
end)

function CheckAndCreateMatch(mode)
    local playersNeeded = tonumber(mode:sub(1, 1)) * 2
    
    if #queues[mode] >= playersNeeded then
        local matchPlayers = {}
        
        for i = 1, playersNeeded do
            matchPlayers[i] = table.remove(queues[mode], 1)
        end
        
        -- ✅ BROADCAST UNIQUEMENT SI CHANGEMENT (après retrait)
        BroadcastQueueStatsIfChanged()
        
        CreateMatch(mode, matchPlayers)
    end
end

-- ========================================
-- CRÉER MATCH AVEC PROTECTION
-- ========================================
function CreateMatch(mode, players)
    for i = 1, #players do
        if GetPlayerPing(players[i]) <= 0 then
            DebugError('🚨 Joueur %d déconnecté avant création match - ANNULATION', players[i])
            
            for j = 1, #players do
                if j ~= i and GetPlayerPing(players[j]) > 0 then
                    queues[mode][#queues[mode] + 1] = players[j]
                end
            end
            
            BroadcastQueueStatsIfChanged()
            return
        end
    end
    
    local matchId = #activeMatches + 1
    local bucketId = CreateMatchBucket()
    local arenaKey, arena = GetRandomArena()
    
    if not arena then
        DebugError('🚨 Arène introuvable - ANNULATION MATCH')
        for i = 1, #players do
            if GetPlayerPing(players[i]) > 0 then
                queues[mode][#queues[mode] + 1] = players[i]
                playersInQueue[players[i]] = nil
            end
        end
        BroadcastQueueStatsIfChanged()
        return
    end
    
    DebugServer('===== MATCH %d =====', matchId)
    DebugServer('Mode: %s | Joueurs: %d | Arene: %s', mode, #players, arena.name)
    
    local allWereSolo = true
    for i = 1, #players do
        local playerId = players[i]
        if playersInQueue[playerId] and not playersInQueue[playerId].isSolo then
            allWereSolo = false
            break
        end
    end
    
    activeMatches[matchId] = {
        mode = mode,
        players = players,
        arena = arenaKey,
        bucketId = bucketId,
        team1 = {},
        team2 = {},
        playerTeams = {},
        score = {team1 = 0, team2 = 0},
        currentRound = 1,
        status = MATCH_STATE.CREATING,
        startTime = os.time(),
        deadPlayers = {},
        deathProcessed = {},
        wasSoloMatch = allWereSolo,
        -- 🆕 TRACKING DES MORTS POUR DÉTECTION SIMULTANÉE
        roundDeaths = {},
        lastDeathTime = 0
    }
    
    local halfSize = #players / 2
    for i = 1, #players do
        local playerId = players[i]
        
        if GetPlayerPing(playerId) <= 0 then
            DebugError('🚨 Joueur %d déconnecté pendant création - ANNULATION MATCH', playerId)
            CancelMatch(matchId, 'Un joueur s\'est déconnecté')
            return
        end
        
        local team = i <= halfSize and 'team1' or 'team2'
        
        if team == 'team1' then
            activeMatches[matchId].team1[#activeMatches[matchId].team1 + 1] = playerId
        else
            activeMatches[matchId].team2[#activeMatches[matchId].team2 + 1] = playerId
        end
        
        activeMatches[matchId].playerTeams[playerId] = team
        
        if playersInQueue[playerId] then
            playerWasSoloBeforeMatch[playerId] = playersInQueue[playerId].isSolo
        end
        
        playersInQueue[playerId] = nil
        playerCurrentMatch[playerId] = matchId
        playerLastHeartbeat[playerId] = GetGameTimer()
    end
    
    if not GetMatchSafe(matchId) then
        DebugError('🚨 Match %d annulé pendant création', matchId)
        return
    end
    
    for i = 1, #players do
        SetPlayerBucket(players[i], bucketId)
    end
    
    Wait(200)
    
    if not GetMatchSafe(matchId) then
        DebugError('🚨 Match %d annulé après buckets', matchId)
        return
    end
    
    SyncAllPlayersInMatch(matchId)
    
    for i = 1, #players do
        if GetPlayerPing(players[i]) > 0 then
            TriggerClientEvent('pvp:matchFound', players[i])
            TriggerClientEvent('esx:showNotification', players[i], '~g~Match trouve! Arene: ~b~' .. arena.name)
            TriggerClientEvent('pvp:showScoreHUD', players[i], activeMatches[matchId].score, 1)
        end
    end
    
    TeleportPlayersToArena(matchId, activeMatches[matchId], arena, arenaKey)
    
    Wait(3000)
    
    if not GetMatchSafe(matchId) then
        DebugError('🚨 Match %d annulé avant sync final', matchId)
        return
    end
    
    SyncAllPlayersInMatch(matchId)
    
    for i = 1, #players do
        if players[i] > 0 and GetPlayerPing(players[i]) > 0 then
            TriggerClientEvent('pvp:freezePlayer', players[i])
        end
    end
    
    Wait(1000)
    
    local match = GetMatchSafe(matchId)
    if match then
        match.status = MATCH_STATE.STARTING
        StartRound(matchId, match, arena)
    else
        DebugError('🚨 Match %d annulé avant StartRound', matchId)
    end
end

-- ========================================
-- 🔄 FONCTION MODIFIÉE: TÉLÉPORTATION AVEC ÉCHANGE SPAWNS
-- ========================================
function TeleportPlayersToArena(matchId, match, arena, arenaKey)
    if not match then
        DebugError('TeleportPlayersToArena: match nil')
        return
    end
    
    -- 🔄 VÉRIFIER SI ON DOIT ÉCHANGER LES SPAWNS
    local shouldSwap = ShouldSwapSpawns(match.currentRound)
    
    if shouldSwap then
        DebugServer('🔄 Round %d: ÉCHANGE DES SPAWNS (Team1 ↔ Team2)', match.currentRound)
    else
        DebugServer('📍 Round %d: Spawns normaux', match.currentRound)
    end
    
    -- 🔄 TÉLÉPORTER TEAM1
    local team1Spawns = shouldSwap and arena.teamB or arena.teamA
    for i = 1, #match.team1 do
        local playerId = match.team1[i]
        if team1Spawns[i] and playerId > 0 and GetPlayerPing(playerId) > 0 then
            TriggerClientEvent('pvp:teleportToSpawn', playerId, team1Spawns[i], 'team1', matchId, arenaKey)
        end
    end
    
    -- 🔄 TÉLÉPORTER TEAM2
    local team2Spawns = shouldSwap and arena.teamA or arena.teamB
    for i = 1, #match.team2 do
        local playerId = match.team2[i]
        if team2Spawns[i] and playerId > 0 and GetPlayerPing(playerId) > 0 then
            TriggerClientEvent('pvp:teleportToSpawn', playerId, team2Spawns[i], 'team2', matchId, arenaKey)
        end
    end
    
    Wait(1000)
    
    for i = 1, #match.players do
        local playerId = match.players[i]
        if playerId > 0 and GetPlayerPing(playerId) > 0 then
            local teammates = GetTeammatesForPlayer(matchId, playerId)
            TriggerClientEvent('pvp:setTeammates', playerId, teammates)
        end
    end
end

-- CALLBACKS
ESX.RegisterServerCallback('pvp:getPlayerStats', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(nil) return end
    
    MySQL.single('SELECT * FROM pvp_stats WHERE identifier = ?', {xPlayer.identifier}, function(result)
        if result then
            result.name = result.name or xPlayer.getName()
            result.kills = result.kills or 0
            result.deaths = result.deaths or 0
            
            if Config.Discord and Config.Discord.enabled then
                exports['pvp_gunfight']:GetPlayerDiscordAvatarAsync(source, function(avatarUrl)
                    result.avatar = avatarUrl
                    cb(result)
                end)
            else
                result.avatar = Config.Discord.defaultAvatar
                cb(result)
            end
        else
            MySQL.insert('INSERT INTO pvp_stats (identifier, name, kills, deaths) VALUES (?, ?, 0, 0)', 
                {xPlayer.identifier, xPlayer.getName()}, function()
                exports['pvp_gunfight']:InitPlayerModeStats(xPlayer.identifier, xPlayer.getName())
                
                if Config.Discord and Config.Discord.enabled then
                    exports['pvp_gunfight']:GetPlayerDiscordAvatarAsync(source, function(avatarUrl)
                        cb({
                            identifier = xPlayer.identifier,
                            name = xPlayer.getName(),
                            elo = Config.StartingELO,
                            kills = 0, deaths = 0,
                            matches_played = 0, wins = 0, losses = 0,
                            avatar = avatarUrl
                        })
                    end)
                else
                    cb({
                        identifier = xPlayer.identifier,
                        name = xPlayer.getName(),
                        elo = Config.StartingELO,
                        kills = 0, deaths = 0,
                        matches_played = 0, wins = 0, losses = 0,
                        avatar = Config.Discord.defaultAvatar
                    })
                end
            end)
        end
    end)
end)

ESX.RegisterServerCallback('pvp:getPlayerStatsByMode', function(source, cb, mode)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(nil) return end
    
    exports['pvp_gunfight']:GetPlayerStatsByMode(xPlayer.identifier, mode, function(stats)
        if stats then
            stats.name = xPlayer.getName()
            if Config.Discord and Config.Discord.enabled then
                exports['pvp_gunfight']:GetPlayerDiscordAvatarAsync(source, function(avatarUrl)
                    stats.avatar = avatarUrl
                    cb(stats)
                end)
            else
                stats.avatar = Config.Discord.defaultAvatar
                cb(stats)
            end
        else
            cb(nil)
        end
    end)
end)

ESX.RegisterServerCallback('pvp:getPlayerAllModeStats', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(nil) return end
    
    exports['pvp_gunfight']:GetPlayerAllModeStats(xPlayer.identifier, function(statsByMode)
        if Config.Discord and Config.Discord.enabled then
            exports['pvp_gunfight']:GetPlayerDiscordAvatarAsync(source, function(avatarUrl)
                cb({name = xPlayer.getName(), avatar = avatarUrl, modes = statsByMode})
            end)
        else
            cb({name = xPlayer.getName(), avatar = Config.Discord.defaultAvatar, modes = statsByMode})
        end
    end)
end)

ESX.RegisterServerCallback('pvp:getLeaderboard', function(source, cb)
    MySQL.query('SELECT * FROM pvp_stats ORDER BY elo DESC LIMIT 50', {}, function(results)
        for i = 1, #results do
            results[i].kills = results[i].kills or 0
            results[i].deaths = results[i].deaths or 0
            results[i].name = results[i].name or ('Joueur ' .. i)
            results[i].avatar = results[i].discord_avatar or Config.Discord.defaultAvatar
        end
        cb(results)
    end)
end)

ESX.RegisterServerCallback('pvp:getLeaderboardByMode', function(source, cb, mode)
    exports['pvp_gunfight']:GetLeaderboardByMode(mode, 50, function(results)
        cb(results)
    end)
end)

ESX.RegisterServerCallback('pvp:getQueueStats', function(source, cb)
    local stats = GetQueueStats()
    cb(stats)
end)

RegisterNetEvent('pvp:cancelSearch', function()
    local src = source
    
    if not playersInQueue[src] then 
        return 
    end
    
    local queueData = playersInQueue[src]
    local mode = queueData.mode
    local groupMembers = queueData.groupMembers or {src}
    local isSolo = queueData.isSolo
    
    if not isSolo and #groupMembers > 1 then
        local group = exports['pvp_gunfight']:GetPlayerGroup(src)
        
        if group and group.leaderId == src then
            CancelGroupSearch(groupMembers, mode, 'Recherche annulée par le leader')
        else
            TriggerClientEvent('esx:showNotification', src, '~r~Seul le leader peut annuler!')
        end
    else
        for j = #queues[mode], 1, -1 do
            if queues[mode][j] == src then
                table.remove(queues[mode], j)
                break
            end
        end
        
        playersInQueue[src] = nil
        playerLastHeartbeat[src] = nil
        TriggerClientEvent('pvp:searchCancelled', src)
        TriggerClientEvent('esx:showNotification', src, '~y~Recherche annulee')
        
        BroadcastQueueStatsIfChanged()
    end
end)

-- ========================================
-- 🆕 FONCTION MODIFIÉE: GESTION MORT AVEC DÉTECTION SIMULTANÉE
-- ========================================
RegisterNetEvent('pvp:playerDied', function(killerId)
    local victimId = source
    local matchId = playerCurrentMatch[victimId]
    
    if not IsMatchValid(matchId) then 
        return 
    end
    
    local match = GetMatchSafe(matchId)
    if not match then return end
    
    local deathKey = victimId .. '_' .. match.currentRound
    
    if match.deathProcessed[deathKey] then return end
    
    local isFriendlyFire = false
    if killerId then
        local killerTeam = match.playerTeams[killerId]
        local victimTeam = match.playerTeams[victimId]
        if killerTeam and victimTeam and killerTeam == victimTeam then
            isFriendlyFire = true
        end
    end
    
    -- 🆕 ENREGISTRER LA MORT AVEC TIMESTAMP
    local currentTime = GetGameTimer()
    match.roundDeaths[#match.roundDeaths + 1] = {
        victimId = victimId,
        killerId = killerId,
        time = currentTime,
        friendlyFire = isFriendlyFire
    }
    
    match.deathProcessed[deathKey] = true
    match.lastDeathTime = currentTime
    
    -- ⏳ ATTENDRE UN PEU POUR DÉTECTER D'AUTRES MORTS SIMULTANÉES
    Wait(SIMULTANEOUS_DEATH_WINDOW)
    
    -- 🆕 VÉRIFIER SI D'AUTRES MORTS ONT EU LIEU DANS LA FENÊTRE
    local simultaneousDeaths = {}
    for i = 1, #match.roundDeaths do
        local death = match.roundDeaths[i]
        if (currentTime - death.time) <= SIMULTANEOUS_DEATH_WINDOW then
            simultaneousDeaths[#simultaneousDeaths + 1] = death
        end
    end
    
    -- 🔍 ANALYSER LES MORTS SIMULTANÉES
    if #simultaneousDeaths > 1 then
        DebugServer('💥 MORTS SIMULTANÉES DÉTECTÉES: %d morts', #simultaneousDeaths)
        HandlePlayerDeath(matchId, match, victimId, killerId, isFriendlyFire, simultaneousDeaths)
    else
        HandlePlayerDeath(matchId, match, victimId, killerId, isFriendlyFire, nil)
    end
end)

RegisterNetEvent('pvp:playerDiedOutsideZone', function()
    local victimId = source
    local matchId = playerCurrentMatch[victimId]
    
    if not IsMatchValid(matchId) then return end
    
    local match = GetMatchSafe(matchId)
    if not match then return end
    
    local deathKey = victimId .. '_' .. match.currentRound
    
    if match.deathProcessed[deathKey] then return end
    
    match.deathProcessed[deathKey] = true
    HandlePlayerDeath(matchId, match, victimId, nil, false, nil)
end)

-- ========================================
-- 🆕 FONCTION MODIFIÉE: GESTION MORT AVEC TRAITEMENT MORTS SIMULTANÉES
-- ========================================
function HandlePlayerDeath(matchId, match, victimId, killerId, isFriendlyFire, simultaneousDeaths)
    if not match then
        return
    end
    
    if match.status ~= MATCH_STATE.PLAYING then 
        return
    end
    
    match.deadPlayers = match.deadPlayers or {}
    match.deadPlayers[victimId] = true
    
    match.roundStats = match.roundStats or {}
    match.roundStats[#match.roundStats + 1] = {
        victim = victimId,
        killer = killerId,
        time = os.time(),
        friendlyFire = isFriendlyFire
    }
    
    if killerId and killerId ~= victimId and not isFriendlyFire then
        exports['pvp_gunfight']:UpdatePlayerKillsByMode(killerId, 1, match.mode)
    end
    exports['pvp_gunfight']:UpdatePlayerDeathsByMode(victimId, 1, match.mode)
    
    local weaponHash = GetHashKey('WEAPON_PISTOL50')
    local isHeadshot = false
    
    BroadcastKillfeed(matchId, killerId, victimId, weaponHash, isHeadshot)
    
    -- 🆕 SI MORTS SIMULTANÉES, PASSER simultaneousDeaths À CheckRoundEnd
    CheckRoundEnd(matchId, match, simultaneousDeaths)
end

-- ========================================
-- 🆕 FONCTION MODIFIÉE: VÉRIFICATION FIN DE ROUND AVEC MORTS SIMULTANÉES
-- ========================================
function CheckRoundEnd(matchId, match, simultaneousDeaths)
    if not match then
        return
    end
    
    local team1Alive, team2Alive = 0, 0
    
    for i = 1, #match.team1 do
        if not match.deadPlayers[match.team1[i]] then
            team1Alive = team1Alive + 1
        end
    end
    
    for i = 1, #match.team2 do
        if not match.deadPlayers[match.team2[i]] then
            team2Alive = team2Alive + 1
        end
    end
    
    local roundWinner = nil
    local isTie = false
    
    -- 🆕 CAS 1: MORTS SIMULTANÉES DÉTECTÉES
    if simultaneousDeaths and #simultaneousDeaths > 1 then
        DebugServer('🎯 Analyse morts simultanées (%d morts)', #simultaneousDeaths)
        
        -- Compter les morts par équipe
        local team1Deaths = 0
        local team2Deaths = 0
        
        for i = 1, #simultaneousDeaths do
            local death = simultaneousDeaths[i]
            local victimTeam = match.playerTeams[death.victimId]
            
            if victimTeam == 'team1' then
                team1Deaths = team1Deaths + 1
            elseif victimTeam == 'team2' then
                team2Deaths = team2Deaths + 1
            end
        end
        
        DebugServer('📊 Team1 morts: %d | Team2 morts: %d', team1Deaths, team2Deaths)
        
        -- 🆕 SI LES DEUX ÉQUIPES ONT EU DES MORTS SIMULTANÉES = ÉGALITÉ
        if team1Deaths > 0 and team2Deaths > 0 then
            DebugSuccess('⚖️ ÉGALITÉ DÉTECTÉE - Point pour chaque équipe!')
            match.score.team1 = match.score.team1 + 1
            match.score.team2 = match.score.team2 + 1
            isTie = true
            roundWinner = 'tie'
        else
            -- Une seule équipe a eu des morts = victoire de l'autre
            if team1Deaths > 0 then
                match.score.team2 = match.score.team2 + 1
                roundWinner = 'team2'
            elseif team2Deaths > 0 then
                match.score.team1 = match.score.team1 + 1
                roundWinner = 'team1'
            end
        end
    -- CAS 2: PAS DE MORTS SIMULTANÉES - LOGIQUE NORMALE
    elseif team1Alive == 0 and team2Alive > 0 then
        match.score.team2 = match.score.team2 + 1
        roundWinner = 'team2'
    elseif team2Alive == 0 and team1Alive > 0 then
        match.score.team1 = match.score.team1 + 1
        roundWinner = 'team1'
    elseif team1Alive == 0 and team2Alive == 0 then
        -- Tous morts en même temps sans détection précise = chercher dernier kill
        if match.roundStats and #match.roundStats > 0 then
            for i = #match.roundStats, 1, -1 do
                local stat = match.roundStats[i]
                if stat.killer and not stat.friendlyFire then
                    roundWinner = match.playerTeams[stat.killer]
                    break
                end
            end
        end
        
        if roundWinner then
            match.score[roundWinner] = match.score[roundWinner] + 1
        else
            -- Aucun tueur valide trouvé = donner à team1 par défaut
            match.score.team1 = match.score.team1 + 1
            roundWinner = 'team1'
        end
    end
    
    if roundWinner then
        EndRound(matchId, match, roundWinner, isTie)
    end
end

-- ========================================
-- 🆕 FONCTION MODIFIÉE: FIN DE ROUND AVEC SUPPORT ÉGALITÉ
-- ========================================
function EndRound(matchId, match, roundWinner, isTie)
    if not match then
        return
    end
    
    match.status = MATCH_STATE.ROUND_END
    local arena = Config.Arenas[match.arena]
    
    if not arena then
        CancelMatch(matchId, 'Erreur arène')
        return
    end
    
    SyncAllPlayersInMatch(matchId)
    
    -- 🆕 BROADCAST AVEC SUPPORT ÉGALITÉ
    for i = 1, #match.players do
        local playerId = match.players[i]
        if playerId > 0 and GetPlayerPing(playerId) > 0 then
            local playerTeam = match.playerTeams[playerId]
            local isVictory = false
            
            if isTie then
                isVictory = nil -- Égalité
                TriggerClientEvent('esx:showNotification', playerId, '⚖️ ÉGALITÉ - Point pour chaque équipe!')
            else
                isVictory = (roundWinner == playerTeam)
            end
            
            TriggerClientEvent('pvp:roundEnd', playerId, roundWinner, match.score, playerTeam, isVictory)
            TriggerClientEvent('pvp:updateScore', playerId, match.score, match.currentRound)
        end
    end
    
    if match.score.team1 >= Config.MaxRounds or match.score.team2 >= Config.MaxRounds then
        EndMatch(matchId, match)
    else
        Wait(3000)
        
        if not GetMatchSafe(matchId) then
            return
        end
        
        match.currentRound = match.currentRound + 1
        match.deadPlayers = {}
        match.deathProcessed = {}
        match.roundDeaths = {} -- 🆕 Réinitialiser le tracking des morts
        match.lastDeathTime = 0
        
        SyncAllPlayersInMatch(matchId)
        
        for i = 1, #match.players do
            if match.players[i] > 0 and GetPlayerPing(match.players[i]) > 0 then
                TriggerClientEvent('pvp:freezePlayer', match.players[i])
            end
        end
        
        Wait(500)
        RespawnPlayers(matchId, match, arena)
        Wait(2000)
        
        if not GetMatchSafe(matchId) then
            return
        end
        
        SyncAllPlayersInMatch(matchId)
        StartRound(matchId, match, arena)
    end
end

-- ========================================
-- 🔄 FONCTION MODIFIÉE: RESPAWN AVEC ÉCHANGE SPAWNS
-- ========================================
function RespawnPlayers(matchId, match, arena)
    if not match then
        return
    end
    
    if not arena then
        return
    end
    
    -- 🔄 VÉRIFIER SI ON DOIT ÉCHANGER LES SPAWNS
    local shouldSwap = ShouldSwapSpawns(match.currentRound)
    
    -- 🔄 RESPAWN TEAM1
    local team1Spawns = shouldSwap and arena.teamB or arena.teamA
    for i = 1, #match.team1 do
        if team1Spawns[i] and match.team1[i] > 0 and GetPlayerPing(match.team1[i]) > 0 then
            TriggerClientEvent('pvp:respawnPlayer', match.team1[i], team1Spawns[i])
        end
    end
    
    -- 🔄 RESPAWN TEAM2
    local team2Spawns = shouldSwap and arena.teamA or arena.teamB
    for i = 1, #match.team2 do
        if team2Spawns[i] and match.team2[i] > 0 and GetPlayerPing(match.team2[i]) > 0 then
            TriggerClientEvent('pvp:respawnPlayer', match.team2[i], team2Spawns[i])
        end
    end
end

function StartRound(matchId, match, arena)
    if not match then
        return
    end
    
    if not arena then
        CancelMatch(matchId, 'Erreur arène')
        return
    end
    
    if match.status == MATCH_STATE.CANCELLED or match.status == MATCH_STATE.FINISHED then
        return
    end
    
    match.status = MATCH_STATE.PLAYING
    match.roundStats = {}
    match.deadPlayers = {}
    match.deathProcessed = {}
    match.roundDeaths = {} -- 🆕 Réinitialiser le tracking des morts
    match.lastDeathTime = 0
    
    SyncAllPlayersInMatch(matchId)
    
    for i = 1, #match.players do
        if match.players[i] > 0 and GetPlayerPing(match.players[i]) > 0 then
            TriggerClientEvent('pvp:roundStart', match.players[i], match.currentRound)
            TriggerClientEvent('pvp:updateScore', match.players[i], match.score, match.currentRound)
        end
    end
end

function EndMatch(matchId, match)
    if not match then
        return
    end
    
    match.status = MATCH_STATE.FINISHING
    
    local winningTeam = match.score.team1 > match.score.team2 and 'team1' or 'team2'
    local winners = winningTeam == 'team1' and match.team1 or match.team2
    local losers = winningTeam == 'team1' and match.team2 or match.team1
    
    if match.mode == '1v1' then
        exports['pvp_gunfight']:UpdatePlayerElo1v1ByMode(winners[1], losers[1], match.score, match.mode)
    else
        exports['pvp_gunfight']:UpdateTeamEloByMode(winners, losers, match.score, match.mode)
    end
    
    for i = 1, #winners do
        if winners[i] > 0 and GetPlayerPing(winners[i]) > 0 then
            TriggerClientEvent('pvp:matchEnd', winners[i], true, match.score, match.playerTeams[winners[i]])
            TriggerClientEvent('pvp:hideScoreHUD', winners[i])
            playerCurrentMatch[winners[i]] = nil
            playerLastHeartbeat[winners[i]] = nil
        end
    end
    
    for i = 1, #losers do
        if losers[i] > 0 and GetPlayerPing(losers[i]) > 0 then
            TriggerClientEvent('pvp:matchEnd', losers[i], false, match.score, match.playerTeams[losers[i]])
            TriggerClientEvent('pvp:hideScoreHUD', losers[i])
            playerCurrentMatch[losers[i]] = nil
            playerLastHeartbeat[losers[i]] = nil
        end
    end
    
    Wait(8000)
    
    for i = 1, #match.players do
        ResetPlayerBucket(match.players[i])
    end
    
    exports['pvp_gunfight']:RestoreGroupsAfterMatch(match.players, match.wasSoloMatch)
    
    for i = 1, #match.players do
        playerWasSoloBeforeMatch[match.players[i]] = nil
    end
    
    Wait(2000)
    
    match.status = MATCH_STATE.FINISHED
    activeMatches[matchId] = nil
end

function HandlePlayerDisconnect(playerId)
    ResetPlayerBucket(playerId)
    playerWasSoloBeforeMatch[playerId] = nil
    playerLastHeartbeat[playerId] = nil
    
    local matchId = playerCurrentMatch[playerId]
    if not IsMatchValid(matchId) then return end
    
    local match = GetMatchSafe(matchId)
    if not match then return end
    
    local quitterTeam = match.playerTeams[playerId]
    if not quitterTeam then return end
    
    local winningTeam = quitterTeam == 'team1' and 'team2' or 'team1'
    local winners = winningTeam == 'team1' and match.team1 or match.team2
    local losers = winningTeam == 'team1' and match.team2 or match.team1
    
    local forfeitScore = {
        team1 = winningTeam == 'team1' and Config.MaxRounds or 0,
        team2 = winningTeam == 'team2' and Config.MaxRounds or 0
    }
    
    if match.mode == '1v1' then
        if #winners > 0 and #losers > 0 then
            exports['pvp_gunfight']:UpdatePlayerElo1v1ByMode(winners[1], losers[1], forfeitScore, match.mode)
        end
    else
        exports['pvp_gunfight']:UpdateTeamEloByMode(winners, losers, forfeitScore, match.mode)
    end
    
    for i = 1, #match.players do
        local pid = match.players[i]
        if pid > 0 and GetPlayerPing(pid) > 0 and pid ~= playerId then
            local playerTeam = match.playerTeams[pid]
            local isWinner = (playerTeam == winningTeam)
            
            if isWinner then
                TriggerClientEvent('esx:showNotification', pid, '~g~🏆 VICTOIRE par abandon adverse!')
                TriggerClientEvent('pvp:matchEnd', pid, true, forfeitScore, playerTeam)
            else
                TriggerClientEvent('esx:showNotification', pid, '~r~❌ DÉFAITE - Un coéquipier a quitté!')
                TriggerClientEvent('pvp:matchEnd', pid, false, forfeitScore, playerTeam)
            end
            
            TriggerClientEvent('pvp:hideScoreHUD', pid)
            
            playerCurrentMatch[pid] = nil
            playerLastHeartbeat[pid] = nil
            ResetPlayerBucket(pid)
            playerWasSoloBeforeMatch[pid] = nil
        end
    end
    
    Wait(3000)
    
    local remainingPlayers = {}
    for i = 1, #match.players do
        if match.players[i] > 0 and GetPlayerPing(match.players[i]) > 0 and match.players[i] ~= playerId then
            remainingPlayers[#remainingPlayers + 1] = match.players[i]
        end
    end
    
    if #remainingPlayers > 0 then
        exports['pvp_gunfight']:RestoreGroupsAfterMatch(remainingPlayers, match.wasSoloMatch)
    end
    
    match.status = MATCH_STATE.FINISHED
    activeMatches[matchId] = nil
    playerCurrentMatch[playerId] = nil
end

AddEventHandler('playerDropped', function()
    local src = source
    
    HandlePlayerDisconnectFromQueue(src)
    HandlePlayerDisconnect(src)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for matchId, match in pairs(activeMatches) do
        for i = 1, #match.players do
            local playerId = match.players[i]
            if playerId > 0 and GetPlayerPing(playerId) > 0 then
                TriggerClientEvent('pvp:hideScoreHUD', playerId)
                TriggerClientEvent('pvp:disableZones', playerId)
                TriggerClientEvent('pvp:onResourceStop', playerId)
                ResetPlayerBucket(playerId)
                playerWasSoloBeforeMatch[playerId] = nil
                playerLastHeartbeat[playerId] = nil
            end
        end
    end
    
    for mode, queue in pairs(queues) do
        for i = 1, #queue do
            if queue[i] > 0 and GetPlayerPing(queue[i]) > 0 then
                TriggerClientEvent('pvp:searchCancelled', queue[i])
                playerLastHeartbeat[queue[i]] = nil
            end
        end
        queues[mode] = {}
    end
end)

local function ForcePlayerToLobby(playerId)
    if not playerId or playerId <= 0 or GetPlayerPing(playerId) <= 0 then
        return false
    end
    
    ResetPlayerBucket(playerId)
    playerWasSoloBeforeMatch[playerId] = nil
    playerLastHeartbeat[playerId] = nil
    
    local matchId = playerCurrentMatch[playerId]
    if matchId then
        playerCurrentMatch[playerId] = nil
    end
    
    if playersInQueue[playerId] then
        local queueData = playersInQueue[playerId]
        for i = #queues[queueData.mode], 1, -1 do
            if queues[queueData.mode][i] == playerId then
                table.remove(queues[queueData.mode], i)
                break
            end
        end
        playersInQueue[playerId] = nil
        TriggerClientEvent('pvp:searchCancelled', playerId)
        
        BroadcastQueueStatsIfChanged()
    end
    
    TriggerClientEvent('pvp:hideScoreHUD', playerId)
    TriggerClientEvent('pvp:forceReturnToLobby', playerId)
    
    return true
end

RegisterCommand('pvpforcelobby', function(source, args)
    if not exports['pvp_gunfight']:IsPlayerAdmin(source) then
        if source > 0 then
            TriggerClientEvent('esx:showNotification', source, '~r~Permission refusée')
        else
            print('[PVP] Cette commande nécessite les permissions admin')
        end
        return
    end
    
    local targetId = tonumber(args[1])
    if not targetId then
        if source > 0 then
            TriggerClientEvent('esx:showNotification', source, '~r~Usage: /pvpforcelobby [player_id]')
        else
            print('[PVP] Usage: pvpforcelobby [player_id]')
        end
        return
    end
    
    if ForcePlayerToLobby(targetId) then
        local msg = '✅ Joueur ' .. targetId .. ' forcé au lobby'
        if source > 0 then
            TriggerClientEvent('esx:showNotification', source, '~g~' .. msg)
        else
            print('[PVP] ' .. msg)
        end
    else
        local msg = '❌ Impossible de forcer joueur ' .. targetId
        if source > 0 then
            TriggerClientEvent('esx:showNotification', source, '~r~' .. msg)
        else
            print('[PVP] ' .. msg)
        end
    end
end, false)

RegisterCommand('pvpkickall', function(source)
    if not exports['pvp_gunfight']:IsPlayerAdmin(source) then
        if source > 0 then
            TriggerClientEvent('esx:showNotification', source, '~r~Permission refusée')
        else
            print('[PVP] Cette commande nécessite les permissions admin')
        end
        return
    end
    
    local kickedCount = 0
    
    for _, match in pairs(activeMatches) do
        for i = 1, #match.players do
            if match.players[i] > 0 and GetPlayerPing(match.players[i]) > 0 then
                ForcePlayerToLobby(match.players[i])
                kickedCount = kickedCount + 1
            end
        end
    end
    
    activeMatches = {}
    
    for mode, queue in pairs(queues) do
        for i = 1, #queue do
            if queue[i] > 0 and GetPlayerPing(queue[i]) > 0 then
                TriggerClientEvent('pvp:searchCancelled', queue[i])
                kickedCount = kickedCount + 1
            end
        end
        queues[mode] = {}
    end
    
    playersInQueue = {}
    playerCurrentMatch = {}
    playerWasSoloBeforeMatch = {}
    playerLastHeartbeat = {}
    
    BroadcastQueueStatsIfChanged()
    
    local msg = kickedCount .. ' joueurs forcés au lobby'
    if source > 0 then
        TriggerClientEvent('esx:showNotification', source, '~g~' .. msg)
    else
        print('[PVP] ' .. msg)
    end
end, false)

RegisterCommand('pvpstatus', function(source)
    if not exports['pvp_gunfight']:IsPlayerAdmin(source) then
        if source > 0 then
            TriggerClientEvent('esx:showNotification', source, '~r~Permission refusée')
        else
            print('[PVP] Cette commande nécessite les permissions admin')
        end
        return
    end
    
    local matchCount = 0
    local playersInMatchCount = 0
    
    for _, match in pairs(activeMatches) do
        matchCount = matchCount + 1
        playersInMatchCount = playersInMatchCount + #match.players
    end
    
    local totalInQueue = 0
    for _, queue in pairs(queues) do
        totalInQueue = totalInQueue + #queue
    end
    
    local msg1 = 'Matchs: ' .. matchCount .. ' | En jeu: ' .. playersInMatchCount .. ' | En queue: ' .. totalInQueue
    if source > 0 then
        TriggerClientEvent('esx:showNotification', source, '~b~' .. msg1)
    else
        print('[PVP] ' .. msg1)
    end
    
    local stats = GetQueueStats()
    local msg2 = 'Stats queues: 1v1=' .. stats['1v1'] .. ', 2v2=' .. stats['2v2'] .. ', 3v3=' .. stats['3v3'] .. ', 4v4=' .. stats['4v4']
    if source > 0 then
        TriggerClientEvent('esx:showNotification', source, '~b~' .. msg2)
    else
        print('[PVP] ' .. msg2)
    end
end, false)

DebugSuccess('Systeme PVP charge (VERSION 4.13.0 - MORTS SIMULTANÉES + ÉCHANGE SPAWNS)')
