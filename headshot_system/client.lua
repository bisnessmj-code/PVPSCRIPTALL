-- ========================================
-- HEADSHOT SYSTEM - ONESHOT KILL
-- Version 3.0.0 - Anti-Suicide Intelligent
-- ========================================

local Config = {
    HeadBone = 31086,
    Debug = false,
    DisableHelmet = true,
}

-- ========================================
-- CACHE NATIVES
-- ========================================
local _PlayerPedId = PlayerPedId
local _GetEntityHealth = GetEntityHealth
local _SetEntityHealth = SetEntityHealth
local _GetPedArmour = GetPedArmour
local _SetPedArmour = SetPedArmour
local _GetGameTimer = GetGameTimer
local _GetPedSourceOfDeath = GetPedSourceOfDeath
local _HasEntityBeenDamagedByAnyPed = HasEntityBeenDamedByAnyPed
local _DoesEntityExist = DoesEntityExist
local _IsPedAPlayer = IsPedAPlayer
local _NetworkGetPlayerIndexFromPed = NetworkGetPlayerIndexFromPed
local _GetPlayerServerId = GetPlayerServerId
local _GetPlayerPed = GetPlayerPed
local _GetPlayerFromServerId = GetPlayerFromServerId

-- ========================================
-- SYST�ME DE D�TECTION MULTI-NIVEAU
-- ========================================
local recentDamageHistory = {}
local MAX_DAMAGE_HISTORY = 100
local DAMAGE_HISTORY_TIMEOUT = 3000 -- 3 secondes

local lastKnownAttacker = nil
local lastKnownWeapon = nil
local lastAttackerTime = 0

-- ========================================
-- FONCTION: ENREGISTRER D�G�T
-- ========================================
local function RecordDamage(attacker, weapon)
    if not attacker or attacker == 0 or attacker == -1 then return end
    if not _DoesEntityExist(attacker) then return end
    if not _IsPedAPlayer(attacker) then return end
    
    local currentTime = _GetGameTimer()
    
    -- Ajouter � l'historique
    table.insert(recentDamageHistory, 1, {
        attacker = attacker,
        weapon = weapon,
        time = currentTime
    })
    
    -- Limiter taille historique
    if #recentDamageHistory > MAX_DAMAGE_HISTORY then
        table.remove(recentDamageHistory)
    end
    
    -- Mettre � jour le cache
    lastKnownAttacker = attacker
    lastKnownWeapon = weapon
    lastAttackerTime = currentTime
    
    if Config.Debug then
        print(string.format('[HEADSHOT] ?? D�g�t enregistr� - Attacker: %d | Weapon: %d | Time: %d', 
            attacker, weapon or 0, currentTime))
    end
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
-- FONCTION: R�CUP�RER LE MEILLEUR ATTAQUANT
-- ========================================
local function GetBestAttacker(eventAttacker, eventWeapon)
    local currentTime = _GetGameTimer()
    
    -- PRIORIT� 1: Attaquant direct de l'event
    if eventAttacker and eventAttacker ~= -1 and _DoesEntityExist(eventAttacker) and _IsPedAPlayer(eventAttacker) then
        if Config.Debug then
            print('[HEADSHOT] ? Attaquant priorit� 1 (event direct)')
        end
        return eventAttacker, eventWeapon
    end
    
    -- PRIORIT� 2: Cache r�cent (< 1 seconde)
    if lastKnownAttacker and (currentTime - lastAttackerTime) < 1000 then
        if _DoesEntityExist(lastKnownAttacker) and _IsPedAPlayer(lastKnownAttacker) then
            if Config.Debug then
                print('[HEADSHOT] ? Attaquant priorit� 2 (cache < 1s)')
            end
            return lastKnownAttacker, lastKnownWeapon
        end
    end
    
    -- PRIORIT� 3: Historique (< 3 secondes)
    for i = 1, #recentDamageHistory do
        local record = recentDamageHistory[i]
        if (currentTime - record.time) < DAMAGE_HISTORY_TIMEOUT then
            if _DoesEntityExist(record.attacker) and _IsPedAPlayer(record.attacker) then
                if Config.Debug then
                    print(string.format('[HEADSHOT] ? Attaquant priorit� 3 (historique, entr�e %d)', i))
                end
                return record.attacker, record.weapon
            end
        end
    end
    
    if Config.Debug then
        print('[HEADSHOT] ? Aucun attaquant trouv�')
    end
    
    return nil, nil
end

