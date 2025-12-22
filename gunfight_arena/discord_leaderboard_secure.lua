-- ================================================================================================
-- GUNFIGHT ARENA - DISCORD LEADERBOARD v4.0 SÉCURISÉ
-- ================================================================================================
-- ✨ Version sécurisée avec webhook chiffré
-- ✅ Protection contre l'accès non autorisé
-- ✅ Utilisation du module de sécurité
-- ================================================================================================

local ESX = exports['es_extended']:getSharedObject()

-- ================================================================================================
-- CACHE SYSTÈME
-- ================================================================================================
local CACHE = {
    leaderboard = nil,
    globalStats = nil,
    lastUpdate = 0,
    duration = 300000 -- 5 minutes
}

-- ================================================================================================
-- EMOJIS & CONSTANTES
-- ================================================================================================
local EMOJIS = {
    rank = {[1] = "🥇", [2] = "🥈", [3] = "🥉"},
    stats = {
        kills = "⚔️",
        deaths = "💀",
        kd = "📊",
        streak = "🔥",
        headshot = "🎯",
        playtime = "⏱️",
        players = "👥"
    },
    status = {
        success = "✅",
        error = "❌",
        warning = "⚠️",
        info = "ℹ️"
    },
    misc = {
        trophy = "🏆",
        crown = "👑",
        target = "🎯",
        fire = "🔥",
        skull = "💀"
    }
}

-- ================================================================================================
-- SYSTÈME DE LOGGING
-- ================================================================================================
local Logger = {
    colors = {
        reset = "^0",
        red = "^1",
        green = "^2",
        yellow = "^3",
        blue = "^4",
        cyan = "^6",
        white = "^7"
    }
}

function Logger:Print(level, message, data)
    if not Config.DebugServer and level == "debug" then return end
    
    local prefix = {
        error = self.colors.red .. "[GF-Discord ERROR]",
        success = self.colors.green .. "[GF-Discord ✓]",
        warning = self.colors.yellow .. "[GF-Discord !]",
        info = self.colors.cyan .. "[GF-Discord]",
        debug = self.colors.blue .. "[GF-Discord DEBUG]"
    }
    
    local msg = (prefix[level] or prefix.info) .. self.colors.reset .. " " .. message
    
    if data then
        msg = msg .. " " .. self.colors.yellow .. json.encode(data) .. self.colors.reset
    end
    
    print(msg)
end

local function LogError(msg, data) Logger:Print("error", msg, data) end
local function LogSuccess(msg, data) Logger:Print("success", msg, data) end
local function LogWarning(msg, data) Logger:Print("warning", msg, data) end
local function LogInfo(msg, data) Logger:Print("info", msg, data) end
local function LogDebug(msg, data) Logger:Print("debug", msg, data) end

-- ================================================================================================
-- UTILITAIRES DE FORMATAGE
-- ================================================================================================
local Formatter = {}

function Formatter.Time(seconds)
    seconds = tonumber(seconds) or 0
    
    if seconds < 60 then
        return string.format("%ds", seconds)
    elseif seconds < 3600 then
        return string.format("%dmin", math.floor(seconds / 60))
    elseif seconds < 86400 then
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        return minutes > 0 and string.format("%dh%02dm", hours, minutes) or string.format("%dh", hours)
    else
        local days = math.floor(seconds / 86400)
        local hours = math.floor((seconds % 86400) / 3600)
        return string.format("%dj %dh", days, hours)
    end
end

function Formatter.Number(num)
    num = tonumber(num) or 0
    local formatted = tostring(num)
    local k
    
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1 %2')
        if k == 0 then break end
    end
    
    return formatted
end

function Formatter.TruncateName(name, maxLength)
    maxLength = maxLength or 20
    if string.len(name) > maxLength then
        return string.sub(name, 1, maxLength - 3) .. "..."
    end
    return name
end

