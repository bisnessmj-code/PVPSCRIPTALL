-- ========================================
-- PVP GUNFIGHT - ZONES DE COMBAT
-- Version 4.2.0 - ZONE INVISIBLE (Apparition proche du bord)
-- ========================================

DebugZones('Module zones chargé (Version 4.2.0 - Zone Invisible)')

-- ========================================
-- CACHE DES NATIVES (LOCALES)
-- ========================================
local _GetGameTimer = GetGameTimer
local _Wait = Wait
local _DrawLine = DrawLine
local _SetEntityHealth = SetEntityHealth
local _GetEntityHealth = GetEntityHealth
local _ShakeGameplayCam = ShakeGameplayCam
local _PlaySoundFrontend = PlaySoundFrontend

-- ========================================
-- VARIABLES
-- ========================================
local currentArenaZone = nil
local isZoneActive = false
local lastDamageTime = 0
local zoneUpdateLock = false

-- Configuration des dégâts
local DAMAGE_CONFIG = {
    damagePerTick = 30,
    tickInterval = 2500,
    warningDistance = 2.0
}

-- ========================================
-- 🔧 NOUVELLE CONFIG: VISIBILITÉ DE LA ZONE
-- ========================================
local VISIBILITY_CONFIG = {
    -- Distance du bord à partir de laquelle la zone devient visible
    showDistance = 1.0,  -- 1 mètre du bord
    
    -- Couleurs de la zone (plus intense quand proche)
    normalColor = {r = 0, g = 255, b = 0, a = 100},
    warningColor = {r = 255, g = 165, b = 0, a = 150},
    dangerColor = {r = 255, g = 0, b = 0, a = 200},
}

-- Configuration du dôme SPHÉRIQUE
local DOME_CONFIG = {
    verticalSegments = 12,
    horizontalSegments = 16,
    groundCircles = 2,
    maxDrawDistance = 50.0
}

-- Précalculs pour le dôme (calculés une seule fois)
local precalculatedAngles = {}
local precalculatedSphere = {}

-- ========================================
-- PRÉCALCULS (UNE SEULE FOIS)
-- ========================================
local function PrecalculateAngles()
    local angleStep = 360.0 / DOME_CONFIG.horizontalSegments
    
    for i = 0, DOME_CONFIG.horizontalSegments do
        local rad = math.rad(i * angleStep)
        precalculatedAngles[i] = {
            cos = math.cos(rad),
            sin = math.sin(rad)
        }
    end
    
    for v = 0, DOME_CONFIG.verticalSegments do
        local heightRatio = v / DOME_CONFIG.verticalSegments
        local angle = math.rad(heightRatio * 180)
        
        precalculatedSphere[v] = {
            cosAngle = math.cos(angle),
            sinAngle = math.sin(angle)
        }
    end
    
    DebugZones('Angles précalculés pour sphère complète')
end

-- Initialiser les précalculs
PrecalculateAngles()

-- ========================================
-- FONCTIONS DE DESSIN OPTIMISÉES
-- ========================================
local function DrawGroundCircle(center, radius, height, r, g, b, a)
    local segments = DOME_CONFIG.horizontalSegments
    
    for i = 0, segments - 1 do
        local p1 = precalculatedAngles[i]
        local p2 = precalculatedAngles[i + 1]
        
        _DrawLine(
            center.x + p1.cos * radius, center.y + p1.sin * radius, height,
            center.x + p2.cos * radius, center.y + p2.sin * radius, height,
            r, g, b, a
        )
    end
end

local function DrawSphere(center, radius, r, g, b, a)
    local verticalSegments = DOME_CONFIG.verticalSegments
    local horizontalSegments = DOME_CONFIG.horizontalSegments
    
    for v = 0, verticalSegments do
        local sphereData = precalculatedSphere[v]
        local currentRadius = sphereData.sinAngle * radius
        local currentHeight = center.z + (sphereData.cosAngle * radius)
        
        DrawGroundCircle(center, currentRadius, currentHeight, r, g, b, a)
    end
    
    for i = 0, horizontalSegments - 1 do
        local baseAngle = precalculatedAngles[i]
        
        for v = 0, verticalSegments - 1 do
            local d1 = precalculatedSphere[v]
            local d2 = precalculatedSphere[v + 1]
            
            local r1 = d1.sinAngle * radius
            local h1 = d1.cosAngle * radius
            local r2 = d2.sinAngle * radius
            local h2 = d2.cosAngle * radius
            
            _DrawLine(
                center.x + baseAngle.cos * r1, center.y + baseAngle.sin * r1, center.z + h1,
                center.x + baseAngle.cos * r2, center.y + baseAngle.sin * r2, center.z + h2,
                r, g, b, a
            )
        end
    end
