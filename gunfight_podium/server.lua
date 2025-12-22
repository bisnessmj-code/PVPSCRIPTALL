-- ================================================================================================
-- GUNFIGHT PODIUM - SERVER v3.0.0
-- ================================================================================================
-- Gestion serveur des DEUX podiums : Gunfight et PVP
-- Compatible avec qs-appearance et pvp_stats_modes
-- ================================================================================================

local ESX = exports['es_extended']:getSharedObject()

-- Cache des top 3 actuels
local currentTop3 = {
    gunfight = {},
    pvp = {}
}

-- ================================================================================================
-- FONCTION : LOG DEBUG
-- ================================================================================================
local function DebugLog(message, logType)
    if not Config.Debug then return end
    
    local prefix = "^6[Podium-Server]^0"
    if logType == "error" then
        prefix = "^1[Podium-Server ERROR]^0"
    elseif logType == "success" then
        prefix = "^2[Podium-Server OK]^0"
    elseif logType == "database" then
        prefix = "^5[Podium-Database]^0"
    elseif logType == "skin" then
        prefix = "^3[Podium-Skin]^0"
    end
    
    print(prefix .. " " .. message)
end

-- ================================================================================================
-- FONCTION : PARSER LE SKIN QS-APPEARANCE
-- ================================================================================================
local function ParseQSAppearanceSkin(skinJson)
    if not skinJson or skinJson == "" then
        DebugLog("Skin JSON vide ou nil", "error")
        return nil
    end
    
    local success, skinData = pcall(json.decode, skinJson)
    
    if not success or not skinData then
        DebugLog("Erreur de parsing JSON du skin", "error")
        return nil
    end
    
    -- Valider les champs essentiels
    if not skinData.model then
        DebugLog("Skin sans modèle défini", "error")
        return nil
    end
    
    DebugLog("Skin parsé - Modèle: " .. skinData.model, "skin")
    
    return skinData
end

