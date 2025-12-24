-- ========================================
-- PVP GUNFIGHT - CLIENT MAIN
-- Version 4.11.0 - SYSTÈME ANTI-ARME-MANQUANTE
-- ========================================

DebugSuccess('Script chargé (Version 4.11.0 - Anti-Arme-Manquante)')

-- Variables locales
local pedSpawned = false
local pedEntity = nil
local uiOpen = false
local LOBBY_COORDS = nil
local isProtectedFromOtherScripts = false
local isNearRankedPed = false

-- Cache des natives (LOCALES)
local _PlayerPedId = PlayerPedId
local _GetEntityCoords = GetEntityCoords
local _IsControlJustReleased = IsControlJustReleased
local _Wait = Wait
local _GetGameTimer = GetGameTimer
local _GetHashKey = GetHashKey
local _IsEntityDead = IsEntityDead
local _GetPedSourceOfDeath = GetPedSourceOfDeath
local _NetworkGetPlayerIndexFromPed = NetworkGetPlayerIndexFromPed
local _GetPlayerServerId = GetPlayerServerId
local _RestorePlayerStamina = RestorePlayerStamina
local _GetPlayerFromServerId = GetPlayerFromServerId
local _GetPlayerPed = GetPlayerPed
local _NetworkIsPlayerActive = NetworkIsPlayerActive
local _FreezeEntityPosition = FreezeEntityPosition
local _SetEntityCoords = SetEntityCoords
local _SetEntityHeading = SetEntityHeading
local _SetEntityHealth = SetEntityHealth
local _DoScreenFadeOut = DoScreenFadeOut
local _DoScreenFadeIn = DoScreenFadeIn
local _PlaySoundFrontend = PlaySoundFrontend
local _SetCanAttackFriendly = SetCanAttackFriendly
local _SetPedRelationshipGroupHash = SetPedRelationshipGroupHash

-- ========================================
-- 🆕 SYSTÈME ANTI-ARME-MANQUANTE
-- ========================================
local weaponCheckAttempts = 0
local MAX_WEAPON_CHECK_ATTEMPTS = 5
local lastWeaponCheckTime = 0
local WEAPON_CHECK_INTERVAL = 500

-- ========================================
-- CONFIGURATION ARMES
-- ========================================
local WEAPON_CONFIG = {
    hash = _GetHashKey('WEAPON_PISTOL50'),
    ammo = 250,
    clipSize = 9
}

-- ========================================
-- 🔧 FONCTION AMÉLIORÉE: DONNER ARMES AVEC RETRY
-- ========================================
local function GiveMatchWeapons(ped)
    RemoveAllPedWeapons(ped, true)
    
    -- Attendre un frame pour que la suppression soit effective
    Wait(50)
    
    -- Donner l'arme
    GiveWeaponToPed(ped, WEAPON_CONFIG.hash, WEAPON_CONFIG.ammo, false, true)
    
    -- Attendre que l'arme soit donnée
    Wait(100)
    
    -- Équiper l'arme
    SetCurrentPedWeapon(ped, WEAPON_CONFIG.hash, true)
    
    -- Vérifier immédiatement
    local hasWeapon, currentWeapon = GetCurrentPedWeapon(ped, true)
    
    if not hasWeapon or currentWeapon ~= WEAPON_CONFIG.hash then
        DebugWarn('⚠️ Arme non équipée au premier essai - Retry...')
        
        -- Retry immédiat
        Wait(100)
        RemoveAllPedWeapons(ped, true)
        Wait(50)
        GiveWeaponToPed(ped, WEAPON_CONFIG.hash, WEAPON_CONFIG.ammo, false, true)
        Wait(100)
        SetCurrentPedWeapon(ped, WEAPON_CONFIG.hash, true)
        
        -- Vérifier à nouveau
        hasWeapon, currentWeapon = GetCurrentPedWeapon(ped, true)
        
        if not hasWeapon or currentWeapon ~= WEAPON_CONFIG.hash then
            DebugError('❌ ÉCHEC attribution arme - Notification serveur')
            TriggerServerEvent('pvp:weaponCheckFailed')
        else
            DebugSuccess('✅ Arme équipée après retry')
        end
    else
        DebugClient('✅ Armes données - %d munitions', WEAPON_CONFIG.ammo)
    end
end

-- ========================================
-- 🔧 NOUVELLE FONCTION: VÉRIFIER ET FORCER ARME
-- ========================================
local function ForceWeaponCheck(ped)
    local hasWeapon, currentWeapon = GetCurrentPedWeapon(ped, true)
    
    if not hasWeapon or currentWeapon ~= WEAPON_CONFIG.hash then
        DebugWarn('🔫 ARME MANQUANTE DÉTECTÉE - Correction...')
        
        -- Forcer attribution
        RemoveAllPedWeapons(ped, true)
        Wait(50)
        GiveWeaponToPed(ped, WEAPON_CONFIG.hash, WEAPON_CONFIG.ammo, false, true)
        Wait(50)
        SetCurrentPedWeapon(ped, WEAPON_CONFIG.hash, true)
        
        -- Vérifier résultat
        hasWeapon, currentWeapon = GetCurrentPedWeapon(ped, true)
        
        if hasWeapon and currentWeapon == WEAPON_CONFIG.hash then
            DebugSuccess('✅ Arme forcée avec succès')
            TriggerServerEvent('pvp:weaponForced')
            return true
        else
            DebugError('❌ Échec forçage arme - Alert serveur')
            TriggerServerEvent('pvp:weaponCheckFailed')
            return false
        end
    end
    
    return true
