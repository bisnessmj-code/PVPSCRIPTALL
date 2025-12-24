--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║              FIGHTLEAGUE COURSE - UTILITAIRES                 ║
    ║                Système de Logs Centralisé                     ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    RÈGLE : Aucun print() direct dans le code
    Tous les logs passent par cette fonction centrale
]]

Utils = {}

-- ═════════════════════════════════════════════════════════════════
-- SYSTÈME DE LOGS CENTRALISÉ
-- ═════════════════════════════════════════════════════════════════
--[[
    Fonction de log centralisée avec contrôle par module
    
    @param module   string  Nom du module (Client, Server, Matchmaking, etc.)
    @param message  string  Message à logger
    @param level    string  Niveau de log : 'info', 'warn', 'error'
    
    Impact CPU : Négligeable (vérification conditionnelle simple)
]]
function Utils.Log(module, message, level)
    -- Vérification si le debug est activé pour ce module
    if not Config.IsDebugEnabled(module) then return end
    
    level = level or 'info'
    local prefix = ''
    
    -- Définir la couleur selon le niveau
    if level == 'error' then
        prefix = '^1[ERREUR]^7'
    elseif level == 'warn' then
        prefix = '^3[ATTENTION]^7'
    else
        prefix = '^2[INFO]^7'
    end
    
    -- Formatage du message
    local side = IsDuplicityVersion() and 'SERVER' or 'CLIENT'
    
    -- Timestamp compatible client/serveur
    local timestamp
    if IsDuplicityVersion() then
        -- Côté serveur : os.date disponible
        timestamp = os.date('%H:%M:%S')
    else
        -- Côté client : utiliser GetGameTimer pour un timestamp relatif
        local timer = GetGameTimer()
        local seconds = math.floor(timer / 1000) % 60
        local minutes = math.floor(timer / 60000) % 60
        local hours = math.floor(timer / 3600000)
        timestamp = string.format('%02d:%02d:%02d', hours, minutes, seconds)
    end
    
    print(string.format('^5[%s]^7 %s ^6[%s]^7 %s', 
        timestamp, 
        prefix, 
        module, 
        message
    ))
end

-- ═════════════════════════════════════════════════════════════════
-- FONCTIONS UTILITAIRES
-- ═════════════════════════════════════════════════════════════════

--[[
    Calcule la distance entre deux positions
    
    @param pos1  vector3
    @param pos2  vector3
    @return      float   Distance en unités
    
    Impact CPU : Très faible (calcul mathématique simple)
    Note : Utilisé uniquement côté client avec cache
]]
function Utils.GetDistance(pos1, pos2)
    return #(pos1 - pos2)
end

--[[
    Affiche une notification à l'écran
    
    @param message  string  Message à afficher
    @param type     string  Type : 'success', 'error', 'info'
    
    Impact CPU : Faible (native GTA)
    Fréquence : Événementiel uniquement
]]
function Utils.Notify(message, type)
    if IsDuplicityVersion() then return end -- Côté client uniquement
    
    type = type or 'info'
    
    -- Notification native GTA
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(false, true)
end

--[[
    Affiche du texte d'aide en bas de l'écran
    
    @param message  string  Message à afficher
    
    Impact CPU : Très faible (native GTA)
    Fréquence : Conditionnel (seulement près du PED)
]]
function Utils.ShowHelpText(message)
    if IsDuplicityVersion() then return end
    
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

--[[
    Vérifie si un joueur a une permission
    
    @param source      int     ID du joueur (0 = console serveur)
    @param permission  string  Nom de la permission
    @return            bool    true si le joueur a la permission
    
    Impact CPU : Faible (vérification simple)
    Note : À adapter selon votre système de permissions (ESX, QBCore, etc.)
]]
function Utils.HasPermission(source, permission)
    if not IsDuplicityVersion() then return false end
    
    -- Si c'est la console serveur (source = 0), toujours autoriser
    if source == 0 then
        return true
    end
    
    -- Vérifier que le joueur existe
    if not source or GetPlayerPing(source) == 0 then
        return false
    end
    
    -- TODO: Intégrer avec votre framework (ESX, QBCore, etc.)
    -- Exemple basique : vérifie si le joueur est admin
    
    -- Version basique (à remplacer)
    return IsPlayerAceAllowed(source, permission)
    
    -- Version ESX (exemple)
    -- local xPlayer = ESX.GetPlayerFromId(source)
    -- return xPlayer and xPlayer.getGroup() == permission
    
    -- Version QBCore (exemple)
    -- local Player = QBCore.Functions.GetPlayer(source)
    -- return Player and QBCore.Functions.HasPermission(source, permission)
end

--[[
    Génère un ID unique pour une partie
    
    @return  string  ID unique
    
    Impact CPU : Négligeable
]]
function Utils.GenerateGameId()
    if IsDuplicityVersion() then
        -- Côté serveur : os.time disponible
        return 'game_' .. os.time() .. '_' .. math.random(1000, 9999)
    else
        -- Côté client : utiliser GetGameTimer
        return 'game_' .. GetGameTimer() .. '_' .. math.random(1000, 9999)
    end
end

--[[
    Nettoie les ressources d'un joueur
    Utilisé lors de la déconnexion ou de l'éjection
    
    @param source  int  ID du joueur
    
    Impact CPU : Faible (cleanup ponctuel)
]]
function Utils.CleanupPlayer(source)
    if not IsDuplicityVersion() then return end
    
    Utils.Log('Server', 'Nettoyage des ressources pour le joueur ' .. source, 'info')
    
    -- Réinitialiser le routing bucket
    SetPlayerRoutingBucket(source, 0)
    
    -- Autres nettoyages si nécessaire
end

-- ═════════════════════════════════════════════════════════════════
-- EXPORTS (si besoin d'utiliser depuis d'autres scripts)
-- ═════════════════════════════════════════════════════════════════
exports('Log', Utils.Log)
exports('Notify', Utils.Notify)