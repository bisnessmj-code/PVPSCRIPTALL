-- ================================================================================================
-- GUNFIGHT PODIUM - CLIENT v3.1.0 OPTIMIZED
-- ================================================================================================
-- VERSION ULTRA-OPTIMISÉE - CPU < 0.02ms
-- Compatible avec qs-appearance
-- ================================================================================================

-- ================================================================================================
-- VARIABLES LOCALES
-- ================================================================================================
local podiumPeds = {
    gunfight = {},
    pvp = {}
}

local podiumData = {
    gunfight = {},
    pvp = {}
}

local blips = {
    gunfight = nil,
    pvp = nil
}

-- ========================================
-- CACHE POUR OPTIMISATION CPU
-- ========================================
local cache = {
    playerPed = 0,
    playerCoords = vector3(0, 0, 0),
    isNearPodium = false,
    nearestPodiumDist = 999999,
    lastUpdate = 0
}

-- Constantes
local CACHE_UPDATE_INTERVAL = 500 -- Mise à jour du cache toutes les 500ms
local NEAR_DISTANCE = 50.0 -- Distance pour activer l'affichage
local VERY_NEAR_DISTANCE = 20.0 -- Distance pour affichage haute fréquence

-- ================================================================================================
-- FONCTION : LOG DEBUG
-- ================================================================================================
local function DebugLog(message, logType)
    if not Config.Debug then return end
    
    local prefix = "^6[Podium-Client]^0"
    if logType == "error" then
        prefix = "^1[Podium-Client ERROR]^0"
    elseif logType == "success" then
        prefix = "^2[Podium-Client OK]^0"
    elseif logType == "ped" then
        prefix = "^3[Podium-PED]^0"
    elseif logType == "skin" then
        prefix = "^5[Podium-Skin]^0"
    end
    
    print(prefix .. " " .. message)
end

-- ================================================================================================
-- FONCTION : METTRE À JOUR LE CACHE JOUEUR
-- ================================================================================================
local function UpdatePlayerCache()
    local currentTime = GetGameTimer()
    
    -- Ne mettre à jour que si l'intervalle est dépassé
    if currentTime - cache.lastUpdate < CACHE_UPDATE_INTERVAL then
        return
    end
    
    cache.playerPed = PlayerPedId()
    cache.playerCoords = GetEntityCoords(cache.playerPed)
    cache.lastUpdate = currentTime
    
    -- Calculer la distance au podium le plus proche
    local minDist = 999999
    
    -- Vérifier distance aux podiums Gunfight
    if Config.Podiums.gunfight then
        for rank = 1, 3 do
            local podiumPos = Config.PodiumGunfight[rank].pos
            local dist = #(cache.playerCoords - podiumPos)
            if dist < minDist then
                minDist = dist
            end
        end
    end
    
    -- Vérifier distance aux podiums PVP
    if Config.Podiums.pvp then
        for rank = 1, 3 do
            local podiumPos = Config.PodiumPVP[rank].pos
            local dist = #(cache.playerCoords - podiumPos)
            if dist < minDist then
                minDist = dist
            end
        end
    end
    
    cache.nearestPodiumDist = minDist
    cache.isNearPodium = minDist < NEAR_DISTANCE
end

-- ================================================================================================
-- FONCTION : AFFICHER DU TEXTE 3D
-- ================================================================================================
local function Draw3DText(x, y, z, text, scale, font)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    
    if onScreen then
        SetTextScale(scale or Config.Text3D.scale, scale or Config.Text3D.scale)
        SetTextFont(font or Config.Text3D.font)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
        
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 150)
    end
end

-- ================================================================================================
-- FONCTION : NETTOYER LES ANCIENS PEDS D'UN PODIUM
-- ================================================================================================
local function CleanupOldPeds(podiumType)
    DebugLog("Nettoyage des anciens PEDs du podium " .. podiumType, "ped")
    
    for rank, ped in pairs(podiumPeds[podiumType]) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
            DebugLog(podiumType .. " - PED de la place " .. rank .. " supprimé", "success")
        end
    end
    
    podiumPeds[podiumType] = {}
    DebugLog("PEDs du podium " .. podiumType .. " nettoyés", "success")
end