end

-- ========================================
-- 🔧 NOUVELLE FONCTION: VÉRIFICATION POST-SPAWN
-- ========================================
local function PostSpawnWeaponCheck()
    CreateThread(function()
        -- Attendre que le joueur soit complètement spawné
        Wait(1000)
        
        local ped = GetCachedPed()
        
        if IsInMatch() then
            DebugClient('🔍 Vérification post-spawn arme...')
            
            -- Vérifier 5 fois avec délai croissant
            for attempt = 1, 5 do
                local hasWeapon, currentWeapon = GetCurrentPedWeapon(ped, true)
                
                if not hasWeapon or currentWeapon ~= WEAPON_CONFIG.hash then
                    DebugWarn('⚠️ Tentative %d/5 - Arme manquante', attempt)
                    
                    -- Forcer l'arme
                    RemoveAllPedWeapons(ped, true)
                    Wait(50)
                    GiveWeaponToPed(ped, WEAPON_CONFIG.hash, WEAPON_CONFIG.ammo, false, true)
                    Wait(100)
                    SetCurrentPedWeapon(ped, WEAPON_CONFIG.hash, true)
                    
                    Wait(500 * attempt) -- Délai croissant
                else
                    DebugSuccess('✅ Arme vérifiée OK (tentative %d)', attempt)
                    break
                end
            end
            
            -- Vérification finale
            local hasWeapon, currentWeapon = GetCurrentPedWeapon(ped, true)
            
            if not hasWeapon or currentWeapon ~= WEAPON_CONFIG.hash then
                DebugError('❌ ÉCHEC FINAL - Arme toujours manquante après 5 tentatives')
                TriggerServerEvent('pvp:weaponCheckFailed')
                ESX.ShowNotification('~r~⚠️ Problème arme détecté - Contactez un admin')
            else
                DebugSuccess('✅ Vérification post-spawn terminée - Arme OK')
            end
        end
    end)
end

-- ========================================
-- EXPORTS
-- ========================================
exports('IsPlayerInPVP', function()
    return IsInMatch() or IsInQueue()
end)

exports('IsPlayerSearchingPVP', function()
    return IsInQueue()
end)

exports('IsPlayerInPVPMatch', function()
    return IsInMatch()
end)

exports('CanPlayerInteract', function()
    if IsInMatch() or IsInQueue() then
        return false
    end
    return true
end)

exports('IsNearRankedPed', function()
    return isNearRankedPed
end)

-- ========================================
-- FONCTION: ACTIVER/DÉSACTIVER PROTECTION
-- ========================================
local function SetScriptProtection(enabled)
    isProtectedFromOtherScripts = enabled
    
    if enabled then
        DebugClient('🔒 PROTECTION ACTIVÉE - Blocage total autres scripts')
    else
        DebugClient('🔓 PROTECTION DÉSACTIVÉE')
        isNearRankedPed = false
    end
end

-- ========================================
-- THREAD: BLOCAGE TOTAL INTERACTIONS (AMÉLIORÉ v2)
-- ========================================
local pedCoords = nil

CreateThread(function()
    while not pedSpawned do
        Wait(100)
    end
    
    pedCoords = vector3(Config.PedLocation.coords.x, Config.PedLocation.coords.y, Config.PedLocation.coords.z)
    
    DebugSuccess('Thread protection ULTRA démarré (Version améliorée v2)')
    
    while true do
        if not isProtectedFromOtherScripts then
            _Wait(1000)
            isNearRankedPed = false
        else
            _Wait(0)
            
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - pedCoords)
            
            isNearRankedPed = (distance <= Config.InteractionDistance)
            
            if IsInMatch() then
                DisableControlAction(0, 38, true)
                DisableControlAction(0, 51, true)
                DisableControlAction(0, 46, true)
                DisableControlAction(0, 23, true)
                DisableControlAction(0, 75, true)
                DisableControlAction(0, 44, true)
                DisableControlAction(0, 74, true)
                DisableControlAction(0, 244, true)
                DisableControlAction(0, 323, true)
                DisableControlAction(0, 170, true)
                DisableControlAction(0, 243, true)
                
            elseif distance > Config.InteractionDistance then
                DisableControlAction(0, 38, true)
                DisableControlAction(0, 51, true)
                DisableControlAction(0, 46, true)
                DisableControlAction(1, 38, true)
                DisableControlAction(1, 51, true)
                DisableControlAction(2, 38, true)
                DisableControlAction(2, 51, true)
                DisableControlAction(0, 23, true)
                DisableControlAction(0, 75, true)
                DisableControlAction(0, 44, true)
                DisableControlAction(0, 74, true)
                DisableControlAction(0, 86, true)
                DisableControlAction(0, 244, true)
                DisableControlAction(0, 323, true)
                DisableControlAction(0, 170, true)
                DisableControlAction(0, 243, true)
                
                if IsDisabledControlJustPressed(0, 38) or IsDisabledControlJustPressed(0, 51) then
                    ESX.ShowNotification('~r~Impossible d\'interagir pendant la recherche PVP!')
                    ESX.ShowNotification('~y~Retournez au PED Ranked pour annuler')
                end
                
            else
                DisableControlAction(0, 44, true)
                DisableControlAction(0, 74, true)
                DisableControlAction(0, 75, true)
                DisableControlAction(0, 86, true)
                DisableControlAction(0, 244, true)
                DisableControlAction(0, 323, true)
                DisableControlAction(0, 170, true)
                DisableControlAction(0, 243, true)
                DisableControlAction(0, 23, true)
            end
        end
    end
