-- ========================================
-- PVP GUNFIGHT - SYSTÈME ELO SIMPLIFIÉ
-- Version 5.2.0 - Progression Facilitée + Cache + ANTI-DEADLOCK
-- ========================================

DebugElo('Module ELO chargé (VERSION SIMPLIFIÉE + CACHE + ANTI-DEADLOCK)')

-- ========================================
-- CONFIGURATION ELO SIMPLIFIÉE
-- ========================================
local ELO_CONFIG = {
    -- GAINS ET PERTES FIXES (SIMPLE)
    baseWinElo = 30,        -- Gain de base par victoire
    baseLoseElo = 12,       -- Perte de base par défaite
    
    -- BONUS
    winStreakBonus = 5,     -- Bonus par victoire consécutive (max 3)
    maxStreakBonus = 15,    -- Bonus maximum de streak (3 victoires = +15)
    
    -- MULTIPLICATEURS PAR MODE (réduits pour simplifier)
    modeMultipliers = {
        ['1v1'] = 1.0,
        ['2v2'] = 1.0,
        ['3v3'] = 1.0,
        ['4v4'] = 1.0
    },
    
    -- PROTECTION CONTRE LES PERTES EXCESSIVES
    maxLossPerMatch = 20,   -- Maximum d'ELO perdu en un match
    minEloGain = 20,        -- Minimum d'ELO gagné (toujours au moins 20)
    
    minimumElo = 0,
    startingElo = 0,
    
    rankThresholds = {
        {id = 1, name = "Bronze", min = 0, max = 999, color = "^9"},
        {id = 2, name = "Argent", min = 1000, max = 1499, color = "^7"},
        {id = 3, name = "Or", min = 1500, max = 1999, color = "^3"},
        {id = 4, name = "Platine", min = 2000, max = 2499, color = "^4"},
        {id = 5, name = "Émeraude", min = 2500, max = 2999, color = "^2"},
        {id = 6, name = "Diamant", min = 3000, max = 9999, color = "^5"}
    }
}

-- ========================================
-- FONCTIONS UTILITAIRES
-- ========================================
local function GetRankByElo(elo)
    for i = 1, #ELO_CONFIG.rankThresholds do
        local rank = ELO_CONFIG.rankThresholds[i]
        if elo >= rank.min and elo <= rank.max then
            return rank
        end
    end
    return ELO_CONFIG.rankThresholds[6]
end

-- ========================================
-- CALCUL ELO SIMPLIFIÉ
-- ========================================
function CalculateEloChange(winnerElo, loserElo, winnerRankId, loserRankId, scoreRatio, mode, winnerStreak)
    winnerStreak = winnerStreak or 0
    
    -- Multiplicateur de mode (tous à 1.0 maintenant)
    local modeMultiplier = ELO_CONFIG.modeMultipliers[mode] or 1.0
    
    -- CALCUL GAIN GAGNANT (SIMPLE)
    local winnerGain = ELO_CONFIG.baseWinElo
    
    -- Bonus de streak (max 3 victoires consécutives)
    if winnerStreak > 0 then
        local streakBonus = math.min(winnerStreak * ELO_CONFIG.winStreakBonus, ELO_CONFIG.maxStreakBonus)
        winnerGain = winnerGain + streakBonus
        DebugElo('🔥 Bonus streak: +%d ELO (streak: %d)', streakBonus, winnerStreak)
    end
    
    -- Appliquer multiplicateur de mode
    winnerGain = math.floor(winnerGain * modeMultiplier)
    
    -- Garantir un gain minimum
    winnerGain = math.max(winnerGain, ELO_CONFIG.minEloGain)
    
    -- CALCUL PERTE PERDANT (SIMPLE)
    local loserLoss = ELO_CONFIG.baseLoseElo
    
    -- Appliquer multiplicateur de mode
    loserLoss = math.floor(loserLoss * modeMultiplier)
    
    -- Limiter la perte maximum
    loserLoss = math.min(loserLoss, ELO_CONFIG.maxLossPerMatch)
    
    -- Nouveau ELO
    local winnerNewElo = winnerElo + winnerGain
    local loserNewElo = math.max(ELO_CONFIG.minimumElo, loserElo - loserLoss)
    
    DebugElo('📊 ELO Change: Gagnant +%d (%d → %d) | Perdant -%d (%d → %d)',
        winnerGain, winnerElo, winnerNewElo,
        loserLoss, loserElo, loserNewElo)
    
    return {
        winnerNewElo = winnerNewElo,
        loserNewElo = loserNewElo,
        winnerChange = winnerGain,
        loserChange = -loserLoss
    }
