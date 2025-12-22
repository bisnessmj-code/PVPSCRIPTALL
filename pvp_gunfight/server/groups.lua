-- ========================================
-- PVP GUNFIGHT - SYSTÈME DE GROUPES
-- Version 4.1.0 - NOM FIVEM + ID
-- ========================================

DebugGroups('Module groupes chargé (Version 4.1.0 - Nom FiveM + ID)')

-- ========================================
-- VARIABLES
-- ========================================
local groups = {}
local playerGroups = {}
local pendingInvites = {}

-- ========================================
-- 🆕 FONCTION: OBTENIR NOM FIVEM + ID
-- ========================================
local function GetPlayerFiveMNameWithID(playerId)
    if not playerId or playerId <= 0 then
        return "Joueur inconnu"
    end
    
    -- Obtenir le nom FiveM (steam, discord, license, etc.)
    local playerName = GetPlayerName(playerId)
    
    -- Nettoyer le nom (retirer les caractères spéciaux)
    if playerName then
        playerName = playerName:gsub("%^%d", "") -- Retirer les codes couleur FiveM
    else
        playerName = "Joueur"
    end
    
    -- Format: "Nom [ID]"
    return string.format("%s [%d]", playerName, playerId)
end

-- ========================================
-- FONCTIONS DE GESTION
-- ========================================
local function CreateGroup(leaderId)
    local groupId = #groups + 1
    groups[groupId] = {
        id = groupId,
        leaderId = leaderId,
        members = {leaderId},
        ready = {[leaderId] = false}
    }
    playerGroups[leaderId] = groupId
    return groupId
end

function GetPlayerGroup(playerId)
    local groupId = playerGroups[playerId]
    if not groupId then return nil end
    
    local group = groups[groupId]
    if not group then
        playerGroups[playerId] = nil
        return nil
    end
    
    local found = false
    for i = 1, #group.members do
        if group.members[i] == playerId then
            found = true
            break
        end
    end
    
    if not found then
        playerGroups[playerId] = nil
        group.ready[playerId] = nil
        return nil
    end
    
    return group
end

local function BroadcastToGroup(groupId)
    local group = groups[groupId]
    if not group then return end
    
    for i = 1, #group.members do
        local memberId = group.members[i]
        CreateThread(function()
            GetGroupDataAsync(memberId, function(groupData)
                TriggerClientEvent('pvp:updateGroupUI', memberId, groupData)
            end)
        end)
    end
end

-- ========================================
-- 🔧 FONCTION MODIFIÉE: UTILISER NOM FIVEM + ID
-- ========================================
function GetGroupDataAsync(playerId, callback)
    local group = GetPlayerGroup(playerId)
    if not group then 
        callback(nil)
        return
    end
    
    local members = {}
    local completed = 0
    local total = #group.members
    
    for i = 1, #group.members do
        local memberId = group.members[i]
        
        -- 🆕 Utiliser le nom FiveM au lieu de xPlayer.getName()
        local displayName = GetPlayerFiveMNameWithID(memberId)
        
        if Config.Discord and Config.Discord.enabled then
            exports['pvp_gunfight']:GetPlayerDiscordAvatarAsync(memberId, function(avatarUrl)
                members[#members + 1] = {
                    id = memberId,
                    name = displayName, -- 🆕 Nom FiveM [ID]
                    isLeader = memberId == group.leaderId,
                    isReady = group.ready[memberId] or false,
                    isYou = memberId == playerId,
                    yourId = playerId,
                    avatar = avatarUrl
                }
                
                completed = completed + 1
                if completed == total then
                    callback({id = group.id, leaderId = group.leaderId, members = members})
                end
            end)
        else
            members[#members + 1] = {
                id = memberId,
                name = displayName, -- 🆕 Nom FiveM [ID]
                isLeader = memberId == group.leaderId,
                isReady = group.ready[memberId] or false,
                isYou = memberId == playerId,
                yourId = playerId,
                avatar = Config.Discord and Config.Discord.defaultAvatar or 'https://cdn.discordapp.com/embed/avatars/0.png'
            }
            
            completed = completed + 1
            if completed == total then
                callback({id = group.id, leaderId = group.leaderId, members = members})
            end
        end
    end