end)

-- ========================================
-- THREAD: VÉRIFICATION POSITION EN MATCH
-- ========================================
CreateThread(function()
    DebugSuccess('Thread vérification position démarré')
    
    while true do
        if not IsInMatch() then
            _Wait(5000)
        else
            _Wait(2000)
            
            local currentArena = GetCurrentArena()
            if currentArena and Config.Arenas[currentArena] then
                local arena = Config.Arenas[currentArena]
                local playerCoords = _GetEntityCoords(_PlayerPedId())
                
                local inArenaZone = false
                
                if arena.zoneCenter and arena.zoneRadius then
                    local distance = #(playerCoords - vector3(arena.zoneCenter.x, arena.zoneCenter.y, arena.zoneCenter.z))
                    
                    if distance <= arena.zoneRadius then
                        inArenaZone = true
                    end
                end
                
                if not inArenaZone then
                    DebugWarn('🚨 JOUEUR HORS ZONE - Demande de re-téléportation')
                    TriggerServerEvent('pvp:playerOutOfArena')
                end
            end
        end
    end
end)

-- ========================================
-- EVENT: RE-TÉLÉPORTATION FORCÉE
-- ========================================
RegisterNetEvent('pvp:forceTeleportToArena', function(spawn)
    DebugClient('🔄 Re-téléportation forcée à l\'arène')
    
    local ped = GetCachedPed()
    
    _DoScreenFadeOut(300)
    _Wait(300)
    
    _SetEntityCoords(ped, spawn.x, spawn.y, spawn.z, false, false, false, false)
    _SetEntityHeading(ped, spawn.w)
    
    _Wait(300)
    _DoScreenFadeIn(300)
    
    ESX.ShowNotification('~y~Vous avez été retéléporté à l\'arène!')
end)

-- ========================================
-- HEARTBEAT THREAD
-- ========================================
CreateThread(function()
    DebugSuccess('Thread heartbeat démarré (envoi toutes les 3 secondes)')
    
    while true do
        _Wait(3000)
        
        if IsInMatch() or IsInQueue() then
            TriggerServerEvent('pvp:heartbeat')
        end
    end
end)