-- ✅ NOUVELLE FONCTION : Nettoyer les caractères invalides pour Discord
function Formatter.SanitizeForDiscord(text)
    if not text then return "Inconnu" end
    
    -- Convertir en string si ce n'est pas le cas
    text = tostring(text)
    
    -- Remplacer les caractères de contrôle et caractères problématiques
    text = text:gsub("[%c%z]", "") -- Supprime les caractères de contrôle
    text = text:gsub("[\128-\255]+", function(c) return c end) -- Garde les UTF-8 valides
    
    -- Limiter la longueur pour éviter les dépassements
    if #text > 256 then
        text = text:sub(1, 253) .. "..."
    end
    
    -- Si vide après nettoyage
    if text == "" or text == nil then
        return "Joueur"
    end
    
    return text
end

-- ================================================================================================
-- GESTIONNAIRE DE CACHE
-- ================================================================================================
local CacheManager = {}

function CacheManager:IsValid()
    return CACHE.leaderboard and 
           CACHE.globalStats and 
           (os.time() * 1000 - CACHE.lastUpdate) < CACHE.duration
end

function CacheManager:Set(leaderboard, globalStats)
    CACHE.leaderboard = leaderboard
    CACHE.globalStats = globalStats
    CACHE.lastUpdate = os.time() * 1000
    LogDebug("Cache mis à jour")
end

function CacheManager:Get()
    if self:IsValid() then
        LogDebug("Données récupérées depuis le cache")
        return CACHE.leaderboard, CACHE.globalStats
    end
    return nil, nil
end

function CacheManager:Clear()
    CACHE.leaderboard = nil
    CACHE.globalStats = nil
    CACHE.lastUpdate = 0
    LogDebug("Cache vidé")
end

-- ================================================================================================
-- REQUÊTES BASE DE DONNÉES
-- ================================================================================================
local Database = {}