end

-- ========================================
-- 🔧 NOUVELLE FONCTION: Dessiner seulement la partie proche du joueur
-- ========================================
local function DrawPartialSphereNearPlayer(center, radius, playerPos, r, g, b, a)
    local verticalSegments = DOME_CONFIG.verticalSegments
    local horizontalSegments = DOME_CONFIG.horizontalSegments
    
    -- Dessiner uniquement les segments proches du joueur
    for v = 0, verticalSegments do
        local sphereData = precalculatedSphere[v]
        local currentRadius = sphereData.sinAngle * radius
        local currentHeight = center.z + (sphereData.cosAngle * radius)
        
        -- Vérifier si ce niveau est proche du joueur en hauteur
        local heightDiff = math.abs(playerPos.z - currentHeight)
        if heightDiff < 5.0 then -- Ne dessiner que les niveaux proches en hauteur
            -- Dessiner le cercle à ce niveau
            for i = 0, horizontalSegments - 1 do
                local p1 = precalculatedAngles[i]
                local p2 = precalculatedAngles[i + 1]
                
                local point1X = center.x + p1.cos * currentRadius
                local point1Y = center.y + p1.sin * currentRadius
                local point2X = center.x + p2.cos * currentRadius
                local point2Y = center.y + p2.sin * currentRadius
                
                -- Vérifier si ce segment est proche du joueur
                local distToSegment = math.sqrt((playerPos.x - point1X)^2 + (playerPos.y - point1Y)^2)
                
                if distToSegment < 5.0 then -- Ne dessiner que les segments proches
                    _DrawLine(point1X, point1Y, currentHeight, point2X, point2Y, currentHeight, r, g, b, a)
                end
            end
        end
    end
    
    -- Dessiner les lignes verticales proches
    for i = 0, horizontalSegments - 1 do
        local baseAngle = precalculatedAngles[i]
        
        -- Vérifier si cette ligne verticale est proche du joueur
        local lineX = center.x + baseAngle.cos * radius
        local lineY = center.y + baseAngle.sin * radius
        local distToLine = math.sqrt((playerPos.x - lineX)^2 + (playerPos.y - lineY)^2)
        
        if distToLine < 5.0 then
            for v = 0, verticalSegments - 1 do
                local d1 = precalculatedSphere[v]
                local d2 = precalculatedSphere[v + 1]
                
                local r1 = d1.sinAngle * radius
                local h1 = d1.cosAngle * radius
                local r2 = d2.sinAngle * radius
                local h2 = d2.cosAngle * radius
                
                _DrawLine(
                    center.x + baseAngle.cos * r1, center.y + baseAngle.sin * r1, center.z + h1,
                    center.x + baseAngle.cos * r2, center.y + baseAngle.sin * r2, center.z + h2,
                    r, g, b, a
                )
            end
        end
    end
end

-- ========================================
-- FONCTIONS UTILITAIRES
-- ========================================
local function GetCurrentZoneSafe()
    if not isZoneActive or zoneUpdateLock or not currentArenaZone then
        return nil
    end
    
    if not currentArenaZone.center or not currentArenaZone.radius then
        return nil
    end
    
    return currentArenaZone
end

local function CalculateDistance3D(playerPos, center)
    local dx = playerPos.x - center.x
    local dy = playerPos.y - center.y
    local dz = playerPos.z - center.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function CalculateDistanceToZone(playerPos, center)
    local dx = playerPos.x - center.x
    local dy = playerPos.y - center.y
    return math.sqrt(dx * dx + dy * dy)
end