-- ========================================
-- FONCTION AMÉLIORÉE: CONFIGURER ANTI-FRIENDLY FIRE
-- ========================================
local function SetupTeamRelations(myPed, teammates)
    if not teammates or #teammates == 0 then 
        DebugClient('Pas de coéquipiers à configurer')
        return 
    end
    
    DebugClient('🛡️ Configuration anti-friendly fire pour %d coéquipiers', #teammates)
    
    _SetCanAttackFriendly(myPed, false, false)
    
    local relationshipGroup = _GetHashKey('PLAYER')
    _SetPedRelationshipGroupHash(myPed, relationshipGroup)
    
    for _, teammateServerId in ipairs(teammates) do
        local teammatePlayerIndex = _GetPlayerFromServerId(teammateServerId)
        
        if teammatePlayerIndex and teammatePlayerIndex ~= -1 and _NetworkIsPlayerActive(teammatePlayerIndex) then
            local teammatePed = _GetPlayerPed(teammatePlayerIndex)
            
            if teammatePed and DoesEntityExist(teammatePed) then
                _SetPedRelationshipGroupHash(teammatePed, relationshipGroup)
                _SetCanAttackFriendly(teammatePed, false, false)
                SetRelationshipBetweenGroups(1, relationshipGroup, relationshipGroup)
                
                DebugClient('Relation configurée avec coéquipier %d', teammateServerId)
            end
        end
    end
    
    DebugSuccess('✅ Relations d\'équipe configurées')
end

-- ========================================
-- NOUVEAU THREAD: VÉRIFICATION CONTINUE DES RELATIONS
-- ========================================
CreateThread(function()
    DebugSuccess('Thread vérification relations d\'équipe démarré')
    
    while true do
        if not IsInMatch() then
            _Wait(2000)
        else
            _Wait(1000)
            
            local teammates = GetTeammates()
            
            if teammates and #teammates > 0 then
                local myPed = GetCachedPed()
                SetupTeamRelations(myPed, teammates)
            end
        end
    end
end)

-- ========================================
-- UI
-- ========================================
local function OpenUI()
    if uiOpen then
        DebugClient('UI déjà ouverte - Fermeture puis réouverture')
        CloseUI()
        _Wait(100)
    end
    
    DebugClient('Ouverture UI')
    SetNuiFocus(true, true)
    
    if IsInQueue() then
        SendNUIMessage({ 
            action = 'openUI',
            isSearching = true
        })
        DebugClient('UI ouverte en mode recherche')
    else
        SendNUIMessage({ action = 'openUI' })
    end
    
    uiOpen = true
end

local function CloseUI()
    if not uiOpen then return end
    
    DebugClient('Fermeture UI')
    SendNUIMessage({ action = 'closeUI' })
    _Wait(100)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    uiOpen = false
end

-- ========================================
-- NUI CALLBACKS
-- ========================================
RegisterNUICallback('closeUI', function(data, cb)
    cb('ok')
    _Wait(50)
    CloseUI()
end)

RegisterNetEvent('pvp:forceCloseUI', function()
    CloseUI()
end)

RegisterNUICallback('joinQueue', function(data, cb)
    DebugClient('Callback joinQueue - Mode: %s', data.mode)
    cb('ok')
    TriggerServerEvent('pvp:joinQueue', data.mode)
end)

RegisterNUICallback('getStats', function(data, cb)
    ESX.TriggerServerCallback('pvp:getPlayerStats', function(stats)
        cb(stats)
    end)
end)

RegisterNUICallback('getPlayerStatsByMode', function(data, cb)
    local mode = data.mode or '1v1'
    ESX.TriggerServerCallback('pvp:getPlayerStatsByMode', function(stats)
        cb(stats)
    end, mode)
end)

RegisterNUICallback('getPlayerAllModeStats', function(data, cb)
    ESX.TriggerServerCallback('pvp:getPlayerAllModeStats', function(allStats)
        cb(allStats)
    end)
end)

RegisterNUICallback('getLeaderboard', function(data, cb)
    ESX.TriggerServerCallback('pvp:getLeaderboard', function(leaderboard)
        cb(leaderboard)
    end)
end)

RegisterNUICallback('getLeaderboardByMode', function(data, cb)
    local mode = data.mode or '1v1'
    ESX.TriggerServerCallback('pvp:getLeaderboardByMode', function(leaderboard)
        cb(leaderboard)
    end, mode)
end)

RegisterNUICallback('invitePlayer', function(data, cb)
    cb('ok')
    TriggerServerEvent('pvp:inviteToGroup', tonumber(data.targetId))
end)

RegisterNUICallback('leaveGroup', function(data, cb)
    cb('ok')
    TriggerServerEvent('pvp:leaveGroup')
end)

RegisterNUICallback('kickPlayer', function(data, cb)
    cb('ok')
    TriggerServerEvent('pvp:kickFromGroup', tonumber(data.targetId))
end)

RegisterNUICallback('toggleReady', function(data, cb)
    cb('ok')
    TriggerServerEvent('pvp:toggleReady')
end)

RegisterNUICallback('getGroupInfo', function(data, cb)
    ESX.TriggerServerCallback('pvp:getGroupInfo', function(groupInfo)
        cb(groupInfo)
    end)
end)

RegisterNUICallback('acceptInvite', function(data, cb)
    cb('ok')
    TriggerServerEvent('pvp:acceptInvite', tonumber(data.inviterId))
end)

RegisterNUICallback('declineInvite', function(data, cb)
    cb('ok')
end)

RegisterNUICallback('cancelSearch', function(data, cb)
    cb('ok')
    TriggerServerEvent('pvp:cancelSearch')
end)

-- ========================================
-- EVENTS RÉSEAU - GROUPE
-- ========================================
RegisterNetEvent('pvp:updateGroupUI', function(groupData)
    SendNUIMessage({
        action = 'updateGroup',
        group = groupData
    })
end)

RegisterNetEvent('pvp:receiveInvite', function(inviterName, inviterId)
    ESX.ShowNotification('~b~' .. inviterName .. '~w~ vous invite à rejoindre son groupe!')
    SendNUIMessage({
        action = 'showInvite',
        inviterName = inviterName,
        inviterId = inviterId
    })
end)

-- ========================================
-- EVENTS RÉSEAU - MATCHMAKING
-- ========================================
RegisterNetEvent('pvp:searchStarted', function(mode)
    DebugClient('Recherche commencée: %s', mode)
    SetInQueue(true)
    SetQueueStartTime(_GetGameTimer())
    
    SetScriptProtection(true)
    
    SendNUIMessage({
        action = 'searchStarted',
        mode = mode
    })
end)

RegisterNetEvent('pvp:matchFound', function()
    DebugSuccess('Match trouvé!')
    SetInQueue(false)
    SetInMatch(true)
    SetMatchDead(false)
    
    SetScriptProtection(true)
    
    SendNUIMessage({ action = 'closeInvitationsPanel' })
    
    if uiOpen then
        CloseUI()
    end
    
    SendNUIMessage({ action = 'matchFound' })
end)



RegisterNetEvent('pvp:searchCancelled', function()
    SetInQueue(false)
    
    SetScriptProtection(false)
    
    SendNUIMessage({ action = 'searchCancelled' })
end)

RegisterNetEvent('pvp:setTeammates', function(teammateIds)
    DebugClient('Réception coéquipiers: %s', json.encode(teammateIds))
    SetTeammates(teammateIds or {})
    
    local myPed = GetCachedPed()
    SetupTeamRelations(myPed, teammateIds)
end)

-- ========================================
-- 🔧 EVENTS RÉSEAU - TÉLÉPORTATION (MODIFIÉ AVEC VÉRIFICATIONS)
-- ========================================
RegisterNetEvent('pvp:teleportToSpawn', function(spawn, team, matchId, arenaKey)
    DebugClient('Téléportation - Team: %s, Match: %d', team, matchId)
    
    SetPlayerTeam(team)
    SetMatchDead(false)
    SetCurrentArena(arenaKey)
    
    local ped = GetCachedPed()
    
    if _IsEntityDead(ped) then
        NetworkResurrectLocalPlayer(spawn.x, spawn.y, spawn.z, spawn.w, true, false)
        _Wait(100)
        ped = _PlayerPedId()
    end
    
    _DoScreenFadeOut(500)
    _Wait(500)
    
    _SetEntityCoords(ped, spawn.x, spawn.y, spawn.z, false, false, false, false)
    _SetEntityHeading(ped, spawn.w)
    _FreezeEntityPosition(ped, true)
    _SetEntityHealth(ped, 200)
    SetPedArmour(ped, 100)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    
    -- 🔧 Attribution armes avec vérification
    GiveMatchWeapons(ped)
    
    exports['pvp_gunfight']:EnableDamageSystem()
    
    _Wait(500)
    _DoScreenFadeIn(500)
    
    local teamColor = team == 'team1' and '~b~' or '~r~'
    ESX.ShowNotification(teamColor .. 'Vous êtes dans la ' .. (team == 'team1' and 'Team A (Bleu)' or 'Team B (Rouge)'))
    
    if arenaKey then
        TriggerEvent('pvp:setArenaZone', arenaKey)
        TriggerEvent('pvp:enableZones')
    end
    
    local teammates = GetTeammates()
    if #teammates > 0 then
        TriggerEvent('pvp:enableTeammateHUD', teammates)
    end
    
    -- 🔧 NOUVEAU: Vérification post-spawn
    PostSpawnWeaponCheck()
end)

RegisterNetEvent('pvp:respawnPlayer', function(spawn)
    SetMatchDead(false)
    
    local ped = GetCachedPed()
    
    if _IsEntityDead(ped) then
        NetworkResurrectLocalPlayer(spawn.x, spawn.y, spawn.z, spawn.w, true, false)
        _Wait(100)
        ped = _PlayerPedId()
    end
    
    _DoScreenFadeOut(300)
    _Wait(300)
    
    _SetEntityCoords(ped, spawn.x, spawn.y, spawn.z, false, false, false, false)
    _SetEntityHeading(ped, spawn.w)
    _SetEntityHealth(ped, 200)
    SetPedArmour(ped, 100)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    
    -- 🔧 Attribution armes avec vérification
    GiveMatchWeapons(ped)
    
    local teammates = GetTeammates()
    if #teammates > 0 then
        SetupTeamRelations(ped, teammates)
    end
    
    _Wait(300)
    _DoScreenFadeIn(300)
    
    -- 🔧 NOUVEAU: Vérification post-respawn
    PostSpawnWeaponCheck()
end)

RegisterNetEvent('pvp:freezePlayer', function()
    _FreezeEntityPosition(GetCachedPed(), true)
end)

-- ========================================
-- EVENTS RÉSEAU - ROUNDS
-- ========================================
RegisterNetEvent('pvp:roundStart', function(roundNumber)
    DebugClient('Début round %d (SANS ANIMATION)', roundNumber)
    
    local ped = GetCachedPed()
    _FreezeEntityPosition(ped, true)
    SetCanShoot(false)
    SetMatchDead(false)
    
    _PlaySoundFrontend(-1, "GO", "HUD_MINI_GAME_SOUNDSET", true)
    
    _Wait(500)
    
    _FreezeEntityPosition(ped, false)
    SetCanShoot(true)
    DebugSuccess('Round %d lancé', roundNumber)
end)

RegisterNetEvent('pvp:roundEnd', function(winningTeam, score, serverPlayerTeam, isVictory)
    SetCanShoot(false)
    
    local actualIsVictory = isVictory
    if actualIsVictory == nil then
        local teamToUse = serverPlayerTeam or GetPlayerTeam()
        actualIsVictory = (winningTeam == teamToUse)
    end
    
    DebugClient('Round terminé - Winner: %s, isVictory: %s', winningTeam, tostring(actualIsVictory))
    
    SendNUIMessage({
        action = 'showRoundEnd',
        winner = winningTeam,
        score = score,
        playerTeam = serverPlayerTeam or GetPlayerTeam(),
        isVictory = actualIsVictory
    })
    
    _PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true)
end)

