--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║              FIGHTLEAGUE COURSE - UTILITAIRES                 ║
    ║                Système de Logs Centralisé                     ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    CORRECTIF : Logs serveur compatibles avec toutes les versions FiveM
]]

Utils = {}

-- ═════════════════════════════════════════════════════════════════
-- SYSTÈME DE LOGS CENTRALISÉ
-- ═════════════════════════════════════════════════════════════════

function Utils.Log(module, message, level)
    if not Config.IsDebugEnabled(module) then return end
    
    level = level or 'info'
    local prefix = ''
    
    if level == 'error' then
        prefix = '^1[ERREUR]^7'
    elseif level == 'warn' then
        prefix = '^3[ATTENTION]^7'
    else
        prefix = '^2[INFO]^7'
    end
    
    -- CORRECTIF : Timestamp simplifié et compatible
    local timestamp
    if IsDuplicityVersion() then
        -- Côté serveur : utiliser un compteur simple ou os.time() formaté manuellement
        local success, time = pcall(os.date, '%H:%M:%S')
        if success then
            timestamp = time
        else
            -- Fallback si os.date ne fonctionne pas
            local rawTime = os.time()
            local hours = math.floor((rawTime % 86400) / 3600)
            local minutes = math.floor((rawTime % 3600) / 60)
            local seconds = rawTime % 60
            timestamp = string.format('%02d:%02d:%02d', hours, minutes, seconds)
        end
    else
        -- Côté client : utiliser GetGameTimer
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

function Utils.GetDistance(pos1, pos2)
    return #(pos1 - pos2)
end

function Utils.Notify(message, type)
    if IsDuplicityVersion() then return end
    
    type = type or 'info'
    
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(false, true)
end

function Utils.ShowHelpText(message)
    if IsDuplicityVersion() then return end
    
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

function Utils.HasPermission(source, permission)
    if not IsDuplicityVersion() then return false end
    
    if source == 0 then
        return true
    end
    
    if not source or GetPlayerPing(source) == 0 then
        return false
    end
    
    return IsPlayerAceAllowed(source, permission)
end

function Utils.GenerateGameId()
    if IsDuplicityVersion() then
        return 'game_' .. os.time() .. '_' .. math.random(1000, 9999)
    else
        return 'game_' .. GetGameTimer() .. '_' .. math.random(1000, 9999)
    end
end

function Utils.CleanupPlayer(source)
    if not IsDuplicityVersion() then return end
    
    Utils.Log('Server', 'Nettoyage des ressources pour le joueur ' .. source, 'info')
    
    SetPlayerRoutingBucket(source, 0)
end

-- ═════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═════════════════════════════════════════════════════════════════
exports('Log', Utils.Log)
exports('Notify', Utils.Notify)