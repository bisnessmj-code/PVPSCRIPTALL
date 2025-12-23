--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                        SERVER - KILLS.LUA                                  ║
    ║          CORRIGÉ : Progression d'arme garantie à 100%                      ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════════════════
-- ÉVÉNEMENT : JOUEUR MORT ⭐ CORRIGÉ ⭐
-- ═══════════════════════════════════════════════════════════════════════════
RegisterNetEvent('gungame:server:playerDied', function(killerServerId, weaponHash)
    local victimSource = source
    
    print('^3[GunGame][KILLS]^7 playerDied event - Victim: ' .. victimSource .. ', Killer: ' .. (killerServerId or 'nil'))
    
    if not GunGame.players[victimSource] then 
        print('^1[GunGame][KILLS][ERROR]^7 Victime ' .. victimSource .. ' pas en partie')
        return
    end
    
    print('^2[GunGame][KILLS]^7 Victime confirmée: ' .. GunGame.players[victimSource].name)
    
    if killerServerId and killerServerId > 0 and GunGame.players[killerServerId] then
        print('^2[GunGame][KILLS]^7 Tueur confirmé: ' .. GunGame.players[killerServerId].name .. ' (ID: ' .. killerServerId .. ')')
        ProcessKill(killerServerId, victimSource, weaponHash)
    else
        print('^3[GunGame][KILLS][WARN]^7 Pas de tueur valide (suicide ou sortie de zone)')
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- TRAITEMENT D'UN KILL ⭐ VERSION ULTRA-FIABLE ⭐
-- ═══════════════════════════════════════════════════════════════════════════
function ProcessKill(killerSource, victimSource, weaponHash)
    print('^5[GunGame][KILLS][PROCESS]^7 ====== DÉBUT ProcessKill ======')
    print('^5[GunGame][KILLS][PROCESS]^7 Tueur: ' .. killerSource .. ', Victime: ' .. victimSource)
    
    if not ValidateKill(killerSource, victimSource, weaponHash) then
        print('^1[GunGame][KILLS][ERROR]^7 Kill invalide')
        return
    end
    
    local killerData = GunGame.players[killerSource]
    local victimData = GunGame.players[victimSource]
    
    if not killerData or not victimData then 
        print('^1[GunGame][KILLS][ERROR]^7 Données joueur manquantes')
        return
    end
    
    print('^5[GunGame][KILLS][BEFORE]^7 Tueur: Arme=' .. killerData.weaponIndex .. ', Kills=' .. killerData.kills .. '/' .. Config.KillsPerWeaponChange)
    
    -- Incrémenter les kills
    killerData.kills = killerData.kills + 1
    killerData.totalKills = killerData.totalKills + 1
    victimData.deaths = victimData.deaths + 1
    
    print('^2[GunGame][KILLS][AFTER]^7 Tueur: Arme=' .. killerData.weaponIndex .. ', Kills=' .. killerData.kills .. '/' .. Config.KillsPerWeaponChange)
    print('^2[GunGame][KILLS]^7 ' .. killerData.name .. ' a tué ' .. victimData.name)
    
    -- Notifier le tueur
    TriggerClientEvent('gungame:client:killConfirm', killerSource, 
        killerData.kills, Config.KillsPerWeaponChange)
    
    -- Notifier la victime
    TriggerClientEvent('gungame:client:playerKilled', victimSource, killerData.name)
    
    -- Kill feed
    local weaponData = Config.GetWeapon(killerData.weaponIndex)
    BroadcastKillFeed(
        killerData.name, 
        killerSource,
        victimData.name, 
        victimSource,
        weaponData and weaponData.label or "Unknown"
    )
    
    -- Hook
    OnPlayerKill(killerData, victimData)
    
    -- ⭐ VÉRIFIER LA PROGRESSION IMMÉDIATEMENT ⭐
    print('^5[GunGame][KILLS]^7 Vérification progression...')
    CheckWeaponProgression(killerSource)
    
    -- Mettre à jour le classement
    Wait(100) -- Petit délai pour s'assurer que la progression est bien appliquée
    BroadcastLeaderboard()
    
    print('^5[GunGame][KILLS][PROCESS]^7 ====== FIN ProcessKill ======')
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PROGRESSION D'ARME ⭐ VERSION ULTRA-FIABLE ⭐
-- ═══════════════════════════════════════════════════════════════════════════
function CheckWeaponProgression(source)
    print('^6[GunGame][PROGRESSION]^7 ========== DÉBUT CheckWeaponProgression ==========')
    print('^6[GunGame][PROGRESSION]^7 Source: ' .. source)
    
    local playerData = GunGame.players[source]
    
    if not playerData then 
        print('^1[GunGame][PROGRESSION][ERROR]^7 PlayerData nil pour source ' .. source)
        return 
    end
    
    print('^6[GunGame][PROGRESSION]^7 Joueur: ' .. playerData.name)
    print('^6[GunGame][PROGRESSION]^7 Arme actuelle: ' .. playerData.weaponIndex .. '/' .. Config.TotalWeapons)
    print('^6[GunGame][PROGRESSION]^7 Kills actuels: ' .. playerData.kills .. '/' .. Config.KillsPerWeaponChange)
    
    -- ⭐ VÉRIFICATION STRICTE ⭐
    if playerData.kills >= Config.KillsPerWeaponChange then
        print('^2[GunGame][PROGRESSION]^7 ✓ Assez de kills ! Changement d\'arme...')
        
        -- Reset les kills AVANT de changer l'arme
        playerData.kills = 0
        print('^2[GunGame][PROGRESSION]^7 Kills reset à 0')
        
        -- Passer à l'arme suivante
        local oldWeaponIndex = playerData.weaponIndex
        local newWeaponIndex = oldWeaponIndex + 1
        
        print('^2[GunGame][PROGRESSION]^7 Passage de l\'arme ' .. oldWeaponIndex .. ' à ' .. newWeaponIndex)
        
        -- ⭐ VÉRIFIER SI VICTOIRE ⭐
        if newWeaponIndex > Config.TotalWeapons then
            print('^2[GunGame][PROGRESSION]^7 🏆 VICTOIRE ! Arme ' .. newWeaponIndex .. ' > ' .. Config.TotalWeapons)
            DeclareWinner(source)
            return
        end
        
        -- ⭐ CHANGER L'ARME (GARANTIE 100%) ⭐
        playerData.weaponIndex = newWeaponIndex
        print('^2[GunGame][PROGRESSION]^7 ✅ Arme changée: ' .. oldWeaponIndex .. ' → ' .. newWeaponIndex)
        
        -- ⭐ NOTIFIER LE CLIENT IMMÉDIATEMENT ⭐
        print('^2[GunGame][PROGRESSION]^7 📤 Envoi updateProgress au client ' .. source)
        print('^2[GunGame][PROGRESSION]^7 📊 Données: weaponIndex=' .. newWeaponIndex .. ', kills=' .. playerData.kills)
        
        TriggerClientEvent('gungame:client:updateProgress', source, newWeaponIndex, playerData.kills)
        
        -- Hook
        OnWeaponChange(playerData, newWeaponIndex)
        
        -- Message de confirmation
        local weaponData = Config.GetWeapon(newWeaponIndex)
        if weaponData then
            print('^2[GunGame][PROGRESSION]^7 🔫 ' .. playerData.name .. ' passe à: ' .. weaponData.label .. ' (' .. newWeaponIndex .. '/40)')
        end
        
        -- ⭐ DOUBLE VÉRIFICATION (SÉCURITÉ) ⭐
        Wait(100)
        if GunGame.players[source] and GunGame.players[source].weaponIndex == newWeaponIndex then
            print('^2[GunGame][PROGRESSION]^7 ✅ Changement d\'arme CONFIRMÉ')
        else
            print('^1[GunGame][PROGRESSION][ERROR]^7 ⚠️ ÉCHEC du changement d\'arme !')
        end
    else
        -- Pas assez de kills, juste mettre à jour la progression
        print('^3[GunGame][PROGRESSION]^7 ✗ Pas assez de kills (' .. playerData.kills .. '/' .. Config.KillsPerWeaponChange .. ')')
        print('^3[GunGame][PROGRESSION]^7 📤 Envoi updateProgress (même arme)')
        
        TriggerClientEvent('gungame:client:updateProgress', source, 
            playerData.weaponIndex, playerData.kills)
    end
    
    print('^6[GunGame][PROGRESSION]^7 ========== FIN CheckWeaponProgression ==========')
end

-- ═══════════════════════════════════════════════════════════════════════════
-- DÉCLARATION DU VAINQUEUR
-- ═══════════════════════════════════════════════════════════════════════════
function DeclareWinner(source)
    local winnerData = GunGame.players[source]
    
    if not winnerData then 
        print('^1[GunGame][WINNER][ERROR]^7 WinnerData nil')
        return 
    end
    
    print('^2[GunGame][WINNER]^7 =====================================')
    print('^2[GunGame][WINNER]^7 🏆 VICTOIRE: ' .. winnerData.name .. ' !')
    print('^2[GunGame][WINNER]^7 Total kills: ' .. winnerData.totalKills)
    print('^2[GunGame][WINNER]^7 =====================================')
    
    EndGame(winnerData)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- KILL FEED
-- ═══════════════════════════════════════════════════════════════════════════
function BroadcastKillFeed(killerName, killerID, victimName, victimID, weaponLabel)
    if not Config.UI.showKillFeed then return end
    
    print('^5[GunGame][KILLFEED]^7 ' .. killerName .. ' [' .. killerID .. '] → ' .. victimName .. ' [' .. victimID .. '] (' .. weaponLabel .. ')')
    
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