RegisterNetEvent('pvp:updateScore', function(score, round)
    SendNUIMessage({
        action = 'updateScore',
        score = score,
        round = round
    })
end)

RegisterNetEvent('pvp:showScoreHUD', function(score, round)
    SendNUIMessage({
        action = 'showScoreHUD',
        score = score,
        round = round
    })
end)

RegisterNetEvent('pvp:hideScoreHUD', function()
    SendNUIMessage({ action = 'hideScoreHUD' })
end)

RegisterNetEvent('pvp:showKillfeed', function(killerName, victimName, weapon, isHeadshot)
    SendNUIMessage({
        action = 'showKillfeed',
        killerName = killerName,
        victimName = victimName,
        weapon = weapon,
        isHeadshot = isHeadshot
    })
end)

-- ========================================
-- EVENTS RÉSEAU - FIN DE MATCH
-- ========================================
RegisterNetEvent('pvp:matchEnd', function(victory, score, serverPlayerTeam)
    DebugClient('Fin match - Victoire: %s', tostring(victory))
    
    SetInMatch(false)
    SetCanShoot(false)
    SetMatchDead(false)
    SetTeammates({})
    
    SetScriptProtection(false)
    
    TriggerEvent('pvp:disableZones')
    TriggerEvent('pvp:disableTeammateHUD')
    
    SendNUIMessage({
        action = 'showMatchEnd',
        victory = victory,
        score = score,
        playerTeam = serverPlayerTeam or GetPlayerTeam()
    })
    
    if victory then
        _PlaySoundFrontend(-1, "RACE_PLACED", "HUD_AWARDS", true)
    else
        _PlaySoundFrontend(-1, "CHECKPOINT_MISSED", "HUD_MINI_GAME_SOUNDSET", true)
    end
    
    _Wait(3000)
    
    SetPlayerTeam(nil)
    
    local ped = GetCachedPed()
    if _IsEntityDead(ped) then
        local coords = _GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
        _Wait(100)
    end
    
    _DoScreenFadeOut(500)
    _Wait(500)
    
    ped = _PlayerPedId()
    _SetEntityCoords(ped, Config.PedLocation.coords.x, Config.PedLocation.coords.y, Config.PedLocation.coords.z, false, false, false, false)
    _SetEntityHeading(ped, Config.PedLocation.coords.w)
    _SetEntityHealth(ped, 200)
    SetPedArmour(ped, 0)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    RemoveAllPedWeapons(ped, true)
    
    _DoScreenFadeIn(500)
    
    ESX.ShowNotification('~b~Retour au lobby')
end)

