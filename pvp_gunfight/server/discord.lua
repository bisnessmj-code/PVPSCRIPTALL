-- ========================================
-- PVP GUNFIGHT - MODULE DISCORD
-- Version 4.0.0 - Optimisé
-- ========================================

DebugServer('Module Discord chargé')

-- ========================================
-- CACHE DES AVATARS
-- ========================================
local avatarCache = {}
local pendingRequests = {}
local CACHE_DURATION = 300000

-- Configuration
local DISCORD_CONFIG = {
    defaultAvatar = Config.Discord.defaultAvatar or 'https://cdn.discordapp.com/embed/avatars/0.png',
    avatarSize = Config.Discord.avatarSize or 128,
    avatarFormat = Config.Discord.avatarFormat or 'png'
}

-- ========================================
-- FONCTIONS UTILITAIRES
-- ========================================
local function GetPlayerDiscordId(playerId)
    local identifiers = GetPlayerIdentifiers(playerId)
    
    if not identifiers then return nil end
    
    for i = 1, #identifiers do
        local identifier = identifiers[i]
        if string.sub(identifier, 1, 8) == 'discord:' then
            return string.sub(identifier, 9)
        end
    end
    
    return nil
end

local function GetDefaultDiscordAvatar(discordId)
    local avatarIndex = tonumber(discordId) % 5
    return string.format('https://cdn.discordapp.com/embed/avatars/%d.png', avatarIndex)
end

local function FetchCustomDiscordAvatar(playerId, discordId, callback)
    if not Config.Discord.botToken or Config.Discord.botToken == '' then
        callback(GetDefaultDiscordAvatar(discordId))
        return
    end
    
    if pendingRequests[playerId] then
        pendingRequests[playerId][#pendingRequests[playerId] + 1] = callback
        return
    end
    
    pendingRequests[playerId] = {callback}
    
    PerformHttpRequest(
        'https://discord.com/api/v10/users/' .. discordId,
        function(statusCode, responseBody, headers)
            local callbacks = pendingRequests[playerId]
            pendingRequests[playerId] = nil
            
            local avatarUrl = GetDefaultDiscordAvatar(discordId)
            
            if statusCode == 200 then
                local success, data = pcall(json.decode, responseBody)
                
                if success and data and data.avatar then
                    avatarUrl = string.format(
                        'https://cdn.discordapp.com/avatars/%s/%s.%s?size=%d',
                        discordId, data.avatar, DISCORD_CONFIG.avatarFormat, DISCORD_CONFIG.avatarSize
                    )
                    
                    -- Mise à jour en DB
                    local xPlayer = ESX.GetPlayerFromId(playerId)
                    if xPlayer then
                        MySQL.update('UPDATE pvp_stats SET discord_avatar = ? WHERE identifier = ?', {
                            avatarUrl, xPlayer.identifier
                        })
                    end
                end
            end
            
            avatarCache[playerId] = {
                url = avatarUrl,
                discordId = discordId,
                timestamp = GetGameTimer()
            }
            
            for i = 1, #callbacks do
                callbacks[i](avatarUrl)
            end
        end,
        'GET',
        '',
        {
            ['Authorization'] = 'Bot ' .. Config.Discord.botToken,
            ['Content-Type'] = 'application/json'
        }
    )
end

function GetPlayerDiscordAvatarAsync(playerId, callback)
    local cached = avatarCache[playerId]
    if cached and (GetGameTimer() - cached.timestamp) < CACHE_DURATION then
        callback(cached.url)
        return
    end
    
    local discordId = GetPlayerDiscordId(playerId)
    
    if not discordId then
        callback(DISCORD_CONFIG.defaultAvatar)
        return
    end
    
    FetchCustomDiscordAvatar(playerId, discordId, callback)
end

function GetPlayerDiscordAvatar(playerId)
    local cached = avatarCache[playerId]
    if cached then return cached.url end
    
    local discordId = GetPlayerDiscordId(playerId)
    if not discordId then return DISCORD_CONFIG.defaultAvatar end
    
    -- Lancer une requête async
    CreateThread(function()
        GetPlayerDiscordAvatarAsync(playerId, function() end)
    end)
    
    return GetDefaultDiscordAvatar(discordId)
end

function GetPlayerDiscordInfo(playerId)
    local discordId = GetPlayerDiscordId(playerId)
    local avatarUrl = DISCORD_CONFIG.defaultAvatar
    
    local cached = avatarCache[playerId]
    if cached then
        avatarUrl = cached.url
    elseif discordId then
        avatarUrl = GetDefaultDiscordAvatar(discordId)
    end
    
    return {
        discordId = discordId,
        avatarUrl = avatarUrl,
        hasDiscord = discordId ~= nil
    }
end

function PreloadAvatarsAsync(playerIds, callback)
    local completed = 0
    local total = #playerIds
    
    if total == 0 then
        callback()
        return
    end
    
    for i = 1, #playerIds do
        GetPlayerDiscordAvatarAsync(playerIds[i], function()
            completed = completed + 1
            if completed == total then
                callback()
            end
        end)
    end
end

-- Nettoyage du cache
local function CleanAvatarCache()
    local currentTime = GetGameTimer()
    local cleaned = 0
    
    for playerId, cached in pairs(avatarCache) do
        if (currentTime - cached.timestamp) > CACHE_DURATION then
            avatarCache[playerId] = nil
            cleaned = cleaned + 1
        end
    end
    
    if cleaned > 0 then
        DebugServer('Cache avatars nettoyé: %d entrées', cleaned)
    end
end

CreateThread(function()
    while true do
        Wait(600000)
        CleanAvatarCache()
    end
end)

-- Déconnexion
AddEventHandler('playerDropped', function()
    local src = source
    avatarCache[src] = nil
    pendingRequests[src] = nil
end)

-- Exports
exports('GetPlayerDiscordId', GetPlayerDiscordId)
exports('GetPlayerDiscordAvatar', GetPlayerDiscordAvatar)
exports('GetPlayerDiscordAvatarAsync', GetPlayerDiscordAvatarAsync)
exports('GetPlayerDiscordInfo', GetPlayerDiscordInfo)
exports('PreloadAvatarsAsync', PreloadAvatarsAsync)

-- Vérification token au démarrage
CreateThread(function()
    Wait(2000)
    
    if not Config.Discord.enabled then
        DebugWarn('Système avatars Discord DÉSACTIVÉ')
        return
    end
    
    if not Config.Discord.botToken or Config.Discord.botToken == '' then
        DebugWarn('Token Discord non configuré - Avatars par défaut')
    else
        PerformHttpRequest(
            'https://discord.com/api/v10/users/@me',
            function(statusCode, responseBody)
                if statusCode == 200 then
                    local success, data = pcall(json.decode, responseBody)
                    if success and data then
                        DebugSuccess('Bot Discord connecté: %s', data.username or 'Unknown')
                    end
                else
                    DebugError('Token Discord invalide (Status: %d)', statusCode)
                end
            end,
            'GET',
            '',
            {
                ['Authorization'] = 'Bot ' .. Config.Discord.botToken,
                ['Content-Type'] = 'application/json'
            }
        )
    end
end)

DebugSuccess('Module Discord initialisé (VERSION 4.0.0)')
