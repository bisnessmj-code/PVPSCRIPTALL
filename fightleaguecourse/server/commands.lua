--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║          FIGHTLEAGUE COURSE - COMMANDES ADMIN                 ║
    ║                  Gestion Administrative                       ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    COMMANDES DISPONIBLES :
    - /kickallcourse   : Éjecter tous les joueurs des parties
    - /kickbyid [id]   : Éjecter un joueur spécifique
    - /coursestatus    : Voir le statut (parties en cours, queue)
]]

-- ═════════════════════════════════════════════════════════════════
-- RÉCUPÉRATION DES DONNÉES DEPUIS SERVER/MAIN.LUA
-- ═════════════════════════════════════════════════════════════════

--[[
    Note : On utilise les exports pour récupérer les données
    depuis server/main.lua au lieu de dupliquer les variables
    
    Impact CPU : Négligeable (appel de fonction simple)
]]
local function GetActiveGames()
    return exports[GetCurrentResourceName()]:GetActiveGames()
end

local function GetMatchmakingQueue()
    return exports[GetCurrentResourceName()]:GetMatchmakingQueue()
end

local function GetActivePlayers()
    return exports[GetCurrentResourceName()]:GetActivePlayers()
end

-- ═════════════════════════════════════════════════════════════════
-- FONCTIONS UTILITAIRES
-- ═════════════════════════════════════════════════════════════════

--[[
    Envoie un message à un joueur ou à la console
    
    @param source   int     ID du joueur (0 = console)
    @param message  string  Message à envoyer
    @param color    table   Couleur RGB (optionnel)
]]
local function SendMessage(source, message, color)
    if source == 0 then
        -- Console serveur
        print(message)
    else
        -- Joueur dans le jeu
        color = color or {255, 255, 255}
        TriggerClientEvent('chat:addMessage', source, {
            color = color,
            multiline = true,
            args = {"Système", message}
        })
    end
end

-- ═════════════════════════════════════════════════════════════════
-- COMMANDE : /kickallcourse
-- ═════════════════════════════════════════════════════════════════

--[[
    Éjecte tous les joueurs de toutes les parties
    
    Permission : Config.Permissions.KickAll
    Impact CPU : Ponctuel (parcours des parties actives)
]]
RegisterCommand('kickallcourse', function(source, args, rawCommand)
    -- Vérifier les permissions
    if not Utils.HasPermission(source, Config.Permissions.KickAll) then
        SendMessage(source, Config.Lang.NoPermission, {255, 0, 0})
        return
    end
    
    Utils.Log('Commands', 'Admin ' .. source .. ' exécute /kickallcourse', 'warn')
    
    local activeGames = GetActiveGames()
    local kickedCount = 0
    
    -- Parcourir toutes les parties actives
    for gameId, _ in pairs(activeGames) do
        -- Utiliser la fonction EndGame du serveur principal
        -- Note : EndGame est une fonction globale définie dans server/main.lua
        EndGame(gameId, 'admin_kick_all')
        kickedCount = kickedCount + 1
    end
    
    -- Message de confirmation
    local message = string.format('Toutes les parties ont été arrêtées (%d partie(s))', kickedCount)
    
    SendMessage(source, message, {0, 255, 0})
    
    Utils.Log('Commands', message, 'info')
end, false)

-- ═════════════════════════════════════════════════════════════════
-- COMMANDE : /kickbyid [id]
-- ═════════════════════════════════════════════════════════════════