end

-- ========================================
-- INITIALISATION DES STATS PAR MODE
-- ========================================
function InitPlayerModeStats(identifier, playerName)
    DebugElo('Init stats par mode: %s', identifier)
    
    local modes = {'1v1', '2v2', '3v3', '4v4'}
    
    for i = 1, #modes do
        MySQL.insert([[
            INSERT IGNORE INTO pvp_stats_modes 
            (identifier, mode, elo, rank_id, best_elo, kills, deaths, wins, losses, matches_played, win_streak, best_win_streak) 
            VALUES (?, ?, ?, 1, ?, 0, 0, 0, 0, 0, 0, 0)
        ]], {identifier, modes[i], ELO_CONFIG.startingElo, ELO_CONFIG.startingElo})
    end
end

-- ========================================
-- RÉCUPÉRATION DES STATS
-- ========================================
function GetPlayerStatsByMode(identifier, mode, callback)
    MySQL.single([[
        SELECT * FROM pvp_stats_modes WHERE identifier = ? AND mode = ?
    ]], {identifier, mode}, function(result)
        if result then
            callback(result)
        else
            MySQL.insert([[
                INSERT INTO pvp_stats_modes 
                (identifier, mode, elo, rank_id, best_elo) VALUES (?, ?, ?, 1, ?)
            ]], {identifier, mode, ELO_CONFIG.startingElo, ELO_CONFIG.startingElo}, function()
                callback({
                    identifier = identifier,
                    mode = mode,
                    elo = ELO_CONFIG.startingElo,
                    rank_id = 1,
                    best_elo = ELO_CONFIG.startingElo,
                    kills = 0,
                    deaths = 0,
                    wins = 0,
                    losses = 0,
                    matches_played = 0,
                    win_streak = 0,
                    best_win_streak = 0
                })
            end)
        end
    end)
end

function GetPlayerAllModeStats(identifier, callback)
    MySQL.query([[
        SELECT * FROM pvp_stats_modes WHERE identifier = ? ORDER BY FIELD(mode, '1v1', '2v2', '3v3', '4v4')
    ]], {identifier}, function(results)
        local statsByMode = {}
        local modes = {'1v1', '2v2', '3v3', '4v4'}
        
        if results then
            for i = 1, #results do
                statsByMode[results[i].mode] = results[i]
            end
        end
        
        for i = 1, #modes do
            if not statsByMode[modes[i]] then
                statsByMode[modes[i]] = {
                    identifier = identifier,
                    mode = modes[i],
                    elo = ELO_CONFIG.startingElo,
                    rank_id = 1,
                    best_elo = ELO_CONFIG.startingElo,
                    kills = 0,
                    deaths = 0,
                    wins = 0,
                    losses = 0,
                    matches_played = 0,
                    win_streak = 0,
                    best_win_streak = 0
                }
            end
        end
        
        callback(statsByMode)
    end)
end

