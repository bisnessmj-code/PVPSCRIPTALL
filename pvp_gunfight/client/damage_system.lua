-- ========================================
-- PVP GUNFIGHT - SYSTÈME DE DÉGÂTS
-- Version 1.6.0 - FIX HEADSHOT TEAM KILL
-- ========================================

DebugClient('Module Damage System chargé')

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

-- ========================================
-- CONFIGURATION DÉGÂTS
-- ========================================
local DAMAGE_CONFIG = {
    baseDamageMultiplier = 1.0,
    
    weapons = {
        [GetHashKey('WEAPON_PISTOL50')] = 1.0,
        [GetHashKey('WEAPON_COMBATPISTOL')] = 1.0,
        [GetHashKey('WEAPON_APPISTOL')] = 1.0,
        [GetHashKey('WEAPON_PISTOL')] = 1.0,
        [GetHashKey('WEAPON_HEAVYPISTOL')] = 1.0,
    },
    
    headshotMultiplier = 1.0, 
}

-- ========================================
-- ÉTAT
-- ========================================
local damageSystemActive = false
local lastHealthCheck = {health = 200, armour = 100, time = 0}
local lastDamageAttacker = nil
local lastDamageTime = 0

-- 🔧 NOUVEAU: Blocage des headsots coéquipiers
local recentTeammateHeadshot = false
local recentTeammateHeadshotTime = 0

-- ========================================
-- 🔧 CACHE DES SERVER IDS COÉQUIPIERS
-- ========================================
local teammateServerIds = {}

