-- ================================================================================================
-- GUNFIGHT ARENA - SERVER v4.2 OPTIMISÉ + KILL FEED ID + NOM FIVEM
-- ================================================================================================
-- ✅ Réduction des logs en production
-- ✅ Optimisation des requêtes SQL avec cache
-- ✅ Throttling des updates
-- ✅ FIX v4.2: Notifications kill streak uniquement (sans notification bank standard)
-- ✅ NOUVEAU: Kill feed avec ID joueur + Nom FiveM
-- ================================================================================================

local ESX = exports['es_extended']:getSharedObject()

-- Tables de suivi
local arenaPlayers = {}
local playerZone = {}
local playerBucket = {}
local zonePlayerCounts = {[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0,[10]=0}
local PlayerStats = {}
local killStreaks = {}
local playerJoinTime = {}
local globalLeaderboard = {}
local lastLeaderboardUpdate = 0

-- Stats de session par zone
local zoneSessionStats = {
    [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {}, [6] = {}, [7] = {}, [8] = {}, [9] = {}, [10] = {}
}

-- ================================================================================================
-- FONCTION : LOG DEBUG SERVER (Conditionnel)
-- ================================================================================================
local function DebugLog(message, logType)
    if not Config.DebugServer then return end
    
    local prefixes = {
        error = "^1[GF-Server ERROR]^0",
        success = "^2[GF-Server OK]^0",
        instance = "^5[GF-Instance]^0",
        database = "^6[GF-Database]^0"
    }
    
    print((prefixes[logType] or "^3[GF-Server]^0") .. " " .. message)
end

-- ================================================================================================
-- ✅ NOUVELLE FONCTION : OBTENIR LE NOM FIVEM DU JOUEUR
-- ================================================================================================
local function GetFiveMName(playerId)
    return GetPlayerName(playerId) or "Joueur Inconnu"
end

-- ================================================================================================
-- ✅ NOUVELLE FONCTION : FORMATER LE NOM POUR LE KILL FEED (ID + Nom FiveM)
-- ================================================================================================
local function FormatKillFeedName(playerId)
    local fivemName = GetFiveMName(playerId)
    return "[" .. playerId .. "] " .. fivemName
end

-- ================================================================================================
-- FONCTION : CHARGER LES STATS DU JOUEUR
-- ================================================================================================
local function LoadPlayerStats(identifier, playerName, callback)
    if not Config.SaveStatsToDatabase then
        callback({kills=0,deaths=0,headshots=0,best_streak=0,total_playtime=0})
        return
    end
    
    MySQL.Async.fetchAll('SELECT * FROM gunfight_stats WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if result[1] then
            if playerName and result[1].player_name ~= playerName then
                MySQL.Async.execute('UPDATE gunfight_stats SET player_name = @name WHERE identifier = @identifier', {
                    ['@name'] = playerName,
                    ['@identifier'] = identifier
                })
            end
            callback(result[1])
        else
            MySQL.Async.execute('INSERT INTO gunfight_stats (identifier, player_name, kills, deaths, headshots, best_streak, total_playtime) VALUES (@identifier, @name, 0, 0, 0, 0, 0)', {
                ['@identifier'] = identifier,
                ['@name'] = playerName or 'Joueur Inconnu'
            }, function()
                callback({kills=0,deaths=0,headshots=0,best_streak=0,total_playtime=0})
            end)
        end
    end)
end

-- ================================================================================================
-- FONCTION : SAUVEGARDER LES STATS DU JOUEUR
-- ================================================================================================
local function SavePlayerStats(identifier, playerName, stats)
    if not Config.SaveStatsToDatabase then return end
    
    MySQL.Async.execute([[
        UPDATE gunfight_stats 
        SET player_name = @name, kills = @kills, deaths = @deaths, 
            headshots = @headshots, best_streak = @best_streak, 
            total_playtime = @total_playtime, last_played = NOW()
        WHERE identifier = @identifier
    ]], {
        ['@identifier'] = identifier,
        ['@name'] = playerName or 'Joueur Inconnu',
        ['@kills'] = stats.kills,
        ['@deaths'] = stats.deaths,
        ['@headshots'] = stats.headshots or 0,
        ['@best_streak'] = stats.best_streak or 0,
        ['@total_playtime'] = stats.total_playtime or 0
    })
end

-- ================================================================================================
-- FONCTION : OBTENIR LE CLASSEMENT GLOBAL
-- ================================================================================================
local function GetGlobalLeaderboard(callback)
    if not Config.SaveStatsToDatabase then
        callback({})
        return
    end
    
    MySQL.Async.fetchAll([[
        SELECT identifier, player_name, kills, deaths, headshots, best_streak,
            CASE WHEN deaths > 0 THEN ROUND(kills / deaths, 2) ELSE kills END as kd_ratio
        FROM gunfight_stats
        ORDER BY kd_ratio DESC, kills DESC
        LIMIT @limit
    ]], {
        ['@limit'] = Config.LeaderboardLimit
    }, function(result)
        local leaderboard = {}
        
        for i, data in ipairs(result) do
            table.insert(leaderboard, {
                rank = i,
                player = data.player_name or "Joueur Inconnu",
                kills = data.kills,
                deaths = data.deaths,
                headshots = data.headshots,
                best_streak = data.best_streak,
                kd = data.kd_ratio
            })
        end
        
        callback(leaderboard)
    end)
end

-- ================================================================================================
-- FONCTION : METTRE À JOUR LE CLASSEMENT GLOBAL
-- ================================================================================================
local function UpdateGlobalLeaderboard()
    GetGlobalLeaderboard(function(leaderboard)
        globalLeaderboard = leaderboard
        lastLeaderboardUpdate = os.time()
    end)
end

-- ================================================================================================
-- FONCTION : OBTENIR LES STATS D'UN JOUEUR
-- ================================================================================================
function GetPlayerStats(id)
    if not PlayerStats[id] then
        PlayerStats[id] = {
            kills = 0,
            deaths = 0,
            headshots = 0,
            best_streak = 0,
            total_playtime = 0
        }
        
        if Config.SaveStatsToDatabase then
            local xPlayer = ESX.GetPlayerFromId(id)
            if xPlayer then
                LoadPlayerStats(xPlayer.identifier, xPlayer.getName(), function(dbStats)
                    PlayerStats[id].kills = dbStats.kills
                    PlayerStats[id].deaths = dbStats.deaths
                    PlayerStats[id].headshots = dbStats.headshots or 0
                    PlayerStats[id].best_streak = dbStats.best_streak or 0
                    PlayerStats[id].total_playtime = dbStats.total_playtime or 0
                end)
            end
        end
    end
    return PlayerStats[id]
end

-- ================================================================================================
-- FONCTION : GÉRER LES INSTANCES (ROUTING BUCKETS)
-- ================================================================================================
local function SetPlayerInstance(source, bucketId)
    if not Config.UseInstances then return end
    
    SetPlayerRoutingBucket(source, bucketId)
    local playerPed = GetPlayerPed(source)
    SetEntityRoutingBucket(playerPed, bucketId)
    playerBucket[source] = bucketId
    
    DebugLog("Joueur " .. source .. " -> bucket " .. bucketId, "instance")
end

local function RemovePlayerFromInstance(source)
    if not Config.UseInstances then return end
    SetPlayerInstance(source, Config.LobbyBucket)
end

-- ================================================================================================
-- FONCTION : METTRE À JOUR LE NOMBRE DE JOUEURS PAR ZONE
-- ================================================================================================
local function updateZonePlayers()
    local zonesData = {}
    for i = 1, 10 do
        local zoneCfg = Config["Zone" .. i]
        if zoneCfg and zoneCfg.enabled then
            table.insert(zonesData, {
                zone = i,
                players = zonePlayerCounts[i] or 0,
                maxPlayers = zoneCfg.maxPlayers or 15
            })
        end
    end
    TriggerClientEvent('gunfightarena:updateZonePlayers', -1, zonesData)
end

-- ================================================================================================
-- COMMANDE : QUITTER L'ARÈNE
-- ================================================================================================
RegisterCommand(Config.ExitCommand, function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    if arenaPlayers[source] then
        if playerJoinTime[source] and Config.SaveStatsToDatabase then
            local playTime = os.time() - playerJoinTime[source]
            local stats = GetPlayerStats(source)
            stats.total_playtime = (stats.total_playtime or 0) + playTime
            SavePlayerStats(xPlayer.identifier, xPlayer.getName(), stats)
        end
        
        arenaPlayers[source] = nil
        local zone = playerZone[source]
        
        if zone then
            zonePlayerCounts[zone] = math.max((zonePlayerCounts[zone] or 1) - 1, 0)
            zoneSessionStats[zone][source] = nil
            playerZone[source] = nil
        end
        
        RemovePlayerFromInstance(source)
        killStreaks[source] = 0
        playerJoinTime[source] = nil
        updateZonePlayers()
        
        TriggerClientEvent('gunfightarena:exit', source)
    end
end, false)

-- ================================================================================================
-- EVENT : SORTIE DE ZONE
-- ================================================================================================
RegisterNetEvent('gunfightarena:leaveArena')
AddEventHandler('gunfightarena:leaveArena', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer or not arenaPlayers[src] then return end
    
    if playerJoinTime[src] and Config.SaveStatsToDatabase then
        local playTime = os.time() - playerJoinTime[src]
        local stats = GetPlayerStats(src)
        stats.total_playtime = (stats.total_playtime or 0) + playTime
        SavePlayerStats(xPlayer.identifier, xPlayer.getName(), stats)
    end
    
    arenaPlayers[src] = nil
    local zone = playerZone[src]
    
    if zone then
        zonePlayerCounts[zone] = math.max((zonePlayerCounts[zone] or 1) - 1, 0)
        zoneSessionStats[zone][src] = nil
        playerZone[src] = nil
    end
    
    RemovePlayerFromInstance(src)
    killStreaks[src] = 0
    playerJoinTime[src] = nil
    updateZonePlayers()
    
    DebugLog("Joueur " .. src .. " sorti de l'arène", "success")
end)

-- ================================================================================================
-- EVENT : DEMANDE DE REJOINDRE UNE ZONE
-- ================================================================================================
RegisterNetEvent('gunfightarena:joinRequest')
AddEventHandler('gunfightarena:joinRequest', function(zoneNumber)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    
    local zoneCfg = Config["Zone" .. zoneNumber]
    if not zoneCfg or not zoneCfg.enabled then
        TriggerClientEvent('esx:showNotification', src, "Zone non disponible.")
        return
    end
    
    local maxPlayers = zoneCfg.maxPlayers or 15
    if zonePlayerCounts[zoneNumber] >= maxPlayers then
        TriggerClientEvent('esx:showNotification', src, Config.Messages.arenaFull)
        return
    end
    
    -- Nettoyage ancienne zone si nécessaire
    if playerZone[src] then
        local oldZone = playerZone[src]
        zonePlayerCounts[oldZone] = math.max((zonePlayerCounts[oldZone] or 1) - 1, 0)
        zoneSessionStats[oldZone][src] = nil
    end
    
    arenaPlayers[src] = true
    playerZone[src] = zoneNumber
    zonePlayerCounts[zoneNumber] = (zonePlayerCounts[zoneNumber] or 0) + 1
    playerJoinTime[src] = os.time()
    
    zoneSessionStats[zoneNumber][src] = {
        kills = 0,
        deaths = 0,
        streak = 0
    }
    
    if Config.UseInstances then
        local bucketId = Config.ZoneBuckets[zoneNumber]
        if bucketId then
            SetPlayerInstance(src, bucketId)
        end
    end
    
    GetPlayerStats(src)
    killStreaks[src] = 0
    updateZonePlayers()
    
    TriggerClientEvent('gunfightarena:join', src, zoneNumber)
end)

-- ================================================================================================
-- ✅ EVENT : MORT DU JOUEUR (MODIFIÉ - Kill feed avec ID + Nom FiveM)
-- ================================================================================================
RegisterNetEvent('gunfightarena:playerDied')
AddEventHandler('gunfightarena:playerDied', function(respawnIndex, killerId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    
    local stats = GetPlayerStats(src)
    stats.deaths = stats.deaths + 1
    killStreaks[src] = 0
    
    local zone = playerZone[src]
    if zone and zoneSessionStats[zone] and zoneSessionStats[zone][src] then
        zoneSessionStats[zone][src].deaths = zoneSessionStats[zone][src].deaths + 1
        zoneSessionStats[zone][src].streak = 0
    end
    
    if Config.SaveStatsToDatabase then
        SavePlayerStats(xPlayer.identifier, xPlayer.getName(), stats)
    end
    
    TriggerClientEvent('gunfightarena:join', src, 0)
    
    -- Traitement du killer
    if killerId and killerId ~= src then
        local killer = ESX.GetPlayerFromId(killerId)
        
        if killer then
            killStreaks[killerId] = (killStreaks[killerId] or 0) + 1
            
            local killerStats = GetPlayerStats(killerId)
            killerStats.kills = killerStats.kills + 1
            
            if killStreaks[killerId] > killerStats.best_streak then
                killerStats.best_streak = killStreaks[killerId]
            end
            
            local killerZone = playerZone[killerId]
            if killerZone and zoneSessionStats[killerZone] and zoneSessionStats[killerZone][killerId] then
                zoneSessionStats[killerZone][killerId].kills = zoneSessionStats[killerZone][killerId].kills + 1
                zoneSessionStats[killerZone][killerId].streak = killStreaks[killerId]
            end
            
            if Config.SaveStatsToDatabase then
                SavePlayerStats(killer.identifier, killer.getName(), killerStats)
            end
            
            -- Récompense SANS notification (silencieux)
            local reward = Config.RewardAmount
            killer.addAccountMoney(Config.RewardAccount, reward)
            
            -- Notification UNIQUEMENT pour les kill streaks
            if Config.KillStreakBonus.enabled then
                local bonus = Config.KillStreakBonus[killStreaks[killerId]]
                if bonus then
                    killer.addAccountMoney(Config.RewardAccount, bonus)
                    TriggerClientEvent('esx:showNotification', killerId, "~g~KILL STREAK x" .. killStreaks[killerId] .. "! ~w~Bonus: ~g~$" .. bonus)
                end
            end
            
            -- ✅ KILL FEED MODIFIÉ : Utiliser ID + Nom FiveM au lieu du nom du personnage
            local killerDisplayName = FormatKillFeedName(killerId)
            local victimDisplayName = FormatKillFeedName(src)
            
            TriggerClientEvent('gunfightarena:killFeed', -1, 
                killerDisplayName,  -- Format: [ID] Nom FiveM
                victimDisplayName,  -- Format: [ID] Nom FiveM
                false, 
                killStreaks[killerId], 
                killerId
            )
            
            DebugLog("Kill feed: " .. killerDisplayName .. " -> " .. victimDisplayName, "success")
        end
    end
end)

-- ================================================================================================
-- EVENT : DÉCONNEXION DU JOUEUR
-- ================================================================================================
AddEventHandler('playerDropped', function(reason)
    local src = source
    
    if arenaPlayers[src] then
        local xPlayer = ESX.GetPlayerFromId(src)
        
        if playerJoinTime[src] and Config.SaveStatsToDatabase and xPlayer then
            local playTime = os.time() - playerJoinTime[src]
            local stats = GetPlayerStats(src)
            stats.total_playtime = (stats.total_playtime or 0) + playTime
            SavePlayerStats(xPlayer.identifier, xPlayer.getName(), stats)
        end
        
        local zone = playerZone[src]
        if zone then
            zonePlayerCounts[zone] = math.max((zonePlayerCounts[zone] or 1) - 1, 0)
            zoneSessionStats[zone][src] = nil
        end
        
        -- Nettoyage
        arenaPlayers[src] = nil
        playerZone[src] = nil
        playerBucket[src] = nil
        killStreaks[src] = nil
        playerJoinTime[src] = nil
        PlayerStats[src] = nil
        
        updateZonePlayers()
    end
end)

-- ================================================================================================
-- EVENT : STATS DE ZONE (TOUCHE G)
-- ================================================================================================
RegisterNetEvent('gunfightarena:getZoneStats')
AddEventHandler('gunfightarena:getZoneStats', function(zoneNumber)
    local src = source
    
    if not arenaPlayers[src] or not zoneNumber then return end
    
    local leaderboard = {}
    
    if zoneSessionStats[zoneNumber] then
        for playerId, sessionStats in pairs(zoneSessionStats[zoneNumber]) do
            local xPlayer = ESX.GetPlayerFromId(playerId)
            if xPlayer then
                local kd = sessionStats.deaths > 0 and (sessionStats.kills / sessionStats.deaths) or sessionStats.kills
                
                table.insert(leaderboard, {
                    player = xPlayer.getName(),
                    kills = sessionStats.kills,
                    deaths = sessionStats.deaths,
                    kd = kd
                })
            end
        end
    end
    
    table.sort(leaderboard, function(a, b)
        if a.kd == b.kd then return a.kills > b.kills end
        return a.kd > b.kd
    end)
    
    TriggerClientEvent('gunfightarena:statsData', src, leaderboard)
end)

-- ================================================================================================
-- EVENT : STATS PERSONNELLES
-- ================================================================================================
RegisterNetEvent('gunfightarena:getPersonalStats')
AddEventHandler('gunfightarena:getPersonalStats', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    
    if Config.SaveStatsToDatabase then
        LoadPlayerStats(xPlayer.identifier, xPlayer.getName(), function(dbStats)
            local sessionStats = GetPlayerStats(src)
            TriggerClientEvent('gunfightarena:personalStatsData', src, {
                player = xPlayer.getName(),
                kills = dbStats.kills,
                deaths = dbStats.deaths,
                headshots = dbStats.headshots,
                best_streak = dbStats.best_streak,
                total_playtime = dbStats.total_playtime,
                kd = (dbStats.deaths > 0 and (dbStats.kills / dbStats.deaths) or dbStats.kills),
                current_streak = killStreaks[src] or 0,
                session_kills = sessionStats.kills - dbStats.kills,
                session_deaths = sessionStats.deaths - dbStats.deaths
            })
        end)
    else
        local stats = GetPlayerStats(src)
        TriggerClientEvent('gunfightarena:personalStatsData', src, {
            player = xPlayer.getName(),
            kills = stats.kills,
            deaths = stats.deaths,
            headshots = stats.headshots or 0,
            best_streak = stats.best_streak or 0,
            total_playtime = 0,
            kd = (stats.deaths > 0 and (stats.kills / stats.deaths) or stats.kills),
            current_streak = killStreaks[src] or 0,
            session_kills = stats.kills,
            session_deaths = stats.deaths
        })
    end
end)

-- ================================================================================================
-- EVENT : CLASSEMENT GLOBAL
-- ================================================================================================
RegisterNetEvent('gunfightarena:getGlobalLeaderboard')
AddEventHandler('gunfightarena:getGlobalLeaderboard', function()
    local src = source
    
    if os.time() - lastLeaderboardUpdate > Config.LeaderboardUpdateInterval then
        UpdateGlobalLeaderboard()
        Citizen.Wait(500)
    end
    
    if #globalLeaderboard > 0 then
        TriggerClientEvent('gunfightarena:globalLeaderboardData', src, globalLeaderboard)
    else
        GetGlobalLeaderboard(function(leaderboard)
            TriggerClientEvent('gunfightarena:globalLeaderboardData', src, leaderboard)
        end)
    end
end)

-- ================================================================================================
-- EVENT : CLASSEMENT LOBBY
-- ================================================================================================
RegisterNetEvent('gunfightarena:getLobbyScoreboard')
AddEventHandler('gunfightarena:getLobbyScoreboard', function()
    local src = source
    
    if os.time() - lastLeaderboardUpdate > Config.LeaderboardUpdateInterval then
        UpdateGlobalLeaderboard()
        Citizen.Wait(500)
    end
    
    if #globalLeaderboard > 0 then
        TriggerClientEvent('gunfightarena:lobbyScoreboardData', src, globalLeaderboard)
    else
        GetGlobalLeaderboard(function(leaderboard)
            TriggerClientEvent('gunfightarena:lobbyScoreboardData', src, leaderboard)
        end)
    end
end)

-- ================================================================================================
-- EVENT : MISE À JOUR DES ZONES
-- ================================================================================================
RegisterNetEvent('gunfightarena:requestZoneUpdate')
AddEventHandler('gunfightarena:requestZoneUpdate', function()
    updateZonePlayers()
end)

-- ================================================================================================
-- THREAD : MISE À JOUR AUTOMATIQUE DU CLASSEMENT
-- ================================================================================================
if Config.SaveStatsToDatabase and Config.LeaderboardUpdateInterval > 0 then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(Config.LeaderboardUpdateInterval * 1000)
            UpdateGlobalLeaderboard()
        end
    end)
end

-- ================================================================================================
-- INITIALISATION
-- ================================================================================================
Citizen.CreateThread(function()
    Citizen.Wait(1000)
    print("^2[Gunfight Arena v4.2-OPT]^0 Server démarré - Optimisé")
    print("^3[Gunfight Arena v4.2-OPT]^0 Notifications: Kill Streak uniquement")
    print("^5[Gunfight Arena v4.2-OPT]^0 Kill Feed: ID + Nom FiveM activé")
    
    if Config.SaveStatsToDatabase then
        UpdateGlobalLeaderboard()
    end
end)
