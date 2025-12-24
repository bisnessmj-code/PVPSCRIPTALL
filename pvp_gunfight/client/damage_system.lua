-- ========================================
-- PVP GUNFIGHT - SYSTÈME DE DÉGÂTS UNIFIÉ
-- Version 2.3.0 - HEADSHOT ONE-SHOT GARANTI
-- ========================================
-- ✅ UN SEUL handler gameEventTriggered
-- ✅ Tracking multi-niveaux robuste
-- ✅ Anti-friendly fire
-- ✅ Headshot one-shot GARANTI (amélioration)
-- ✅ Détection multi-bone pour la tête
-- ✅ Kill instantané avec protection anti-restauration
-- ✅ Désactivation casques renforcée
-- ✅ SANS système d'armure
-- ========================================

DebugClient('Module Damage System chargé (UNIFIÉ v2.3.0 - Headshot Garanti)')

-- ========================================
-- CACHE DES NATIVES
-- ========================================
local _PlayerPedId = PlayerPedId
local _SetWeaponDamageModifier = SetWeaponDamageModifier
local _SetWeaponDamageModifierThisFrame = SetWeaponDamageModifierThisFrame
local _GetHashKey = GetHashKey
local _Wait = Wait
local _NetworkGetPlayerIndexFromPed = NetworkGetPlayerIndexFromPed
local _GetPlayerServerId = GetPlayerServerId
local _GetEntityHealth = GetEntityHealth
local _SetEntityHealth = SetEntityHealth
local _GetGameTimer = GetGameTimer
local _GetPlayerPed = GetPlayerPed
local _GetPlayerFromServerId = GetPlayerFromServerId
local _NetworkIsPlayerActive = NetworkIsPlayerActive
local _DoesEntityExist = DoesEntityExist
local _IsPedAPlayer = IsPedAPlayer
local _GetPedSourceOfDeath = GetPedSourceOfDeath
local _GetPedCauseOfDeath = GetPedCauseOfDeath
local _SetPedHelmet = SetPedHelmet
local _SetPedCanLosePropsOnDamage = SetPedCanLosePropsOnDamage
local _SetPedConfigFlag = SetPedConfigFlag
local _GetPedLastDamageBone = GetPedLastDamageBone
local _IsEntityDead = IsEntityDead

-- ========================================
-- CONFIGURATION AMÉLIORÉE
-- ========================================
local DAMAGE_CONFIG = {
    -- Dégâts normaux
    baseDamageMultiplier = 1.0,
    
    -- Armes PVP
    weapons = {
        [GetHashKey('WEAPON_PISTOL50')] = 1.0,
        [GetHashKey('WEAPON_COMBATPISTOL')] = 1.0,
        [GetHashKey('WEAPON_APPISTOL')] = 1.0,
        [GetHashKey('WEAPON_PISTOL')] = 1.0,
        [GetHashKey('WEAPON_HEAVYPISTOL')] = 1.0,
    },
    
    -- 🆕 HEADSHOT CONFIG AMÉLIORÉE
    headshotEnabled = true,
    headshotInstantKill = true,
    
    -- 🆕 MULTIPLE BONE IDs POUR LA TÊTE (pour être sûr)
    headshotBones = {
        31086,  -- SKEL_Head (principal)
        39317,  -- SKEL_Neck_1
        0x796E, -- IK_Head (format hex)
        12844,  -- BONETAG_HEAD
    },
}

-- 🆕 ÉTAT ANTI-RESTAURATION HEADSHOT
local headshotKillInProgress = false
local lastHeadshotTime = 0

-- ========================================
-- SYSTÈME DE TRACKING MULTI-NIVEAUX
-- ========================================
local recentDamageHistory = {}
local MAX_DAMAGE_HISTORY = 50
local DAMAGE_HISTORY_TIMEOUT = 3000

local lastKnownAttacker = nil
local lastKnownWeapon = nil
local lastAttackerTime = 0

local teammateServerIds = {}
local damageSystemActive = false
local lastHealthCheck = {health = 200, time = 0}