-- ========================================
-- 🔧 FONCTION: Calculer la distance au bord de la zone
-- ========================================
local function GetDistanceToBorder(playerPos, center, radius)
    local distance3D = CalculateDistance3D(playerPos, center)
    return radius - distance3D  -- Positif = dans la zone, Négatif = hors zone
end

-- ========================================
-- 🔧 FONCTION: Obtenir la couleur selon la distance au bord
-- ========================================
local function GetZoneColor(distanceToBorder)
    if distanceToBorder < 0 then
        -- Hors zone = ROUGE
        return VISIBILITY_CONFIG.dangerColor
    elseif distanceToBorder < 0.5 then
        -- Très proche du bord = ORANGE
        return VISIBILITY_CONFIG.warningColor
    else
        -- Dans la zone mais proche = VERT
        return VISIBILITY_CONFIG.normalColor
    end
end

-- ========================================
-- THREAD: DESSIN DE LA ZONE (RENDU)
-- ⚡ MODIFIÉ: Zone invisible sauf proche du bord
-- ========================================
CreateThread(function()
    DebugZones('Thread dessin zone démarré (MODE INVISIBLE)')
    
    while true do
        local zone = GetCurrentZoneSafe()
        
        if not zone then
            _Wait(1000)
        else
            local playerPos = GetCachedCoords()
            local distanceToBorder = GetDistanceToBorder(playerPos, zone.center, zone.radius)
            
            -- 🔧 NOUVEAU: Ne dessiner que si proche du bord
            if distanceToBorder > VISIBILITY_CONFIG.showDistance then
                -- Loin du bord: pas de dessin, vérification lente
                _Wait(200)
            elseif distanceToBorder < -5.0 then
                -- Très loin hors zone: vérification lente
                _Wait(Config.Performance.intervals.zoneDomeIdle)
            else
                -- Proche du bord (ou hors zone): dessiner
                _Wait(0)
                
                local color = GetZoneColor(distanceToBorder)
                
                -- Dessiner uniquement la partie de la sphère proche du joueur
                DrawPartialSphereNearPlayer(zone.center, zone.radius, playerPos, color.r, color.g, color.b, color.a)
                
                -- Dessiner un cercle au sol pour référence
                DrawGroundCircle(zone.center, zone.radius, zone.center.z + 0.1, color.r, color.g, color.b, color.a)
            end
        end
    end
end)

-- ========================================
-- THREAD: VÉRIFICATION HORS ZONE (LOGIQUE)
-- ⚡ INCHANGÉ
-- ========================================
CreateThread(function()
    DebugZones('Thread vérification zone démarré')
    
    while true do
        if not isZoneActive then
            _Wait(1000)
        else
            local zone = GetCurrentZoneSafe()
            
            if not zone then
                _Wait(500)
            else
                local center = zone.center
                local radius = zone.radius
                
                _Wait(Config.Performance.intervals.zoneCheck)
                
                if not isZoneActive then
                    goto continue
                end
                
                local playerPos = GetCachedCoords()
                local distance3D = CalculateDistance3D(playerPos, center)
                local isInZone = distance3D <= radius
                
                if not isInZone then
                    DebugWarn('Joueur hors zone! Distance 3D: %.2fm / Rayon: %.2fm', distance3D, radius)
                    
                    local currentTime = _GetGameTimer()
                    
                    if currentTime - lastDamageTime >= DAMAGE_CONFIG.tickInterval then
                        local ped = GetCachedPed()
                        local currentHealth = _GetEntityHealth(ped)
                        local newHealth = currentHealth - DAMAGE_CONFIG.damagePerTick
                        
                        DebugZones('Dégâts: -%d HP (%d -> %d)', DAMAGE_CONFIG.damagePerTick, currentHealth, newHealth)
                        
                        _SetEntityHealth(ped, newHealth)
                        _ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08)
                        _PlaySoundFrontend(-1, "CHECKPOINT_MISSED", "HUD_MINI_GAME_SOUNDSET", true)
                        ESX.ShowNotification('~r~⚠ Hors zone! (-' .. DAMAGE_CONFIG.damagePerTick .. ' HP)')
                        
                        lastDamageTime = currentTime
                        
                        if newHealth <= 0 then
                            DebugError('Joueur mort hors zone!')
                            TriggerServerEvent('pvp:playerDiedOutsideZone')
                        end
                    end
                end
                
                ::continue::
            end
        end
    end
