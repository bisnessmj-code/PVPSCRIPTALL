-- ═══════════════════════════════════════════════════════════════════════
--  SERVER SIDE - SAFEZONE OPTIMISÉ
--  Version: 1.1.5 | Performance serveur minimal
-- ═══════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════
-- 📦 DONNÉES
-- ═══════════════════════════════════════════════════════════════════════

local PlayersInZones = {} -- Table des joueurs dans les zones
local ZoneStats = {}      -- Statistiques par zone

-- ═══════════════════════════════════════════════════════════════════════
-- 🔧 UTILITAIRES
-- ═══════════════════════════════════════════════════════════════════════

-- Log serveur
local function ServerLog(message, level)
    if not Config.ServerLogs then return end
    
    local prefix = '^3[SafeZone Server]^7'
    if level == 'error' then
        prefix = '^1[SafeZone Server ERROR]^7'
    elseif level == 'success' then
        prefix = '^2[SafeZone Server]^7'
    end
    
    print(prefix .. ' ' .. message)
end

-- Récupère le nom du joueur
local function GetPlayerName(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        return xPlayer.getName()
    end
    return GetPlayerName(source)
end

-- Récupère l'identifiant du joueur
local function GetPlayerIdentifier(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        return xPlayer.identifier
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════
-- 📊 GESTION DES STATISTIQUES
-- ═══════════════════════════════════════════════════════════════════════

-- Initialise les stats d'une zone
local function InitZoneStats(zoneName)
    if not ZoneStats[zoneName] then
        ZoneStats[zoneName] = {
            totalVisits = 0,
            currentPlayers = 0,
            averageTime = 0,
            totalTime = 0,
        }
    end
end

-- Met à jour les stats d'une zone
local function UpdateZoneStats(zoneName, timeSpent)
    InitZoneStats(zoneName)
    
    local stats = ZoneStats[zoneName]
    stats.totalVisits = stats.totalVisits + 1
    stats.totalTime = stats.totalTime + timeSpent
    stats.averageTime = stats.totalTime / stats.totalVisits
end

-- ═══════════════════════════════════════════════════════════════════════
-- 📥 EVENTS DU CLIENT
-- ═══════════════════════════════════════════════════════════════════════

-- Joueur entre dans une zone
RegisterNetEvent('safezone:playerEntered', function(zoneName)
    local _source = source
    local playerName = GetPlayerName(_source)
    local identifier = GetPlayerIdentifier(_source)
    
    -- Enregistre le joueur
    PlayersInZones[_source] = {
        zoneName = zoneName,
        timestamp = os.time(),
        identifier = identifier,
    }
    
    -- Stats
    InitZoneStats(zoneName)
    ZoneStats[zoneName].currentPlayers = ZoneStats[zoneName].currentPlayers + 1
    
    ServerLog(string.format('Joueur %s (ID:%d) → Zone: %s', 
        playerName, _source, zoneName))
    
    -- Event pour autres scripts
    TriggerEvent('safezone:onPlayerEntered', _source, zoneName, identifier)
end)

-- Joueur sort d'une zone
RegisterNetEvent('safezone:playerLeft', function(zoneName)
    local _source = source
    local playerName = GetPlayerName(_source)
    local identifier = GetPlayerIdentifier(_source)
    
    -- Calcul du temps passé
    local timeInZone = 0
    if PlayersInZones[_source] then
        timeInZone = os.time() - PlayersInZones[_source].timestamp
        PlayersInZones[_source] = nil
    end
    
    -- Stats
    if ZoneStats[zoneName] then
        ZoneStats[zoneName].currentPlayers = math.max(0, ZoneStats[zoneName].currentPlayers - 1)
        UpdateZoneStats(zoneName, timeInZone)
    end
    
    ServerLog(string.format('Joueur %s (ID:%d) ← Zone: %s (Temps: %ds)', 
        playerName, _source, zoneName, timeInZone))
    
    -- Event pour autres scripts
    TriggerEvent('safezone:onPlayerLeft', _source, zoneName, identifier, timeInZone)
end)

-- ═══════════════════════════════════════════════════════════════════════
-- 🚪 GESTION DES DÉCONNEXIONS
-- ═══════════════════════════════════════════════════════════════════════

AddEventHandler('playerDropped', function(reason)
    local _source = source
    
    if PlayersInZones[_source] then
        local zoneName = PlayersInZones[_source].zoneName
        local timeInZone = os.time() - PlayersInZones[_source].timestamp
        
        -- Stats
        if ZoneStats[zoneName] then
            ZoneStats[zoneName].currentPlayers = math.max(0, ZoneStats[zoneName].currentPlayers - 1)
            UpdateZoneStats(zoneName, timeInZone)
        end
        
        ServerLog(string.format('Joueur (ID:%d) déconnecté de: %s (Temps: %ds)', 
            _source, zoneName, timeInZone))
        
        PlayersInZones[_source] = nil
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- 🎛️ COMMANDES ADMIN
-- ═══════════════════════════════════════════════════════════════════════

-- Liste des joueurs dans les zones
RegisterCommand('safezone_list', function(source, args)
    local xPlayer = source > 0 and ESX.GetPlayerFromId(source) or nil
    
    -- Vérification admin
    if source > 0 and (not xPlayer or xPlayer.getGroup() ~= 'admin') then
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            args = {'SafeZone', 'Permission refusée'}
        })
        return
    end
    
    local output = function(msg, color)
        if source == 0 then
            print(msg)
        else
            TriggerClientEvent('chat:addMessage', source, {
                color = color or {255, 255, 255},
                args = {'SafeZone', msg}
            })
        end
    end
    
    output('═══════════════════════════════════════', {0, 255, 0})
    output('📋 JOUEURS DANS LES ZONES', {0, 255, 0})
    output('═══════════════════════════════════════', {0, 255, 0})
    
    local count = 0
    for playerId, data in pairs(PlayersInZones) do
        count = count + 1
        local timeInZone = os.time() - data.timestamp
        output(string.format('[%d] %s → %s (Depuis: %ds)', 
            playerId, GetPlayerName(playerId), data.zoneName, timeInZone))
    end
    
    output('───────────────────────────────────────')
    output('Total: ' .. count .. ' joueur(s)')
    output('═══════════════════════════════════════', {0, 255, 0})
end, false)

-- Statistiques détaillées
RegisterCommand('safezone_stats', function(source, args)
    local xPlayer = source > 0 and ESX.GetPlayerFromId(source) or nil
    
    -- Vérification admin
    if source > 0 and (not xPlayer or xPlayer.getGroup() ~= 'admin') then
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            args = {'SafeZone', 'Permission refusée'}
        })
        return
    end
    
    local output = function(msg, color)
        if source == 0 then
            print(msg)
        else
            TriggerClientEvent('chat:addMessage', source, {
                color = color or {255, 255, 255},
                args = {'SafeZone', msg}
            })
        end
    end
    
    output('═══════════════════════════════════════', {0, 255, 0})
    output('📊 STATISTIQUES SAFEZONES', {0, 255, 0})
    output('═══════════════════════════════════════', {0, 255, 0})
    output('Zones configurées: ' .. #Config.SafeZones)
    output('Zones actives: ' .. Config.GetActiveZonesCount())
    
    -- Compte les joueurs dans les zones
    local playerCount = 0
    for _ in pairs(PlayersInZones) do
        playerCount = playerCount + 1
    end
    output('Joueurs dans zones: ' .. playerCount)
    output('───────────────────────────────────────')
    
    if next(ZoneStats) then
        output('STATISTIQUES PAR ZONE:')
        for zoneName, stats in pairs(ZoneStats) do
            output(string.format('  %s:', zoneName))
            output(string.format('    - Joueurs actuels: %d', stats.currentPlayers))
            output(string.format('    - Visites totales: %d', stats.totalVisits))
            output(string.format('    - Temps moyen: %ds', math.floor(stats.averageTime)))
        end
    end
    
    output('═══════════════════════════════════════', {0, 255, 0})
end, false)

