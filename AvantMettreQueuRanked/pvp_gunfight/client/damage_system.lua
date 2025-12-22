-- ========================================
-- PVP GUNFIGHT - SYSTÈME DE DÉGÂTS UNIFIÉ
-- Version 2.1.0 - DÉSACTIVATION CASQUES
-- ========================================
-- ✅ UN SEUL handler gameEventTriggered
-- ✅ Tracking multi-niveaux robuste (headshot_system)
-- ✅ Anti-friendly fire (damage_system)
-- ✅ Headshot one-shot kill garanti
-- ✅ AUCUN "Suicide" erroné
-- ✅ NOUVEAUTÉ: Désactivation protection casques
-- ========================================

DebugClient('Module Damage System chargé (UNIFIÉ v2.1.0 - Casques désactivés)')

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
local _GetPedArmour = GetPedArmour
local _SetPedArmour = SetPedArmour
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

-- ========================================
-- CONFIGURATION
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
    
    -- HEADSHOT CONFIG
    headshotEnabled = true,
    headshotBone = 31086, -- Bone de la tête
    headshotInstantKill = true, -- Mort instantanée
}

-- ========================================
-- SYSTÈME DE TRACKING MULTI-NIVEAUX
-- (inspiré de headshot_system pour robustesse)
-- ========================================
local recentDamageHistory = {}
local MAX_DAMAGE_HISTORY = 50 -- Limite FIFO
local DAMAGE_HISTORY_TIMEOUT = 3000 -- 3 secondes

local lastKnownAttacker = nil
local lastKnownWeapon = nil
local lastAttackerTime = 0

-- Cache coéquipiers
local teammateServerIds = {}

-- État système
local damageSystemActive = false
local lastHealthCheck = {health = 200, armour = 100, time = 0}

-- ========================================
-- 🆕 FONCTION: DÉSACTIVER PROTECTION CASQUES
-- ========================================
local function DisableHelmetProtection(ped)
    -- 1. Désactiver la capacité du casque à protéger
    _SetPedHelmet(ped, false)
    
    -- 2. Désactiver la perte de props (empêche le casque de tomber)
    _SetPedCanLosePropsOnDamage(ped, false, 0)
    
    -- 3. Flag CONFIG: Désactiver l'armure du casque (CRITICAL)
    _SetPedConfigFlag(ped, 438, true) -- CPED_CONFIG_FLAG_DisableHelmetArmor
    
    DebugClient('🎩 Protection casque DÉSACTIVÉE pour ped %d', ped)
end