end

-- ========================================
-- 🔧 FONCTION MODIFIÉE: UTILISER NOM FIVEM + ID
-- ========================================
function GetGroupData(playerId)
    local group = GetPlayerGroup(playerId)
    if not group then return nil end
    
    local members = {}
    for i = 1, #group.members do
        local memberId = group.members[i]
        
        -- 🆕 Utiliser le nom FiveM au lieu de xPlayer.getName()
        local displayName = GetPlayerFiveMNameWithID(memberId)
        local avatarUrl = Config.Discord and Config.Discord.defaultAvatar or 'https://cdn.discordapp.com/embed/avatars/0.png'
        
        if Config.Discord and Config.Discord.enabled then
            avatarUrl = exports['pvp_gunfight']:GetPlayerDiscordAvatar(memberId)
        end
        
        members[#members + 1] = {
            id = memberId,
            name = displayName, -- 🆕 Nom FiveM [ID]
            isLeader = memberId == group.leaderId,
            isReady = group.ready[memberId] or false,
            isYou = memberId == playerId,
            yourId = playerId,
            avatar = avatarUrl
        }
    end
    
    return {id = group.id, leaderId = group.leaderId, members = members}
end

-- ========================================
-- [... RESTE DU CODE IDENTIQUE ...]
-- ========================================

function RemovePlayerFromGroup(playerId)
    local group = GetPlayerGroup(playerId)
    if not group then
        playerGroups[playerId] = nil
        return
    end
    
    for i = #group.members, 1, -1 do
        if group.members[i] == playerId then
            table.remove(group.members, i)
            break
        end
    end
    
    group.ready[playerId] = nil
    playerGroups[playerId] = nil
    
    TriggerClientEvent('pvp:updateGroupUI', playerId, nil)
    
    if #group.members == 0 then
        groups[group.id] = nil
    else
        if group.leaderId == playerId then
            group.leaderId = group.members[1]
            TriggerClientEvent('esx:showNotification', group.leaderId, '~b~Vous êtes maintenant le leader')
        end
        BroadcastToGroup(group.id)
    end
end

function ForceCleanPlayerGroup(playerId)
    DebugGroups('🧹 Nettoyage forcé groupe - Joueur %d', playerId)
    
    local groupId = playerGroups[playerId]
    playerGroups[playerId] = nil
    
    if groupId and groups[groupId] then
        local group = groups[groupId]
        
        for i = #group.members, 1, -1 do
            if group.members[i] == playerId then
                table.remove(group.members, i)
                break
            end
        end
        
        group.ready[playerId] = nil
        
        if #group.members == 0 then
            groups[groupId] = nil
            DebugGroups('Groupe %d supprimé (vide)', groupId)
        else
            if group.leaderId == playerId then
                group.leaderId = group.members[1]
                DebugGroups('Nouveau leader: %d', group.leaderId)
            end
            BroadcastToGroup(groupId)
        end
    end
    
    TriggerClientEvent('pvp:updateGroupUI', playerId, nil)
    DebugGroups('✅ Nettoyage terminé - Joueur %d', playerId)
end