-- Reset des stats
RegisterCommand('safezone_resetstats', function(source, args)
    local xPlayer = source > 0 and ESX.GetPlayerFromId(source) or nil
    
    -- Vérification admin
    if source > 0 and (not xPlayer or xPlayer.getGroup() ~= 'admin') then
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            args = {'SafeZone', 'Permission refusée'}
        })
        return
    end
    
    ZoneStats = {}
    
    local msg = 'Statistiques réinitialisées'
    if source == 0 then
        print('^2[SafeZone]^7 ' .. msg)
    else
        TriggerClientEvent('chat:addMessage', source, {
            color = {0, 255, 0},
            args = {'SafeZone', msg}
        })
    end
end, false)

-- ═══════════════════════════════════════════════════════════════════════
-- 📤 EXPORTS SERVEUR
-- ═══════════════════════════════════════════════════════════════════════

-- Récupère les joueurs dans une zone
exports('GetPlayersInZone', function(zoneName)
    local players = {}
    for playerId, data in pairs(PlayersInZones) do
        if data.zoneName == zoneName then
            table.insert(players, playerId)
        end
    end
    return players
end)

-- Vérifie si un joueur est dans une zone
exports('IsPlayerInZone', function(playerId)
    return PlayersInZones[playerId] ~= nil
end)

-- Récupère la zone d'un joueur
exports('GetPlayerZone', function(playerId)
    if PlayersInZones[playerId] then
        return PlayersInZones[playerId].zoneName
    end
    return nil
end)

-- Récupère les stats d'une zone
exports('GetZoneStats', function(zoneName)
    return ZoneStats[zoneName]
end)

-- Récupère toutes les stats
exports('GetAllStats', function()
    return ZoneStats
end)

-- ═══════════════════════════════════════════════════════════════════════
-- 🚀 INITIALISATION
-- ═══════════════════════════════════════════════════════════════════════

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    ServerLog('═══════════════════════════════════════', 'success')
    ServerLog('🛡️  SAFEZONE v2.0.2.1 SERVER DÉMARRÉ', 'success')
    ServerLog('═══════════════════════════════════════', 'success')
    ServerLog('Zones actives: ' .. Config.GetActiveZonesCount(), 'success')
    ServerLog('Debug: ' .. (Config.Debug and 'ON' or 'OFF'), 'success')
    ServerLog('Logs: ' .. (Config.ServerLogs and 'ON' or 'OFF'), 'success')
    ServerLog('═══════════════════════════════════════', 'success')
end)

-- ═══════════════════════════════════════════════════════════════════════
-- 🧹 NETTOYAGE
-- ═══════════════════════════════════════════════════════════════════════

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    ServerLog('SafeZone arrêté proprement', 'success')
    
    PlayersInZones = {}
    ZoneStats = {}
end)