end)

-- ========================================
-- THREAD: AFFICHAGE TEXTE ZONE (RENDU)
-- ⚡ MODIFIÉ: Afficher seulement quand proche du bord
-- ========================================
CreateThread(function()
    while true do
        if not isZoneActive then
            _Wait(1000)
        else
            local zone = GetCurrentZoneSafe()
            
            if not zone then
                _Wait(500)
            else
                local playerPos = GetCachedCoords()
                local distanceToBorder = GetDistanceToBorder(playerPos, zone.center, zone.radius)
                
                -- 🔧 MODIFIÉ: Afficher texte seulement si proche du bord ou hors zone
                if distanceToBorder > DAMAGE_CONFIG.warningDistance then
                    -- Loin du bord: pas de texte
                    _Wait(200)
                else
                    _Wait(0)
                    
                    if distanceToBorder < 0 then
                        -- Hors zone
                        SetTextScale(0.5, 0.5)
                        SetTextFont(4)
                        SetTextProportional(1)
                        SetTextColour(255, 0, 0, 255)
                        SetTextEntry("STRING")
                        SetTextCentre(1)
                        AddTextComponentString(string.format("⚠ HORS ZONE! (%.1fm)", math.abs(distanceToBorder)))
                        DrawText(0.5, 0.15)
                    elseif distanceToBorder <= DAMAGE_CONFIG.warningDistance then
                        -- Avertissement proche de la limite
                        SetTextScale(0.4, 0.4)
                        SetTextFont(4)
                        SetTextProportional(1)
                        SetTextColour(255, 165, 0, 255)
                        SetTextEntry("STRING")
                        SetTextCentre(1)
                        AddTextComponentString(string.format("⚠ Limite à %.1fm", distanceToBorder))
                        DrawText(0.5, 0.15)
                    end
                end
            end
        end
    end
end)

-- ========================================
-- EVENTS
-- ========================================
RegisterNetEvent('pvp:setArenaZone', function(arenaKey)
    DebugZones('Configuration zone: %s', arenaKey)
    
    zoneUpdateLock = true
    
    local arena = Config.Arenas[arenaKey]
    
    if not arena then
        DebugError('Arène %s introuvable!', arenaKey)
        zoneUpdateLock = false
        return
    end
    
    if not arena.zone or not arena.zone.center or not arena.zone.radius then
        DebugError('Zone invalide pour arène %s!', arenaKey)
        zoneUpdateLock = false
        return
    end
    
    currentArenaZone = {
        center = vector3(arena.zone.center.x, arena.zone.center.y, arena.zone.center.z),
        radius = arena.zone.radius
    }
    
    zoneUpdateLock = false
    
    DebugZones('Zone sphérique activée (INVISIBLE) - Centre: %.2f, %.2f, %.2f | Rayon: %.2f', 
        currentArenaZone.center.x, currentArenaZone.center.y, currentArenaZone.center.z, currentArenaZone.radius)
end)

RegisterNetEvent('pvp:enableZones', function()
    DebugSuccess('Activation zones (MODE INVISIBLE - Visible à %.1fm du bord)', VISIBILITY_CONFIG.showDistance)
    lastDamageTime = _GetGameTimer()
    isZoneActive = true
end)

RegisterNetEvent('pvp:disableZones', function()
    DebugSuccess('Désactivation zones')
    
    zoneUpdateLock = true
    isZoneActive = false
    _Wait(0)
    currentArenaZone = nil
    lastDamageTime = 0
    zoneUpdateLock = false
end)

-- ========================================
-- CLEANUP
-- ========================================
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    DebugZones('Nettoyage module zones')
    zoneUpdateLock = true
    isZoneActive = false
    currentArenaZone = nil
    zoneUpdateLock = false
end)

DebugSuccess('Module zones initialisé (VERSION 4.2.0 - Zone Invisible, Visible à %.1fm du bord)', VISIBILITY_CONFIG.showDistance)