--[[
    Éjecte un joueur spécifique d'une partie
    
    Permission : Config.Permissions.KickById
    Usage : /kickbyid [server_id]
    Impact CPU : Ponctuel (recherche d'un joueur)
]]
RegisterCommand('kickbyid', function(source, args, rawCommand)
    -- Vérifier les permissions
    if not Utils.HasPermission(source, Config.Permissions.KickById) then
        SendMessage(source, Config.Lang.NoPermission, {255, 0, 0})
        return
    end
    
    -- Vérifier les arguments
    if #args < 1 then
        SendMessage(source, "Usage: /kickbyid [server_id]", {255, 165, 0})
        return
    end
    
    local targetId = tonumber(args[1])
    
    if not targetId then
        SendMessage(source, "ID invalide", {255, 0, 0})
        return
    end
    
    Utils.Log('Commands', 'Admin ' .. source .. ' exécute /kickbyid sur le joueur ' .. targetId, 'warn')
    
    -- Vérifier si le joueur existe
    if GetPlayerPing(targetId) == 0 then
        SendMessage(source, Config.Lang.PlayerNotFound, {255, 0, 0})
        return
    end
    
    -- Récupérer les données du joueur
    local activePlayers = GetActivePlayers()
    local playerData = activePlayers[targetId]
    
    if not playerData then
        SendMessage(source, "Le joueur n'est pas en partie", {255, 165, 0})
        return
    end
    
    -- Terminer la partie du joueur
    local gameId = playerData.gameId
    EndGame(gameId, 'admin_kick_id')
    
    -- Message de confirmation
    local message = string.format(Config.Lang.PlayerKicked, targetId)
    
    SendMessage(source, message, {0, 255, 0})
    
    Utils.Log('Commands', message, 'info')
end, false)

-- ═════════════════════════════════════════════════════════════════
-- COMMANDE : /coursestatus
-- ═════════════════════════════════════════════════════════════════

--[[
    Affiche le statut du système de courses
    
    Permission : Config.Permissions.ViewStatus
    Impact CPU : Ponctuel (parcours des tables)
]]
RegisterCommand('coursestatus', function(source, args, rawCommand)
    -- Vérifier les permissions
    if not Utils.HasPermission(source, Config.Permissions.ViewStatus) then
        SendMessage(source, Config.Lang.NoPermission, {255, 0, 0})
        return
    end
    
    Utils.Log('Commands', 'Admin ' .. source .. ' exécute /coursestatus', 'info')
    
    local activeGames = GetActiveGames()
    local queue = GetMatchmakingQueue()
    local activePlayers = GetActivePlayers()
    
    -- Compter les parties actives
    local gameCount = 0
    for _ in pairs(activeGames) do
        gameCount = gameCount + 1
    end
    
    -- Compter les joueurs en partie
    local playersInGame = 0
    for _ in pairs(activePlayers) do
        playersInGame = playersInGame + 1
    end
    
    -- Construire le message de statut
    local statusMessage = string.format([[
╔════════════════════════════════════════╗
║     FIGHTLEAGUE COURSE - STATUT        ║
╠════════════════════════════════════════╣
║ Parties en cours   : %d                
║ Joueurs en partie  : %d                
║ File d'attente     : %d                
║ Limite parties     : %d                
╚════════════════════════════════════════╝
    ]], 
        gameCount,
        playersInGame,
        #queue,
        Config.Matchmaking.MaxConcurrentGames
    )
    
    -- Envoyer dans le chat ou la console
    if source == 0 then
        -- Console : affichage direct
        print(statusMessage)
    else
        -- Joueur : utiliser le chat
        TriggerClientEvent('chat:addMessage', source, {
            color = {100, 200, 255},
            multiline = true,
            args = {"Statut", statusMessage}
        })
    end
    
    -- Détails des parties actives (si demandé)
    if args[1] == 'detail' then
        for gameId, game in pairs(activeGames) do
            local details = string.format(
                "Partie %s | Bucket: %d | Status: %s | Joueurs: %d,%d",
                gameId,
                game.bucket,
                game.status,
                game.players[1].source,
                game.players[2].source
            )
            
            if source == 0 then
                print("→ " .. details)
            else
                TriggerClientEvent('chat:addMessage', source, {
                    color = {200, 200, 200},
                    multiline = false,
                    args = {"→", details}
                })
            end
        end
    end
    
    Utils.Log('Commands', 'Statut affiché à l\'admin ' .. source, 'info')
end, false)

-- ═════════════════════════════════════════════════════════════════
-- SUGGESTIONS DE COMMANDES (Auto-complétion)
-- ═════════════════════════════════════════════════════════════════

TriggerEvent('chat:addSuggestion', '/kickallcourse', 'Éjecte tous les joueurs des parties en cours')
TriggerEvent('chat:addSuggestion', '/kickbyid', 'Éjecte un joueur spécifique', {
    {name = "id", help = "ID du joueur (server ID)"}
})
TriggerEvent('chat:addSuggestion', '/coursestatus', 'Affiche le statut du système de courses', {
    {name = "detail", help = "(Optionnel) Affiche les détails des parties"}
})

-- ═════════════════════════════════════════════════════════════════
-- LOG DE DÉMARRAGE
-- ═════════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(1000) -- Attendre que le serveur soit prêt
    
    Utils.Log('Commands', 'Commandes administrateur chargées', 'info')
    Utils.Log('Commands', '- /kickallcourse : Éjecter tous les joueurs', 'info')
    Utils.Log('Commands', '- /kickbyid [id] : Éjecter un joueur spécifique', 'info')
    Utils.Log('Commands', '- /coursestatus : Voir le statut', 'info')
end)