-- ========================================
-- 🔧 FONCTION: METTRE À JOUR LA LISTE DES SERVER IDS COÉQUIPIERS
-- ========================================
local function UpdateTeammateServerIds()
    teammateServerIds = {}
    
    local teammates = GetTeammates()
    if not teammates or #teammates == 0 then
        DebugClient('🔍 Aucun coéquipier à enregistrer')
        return
    end
    
    for i = 1, #teammates do
        local teammateServerId = teammates[i]
        teammateServerIds[teammateServerId] = true
        DebugClient('✅ Coéquipier enregistré: ServerId %d', teammateServerId)
    end
    
    DebugClient('📋 Total coéquipiers: %d', #teammates)
end

-- ========================================
-- 🔧 FONCTION: VÉRIFIER SI UN PED EST UN COÉQUIPIER
-- ========================================
local function IsTeammatePed(ped)
    if not ped or not DoesEntityExist(ped) or not IsPedAPlayer(ped) then
        return false
    end
    
    -- Convertir PED -> ServerID
    local playerIndex = _NetworkGetPlayerIndexFromPed(ped)
    if not playerIndex or playerIndex == -1 then
        return false
    end
    
    local serverId = _GetPlayerServerId(playerIndex)
    if not serverId or serverId <= 0 then
        return false
    end
    
    -- Vérifier si ce serverId est dans la liste des coéquipiers
    local isTeammate = teammateServerIds[serverId] == true
    
    -- Debug
    if isTeammate then
        DebugClient('🛡️ PED %d (ServerId: %d) = COÉQUIPIER', ped, serverId)
    else
        DebugClient('⚔️ PED %d (ServerId: %d) = ENNEMI', ped, serverId)
    end
    
    return isTeammate
end

-- ========================================
-- 🔧 THREAD: SURVEILLANCE DÉGÂTS + RESTAURATION
-- ========================================
CreateThread(function()
    DebugSuccess('Thread surveillance dégâts démarré')
    
    while true do
        if not IsInMatch() or not damageSystemActive then
            _Wait(500)
            lastDamageAttacker = nil
            lastDamageTime = 0
            recentTeammateHeadshot = false
        else
            _Wait(0) -- CHAQUE FRAME
            
            local ped = _PlayerPedId()
            local currentHealth = _GetEntityHealth(ped)
            local currentArmour = _GetPedArmour(ped)
            local currentTime = _GetGameTimer()
            
            -- 🔧 NOUVEAU: Vérifier si on vient de subir un headshot coéquipier
            if recentTeammateHeadshot and (currentTime - recentTeammateHeadshotTime) < 100 then
                -- Ressusciter immédiatement si tué par headshot coéquipier
                if _GetEntityHealth(ped) <= 0 or currentHealth <= 0 then
                    DebugClient('🛡️ RESSUSCITATION HEADSHOT COÉQUIPIER!')
                    NetworkResurrectLocalPlayer(
                        GetEntityCoords(ped).x,
                        GetEntityCoords(ped).y,
                        GetEntityCoords(ped).z,
                        GetEntityHeading(ped),
                        false,
                        false
                    )
                    
                    Wait(50)
                    local newPed = _PlayerPedId()
                    _SetEntityHealth(newPed, lastHealthCheck.health or 150)
                    _SetPedArmour(newPed, lastHealthCheck.armour or 100)
                    
                    -- Reset flag
                    recentTeammateHeadshot = false
                end
            end
            
            -- Détecter baisse de vie ou armure
            local healthLost = lastHealthCheck.health - currentHealth
            local armourLost = lastHealthCheck.armour - currentArmour
            
            if (healthLost > 0 or armourLost > 0) then
                -- Dégâts détectés !
                local shouldRestore = false
                local attacker = lastDamageAttacker
                
                -- Vérifier si l'attaquant récent est un coéquipier
                if attacker and DoesEntityExist(attacker) and (currentTime - lastDamageTime) < 200 then
                    local isTeammate = IsTeammatePed(attacker)
                    
                    if isTeammate then
                        shouldRestore = true
                        DebugClient('🛡️ TEAM DAMAGE - Restauration HP: +%d | Armure: +%d', healthLost, armourLost)
                    else
                        DebugClient('⚔️ ENEMY DAMAGE - HP: -%d | Armure: -%d', healthLost, armourLost)
                    end
                else
                    DebugClient('❓ UNKNOWN DAMAGE - HP: -%d | Armure: -%d', healthLost, armourLost)
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
                    -- Dégâts acceptés (ennemi ou inconnu)
                    lastHealthCheck = {
                        health = currentHealth,
                        armour = currentArmour,
                        time = currentTime
                    }
                end
                
                -- Reset attacker après traitement
                lastDamageAttacker = nil
                lastDamageTime = 0
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
-- 🔧 THREAD: MISE À JOUR LISTE COÉQUIPIERS
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
-- ACTIVATION/DÉSACTIVATION
-- ========================================
local function EnableDamageSystem()
    if damageSystemActive then return end
    
    damageSystemActive = true
    DebugSuccess('🔫 Système de dégâts PVP ACTIVÉ')
    
    for weaponHash, multiplier in pairs(DAMAGE_CONFIG.weapons) do
        _SetWeaponDamageModifier(weaponHash, multiplier)
    end
    
    -- Réinitialiser le suivi
    local ped = _PlayerPedId()
    lastHealthCheck = {
        health = _GetEntityHealth(ped),
        armour = _GetPedArmour(ped),
        time = _GetGameTimer()
    }
    
    lastDamageAttacker = nil
    lastDamageTime = 0
    recentTeammateHeadshot = false
    
    -- Mettre à jour la liste des coéquipiers
    Wait(200)
    UpdateTeammateServerIds()
end

local function DisableDamageSystem()
    if not damageSystemActive then return end
    
    damageSystemActive = false
    DebugClient('🔫 Système de dégâts PVP DÉSACTIVÉ')
    
    for weaponHash, _ in pairs(DAMAGE_CONFIG.weapons) do
        _SetWeaponDamageModifier(weaponHash, 1.0)
    end
    
    teammateServerIds = {}
    lastDamageAttacker = nil
    lastDamageTime = 0
    recentTeammateHeadshot = false
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
-- 🔧 SYSTÈME HEADSHOT - BLOCAGE TOTAL TEAM KILL
-- ========================================
AddEventHandler('gameEventTriggered', function(eventName, eventData)
    if eventName ~= 'CEventNetworkEntityDamage' then return end
    if not IsInMatch() then return end
    
    local victim = eventData[1]
    local attacker = eventData[2]
    local isDead = eventData[4] == 1
    local weaponHash = eventData[7]
    local boneIndex = eventData[3]
    
    if victim ~= _PlayerPedId() then return end
    
    -- Vérifier si c'est un headshot
    local isHeadshot = (boneIndex == 31086 or boneIndex == 39317)
    
    -- Enregistrer l'attaquant
    if attacker and IsEntityAPed(attacker) and IsPedAPlayer(attacker) and DoesEntityExist(attacker) then
        lastDamageAttacker = attacker
        lastDamageTime = _GetGameTimer()
        
        -- Vérifier si c'est un coéquipier
        local isTeammate = IsTeammatePed(attacker)
        
        if isTeammate then
            DebugClient('🛡️ Event: Attaque coéquipier détectée')
            
            -- 🔧 NOUVEAU: BLOQUER COMPLÈTEMENT LES HEADSOTS COÉQUIPIERS
            if isHeadshot then
                DebugClient('🛡️🚫 HEADSHOT COÉQUIPIER - BLOCAGE TOTAL!')
                
                -- Marquer qu'on vient de subir un headshot coéquipier
                recentTeammateHeadshot = true
                recentTeammateHeadshotTime = _GetGameTimer()
                
                -- Empêcher la mort immédiate
                local ped = _PlayerPedId()
                local currentHealth = _GetEntityHealth(ped)
                
                if currentHealth <= 100 or isDead then
                    -- Restaurer la santé IMMÉDIATEMENT
                    _SetEntityHealth(ped, lastHealthCheck.health or 150)
                    DebugSuccess('🛡️ Santé restaurée après headshot coéquipier')
                end
                
                -- Ne PAS traiter ce headshot comme létal
                return
            end
            
            return -- Ne pas traiter les dégâts de coéquipier
        else
            DebugClient('⚔️ Event: Attaque ENNEMIE détectée')
        end
    else
        lastDamageAttacker = nil
    end
    
    -- Si ce n'est PAS un coéquipier, traiter normalement
    if not attacker or not IsEntityAPed(attacker) or not IsPedAPlayer(attacker) then
        return
    end
    
    -- Vérifier si c'est une arme PVP
    local isPvpWeapon = false
    for wpnHash, _ in pairs(DAMAGE_CONFIG.weapons) do
        if weaponHash == wpnHash then
            isPvpWeapon = true
            break
        end
    end
    
    if not isPvpWeapon then return end
    
    -- 🔧 MODIFIÉ: Headshot létal UNIQUEMENT pour les ENNEMIS
    if isHeadshot and not isDead then
        -- Double vérification que ce n'est PAS un coéquipier
        local isTeammateCheck = IsTeammatePed(attacker)
        
        if not isTeammateCheck then
            DebugClient('💀 HEADSHOT LÉTAL détecté (ennemi confirmé)!')
            
            SetEntityHealth(_PlayerPedId(), 0)
            
            local attackerServerId = _GetPlayerServerId(_NetworkGetPlayerIndexFromPed(attacker))
            TriggerServerEvent('pvp:playerDied', attackerServerId)
        else
            DebugClient('🛡️ HEADSHOT COÉQUIPIER - Ignoré')
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
            local armour = GetPedArmour(ped)
            
            if armour > 100 then
                SetPedArmour(ped, 100)
            end
        end
    end
end)

-- ========================================
-- 🔧 EVENT: MISE À JOUR COÉQUIPIERS
-- ========================================
RegisterNetEvent('pvp:setTeammates', function(teammateIds)
    DebugClient('📡 Event setTeammates reçu: %s', json.encode(teammateIds))
    
    -- Attendre que les joueurs soient chargés
    Wait(500)
    
    -- Forcer la mise à jour immédiate
    UpdateTeammateServerIds()
    
    -- Debug final
    DebugClient('📊 Liste finale des coéquipiers:')
    for serverId, _ in pairs(teammateServerIds) do
        DebugClient('  - ServerId: %d', serverId)
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
-- EXPORTS
-- ========================================
exports('EnableDamageSystem', EnableDamageSystem)
exports('DisableDamageSystem', DisableDamageSystem)

DebugSuccess('Module Damage System initialisé (VERSION 1.6.0 - FIX HEADSHOT TEAM KILL)')