-- ========================================
-- 🆕 FONCTION AMÉLIORÉE: VÉRIFIER SI BONE EST TÊTE
-- ========================================
local function IsHeadshotBone(bone)
    if not bone then return false end
    
    for i = 1, #DAMAGE_CONFIG.headshotBones do
        if bone == DAMAGE_CONFIG.headshotBones[i] then
            return true
        end
    end
    
    return false
end

-- ========================================
-- 🆕 FONCTION: KILL INSTANTANÉ GARANTI
-- ========================================
local function ForceInstantKill(ped, reason)
    headshotKillInProgress = true
    lastHeadshotTime = _GetGameTimer()
    
    DebugClient('[HEADSHOT] 💀 KILL INSTANTANÉ FORCÉ - Raison: %s', reason)
    
    -- Multi-étapes pour garantir la mort
    _SetEntityHealth(ped, 0)
    Wait(0)
    _SetEntityHealth(ped, 0)
    Wait(50)
    
    -- Vérifier si vraiment mort
    if not _IsEntityDead(ped) then
        DebugWarn('[HEADSHOT] ⚠️ PED encore vivant - Force kill #2')
        _SetEntityHealth(ped, 0)
        Wait(0)
        _SetEntityHealth(ped, 0)
    end
    
    -- Laisser 500ms avant de réactiver la restauration
    CreateThread(function()
        Wait(500)
        headshotKillInProgress = false
        DebugClient('[HEADSHOT] ✅ Protection kill désactivée')
    end)
end

-- ========================================
-- FONCTION: DÉSACTIVER PROTECTION CASQUES
-- ========================================
local function DisableHelmetProtection(ped)
    _SetPedHelmet(ped, false)
    _SetPedCanLosePropsOnDamage(ped, false, 0)
    _SetPedConfigFlag(ped, 438, true) -- CPED_CONFIG_FLAG_DisableHelmetArmor
    
    DebugClient('🎩 Protection casque DÉSACTIVÉE pour ped %d', ped)
end

local function EnableHelmetProtection(ped)
    _SetPedHelmet(ped, true)
    _SetPedCanLosePropsOnDamage(ped, true, 0)
    _SetPedConfigFlag(ped, 438, false)
    
    DebugClient('🎩 Protection casque RÉACTIVÉE pour ped %d', ped)
end

-- ========================================
-- FONCTION: ENREGISTRER DÉGÂT
-- ========================================
local function RecordDamage(attacker, weapon)
    if not attacker or attacker == 0 or attacker == -1 then return end
    if not _DoesEntityExist(attacker) then return end
    if not _IsPedAPlayer(attacker) then return end
    
    local currentTime = _GetGameTimer()
    
    table.insert(recentDamageHistory, 1, {
        attacker = attacker,
        weapon = weapon,
        time = currentTime
    })
    
    if #recentDamageHistory > MAX_DAMAGE_HISTORY then
        table.remove(recentDamageHistory)
    end
    
    lastKnownAttacker = attacker
    lastKnownWeapon = weapon
    lastAttackerTime = currentTime
    
    DebugClient('[TRACKING] Dégât enregistré - Attacker: %d | Weapon: %d | Time: %d', 
        attacker, weapon or 0, currentTime)
end

-- ========================================
-- FONCTION: NETTOYER L'HISTORIQUE
-- ========================================
local function CleanupHistory()
    local currentTime = _GetGameTimer()
    local i = #recentDamageHistory
    
    while i > 0 do
        if (currentTime - recentDamageHistory[i].time) > DAMAGE_HISTORY_TIMEOUT then
            table.remove(recentDamageHistory, i)
        end
        i = i - 1
    end
end