RegisterNetEvent('pvp:forceReturnToLobby', function()
    DebugClient('Retour forcé au lobby')
    
    ResetMatchState()
    
    SetScriptProtection(false)
    
    TriggerEvent('pvp:disableZones')
    TriggerEvent('pvp:disableTeammateHUD')
    
    local ped = GetCachedPed()
    
    if _IsEntityDead(ped) then
        local coords = _GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
        _Wait(100)
    end
    
    _DoScreenFadeOut(500)
    _Wait(500)
    
    ped = _PlayerPedId()
    _SetEntityCoords(ped, Config.PedLocation.coords.x, Config.PedLocation.coords.y, Config.PedLocation.coords.z, false, false, false, false)
    _SetEntityHeading(ped, Config.PedLocation.coords.w)
    _SetEntityHealth(ped, 200)
    SetPedArmour(ped, 0)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    RemoveAllPedWeapons(ped, true)
    _FreezeEntityPosition(ped, false)
    
    _DoScreenFadeIn(500)
end)

-- ========================================
-- 🆕 EVENT: MISE À JOUR STATS QUEUES
-- ========================================
RegisterNetEvent('pvp:updateQueueStats', function(stats)
    SendNUIMessage({
        action = 'updateQueueStats',
        stats = stats
    })
end)

-- ========================================
-- DÉTECTION DE MORT (EVENT-DRIVEN)
-- ========================================
AddEventHandler('gameEventTriggered', function(eventName, eventData)
    if eventName ~= 'CEventNetworkEntityDamage' then return end
    if not IsInMatch() then return end
    if IsMatchDead() then return end
    
    local victim = eventData[1]
    local attacker = eventData[2]
    local victimDied = eventData[4] == 1
    
    if not victimDied then return end
    if victim ~= GetCachedPed() then return end
    
    SetMatchDead(true)
    
    local killerPlayer = nil
    
    if attacker and IsEntityAPed(attacker) and IsPedAPlayer(attacker) then
        local killerIndex = _NetworkGetPlayerIndexFromPed(attacker)
        if killerIndex then
            killerPlayer = _GetPlayerServerId(killerIndex)
        end
    end
    
    DebugClient('Joueur mort - Killer: %s', killerPlayer or 'suicide/zone')
    TriggerServerEvent('pvp:playerDied', killerPlayer)
end)

-- ========================================
-- THREAD: DÉTECTION MORT BACKUP
-- ========================================
CreateThread(function()
    while true do
        if not IsInMatch() then
            _Wait(2000)
        elseif IsMatchDead() then
            _Wait(500)
        else
            local ped = GetCachedPed()
            
            if _IsEntityDead(ped) then
                SetMatchDead(true)
                
                local killer = _GetPedSourceOfDeath(ped)
                local killerPlayer = nil
                
                if killer and IsEntityAPed(killer) and IsPedAPlayer(killer) then
                    local killerIndex = _NetworkGetPlayerIndexFromPed(killer)
                    if killerIndex then
                        killerPlayer = _GetPlayerServerId(killerIndex)
                    end
                end
                
                DebugClient('[BACKUP] Joueur mort - Killer: %s', killerPlayer or 'suicide')
                TriggerServerEvent('pvp:playerDied', killerPlayer)
            end
            
            _Wait(Config.Performance.intervals.deathDetection)
        end
    end
end)

-- ========================================
-- THREAD: STAMINA
-- ========================================
CreateThread(function()
    while true do
        if IsInMatch() then
            _RestorePlayerStamina(PlayerId(), 100.0)
            _Wait(Config.Performance.intervals.staminaRestore)
        else
            _Wait(2000)
        end
    end
end)

-- ========================================
-- THREAD: CONTRÔLES DE TIR (RENDU UNIQUEMENT)
-- ========================================
CreateThread(function()
    while true do
        if not IsInMatch() then
            _Wait(1000)
        else
            _Wait(0)
            
            if not CanShoot() then
                DisableControlAction(0, 24, true)
                DisableControlAction(0, 25, true)
                DisableControlAction(0, 257, true)
                DisableControlAction(0, 140, true)
                DisableControlAction(0, 141, true)
                DisableControlAction(0, 142, true)
            end
            
            DisableControlAction(0, 14, true)
            DisableControlAction(0, 15, true)
            DisableControlAction(0, 16, true)
            DisableControlAction(0, 17, true)
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 157, true)
            DisableControlAction(0, 158, true)
            DisableControlAction(0, 159, true)
            DisableControlAction(0, 160, true)
            DisableControlAction(0, 161, true)
            DisableControlAction(0, 162, true)
            DisableControlAction(0, 163, true)
            DisableControlAction(0, 164, true)
            DisableControlAction(0, 165, true)
        end
    end