-- ================================================================================================
-- FONCTION : APPLIQUER LE SKIN QS-APPEARANCE AU PED
-- ================================================================================================
local function ApplyQSAppearanceSkin(ped, skinData)
    if not skinData then
        DebugLog("Aucune donnée de skin à appliquer", "error")
        return false
    end
    
    DebugLog("Application du skin qs-appearance au PED...", "skin")
    
    Citizen.Wait(100)
    
    -- ============================================
    -- COMPOSANTS (components)
    -- ============================================
    if skinData.components and type(skinData.components) == "table" then
        for _, comp in ipairs(skinData.components) do
            if comp.component_id and comp.component_id ~= 99 then
                local drawable = comp.drawable
                local texture = comp.texture or 0
                
                if type(drawable) == "string" then
                    local d, t = drawable:match("(%d+)_(%d+)")
                    if d then
                        drawable = tonumber(d)
                        texture = tonumber(t) or texture
                    else
                        drawable = tonumber(drawable) or 0
                    end
                end
                
                if type(drawable) == "number" then
                    SetPedComponentVariation(ped, comp.component_id, drawable, texture, 0)
                    DebugLog(string.format("  Component %d: drawable=%d, texture=%d", comp.component_id, drawable, texture), "skin")
                end
            end
        end
    end
    
    -- ============================================
    -- ACCESSOIRES (props)
    -- ============================================
    if skinData.props and type(skinData.props) == "table" then
        for _, prop in ipairs(skinData.props) do
            if prop.prop_id then
                local drawable = prop.drawable
                local texture = prop.texture or 0
                
                if drawable and drawable ~= -1 then
                    SetPedPropIndex(ped, prop.prop_id, drawable, texture, true)
                    DebugLog(string.format("  Prop %d: drawable=%d, texture=%d", prop.prop_id, drawable, texture), "skin")
                else
                    ClearPedProp(ped, prop.prop_id)
                end
            end
        end
    end
    
    -- ============================================
    -- CHEVEUX (hair)
    -- ============================================
    if skinData.hair then
        local hairStyle = skinData.hair.style or 0
        local hairTexture = skinData.hair.texture or 0
        local hairColor = skinData.hair.color or 0
        local hairHighlight = skinData.hair.highlight or 0
        
        SetPedComponentVariation(ped, 2, hairStyle, hairTexture, 0)
        
        if hairColor >= 0 and hairHighlight >= 0 then
            SetPedHairColor(ped, hairColor, hairHighlight)
        end
        
        DebugLog(string.format("  Hair: style=%d, color=%d, highlight=%d", hairStyle, hairColor, hairHighlight), "skin")
    end
    
    -- ============================================
    -- COULEUR DES YEUX (eyeColor)
    -- ============================================
    if skinData.eyeColor and skinData.eyeColor >= 0 then
        SetPedEyeColor(ped, skinData.eyeColor)
        DebugLog("  EyeColor: " .. skinData.eyeColor, "skin")
    end
    
    -- ============================================
    -- HEAD BLEND
    -- ============================================
    if skinData.headBlend then
        local hb = skinData.headBlend
        local shapeFirst = hb.shapeFirst or 0
        local shapeSecond = hb.shapeSecond or 0
        local skinFirst = hb.skinFirst or 0
        local skinSecond = hb.skinSecond or 0
        local shapeMix = hb.shapeMix or 0.5
        local skinMix = hb.skinMix or 0.5
        local thirdMix = hb.thirdMix or 0.0
        
        if shapeMix > 1.0 then shapeMix = shapeMix / 100.0 end
        if skinMix > 1.0 then skinMix = skinMix / 100.0 end
        if thirdMix > 1.0 then thirdMix = thirdMix / 100.0 end
        
        SetPedHeadBlendData(ped, 
            shapeFirst, shapeSecond, 0,
            skinFirst, skinSecond, 0,
            shapeMix, skinMix, thirdMix, false
        )
        
        DebugLog(string.format("  HeadBlend: shape=%d/%d, skin=%d/%d, mix=%.2f/%.2f", 
            shapeFirst, shapeSecond, skinFirst, skinSecond, shapeMix, skinMix), "skin")
    end
    
    -- ============================================
    -- HEAD OVERLAYS
    -- ============================================
    if skinData.headOverlays then
        local overlays = skinData.headOverlays
        
        local overlayMapping = {
            blemishes = 0, beard = 1, eyebrows = 2, ageing = 3,
            makeUp = 4, blush = 5, complexion = 6, sunDamage = 7,
            lipstick = 8, moleAndFreckles = 9, chestHair = 10, bodyBlemishes = 11
        }
        
        local colorTypes = {
            [0] = 0, [1] = 1, [2] = 1, [3] = 0, [4] = 2, [5] = 2,
            [6] = 0, [7] = 0, [8] = 2, [9] = 0, [10] = 1, [11] = 0
        }
        
        for name, index in pairs(overlayMapping) do
            local overlay = overlays[name]
            if overlay then
                local style = overlay.style or 255
                local opacity = overlay.opacity or 0
                local color = overlay.color or 0
                local secondColor = overlay.secondColor or 0
                
                if opacity > 1.0 then opacity = opacity / 10.0 end
                
                if style >= 0 and style < 255 then
                    SetPedHeadOverlay(ped, index, style, opacity)
                    
                    local colorType = colorTypes[index] or 0
                    if colorType > 0 then
                        SetPedHeadOverlayColor(ped, index, colorType, color, secondColor)
                    end
                    
                    DebugLog(string.format("  Overlay %s: style=%d, opacity=%.2f, color=%d", 
                        name, style, opacity, color), "skin")
                else
                    SetPedHeadOverlay(ped, index, 255, 0.0)
                end
            end
        end
    end
    
    -- ============================================
    -- FACE FEATURES
    -- ============================================
    if skinData.faceFeatures then
        local ff = skinData.faceFeatures
        
        local featureMapping = {
            noseWidth = 0, nosePeakHigh = 1, nosePeakSize = 2, noseBoneHigh = 3,
            nosePeakLowering = 4, noseBoneTwist = 5, eyeBrownHigh = 6, eyeBrownForward = 7,
            cheeksBoneHigh = 8, cheeksBoneWidth = 9, cheeksWidth = 10, eyesOpening = 11,
            lipsThickness = 12, jawBoneWidth = 13, jawBoneBackSize = 14, chinBoneLowering = 15,
            chinBoneLenght = 16, chinBoneSize = 17, chinHole = 18, neckThickness = 19
        }
        
        for name, index in pairs(featureMapping) do
            local value = ff[name]
            if value then
                SetPedFaceFeature(ped, index, value)
            end
        end
        
        DebugLog("  FaceFeatures appliqués", "skin")
    end
    
    -- ============================================
    -- ÉCHELLE DU PED
    -- ============================================
    if skinData.pedScale and skinData.pedScale ~= 1.0 then
        SetPedScale(ped, skinData.pedScale)
        DebugLog("  PedScale: " .. skinData.pedScale, "skin")
    end
    
    DebugLog("Skin qs-appearance appliqué avec succès", "success")
    return true