-- ========================================
-- FONCTION: RÉCUPÉRER LE MEILLEUR ATTAQUANT
-- ========================================
local function GetBestAttacker(eventAttacker, eventWeapon)
    local currentTime = _GetGameTimer()
    
    -- PRIORITÉ 1: Attaquant direct de l'event
    if eventAttacker and eventAttacker ~= -1 and _DoesEntityExist(eventAttacker) and _IsPedAPlayer(eventAttacker) then
        DebugClient('[ATTACKER] Priorité 1 (event direct)')
        return eventAttacker, eventWeapon
    end
    
    -- PRIORITÉ 2: Cache récent (< 1 seconde)
    if lastKnownAttacker and (currentTime - lastAttackerTime) < 1000 then
        if _DoesEntityExist(lastKnownAttacker) and _IsPedAPlayer(lastKnownAttacker) then
            DebugClient('[ATTACKER] Priorité 2 (cache < 1s)')
            return lastKnownAttacker, lastKnownWeapon
        end
    end
    
    -- PRIORITÉ 3: Historique (< 3 secondes)
    for i = 1, #recentDamageHistory do
        local record = recentDamageHistory[i]
        if (currentTime - record.time) < DAMAGE_HISTORY_TIMEOUT then
            if _DoesEntityExist(record.attacker) and _IsPedAPlayer(record.attacker) then
                DebugClient('[ATTACKER] Priorité 3 (historique, entrée %d)', i)
                return record.attacker, record.weapon
            end
        end
    end
    
    DebugClient('[ATTACKER] ❌ Aucun attaquant trouvé')
    return nil, nil
end

-- ========================================
-- FONCTION: VÉRIFIER SI COÉQUIPIER
-- ========================================
local function IsTeammatePed(ped)
    if not ped or not _DoesEntityExist(ped) or not _IsPedAPlayer(ped) then
        return false
    end
    
    local playerIndex = _NetworkGetPlayerIndexFromPed(ped)
    if not playerIndex or playerIndex == -1 then
        return false
    end
    
    local serverId = _GetPlayerServerId(playerIndex)
    if not serverId or serverId <= 0 then
        return false
    end
    
    return teammateServerIds[serverId] == true
end