end)

-- ========================================
-- 🔧 THREAD MODIFIÉ: VÉRIFICATION ARMES (LOGIQUE RENFORCÉE)
-- ========================================
CreateThread(function()
    DebugSuccess('Thread vérification armes démarré (RENFORCÉ)')
    
    while true do
        if not IsInMatch() then
            _Wait(2000)
            weaponCheckAttempts = 0
            lastWeaponCheckTime = 0
        elseif IsMatchDead() then
            _Wait(1000)
        elseif not CanShoot() then
            _Wait(500)
        else
            local currentTime = _GetGameTimer()
            
            -- Vérifier toutes les 500ms au lieu de 500ms
            if currentTime - lastWeaponCheckTime >= WEAPON_CHECK_INTERVAL then
                lastWeaponCheckTime = currentTime
                
                local ped = GetCachedPed()
                local hasWeapon, weaponHash = GetCurrentPedWeapon(ped, true)
                
                if not hasWeapon or weaponHash ~= WEAPON_CONFIG.hash then
                    weaponCheckAttempts = weaponCheckAttempts + 1
                    
                    DebugWarn('🚨 ARME MANQUANTE (Tentative %d/%d)', weaponCheckAttempts, MAX_WEAPON_CHECK_ATTEMPTS)
                    
                    if weaponCheckAttempts >= MAX_WEAPON_CHECK_ATTEMPTS then
                        DebugError('❌ ÉCHEC ATTRIBUTION ARME APRÈS %d TENTATIVES', MAX_WEAPON_CHECK_ATTEMPTS)
                        TriggerServerEvent('pvp:weaponCheckFailed')
                        ESX.ShowNotification('~r~⚠️ Problème arme persistant - Contactez un admin')
                        weaponCheckAttempts = 0
                    else
                        -- Forcer l'arme
                        ForceWeaponCheck(ped)
                    end
                else
                    -- Reset compteur si arme OK
                    weaponCheckAttempts = 0
                end
            end
            
            _Wait(100)
        end
    end
end)

-- ========================================
-- THREAD: TIMER DE RECHERCHE
-- ========================================
CreateThread(function()
    while true do
        _Wait(1000)
        
        if IsInQueue() then
            local elapsed = math.floor((_GetGameTimer() - GetQueueStartTime()) / 1000)
            SendNUIMessage({
                action = 'updateSearchTimer',
                elapsed = elapsed
            })
        end
    end
end)

-- ========================================
-- THREAD: DÉTECTION DISTANCE PED
-- ========================================
local isNearPed = false

CreateThread(function()
    while not pedSpawned do
        _Wait(1000)
    end
    
    local drawDistance = Config.Performance.distances.pedDrawDistance
    local interactDistance = Config.InteractionDistance
    
    while true do
        local playerCoords = GetCachedCoords()
        local distance = #(playerCoords - pedCoords)
        
        isNearPed = distance <= interactDistance
        
        if distance > drawDistance then
            _Wait(Config.Performance.intervals.pedInteraction)
        elseif distance > interactDistance then
            _Wait(200)
        else
            _Wait(100)
        end
    end
end)

-- ========================================
-- THREAD: AFFICHAGE MARKER + HELP TEXT
-- ========================================
CreateThread(function()
    while not pedSpawned do
        _Wait(1000)
    end
    
    local markerCoords = vector3(Config.PedLocation.coords.x, Config.PedLocation.coords.y, Config.PedLocation.coords.z)
    
    while true do
        if not isNearPed then
            _Wait(500)
        else
            _Wait(0)
            
            if IsInMatch() then
                _Wait(500)
            else
                ESX.ShowHelpNotification('Appuyez sur ~INPUT_CONTEXT~ pour ouvrir le menu PVP')
                
                if Config.DrawMarker then
                    DrawMarker(2, markerCoords.x, markerCoords.y, markerCoords.z + 1.0, 
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                        0.3, 0.3, 0.3, 255, 0, 0, 200, true, true, 2, false, nil, nil, false)
                end
            end
        end
    end
end)

-- ========================================
-- THREAD: INTERACTION PED RANKED (AMÉLIORÉ)
-- ========================================
CreateThread(function()
    while not pedSpawned do
        _Wait(1000)
    end
    
    DebugSuccess('Thread interaction PED démarré (Version améliorée)')
    
    while true do
        _Wait(0)
        
        local ePressed = _IsControlJustReleased(0, 38) or IsDisabledControlJustReleased(0, 38)
        
        if ePressed then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - pedCoords)
            
            DebugClient('🔍 E relâchée - Distance: %.2fm | Protection: %s | Match: %s | NearRanked: %s', 
                distance, tostring(isProtectedFromOtherScripts), tostring(IsInMatch()), tostring(isNearRankedPed))
            
            if distance <= Config.InteractionDistance then
                if IsInMatch() then
                    ESX.ShowNotification('~r~Impossible d\'ouvrir l\'interface en match!')
                else
                    DebugClient('✅ Ouverture UI autorisée')
                    OpenUI()
                    _Wait(200)
                end
            else
                if isProtectedFromOtherScripts then
                    ESX.ShowNotification('~r~Retournez au PED Ranked pour interagir!')
                end
            end
        end
    end
