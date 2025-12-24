
-- ========================================
-- PVP GUNFIGHT - CACHE LEADERBOARDS COMPLET
-- Version 1.0.0 - Tous les modes (1v1, 2v2, 3v3, 4v4)
-- ========================================

DebugServer('Module Cache Leaderboards chargé (TOUS MODES)')

-- ========================================
-- CONFIGURATION CACHE
-- ========================================
local CACHE_CONFIG = {
    -- Durée de vie du cache (en millisecondes)
    duration = 60000, -- 1 minute
    
    -- Limite de joueurs par leaderboard
    maxPlayers = 50,
    
    -- Modes supportés
    modes = {'1v1', '2v2', '3v3', '4v4'}
}

-- ========================================
-- CACHE MÉMOIRE (TOUS LES MODES)
-- ========================================
local leaderboardCache = {
    ['1v1'] = {data = nil, timestamp = 0, loading = false},
    ['2v2'] = {data = nil, timestamp = 0, loading = false},
    ['3v3'] = {data = nil, timestamp = 0, loading = false},
    ['4v4'] = {data = nil, timestamp = 0, loading = false}
}

-- Statistiques de performance
local cacheStats = {
    hits = {['1v1'] = 0, ['2v2'] = 0, ['3v3'] = 0, ['4v4'] = 0},
    misses = {['1v1'] = 0, ['2v2'] = 0, ['3v3'] = 0, ['4v4'] = 0},
    totalQueries = 0,
    totalCacheTime = 0
}

-- ========================================
-- 🔧 FONCTION: VÉRIFIER SI CACHE VALIDE
-- ========================================
local function IsCacheValid(mode)
    local cache = leaderboardCache[mode]
    
    if not cache or not cache.data then
        return false
    end
    
    local elapsed = GetGameTimer() - cache.timestamp
    
    return elapsed < CACHE_CONFIG.duration
end