-- ========================================
-- MISE À JOUR ELO - 1V1
-- ========================================
function UpdatePlayerElo1v1ByMode(winnerId, loserId, finalScore, mode)
    local xWinner = ESX.GetPlayerFromId(winnerId)
    local xLoser = ESX.GetPlayerFromId(loserId)
    
    if not xWinner or not xLoser then
        DebugError('Joueur introuvable pour mise à jour ELO')
        return
    end
    
    DebugElo('[%s] Mise à jour ELO 1v1 (SYSTÈME SIMPLIFIÉ)', mode)
    
    GetPlayerStatsByMode(xWinner.identifier, mode, function(winnerStats)
        GetPlayerStatsByMode(xLoser.identifier, mode, function(loserStats)
            local winnerElo = winnerStats.elo or ELO_CONFIG.startingElo
            local loserElo = loserStats.elo or ELO_CONFIG.startingElo
            local winnerRankId = winnerStats.rank_id or 1
            local loserRankId = loserStats.rank_id or 1
            local winnerBestElo = winnerStats.best_elo or ELO_CONFIG.startingElo
            local loserBestElo = loserStats.best_elo or ELO_CONFIG.startingElo
            local winnerStreak = (winnerStats.win_streak or 0) + 1
            local winnerBestStreak = math.max(winnerStats.best_win_streak or 0, winnerStreak)
            
            local winnerScore = math.max(finalScore.team1, finalScore.team2)
            local loserScore = math.min(finalScore.team1, finalScore.team2)
            local scoreRatio = loserScore / winnerScore
            
            -- CALCUL SIMPLIFIÉ
            local eloResult = CalculateEloChange(winnerElo, loserElo, winnerRankId, loserRankId, scoreRatio, mode, winnerStreak - 1)
            
            local winnerNewRank = GetRankByElo(eloResult.winnerNewElo)
            local loserNewRank = GetRankByElo(eloResult.loserNewElo)
            local newWinnerBestElo = math.max(winnerBestElo, eloResult.winnerNewElo)
            local newLoserBestElo = math.max(loserBestElo, eloResult.loserNewElo)
            
            -- Mise à jour gagnant
            MySQL.update([[
                UPDATE pvp_stats_modes 
                SET elo = ?, rank_id = ?, best_elo = ?, wins = wins + 1, 
                    matches_played = matches_played + 1, win_streak = ?, best_win_streak = ?
                WHERE identifier = ? AND mode = ?
            ]], {eloResult.winnerNewElo, winnerNewRank.id, newWinnerBestElo, winnerStreak, winnerBestStreak, xWinner.identifier, mode})
            
            -- Mise à jour perdant
            MySQL.update([[
                UPDATE pvp_stats_modes 
                SET elo = ?, rank_id = ?, best_elo = ?, losses = losses + 1, 
                    matches_played = matches_played + 1, win_streak = 0
                WHERE identifier = ? AND mode = ?
            ]], {eloResult.loserNewElo, loserNewRank.id, newLoserBestElo, xLoser.identifier, mode})
            
            -- Stats globales
            UpdateGlobalStats(xWinner.identifier, eloResult.winnerNewElo, winnerNewRank.id, true)
            UpdateGlobalStats(xLoser.identifier, eloResult.loserNewElo, loserNewRank.id, false)
            
            -- Notifications
            TriggerClientEvent('esx:showNotification', winnerId, 
                string.format('~g~+%d ELO~w~ en %s (%d) ~y~🔥 Streak: %d', 
                    eloResult.winnerChange, mode, eloResult.winnerNewElo, winnerStreak))
            
            TriggerClientEvent('esx:showNotification', loserId, 
                string.format('~r~%d ELO~w~ en %s (%d)', 
                    eloResult.loserChange, mode, eloResult.loserNewElo))
            
            if winnerNewRank.id > winnerRankId then
                TriggerClientEvent('esx:showNotification', winnerId, 
                    string.format('~g~🎉 PROMOTION %s! Vous êtes ~b~%s~w~!', mode, winnerNewRank.name))
            end
            
            if loserNewRank.id < loserRankId then
                TriggerClientEvent('esx:showNotification', loserId, 
                    string.format('~r~⚠️ RÉTROGRADATION %s - Vous êtes ~y~%s~w~', mode, loserNewRank.name))
            end
        end)
    end)
end