-- ================================================================================================
-- FONCTION : RÉCUPÉRER LE NOM DU JOUEUR CONNECTÉ
-- ================================================================================================
local function GetConnectedPlayerName(identifier)
    for _, playerId in ipairs(GetPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(tonumber(playerId))
        if xPlayer and xPlayer.identifier == identifier then
            return xPlayer.getName()
        end
    end
    return nil
end

-- ================================================================================================
-- FONCTION : RÉCUPÉRER LE TOP 3 GUNFIGHT DEPUIS LA BDD
-- ================================================================================================
local function GetTop3Gunfight(callback)
    if not Config.Podiums.gunfight then
        DebugLog("Podium Gunfight désactivé", "database")
        callback({})
        return
    end
    
    DebugLog("Récupération du top 3 Gunfight depuis la base de données...", "database")
    
    local orderBy = "kd_ratio DESC, kills DESC"
    if Config.RankingCriteria.gunfight == "kills" then
        orderBy = "kills DESC, kd_ratio DESC"
    end
    
    local query = string.format([[
        SELECT 
            gs.identifier,
            gs.player_name,
            gs.kills,
            gs.deaths,
            gs.best_streak,
            u.skin,
            u.firstname,
            u.lastname,
            CASE 
                WHEN gs.deaths > 0 THEN ROUND(gs.kills / gs.deaths, 2) 
                ELSE gs.kills 
            END as kd_ratio
        FROM %s gs
        LEFT JOIN %s u ON u.identifier = gs.identifier
        WHERE gs.kills > 0
        ORDER BY %s
        LIMIT 3
    ]], Config.DatabaseTables.gunfight, Config.DatabaseTables.users, orderBy)
    
    MySQL.Async.fetchAll(query, {}, function(result)
        if not result or #result == 0 then
            DebugLog("Aucune donnée Gunfight trouvée", "error")
            callback({})
            return
        end
        
        local top3 = {}
        
        for i, data in ipairs(result) do
            -- Priorité : nom de la BDD stats > nom users > joueur connecté
            local playerName = data.player_name
            
            if (not playerName or playerName == "") and data.firstname and data.lastname then
                playerName = data.firstname .. " " .. data.lastname
            end
            
            -- Vérifier si le joueur est connecté pour un nom à jour
            local connectedName = GetConnectedPlayerName(data.identifier)
            if connectedName then
                playerName = connectedName
            end
            
            if not playerName or playerName == "" then
                playerName = "Joueur Inconnu"
            end
            
            -- Parser le skin qs-appearance
            local skinData = ParseQSAppearanceSkin(data.skin)
            
            if skinData then
                DebugLog(string.format("[Gunfight] Skin chargé pour %s - Modèle: %s", playerName, skinData.model), "success")
            else
                DebugLog(string.format("[Gunfight] Pas de skin valide pour %s", playerName), "error")
            end
            
            table.insert(top3, {
                rank = i,
                identifier = data.identifier,
                name = playerName,
                kills = data.kills or 0,
                deaths = data.deaths or 0,
                kd = data.kd_ratio or 0,
                streak = data.best_streak or 0,
                skin = skinData,
                podium_type = "gunfight"
            })
            
            DebugLog(string.format("[Gunfight] Place %d : %s (K/D: %.2f, Kills: %d)", 
                i, playerName, data.kd_ratio or 0, data.kills or 0), "success")
        end
        
        callback(top3)
    end)
end

-- ================================================================================================
-- FONCTION : RÉCUPÉRER LE TOP 3 PVP DEPUIS LA BDD (pvp_stats_modes)
-- ================================================================================================
local function GetTop3PVP(callback)
    if not Config.Podiums.pvp then
        DebugLog("Podium PVP désactivé", "database")
        callback({})
        return
    end
    
    DebugLog("Récupération du top 3 PVP (mode: " .. Config.PVPMode .. ") depuis la base de données...", "database")
    
    local orderBy = "ps.elo DESC, ps.wins DESC"
    if Config.RankingCriteria.pvp == "wins" then
        orderBy = "ps.wins DESC, ps.elo DESC"
    end
    
    -- Requête adaptée à pvp_stats_modes
    local query = string.format([[
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
            u.skin,
            u.firstname,
            u.lastname,
            CASE 
                WHEN ps.matches_played > 0 THEN ROUND((ps.wins * 100.0 / ps.matches_played), 1)
                ELSE 0
            END as win_rate
        FROM %s ps
        LEFT JOIN %s u ON u.identifier = ps.identifier
        WHERE ps.mode = ? AND ps.matches_played > 0
        ORDER BY %s
        LIMIT 3
    ]], Config.DatabaseTables.pvp, Config.DatabaseTables.users, orderBy)
    
    MySQL.Async.fetchAll(query, { Config.PVPMode }, function(result)
        if not result or #result == 0 then
            DebugLog("Aucune donnée PVP trouvée pour le mode " .. Config.PVPMode, "error")
            callback({})
            return
        end
        
        local top3 = {}
        
        for i, data in ipairs(result) do
            -- Construire le nom du joueur
            local playerName = nil
            
            if data.firstname and data.lastname then
                playerName = data.firstname .. " " .. data.lastname
            end
            
            -- Vérifier si le joueur est connecté pour un nom à jour
            local connectedName = GetConnectedPlayerName(data.identifier)
            if connectedName then
                playerName = connectedName
            end
            
            if not playerName or playerName == "" then
                playerName = "Joueur Inconnu"
            end
            
            -- Parser le skin qs-appearance
            local skinData = ParseQSAppearanceSkin(data.skin)
            
            if skinData then
                DebugLog(string.format("[PVP] Skin chargé pour %s - Modèle: %s", playerName, skinData.model), "success")
            else
                DebugLog(string.format("[PVP] Pas de skin valide pour %s", playerName), "error")
            end
            
            table.insert(top3, {
                rank = i,
                identifier = data.identifier,
                name = playerName,
                mode = data.mode,
                elo = data.elo or 1000,
                rank_id = data.rank_id or 1,
                best_elo = data.best_elo or 1000,
                wins = data.wins or 0,
                losses = data.losses or 0,
                kills = data.kills or 0,
                deaths = data.deaths or 0,
                win_rate = data.win_rate or 0,
                matches_played = data.matches_played or 0,
                win_streak = data.win_streak or 0,
                best_win_streak = data.best_win_streak or 0,
                skin = skinData,
                podium_type = "pvp"
            })
            
            DebugLog(string.format("[PVP] Place %d : %s (ELO: %d, W/L: %d/%d, Mode: %s)", 
                i, playerName, data.elo or 1000, data.wins or 0, data.losses or 0, data.mode), "success")
        end
        
        callback(top3)
    end)
end

-- ================================================================================================
-- FONCTION : METTRE À JOUR LE PODIUM GUNFIGHT
-- ================================================================================================
local function UpdateGunfightPodium()
    DebugLog("Mise à jour du podium Gunfight...", "success")
    
    GetTop3Gunfight(function(top3)
        if #top3 == 0 then
            DebugLog("Aucun joueur à afficher sur le podium Gunfight", "error")
            return
        end
        
        currentTop3.gunfight = top3
        
        -- Envoyer aux clients
        TriggerClientEvent('gunfightpodium:updateGunfight', -1, top3)
        
        DebugLog("Podium Gunfight mis à jour avec " .. #top3 .. " joueur(s)", "success")
        
        if Config.Debug then
            print("^3[Podium Gunfight]^0 Top 3 actuel :")
            for i, player in ipairs(top3) do
                local modelName = player.skin and player.skin.model or "N/A"
                print(string.format("  ^2%d.^0 %s - K/D: %.2f (Kills: %d) - Model: %s", 
                    i, player.name, player.kd, player.kills, modelName))
            end
        end
    end)
end

-- ================================================================================================
-- FONCTION : METTRE À JOUR LE PODIUM PVP
-- ================================================================================================
local function UpdatePVPPodium()
    DebugLog("Mise à jour du podium PVP (mode: " .. Config.PVPMode .. ")...", "success")
    
    GetTop3PVP(function(top3)
        if #top3 == 0 then
            DebugLog("Aucun joueur à afficher sur le podium PVP", "error")
            return
        end
        
        currentTop3.pvp = top3
        
        -- Envoyer aux clients
        TriggerClientEvent('gunfightpodium:updatePVP', -1, top3)
        
        DebugLog("Podium PVP mis à jour avec " .. #top3 .. " joueur(s)", "success")
        
        if Config.Debug then
            print("^3[Podium PVP - Mode " .. Config.PVPMode .. "]^0 Top 3 actuel :")
            for i, player in ipairs(top3) do
                local modelName = player.skin and player.skin.model or "N/A"
                print(string.format("  ^2%d.^0 %s - ELO: %d (W/L: %d/%d) - Model: %s", 
                    i, player.name, player.elo, player.wins, player.losses, modelName))
            end
        end
    end)
end

-- ================================================================================================
-- FONCTION : METTRE À JOUR TOUS LES PODIUMS
-- ================================================================================================
local function UpdateAllPodiums()
    DebugLog("Mise à jour de tous les podiums...", "success")
    
    if Config.Podiums.gunfight then
        UpdateGunfightPodium()
    end
    
    if Config.Podiums.pvp then
        UpdatePVPPodium()
    end
end

-- ================================================================================================
-- EVENT : DEMANDE DE MISE À JOUR DU PODIUM (CLIENT)
-- ================================================================================================
RegisterNetEvent('gunfightpodium:requestUpdate')
AddEventHandler('gunfightpodium:requestUpdate', function()
    local src = source
    DebugLog("Demande de mise à jour des podiums par le joueur " .. src)
    
    -- Envoyer les données en cache
    if #currentTop3.gunfight > 0 then
        TriggerClientEvent('gunfightpodium:updateGunfight', src, currentTop3.gunfight)
    end
    
    if #currentTop3.pvp > 0 then
        TriggerClientEvent('gunfightpodium:updatePVP', src, currentTop3.pvp)
    end
    
    -- Si aucune donnée en cache, récupérer depuis la BDD
    if #currentTop3.gunfight == 0 or #currentTop3.pvp == 0 then
        UpdateAllPodiums()
    end
end)

-- ================================================================================================
-- EVENT : FORCER LA MISE À JOUR DES PODIUMS (ADMIN)
-- ================================================================================================
RegisterNetEvent('gunfightpodium:forceUpdate')
AddEventHandler('gunfightpodium:forceUpdate', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    if xPlayer.getGroup() == 'admin' or xPlayer.getGroup() == 'superadmin' then
        DebugLog("Mise à jour forcée des podiums par " .. xPlayer.getName())
        UpdateAllPodiums()
        TriggerClientEvent('esx:showNotification', src, Config.Messages.podiumUpdated)
    else
        TriggerClientEvent('esx:showNotification', src, "^1Vous n'avez pas la permission.")
    end
end)

-- ================================================================================================
-- COMMANDE : RAFRAÎCHIR LES PODIUMS (ADMIN)
-- ================================================================================================
RegisterCommand('refreshpodium', function(source, args, rawCommand)
    if source == 0 then
        print("^3[Podium]^0 Mise à jour des podiums depuis la console...")
        UpdateAllPodiums()
        return
    end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    if xPlayer.getGroup() == 'admin' or xPlayer.getGroup() == 'superadmin' then
        UpdateAllPodiums()
        TriggerClientEvent('esx:showNotification', source, Config.Messages.podiumUpdated)
    else
        TriggerClientEvent('esx:showNotification', source, "^1Vous n'avez pas la permission.")
    end
end, false)

-- ================================================================================================
-- COMMANDE : CHANGER LE MODE PVP AFFICHÉ (ADMIN)
-- ================================================================================================
RegisterCommand('setpvpmode', function(source, args, rawCommand)
    local validModes = { ["1v1"] = true, ["2v2"] = true, ["3v3"] = true, ["4v4"] = true }
    local newMode = args[1]
    
    if not newMode or not validModes[newMode] then
        if source == 0 then
            print("^1[Podium]^0 Usage: setpvpmode <1v1|2v2|3v3|4v4>")
        else
            TriggerClientEvent('esx:showNotification', source, "^1Usage: /setpvpmode <1v1|2v2|3v3|4v4>")
        end
        return
    end
    
    if source == 0 then
        Config.PVPMode = newMode
        print("^2[Podium]^0 Mode PVP changé en: " .. newMode)
        UpdatePVPPodium()
        return
    end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    if xPlayer.getGroup() == 'admin' or xPlayer.getGroup() == 'superadmin' then
        Config.PVPMode = newMode
        DebugLog("Mode PVP changé en " .. newMode .. " par " .. xPlayer.getName())
        UpdatePVPPodium()
        TriggerClientEvent('esx:showNotification', source, "^2Mode PVP changé en: " .. newMode)
    else
        TriggerClientEvent('esx:showNotification', source, "^1Vous n'avez pas la permission.")
    end
end, false)

-- ================================================================================================
-- COMMANDE : AFFICHER LES TOP 3 ACTUELS (ADMIN/CONSOLE)
-- ================================================================================================
RegisterCommand('showpodium', function(source, args, rawCommand)
    local podiumType = args[1] or "all" -- gunfight, pvp, ou all
    
    if source == 0 then
        -- Console serveur
        if podiumType == "all" or podiumType == "gunfight" then
            print("^3[Podium Gunfight]^0 Top 3 actuel :")
            if #currentTop3.gunfight > 0 then
                for i, player in ipairs(currentTop3.gunfight) do
                    local modelName = player.skin and player.skin.model or "N/A"
                    print(string.format("  ^2%d.^0 %s - K/D: %.2f (Kills: %d, Deaths: %d) - Model: %s", 
                        i, player.name, player.kd, player.kills, player.deaths, modelName))
                end
            else
                print("  ^1Aucune donnée disponible")
            end
        end
        
        if podiumType == "all" or podiumType == "pvp" then
            print("^3[Podium PVP - Mode " .. Config.PVPMode .. "]^0 Top 3 actuel :")
            if #currentTop3.pvp > 0 then
                for i, player in ipairs(currentTop3.pvp) do
                    local modelName = player.skin and player.skin.model or "N/A"
                    print(string.format("  ^2%d.^0 %s - ELO: %d (W: %d, L: %d) - Model: %s", 
                        i, player.name, player.elo, player.wins, player.losses, modelName))
                end
            else
                print("  ^1Aucune donnée disponible")
            end
        end
    else
        -- Joueur en jeu
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return end
        
        if podiumType == "all" or podiumType == "gunfight" then
            TriggerClientEvent('chat:addMessage', source, {
                args = { "^3[Podium Gunfight]^0", "Top 3 actuel :" }
            })
            
            if #currentTop3.gunfight > 0 then
                for i, player in ipairs(currentTop3.gunfight) do
                    TriggerClientEvent('chat:addMessage', source, {
                        args = { string.format("^2%d.^0", i), string.format("%s - K/D: %.2f (%d kills)", 
                            player.name, player.kd, player.kills) }
                    })
                end
            else
                TriggerClientEvent('chat:addMessage', source, {
                    args = { "^1Erreur^0", "Aucune donnée disponible" }
                })
            end
        end
        
        if podiumType == "all" or podiumType == "pvp" then
            TriggerClientEvent('chat:addMessage', source, {
                args = { "^3[Podium PVP - " .. Config.PVPMode .. "]^0", "Top 3 actuel :" }
            })
            
            if #currentTop3.pvp > 0 then
                for i, player in ipairs(currentTop3.pvp) do
                    TriggerClientEvent('chat:addMessage', source, {
                        args = { string.format("^2%d.^0", i), string.format("%s - ELO: %d (W/L: %d/%d)", 
                            player.name, player.elo, player.wins, player.losses) }
                    })
                end
            else
                TriggerClientEvent('chat:addMessage', source, {
                    args = { "^1Erreur^0", "Aucune donnée disponible" }
                })
            end
        end
    end
end, false)

-- ================================================================================================
-- THREAD : MISE À JOUR AUTOMATIQUE
-- ================================================================================================
if Config.AutoUpdate.enabled and Config.AutoUpdate.interval > 0 then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(Config.AutoUpdate.interval)
            
            DebugLog("Mise à jour automatique des podiums...", "success")
            UpdateAllPodiums()
        end
    end)
end

-- ================================================================================================
-- INITIALISATION AU DÉMARRAGE DU SERVEUR
-- ================================================================================================
Citizen.CreateThread(function()
    Wait(2000)
    
    print("^2========================================^0")
    print("^2[Gunfight Podium v3.1.0 OPTIMIZED]^0 Serveur initialisé")
    print("^3[Podium]^0 Compatible: ^2qs-appearance^0")
    print("^3[Podium]^0 Podiums activés:")
    print("  - Gunfight Arena: " .. (Config.Podiums.gunfight and "^2OUI^0" or "^1NON^0"))
    print("  - PVP Stats: " .. (Config.Podiums.pvp and "^2OUI^0" or "^1NON^0"))
    print("^3[Podium]^0 Mode PVP affiché: ^2" .. Config.PVPMode .. "^0")
    print("^3[Podium]^0 Critères de classement:")
    print("  - Gunfight: ^2" .. Config.RankingCriteria.gunfight .. "^0")
    print("  - PVP: ^2" .. Config.RankingCriteria.pvp .. "^0")
    
    if Config.AutoUpdate.enabled then
        print("^3[Podium]^0 Mise à jour auto: ^2ACTIVÉE^0 (toutes les " .. (Config.AutoUpdate.interval / 60000) .. " min)")
    else
        print("^3[Podium]^0 Mise à jour auto: ^1DÉSACTIVÉE^0")
    end
    
    print("^2========================================^0")
    
    -- Récupérer les top 3 initiaux
    UpdateAllPodiums()
end)

-- ================================================================================================
-- EXPORTS : OBTENIR LES TOP 3 ACTUELS
-- ================================================================================================
exports('GetTop3Gunfight', function()
    return currentTop3.gunfight
end)

exports('GetTop3PVP', function()
    return currentTop3.pvp
end)

exports('GetAllTop3', function()
    return currentTop3
end)

exports('GetCurrentPVPMode', function()
    return Config.PVPMode
end)
