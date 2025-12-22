-- ========================================
-- PVP GUNFIGHT - DISCORD LEADERBOARDS
-- Style GUNFIGHT ARENA v4.1 - WEBHOOKS SÉCURISÉS
-- ========================================

DebugServer('Module Discord Leaderboards charge (Webhooks sécurisés)')

-- ========================================
-- VARIABLES
-- ========================================
local lastSendTime = {}
local isSending = false

-- ========================================
-- LOGGING
-- ========================================
local function LogError(msg) print("^1[PVP-Discord ERROR]^0 " .. tostring(msg)) end
local function LogSuccess(msg) print("^2[PVP-Discord OK]^0 " .. tostring(msg)) end
local function LogInfo(msg) print("^6[PVP-Discord]^0 " .. tostring(msg)) end

-- ========================================
-- SANITIZATION DES NOMS
-- ========================================
local function SanitizePlayerName(name)
    if not name or name == "" then 
        return "Joueur"
    end
    
    name = tostring(name)
    local cleaned = ""
    
    for i = 1, #name do
        local char = name:sub(i, i)
        local byte = string.byte(char)
        if (byte >= 65 and byte <= 90) or 
           (byte >= 97 and byte <= 122) or 
           (byte >= 48 and byte <= 57) or 
           byte == 32 or byte == 45 or byte == 95 or byte == 46 then
            cleaned = cleaned .. char
        end
    end
    
    if cleaned == "" or cleaned:match("^%s*$") then
        return "Joueur"
    end
    
    cleaned = cleaned:match("^%s*(.-)%s*$")
    return cleaned
end

local function FormatPlayerName(name, maxLength)
    name = SanitizePlayerName(name)
    maxLength = maxLength or 20
    if #name > maxLength then
        return string.sub(name, 1, maxLength - 3) .. "..."
    end
    return name
end

local function SafeNumber(num, default)
    local n = tonumber(num)
    if n and n == n and n ~= math.huge and n ~= -math.huge then
        return n
    end
    return default or 0
end

-- ========================================
-- CALCUL K/D
-- ========================================
local function CalculateKD(kills, deaths)
    kills = SafeNumber(kills, 0)
    deaths = SafeNumber(deaths, 0)
    if deaths == 0 then
        return kills > 0 and string.format("%.2f", kills) or "0.00"
    end
    return string.format("%.2f", kills / deaths)
end

-- ========================================
-- FORMATER NOMBRE
-- ========================================
local function FormatNumber(num)
    num = SafeNumber(num, 0)
    local formatted = tostring(math.floor(num))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1 %2')
        if k == 0 then break end
    end
    return formatted
end

