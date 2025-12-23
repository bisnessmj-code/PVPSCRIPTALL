--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                        SERVER - MAIN.LUA                                   ║
    ║            CORRIGÉ : Bucket 100, Classement 5, Déconnexion                 ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════════════════
-- TABLE GLOBALE DES JOUEURS
-- ═══════════════════════════════════════════════════════════════════════════
GunGame = {
    players = {},
    activeGame = false,
    winner = nil
}

-- ═══════════════════════════════════════════════════════════════════════════
-- ÉVÉNEMENT : VIDER L'INVENTAIRE DES ARMES
-- ═══════════════════════════════════════════════════════════════════════════
RegisterNetEvent('gungame:server:clearInventoryWeapons', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    local loadout = xPlayer.getLoadout()
    
    for i = 1, #loadout do
        xPlayer.removeWeapon(loadout[i].name)
    end
    
    print('^2[GunGame][SERVER]^7 Inventaire des armes vidé pour ' .. xPlayer.getName())
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- ÉVÉNEMENT : DEMANDE DE REJOINDRE
-- ═══════════════════════════════════════════════════════════════════════════
RegisterNetEvent('gungame:server:requestJoin', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        print('^1[GunGame][ERROR]^7 Joueur invalide (source: ' .. source .. ')')
        return
    end
    
    if GunGame.players[source] then
        print('^3[GunGame][WARN]^7 Le joueur ' .. xPlayer.getName() .. ' (' .. source .. ') est déjà en partie')
        return
    end
    
    local currentPlayers = 0
    for _ in pairs(GunGame.players) do
        currentPlayers = currentPlayers + 1
    end
    
    if currentPlayers >= Config.MaxPlayersPerGame then
        TriggerClientEvent('esx:showNotification', source, '~r~La partie est complète !')
        print('^3[GunGame][WARN]^7 Partie complète - Joueur refusé : ' .. xPlayer.getName())
        return
    end
    
    local playerData = {
        source = source,
        identifier = xPlayer.identifier,
        name = xPlayer.getName(),
        weaponIndex = 1,
        kills = 0,
        totalKills = 0,
        deaths = 0,
        joinTime = os.time()
    }
    
    GunGame.players[source] = playerData
    
    -- ⭐ MISE DANS LE BUCKET 100 (GunGame) ⭐
    if Config.RoutingBucket.enabled then
        SetPlayerRoutingBucket(source, Config.RoutingBucket.bucketId)
        print('^2[GunGame][BUCKET]^7 ' .. playerData.name .. ' mis dans le bucket ' .. Config.RoutingBucket.bucketId)
    end
    
    TriggerClientEvent('gungame:client:joinGame', source, 1)
    
    print('^2[GunGame][JOIN]^7 ' .. playerData.name .. ' (' .. source .. ') a rejoint la partie (' .. (currentPlayers + 1) .. '/' .. Config.MaxPlayersPerGame .. ')')
    
    Wait(500)
    BroadcastLeaderboard()
    BroadcastPlayerBlips()
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- ÉVÉNEMENT : DEMANDE DE QUITTER
-- ═══════════════════════════════════════════════════════════════════════════
RegisterNetEvent('gungame:server:requestLeave', function()
    local source = source
    
    if not GunGame.players[source] then
        print('^3[GunGame][WARN]^7 Joueur ' .. source .. ' pas en partie, impossible de quitter')
        TriggerClientEvent('esx:showNotification', source, '~r~Tu n\'es pas dans le GunGame !')
        return
    end
    
    local playerData = GunGame.players[source]
    print('^3[GunGame][LEAVE]^7 ' .. playerData.name .. ' (' .. source .. ') quitte la partie (commande)')
    
    RemovePlayer(source)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- FONCTION : RETIRER UN JOUEUR
-- ═══════════════════════════════════════════════════════════════════════════
function RemovePlayer(source, skipClient)
    if not GunGame.players[source] then return end
    
    local playerData = GunGame.players[source]
    
    GunGame.players[source] = nil
    
    -- ⭐ REMETTRE DANS LE BUCKET 0 (gf_respawn fonctionne ici) ⭐
    if Config.RoutingBucket.enabled then
        SetPlayerRoutingBucket(source, Config.RoutingBucket.defaultBucket)
        print('^2[GunGame][BUCKET]^7 ' .. playerData.name .. ' remis dans le bucket ' .. Config.RoutingBucket.defaultBucket)
    end
    
    if not skipClient then
        TriggerClientEvent('gungame:client:leaveGame', source)
    end
    
    BroadcastLeaderboard()
    BroadcastPlayerBlips()
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FONCTION : DIFFUSER LE CLASSEMENT (LIMITÉ À 5) ⭐ CORRIGÉ ⭐
-- ═══════════════════════════════════════════════════════════════════════════
function BroadcastLeaderboard()
    local leaderboard = {}
    
    for source, playerData in pairs(GunGame.players) do
        table.insert(leaderboard, {
            id = source,
            name = playerData.name,
            weaponIndex = playerData.weaponIndex,
            kills = playerData.kills,
            totalKills = playerData.totalKills,
            deaths = playerData.deaths
        })
    end
    
    table.sort(leaderboard, function(a, b)
        if a.weaponIndex == b.weaponIndex then
            return a.totalKills > b.totalKills
        end
        return a.weaponIndex > b.weaponIndex
    end)
    
    -- ⭐ LIMITER À 5 JOUEURS ⭐
    local limitedLeaderboard = {}
    for i = 1, math.min(#leaderboard, 5) do
        table.insert(limitedLeaderboard, leaderboard[i])
    end
    
    print('^5[GunGame][LEADERBOARD]^7 Diffusion du classement à ' .. GetTableLength(GunGame.players) .. ' joueurs')
    print('^5[GunGame][LEADERBOARD]^7 Contenu (top 5): ' .. json.encode(limitedLeaderboard))
    
    for source, _ in pairs(GunGame.players) do
        TriggerClientEvent('gungame:client:updateLeaderboard', source, limitedLeaderboard)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FONCTION : DIFFUSER LES BLIPS JOUEURS
-- ═══════════════════════════════════════════════════════════════════════════
function BroadcastPlayerBlips()
    if not Config.PlayerBlips.enabled then return end
    
    local players = {}
    
    for source, playerData in pairs(GunGame.players) do
        local ped = GetPlayerPed(source)
        if ped and ped > 0 then
            local coords = GetEntityCoords(ped)
            table.insert(players, {
                id = source,
                name = playerData.name,
                x = coords.x,
                y = coords.y,
                z = coords.z
            })
        end
    end
    
    for source, _ in pairs(GunGame.players) do
        TriggerClientEvent('gungame:client:updatePlayerBlips', source, players)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FONCTION : FIN DE PARTIE
-- ═══════════════════════════════════════════════════════════════════════════
function EndGame(winnerData)
    GunGame.activeGame = false
    GunGame.winner = winnerData.name
    
    local leaderboard = {}
    for source, playerData in pairs(GunGame.players) do
        table.insert(leaderboard, {
            id = source,
            name = playerData.name,
            weaponIndex = playerData.weaponIndex,
            totalKills = playerData.totalKills
        })
    end
    
    table.sort(leaderboard, function(a, b)
        if a.weaponIndex == b.weaponIndex then
            return a.totalKills > b.totalKills
        end
        return a.weaponIndex > b.weaponIndex
    end)
    
    local top3 = {}
    for i = 1, math.min(3, #leaderboard) do
        table.insert(top3, leaderboard[i])
    end
    
    print('^2[GunGame][VICTOIRE]^7 🏆 ' .. winnerData.name .. ' a gagné !')
    
    for source, _ in pairs(GunGame.players) do
        TriggerClientEvent('gungame:client:gameEnd', source, winnerData.name, top3)
    end
    
    SetTimeout(Config.UI.endScreenDuration, function()
        for source, _ in pairs(GunGame.players) do
            RemovePlayer(source, false)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- THREAD : MISE À JOUR DES BLIPS
-- ═══════════════════════════════════════════════════════════════════════════
CreateThread(function()
    while true do
        if Config.PlayerBlips.enabled then
            BroadcastPlayerBlips()
        end
        Wait(Config.PlayerBlips.updateInterval or 2000)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- THREAD : MISE À JOUR DU CLASSEMENT
-- ═══════════════════════════════════════════════════════════════════════════
CreateThread(function()
    while true do
        Wait(5000)
        if GetTableLength(GunGame.players) > 0 then
            BroadcastLeaderboard()
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- HANDLER : DÉCONNEXION ⭐ CORRIGÉ POUR ÉVITER LES BUGS ⭐
-- ═══════════════════════════════════════════════════════════════════════════
AddEventHandler('playerDropped', function(reason)
    local source = source
    
    if GunGame.players[source] then
        local playerName = GunGame.players[source].name
        print('^3[GunGame][DISCONNECT]^7 ' .. playerName .. ' s\'est déconnecté (' .. reason .. ')')
        
        -- Retirer du jeu immédiatement
        GunGame.players[source] = nil
        
        -- Remettre dans le bucket par défaut (au cas où)
        if Config.RoutingBucket.enabled then
            SetPlayerRoutingBucket(source, Config.RoutingBucket.defaultBucket)
        end
        
        -- Force update du classement
        Wait(100)
        BroadcastLeaderboard()
        
        print('^2[GunGame][DISCONNECT]^7 ' .. playerName .. ' retiré du classement')
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- COMMANDES ADMIN
-- ═══════════════════════════════════════════════════════════════════════════
ESX.RegisterCommand('ggkick', Config.AdminGroup, function(xPlayer, args, showError)
    local targetId = tonumber(args.id)
    
    if not targetId then
        TriggerClientEvent('esx:showNotification', xPlayer.source, '~r~Usage: /ggkick [id]')
        return
    end
    
    if GunGame.players[targetId] then
        RemovePlayer(targetId, false)
        TriggerClientEvent('esx:showNotification', xPlayer.source, '~g~Joueur kick du GunGame')
        print('^2[GunGame][ADMIN]^7 ' .. xPlayer.getName() .. ' a kick le joueur ' .. targetId)
    else
        TriggerClientEvent('esx:showNotification', xPlayer.source, '~r~Ce joueur n\'est pas en partie')
    end
end, false, {help = 'Kick un joueur du GunGame', validate = true, arguments = {
    {name = 'id', help = 'ID du joueur', type = 'number'}
}})

ESX.RegisterCommand('ggkickall', Config.AdminGroup, function(xPlayer, args, showError)
    local count = 0
    for source, _ in pairs(GunGame.players) do
        RemovePlayer(source, false)
        count = count + 1
    end
    
    TriggerClientEvent('esx:showNotification', xPlayer.source, '~g~' .. count .. ' joueur(s) kick du GunGame')
    print('^2[GunGame][ADMIN]^7 ' .. xPlayer.getName() .. ' a kick tous les joueurs (' .. count .. ')')
end, false, {help = 'Kick tous les joueurs du GunGame', validate = false})

ESX.RegisterCommand('gglist', Config.AdminGroup, function(xPlayer, args, showError)
    local count = GetTableLength(GunGame.players)
    
    if count == 0 then
        TriggerClientEvent('esx:showNotification', xPlayer.source, '~y~Aucun joueur en partie')
        return
    end
    
    print('^5[GunGame][LIST]^7 ==== JOUEURS EN PARTIE (' .. count .. ') ====')
    for source, playerData in pairs(GunGame.players) do
        print(string.format('^5[GunGame][LIST]^7 [%d] %s - Arme: %d/40 - Kills: %d (%d total)', 
            source, playerData.name, playerData.weaponIndex, playerData.kills, playerData.totalKills))
    end
    
    TriggerClientEvent('esx:showNotification', xPlayer.source, '~g~Liste affichée dans la console serveur')
end, false, {help = 'Liste les joueurs en partie', validate = false})

-- ═══════════════════════════════════════════════════════════════════════════
-- UTILITAIRES
-- ═══════════════════════════════════════════════════════════════════════════
function GetTableLength(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- ═══════════════════════════════════════════════════════════════════════════
-- INITIALISATION
-- ═══════════════════════════════════════════════════════════════════════════
CreateThread(function()
    Wait(1000)
    print('^2[GunGame]^7 ========================================')
    print('^2[GunGame]^7 Server initialisé avec succès')
    print('^2[GunGame]^7 Mode Instance: ' .. (Config.RoutingBucket.enabled and 'ACTIVÉ (bucket ' .. Config.RoutingBucket.bucketId .. ')' or 'DÉSACTIVÉ'))
    print('^2[GunGame]^7 Max joueurs: ' .. Config.MaxPlayersPerGame)
    print('^2[GunGame]^7 Total armes: ' .. Config.TotalWeapons)
    print('^2[GunGame]^7 Classement: Top 5')
    print('^2[GunGame]^7 Commande joueur: /quitgungame')
    print('^2[GunGame]^7 ========================================')
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════
exports('getPlayers', function() return GunGame.players end)
exports('getPlayerCount', function() return GetTableLength(GunGame.players) end)
exports('isPlayerInGame', function(source) return GunGame.players[source] ~= nil end)