-- ========================================
-- THREAD: SURVEILLANCE CONTINUE DES D�G�TS
-- ========================================
CreateThread(function()
    while true do
        Wait(0) -- CRITIQUE: Surveiller chaque frame
        
        local ped = _PlayerPedId()
        
        if HasEntityBeenDamagedByAnyPed(ped) then
            local attacker = _GetPedSourceOfDeath(ped)
            local weapon = GetPedCauseOfDeath(ped)
            
            RecordDamage(attacker, weapon)
            ClearEntityLastDamageEntity(ped)
        end
    end
end)

-- ========================================
-- THREAD: NETTOYAGE P�RIODIQUE
-- ========================================
CreateThread(function()
    while true do
        Wait(1000)
        CleanupHistory()
    end
end)

-- ========================================
-- EVENT: D�TECTION HEADSHOT
-- ========================================
AddEventHandler('gameEventTriggered', function(eventName, eventData)
    if eventName ~= 'CEventNetworkEntityDamage' then return end
    
    local victim = eventData[1]
    local attacker = eventData[2]
    local weaponUsed = eventData[7]
    local bone = eventData[3]
    
    if victim ~= _PlayerPedId() then return end
    
    if Config.Debug then
        print(string.format('[HEADSHOT] ?? Event D�g�t - Attacker: %d | Bone: %d | Weapon: %d', 
            attacker or -1, bone or -1, weaponUsed or -1))
    end
    
    -- Enregistrer les d�g�ts dans l'historique
    if attacker and attacker ~= -1 then
        RecordDamage(attacker, weaponUsed)
    end
    
    -- V�rifier si c'est un headshot
    if bone == Config.HeadBone then
        if Config.Debug then
            print('[HEADSHOT] ?? HEADSHOT D�TECT�')
        end
        
        -- R�cup�rer le meilleur attaquant possible
        local finalAttacker, finalWeapon = GetBestAttacker(attacker, weaponUsed)
        
        if not finalAttacker then
            if Config.Debug then
                print('[HEADSHOT] ?? Aucun attaquant valide - HEADSHOT ANNUL�')
            end
            return
        end
        
        -- Convertir PED -> ServerID
        local attackerPlayerIndex = _NetworkGetPlayerIndexFromPed(finalAttacker)
        local attackerServerId = nil
        
        if attackerPlayerIndex and attackerPlayerIndex ~= -1 then
            attackerServerId = _GetPlayerServerId(attackerPlayerIndex)
        end
        
        if Config.Debug then
            print('[HEADSHOT] ? ATTAQUANT FINAL CONFIRM�')
            print(string.format('[HEADSHOT]    Entity: %d', finalAttacker))
            print(string.format('[HEADSHOT]    ServerId: %s', attackerServerId or 'nil'))
            print(string.format('[HEADSHOT]    Weapon: %d', finalWeapon or 0))
        end
        
        -- TUER IMM�DIATEMENT
        local ped = _PlayerPedId()
        _SetPedArmour(ped, 0)
        _SetEntityHealth(ped, 0)
        
        if Config.Debug then
            print('[HEADSHOT] ?? MORT PAR HEADSHOT')
        end
        
        -- Notifier le serveur
        if attackerServerId then
            TriggerServerEvent('pvp_gunfight:server:playerDied', attackerServerId, finalWeapon)
            
            if Config.Debug then
                print(string.format('[HEADSHOT] ?? Notification serveur - Killer: %d', attackerServerId))
            end
        end
    end
end)

-- ========================================
-- COMMANDES DEBUG
-- ========================================
RegisterCommand('hsdebug', function()
    Config.Debug = not Config.Debug
    print(string.format('^5[HEADSHOT]^7 Debug: %s', tostring(Config.Debug)))
end, false)

RegisterCommand('hsinfo', function()
    print('^5[HEADSHOT]^7 === INFORMATIONS ===')
    print(string.format('Debug: %s', tostring(Config.Debug)))
    print(string.format('Historique: %d entr�es', #recentDamageHistory))
    print(string.format('Cache attacker: %s', lastKnownAttacker and 'Actif' or 'Vide'))
end, false)

RegisterCommand('hsclear', function()
    recentDamageHistory = {}
    lastKnownAttacker = nil
    lastKnownWeapon = nil
    lastAttackerTime = 0
    print('^5[HEADSHOT]^7 Historique effac�')
end, false)

-- ========================================
-- D�SACTIVATION CASQUE
-- ========================================
if Config.DisableHelmet then
    CreateThread(function()
        while true do
            Wait(0)
            SetPedComponentVariation(_PlayerPedId(), 1, 0, 0, 0) -- Slot casque
        end
    end)
end

print('^2[HEADSHOT]^7 Syst�me charg� - Anti-Suicide Intelligent v3.0')