function RestoreGroupsAfterMatch(playerIds, wasSoloMatch)
    DebugGroups('Restauration groupes: %d joueurs (Solo: %s)', #playerIds, tostring(wasSoloMatch))
    
    if wasSoloMatch then
        DebugGroups('Match solo détecté - Nettoyage complet')
        
        for i = 1, #playerIds do
            local playerId = playerIds[i]
            if playerId > 0 and GetPlayerPing(playerId) > 0 then
                ForceCleanPlayerGroup(playerId)
            end
        end
        
        return
    end
    
    local processedGroups = {}
    
    for i = 1, #playerIds do
        local playerId = playerIds[i]
        if playerId > 0 and GetPlayerPing(playerId) > 0 then
            local group = GetPlayerGroup(playerId)
            
            if group and not processedGroups[group.id] then
                BroadcastToGroup(group.id)
                processedGroups[group.id] = true
            end
        end
    end
end

function ResetPlayerReadyStatus(playerId)
    local group = GetPlayerGroup(playerId)
    if not group then return false end
    
    group.ready[playerId] = false
    return true
end

function BroadcastGroupUpdateForPlayer(playerId)
    local group = GetPlayerGroup(playerId)
    if group then
        BroadcastToGroup(group.id)
    end
end

-- ========================================
-- EVENTS RÉSEAU MODIFIÉS
-- ========================================
RegisterNetEvent('pvp:inviteToGroup', function(targetId)
    local src = source
    
    -- 🆕 Utiliser nom FiveM pour les notifications
    local inviterName = GetPlayerFiveMNameWithID(src)
    local targetName = GetPlayerFiveMNameWithID(targetId)
    
    if not targetId or GetPlayerPing(targetId) <= 0 then
        TriggerClientEvent('esx:showNotification', src, '~r~Joueur introuvable')
        return
    end
    
    local targetGroup = GetPlayerGroup(targetId)
    if targetGroup then
        if #targetGroup.members == 1 and targetGroup.members[1] == targetId then
            DebugGroups('⚠️ Groupe solo détecté pour joueur %d - Nettoyage', targetId)
            ForceCleanPlayerGroup(targetId)
        else
            TriggerClientEvent('esx:showNotification', src, '~r~' .. targetName .. ' est déjà dans un groupe!')
            return
        end
    end
    
    local group = GetPlayerGroup(src)
    if not group then
        CreateGroup(src)
        group = GetPlayerGroup(src)
    end
    
    if group.leaderId ~= src then
        TriggerClientEvent('esx:showNotification', src, '~r~Seul le leader peut inviter')
        return
    end
    
    if #group.members >= 4 then
        TriggerClientEvent('esx:showNotification', src, '~r~Groupe complet (4 max)')
        return
    end
    
    pendingInvites[targetId] = src
    
    if Config.Discord and Config.Discord.enabled then
        exports['pvp_gunfight']:GetPlayerDiscordAvatarAsync(src, function(avatar)
            TriggerClientEvent('pvp:receiveInvite', targetId, inviterName, src, avatar)
        end)
    else
        TriggerClientEvent('pvp:receiveInvite', targetId, inviterName, src, Config.Discord.defaultAvatar)
    end
    
    TriggerClientEvent('esx:showNotification', src, '~b~Invitation envoyée à ' .. targetName)
end)

RegisterNetEvent('pvp:acceptInvite', function(inviterId)
    local src = source
    local playerName = GetPlayerFiveMNameWithID(src)
    
    if not pendingInvites[src] or pendingInvites[src] ~= inviterId then
        TriggerClientEvent('esx:showNotification', src, '~r~Invitation expirée')
        return
    end
    
    pendingInvites[src] = nil
    ForceCleanPlayerGroup(src)
    
    local group = GetPlayerGroup(inviterId)
    if not group then
        TriggerClientEvent('esx:showNotification', src, '~r~Groupe inexistant')
        return
    end
    
    if #group.members >= 4 then
        TriggerClientEvent('esx:showNotification', src, '~r~Groupe complet')
        return
    end
    
    group.members[#group.members + 1] = src
    group.ready[src] = false
    playerGroups[src] = group.id
    
    TriggerClientEvent('esx:showNotification', src, '~g~Groupe rejoint!')
    TriggerClientEvent('esx:showNotification', inviterId, '~g~' .. playerName .. ' a rejoint')
    
    Wait(200)
    BroadcastToGroup(group.id)
end)

RegisterNetEvent('pvp:leaveGroup', function()
    local src = source
    local group = GetPlayerGroup(src)
    
    if not group then
        TriggerClientEvent('esx:showNotification', src, '~r~Vous n\'êtes pas dans un groupe')
        return
    end
    
    RemovePlayerFromGroup(src)
    TriggerClientEvent('esx:showNotification', src, '~y~Groupe quitté')
end)

RegisterNetEvent('pvp:kickFromGroup', function(targetId)
    local src = source
    local group = GetPlayerGroup(src)
    
    if not group or group.leaderId ~= src then
        TriggerClientEvent('esx:showNotification', src, '~r~Vous n\'êtes pas le leader')
        return
    end
    
    local found = false
    for i = #group.members, 1, -1 do
        if group.members[i] == targetId then
            table.remove(group.members, i)
            found = true
            break
        end
    end
    
    if not found then
        TriggerClientEvent('esx:showNotification', src, '~r~Joueur introuvable')
        return
    end
    
    group.ready[targetId] = nil
    playerGroups[targetId] = nil
    
    TriggerClientEvent('esx:showNotification', targetId, '~r~Vous avez été exclu')
    TriggerClientEvent('pvp:updateGroupUI', targetId, nil)
    TriggerClientEvent('esx:showNotification', src, '~y~Joueur exclu')
    
    if #group.members == 1 then
        playerGroups[src] = nil
        group.ready[src] = nil
        groups[group.id] = nil
        TriggerClientEvent('esx:showNotification', src, '~y~Groupe dissous')
        TriggerClientEvent('pvp:updateGroupUI', src, nil)
    elseif #group.members > 1 then
        BroadcastToGroup(group.id)
    else
        groups[group.id] = nil
    end
end)

RegisterNetEvent('pvp:toggleReady', function()
    local src = source
    
    local group = GetPlayerGroup(src)
    if not group then
        CreateGroup(src)
        group = GetPlayerGroup(src)
    end
    
    group.ready[src] = not group.ready[src]
    local status = group.ready[src] and '~g~Prêt' or '~r~Pas prêt'
    
    TriggerClientEvent('esx:showNotification', src, 'Statut: ' .. status)
    BroadcastToGroup(group.id)
end)

ESX.RegisterServerCallback('pvp:getGroupInfo', function(source, cb)
    CreateThread(function()
        GetGroupDataAsync(source, function(groupData)
            cb(groupData)
        end)
    end)
end)

ESX.RegisterServerCallback('pvp:getPlayerAvatar', function(source, cb, targetId)
    local playerId = targetId or source
    
    if Config.Discord and Config.Discord.enabled then
        exports['pvp_gunfight']:GetPlayerDiscordAvatarAsync(playerId, function(avatarUrl)
            cb(avatarUrl)
        end)
    else
        cb(Config.Discord and Config.Discord.defaultAvatar or 'https://cdn.discordapp.com/embed/avatars/0.png')
    end
end)

ESX.RegisterServerCallback('pvp:getPlayersAvatars', function(source, cb, playerIds)
    local avatars = {}
    local completed = 0
    local total = #playerIds
    
    if total == 0 then
        cb(avatars)
        return
    end
    
    for i = 1, #playerIds do
        local playerId = playerIds[i]
        if Config.Discord and Config.Discord.enabled then
            exports['pvp_gunfight']:GetPlayerDiscordAvatarAsync(playerId, function(avatarUrl)
                avatars[playerId] = avatarUrl
                completed = completed + 1
                if completed == total then cb(avatars) end
            end)
        else
            avatars[playerId] = Config.Discord and Config.Discord.defaultAvatar or 'https://cdn.discordapp.com/embed/avatars/0.png'
            completed = completed + 1
            if completed == total then cb(avatars) end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    
    local group = GetPlayerGroup(src)
    if group then
        RemovePlayerFromGroup(src)
    end
    
    pendingInvites[src] = nil
end)

-- ========================================
-- EXPORTS
-- ========================================
exports('GetPlayerGroup', GetPlayerGroup)
exports('RemovePlayerFromGroup', RemovePlayerFromGroup)
exports('ForceCleanPlayerGroup', ForceCleanPlayerGroup)
exports('GetGroupDataAsync', GetGroupDataAsync)
exports('RestoreGroupsAfterMatch', RestoreGroupsAfterMatch)
exports('ResetPlayerReadyStatus', ResetPlayerReadyStatus)
exports('BroadcastGroupUpdateForPlayer', BroadcastGroupUpdateForPlayer)

DebugSuccess('Module groupes initialisé (VERSION 4.1.0 - Nom FiveM + ID)')