-- ========================================
-- 🔧 FONCTION: RÉCUPÉRER LEADERBOARD OPTIMISÉ
-- ========================================
function GetLeaderboardByModeOptimized(mode, limit, callback)
    limit = limit or CACHE_CONFIG.maxPlayers
    
    -- Validation du mode
    if not leaderboardCache[mode] then
        DebugError('Mode invalide: %s', mode)
        callback({})
        return
    end
    
    -- ✅ VÉRIFIER CACHE AVANT REQUÊTE
    if IsCacheValid(mode) then
        cacheStats.hits[mode] = cacheStats.hits[mode] + 1
        DebugServer('📦 Cache HIT - Mode: %s (évité requête SQL) [%d hits]', mode, cacheStats.hits[mode])
        callback(leaderboardCache[mode].data)
        return
    end
    
    -- Éviter les requêtes multiples simultanées
    if leaderboardCache[mode].loading then
        DebugWarn('⏳ Requête déjà en cours pour mode: %s - Attente...', mode)
        
        -- Attendre que la requête en cours se termine
        CreateThread(function()
            local maxWait = 50 -- 5 secondes max
            local waited = 0
            
            while leaderboardCache[mode].loading and waited < maxWait do
                Wait(100)
                waited = waited + 1
            end
            
            -- Réessayer
            if IsCacheValid(mode) then
                callback(leaderboardCache[mode].data)
            else
                callback({})
            end
        end)
        
        return
    end
    
    -- Marquer comme en chargement
    leaderboardCache[mode].loading = true
    
    cacheStats.misses[mode] = cacheStats.misses[mode] + 1
    cacheStats.totalQueries = cacheStats.totalQueries + 1
    
    local queryStartTime = GetGameTimer()
    
    DebugServer('🔍 Cache MISS - Mode: %s (requête SQL nécessaire) [%d misses]', mode, cacheStats.misses[mode])
    
    -- ✅ REQUÊTE OPTIMISÉE (sans calcul dynamique inutile)
    MySQL.query([[
        SELECT 
            ps.identifier,
            ps.mode,
            ps.elo,
            ps.rank_id,
            ps.best_elo,
            ps.wins,
            ps.losses,
            ps.kills,
            ps.deaths,
            ps.matches_played,
            ps.win_streak,
            ps.best_win_streak,
            u.firstname,
            u.lastname
        FROM pvp_stats_modes ps
        LEFT JOIN users u ON u.identifier = ps.identifier
        WHERE ps.mode = ? AND ps.matches_played > 0
        ORDER BY ps.elo DESC, ps.wins DESC
        LIMIT ?
    ]], {mode, limit}, function(results)
        -- Démarquer le chargement
        leaderboardCache[mode].loading = false
        
        local queryDuration = GetGameTimer() - queryStartTime
        cacheStats.totalCacheTime = cacheStats.totalCacheTime + queryDuration
        
        if not results then
            DebugError('❌ Erreur requête SQL - Mode: %s', mode)
            callback({})
            return
        end
        
        -- ✅ CALCULER win_rate EN LUA (plus rapide que SQL)
        for i = 1, #results do
            local player = results[i]
            
            -- Calculs côté Lua
            player.kills = player.kills or 0
            player.deaths = player.deaths or 0
            
            if player.matches_played and player.matches_played > 0 then
                player.win_rate = math.floor((player.wins * 100.0 / player.matches_played) * 10) / 10
            else
                player.win_rate = 0
            end
            
            -- Nom complet
            player.name = (player.firstname or 'Joueur') .. ' ' .. (player.lastname or i)
            
            -- Avatar (sera récupéré async plus tard si besoin)
            player.avatar = Config.Discord.defaultAvatar
            player.rank = exports['pvp_gunfight']:GetRankByElo(player.elo)
        end
        
        -- ✅ MISE EN CACHE
        leaderboardCache[mode] = {
            data = results,
            timestamp = GetGameTimer(),
            loading = false
        }
        
        DebugSuccess('✅ Leaderboard %s mis en cache (%d joueurs, %dms)', mode, #results, queryDuration)
        
        callback(results)
    end)
end

-- ========================================
-- 🔧 FONCTION: INVALIDER CACHE (après match)
-- ========================================
function InvalidateLeaderboardCache(mode)
    if mode then
        -- Invalider un mode spécifique
        if leaderboardCache[mode] then
            leaderboardCache[mode] = {data = nil, timestamp = 0, loading = false}
            DebugServer('🗑️ Cache invalidé - Mode: %s', mode)
        else
            DebugWarn('⚠️ Mode inconnu: %s', mode)
        end
    else
        -- Invalider TOUS les modes
        for i = 1, #CACHE_CONFIG.modes do
            local m = CACHE_CONFIG.modes[i]
            leaderboardCache[m] = {data = nil, timestamp = 0, loading = false}
        end
        DebugServer('🗑️ Cache TOTAL invalidé (tous les modes)')
    end
end

-- ========================================
-- 🔧 FONCTION: FORCER REFRESH CACHE
-- ========================================
function RefreshLeaderboardCache(mode, callback)
    if mode then
        -- Refresh un mode spécifique
        DebugServer('🔄 Refresh forcé - Mode: %s', mode)
        InvalidateLeaderboardCache(mode)
        GetLeaderboardByModeOptimized(mode, CACHE_CONFIG.maxPlayers, callback)
    else
        -- Refresh TOUS les modes
        DebugServer('🔄 Refresh forcé - TOUS LES MODES')
        
        local completed = 0
        local results = {}
        
        for i = 1, #CACHE_CONFIG.modes do
            local m = CACHE_CONFIG.modes[i]
            
            InvalidateLeaderboardCache(m)
            
            GetLeaderboardByModeOptimized(m, CACHE_CONFIG.maxPlayers, function(data)
                results[m] = data
                completed = completed + 1
                
                if completed == #CACHE_CONFIG.modes then
                    if callback then
                        callback(results)
                    end
                end
            end)
        end
    end
end

-- ========================================
-- 🔧 FONCTION: PRÉCHARGER TOUS LES CACHES
-- ========================================
function PreloadAllLeaderboards(callback)
    DebugServer('📥 Préchargement de tous les leaderboards...')
    
    local completed = 0
    local results = {}
    
    for i = 1, #CACHE_CONFIG.modes do
        local mode = CACHE_CONFIG.modes[i]
        
        GetLeaderboardByModeOptimized(mode, CACHE_CONFIG.maxPlayers, function(data)
            results[mode] = data
            completed = completed + 1
            
            DebugServer('  ✅ Leaderboard %s préchargé (%d joueurs)', mode, #data)
            
            if completed == #CACHE_CONFIG.modes then
                DebugSuccess('✅ Tous les leaderboards préchargés (%d modes)', #CACHE_CONFIG.modes)
                if callback then callback(results) end
            end
        end)
    end
end

-- ========================================
-- THREAD: INVALIDATION AUTOMATIQUE (toutes les 2 minutes)
-- ========================================
CreateThread(function()
    -- Attendre 5 secondes avant de commencer
    Wait(5000)
    
    DebugSuccess('Thread invalidation cache démarré (toutes les 2 minutes)')
    
    while true do
        Wait(120000) -- 2 minutes
        
        DebugServer('🔄 Invalidation automatique du cache (tous modes)')
        InvalidateLeaderboardCache() -- Invalider tout
    end
end)

-- ========================================
-- THREAD: PRÉCHARGEMENT AU DÉMARRAGE
-- ========================================
CreateThread(function()
    -- Attendre que tout soit chargé
    Wait(10000)
    
    DebugServer('🚀 Préchargement initial des leaderboards...')
    
    PreloadAllLeaderboards(function(results)
        DebugSuccess('✅ Préchargement terminé!')
        
        -- Afficher les stats
        for mode, data in pairs(results) do
            DebugServer('  %s: %d joueurs en cache', mode, #data)
        end
    end)
end)

-- ========================================
-- COMMANDE ADMIN: FORCER REFRESH
-- ========================================
RegisterCommand('pvprefreshcache', function(source, args)
    if source ~= 0 and not exports['pvp_gunfight']:IsPlayerAdmin(source) then
        if source > 0 then
            TriggerClientEvent('esx:showNotification', source, '~r~Permission refusée')
        end
        return
    end
    
    local mode = args[1]
    
    if mode and mode ~= 'all' then
        -- Refresh un mode spécifique
        RefreshLeaderboardCache(mode, function(results)
            local msg = string.format('✅ Cache %s rafraîchi (%d joueurs)', mode, #results)
            if source > 0 then
                TriggerClientEvent('esx:showNotification', source, '~g~' .. msg)
            else
                print('[PVP] ' .. msg)
            end
        end)
    else
        -- Refresh TOUS les modes
        RefreshLeaderboardCache(nil, function(results)
            local total = 0
            for _, data in pairs(results) do
                total = total + #data
            end
            
            local msg = string.format('✅ Tous les caches rafraîchis (%d joueurs)', total)
            if source > 0 then
                TriggerClientEvent('esx:showNotification', source, '~g~' .. msg)
            else
                print('[PVP] ' .. msg)
            end
        end)
    end
end, false)

-- ========================================
-- COMMANDE ADMIN: STATS DU CACHE
-- ========================================
RegisterCommand('pvpcachestats', function(source)
    if source ~= 0 and not exports['pvp_gunfight']:IsPlayerAdmin(source) then
        return
    end
    
    local msg = '📊 STATS CACHE LEADERBOARDS'
    print('[PVP] ' .. msg)
    if source > 0 then TriggerClientEvent('esx:showNotification', source, '~b~' .. msg) end
    
    -- Stats par mode
    for i = 1, #CACHE_CONFIG.modes do
        local mode = CACHE_CONFIG.modes[i]
        local cache = leaderboardCache[mode]
        local status = cache.data and '✅ ACTIF' or '❌ VIDE'
        local age = cache.data and math.floor((GetGameTimer() - cache.timestamp) / 1000) or 0
        local count = cache.data and #cache.data or 0
        local hits = cacheStats.hits[mode] or 0
        local misses = cacheStats.misses[mode] or 0
        local hitRate = (hits + misses) > 0 and math.floor((hits / (hits + misses)) * 100) or 0
        
        local line = string.format('%s: %s (%d joueurs, %ds ago) | Hits: %d (%.1f%%)', 
            mode, status, count, age, hits, hitRate)
        
        print('[PVP]   ' .. line)
        if source > 0 then TriggerClientEvent('esx:showNotification', source, '~w~' .. line) end
    end
    
    -- Stats globales
    local totalHits = 0
    local totalMisses = 0
    
    for _, hits in pairs(cacheStats.hits) do
        totalHits = totalHits + hits
    end
    
    for _, misses in pairs(cacheStats.misses) do
        totalMisses = totalMisses + misses
    end
    
    local globalHitRate = (totalHits + totalMisses) > 0 and math.floor((totalHits / (totalHits + totalMisses)) * 100) or 0
    local avgQueryTime = cacheStats.totalQueries > 0 and math.floor(cacheStats.totalCacheTime / cacheStats.totalQueries) or 0
    
    local globalLine = string.format('GLOBAL: %d hits, %d misses (%.1f%%) | Avg query: %dms', 
        totalHits, totalMisses, globalHitRate, avgQueryTime)
    
    print('[PVP] ' .. globalLine)
    if source > 0 then TriggerClientEvent('esx:showNotification', source, '~g~' .. globalLine) end
end, false)

-- ========================================
-- COMMANDE ADMIN: VIDER LE CACHE
-- ========================================
RegisterCommand('pvpclearcache', function(source, args)
    if source ~= 0 and not exports['pvp_gunfight']:IsPlayerAdmin(source) then
        if source > 0 then
            TriggerClientEvent('esx:showNotification', source, '~r~Permission refusée')
        end
        return
    end
    
    local mode = args[1]
    
    InvalidateLeaderboardCache(mode)
    
    local msg = mode and ('Cache ' .. mode .. ' vidé') or 'Tous les caches vidés'
    
    if source > 0 then
        TriggerClientEvent('esx:showNotification', source, '~g~✅ ' .. msg)
    else
        print('[PVP] ✅ ' .. msg)
    end
end, false)

-- ========================================
-- EXPORTS
-- ========================================
exports('GetLeaderboardByModeOptimized', GetLeaderboardByModeOptimized)
exports('InvalidateLeaderboardCache', InvalidateLeaderboardCache)
exports('RefreshLeaderboardCache', RefreshLeaderboardCache)
exports('PreloadAllLeaderboards', PreloadAllLeaderboards)

DebugSuccess('========================================')
DebugSuccess('MODULE CACHE LEADERBOARDS INITIALISÉ')
DebugSuccess('Modes: %s', table.concat(CACHE_CONFIG.modes, ', '))
DebugSuccess('Durée cache: %dms (%d secondes)', CACHE_CONFIG.duration, CACHE_CONFIG.duration / 1000)
DebugSuccess('Limite joueurs: %d', CACHE_CONFIG.maxPlayers)
DebugSuccess('========================================')