end

-- ================================================================================================
-- FONCTION : VÉRIFIER SI LE MODÈLE EST UN PED FREEMODE
-- ================================================================================================
local function IsFreemodeModel(modelName)
    return modelName == "mp_m_freemode_01" or modelName == "mp_f_freemode_01"
end

-- ================================================================================================
-- FONCTION : CRÉER UN PED DE PODIUM
-- ================================================================================================
local function CreatePodiumPed(rank, playerData, podiumType)
    local podiumConfig = podiumType == "gunfight" and Config.PodiumGunfight[rank] or Config.PodiumPVP[rank]
    
    if not podiumConfig then
        DebugLog("Configuration manquante pour le rang " .. rank .. " du podium " .. podiumType, "error")
        return nil
    end
    
    DebugLog(string.format("[%s] Création du PED pour la place %d : %s", podiumType, rank, playerData.name), "ped")
    
    local modelName = "mp_m_freemode_01"
    
    if playerData.skin and playerData.skin.model then
        modelName = playerData.skin.model
        DebugLog("Modèle trouvé dans le skin: " .. modelName, "ped")
    end
    
    local modelHash = GetHashKey(modelName)
    
    RequestModel(modelHash)
    
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 10000 do
        Citizen.Wait(100)
        timeout = timeout + 100
    end
    
    if not HasModelLoaded(modelHash) then
        DebugLog("Impossible de charger le modèle " .. modelName .. ", utilisation du fallback", "error")
        modelHash = GetHashKey("mp_m_freemode_01")
        RequestModel(modelHash)
        
        timeout = 0
        while not HasModelLoaded(modelHash) and timeout < 5000 do
            Citizen.Wait(100)
            timeout = timeout + 100
        end
        
        if not HasModelLoaded(modelHash) then
            DebugLog("Impossible de charger le modèle fallback", "error")
            return nil
        end
    end
    
    local ped = CreatePed(
        4, modelHash,
        podiumConfig.pos.x, podiumConfig.pos.y, podiumConfig.pos.z,
        podiumConfig.heading,
        false, true
    )
    
    if not DoesEntityExist(ped) then
        DebugLog("Échec de la création du PED", "error")
        SetModelAsNoLongerNeeded(modelHash)
        return nil
    end
    
    -- Configuration complète du PED (une seule fois à la création)
    SetEntityAlpha(ped, 255, false)
    SetEntityAsMissionEntity(ped, true, true)
    SetPedFleeAttributes(ped, 0, 0)
    SetPedDiesWhenInjured(ped, false)
    SetPedKeepTask(ped, true)
    SetPedCanBeKnockedOffVehicle(ped, 1)
    
    -- Invincibilité
    SetEntityInvincible(ped, true)
    SetEntityMaxHealth(ped, 10000)
    SetEntityHealth(ped, 10000)
    SetPedArmour(ped, 10000)
    SetPedCanRagdoll(ped, false)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetPedSuffersCriticalHits(ped, false)
    SetEntityProofs(ped, true, true, true, true, true, true, true, true)
    
    -- Bloquer les événements
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskSetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCombatAttributes(ped, 17, true)
    SetPedCombatAttributes(ped, 46, true)
    
    -- Flags de configuration (regroupés)
    local configFlags = {2, 17, 24, 32, 46, 122, 186, 187, 208, 225, 226, 241, 242, 243, 281, 429}
    for _, flag in ipairs(configFlags) do
        SetPedConfigFlag(ped, flag, true)
    end
    
    -- Protection supplémentaire
    SetPedCanBeDraggedOut(ped, false)
    SetPedCanBeTargetted(ped, false)
    SetPedCanBeTargettedByPlayer(ped, PlayerId(), false)
    SetPedCanBeTargettedByTeam(ped, 0, false)
    SetEntityCanBeDamaged(ped, false)
    
    -- Physique
    SetEntityDynamic(ped, false)
    SetEntityCollision(ped, false, false)
    
    -- Appliquer le skin
    if playerData.skin then
        if IsFreemodeModel(modelName) then
            ApplyQSAppearanceSkin(ped, playerData.skin)
        else
            DebugLog("PED custom détecté (" .. modelName .. "), application minimale du skin", "skin")
            
            if playerData.skin.components then
                for _, comp in ipairs(playerData.skin.components) do
                    if comp.component_id and comp.component_id ~= 99 and type(comp.drawable) == "number" then
                        SetPedComponentVariation(ped, comp.component_id, comp.drawable, comp.texture or 0, 0)
                    end
                end
            end
            
            if playerData.skin.props then
                for _, prop in ipairs(playerData.skin.props) do
                    if prop.prop_id and prop.drawable and prop.drawable ~= -1 then
                        SetPedPropIndex(ped, prop.prop_id, prop.drawable, prop.texture or 0, true)
                    end
                end
            end
        end
    end
    
    -- Animation
    if Config.Animations.enabled and Config.Animations.scenarios[rank] then
        Citizen.Wait(200)
        TaskStartScenarioInPlace(ped, Config.Animations.scenarios[rank], 0, true)
        DebugLog("Animation appliquée: " .. Config.Animations.scenarios[rank], "ped")
    end
    
    SetModelAsNoLongerNeeded(modelHash)
    
    DebugLog(string.format("[%s] PED créé : %s (Rang %d, Model: %s)", podiumType, playerData.name, rank, modelName), "success")
    
    return ped