-- ========================================
-- MISE À JOUR ELO - ÉQUIPE
-- ========================================
function UpdateTeamEloByMode(winners, losers, finalScore, mode)
    DebugElo('[%s] Mise à jour ELO équipe (SYSTÈME SIMPLIFIÉ)', mode)
    
    local winnersData = {}
    local losersData = {}
    local winnersProcessed = 0
    local losersProcessed = 0
    
    for i = 1, #winners do
        local xWinner = ESX.GetPlayerFromId(winners[i])
        if xWinner then
            GetPlayerStatsByMode(xWinner.identifier, mode, function(stats)
                winnersData[#winnersData + 1] = {
                    playerId = winners[i],
                    identifier = xWinner.identifier,
                    elo = stats.elo or ELO_CONFIG.startingElo,
                    rankId = stats.rank_id or 1,
                    bestElo = stats.best_elo or ELO_CONFIG.startingElo,
                    winStreak = (stats.win_streak or 0) + 1,
                    bestWinStreak = stats.best_win_streak or 0
                }
                winnersProcessed = winnersProcessed + 1
                
                if winnersProcessed == #winners and losersProcessed == #losers then
                    ProcessTeamEloUpdateByMode(winnersData, losersData, finalScore, mode)
                end
            end)
        else
            winnersProcessed = winnersProcessed + 1
        end
    end
    
    for i = 1, #losers do
        local xLoser = ESX.GetPlayerFromId(losers[i])
        if xLoser then
            GetPlayerStatsByMode(xLoser.identifier, mode, function(stats)
                losersData[#losersData + 1] = {
                    playerId = losers[i],
                    identifier = xLoser.identifier,
                    elo = stats.elo or ELO_CONFIG.startingElo,
                    rankId = stats.rank_id or 1,
                    bestElo = stats.best_elo or ELO_CONFIG.startingElo
                }
                losersProcessed = losersProcessed + 1
                
                if winnersProcessed == #winners and losersProcessed == #losers then
                    ProcessTeamEloUpdateByMode(winnersData, losersData, finalScore, mode)
                end
            end)
        else
            losersProcessed = losersProcessed + 1
        end
    end
end

