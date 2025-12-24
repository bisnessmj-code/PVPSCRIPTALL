--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                        SERVER - MAIN.LUA                                   ║
    ║           Optimisé : Logging centralisé, zéro spam console                ║
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
-- FONCTION : RÉCUPÉRER LE NOM FIVEM
-- ═══════════════════════════════════════════════════════════════════════════
function GetFiveMName(source)
    return GetPlayerName(source) or "Unknown"
end

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
    
    Logger.Debug('SERVER', 'Inventaire vidé pour %s', GetFiveMName(source))
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- ÉVÉNEMENT : DEMANDE DE REJOINDRE
-- ═══════════════════════════════════════════════════════════════════════════
RegisterNetEvent('gungame:server:requestJoin', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        Logger.Error('SERVER', 'Joueur invalide (source: %d)', source)
        return
    end
    
    if GunGame.players[source] then
        Logger.Warn('SERVER', 'Joueur %s déjà en partie', GetFiveMName(source))
        return
    end
    
    local currentPlayers = 0
    for _ in pairs(GunGame.players) do
        currentPlayers = currentPlayers + 1
    end
    
    if currentPlayers >= Config.MaxPlayersPerGame then
        TriggerClientEvent('esx:showNotification', source, '~r~La partie est complète !')
        Logger.Warn('SERVER', 'Partie complète - Joueur refusé: %s', GetFiveMName(source))
        return
    end
    
    local fiveMName = GetFiveMName(source)
    
    local playerData = {
        source = source,
        identifier = xPlayer.identifier,
        name = fiveMName,
        weaponIndex = 1,
        kills = 0,
        totalKills = 0,
        deaths = 0,
        joinTime = os.time()
    }
    
    GunGame.players[source] = playerData
    
    if Config.RoutingBucket.enabled then
        SetPlayerRoutingBucket(source, Config.RoutingBucket.bucketId)
        Logger.Debug('BUCKET', '%s mis dans le bucket %d', playerData.name, Config.RoutingBucket.bucketId)
    end
    
    TriggerClientEvent('gungame:client:joinGame', source, 1)
    
    Logger.Info('JOIN', '%s a rejoint (%d/%d)', playerData.name, currentPlayers + 1, Config.MaxPlayersPerGame)
    
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
        Logger.Warn('SERVER', 'Joueur %d pas en partie', source)
        TriggerClientEvent('esx:showNotification', source, '~r~Tu n\'es pas dans le GunGame !')
        return
    end
    
    local playerData = GunGame.players[source]
    Logger.Info('LEAVE', '%s quitte la partie', playerData.name)
    
    RemovePlayer(source)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- FONCTION : RETIRER UN JOUEUR
-- ═══════════════════════════════════════════════════════════════════════════
function RemovePlayer(source, skipClient)
    if not GunGame.players[source] then return end
    
    local playerData = GunGame.players[source]
    
    GunGame.players[source] = nil
    
    if Config.RoutingBucket.enabled then
        SetPlayerRoutingBucket(source, Config.RoutingBucket.defaultBucket)
        Logger.Debug('BUCKET', '%s remis dans le bucket %d', playerData.name, Config.RoutingBucket.defaultBucket)
    end
    
    if not skipClient then
        TriggerClientEvent('gungame:client:leaveGame', source)
    end
    
    BroadcastLeaderboard()
    BroadcastPlayerBlips()
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FONCTION : DIFFUSER LE CLASSEMENT
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
    
    local limitedLeaderboard = {}
    for i = 1, math.min(#leaderboard, 5) do
        table.insert(limitedLeaderboard, leaderboard[i])
    end
    
    Logger.Debug('LEADERBOARD', 'Diffusion à %d joueurs', GetTableLength(GunGame.players))
    
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
    
    Logger.Info('VICTORY', '🏆 %s a gagné !', winnerData.name)
    
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
-- HANDLER : DÉCONNEXION
-- ═══════════════════════════════════════════════════════════════════════════
AddEventHandler('playerDropped', function(reason)
    local source = source
    
    if GunGame.players[source] then
        local playerName = GunGame.players[source].name
        Logger.Info('DISCONNECT', '%s s\'est déconnecté (%s)', playerName, reason)
        
        GunGame.players[source] = nil
        
        if Config.RoutingBucket.enabled then
            SetPlayerRoutingBucket(source, Config.RoutingBucket.defaultBucket)
        end
        
        Wait(100)
        BroadcastLeaderboard()
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
        Logger.Info('ADMIN', '%s a kick le joueur %d', GetFiveMName(xPlayer.source), targetId)
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
    Logger.Info('ADMIN', '%s a kick tous les joueurs (%d)', GetFiveMName(xPlayer.source), count)
end, false, {help = 'Kick tous les joueurs du GunGame', validate = false})

ESX.RegisterCommand('gglist', Config.AdminGroup, function(xPlayer, args, showError)
    local count = GetTableLength(GunGame.players)
    
    if count == 0 then
        TriggerClientEvent('esx:showNotification', xPlayer.source, '~y~Aucun joueur en partie')
        return
    end
    
    Logger.Info('LIST', '==== JOUEURS EN PARTIE (%d) ====', count)
    for source, playerData in pairs(GunGame.players) do
        Logger.Info('LIST', '[%d] %s - Arme: %d/40 - Kills: %d (%d total)', 
            source, playerData.name, playerData.weaponIndex, playerData.kills, playerData.totalKills)
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
    Logger.Info('SERVER', '========================================')
    Logger.Info('SERVER', 'Server initialisé avec succès')
    Logger.Info('SERVER', 'Mode Instance: %s', Config.RoutingBucket.enabled and 'ACTIVÉ (bucket ' .. Config.RoutingBucket.bucketId .. ')' or 'DÉSACTIVÉ')
    Logger.Info('SERVER', 'Max joueurs: %d', Config.MaxPlayersPerGame)
    Logger.Info('SERVER', 'Total armes: %d', Config.TotalWeapons)
    Logger.Info('SERVER', 'Classement: Top 5')
    Logger.Info('SERVER', 'Noms: FiveM (natifs)')
    Logger.Info('SERVER', 'Logging: %s', Config.Debug and 'DEBUG' or Config.LogLevel:upper())
    Logger.Info('SERVER', '========================================')
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════
exports('getPlayers', function() return GunGame.players end)
exports('getPlayerCount', function() return GetTableLength(GunGame.players) end)
exports('isPlayerInGame', function(source) return GunGame.players[source] ~= nil end)
exports('getFiveMName', GetFiveMName)
