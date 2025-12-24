--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                        SERVER - KILLS.LUA                                  ║
    ║           Optimisé : Logging centralisé, progression garantie             ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════════════════
-- ÉVÉNEMENT : JOUEUR MORT
-- ═══════════════════════════════════════════════════════════════════════════
RegisterNetEvent('gungame:server:playerDied', function(killerServerId, weaponHash)
    local victimSource = source
    
    if not GunGame.players[victimSource] then 
        Logger.Warn('KILLS', 'Victime %d pas en partie', victimSource)
        return
    end
    
    Logger.Debug('KILLS', 'Victime: %s', GunGame.players[victimSource].name)
    
    if killerServerId and killerServerId > 0 and GunGame.players[killerServerId] then
        Logger.Debug('KILLS', 'Tueur: %s (ID: %d)', GunGame.players[killerServerId].name, killerServerId)
        ProcessKill(killerServerId, victimSource, weaponHash)
    else
        Logger.Debug('KILLS', 'Pas de tueur valide (suicide ou sortie de zone)')
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- TRAITEMENT D'UN KILL
-- ═══════════════════════════════════════════════════════════════════════════
function ProcessKill(killerSource, victimSource, weaponHash)
    Logger.Section('KILLS', 'DÉBUT ProcessKill')
    
    if not ValidateKill(killerSource, victimSource, weaponHash) then
        Logger.Warn('KILLS', 'Kill invalide')
        return
    end
    
    local killerData = GunGame.players[killerSource]
    local victimData = GunGame.players[victimSource]
    
    if not killerData or not victimData then 
        Logger.Error('KILLS', 'Données joueur manquantes')
        return
    end
    
    Logger.Debug('KILLS', 'AVANT: Tueur Arme=%d, Kills=%d/%d', killerData.weaponIndex, killerData.kills, Config.KillsPerWeaponChange)
    
    killerData.kills = killerData.kills + 1
    killerData.totalKills = killerData.totalKills + 1
    victimData.deaths = victimData.deaths + 1
    
    Logger.Info('KILLS', '%s a tué %s', killerData.name, victimData.name)
    Logger.Debug('KILLS', 'APRÈS: Tueur Arme=%d, Kills=%d/%d', killerData.weaponIndex, killerData.kills, Config.KillsPerWeaponChange)
    
    TriggerClientEvent('gungame:client:killConfirm', killerSource, 
        killerData.kills, Config.KillsPerWeaponChange)
    
    TriggerClientEvent('gungame:client:playerKilled', victimSource, killerData.name)
    
    local weaponData = Config.GetWeapon(killerData.weaponIndex)
    BroadcastKillFeed(
        killerData.name, 
        killerSource,
        victimData.name, 
        victimSource,
        weaponData and weaponData.label or "Unknown"
    )
    
    OnPlayerKill(killerData, victimData)
    
    CheckWeaponProgression(killerSource)
    
    Wait(100)
    BroadcastLeaderboard()
    
    Logger.Section('KILLS', 'FIN ProcessKill')
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PROGRESSION D'ARME
-- ═══════════════════════════════════════════════════════════════════════════
function CheckWeaponProgression(source)
    Logger.Section('PROGRESSION', 'DÉBUT CheckWeaponProgression')
    
    local playerData = GunGame.players[source]
    
    if not playerData then 
        Logger.Error('PROGRESSION', 'PlayerData nil pour source %d', source)
        return 
    end
    
    Logger.Debug('PROGRESSION', 'Joueur: %s', playerData.name)
    Logger.Debug('PROGRESSION', 'Arme: %d/%d', playerData.weaponIndex, Config.TotalWeapons)
    Logger.Debug('PROGRESSION', 'Kills: %d/%d', playerData.kills, Config.KillsPerWeaponChange)
    
    if playerData.kills >= Config.KillsPerWeaponChange then
        Logger.Debug('PROGRESSION', 'Assez de kills ! Changement d\'arme')
        
        playerData.kills = 0
        
        local oldWeaponIndex = playerData.weaponIndex
        local newWeaponIndex = oldWeaponIndex + 1
        
        Logger.Debug('PROGRESSION', 'Passage arme %d → %d', oldWeaponIndex, newWeaponIndex)
        
        if newWeaponIndex > Config.TotalWeapons then
            Logger.Info('PROGRESSION', '🏆 VICTOIRE ! %s a terminé', playerData.name)
            DeclareWinner(source)
            return
        end
        
        playerData.weaponIndex = newWeaponIndex
        
        TriggerClientEvent('gungame:client:updateProgress', source, newWeaponIndex, playerData.kills)
        
        OnWeaponChange(playerData, newWeaponIndex)
        
        local weaponData = Config.GetWeapon(newWeaponIndex)
        if weaponData then
            Logger.Info('PROGRESSION', '%s passe à: %s (%d/40)', playerData.name, weaponData.label, newWeaponIndex)
        end
        
        Wait(100)
        if GunGame.players[source] and GunGame.players[source].weaponIndex == newWeaponIndex then
            Logger.Debug('PROGRESSION', 'Changement d\'arme CONFIRMÉ')
        else
            Logger.Error('PROGRESSION', 'ÉCHEC du changement d\'arme')
        end
    else
        Logger.Debug('PROGRESSION', 'Pas assez de kills (%d/%d)', playerData.kills, Config.KillsPerWeaponChange)
        
        TriggerClientEvent('gungame:client:updateProgress', source, 
            playerData.weaponIndex, playerData.kills)
    end
    
    Logger.Section('PROGRESSION', 'FIN CheckWeaponProgression')
end

-- ═══════════════════════════════════════════════════════════════════════════
-- DÉCLARATION DU VAINQUEUR
-- ═══════════════════════════════════════════════════════════════════════════
function DeclareWinner(source)
    local winnerData = GunGame.players[source]
    
    if not winnerData then 
        Logger.Error('WINNER', 'WinnerData nil')
        return 
    end
    
    Logger.Info('WINNER', '=====================================')
    Logger.Info('WINNER', '🏆 VICTOIRE: %s !', winnerData.name)
    Logger.Info('WINNER', 'Total kills: %d', winnerData.totalKills)
    Logger.Info('WINNER', '=====================================')
    
    EndGame(winnerData)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- KILL FEED
-- ═══════════════════════════════════════════════════════════════════════════
function BroadcastKillFeed(killerName, killerID, victimName, victimID, weaponLabel)
    if not Config.UI.showKillFeed then return end
    
    Logger.Debug('KILLFEED', '%s [%d] → %s [%d] (%s)', killerName, killerID, victimName, victimID, weaponLabel)
    
    for source, _ in pairs(GunGame.players) do
        TriggerClientEvent('gungame:client:killFeed', source, 
            killerName, killerID, victimName, victimID, weaponLabel)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- STATISTIQUES JOUEUR
-- ═══════════════════════════════════════════════════════════════════════════
function GetPlayerStats(source)
    local playerData = GunGame.players[source]
    
    if not playerData then return nil end
    
    return {
        id = playerData.source,
        name = playerData.name,
        weaponIndex = playerData.weaponIndex,
        kills = playerData.kills,
        totalKills = playerData.totalKills,
        deaths = playerData.deaths
    }
end

function GetCurrentLeader()
    local leader = nil
    local highestWeapon = 0
    local highestKills = 0
    
    for source, playerData in pairs(GunGame.players) do
        if playerData.weaponIndex > highestWeapon or 
           (playerData.weaponIndex == highestWeapon and playerData.totalKills > highestKills) then
            highestWeapon = playerData.weaponIndex
            highestKills = playerData.totalKills
            leader = playerData
        end
    end
    
    return leader
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════
exports('getPlayerStats', GetPlayerStats)
exports('getCurrentLeader', GetCurrentLeader)
exports('processKill', ProcessKill)