-- ========================================
-- FONCTION: METTRE À JOUR LISTE COÉQUIPIERS
-- ========================================
local function UpdateTeammateServerIds()
    teammateServerIds = {}
    
    local teammates = GetTeammates()
    if not teammates or #teammates == 0 then
        return
    end
    
    for i = 1, #teammates do
        local teammateServerId = teammates[i]
        teammateServerIds[teammateServerId] = true
        DebugClient('[TEAM] Coéquipier enregistré: ServerId %d', teammateServerId)
    end
    
    DebugClient('[TEAM] Total coéquipiers: %d', #teammates)
end

-- ========================================
-- THREAD: SURVEILLANCE CONTINUE DES DÉGÂTS
-- ========================================
CreateThread(function()
    DebugSuccess('Thread surveillance dégâts démarré (CRITIQUE)')
    
    while true do
        if not IsInMatch() or not damageSystemActive then
            _Wait(500)
        else
            _Wait(0)
            
            local ped = _PlayerPedId()
            
            if HasEntityBeenDamagedByAnyPed(ped) then
                local attacker = _GetPedSourceOfDeath(ped)
                local weapon = _GetPedCauseOfDeath(ped)
                
                RecordDamage(attacker, weapon)
                ClearEntityLastDamageEntity(ped)
            end
        end
    end
end)

-- ========================================
-- THREAD: NETTOYAGE PÉRIODIQUE HISTORIQUE
-- ========================================
CreateThread(function()
    while true do
        _Wait(1000)
        CleanupHistory()
    end
end)

-- ========================================
-- THREAD: MISE À JOUR LISTE COÉQUIPIERS
-- ========================================
CreateThread(function()
    DebugSuccess('Thread mise à jour coéquipiers démarré')
    
    while true do
        if not IsInMatch() then
            _Wait(2000)
            teammateServerIds = {}
        else
            _Wait(1000)
            UpdateTeammateServerIds()
        end
    end
end)

-- ========================================
-- THREAD: DÉSACTIVATION CONTINUE DES CASQUES
-- ========================================
CreateThread(function()
    DebugSuccess('Thread désactivation casques démarré')
    
    while true do
        if not IsInMatch() or not damageSystemActive then
            _Wait(1000)
        else
            _Wait(500)
            
            local ped = _PlayerPedId()
            _SetPedConfigFlag(ped, 438, true)
            _SetPedHelmet(ped, false)
        end
    end
end)

-- ========================================
-- 🔧 EVENT AMÉLIORÉ: DÉTECTION HEADSHOT + DÉGÂTS
-- ========================================
AddEventHandler('gameEventTriggered', function(eventName, eventData)
    if eventName ~= 'CEventNetworkEntityDamage' then return end
    if not IsInMatch() then return end
    
    local victim = eventData[1]
    local attacker = eventData[2]
    local weaponUsed = eventData[7]
    local bone = eventData[3]
    local isDead = eventData[4] == 1
    
    -- Seulement si c'est nous la victime
    if victim ~= _PlayerPedId() then return end
    
    DebugClient('[EVENT] Dégât reçu - Attacker: %d | Bone: %d | Weapon: %d | Dead: %s', 
        attacker or -1, bone or -1, weaponUsed or -1, tostring(isDead))
    
    -- Enregistrer dans l'historique
    if attacker and attacker ~= -1 then
        RecordDamage(attacker, weaponUsed)
    end
    
    -- ========================================
    -- 🆕 VÉRIFICATION HEADSHOT AMÉLIORÉE
    -- ========================================
    local isHeadshot = IsHeadshotBone(bone)
    
    -- 🆕 DOUBLE-CHECK avec GetPedLastDamageBone
    if not isHeadshot then
        local lastBone = _GetPedLastDamageBone(victim)
        if IsHeadshotBone(lastBone) then
            isHeadshot = true
            DebugClient('[HEADSHOT] 🎯 Détecté via GetPedLastDamageBone: %d', lastBone)
        end
    end
    
    if isHeadshot and DAMAGE_CONFIG.headshotEnabled then
        DebugClient('[HEADSHOT] 💀 HEADSHOT DÉTECTÉ! (Bone: %d)', bone or -1)
        
        -- Récupérer le MEILLEUR attaquant possible
        local finalAttacker, finalWeapon = GetBestAttacker(attacker, weaponUsed)
        
        if not finalAttacker then
            DebugClient('[HEADSHOT] ❌ Aucun attaquant valide - HEADSHOT ANNULÉ')
            return
        end
        
        -- Vérifier si c'est un coéquipier
        local isTeammate = IsTeammatePed(finalAttacker)
        
        if isTeammate then
            DebugClient('[HEADSHOT] 🛡️ Headshot COÉQUIPIER - BLOQUÉ')
            
            local ped = _PlayerPedId()
            local currentHealth = _GetEntityHealth(ped)
            
            if currentHealth <= 100 or isDead then
                _SetEntityHealth(ped, lastHealthCheck.health or 150)
                DebugSuccess('[HEADSHOT] 🛡️ Santé restaurée (team kill bloqué)')
            end
            
            return
        end
        
        -- Convertir PED -> ServerID
        local attackerPlayerIndex = _NetworkGetPlayerIndexFromPed(finalAttacker)
        local attackerServerId = nil
        
        if attackerPlayerIndex and attackerPlayerIndex ~= -1 then
            attackerServerId = _GetPlayerServerId(attackerPlayerIndex)
        end
        
        DebugClient('[HEADSHOT] ✅ ATTAQUANT CONFIRMÉ')
        DebugClient('[HEADSHOT]    Entity: %d', finalAttacker)
        DebugClient('[HEADSHOT]    ServerId: %s', attackerServerId or 'nil')
        DebugClient('[HEADSHOT]    Weapon: %d', finalWeapon or 0)
        
        -- ========================================
        -- 🆕 KILL INSTANTANÉ GARANTI
        -- ========================================
        if DAMAGE_CONFIG.headshotInstantKill then
            local ped = _PlayerPedId()
            ForceInstantKill(ped, 'HEADSHOT')
        end
        
        -- Notifier le serveur
        if attackerServerId then
            TriggerServerEvent('pvp:playerDied', attackerServerId)
            DebugClient('[HEADSHOT] 📤 Notification serveur - Killer: %d', attackerServerId)
        end
    end
end)

-- ========================================
-- 🔧 THREAD MODIFIÉ: SURVEILLANCE DÉGÂTS (AVEC PROTECTION HEADSHOT)
-- ========================================
CreateThread(function()
    DebugSuccess('Thread restauration dégâts équipe démarré (AVEC PROTECTION HEADSHOT)')
    
    while true do
        if not IsInMatch() or not damageSystemActive then
            _Wait(500)
        else
            _Wait(0)
            
            -- 🆕 NE PAS RESTAURER SI HEADSHOT KILL EN COURS
            if headshotKillInProgress then
                local timeSinceHeadshot = _GetGameTimer() - lastHeadshotTime
                if timeSinceHeadshot < 1000 then
                    -- Skip complètement pendant 1 seconde après un headshot
                    goto continue
                end
            end
            
            local ped = _PlayerPedId()
            local currentHealth = _GetEntityHealth(ped)
            local currentTime = _GetGameTimer()
            
            -- Détecter baisse de vie
            local healthLost = lastHealthCheck.health - currentHealth
            
            if healthLost > 0 then
                local shouldRestore = false
                local attacker = lastKnownAttacker
                
                -- Vérifier si l'attaquant récent est un coéquipier
                if attacker and _DoesEntityExist(attacker) and (currentTime - lastAttackerTime) < 200 then
                    local isTeammate = IsTeammatePed(attacker)
                    
                    if isTeammate then
                        shouldRestore = true
                        DebugClient('[DAMAGE] 🛡️ TEAM DAMAGE - Restauration HP: +%d', healthLost)
                    else
                        DebugClient('[DAMAGE] ⚔️ ENEMY DAMAGE - HP: -%d', healthLost)
                    end
                end
                
                if shouldRestore then
                    _SetEntityHealth(ped, lastHealthCheck.health)
                    
                    lastHealthCheck = {
                        health = _GetEntityHealth(ped),
                        time = currentTime
                    }
                else
                    lastHealthCheck = {
                        health = currentHealth,
                        time = currentTime
                    }
                end
            else
                if currentTime - lastHealthCheck.time > 200 then
                    lastHealthCheck = {
                        health = currentHealth,
                        time = currentTime
                    }
                end
            end
            
            ::continue::
        end
    end
end)

-- ========================================
-- ACTIVATION/DÉSACTIVATION
-- ========================================
local function EnableDamageSystem()
    if damageSystemActive then return end
    
    damageSystemActive = true
    headshotKillInProgress = false
    lastHeadshotTime = 0
    
    DebugSuccess('🔫 Système de dégâts UNIFIÉ ACTIVÉ (VERSION AMÉLIORÉE)')
    
    for weaponHash, multiplier in pairs(DAMAGE_CONFIG.weapons) do
        _SetWeaponDamageModifier(weaponHash, multiplier)
    end
    
    local ped = _PlayerPedId()
    DisableHelmetProtection(ped)
    
    lastHealthCheck = {
        health = _GetEntityHealth(ped),
        time = _GetGameTimer()
    }
    
    recentDamageHistory = {}
    lastKnownAttacker = nil
    lastKnownWeapon = nil
    lastAttackerTime = 0
    
    _Wait(200)
    UpdateTeammateServerIds()
end

local function DisableDamageSystem()
    if not damageSystemActive then return end
    
    damageSystemActive = false
    headshotKillInProgress = false
    lastHeadshotTime = 0
    
    DebugClient('🔫 Système de dégâts DÉSACTIVÉ')
    
    for weaponHash, _ in pairs(DAMAGE_CONFIG.weapons) do
        _SetWeaponDamageModifier(weaponHash, 1.0)
    end
    
    local ped = _PlayerPedId()
    EnableHelmetProtection(ped)
    
    recentDamageHistory = {}
    teammateServerIds = {}
    lastKnownAttacker = nil
    lastKnownWeapon = nil
    lastAttackerTime = 0
end

-- ========================================
-- THREAD: ACTIVATION AUTOMATIQUE EN MATCH
-- ========================================
CreateThread(function()
    while true do
        if IsInMatch() then
            if not damageSystemActive then
                EnableDamageSystem()
            end
            _Wait(1000)
        else
            if damageSystemActive then
                DisableDamageSystem()
            end
            _Wait(2000)
        end
    end
end)

-- ========================================
-- THREAD: MULTIPLICATEUR DYNAMIQUE (FRAME)
-- ========================================
CreateThread(function()
    while true do
        if not damageSystemActive then
            _Wait(1000)
        else
            _Wait(0)
            
            for weaponHash, multiplier in pairs(DAMAGE_CONFIG.weapons) do
                _SetWeaponDamageModifierThisFrame(weaponHash, multiplier)
            end
        end
    end
end)

-- ========================================
-- EVENT: MISE À JOUR COÉQUIPIERS
-- ========================================
RegisterNetEvent('pvp:setTeammates', function(teammateIds)
    DebugClient('[TEAM] 📡 Event setTeammates reçu: %s', json.encode(teammateIds))
    
    _Wait(500)
    UpdateTeammateServerIds()
    
    DebugClient('[TEAM] 📊 Liste finale des coéquipiers:')
    for serverId, _ in pairs(teammateServerIds) do
        DebugClient('[TEAM]   - ServerId: %d', serverId)
    end
end)

-- ========================================
-- EVENTS
-- ========================================
RegisterNetEvent('pvp:enableDamageSystem', function()
    EnableDamageSystem()
end)

RegisterNetEvent('pvp:disableDamageSystem', function()
    DisableDamageSystem()
end)

-- ========================================
-- COMMANDES DEBUG
-- ========================================
RegisterCommand('hsdebug', function()
    DAMAGE_CONFIG.debug = not DAMAGE_CONFIG.debug
    print(string.format('^5[DAMAGE]^7 Debug: %s', tostring(DAMAGE_CONFIG.debug)))
end, false)

RegisterCommand('hsinfo', function()
    print('^5[DAMAGE]^7 === INFORMATIONS SYSTÈME UNIFIÉ (VERSION AMÉLIORÉE) ===')
    print(string.format('Actif: %s', tostring(damageSystemActive)))
    print(string.format('Headshots: %s', tostring(DAMAGE_CONFIG.headshotEnabled)))
    print(string.format('Instant Kill: %s', tostring(DAMAGE_CONFIG.headshotInstantKill)))
    print(string.format('Historique: %d entrées', #recentDamageHistory))
    print(string.format('Cache attacker: %s', lastKnownAttacker and 'Actif' or 'Vide'))
    print(string.format('Coéquipiers: %d', CountTableKeys(teammateServerIds)))
    print(string.format('Headshot kill actif: %s', tostring(headshotKillInProgress)))
    print('^5[CASQUES]^7 Protection désactivée: ' .. (damageSystemActive and 'OUI' or 'NON'))
    print('^5[ARMURE]^7 Système désactivé: OUI')
    print('^5[BONES TÊTE]^7 ' .. #DAMAGE_CONFIG.headshotBones .. ' bones détectés')
end, false)

RegisterCommand('hsclear', function()
    recentDamageHistory = {}
    lastKnownAttacker = nil
    lastKnownWeapon = nil
    lastAttackerTime = 0
    headshotKillInProgress = false
    lastHeadshotTime = 0
    print('^5[DAMAGE]^7 Historique et états effacés')
end, false)

RegisterCommand('hstest', function()
    local ped = _PlayerPedId()
    print('^5[HEADSHOT TEST]^7 Simulation headshot...')
    ForceInstantKill(ped, 'TEST COMMANDE')
end, false)

-- Fonction utilitaire
function CountTableKeys(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

-- ========================================
-- EXPORTS
-- ========================================
exports('EnableDamageSystem', EnableDamageSystem)
exports('DisableDamageSystem', DisableDamageSystem)

DebugSuccess('Module Damage System UNIFIÉ initialisé (VERSION 2.3.0 - HEADSHOT GARANTI)')
DebugSuccess('✅ Headshot one-shot: GARANTI')
DebugSuccess('✅ Multi-bone detection: ACTIF')
DebugSuccess('✅ Protection anti-restauration: ACTIF')
DebugSuccess('✅ Tracking multi-niveaux: ACTIF')
DebugSuccess('✅ Anti-friendly fire: ACTIF')
DebugSuccess('✅ Protection casques: DÉSACTIVÉE')
DebugSuccess('✅ Système d\'armure: DÉSACTIVÉ')
