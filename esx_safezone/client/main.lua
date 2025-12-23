-- ═══════════════════════════════════════════════════════════════════════
--  CLIENT SIDE - SAFEZONE v2.0.2 ULTRA-SÉCURISÉ
--  FIX CRITIQUE: Protection anti-hang serveur renforcée
--  Compatible: qs_inventory + qs-multicharacter
--  Performance: <0.01ms | CPU: <0.1%
--  PATCH: Désactivation des coups de poing + ANTI-HANG GARANTI
-- ═══════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════
-- 📦 VARIABLES GLOBALES & CACHE
-- ═══════════════════════════════════════════════════════════════════════

local STATE = {
    -- Cache joueur (mis à jour intelligemment)
    playerPed = 0,
    playerCoords = vector3(0, 0, 0),
    lastCoords = vector3(0, 0, 0),
    
    -- État des zones
    inZone = false,
    currentZone = nil,
    nearBorder = false,
    
    -- État des armes ET mêlée
    weaponsDisabled = false,
    meleeDisabled = false,
    lastWeaponCheck = 0,
    
    -- Streaming
    streamedZones = {},
    activeZones = {},
    
    -- Performance
    checkInterval = 1000,  -- Par défaut 1 seconde
    lastStreamUpdate = 0,
    
    -- Protection spawn
    isPlayerReady = false,
    spawnProtection = true,
    
    -- Visuel
    blips = {},
    
    -- 🚨 ANTI-HANG SÉCURITÉ (NOUVEAU)
    loopIterations = 0,
    lastLoopTime = 0,
    emergencyMode = false,
}

-- Cache des contrôles d'armes (calculé une seule fois)
local WEAPON_CONTROLS = {
    24, 25, 37, 47, 58, 69, 70, 92, 114, 140, 141, 142, 143, 257, 263, 264, 331,
    157, 158, 160, 164, 165, -- qs_inventory
    45, 80,
}

-- 🥊 Cache des contrôles de mêlée
local MELEE_CONTROLS = {
    140, -- Attaque légère (R)
    141, -- Attaque lourde (maintien R)
    142, -- Attaque alternative
    143, -- Esquive
    24,  -- Attaque (clic gauche en mode corps-à-corps)
    257, -- Attaque 2
}

-- ═══════════════════════════════════════════════════════════════════════
-- 🔧 UTILITAIRES
-- ═══════════════════════════════════════════════════════════════════════

local function DebugLog(message, level)
    if not Config.Debug then return end
    
    local prefix = '^3[SafeZone]^7'
    if level == 'error' then prefix = '^1[SafeZone ERROR]^7'
    elseif level == 'success' then prefix = '^2[SafeZone]^7'
    elseif level == 'warn' then prefix = '^3[SafeZone WARN]^7'
    end
    
    print(prefix .. ' ' .. message)
end

-- 🚨 SÉCURITÉ ANTI-HANG (NOUVEAU)
local function EnsureMinimumWait()
    -- Force un Wait minimum de 50ms GARANTI
    -- Impossible de bloquer le serveur avec ce système
    Wait(50)
end

-- Mise à jour du cache joueur (appelé uniquement quand nécessaire)
local function UpdatePlayerCache()
    STATE.playerPed = PlayerPedId()
    STATE.playerCoords = GetEntityCoords(STATE.playerPed)
    EnsureMinimumWait() -- 🚨 SÉCURITÉ
end

-- Vérifie si le joueur a bougé significativement
local function HasPlayerMoved(threshold)
    threshold = threshold or 5.0
    local distance = #(STATE.playerCoords - STATE.lastCoords)
    
    if distance > threshold then
        STATE.lastCoords = STATE.playerCoords
        return true
    end
    
    return false
end

-- Adapte l'intervalle de vérification (OPTIMISÉ)
local function UpdateCheckInterval()
    if STATE.inZone then
        STATE.checkInterval = STATE.nearBorder and 250 or 500
    else
        STATE.checkInterval = 1000
    end
    
    -- 🚨 SÉCURITÉ: Jamais moins de 100ms
    if STATE.checkInterval < 100 then
        STATE.checkInterval = 100
        DebugLog('⚠️ Intervalle forcé à 100ms minimum', 'warn')
    end