function ProcessTeamEloUpdateByMode(winnersData, losersData, finalScore, mode)
    if #winnersData == 0 or #losersData == 0 then return end
    
    local avgWinnerElo, avgLoserElo = 0, 0
    local avgWinnerRank, avgLoserRank = 0, 0
    
    for i = 1, #winnersData do
        avgWinnerElo = avgWinnerElo + winnersData[i].elo
        avgWinnerRank = avgWinnerRank + winnersData[i].rankId
    end
    avgWinnerElo = math.floor(avgWinnerElo / #winnersData)
    avgWinnerRank = math.floor(avgWinnerRank / #winnersData)
    
    for i = 1, #losersData do
        avgLoserElo = avgLoserElo + losersData[i].elo
        avgLoserRank = avgLoserRank + losersData[i].rankId
    end
    avgLoserElo = math.floor(avgLoserElo / #losersData)
    avgLoserRank = math.floor(avgLoserRank / #losersData)
    
    local winnerScore = math.max(finalScore.team1, finalScore.team2)
    local loserScore = math.min(finalScore.team1, finalScore.team2)
    local scoreRatio = loserScore / winnerScore
    
    -- Utiliser le streak du premier joueur de l'équipe gagnante
    local teamStreak = winnersData[1].winStreak - 1
    
    -- CALCUL SIMPLIFIÉ
    local eloResult = CalculateEloChange(avgWinnerElo, avgLoserElo, avgWinnerRank, avgLoserRank, scoreRatio, mode, teamStreak)
    
    -- Mise à jour gagnants
    for i = 1, #winnersData do
        local data = winnersData[i]
        local newElo = data.elo + eloResult.winnerChange
        local newRank = GetRankByElo(newElo)
        local newBestElo = math.max(data.bestElo, newElo)
        local newBestStreak = math.max(data.bestWinStreak, data.winStreak)
        
        MySQL.update([[
            UPDATE pvp_stats_modes 
            SET elo = ?, rank_id = ?, best_elo = ?, wins = wins + 1, 
                matches_played = matches_played + 1, win_streak = ?, best_win_streak = ?
            WHERE identifier = ? AND mode = ?
        ]], {newElo, newRank.id, newBestElo, data.winStreak, newBestStreak, data.identifier, mode})
        
        TriggerClientEvent('esx:showNotification', data.playerId, 
            string.format('~g~+%d ELO~w~ en %s (%d) ~y~🔥 Streak: %d', 
                eloResult.winnerChange, mode, newElo, data.winStreak))
        
        UpdateGlobalStats(data.identifier, newElo, newRank.id, true)
    end
    
    -- Mise à jour perdants
    for i = 1, #losersData do
        local data = losersData[i]
        local newElo = math.max(ELO_CONFIG.minimumElo, data.elo + eloResult.loserChange)
        local newRank = GetRankByElo(newElo)
        local newBestElo = math.max(data.bestElo, newElo)
        
        MySQL.update([[
            UPDATE pvp_stats_modes 
            SET elo = ?, rank_id = ?, best_elo = ?, losses = losses + 1, 
                matches_played = matches_played + 1, win_streak = 0
            WHERE identifier = ? AND mode = ?
        ]], {newElo, newRank.id, newBestElo, data.identifier, mode})
        
        TriggerClientEvent('esx:showNotification', data.playerId, 
            string.format('~r~%d ELO~w~ en %s (%d)', eloResult.loserChange, mode, newElo))
        
        UpdateGlobalStats(data.identifier, newElo, newRank.id, false)
    end
end

-- ========================================
-- STATS GLOBALES
-- ========================================
function UpdateGlobalStats(identifier, newElo, newRankId, isWin)
    MySQL.single([[
        SELECT MAX(elo) as max_elo, MAX(best_elo) as max_best_elo FROM pvp_stats_modes WHERE identifier = ?
    ]], {identifier}, function(result)
        local globalBestElo = result and math.max(result.max_elo or 1000, result.max_best_elo or 1000) or 1000
        
        if isWin then
            MySQL.update([[
                UPDATE pvp_stats SET wins = wins + 1, matches_played = matches_played + 1, best_elo = GREATEST(best_elo, ?)
                WHERE identifier = ?
            ]], {globalBestElo, identifier})
        else
            MySQL.update('UPDATE pvp_stats SET losses = losses + 1, matches_played = matches_played + 1 WHERE identifier = ?', {identifier})
        end
    end)
end

-- ========================================
-- ✅ KILLS/DEATHS PAR MODE (ANTI-DEADLOCK)
-- ========================================

-- ✅ FONCTION OPTIMISÉE: MISE À JOUR KILLS (SANS DEADLOCK)
function UpdatePlayerKillsByMode(playerId, amount, mode)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end
    
    -- ✅ UTILISER CreateThread POUR ÉVITER LES DEADLOCKS
    CreateThread(function()
        local success = false
        local attempts = 0
        local maxAttempts = 3
        
        -- Retry en cas de deadlock
        while not success and attempts < maxAttempts do
            attempts = attempts + 1
            
            -- ✅ UPDATE par mode (avec index composite identifier + mode)
            MySQL.update('UPDATE pvp_stats_modes SET kills = kills + ? WHERE identifier = ? AND mode = ?', 
                {amount, xPlayer.identifier, mode}, function(affectedRows)
                    if affectedRows and affectedRows > 0 then
                        success = true
                        DebugElo('✅ Kills mis à jour: %s (+%d) [tentative %d]', mode, amount, attempts)
                    else
                        if attempts >= maxAttempts then
                            DebugError('❌ Échec UPDATE kills après %d tentatives (mode: %s)', maxAttempts, mode)
                        end
                    end
                end)
            
            -- Attente progressive en cas d'échec (50ms, 100ms, 150ms)
            if not success and attempts < maxAttempts then
                Wait(50 * attempts)
            end
        end
        
        -- ✅ UPDATE stats globales (requête séparée pour éviter deadlock)
        Wait(25) -- Petit délai pour éviter collision
        MySQL.update('UPDATE pvp_stats SET kills = kills + ? WHERE identifier = ?', {amount, xPlayer.identifier})
    end)
end

-- ✅ FONCTION OPTIMISÉE: MISE À JOUR DEATHS (SANS DEADLOCK)
function UpdatePlayerDeathsByMode(playerId, amount, mode)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end
    
    -- ✅ UTILISER CreateThread POUR ÉVITER LES DEADLOCKS
    CreateThread(function()
        local success = false
        local attempts = 0
        local maxAttempts = 3
        
        -- Retry en cas de deadlock
        while not success and attempts < maxAttempts do
            attempts = attempts + 1
            
            -- ✅ UPDATE par mode (avec index composite identifier + mode)
            MySQL.update('UPDATE pvp_stats_modes SET deaths = deaths + ? WHERE identifier = ? AND mode = ?', 
                {amount, xPlayer.identifier, mode}, function(affectedRows)
                    if affectedRows and affectedRows > 0 then
                        success = true
                        DebugElo('✅ Deaths mis à jour: %s (+%d) [tentative %d]', mode, amount, attempts)
                    else
                        if attempts >= maxAttempts then
                            DebugError('❌ Échec UPDATE deaths après %d tentatives (mode: %s)', maxAttempts, mode)
                        end
                    end
                end)
            
            -- Attente progressive en cas d'échec (50ms, 100ms, 150ms)
            if not success and attempts < maxAttempts then
                Wait(50 * attempts)
            end
        end
        
        -- ✅ UPDATE stats globales (requête séparée pour éviter deadlock)
        Wait(25) -- Petit délai pour éviter collision
        MySQL.update('UPDATE pvp_stats SET deaths = deaths + ? WHERE identifier = ?', {amount, xPlayer.identifier})
    end)
end

-- ========================================
-- LEADERBOARD OPTIMISÉ (AVEC CACHE)
-- ========================================
function GetLeaderboardByMode(mode, limit, callback)
    -- ✅ UTILISER LE CACHE au lieu de requête directe
    exports['pvp_gunfight']:GetLeaderboardByModeOptimized(mode, limit, callback)
end

-- ========================================
-- COMPATIBILITÉ
-- ========================================
function UpdatePlayerElo1v1(winnerId, loserId, finalScore)
    UpdatePlayerElo1v1ByMode(winnerId, loserId, finalScore, '1v1')
end

function UpdateTeamElo(winners, losers, finalScore)
    UpdateTeamEloByMode(winners, losers, finalScore, '2v2')
end

-- ========================================
-- EXPORTS
-- ========================================
exports('UpdatePlayerElo1v1', UpdatePlayerElo1v1)
exports('UpdatePlayerElo1v1ByMode', UpdatePlayerElo1v1ByMode)
exports('UpdateTeamElo', UpdateTeamElo)
exports('UpdateTeamEloByMode', UpdateTeamEloByMode)
exports('GetRankByElo', GetRankByElo)
exports('CalculateEloChange', CalculateEloChange)
exports('GetPlayerStatsByMode', GetPlayerStatsByMode)
exports('GetPlayerAllModeStats', GetPlayerAllModeStats)
exports('GetLeaderboardByMode', GetLeaderboardByMode)
exports('InitPlayerModeStats', InitPlayerModeStats)
exports('UpdatePlayerKillsByMode', UpdatePlayerKillsByMode)
exports('UpdatePlayerDeathsByMode', UpdatePlayerDeathsByMode)

DebugSuccess('========================================')
DebugSuccess('Système ELO initialisé (VERSION 5.2.0)')
DebugSuccess('✅ SIMPLIFIÉ + CACHE + ANTI-DEADLOCK')
DebugSuccess('📊 Gains: +%d ELO | Pertes: -%d ELO', ELO_CONFIG.baseWinElo, ELO_CONFIG.baseLoseElo)
DebugSuccess('🔥 Bonus Streak: +%d par victoire (max: %d)', ELO_CONFIG.winStreakBonus, ELO_CONFIG.maxStreakBonus)
DebugSuccess('🔒 Anti-Deadlock: Retry x3 + Délais progressifs')
DebugSuccess('========================================')