-- ========================================
-- 🆕 FONCTION: RÉACTIVER PROTECTION CASQUES
-- ========================================
local function EnableHelmetProtection(ped)
    -- Réactiver la protection (état vanilla)
    _SetPedHelmet(ped, true)
    _SetPedCanLosePropsOnDamage(ped, true, 0)
    _SetPedConfigFlag(ped, 438, false) -- Réactiver armure casque
    
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
    
    -- Ajouter à l'historique (FIFO)
    table.insert(recentDamageHistory, 1, {
        attacker = attacker,
        weapon = weapon,
        time = currentTime
    })
    
    -- Limiter taille
    if #recentDamageHistory > MAX_DAMAGE_HISTORY then
        table.remove(recentDamageHistory)
    end
    
    -- Mettre à jour le cache rapide
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
-- (Système à 3 niveaux de priorité)
-- ========================================
local function GetBestAttacker(eventAttacker, eventWeapon)
    local currentTime = _GetGameTimer()
    
    -- PRIORITÉ 1: Attaquant direct de l'event (temps réel)
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
-- 🔧 THREAD: SURVEILLANCE CONTINUE DES DÉGÂTS
-- (Capture l'attaquant AVANT l'event gameEventTriggered)
-- ========================================
CreateThread(function()
    DebugSuccess('Thread surveillance dégâts démarré (CRITIQUE)')
    
    while true do
        if not IsInMatch() or not damageSystemActive then
            _Wait(500)
        else
            _Wait(0) -- CHAQUE FRAME en match
            
            local ped = _PlayerPedId()
            
            -- Vérifier si le joueur a reçu des dégâts
            if HasEntityBeenDamagedByAnyPed(ped) then
                local attacker = _GetPedSourceOfDeath(ped)
                local weapon = _GetPedCauseOfDeath(ped)
                
                -- ENREGISTRER dans l'historique
                RecordDamage(attacker, weapon)
                
                -- Nettoyer l'état
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
-- 🆕 THREAD: DÉSACTIVATION CONTINUE DES CASQUES
-- ========================================
CreateThread(function()
    DebugSuccess('Thread désactivation casques démarré')
    
    while true do
        if not IsInMatch() or not damageSystemActive then
            _Wait(1000)
        else
            _Wait(500) -- Vérifier toutes les 500ms
            
            local ped = _PlayerPedId()
            
            -- Forcer la désactivation (au cas où le jeu réactive)
            _SetPedConfigFlag(ped, 438, true)
            _SetPedHelmet(ped, false)
        end
    end
end)

-- ========================================
-- 🎯 EVENT UNIQUE: DÉTECTION HEADSHOT + DÉGÂTS
-- (UN SEUL HANDLER = PAS DE RACE CONDITION)
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
    
    -- Enregistrer dans l'historique (même si pas headshot)
    if attacker and attacker ~= -1 then
        RecordDamage(attacker, weaponUsed)
    end
    
    -- ========================================
    -- VÉRIFIER SI HEADSHOT
    -- ========================================
    local isHeadshot = (bone == DAMAGE_CONFIG.headshotBone)
    
    if isHeadshot and DAMAGE_CONFIG.headshotEnabled then
        DebugClient('[HEADSHOT] 💀 HEADSHOT DÉTECTÉ!')
        
        -- Récupérer le MEILLEUR attaquant possible (3 priorités)
        local finalAttacker, finalWeapon = GetBestAttacker(attacker, weaponUsed)
        
        if not finalAttacker then
            DebugClient('[HEADSHOT] ❌ Aucun attaquant valide - HEADSHOT ANNULÉ')
            return
        end
        
        -- Vérifier si c'est un coéquipier
        local isTeammate = IsTeammatePed(finalAttacker)
        
        if isTeammate then
            DebugClient('[HEADSHOT] 🛡️ Headshot COÉQUIPIER - BLOQUÉ')
            
            -- Restaurer la santé immédiatement
            local ped = _PlayerPedId()
            local currentHealth = _GetEntityHealth(ped)
            
            if currentHealth <= 100 or isDead then
                _SetEntityHealth(ped, lastHealthCheck.health or 150)
                DebugSuccess('[HEADSHOT] 🛡️ Santé restaurée (team kill bloqué)')
            end
            
            return -- Ne pas traiter ce headshot
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
        -- TUER INSTANTANÉMENT
        -- ========================================
        if DAMAGE_CONFIG.headshotInstantKill then
            local ped = _PlayerPedId()
            _SetPedArmour(ped, 0)
            _SetEntityHealth(ped, 0)
            
            DebugClient('[HEADSHOT] 💀 MORT INSTANTANÉE')
        end
        
        -- Notifier le serveur avec le BON tueur
        if attackerServerId then
            TriggerServerEvent('pvp:playerDied', attackerServerId)
            DebugClient('[HEADSHOT] 📤 Notification serveur - Killer: %d', attackerServerId)
        end
    end
end)