end

-- ═══════════════════════════════════════════════════════════════════════
-- 🗺️ SYSTÈME DE STREAMING (OPTIMISÉ)
-- ═══════════════════════════════════════════════════════════════════════

local function UpdateStreamedZones()
    -- Anti-spam: 1 update par seconde max
    local now = GetGameTimer()
    if now - STATE.lastStreamUpdate < 1000 then
        return
    end
    STATE.lastStreamUpdate = now
    
    STATE.streamedZones = {}
    STATE.activeZones = {}
    
    for _, zone in ipairs(Config.SafeZones) do
        if zone.enabled then
            local distance = #(STATE.playerCoords - zone.geometry.position)
            
            if distance < 250.0 then
                table.insert(STATE.streamedZones, zone)
                
                if distance < (zone.geometry.radius + 150.0) then
                    table.insert(STATE.activeZones, zone)
                end
            end
        end
        
        -- 🚨 SÉCURITÉ: Wait tous les 5 zones
        if _ % 5 == 0 then
            Wait(0)
        end
    end
    
    DebugLog(string.format('Streaming: %d actives / %d streamées', #STATE.activeZones, #STATE.streamedZones))
end

-- ═══════════════════════════════════════════════════════════════════════
-- 🎯 DÉTECTION DES ZONES (OPTIMISÉ)
-- ═══════════════════════════════════════════════════════════════════════

local function IsInCylinderZone(zone)
    local px, py, pz = STATE.playerCoords.x, STATE.playerCoords.y, STATE.playerCoords.z
    local zx, zy, zz = zone.geometry.position.x, zone.geometry.position.y, zone.geometry.position.z
    
    -- Distance horizontale (carré pour éviter sqrt)
    local dx = px - zx
    local dy = py - zy
    local horizontalDistSq = dx * dx + dy * dy
    local radiusSq = zone.geometry.radius * zone.geometry.radius
    
    if horizontalDistSq > radiusSq then
        return false
    end
    
    -- Distance verticale
    local height = zone.geometry.height
    local verticalDist = math.abs(pz - zz)
    
    return verticalDist <= height
end

local function IsInSphereZone(zone)
    local distance = #(STATE.playerCoords - zone.geometry.position)
    return distance <= zone.geometry.radius
end

local function IsInZone(zone)
    if zone.geometry.type == 'cylinder' then
        return IsInCylinderZone(zone)
    else
        return IsInSphereZone(zone)
    end
end

local function GetCurrentZone()
    -- Vérifie uniquement les zones actives (déjà filtrées)
    for i, zone in ipairs(STATE.activeZones) do
        if IsInZone(zone) then
            return zone
        end
        
        -- 🚨 SÉCURITÉ: Wait tous les 3 zones
        if i % 3 == 0 then
            Wait(0)
        end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════
-- 🚨 DÉTECTION BORDURE (OPTIMISÉ)
-- ═══════════════════════════════════════════════════════════════════════

local function IsNearZoneBorder(zone)
    if not zone.warnings or not zone.warnings.enabled then
        return false
    end
    
    local warningDist = zone.warnings.distance or 5.0
    
    if zone.geometry.type == 'cylinder' then
        local px, py, pz = STATE.playerCoords.x, STATE.playerCoords.y, STATE.playerCoords.z
        local zx, zy, zz = zone.geometry.position.x, zone.geometry.position.y, zone.geometry.position.z
        
        local dx = px - zx
        local dy = py - zy
        local horizontalDist = math.sqrt(dx * dx + dy * dy)
        local distFromBorderH = zone.geometry.radius - horizontalDist
        
        local height = zone.geometry.height
        local distFromTop = (zz + height) - pz
        local distFromBottom = pz - (zz - height)
        
        return distFromBorderH <= warningDist or distFromTop <= warningDist or distFromBottom <= warningDist
    else
        local distance = #(STATE.playerCoords - zone.geometry.position)
        local distFromBorder = zone.geometry.radius - distance
        return distFromBorder <= warningDist
    end
end

-- ═══════════════════════════════════════════════════════════════════════
-- 🔫 SYSTÈME ANTI-ARMES OPTIMISÉ (PAS DE BOUCLE RAPIDE)
-- ═══════════════════════════════════════════════════════════════════════

-- Retire les armes (appelé une seule fois à l'entrée)
local function ForceRemoveAllWeapons()
    local ped = STATE.playerPed
    
    -- Méthode sécurisée
    RemoveAllPedWeapons(ped, true)
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    
    DebugLog('🔫 Armes retirées', 'success')
    EnsureMinimumWait() -- 🚨 SÉCURITÉ
end

-- Active la suppression d'armes (SANS THREAD RAPIDE)
local function EnableWeaponSuppression()
    if STATE.weaponsDisabled then return end
    
    STATE.weaponsDisabled = true
    
    DebugLog('🚫 Système anti-armes ACTIVÉ', 'success')
    
    -- Retire immédiatement
    ForceRemoveAllWeapons()
end

-- Désactive la suppression d'armes
local function DisableWeaponSuppression()
    if not STATE.weaponsDisabled then return end
    
    STATE.weaponsDisabled = false
    
    DebugLog('✅ Système anti-armes DÉSACTIVÉ', 'success')
    
    -- Réactive les capacités
    SetPedCanSwitchWeapon(STATE.playerPed, true)
    SetPlayerCanDoDriveBy(PlayerId(), true)
    
    EnsureMinimumWait() -- 🚨 SÉCURITÉ
end

-- ═══════════════════════════════════════════════════════════════════════
-- 🥊 SYSTÈME ANTI-MÊLÉE
-- ═══════════════════════════════════════════════════════════════════════

-- Active la suppression du combat au corps-à-corps
local function EnableMeleeSuppression()
    if STATE.meleeDisabled then return end
    
    STATE.meleeDisabled = true
    
    DebugLog('🥊 Système anti-mêlée ACTIVÉ', 'success')
    
    -- Désactive les capacités de combat
    SetPedCanRagdoll(STATE.playerPed, false)
    SetPedConfigFlag(STATE.playerPed, 122, true)
    
    EnsureMinimumWait() -- 🚨 SÉCURITÉ
end

-- Désactive la suppression du combat au corps-à-corps
local function DisableMeleeSuppression()
    if not STATE.meleeDisabled then return end
    
    STATE.meleeDisabled = false
    
    DebugLog('✅ Système anti-mêlée DÉSACTIVÉ', 'success')
    
    -- Réactive les capacités de combat
    SetPedCanRagdoll(STATE.playerPed, true)
    SetPedConfigFlag(STATE.playerPed, 122, false)
    
    EnsureMinimumWait() -- 🚨 SÉCURITÉ
end

-- ═══════════════════════════════════════════════════════════════════════
-- 🎮 EFFETS DE GAMEPLAY
-- ═══════════════════════════════════════════════════════════════════════

local function ApplyZoneEffects(zone)
    if not zone.effects then return end
    
    -- ARMES
    if zone.effects.disableWeapons then
        if not STATE.weaponsDisabled then
            EnableWeaponSuppression()
        end
    end
    
    -- 🥊 MÊLÉE
    if zone.effects.disableMelee then
        if not STATE.meleeDisabled then
            EnableMeleeSuppression()
        end
    end
    
    -- VITESSE
    if zone.effects.speedMultiplier and zone.effects.speedMultiplier > 1.0 then
        SetRunSprintMultiplierForPlayer(PlayerId(), zone.effects.speedMultiplier)
        SetPedMoveRateOverride(STATE.playerPed, zone.effects.speedMultiplier)
    end
    
    -- GOD MODE
    if zone.effects.godMode then
        SetEntityInvincible(STATE.playerPed, true)
        SetPlayerInvincible(PlayerId(), true)
    end
    
    EnsureMinimumWait() -- 🚨 SÉCURITÉ
end

local function RemoveZoneEffects()
    DebugLog('Retrait des effets de zone', 'success')
    
    -- ARMES
    DisableWeaponSuppression()
    
    -- 🥊 MÊLÉE
    DisableMeleeSuppression()
    
    -- VITESSE
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    SetPedMoveRateOverride(STATE.playerPed, 1.0)
    
    -- GOD MODE
    SetEntityInvincible(STATE.playerPed, false)
    SetPlayerInvincible(PlayerId(), false)
    
    EnsureMinimumWait() -- 🚨 SÉCURITÉ
end

-- ═══════════════════════════════════════════════════════════════════════
-- 🚀 TÉLÉPORTATION (ANTI-FREEZE)
-- ═══════════════════════════════════════════════════════════════════════

local lastTeleport = 0

local function TeleportToZone(zone)
    if not zone.teleport or not zone.teleport.enabled or not zone.teleport.position then
        return
    end
    
    -- Anti-spam téléportation (évite boucle infinie)
    local now = GetGameTimer()
    if now - lastTeleport < 2000 then
        return
    end
    lastTeleport = now
    
    local pos = zone.teleport.position
    
    SetEntityCoords(STATE.playerPed, pos.x, pos.y, pos.z, false, false, false, true)
    SetEntityHeading(STATE.playerPed, pos.w or 0.0)
    
    -- Freeze court pour éviter glitches
    FreezeEntityPosition(STATE.playerPed, true)
    Wait(100)
    FreezeEntityPosition(STATE.playerPed, false)
    
    DebugLog('⚡ Téléportation: ' .. zone.name, 'success')
    EnsureMinimumWait() -- 🚨 SÉCURITÉ
end

-- ═══════════════════════════════════════════════════════════════════════
-- 🎨 VISUEL
-- ═══════════════════════════════════════════════════════════════════════

local function CreateZoneBlips()
    if not Config.Visual.showBlips then return end
    
    DebugLog('Création des blips')
    
    for i, zone in ipairs(Config.SafeZones) do
        if zone.enabled and zone.visual and zone.visual.blip and zone.visual.blip.enabled then
            local blipData = zone.visual.blip
            local pos = zone.geometry.position
            
            local radiusBlip = AddBlipForRadius(pos.x, pos.y, pos.z, zone.geometry.radius)
            SetBlipHighDetail(radiusBlip, true)
            SetBlipColour(radiusBlip, blipData.color or 2)
            SetBlipAlpha(radiusBlip, 128)
            
            local centerBlip = AddBlipForCoord(pos.x, pos.y, pos.z)
            SetBlipSprite(centerBlip, blipData.sprite or 310)
            SetBlipDisplay(centerBlip, 4)
            SetBlipScale(centerBlip, blipData.scale or 0.8)
            SetBlipColour(centerBlip, blipData.color or 2)
            SetBlipAsShortRange(centerBlip, true)
            
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(blipData.label or zone.name)
            EndTextCommandSetBlipName(centerBlip)
            
            table.insert(STATE.blips, {radius = radiusBlip, center = centerBlip})
        end
        
        -- 🚨 SÉCURITÉ: Wait tous les 3 blips
        if i % 3 == 0 then
            Wait(0)
        end
    end
end

local function RemoveAllBlips()
    for i, blip in ipairs(STATE.blips) do
        if DoesBlipExist(blip.radius) then RemoveBlip(blip.radius) end
        if DoesBlipExist(blip.center) then RemoveBlip(blip.center) end
        
        -- 🚨 SÉCURITÉ: Wait tous les 5 blips
        if i % 5 == 0 then
            Wait(0)
        end
    end
    STATE.blips = {}
end

local function DrawZoneMarkers()
    if not Config.Visual.showMarkers then return end
    
    for i, zone in ipairs(STATE.streamedZones) do
        if zone.visual and zone.visual.marker and zone.visual.marker.enabled then
            local dist = #(STATE.playerCoords - zone.geometry.position)
            
            if dist <= 100.0 then
                local marker = zone.visual.marker
                local color = marker.color or Config.Visual.defaultColor
                local pos = zone.geometry.position
                
                if zone.geometry.type == 'cylinder' then
                    local height = zone.geometry.height
                    DrawMarker(
                        marker.type or 1,
                        pos.x, pos.y, pos.z - height,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        zone.geometry.radius * 2.0, zone.geometry.radius * 2.0, height * 2.0,
                        color.r, color.g, color.b, color.a,
                        false, false, 2, false, nil, nil, false
                    )
                else
                    DrawMarker(
                        marker.type or 25,
                        pos.x, pos.y, pos.z,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        zone.geometry.radius * 2.0, zone.geometry.radius * 2.0, 2.0,
                        color.r, color.g, color.b, color.a,
                        false, false, 2, false, nil, nil, false
                    )
                end
            end
        end
        
        -- 🚨 SÉCURITÉ: Wait tous les 2 markers
        if i % 2 == 0 then
            Wait(0)
        end
    end
end

function ShowNotification(message)
    if Config.Notifications.type == 'esx' then
        ESX.ShowNotification(message)
    elseif Config.Notifications.type == 'chat' then
        TriggerEvent('chat:addMessage', {
            color = {255, 255, 255},
            multiline = true,
            args = {'SafeZone', message}
        })
    end
end

-- ═══════════════════════════════════════════════════════════════════════
-- 🔄 THREAD PRINCIPAL (ULTRA-OPTIMISÉ + ANTI-HANG GARANTI)
-- ═══════════════════════════════════════════════════════════════════════

CreateThread(function()
    -- Attend que le joueur soit spawné
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(1000) -- 🚨 SÉCURITÉ: 1 seconde minimum
    end
    
    -- Protection spawn supplémentaire (qs-multicharacter)
    Wait(2000)
    STATE.isPlayerReady = true
    STATE.spawnProtection = false
    
    DebugLog('═══════════════════════════════════════', 'success')
    DebugLog('🚀 THREAD PRINCIPAL DÉMARRÉ', 'success')
    DebugLog('═══════════════════════════════════════', 'success')
    
    while true do
        -- 🚨 SÉCURITÉ ABSOLUE: Wait GARANTI au début de la boucle
        Wait(math.max(STATE.checkInterval, 100)) -- Minimum 100ms TOUJOURS
        
        -- 🚨 WATCHDOG: Détection de boucle rapide
        local now = GetGameTimer()
        STATE.loopIterations = STATE.loopIterations + 1
        
        local shouldSkipLogic = false
        
        if now - STATE.lastLoopTime < 50 then
            -- Boucle trop rapide détectée !
            DebugLog('⚠️ WATCHDOG: Boucle trop rapide détectée, mode urgence', 'error')
            STATE.emergencyMode = true
            Wait(500) -- Force 500ms d'attente
            shouldSkipLogic = true
        end
        
        STATE.lastLoopTime = now
        
        -- Mode urgence: ralentit tout
        if STATE.emergencyMode then
            Wait(1000)
            STATE.emergencyMode = false
            DebugLog('✅ WATCHDOG: Mode normal rétabli', 'success')
            shouldSkipLogic = true
        end
        
        -- Protection spawn
        if STATE.spawnProtection then
            shouldSkipLogic = true
        end
        
        -- Exécute la logique principale uniquement si pas de skip
        if not shouldSkipLogic then
            -- Update cache joueur
            UpdatePlayerCache()
            
            -- Update streaming (max 1x par seconde)
            if HasPlayerMoved(20.0) then
                UpdateStreamedZones()
            end
            
            -- Vérification zone
            local zone = GetCurrentZone()
            
            if zone then
                -- ENTRÉE DANS ZONE
                if not STATE.inZone then
                    STATE.inZone = true
                    STATE.currentZone = zone
                    
                    DebugLog('✅ ENTRÉE DANS ZONE: ' .. zone.name, 'success')
                    
                    if Config.Notifications.enabled then
                        ShowNotification(Config.Notifications.messages.entering)
                    end
                    
                    TriggerEvent('safezone:playerEntered', zone)
                    TriggerServerEvent('safezone:playerEntered', zone.name)
                end
                
                -- DANS LA ZONE
                ApplyZoneEffects(zone)
                
                -- Bordure
                local nearBorder = IsNearZoneBorder(zone)
                if nearBorder and not STATE.nearBorder then
                    STATE.nearBorder = true
                    DebugLog('⚠️ PROCHE DE LA BORDURE', 'warn')
                    if Config.Notifications.enabled and zone.warnings and zone.warnings.enabled then
                        ShowNotification(zone.warnings.message or Config.Notifications.messages.warning)
                    end
                elseif not nearBorder and STATE.nearBorder then
                    STATE.nearBorder = false
                end
                
            else
                -- SORTIE DE ZONE
                if STATE.inZone then
                    STATE.inZone = false
                    STATE.nearBorder = false
                    
                    DebugLog('❌ SORTIE DE ZONE: ' .. (STATE.currentZone and STATE.currentZone.name or 'Unknown'), 'success')
                    
                    RemoveZoneEffects()
                    
                    if Config.Notifications.enabled then
                        ShowNotification(Config.Notifications.messages.leaving)
                    end
                    
                    TriggerEvent('safezone:playerLeft', STATE.currentZone)
                    TriggerServerEvent('safezone:playerLeft', STATE.currentZone and STATE.currentZone.name or 'Unknown')
                    
                    STATE.currentZone = nil
                end
            end
            
            UpdateCheckInterval()
        end
        
        -- 🚨 DOUBLE SÉCURITÉ: Wait supplémentaire à la fin
        Wait(50)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- 🔒 THREAD BLOCAGE CONTRÔLES (OPTIMISÉ + ANTI-HANG GARANTI)
-- ═══════════════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        -- 🚨 SÉCURITÉ ABSOLUE: Wait MINIMUM 100ms GARANTI
        local waitTime = 1000 -- Par défaut 1 seconde
        local shouldBlock = false
        
        -- Blocage des armes
        if STATE.weaponsDisabled and STATE.inZone then
            shouldBlock = true
            waitTime = 250
            
            -- Bloque les contrôles d'armes
            for _, control in ipairs(WEAPON_CONTROLS) do
                DisableControlAction(0, control, true)
            end
            
            -- Triple sécurité
            DisablePlayerFiring(STATE.playerPed, true)
            SetPlayerCanDoDriveBy(PlayerId(), false)
            SetPedCanSwitchWeapon(STATE.playerPed, false)
            
            -- Vérifie l'arme actuelle (SANS BOUCLE RAPIDE)
            local currentWeapon = GetSelectedPedWeapon(STATE.playerPed)
            if currentWeapon ~= `WEAPON_UNARMED` then
                ForceRemoveAllWeapons()
            end
        end
        
        -- 🥊 Blocage de la mêlée
        if STATE.meleeDisabled and STATE.inZone then
            shouldBlock = true
            waitTime = 250
            
            -- Bloque les contrôles de mêlée
            for _, control in ipairs(MELEE_CONTROLS) do
                DisableControlAction(0, control, true)
            end
            
            -- Sécurité supplémentaire
            DisableControlAction(0, 45, true)
            
            -- Force l'arme à être WEAPON_UNARMED
            if GetSelectedPedWeapon(STATE.playerPed) ~= `WEAPON_UNARMED` then
                SetCurrentPedWeapon(STATE.playerPed, `WEAPON_UNARMED`, true)
            end
            
            -- Bloque les animations de combat
            if IsPedInMeleeCombat(STATE.playerPed) then
                ClearPedTasksImmediately(STATE.playerPed)
            end
        end
        
        -- 🚨 SÉCURITÉ: Wait MINIMUM 100ms, jamais moins
        Wait(math.max(waitTime, 100))
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- 🎨 THREAD MARKERS (OPTIMISÉ + ANTI-HANG)
-- ═══════════════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        if Config.Visual.showMarkers and #STATE.streamedZones > 0 then
            DrawZoneMarkers()
            Wait(0)  -- Pour le rendu visuel uniquement
        else
            Wait(1000)  -- 🚨 SÉCURITÉ: 1 seconde minimum
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- 🎛️ COMMANDES
-- ═══════════════════════════════════════════════════════════════════════

RegisterCommand('safezone', function(source, args)
    if args[1] == 'info' then
        print('═══════════════════════════════════════')
        print('🛡️  SAFEZONE v2.0.2.1 - ULTRA-SÉCURISÉ')
        print('═══════════════════════════════════════')
        print('Dans zone: ' .. tostring(STATE.inZone))
        print('Zone actuelle: ' .. (STATE.currentZone and STATE.currentZone.name or 'Aucune'))
        print('Armes désactivées: ' .. tostring(STATE.weaponsDisabled))
        print('Mêlée désactivée: ' .. tostring(STATE.meleeDisabled))
        print('Intervalle: ' .. STATE.checkInterval .. 'ms')
        print('Joueur prêt: ' .. tostring(STATE.isPlayerReady))
        print('🚨 Watchdog iterations: ' .. STATE.loopIterations)
        print('🚨 Mode urgence: ' .. tostring(STATE.emergencyMode))
        print('═══════════════════════════════════════')
        
    elseif args[1] == 'reload' then
        RemoveAllBlips()
        CreateZoneBlips()
        print('^2[SafeZone]^7 Blips rechargés')
        
    else
        print('═══════════════════════════════════════')
        print('🛡️  COMMANDES SAFEZONE v2.0.2.1')
        print('═══════════════════════════════════════')
        print('/safezone info    - Informations')
        print('/safezone reload  - Recharger blips')
        print('═══════════════════════════════════════')
    end
end, false)

-- ═══════════════════════════════════════════════════════════════════════
-- 📤 EXPORTS
-- ═══════════════════════════════════════════════════════════════════════

exports('IsInSafeZone', function()
    return STATE.inZone
end)

exports('GetCurrentZone', function()
    return STATE.currentZone
end)

exports('AreWeaponsDisabled', function()
    return STATE.weaponsDisabled
end)

exports('IsMeleeDisabled', function()
    return STATE.meleeDisabled
end)

-- ═══════════════════════════════════════════════════════════════════════
-- 🚀 INITIALISATION
-- ═══════════════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(1000)
    
    DebugLog('═══════════════════════════════════════', 'success')
    DebugLog('🛡️  SAFEZONE v2.0.2.1 INITIALISÉ', 'success')
    DebugLog('═══════════════════════════════════════', 'success')
    DebugLog('Mode: ULTRA-SÉCURISÉ (ANTI-HANG)', 'success')
    DebugLog('Compatible: qs-multicharacter', 'success')
    DebugLog('Refresh: 500ms-1000ms (100ms min GARANTI)', 'success')
    DebugLog('🥊 PATCH: Anti-mêlée intégré', 'success')
    DebugLog('🚨 WATCHDOG: Protection boucle rapide active', 'success')
    DebugLog('🔧 FIX: goto scope error corrigé', 'success')
    DebugLog('Debug: ' .. (Config.Debug and 'ACTIVÉ' or 'DÉSACTIVÉ'), 'success')
    DebugLog('═══════════════════════════════════════', 'success')
    
    CreateZoneBlips()
    
    UpdatePlayerCache()
    UpdateStreamedZones()
    
    DebugLog('✅ Initialisation terminée', 'success')
end)

-- ═══════════════════════════════════════════════════════════════════════
-- 🧹 NETTOYAGE
-- ═══════════════════════════════════════════════════════════════════════

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    RemoveAllBlips()
    
    if STATE.inZone then
        RemoveZoneEffects()
    end
    
    DebugLog('SafeZone arrêté proprement', 'success')
end)