function Database.GetLeaderboard(callback)
    if not Config.SaveStatsToDatabase then
        LogError("Base de données désactivée")
        return callback(nil)
    end
    
    LogDebug("Récupération du classement depuis la BDD...")
    
    MySQL.Async.fetchAll([[
        SELECT 
            player_name,
            kills, 
            deaths, 
            headshots, 
            best_streak,
            total_playtime,
            CASE 
                WHEN deaths > 0 THEN ROUND(kills / deaths, 2) 
                ELSE kills 
            END as kd_ratio
        FROM gunfight_stats
        ORDER BY kd_ratio DESC, kills DESC, best_streak DESC
        LIMIT @limit
    ]], {
        ['@limit'] = Config.Discord.leaderboardLimit or 15
    }, function(result)
        if result then
            LogDebug("Classement récupéré", {count = #result})
            callback(result)
        else
            LogError("Erreur lors de la récupération du classement")
            callback(nil)
        end
    end)
end

function Database.GetGlobalStats(callback)
    LogDebug("Récupération des statistiques globales...")
    
    MySQL.Async.fetchAll([[
        SELECT 
            COUNT(*) as total_players,
            SUM(kills) as total_kills,
            SUM(deaths) as total_deaths,
            MAX(best_streak) as best_streak_ever,
            SUM(total_playtime) as total_playtime,
            AVG(CASE WHEN deaths > 0 THEN kills / deaths ELSE kills END) as avg_kd
        FROM gunfight_stats
        WHERE kills > 0
    ]], {}, function(result)
        if result and result[1] then
            LogDebug("Stats globales récupérées")
            callback(result[1])
        else
            LogWarning("Aucune statistique globale trouvée")
            callback({
                total_players = 0,
                total_kills = 0,
                total_deaths = 0,
                best_streak_ever = 0,
                total_playtime = 0,
                avg_kd = 0
            })
        end
    end)
end

-- ================================================================================================
-- GÉNÉRATEUR D'EMBEDS - STYLE MODERNE
-- ================================================================================================
local function CreateEmbedModern(leaderboard, globalStats)
    local fields = {}
    
    -- Statistiques globales
    if Config.Discord.showGlobalStats then
        local stats = {
            {name = EMOJIS.stats.players .. " Joueurs", value = Formatter.Number(tonumber(globalStats.total_players) or 0)},
            {name = EMOJIS.stats.kills .. " Kills", value = Formatter.Number(tonumber(globalStats.total_kills) or 0)},
            {name = EMOJIS.stats.deaths .. " Morts", value = Formatter.Number(tonumber(globalStats.total_deaths) or 0)},
            {name = EMOJIS.stats.streak .. " Record", value = Formatter.Number(tonumber(globalStats.best_streak_ever) or 0)},
            {name = EMOJIS.stats.kd .. " K/D Moyen", value = string.format("%.2f", tonumber(globalStats.avg_kd) or 0)}
        }
        
        for _, stat in ipairs(stats) do
            table.insert(fields, {
                name = stat.name,
                value = "```" .. stat.value .. "```",
                inline = true
            })
        end
    end
    
    -- Top 15
    if #leaderboard > 0 then
        local rankText = ""
        
        for i = 1, math.min(15, #leaderboard) do
            local data = leaderboard[i]
            local medal = EMOJIS.rank[i] or "▫️"
            
            -- ✅ NETTOYAGE DES DONNÉES
            local playerName = Formatter.SanitizeForDiscord(data.player_name or "Joueur")
            playerName = Formatter.TruncateName(playerName, 22)
            
            local kd = tonumber(data.kd_ratio) or 0
            local kills = tonumber(data.kills) or 0
            local deaths = tonumber(data.deaths) or 0
            
            -- Vérification que les valeurs sont valides
            if kd > 999 then kd = 999 end
            if kills > 999999 then kills = 999999 end
            if deaths > 999999 then deaths = 999999 end
            
            rankText = rankText .. string.format(
                "%s **#%02d %s**\n" ..
                "K/D: `%.2f` • Kills: `%s` • Morts: `%s`\n",
                medal, i, playerName, kd,
                Formatter.Number(kills),
                Formatter.Number(deaths)
            )
            
            if i < math.min(15, #leaderboard) then
                rankText = rankText .. "— — — — — — — —\n"
            end
        end
        
        table.insert(fields, {
            name = EMOJIS.misc.trophy .. " **CLASSEMENT GÉNÉRAL**",
            value = rankText,
            inline = false
        })
    end
    
    return {
        author = {
            name = "GUNFIGHT ARENA",
            icon_url = Config.Discord.botAvatar or ""
        },
        title = Config.Discord.embedTitle or "🏆 CLASSEMENT DES CHAMPIONS",
        description = Config.Discord.embedDescription or "*Les meilleurs guerriers de l'arène*",
        color = Config.Discord.embedColor or 3447003,
        fields = fields,
        thumbnail = {
            url = Config.Discord.thumbnailUrl or ""
        },
        image = {
            url = Config.Discord.bannerUrl or ""
        },
        footer = {
            text = string.format(
                "Prochain classement dans %dh • %s",
                math.floor((Config.Discord.updateInterval or 21600) / 3600),
                os.date("%d/%m/%Y à %H:%M")
            ),
            icon_url = Config.Discord.footerIcon or ""
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
end

-- ================================================================================================
-- ✅ FONCTION PRINCIPALE D'ENVOI (SÉCURISÉE)
-- ================================================================================================
function SendLeaderboardToDiscord(forceRefresh)
    if not Config.Discord.enabled then
        LogWarning("Système Discord désactivé")
        return
    end
    
    -- ✅ RÉCUPÉRATION SÉCURISÉE DU WEBHOOK
    local webhookUrl = Config.Discord.GetWebhookUrl()
    
    if not webhookUrl then
        LogError("Webhook non configuré. Utilisez /gfsetwebhook pour configurer.")
        return
    end
    
    LogInfo("═══════════════════════════════════════════════")
    LogInfo("Préparation de l'envoi du classement Discord...")
    
    -- Vérifier le cache
    if not forceRefresh then
        local cachedLeaderboard, cachedStats = CacheManager:Get()
        if cachedLeaderboard and cachedStats then
            LogInfo("Utilisation des données en cache")
            ProcessAndSendEmbed(cachedLeaderboard, cachedStats, webhookUrl)
            return
        end
    end
    
    -- Récupérer depuis la BDD
    Database.GetLeaderboard(function(leaderboard)
        if not leaderboard then
            LogError("Impossible de récupérer le classement")
            return
        end
        
        Database.GetGlobalStats(function(globalStats)
            CacheManager:Set(leaderboard, globalStats)
            ProcessAndSendEmbed(leaderboard, globalStats, webhookUrl)
        end)
    end)
end

function ProcessAndSendEmbed(leaderboard, globalStats, webhookUrl)
    LogInfo(string.format("Classement récupéré: %d joueurs", #leaderboard))
    
    local embed = CreateEmbedModern(leaderboard, globalStats)
    
    -- ✅ VALIDATION DE LA TAILLE DE L'EMBED
    -- Discord limite : titre (256), description (4096), chaque field value (1024)
    -- Total embed : 6000 caractères max
    
    if embed.description and #embed.description > 4096 then
        embed.description = embed.description:sub(1, 4093) .. "..."
        LogWarning("Description tronquée (>4096 caractères)")
    end
    
    -- Vérifier chaque field
    if embed.fields then
        for i, field in ipairs(embed.fields) do
            if field.value and #field.value > 1024 then
                field.value = field.value:sub(1, 1021) .. "..."
                LogWarning(string.format("Field %d tronqué (>1024 caractères)", i))
            end
        end
    end
    
    local payload = {
        username = Config.Discord.botName or "Gunfight Arena",
        avatar_url = Config.Discord.botAvatar or "",
        embeds = {embed}
    }
    
    if Config.Discord.mentionEveryone then
        payload.content = "@everyone 🎯 **Nouveau classement disponible !**"
    elseif Config.Discord.mentionRole and Config.Discord.mentionRole ~= "" then
        payload.content = string.format("<@&%s> 🎯 **Nouveau classement disponible !**", Config.Discord.mentionRole)
    end
    
    local jsonPayload = json.encode(payload)
    
    -- ✅ VÉRIFICATION DE LA TAILLE DU PAYLOAD
    if #jsonPayload > 20000 then
        LogError("Payload trop grand (>20KB), envoi annulé")
        LogError("Taille: " .. #jsonPayload .. " octets")
        return
    end
    
    LogDebug("Taille du payload: " .. #jsonPayload .. " octets")
    
    PerformHttpRequest(webhookUrl, function(statusCode, responseText, headers)
        if statusCode == 204 or statusCode == 200 then
            LogSuccess(string.format("Classement envoyé avec succès ! (Code HTTP: %d)", statusCode))
        elseif statusCode == 400 then
            LogError(string.format("Erreur 400 - Requête invalide (Code HTTP: %d)", statusCode))
            LogError("Réponse Discord: " .. tostring(responseText))
            LogError("Cela peut être dû à:")
            LogError("  - Des caractères invalides dans les noms de joueurs")
            LogError("  - Un embed trop grand (>6000 caractères)")
            LogError("  - Des emojis non supportés")
            LogError("Payload envoyé (premiers 500 chars):")
            LogError(jsonPayload:sub(1, 500))
        else
            LogError(string.format("Échec de l'envoi (Code HTTP: %d)", statusCode))
            LogError("Réponse: " .. tostring(responseText))
        end
    end, 'POST', jsonPayload, {
        ['Content-Type'] = 'application/json'
    })
    
    LogInfo("═══════════════════════════════════════════════")
end

-- ================================================================================================
-- COMMANDES ADMIN
-- ================================================================================================
RegisterCommand(Config.Discord.manualCommand or "gfleaderboard", function(source, args, rawCommand)
    if source ~= 0 then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer or xPlayer.getGroup() ~= 'admin' then
            TriggerClientEvent('esx:showNotification', source, "~r~Permission refusée.")
            return
        end
    end
    
    local forceRefresh = args[1] == "refresh" or args[1] == "force"
    
    LogInfo(string.format(
        "Envoi manuel demandé par %s %s",
        source == 0 and "la console" or "le joueur #" .. source,
        forceRefresh and "(avec rafraîchissement forcé)" or ""
    ))
    
    SendLeaderboardToDiscord(forceRefresh)
    
    if source ~= 0 then
        TriggerClientEvent('esx:showNotification', source, "~g~✓ Classement envoyé !")
    end
end, false)

RegisterCommand("gfclearcache", function(source, args, rawCommand)
    if source ~= 0 then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer or xPlayer.getGroup() ~= 'admin' then return end
    end
    
    CacheManager:Clear()
    LogSuccess("Cache vidé manuellement")
    
    if source ~= 0 then
        TriggerClientEvent('esx:showNotification', source, "~g~✓ Cache vidé !")
    end
end, false)

-- ================================================================================================
-- SYSTÈME D'ENVOI AUTOMATIQUE
-- ================================================================================================
if Config.Discord.enabled and Config.Discord.autoSend then
    Citizen.CreateThread(function()
        Wait(60000) -- 1 minute
        
        LogSuccess("Thread d'envoi automatique démarré")
        LogInfo(string.format("Intervalle: %d heures", math.floor((Config.Discord.updateInterval or 21600) / 3600)))
        
        if Config.Discord.sendOnStartup then
            LogInfo("Envoi du classement au démarrage...")
            SendLeaderboardToDiscord(false)
        end
        
        while true do
            Wait((Config.Discord.updateInterval or 21600) * 1000)
            
            LogInfo("Envoi automatique du classement...")
            SendLeaderboardToDiscord(false)
        end
    end)
end

-- ================================================================================================
-- INITIALISATION
-- ================================================================================================
Citizen.CreateThread(function()
    Wait(2000)
    
    print("^2╔═══════════════════════════════════════════════╗^0")
    print("^2║  GUNFIGHT ARENA - Discord Leaderboard v4.0  ║^0")
    print("^2║           MODE SÉCURISÉ ACTIVÉ ✓             ║^0")
    print("^2╚═══════════════════════════════════════════════╝^0")
    print("")
    LogInfo(string.format("État: %s", Config.Discord.enabled and "^2ACTIVÉ^0" or "^1DÉSACTIVÉ^0"))
    
    if Config.Discord.enabled then
        local webhook = Config.Discord.GetWebhookUrl()
        if webhook then
            LogSuccess("✓ Webhook Discord configuré (chiffré)")
        else
            LogWarning("⚠️  Aucun webhook configuré")
            LogInfo("Utilisez /gfsetwebhook [URL] pour configurer")
        end
        
        LogInfo(string.format("Auto-envoi: %s", Config.Discord.autoSend and "OUI" or "NON"))
        
        if Config.Discord.autoSend then
            LogInfo(string.format("Intervalle: %dh", math.floor((Config.Discord.updateInterval or 21600) / 3600)))
        end
        
        LogInfo(string.format("Commande: /%s [refresh]", Config.Discord.manualCommand or "gfleaderboard"))
        LogInfo("Commande cache: /gfclearcache")
    end
    
    print("")
end)

-- ================================================================================================
-- EXPORTS
-- ================================================================================================
exports('SendLeaderboard', SendLeaderboardToDiscord)
exports('ClearCache', function() CacheManager:Clear() end)
exports('GetCachedData', function() return CacheManager:Get() end)