end)

-- ========================================
-- CLEANUP
-- ========================================
local function CleanupAndReturnToLobby(showNotification)
    DebugClient('Cleanup complet')
    
    ResetMatchState()
    
    SetScriptProtection(false)
    
    TriggerEvent('pvp:disableZones')
    TriggerEvent('pvp:disableTeammateHUD')
    
    if uiOpen then
        CloseUI()
    end
    
    local ped = GetCachedPed()
    if _IsEntityDead(ped) then
        local coords = _GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
        _Wait(100)
        ped = _PlayerPedId()
    end
    
    _DoScreenFadeOut(500)
    _Wait(500)
    
    local lobbyX = LOBBY_COORDS and LOBBY_COORDS.x or Config.PedLocation.coords.x
    local lobbyY = LOBBY_COORDS and LOBBY_COORDS.y or Config.PedLocation.coords.y
    local lobbyZ = LOBBY_COORDS and LOBBY_COORDS.z or Config.PedLocation.coords.z
    local lobbyH = LOBBY_COORDS and LOBBY_COORDS.w or Config.PedLocation.coords.w
    
    ped = _PlayerPedId()
    _SetEntityCoords(ped, lobbyX, lobbyY, lobbyZ, false, false, false, false)
    _SetEntityHeading(ped, lobbyH)
    _SetEntityHealth(ped, 200)
    SetPedArmour(ped, 0)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    RemoveAllPedWeapons(ped, true)
    _FreezeEntityPosition(ped, false)
    
    _Wait(300)
    _DoScreenFadeIn(500)
    
    if showNotification then
        ESX.ShowNotification('~r~Ressource PVP arrêtée. Retour au lobby.')
    end
end

RegisterNetEvent('pvp:onResourceStop', function()
    CleanupAndReturnToLobby(true)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    DebugClient('Arrêt ressource - Cleanup immédiat')
    
    SetScriptProtection(false)
    
    local lobbyX = LOBBY_COORDS and LOBBY_COORDS.x or -2649.45
    local lobbyY = LOBBY_COORDS and LOBBY_COORDS.y or -767.22
    local lobbyZ = LOBBY_COORDS and LOBBY_COORDS.z or 4.75
    local lobbyH = LOBBY_COORDS and LOBBY_COORDS.w or 102.05
    
    if IsInMatch() or IsInQueue() then
        ResetMatchState()
        TriggerEvent('pvp:disableZones')
        TriggerEvent('pvp:disableTeammateHUD')
        
        local ped = _PlayerPedId()
        
        if _IsEntityDead(ped) then
            local coords = _GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
            ped = _PlayerPedId()
        end
        
        _SetEntityCoords(ped, lobbyX, lobbyY, lobbyZ, false, false, false, false)
        _SetEntityHeading(ped, lobbyH)
        _SetEntityHealth(ped, 200)
        SetPedArmour(ped, 0)
        ClearPedBloodDamage(ped)
        ResetPedVisibleDamage(ped)
        RemoveAllPedWeapons(ped, true)
        _FreezeEntityPosition(ped, false)
        
        if IsScreenFadedOut() then
            _DoScreenFadeIn(0)
        end
    end
    
    if DoesEntityExist(pedEntity) then
        DeleteEntity(pedEntity)
    end
    
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end)

-- ========================================
-- SPAWN PED
-- ========================================
local function SpawnPed()
    if pedSpawned then 
        DebugWarn('PED déjà spawné')
        return 
    end
    
    if not LOBBY_COORDS then
        LOBBY_COORDS = {
            x = Config.PedLocation.coords.x,
            y = Config.PedLocation.coords.y,
            z = Config.PedLocation.coords.z,
            w = Config.PedLocation.coords.w
        }
    end
    
    DebugClient('Spawn du PED...')
    local pedModel = _GetHashKey(Config.PedLocation.model)
    
    RequestModel(pedModel)
    local timeout = 0
    while not HasModelLoaded(pedModel) and timeout < 50 do
        _Wait(100)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(pedModel) then
        DebugError('Impossible de charger le modèle du PED')
        return
    end
    
    pedEntity = CreatePed(4, pedModel, 
        Config.PedLocation.coords.x, 
        Config.PedLocation.coords.y, 
        Config.PedLocation.coords.z - 1.0, 
        Config.PedLocation.coords.w, false, true)
    
    SetEntityAsMissionEntity(pedEntity, true, true)
    SetPedFleeAttributes(pedEntity, 0, 0)
    SetPedDiesWhenInjured(pedEntity, false)
    SetPedKeepTask(pedEntity, true)
    SetBlockingOfNonTemporaryEvents(pedEntity, true)
    SetEntityInvincible(pedEntity, true)
    _FreezeEntityPosition(pedEntity, true)
    
    if Config.PedLocation.scenario then
        TaskStartScenarioInPlace(pedEntity, Config.PedLocation.scenario, 0, true)
    end
    
    pedSpawned = true
    pedCoords = vector3(Config.PedLocation.coords.x, Config.PedLocation.coords.y, Config.PedLocation.coords.z)
    
    DebugSuccess('PED spawné avec succès')
end

CreateThread(function()
    SpawnPed()
end)

DebugSuccess('Initialisation terminée (VERSION 4.11.0 - Système Anti-Arme-Manquante)')