-- ========================================
-- THREAD: SURVEILLANCE DÉGÂTS + RESTAURATION
-- (pour les dégâts non-headshot d'équipe)
-- ========================================
CreateThread(function()
    DebugSuccess('Thread restauration dégâts équipe démarré')
    
    while true do
        if not IsInMatch() or not damageSystemActive then
            _Wait(500)
        else
            _Wait(0)
            
            local ped = _PlayerPedId()
            local currentHealth = _GetEntityHealth(ped)
            local currentArmour = _GetPedArmour(ped)
            local currentTime = _GetGameTimer()
            
            -- Détecter baisse de vie ou armure
            local healthLost = lastHealthCheck.health - currentHealth
            local armourLost = lastHealthCheck.armour - currentArmour
            
            if (healthLost > 0 or armourLost > 0) then
                local shouldRestore = false
                local attacker = lastKnownAttacker
                
                -- Vérifier si l'attaquant récent est un coéquipier
                if attacker and _DoesEntityExist(attacker) and (currentTime - lastAttackerTime) < 200 then
                    local isTeammate = IsTeammatePed(attacker)
                    
                    if isTeammate then
                        shouldRestore = true
                        DebugClient('[DAMAGE] 🛡️ TEAM DAMAGE - Restauration HP: +%d | Armure: +%d', healthLost, armourLost)
                    else
                        DebugClient('[DAMAGE] ⚔️ ENEMY DAMAGE - HP: -%d | Armure: -%d', healthLost, armourLost)
                    end
                end
                
                if shouldRestore then
                    -- RESTAURER IMMÉDIATEMENT
                    if healthLost > 0 then
                        _SetEntityHealth(ped, lastHealthCheck.health)
                    end
                    
                    if armourLost > 0 then
                        _SetPedArmour(ped, lastHealthCheck.armour)
                    end
                    
                    -- Mettre à jour immédiatement
                    lastHealthCheck = {
                        health = _GetEntityHealth(ped),
                        armour = _GetPedArmour(ped),
                        time = currentTime
                    }
                else
                    -- Dégâts acceptés (ennemi)
                    lastHealthCheck = {
                        health = currentHealth,
                        armour = currentArmour,
                        time = currentTime
                    }
                end
            else
                -- Pas de dégâts, mise à jour normale
                if currentTime - lastHealthCheck.time > 200 then
                    lastHealthCheck = {
                        health = currentHealth,
                        armour = currentArmour,
                        time = currentTime
                    }
                end
            end
        end
    end
end)

-- ========================================
-- ACTIVATION/DÉSACTIVATION
-- ========================================
local function EnableDamageSystem()
    if damageSystemActive then return end
    
    damageSystemActive = true
    DebugSuccess('🔫 Système de dégâts UNIFIÉ ACTIVÉ')
    
    for weaponHash, multiplier in pairs(DAMAGE_CONFIG.weapons) do
        _SetWeaponDamageModifier(weaponHash, multiplier)
    end
    
    -- 🆕 DÉSACTIVER LES CASQUES
    local ped = _PlayerPedId()
    DisableHelmetProtection(ped)
    
    -- Réinitialiser le suivi
    lastHealthCheck = {
        health = _GetEntityHealth(ped),
        armour = _GetPedArmour(ped),
        time = _GetGameTimer()
    }
    
    recentDamageHistory = {}
    lastKnownAttacker = nil
    lastKnownWeapon = nil
    lastAttackerTime = 0
    
    -- Mettre à jour la liste des coéquipiers
    _Wait(200)
    UpdateTeammateServerIds()
end

local function DisableDamageSystem()
    if not damageSystemActive then return end
    
    damageSystemActive = false
    DebugClient('🔫 Système de dégâts DÉSACTIVÉ')
    
    for weaponHash, _ in pairs(DAMAGE_CONFIG.weapons) do
        _SetWeaponDamageModifier(weaponHash, 1.0)
    end
    
    -- 🆕 RÉACTIVER LES CASQUES
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
-- GESTION ARMURE EN MATCH
-- ========================================
CreateThread(function()
    while true do
        if not IsInMatch() then
            _Wait(2000)
        else
            _Wait(500)
            
            local ped = _PlayerPedId()
            local armour = _GetPedArmour(ped)
            
            if armour > 100 then
                _SetPedArmour(ped, 100)
            end
        end
    end
end)

-- ========================================
-- EVENT: MISE À JOUR COÉQUIPIERS
-- ========================================
RegisterNetEvent('pvp:setTeammates', function(teammateIds)
    DebugClient('[TEAM] 📡 Event setTeammates reçu: %s', json.encode(teammateIds))
    
    -- Attendre que les joueurs soient chargés
    _Wait(500)
    
    -- Forcer la mise à jour immédiate
    UpdateTeammateServerIds()
    
    -- Debug final
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
    print('^5[DAMAGE]^7 === INFORMATIONS SYSTÈME UNIFIÉ ===')
    print(string.format('Actif: %s', tostring(damageSystemActive)))
    print(string.format('Headshots: %s', tostring(DAMAGE_CONFIG.headshotEnabled)))
    print(string.format('Instant Kill: %s', tostring(DAMAGE_CONFIG.headshotInstantKill)))
    print(string.format('Historique: %d entrées', #recentDamageHistory))
    print(string.format('Cache attacker: %s', lastKnownAttacker and 'Actif' or 'Vide'))
    print(string.format('Coéquipiers: %d', CountTableKeys(teammateServerIds)))
    print('^5[CASQUES]^7 Protection désactivée: ' .. (damageSystemActive and 'OUI' or 'NON'))
end, false)

RegisterCommand('hsclear', function()
    recentDamageHistory = {}
    lastKnownAttacker = nil
    lastKnownWeapon = nil
    lastAttackerTime = 0
    print('^5[DAMAGE]^7 Historique effacé')
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

DebugSuccess('Module Damage System UNIFIÉ initialisé (VERSION 2.1.0)')
DebugSuccess('✅ Headshot one-shot: ACTIF')
DebugSuccess('✅ Tracking multi-niveaux: ACTIF')
DebugSuccess('✅ Anti-friendly fire: ACTIF')
DebugSuccess('✅ Protection casques: DÉSACTIVÉE')
DebugSuccess('✅ Aucun "Suicide" erroné')