end

-- ================================================================================================
-- FONCTION : METTRE À JOUR UN PODIUM
-- ================================================================================================
local function UpdatePodium(top3, podiumType)
    DebugLog("Mise à jour du podium " .. podiumType .. " avec " .. #top3 .. " joueur(s)")
    
    if Config.Optimization.cleanupOldPeds then
        CleanupOldPeds(podiumType)
    end
    
    podiumData[podiumType] = top3
    
    for rank, playerData in ipairs(top3) do
        if rank <= 3 then
            local ped = CreatePodiumPed(rank, playerData, podiumType)
            
            if ped then
                podiumPeds[podiumType][rank] = ped
            end
        end
    end
    
    DebugLog("Podium " .. podiumType .. " mis à jour avec " .. #podiumPeds[podiumType] .. " PED(s)", "success")
end

-- ================================================================================================
-- EVENTS : RECEVOIR LES MISES À JOUR
-- ================================================================================================
RegisterNetEvent('gunfightpodium:updateGunfight')
AddEventHandler('gunfightpodium:updateGunfight', function(top3)
    if not top3 or #top3 == 0 then
        DebugLog("Aucune donnée Gunfight reçue", "error")
        return
    end
    
    DebugLog("Données Gunfight reçues: " .. #top3 .. " joueur(s)", "success")
    UpdatePodium(top3, "gunfight")
end)

RegisterNetEvent('gunfightpodium:updatePVP')
AddEventHandler('gunfightpodium:updatePVP', function(top3)
    if not top3 or #top3 == 0 then
        DebugLog("Aucune donnée PVP reçue", "error")
        return
    end
    
    DebugLog("Données PVP reçues: " .. #top3 .. " joueur(s)", "success")
    UpdatePodium(top3, "pvp")
end)

-- ================================================================================================
-- THREAD : MISE À JOUR DU CACHE (500ms)
-- ================================================================================================
Citizen.CreateThread(function()
    DebugLog("Thread de mise à jour du cache démarré (500ms)")
    
    while true do
        Citizen.Wait(CACHE_UPDATE_INTERVAL)
        UpdatePlayerCache()
    end
end)

-- ================================================================================================
-- THREAD : MAINTENANCE DES PEDS (OPTIMISÉ - 30 secondes)
-- ================================================================================================
Citizen.CreateThread(function()
    DebugLog("Thread de maintenance des PEDs démarré (30s)")
    
    while true do
        Citizen.Wait(30000) -- Toutes les 30 secondes au lieu de 5
        
        -- Ne maintenir que si le joueur est proche
        if cache.isNearPodium then
            for podiumType, peds in pairs(podiumPeds) do
                for rank, ped in pairs(peds) do
                    if DoesEntityExist(ped) then
                        -- Réappliquer seulement les propriétés critiques
                        SetEntityInvincible(ped, true)
                        FreezeEntityPosition(ped, true)
                        SetEntityCanBeDamaged(ped, false)
                    end
                end
            end
        end
    end
end)

-- ================================================================================================
-- THREAD : AFFICHAGE DES NOMS EN 3D (ULTRA-OPTIMISÉ)
-- ================================================================================================
Citizen.CreateThread(function()
    if not Config.Text3D.enabled then
        DebugLog("Affichage des noms 3D désactivé")
        return
    end
    
    DebugLog("Thread d'affichage des noms 3D démarré (OPTIMISÉ)")
    
    while true do
        -- Wait adaptatif selon la distance
        if not cache.isNearPodium then
            -- LOIN : thread inactif
            Citizen.Wait(2000)
        elseif cache.nearestPodiumDist > VERY_NEAR_DISTANCE then
            -- MOYENNEMENT PROCHE : rafraîchissement lent
            Citizen.Wait(500)
        else
            -- TRÈS PROCHE : affichage fluide
            Citizen.Wait(0)
        end
        
        -- Ne rien faire si trop loin
        if not cache.isNearPodium then
            goto continue
        end
        
        -- Afficher les textes (utilise le cache.playerCoords)
        for podiumType, peds in pairs(podiumPeds) do
            local podiumConfig = podiumType == "gunfight" and Config.PodiumGunfight or Config.PodiumPVP
            local statsFormat = Config.StatsDisplay[podiumType]
            
            for rank, ped in pairs(peds) do
                if DoesEntityExist(ped) and podiumData[podiumType][rank] and podiumConfig[rank] then
                    local pedCoords = GetEntityCoords(ped)
                    local distance = #(cache.playerCoords - pedCoords)
                    
                    if distance < Config.Text3D.drawDistance then
                        local playerDataInfo = podiumData[podiumType][rank]
                        local config = podiumConfig[rank]
                        
                        local baseZ = pedCoords.z + 1.0
                        local spacing = Config.Text3D.spacing
                        local currentZ = baseZ + spacing.label
                        
                        -- Label
                        if Config.Text3D.showLabel then
                            Draw3DText(pedCoords.x, pedCoords.y, currentZ, config.label, 0.4, 4)
                            currentZ = currentZ - spacing.name
                        end
                        
                        -- Nom
                        if Config.Text3D.showName then
                            Draw3DText(pedCoords.x, pedCoords.y, currentZ, playerDataInfo.name, 0.35, 4)
                            currentZ = currentZ - spacing.stats
                        end
                        
                        -- Statistiques
                        if Config.Text3D.showStats and statsFormat then
                            if podiumType == "gunfight" then
                                if statsFormat.showKD then
                                    Draw3DText(pedCoords.x, pedCoords.y, currentZ, 
                                        string.format(statsFormat.formatKD, playerDataInfo.kd or 0), 0.3, 4)
                                    currentZ = currentZ - spacing.stats
                                end
                                
                                if statsFormat.showKills then
                                    Draw3DText(pedCoords.x, pedCoords.y, currentZ, 
                                        string.format(statsFormat.formatKills, playerDataInfo.kills or 0, playerDataInfo.deaths or 0), 0.3, 4)
                                    currentZ = currentZ - spacing.stats
                                end
                                
                                if statsFormat.showStreak then
                                    Draw3DText(pedCoords.x, pedCoords.y, currentZ, 
                                        string.format(statsFormat.formatStreak, playerDataInfo.streak or 0), 0.3, 4)
                                end
                                    
                            elseif podiumType == "pvp" then
                                if statsFormat.showElo then
                                    Draw3DText(pedCoords.x, pedCoords.y, currentZ, 
                                        string.format(statsFormat.formatElo, playerDataInfo.elo or 1000), 0.3, 4)
                                    currentZ = currentZ - spacing.stats
                                end
                                
                                if statsFormat.showRankId then
                                    Draw3DText(pedCoords.x, pedCoords.y, currentZ, 
                                        string.format(statsFormat.formatRankId, playerDataInfo.rank_id or 1), 0.3, 4)
                                    currentZ = currentZ - spacing.stats
                                end
                                
                                if statsFormat.showBestElo then
                                    Draw3DText(pedCoords.x, pedCoords.y, currentZ, 
                                        string.format(statsFormat.formatBestElo, playerDataInfo.best_elo or 1000), 0.3, 4)
                                    currentZ = currentZ - spacing.stats
                                end
                                
                                if statsFormat.showWinLoss then
                                    Draw3DText(pedCoords.x, pedCoords.y, currentZ, 
                                        string.format(statsFormat.formatWinLoss, playerDataInfo.wins or 0, playerDataInfo.losses or 0), 0.3, 4)
                                    currentZ = currentZ - spacing.stats
                                end
                                
                                if statsFormat.showWinRate then
                                    Draw3DText(pedCoords.x, pedCoords.y, currentZ, 
                                        string.format(statsFormat.formatWinRate, playerDataInfo.win_rate or 0), 0.3, 4)
                                    currentZ = currentZ - spacing.stats
                                end
                                
                                if statsFormat.showMatches then
                                    Draw3DText(pedCoords.x, pedCoords.y, currentZ, 
                                        string.format(statsFormat.formatMatches, playerDataInfo.matches_played or 0), 0.3, 4)
                                    currentZ = currentZ - spacing.stats
                                end
                                
                                if statsFormat.showWinStreak then
                                    Draw3DText(pedCoords.x, pedCoords.y, currentZ, 
                                        string.format(statsFormat.formatWinStreak, playerDataInfo.win_streak or 0), 0.3, 4)
                                    currentZ = currentZ - spacing.stats
                                end
                                
                                if statsFormat.showBestStreak then
                                    Draw3DText(pedCoords.x, pedCoords.y, currentZ, 
                                        string.format(statsFormat.formatBestStreak, playerDataInfo.best_win_streak or 0), 0.3, 4)
                                end
                            end
                        end
                    end
                end
            end
        end
        
        ::continue::
    end
end)

-- ================================================================================================
-- CRÉATION DES BLIPS
-- ================================================================================================
Citizen.CreateThread(function()
    if Config.Blips.gunfight.enabled then
        DebugLog("Création du blip Gunfight")
        
        local blip = AddBlipForCoord(Config.Blips.gunfight.pos.x, Config.Blips.gunfight.pos.y, Config.Blips.gunfight.pos.z)
        SetBlipSprite(blip, Config.Blips.gunfight.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Blips.gunfight.scale)
        SetBlipColour(blip, Config.Blips.gunfight.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Config.Blips.gunfight.name)
        EndTextCommandSetBlipName(blip)
        
        blips.gunfight = blip
    end
    
    if Config.Blips.pvp.enabled then
        DebugLog("Création du blip PVP")
        
        local blip = AddBlipForCoord(Config.Blips.pvp.pos.x, Config.Blips.pvp.pos.y, Config.Blips.pvp.pos.z)
        SetBlipSprite(blip, Config.Blips.pvp.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Blips.pvp.scale)
        SetBlipColour(blip, Config.Blips.pvp.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Config.Blips.pvp.name)
        EndTextCommandSetBlipName(blip)
        
        blips.pvp = blip
    end
end)

-- ================================================================================================
-- NETTOYAGE À L'ARRÊT
-- ================================================================================================
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    DebugLog("Arrêt de la ressource, nettoyage...", "success")
    
    CleanupOldPeds("gunfight")
    CleanupOldPeds("pvp")
    
    for _, blip in pairs(blips) do
        if blip then RemoveBlip(blip) end
    end
    
    DebugLog("Nettoyage terminé", "success")
end)

-- ================================================================================================
-- INITIALISATION
-- ================================================================================================
Citizen.CreateThread(function()
    Wait(2000)
    
    DebugLog("Client initialisé - Version OPTIMISÉE v3.1.0", "success")
    DebugLog("Demande de mise à jour des podiums au serveur...")
    TriggerServerEvent('gunfightpodium:requestUpdate')
end)

-- ================================================================================================
-- COMMANDE : DEBUG
-- ================================================================================================
RegisterCommand('podiumdebug', function()
    print("^3[Podium Debug]^0 ========================================")
    print("^3[Podium Debug]^0 Version: 3.1.0 (OPTIMISÉ)")
    print("^3[Podium Debug]^0 ========================================")
    print("^3[Podium Debug]^0 Cache:")
    print("  - Distance podium le plus proche: ^2" .. string.format("%.2f", cache.nearestPodiumDist) .. "m^0")
    print("  - À proximité: " .. (cache.isNearPodium and "^2OUI^0" or "^1NON^0"))
    print("^3[Podium Debug]^0 ========================================")
    
    print("^3[Podium Debug]^0 GUNFIGHT - PEDs créés: ^2" .. (next(podiumPeds.gunfight) and #podiumPeds.gunfight or 0))
    for rank, ped in pairs(podiumPeds.gunfight) do
        if DoesEntityExist(ped) then
            local coords = GetEntityCoords(ped)
            local playerInfo = podiumData.gunfight[rank]
            local skinModel = playerInfo and playerInfo.skin and playerInfo.skin.model or "N/A"
            print(string.format("^3[Podium Debug]^0   Rang %d : %s (Model: %s, Pos: %.2f, %.2f, %.2f)", 
                rank, playerInfo and playerInfo.name or "Unknown", skinModel, coords.x, coords.y, coords.z))
        else
            print(string.format("^1[Podium Debug]^0   Rang %d : PED n'existe pas!", rank))
        end
    end
    
    print("^3[Podium Debug]^0 PVP - PEDs créés: ^2" .. (next(podiumPeds.pvp) and #podiumPeds.pvp or 0))
    for rank, ped in pairs(podiumPeds.pvp) do
        if DoesEntityExist(ped) then
            local coords = GetEntityCoords(ped)
            local playerInfo = podiumData.pvp[rank]
            local skinModel = playerInfo and playerInfo.skin and playerInfo.skin.model or "N/A"
            print(string.format("^3[Podium Debug]^0   Rang %d : %s (Model: %s, ELO: %d)", 
                rank, playerInfo and playerInfo.name or "Unknown", skinModel, playerInfo and playerInfo.elo or 0))
        else
            print(string.format("^1[Podium Debug]^0   Rang %d : PED n'existe pas!", rank))
        end
    end
    
    print("^3[Podium Debug]^0 ========================================")
end, false)

-- ================================================================================================
-- COMMANDE : FORCER REFRESH LOCAL
-- ================================================================================================
RegisterCommand('podiumrefresh', function()
    DebugLog("Demande de rafraîchissement des podiums...", "success")
    TriggerServerEvent('gunfightpodium:requestUpdate')
end, false)