-- ========================================
-- OBTENIR RANG PAR ELO
-- ========================================
local function GetRankByElo(elo)
    elo = SafeNumber(elo, 1000)
    
    for _, rank in ipairs(ConfigDiscordLeaderboard.RankSystem.ranks) do
        if elo >= rank.min_elo then
            return rank
        end
    end
    return ConfigDiscordLeaderboard.RankSystem.ranks[#ConfigDiscordLeaderboard.RankSystem.ranks]
end

-- ========================================
-- EMOJIS
-- ========================================
local EMOJIS = {
    rank = {[1] = "🥇", [2] = "🥈", [3] = "🥉"},
    stats = {
        kills = "⚔️",
        deaths = "💀",
        kd = "📊",
        elo = "⚡",
        wins = "🏆",
        streak = "🔥",
        players = "👥"
    },
    misc = {
        trophy = "🏆",
        crown = "👑",
        fire = "🔥",
        star = "⭐"
    }
}

-- ========================================
-- COULEURS PAR MODE
-- ========================================
local COLORS = {
    ['1v1'] = 15158332,  -- Rouge
    ['2v2'] = 3447003,   -- Bleu
    ['3v3'] = 16750848,  -- Orange
    ['4v4'] = 5763719    -- Vert
}

-- ========================================
-- NOMS DES MODES
-- ========================================
local MODE_NAMES = {
    ['1v1'] = 'SOLO 1v1',
    ['2v2'] = 'DUO 2v2',
    ['3v3'] = 'TRIO 3v3',
    ['4v4'] = 'SQUAD 4v4'
}

-- ========================================
-- CRÉATION EMBED STYLE GUNFIGHT ARENA
-- ========================================
local function CreateLeaderboardEmbed(mode, leaderboardData)
    local modeName = MODE_NAMES[mode] or mode:upper()
    local color = COLORS[mode] or 65535
    
    local fields = {}
    
    -- ========================================
    -- CALCUL STATS GLOBALES
    -- ========================================
    local totalPlayers = #leaderboardData
    local totalKills = 0
    local totalDeaths = 0
    local totalElo = 0
    local bestElo = 0
    local bestStreak = 0
    
    for i = 1, #leaderboardData do
        local p = leaderboardData[i]
        totalKills = totalKills + SafeNumber(p.kills, 0)
        totalDeaths = totalDeaths + SafeNumber(p.deaths, 0)
        totalElo = totalElo + SafeNumber(p.elo, 1000)
        
        if SafeNumber(p.elo, 0) > bestElo then
            bestElo = SafeNumber(p.elo, 0)
        end
        if SafeNumber(p.best_streak, 0) > bestStreak then
            bestStreak = SafeNumber(p.best_streak, 0)
        end
    end
    
    local avgElo = totalPlayers > 0 and math.floor(totalElo / totalPlayers) or 0
    local globalKD = CalculateKD(totalKills, totalDeaths)
    
    -- ========================================
    -- STATS GLOBALES EN FIELDS INLINE
    -- ========================================
    if ConfigDiscordLeaderboard.ShowGlobalStatsTop then
        table.insert(fields, {
            name = EMOJIS.stats.players .. " Joueurs",
            value = "```" .. FormatNumber(totalPlayers) .. "```",
            inline = true
        })
        table.insert(fields, {
            name = EMOJIS.stats.kills .. " Kills",
            value = "```" .. FormatNumber(totalKills) .. "```",
            inline = true
        })
        table.insert(fields, {
            name = EMOJIS.stats.deaths .. " Morts",
            value = "```" .. FormatNumber(totalDeaths) .. "```",
            inline = true
        })
        table.insert(fields, {
            name = EMOJIS.stats.elo .. " ELO Moyen",
            value = "```" .. FormatNumber(avgElo) .. "```",
            inline = true
        })
        table.insert(fields, {
            name = EMOJIS.stats.kd .. " K/D Global",
            value = "```" .. globalKD .. "```",
            inline = true
        })
        table.insert(fields, {
            name = EMOJIS.stats.streak .. " Record",
            value = "```" .. FormatNumber(bestStreak) .. "```",
            inline = true
        })
    end
    
    -- ========================================
    -- CLASSEMENT TOP 10
    -- ========================================
    if #leaderboardData > 0 then
        local rankText = ""
        
        for i = 1, math.min(10, #leaderboardData) do
            local data = leaderboardData[i]
            local medal = EMOJIS.rank[i] or "▫️"
            local playerName = FormatPlayerName(data.name, 22)
            local elo = SafeNumber(data.elo, 1000)
            local kills = SafeNumber(data.kills, 0)
            local deaths = SafeNumber(data.deaths, 0)
            local kd = CalculateKD(kills, deaths)
            local rank = GetRankByElo(elo)
            
            rankText = rankText .. string.format(
                "%s **#%02d %s**\n" ..
                "%s **%s** • ⚡ `%d` ELO • 🎯 `%s` K/D • 💀 `%d` • ☠️ `%d`\n",
                medal, i, playerName,
                rank.emoji, rank.name,
                elo, kd, kills, deaths
            )
            
            -- Séparateur sauf pour le dernier
            if i < math.min(10, #leaderboardData) then
                rankText = rankText .. "— — — — — — — —\n"
            end
        end
        
        table.insert(fields, {
            name = EMOJIS.misc.trophy .. " **CLASSEMENT " .. modeName .. "**",
            value = rankText,
            inline = false
        })
    else
        table.insert(fields, {
            name = EMOJIS.misc.trophy .. " **CLASSEMENT " .. modeName .. "**",
            value = "Aucun joueur dans le classement.",
            inline = false
        })
    end
    
    -- ========================================
    -- INFORMATIONS SUPPLÉMENTAIRES
    -- ========================================
    if #leaderboardData > 0 and ConfigDiscordLeaderboard.ShowFooterInfo then
        local topPlayer = leaderboardData[1]
        local infoText = string.format(
            "%s **Leader:** %s (%d ELO)\n" ..
            "%s **Meilleur ELO:** %d\n" ..
            "%s **Total joueurs:** %s",
            EMOJIS.misc.crown,
            FormatPlayerName(topPlayer.name, 20),
            SafeNumber(topPlayer.elo, 1000),
            EMOJIS.stats.elo,
            bestElo,
            EMOJIS.stats.players,
            FormatNumber(totalPlayers)
        )
        
        table.insert(fields, {
            name = "ℹ️ **INFORMATIONS**",
            value = infoText,
            inline = false
        })
    end
    
    -- ========================================
    -- CONSTRUCTION EMBED
    -- ========================================
    local embed = {
        title = ConfigDiscordLeaderboard.TitleFormat or "🏆 **FIGHT LEAGUE RANKINGS • SEASON 1**",
        description = ConfigDiscordLeaderboard.SubtitleFormat:gsub("{mode}", modeName) or ("━━━━━━━━━━ **" .. modeName .. "** ━━━━━━━━━━"),
        color = color,
        fields = fields,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        footer = {
            text = ConfigDiscordLeaderboard.Footer.text or "Voici le classement du serveur"
        }
    }
    
    -- Thumbnail
    local thumbUrl = ConfigDiscordLeaderboard.ModeThumbnails[mode]
    if thumbUrl and thumbUrl ~= "" then
        embed.thumbnail = { url = thumbUrl }
    end
    
    -- Banner
    if ConfigDiscordLeaderboard.BannerImage and ConfigDiscordLeaderboard.BannerImage ~= "" then
        embed.image = { url = ConfigDiscordLeaderboard.BannerImage }
    end
    
    -- Footer icon
    if ConfigDiscordLeaderboard.Footer.icon_url and ConfigDiscordLeaderboard.Footer.icon_url ~= "" then
        embed.footer.icon_url = ConfigDiscordLeaderboard.Footer.icon_url
    end
    
    return embed
end

-- ========================================
-- 🔒 ENVOYER CLASSEMENT POUR UN MODE (SÉCURISÉ)
-- ========================================
local function SendLeaderboardToDiscord(mode, callback)
    LogInfo('Recuperation webhook ' .. mode .. ' (sécurisé)...')
    
    -- 🔒 Récupérer le webhook depuis la base de données chiffrée
    exports['pvp_gunfight']:GetWebhookURL(mode, function(webhook)
        if not webhook or webhook == '' then
            LogError('Webhook Discord manquant ou non configuré pour mode: ' .. mode)
            LogInfo('💡 Utilisez /gfrankedsetwebhook ' .. mode .. ' [url] pour le configurer')
            if callback then callback(false) end
            return
        end
        
        LogInfo('Webhook ' .. mode .. ' récupéré avec succès (déchiffré)')
        LogInfo('Recuperation classement ' .. mode .. '...')
        
        exports['pvp_gunfight']:GetLeaderboardByMode(mode, 50, function(leaderboard)
            if not leaderboard then
                LogError('Impossible de recuperer le classement pour ' .. mode)
                if callback then callback(false) end
                return
            end
            
            LogInfo('Classement ' .. mode .. ' recupere: ' .. #leaderboard .. ' joueurs')
            
            local embed = CreateLeaderboardEmbed(mode, leaderboard)
            
            local payload = {
                username = 'Fight League Rankings',
                embeds = {embed}
            }
            
            -- Avatar optionnel
            if ConfigDiscordLeaderboard.BotAvatar and ConfigDiscordLeaderboard.BotAvatar ~= "" then
                payload.avatar_url = ConfigDiscordLeaderboard.BotAvatar
            end
            
            local success, jsonPayload = pcall(json.encode, payload)
            
            if not success then
                LogError('Erreur encodage JSON: ' .. tostring(jsonPayload))
                if callback then callback(false) end
                return
            end
            
            PerformHttpRequest(webhook, function(statusCode, responseBody, headers)
                if statusCode == 204 or statusCode == 200 then
                    LogSuccess('Classement ' .. mode .. ' envoye sur Discord ✅')
                    lastSendTime[mode] = os.time()
                    if callback then callback(true) end
                else
                    LogError('Erreur envoi Discord ' .. mode .. ' (Status: ' .. tostring(statusCode) .. ')')
                    if responseBody then
                        LogError('Reponse: ' .. tostring(responseBody))
                    end
                    if callback then callback(false) end
                end
            end, 'POST', jsonPayload, {
                ['Content-Type'] = 'application/json'
            })
        end)
    end)
end

-- ========================================
-- ENVOYER TOUS LES CLASSEMENTS
-- ========================================
local function SendAllLeaderboards(callback)
    if isSending then
        LogInfo('Envoi deja en cours...')
        if callback then callback(false) end
        return
    end
    
    isSending = true
    LogInfo('=============================================')
    LogInfo('ENVOI CLASSEMENTS DISCORD (4 modes) 🔒')
    LogInfo('=============================================')
    
    local modes = {'1v1', '2v2', '3v3', '4v4'}
    local completed = 0
    local success = 0
    
    for i = 1, #modes do
        local mode = modes[i]
        
        Citizen.SetTimeout(i * 2000, function()
            SendLeaderboardToDiscord(mode, function(result)
                completed = completed + 1
                if result then success = success + 1 end
                
                if completed == #modes then
                    isSending = false
                    LogInfo('=============================================')
                    LogSuccess('ENVOI TERMINE: ' .. success .. '/' .. #modes .. ' MODES')
                    LogInfo('=============================================')
                    if callback then callback(success == #modes) end
                end
            end)
        end)
    end
end

-- ========================================
-- VÉRIFIER SI HEURE D'ENVOI
-- ========================================
local function ShouldSendNow()
    if not ConfigDiscordLeaderboard.AutoSend then
        return false
    end
    
    local currentTime = os.time()
    local currentDate = os.date("*t", currentTime)
    
    if ConfigDiscordLeaderboard.AutoSendTime then
        local targetHour = ConfigDiscordLeaderboard.AutoSendTime.hour
        local targetMinute = ConfigDiscordLeaderboard.AutoSendTime.minute or 0
        
        if currentDate.hour == targetHour and currentDate.min == targetMinute then
            local lastSend = lastSendTime['daily'] or 0
            local daysSinceLastSend = math.floor((currentTime - lastSend) / 86400)
            return daysSinceLastSend >= 1
        end
        return false
    else
        local lastSend = lastSendTime['interval'] or 0
        local hoursSinceLastSend = (currentTime - lastSend) / 3600
        return hoursSinceLastSend >= ConfigDiscordLeaderboard.AutoSendInterval
    end
end

-- ========================================
-- THREAD: ENVOI AUTOMATIQUE
-- ========================================
if ConfigDiscordLeaderboard.AutoSend then
    CreateThread(function()
        Wait(10000)
        LogSuccess('Systeme d\'envoi automatique active (Webhooks sécurisés)')
        
        if ConfigDiscordLeaderboard.AutoSendTime then
            LogInfo('Envoi quotidien: ' .. string.format('%02d:%02d', 
                ConfigDiscordLeaderboard.AutoSendTime.hour,
                ConfigDiscordLeaderboard.AutoSendTime.minute or 0
            ))
        else
            LogInfo('Intervalle: toutes les ' .. ConfigDiscordLeaderboard.AutoSendInterval .. ' heures')
        end
        
        while true do
            Wait(60000)  -- Vérification chaque minute
            if ShouldSendNow() then
                SendAllLeaderboards(function(success)
                    if success then
                        if ConfigDiscordLeaderboard.AutoSendTime then
                            lastSendTime['daily'] = os.time()
                        else
                            lastSendTime['interval'] = os.time()
                        end
                    end
                end)
            end
        end
    end)
end

-- ========================================
-- COMMANDES ADMIN
-- ========================================
RegisterCommand(ConfigDiscordLeaderboard.Commands.sendLeaderboard or 'pvpleaderboard', function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(source, ConfigDiscordLeaderboard.AdminAce) then
        if source > 0 then
            TriggerClientEvent('esx:showNotification', source, '~r~Permission refusee')
        end
        return
    end
    
    if source > 0 then
        TriggerClientEvent('esx:showNotification', source, '~b~Envoi des classements en cours... 🔒')
    else
        print('[PVP] Envoi des 4 classements (1v1, 2v2, 3v3, 4v4) - Webhooks sécurisés...')
    end
    
    SendAllLeaderboards(function(success)
        if source > 0 then
            if success then
                TriggerClientEvent('esx:showNotification', source, '~g~Classements envoyes avec succes! ✅')
            else
                TriggerClientEvent('esx:showNotification', source, '~o~Erreur lors de l\'envoi')
            end
        else
            if success then
                print('[PVP] Classements envoyes avec succes')
            else
                print('[PVP] Erreur lors de l\'envoi')
            end
        end
    end)
end, false)

-- Commande pour un mode spécifique
RegisterCommand('pvpsendmode', function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(source, ConfigDiscordLeaderboard.AdminAce) then
        return
    end
    
    local mode = args[1]
    if not mode then
        if source > 0 then
            TriggerClientEvent('esx:showNotification', source, '~r~Mode invalide. Utilisez: 1v1, 2v2, 3v3, 4v4')
        else
            print('[PVP] Mode invalide. Utilisez: 1v1, 2v2, 3v3, 4v4')
        end
        return
    end
    
    SendLeaderboardToDiscord(mode, function(success)
        if source > 0 then
            if success then
                TriggerClientEvent('esx:showNotification', source, '~g~Classement ' .. mode .. ' envoye! ✅')
            else
                TriggerClientEvent('esx:showNotification', source, '~r~Erreur envoi ' .. mode)
                TriggerClientEvent('esx:showNotification', source, '~y~Vérifiez que le webhook est configuré')
            end
        end
    end)
end, false)

-- ========================================
-- EXPORTS
-- ========================================
exports('SendLeaderboardToDiscord', SendLeaderboardToDiscord)
exports('SendAllLeaderboards', SendAllLeaderboards)

LogSuccess('Module Discord Leaderboards v4.1 (WEBHOOKS SÉCURISÉS) initialise')
LogInfo('💡 Utilisez /gfrankedwebhookhelp pour voir les commandes disponibles')
