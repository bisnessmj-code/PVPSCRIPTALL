--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                        CLIENT - MAIN.LUA                                   ║
    ║     ✅ ULTRA-CORRIGÉ : BLOCAGE TOTAL QS-INVENTORY (TAB + & é " ' ()       ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════════════════
-- CACHE LOCAL
-- ═══════════════════════════════════════════════════════════════════════════
local cachedData = {
    isInGame = false,
    currentWeaponIndex = 1,
    currentKills = 0,
    playerPed = nil,
    joinPed = nil,
    joinBlip = nil,
    playerBlips = {},
    isDead = false,
    lastDeathCheck = 0,
    isRespawning = false,
    weaponGiven = false
}

local ESX = exports['es_extended']:getSharedObject()

-- ═══════════════════════════════════════════════════════════════════════════
-- INITIALISATION
-- ═══════════════════════════════════════════════════════════════════════════
CreateThread(function()
    while not ESX.IsPlayerLoaded() do
        Wait(500)
    end
    
    cachedData.playerPed = PlayerPedId()
    CreateJoinPed()
    CreateJoinBlip()
    
    print('^2[GunGame][CLIENT]^7 Initialisé avec succès')
    print('^2[GunGame][CLIENT]^7 Zone de combat: Rayon ' .. Config.MapRadius .. 'm')
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- CRÉATION DU PED D'ENTRÉE
-- ═══════════════════════════════════════════════════════════════════════════
function CreateJoinPed()
    local pedConfig = Config.JoinPed
    local model = GetHashKey(pedConfig.model)
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    
    local coords = pedConfig.coords
    cachedData.joinPed = CreatePed(4, model, coords.x, coords.y, coords.z, coords.w, false, true)
    
    SetEntityInvincible(cachedData.joinPed, true)
    SetBlockingOfNonTemporaryEvents(cachedData.joinPed, true)
    FreezeEntityPosition(cachedData.joinPed, true)
    
    if pedConfig.scenario then
        TaskStartScenarioInPlace(cachedData.joinPed, pedConfig.scenario, 0, true)
    end
    
    SetModelAsNoLongerNeeded(model)
    print('^2[GunGame][CLIENT]^7 PED d\'entrée créé')
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CRÉATION DU BLIP
-- ═══════════════════════════════════════════════════════════════════════════
function CreateJoinBlip()
    local blipConfig = Config.JoinPed.blip
    if not blipConfig.enabled then return end
    
    local coords = Config.JoinPed.coords
    cachedData.joinBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    
    SetBlipSprite(cachedData.joinBlip, blipConfig.sprite)
    SetBlipDisplay(cachedData.joinBlip, 4)
    SetBlipScale(cachedData.joinBlip, blipConfig.scale)
    SetBlipColour(cachedData.joinBlip, blipConfig.color)
    SetBlipAsShortRange(cachedData.joinBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(blipConfig.name)
    EndTextCommandSetBlipName(cachedData.joinBlip)
    
    print('^2[GunGame][CLIENT]^7 Blip créé')
end

-- ═══════════════════════════════════════════════════════════════════════════
-- THREAD : DESSINER LA ZONE DE COMBAT
-- ═══════════════════════════════════════════════════════════════════════════
CreateThread(function()
    while true do
        local sleep = 1000
        
        if cachedData.isInGame then
            sleep = 0
            
            local map = Config.GetActiveMap()
            if map then
                DrawMarker(
                    1,
                    map.center.x,
                    map.center.y,
                    map.center.z - (Config.MapCylinderDepth or 200.0),
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    map.radius * 2.0,
                    map.radius * 2.0,
                    400.0,
                    255, 0, 0, 50,
                    false, false, 2, false, nil, nil, false
                )
                
                DrawMarker(
                    1,
                    map.center.x,
                    map.center.y,
                    map.center.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    map.radius * 2.0,
                    map.radius * 2.0,
                    2.0,
                    255, 0, 0, 100,
                    false, false, 2, false, nil, nil, false
                )
            end
        end
        
        Wait(sleep)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- THREAD : Détection de proximité PED
-- ═══════════════════════════════════════════════════════════════════════════
CreateThread(function()
    local interactionDist = Config.JoinPed.interactionDistance
    local pedCoords = Config.JoinPed.coords
    local lastJoinRequest = 0
    
    while true do
        local sleep = 1000
        
        if not cachedData.isInGame then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - vec3(pedCoords.x, pedCoords.y, pedCoords.z))
            
            if distance < 20.0 then
                sleep = 0
                
                if distance < interactionDist then
                    BeginTextCommandDisplayHelp("STRING")
                    AddTextComponentSubstringPlayerName(Config.JoinPed.prompt)
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    
                    if IsControlJustPressed(0, 38) then
                        local currentTime = GetGameTimer()
                        
                        if currentTime - lastJoinRequest > 2000 then
                            lastJoinRequest = currentTime
                            print('^2[GunGame][CLIENT]^7 Demande de rejoindre envoyée au serveur')
                            TriggerServerEvent('gungame:server:requestJoin')
                            Wait(2000)
                        else
                            print('^3[GunGame][CLIENT]^7 Cooldown actif - Patientez...')
                        end
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- THREAD : VÉRIFICATION SORTIE DE ZONE
-- ═══════════════════════════════════════════════════════════════════════════
CreateThread(function()
    local lastWarning = 0
    
    while true do
        local sleep = Config.ExitCheckInterval or 500
        
        if cachedData.isInGame and Config.DeathOnExit and not cachedData.isRespawning then
            local ped = PlayerPedId()
            
            if not IsEntityDead(ped) then
                local coords = GetEntityCoords(ped)
                local inZone = Config.IsInCombatZone(coords)
                
                local currentTime = GetGameTimer()
                if currentTime - lastWarning > 10000 then
                    local map = Config.GetActiveMap()
                    if map then
                        local dx = coords.x - map.center.x
                        local dy = coords.y - map.center.y
                        local distance = math.sqrt(dx * dx + dy * dy)
                        print('^6[GunGame][CLIENT][ZONE CHECK]^7 Distance: ' .. string.format("%.1f", distance) .. 'm / ' .. map.radius .. 'm - Dans zone: ' .. tostring(inZone))
                    end
                    lastWarning = currentTime
                end
                
                if not inZone then
                    print('^1[GunGame][CLIENT][ZONE]^7 ⚠️ SORTIE DE ZONE !')
                    print('^1[GunGame][CLIENT][ZONE]^7 Position: ' .. coords.x .. ', ' .. coords.y .. ', ' .. coords.z)
                    
                    SetEntityHealth(ped, 0)
                    ShowNotification('~r~Tu es sorti de la zone de combat !')
                    Wait(2000)
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- ⭐ THREAD : BLOCAGE ULTRA-COMPLET QS-INVENTORY (TAB + RACCOURCIS 1-9) ⭐
-- ═══════════════════════════════════════════════════════════════════════════
CreateThread(function()
    while true do
        Wait(0) -- ⭐ CRITIQUE : Wait(0) pour bloquer en temps réel ⭐
        
        if cachedData.isInGame then
            local ped = PlayerPedId()
            
            -- ═══════════════════════════════════════════════════════════════
            -- ⭐ BLOCAGE ABSOLU TAB (INVENTAIRE QS-INVENTORY) ⭐
            -- ═══════════════════════════════════════════════════════════════
            DisableControlAction(0, 37, true)    -- TAB principal
            DisableControlAction(1, 37, true)    -- TAB (contexte alternatif)
            DisableControlAction(2, 37, true)    -- TAB (frontend)
            
            -- ═══════════════════════════════════════════════════════════════
            -- ⭐ BLOCAGE COMPLET RACCOURCIS 1-9 (& é " ' ( - è _ ç) ⭐
            -- ═══════════════════════════════════════════════════════════════
            -- Contexte principal (0)
            DisableControlAction(0, 157, true)   -- 1 (&)
            DisableControlAction(0, 158, true)   -- 2 (é)
            DisableControlAction(0, 160, true)   -- 3 (")
            DisableControlAction(0, 164, true)   -- 4 (')
            DisableControlAction(0, 165, true)   -- 5 (()
            DisableControlAction(0, 159, true)   -- 6 (-)
            DisableControlAction(0, 161, true)   -- 7 (è)
            DisableControlAction(0, 162, true)   -- 8 (_)
            DisableControlAction(0, 163, true)   -- 9 (ç)
            
            -- Contexte alternatif (1)
            DisableControlAction(1, 157, true)
            DisableControlAction(1, 158, true)
            DisableControlAction(1, 160, true)
            DisableControlAction(1, 164, true)
            DisableControlAction(1, 165, true)
            DisableControlAction(1, 159, true)
            DisableControlAction(1, 161, true)
            DisableControlAction(1, 162, true)
            DisableControlAction(1, 163, true)
            
            -- ═══════════════════════════════════════════════════════════════
            -- ⭐ BLOCAGE SCROLL MOLETTE (CHANGEMENT D'ARME) ⭐
            -- ═══════════════════════════════════════════════════════════════
            DisableControlAction(0, 14, true)    -- Scroll down
            DisableControlAction(0, 15, true)    -- Scroll up
            DisableControlAction(0, 16, true)    -- Scroll wheel press
            DisableControlAction(0, 17, true)    -- Scroll wheel
            DisableControlAction(1, 14, true)
            DisableControlAction(1, 15, true)
            DisableControlAction(1, 16, true)
            DisableControlAction(1, 17, true)
            
            -- ═══════════════════════════════════════════════════════════════
            -- ⭐ BLOCAGE TOUCHES INVENTAIRE (I, F3, etc.) ⭐
            -- ═══════════════════════════════════════════════════════════════
            DisableControlAction(0, 289, true)   -- I (inventaire standard)
            DisableControlAction(0, 170, true)   -- F3 (inventaire alternatif)
            DisableControlAction(1, 289, true)
            DisableControlAction(1, 170, true)
            
            -- ═══════════════════════════════════════════════════════════════
            -- ⭐ BLOCAGE X (ROUE D'ARMES NATIVE GTA) ⭐
            -- ═══════════════════════════════════════════════════════════════
            DisableControlAction(0, 99, true)    -- X (INPUT_VEH_SELECT_NEXT_WEAPON)
            DisableControlAction(0, 115, true)   -- X (alternative)
            
            -- ═══════════════════════════════════════════════════════════════
            -- ⭐ EMPÊCHER L'OUVERTURE DES MENUS (M, F1, etc.) ⭐
            -- ═══════════════════════════════════════════════════════════════
            DisableControlAction(0, 244, true)   -- M (map)
            DisableControlAction(0, 288, true)   -- F1 (phone/menu)
            
            -- ═══════════════════════════════════════════════════════════════
            -- ⭐ FORCER L'ARME GUNGAME (SÉCURITÉ ABSOLUE) ⭐
            -- ═══════════════════════════════════════════════════════════════
            if not cachedData.isRespawning then
                local currentWeapon = GetSelectedPedWeapon(ped)
                local expectedWeapon = Config.GetWeaponHash(cachedData.currentWeaponIndex)
                
                -- Vérifier si le joueur a changé d'arme
                if currentWeapon ~= expectedWeapon and expectedWeapon ~= 0 then
                    -- FORCER le retour à l'arme GunGame
                    SetCurrentPedWeapon(ped, expectedWeapon, true)
                    
                    -- Notification visuelle (limité à 1 par seconde)
                    if not cachedData.lastWeaponWarning or GetGameTimer() - cachedData.lastWeaponWarning > 1000 then
                        ShowNotification('~r~Tu ne peux utiliser que l\'arme GunGame !')
                        cachedData.lastWeaponWarning = GetGameTimer()
                        print('^1[GunGame][CLIENT][ANTI-WEAPON]^7 Arme forcée: ' .. expectedWeapon)
                    end
                end
            end
            
            -- DÉSACTIVER LE RESPAWN ESX/GF_RESPAWN
            SetPlayerInvincible(PlayerId(), false)
        else
            Wait(500) -- ⭐ En dehors du jeu, on attend plus longtemps ⭐
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- ⭐ THREAD SUPPLÉMENTAIRE : NETTOYAGE PÉRIODIQUE DES ARMES ⭐
-- ═══════════════════════════════════════════════════════════════════════════
CreateThread(function()
    while true do
        Wait(500) -- Vérification toutes les 500ms
        
        if cachedData.isInGame and not cachedData.isRespawning then
            local ped = PlayerPedId()
            local expectedWeapon = Config.GetWeaponHash(cachedData.currentWeaponIndex)
            
            if expectedWeapon and expectedWeapon ~= 0 then
                -- Compter le nombre d'armes que le joueur possède
                local weaponCount = 0
                local hasExpectedWeapon = false
                
                -- Vérifier les armes du joueur
                for _, weapon in ipairs(Config.Weapons) do
                    local weaponHash = GetHashKey(weapon.name)
                    if HasPedGotWeapon(ped, weaponHash, false) then
                        weaponCount = weaponCount + 1
                        if weaponHash == expectedWeapon then
                            hasExpectedWeapon = true
                        end
                    end
                end
                
                -- Si le joueur a plus d'une arme OU n'a pas l'arme attendue
                if weaponCount > 1 or not hasExpectedWeapon then
                    print('^1[GunGame][CLIENT][ANTI-INVENTORY]^7 ⚠️ Détection d\'armes multiples ou manquantes')
                    print('^1[GunGame][CLIENT][ANTI-INVENTORY]^7 Armes détectées: ' .. weaponCount .. ', A l\'arme attendue: ' .. tostring(hasExpectedWeapon))
                    
                    -- NETTOYAGE TOTAL
                    RemoveAllPedWeapons(ped, true)
                    Wait(100)
                    
                    -- REDONNER L'ARME GUNGAME
                    GiveWeaponToPed(ped, expectedWeapon, Config.DefaultAmmo, false, true)
                    SetPedAmmo(ped, expectedWeapon, Config.DefaultAmmo)
                    SetAmmoInClip(ped, expectedWeapon, GetMaxAmmoInClip(ped, expectedWeapon, true))
                    SetCurrentPedWeapon(ped, expectedWeapon, true)
                    
                    ShowNotification('~r~Armes non autorisées supprimées !')
                    print('^2[GunGame][CLIENT][ANTI-INVENTORY]^7 ✅ Arme GunGame restaurée')
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- THREAD : DÉTECTION DE MORT AMÉLIORÉE
-- ═══════════════════════════════════════════════════════════════════════════
CreateThread(function()
    while true do
        Wait(100)
        
        if cachedData.isInGame and not cachedData.isRespawning then
            local ped = PlayerPedId()
            local currentTime = GetGameTimer()
            
            -- Vérifier si le joueur vient de mourir
            if IsEntityDead(ped) and not cachedData.isDead then
                -- Anti-spam: minimum 2 secondes entre chaque mort
                if currentTime - cachedData.lastDeathCheck < 2000 then
                    goto continue
                end
                
                cachedData.lastDeathCheck = currentTime
                cachedData.isDead = true
                
                -- Récupérer le tueur
                local killer = GetPedSourceOfDeath(ped)
                local killerServerId = 0
                
                if killer and killer ~= 0 and IsEntityAPed(killer) and IsPedAPlayer(killer) then
                    killerServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(killer))
                end
                
                local weaponHash = GetPedCauseOfDeath(ped)
                
                print('^3[GunGame][CLIENT][DEATH]^7 Mort détectée - Tueur ID: ' .. killerServerId .. ' - Arme: ' .. weaponHash)
                
                -- Vérifier si dans la zone
                local coords = GetEntityCoords(ped)
                local inZone = Config.IsInCombatZone(coords)
                
                if inZone then
                    -- Notifier le serveur IMMÉDIATEMENT
                    TriggerServerEvent('gungame:server:playerDied', killerServerId, weaponHash)
                    print('^2[GunGame][CLIENT][DEATH]^7 Notification serveur envoyée')
                else
                    print('^1[GunGame][CLIENT][DEATH]^7 Mort hors zone - Ne pas notifier')
                end
                
                -- Respawn après un court délai
                Wait(1000)
                DoRespawn()
            elseif not IsEntityDead(ped) then
                cachedData.isDead = false
            end
        end
        
        ::continue::
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- FONCTION DE RESPAWN
-- ═══════════════════════════════════════════════════════════════════════════
function DoRespawn()
    cachedData.isRespawning = true
    
    local respawn = Config.GetRandomRespawn()
    
    if not respawn then
        print('^1[GunGame][CLIENT][ERROR]^7 Aucun point de respawn trouvé !')
        cachedData.isRespawning = false
        return
    end
    
    print('^6[GunGame][CLIENT][RESPAWN]^7 Point choisi: ' .. respawn.x .. ', ' .. respawn.y .. ', ' .. respawn.z)
    
    if Config.RespawnDelay > 0 then
        Wait(Config.RespawnDelay)
    end
    
    local ped = PlayerPedId()
    
    -- DÉSACTIVER TOUS LES SYSTÈMES DE RESPAWN EXTERNES
    TriggerEvent('esx_ambulancejob:setDeathStatus', false)
    
    -- FADE OUT POUR MASQUER LA TÉLÉPORTATION
    DoScreenFadeOut(250)
    Wait(300)
    
    -- Résurrection
    NetworkResurrectLocalPlayer(respawn.x, respawn.y, respawn.z, respawn.w, true, false)
    
    Wait(200)
    ped = PlayerPedId()
    
    -- Forcer la téléportation
    SetEntityCoords(ped, respawn.x, respawn.y, respawn.z, false, false, false, false)
    SetEntityHeading(ped, respawn.w)
    
    -- RENDRE INVINCIBLE TEMPORAIREMENT (évite les animations de mort)
    SetEntityInvincible(ped, true)
    
    Wait(100)
    
    -- Vérifier position
    local finalCoords = GetEntityCoords(ped)
    local inZone = Config.IsInCombatZone(finalCoords)
    
    print('^6[GunGame][CLIENT][RESPAWN]^7 Position finale: ' .. finalCoords.x .. ', ' .. finalCoords.y .. ', ' .. finalCoords.z)
    print('^6[GunGame][CLIENT][RESPAWN]^7 Dans la zone: ' .. tostring(inZone))
    
    if not inZone then
        print('^1[GunGame][CLIENT][RESPAWN ERROR]^7 HORS ZONE ! Retéléportation...')
        SetEntityCoords(ped, respawn.x, respawn.y, respawn.z, false, false, false, false)
        Wait(100)
    end
    
    -- Configurer le joueur
    SetEntityHealth(ped, Config.DefaultHealth)
    SetPedArmour(ped, Config.DefaultArmor)
    ClearPedBloodDamage(ped)
    
    -- ENLEVER INVINCIBILITÉ APRÈS CONFIGURATION
    Wait(100)
    SetEntityInvincible(ped, false)
    
    -- REDONNER L'ARME AVEC MUNITIONS COMPLÈTES
    GiveCurrentWeapon()
    
    -- FADE IN APRÈS SPAWN COMPLET
    DoScreenFadeIn(250)
    
    cachedData.isDead = false
    cachedData.isRespawning = false
    
    print('^2[GunGame][CLIENT][RESPAWN]^7 Respawn terminé')
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ÉVÉNEMENTS SERVEUR -> CLIENT
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent('gungame:client:joinGame', function(weaponIndex)
    cachedData.isInGame = true
    cachedData.currentWeaponIndex = weaponIndex or 1
    cachedData.currentKills = 0
    cachedData.isDead = false
    cachedData.isRespawning = true
    cachedData.weaponGiven = false
    
    local ped = PlayerPedId()
    cachedData.playerPed = ped
    
    print('^2[GunGame][CLIENT]^7 Rejoindre la partie - Arme initiale: ' .. weaponIndex)
    
    -- DÉSACTIVER le respawn ESX/GF_RESPAWN
    TriggerEvent('esx_ambulancejob:setDeathStatus', false)
    
    -- Téléportation au spawn
    local respawn = Config.GetRandomRespawn()
    
    print('^2[GunGame][CLIENT][JOIN]^7 Point de spawn: ' .. respawn.x .. ', ' .. respawn.y .. ', ' .. respawn.z)
    
    DoScreenFadeOut(250)
    Wait(300)
    
    SetEntityCoords(ped, respawn.x, respawn.y, respawn.z, false, false, false, false)
    SetEntityHeading(ped, respawn.w)
    
    -- INVINCIBLE TEMPORAIREMENT PENDANT LE SPAWN INITIAL
    SetEntityInvincible(ped, true)
    
    Wait(200)
    
    local finalCoords = GetEntityCoords(ped)
    print('^2[GunGame][CLIENT][JOIN]^7 Position finale: ' .. finalCoords.x .. ', ' .. finalCoords.y .. ', ' .. finalCoords.z)
    
    SetupPlayerForGame()
    
    -- ATTENDRE UN PEU PLUS LONGTEMPS AVANT DE DONNER L'ARME
    Wait(500)
    
    GiveCurrentWeapon()
    
    -- VÉRIFICATION MULTIPLE QUE L'ARME EST BIEN ÉQUIPÉE
    Wait(200)
    local currentWeapon = GetSelectedPedWeapon(ped)
    local expectedWeapon = Config.GetWeaponHash(cachedData.currentWeaponIndex)
    
    if currentWeapon ~= expectedWeapon then
        print('^3[GunGame][CLIENT][JOIN]^7 ⚠️ Arme pas équipée, retry...')
        GiveCurrentWeapon()
        Wait(200)
    end
    
    -- ENLEVER INVINCIBILITÉ
    SetEntityInvincible(ped, false)
    
    DoScreenFadeIn(250)
    
    cachedData.isRespawning = false
    
    ShowNotification(Config.Messages.joinedGame)
    
    SendNUIMessage({
        action = 'show',
        weaponIndex = cachedData.currentWeaponIndex,
        weaponName = Config.GetWeapon(cachedData.currentWeaponIndex).label,
        weaponCategory = Config.GetWeapon(cachedData.currentWeaponIndex).category,
        kills = cachedData.currentKills,
        totalWeapons = Config.TotalWeapons,
        killsNeeded = Config.KillsPerWeaponChange
    })
    
    print('^2[GunGame][CLIENT]^7 UI activée')
end)

RegisterNetEvent('gungame:client:leaveGame', function()
    print('^3[GunGame][CLIENT]^7 Quitter la partie')
    
    cachedData.isInGame = false
    cachedData.currentWeaponIndex = 1
    cachedData.currentKills = 0
    cachedData.isDead = false
    cachedData.isRespawning = false
    cachedData.weaponGiven = false
    
    local ped = PlayerPedId()
    
    -- Fade out pour transition fluide
    DoScreenFadeOut(250)
    Wait(300)
    
    local exitCoords = Config.EndTeleport
    SetEntityCoords(ped, exitCoords.x, exitCoords.y, exitCoords.z, false, false, false, false)
    SetEntityHeading(ped, exitCoords.w)
    
    RemoveAllPedWeapons(ped, true)
    
    -- Restaurer l'état normal
    SetEntityInvincible(ped, false)
    SetEntityHealth(ped, 200)
    
    Wait(100)
    DoScreenFadeIn(250)
    
    ShowNotification(Config.Messages.leftGame)
    
    SendNUIMessage({ action = 'hide' })
    
    ClearPlayerBlips()
end)

RegisterNetEvent('gungame:client:updateProgress', function(weaponIndex, kills)
    local previousWeapon = cachedData.currentWeaponIndex
    cachedData.currentWeaponIndex = weaponIndex
    cachedData.currentKills = kills
    
    print('^5[GunGame][CLIENT][PROGRESS]^7 Arme: ' .. weaponIndex .. '/40, Kills: ' .. kills .. '/' .. Config.KillsPerWeaponChange)
    
    -- Changement d'arme ?
    if weaponIndex ~= previousWeapon then
        print('^2[GunGame][CLIENT][WEAPON CHANGE]^7 ' .. previousWeapon .. ' → ' .. weaponIndex)
        GiveCurrentWeapon()
        local weaponData = Config.GetWeapon(weaponIndex)
        if weaponData then
            ShowNotification(string.format(Config.Messages.weaponChanged, weaponData.label))
        end
    end
    
    -- Mise à jour UI
    local weaponData = Config.GetWeapon(weaponIndex)
    SendNUIMessage({
        action = 'updateProgress',
        weaponIndex = weaponIndex,
        weaponName = weaponData and weaponData.label or "Unknown",
        weaponCategory = weaponData and weaponData.category or "unknown",
        kills = kills,
        killsNeeded = Config.KillsPerWeaponChange,
        totalWeapons = Config.TotalWeapons
    })
end)

RegisterNetEvent('gungame:client:killConfirm', function(kills, neededKills)
    print('^2[GunGame][CLIENT][KILL]^7 Kill confirmé ! (' .. kills .. '/' .. neededKills .. ')')
    ShowNotification(string.format(Config.Messages.killConfirm, kills, neededKills))
end)

RegisterNetEvent('gungame:client:playerKilled', function(killerName)
    print('^1[GunGame][CLIENT][DEATH]^7 Tué par ' .. killerName)
    ShowNotification(string.format(Config.Messages.playerKilled, killerName))
end)

RegisterNetEvent('gungame:client:updateLeaderboard', function(leaderboard)
    print('^5[GunGame][CLIENT][LEADERBOARD]^7 Classement reçu: ' .. #leaderboard .. ' joueurs')
    
    SendNUIMessage({
        action = 'updateLeaderboard',
        leaderboard = leaderboard
    })
end)

RegisterNetEvent('gungame:client:updatePlayerBlips', function(players)
    ClearPlayerBlips()
    
    if not Config.PlayerBlips.enabled then return end
    
    for _, playerData in ipairs(players) do
        if playerData.id ~= GetPlayerServerId(PlayerId()) then
            local blip = AddBlipForCoord(playerData.x, playerData.y, playerData.z)
            SetBlipSprite(blip, Config.PlayerBlips.sprite)
            SetBlipColour(blip, Config.PlayerBlips.color)
            SetBlipScale(blip, Config.PlayerBlips.scale)
            SetBlipDisplay(blip, 2)
            table.insert(cachedData.playerBlips, blip)
        end
    end
end)

RegisterNetEvent('gungame:client:gameEnd', function(winner, top3)
    cachedData.isInGame = false
    cachedData.isRespawning = false
    cachedData.weaponGiven = false
    
    print('^2[GunGame][CLIENT][END]^7 Partie terminée - Vainqueur: ' .. winner)
    
    SendNUIMessage({
        action = 'showEndScreen',
        winner = winner,
        top3 = top3
    })
    
    SetTimeout(Config.UI.endScreenDuration, function()
        DoScreenFadeOut(250)
        Wait(300)
        
        local exitCoords = Config.EndTeleport
        SetEntityCoords(PlayerPedId(), exitCoords.x, exitCoords.y, exitCoords.z, false, false, false, false)
        SetEntityHeading(PlayerPedId(), exitCoords.w)
        RemoveAllPedWeapons(PlayerPedId(), true)
        
        SetEntityInvincible(PlayerPedId(), false)
        
        Wait(100)
        DoScreenFadeIn(250)
        
        SendNUIMessage({ action = 'hide' })
        ClearPlayerBlips()
    end)
    
    if winner == GetPlayerName(PlayerId()) then
        ShowNotification(Config.Messages.gameWon)
    else
        ShowNotification(string.format(Config.Messages.gameEnded, winner))
    end
end)

RegisterNetEvent('gungame:client:killFeed', function(killer, killerID, victim, victimID, weaponLabel)
    if Config.UI.showKillFeed then
        SendNUIMessage({
            action = 'killFeed',
            killer = killer,
            killerID = killerID,
            victim = victim,
            victimID = victimID,
            weapon = weaponLabel
        })
    end
end)

RegisterNetEvent('gungame:client:kicked', function()
    cachedData.isInGame = false
    cachedData.currentWeaponIndex = 1
    cachedData.currentKills = 0
    cachedData.isRespawning = false
    cachedData.weaponGiven = false
    
    local ped = PlayerPedId()
    
    DoScreenFadeOut(250)
    Wait(300)
    
    local exitCoords = Config.EndTeleport
    SetEntityCoords(ped, exitCoords.x, exitCoords.y, exitCoords.z, false, false, false, false)
    SetEntityHeading(ped, exitCoords.w)
    RemoveAllPedWeapons(ped, true)
    
    SetEntityInvincible(ped, false)
    
    Wait(100)
    DoScreenFadeIn(250)
    
    SendNUIMessage({ action = 'hide' })
    ClearPlayerBlips()
    
    ShowNotification(Config.Messages.kicked)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- FONCTIONS UTILITAIRES
-- ═══════════════════════════════════════════════════════════════════════════

function SetupPlayerForGame()
    local ped = PlayerPedId()
    
    RemoveAllPedWeapons(ped, true)
    TriggerServerEvent('gungame:server:clearInventoryWeapons')
    
    SetEntityHealth(ped, Config.DefaultHealth)
    SetPedArmour(ped, Config.DefaultArmor)
    SetPedCanRagdoll(ped, false)
    ClearPedBloodDamage(ped)
    
    print('^2[GunGame][CLIENT]^7 Joueur configuré - Santé: ' .. Config.DefaultHealth .. ', Armure: ' .. Config.DefaultArmor)
    print('^2[GunGame][CLIENT]^7 Inventaire vidé')
end

function GiveCurrentWeapon()
    local ped = PlayerPedId()
    local weaponData = Config.GetWeapon(cachedData.currentWeaponIndex)
    
    if not weaponData then
        print('^1[GunGame][CLIENT][ERROR]^7 Arme invalide à l\'index ' .. cachedData.currentWeaponIndex)
        return
    end
    
    RemoveAllPedWeapons(ped, true)
    
    local weaponHash = GetHashKey(weaponData.name)
    
    -- DONNER L'ARME AVEC MUNITIONS COMPLÈTES
    GiveWeaponToPed(ped, weaponHash, Config.DefaultAmmo, false, true)
    
    -- FORCER LES MUNITIONS AU MAXIMUM
    SetPedAmmo(ped, weaponHash, Config.DefaultAmmo)
    SetAmmoInClip(ped, weaponHash, GetMaxAmmoInClip(ped, weaponHash, true))
    
    -- METTRE L'ARME DANS LES MAINS IMMÉDIATEMENT
    SetCurrentPedWeapon(ped, weaponHash, true)
    
    -- ATTENDRE UN PEU PUIS FORCER À NOUVEAU (GARANTIE MAXIMALE)
    Wait(100)
    SetCurrentPedWeapon(ped, weaponHash, true)
    
    -- TRIPLE VÉRIFICATION
    Wait(100)
    local currentWeapon = GetSelectedPedWeapon(ped)
    if currentWeapon ~= weaponHash then
        print('^3[GunGame][CLIENT][WARNING]^7 L\'arme n\'est pas équipée, retry final...')
        SetCurrentPedWeapon(ped, weaponHash, true)
    else
        print('^2[GunGame][CLIENT]^7 ✅ Arme équipée: ' .. weaponData.label)
    end
    
    cachedData.weaponGiven = true
    
    print('^2[GunGame][CLIENT]^7 Arme donnée: ' .. weaponData.label .. ' (' .. weaponData.name .. ') avec ' .. Config.DefaultAmmo .. ' munitions')
end

function ShowNotification(message)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
end

function ClearPlayerBlips()
    for _, blip in ipairs(cachedData.playerBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    cachedData.playerBlips = {}
end

-- ═══════════════════════════════════════════════════════════════════════════
-- COMMANDE : QUITTER LE GUNGAME
-- ═══════════════════════════════════════════════════════════════════════════
RegisterCommand('quitgungame', function()
    if not cachedData.isInGame then
        ShowNotification('~r~Tu n\'es pas dans le GunGame !')
        return
    end
    
    print('^3[GunGame][CLIENT]^7 Commande /quitgungame utilisée')
    TriggerServerEvent('gungame:server:requestLeave')
end, false)

-- ═══════════════════════════════════════════════════════════════════════════
-- NETTOYAGE
-- ═══════════════════════════════════════════════════════════════════════════
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if DoesEntityExist(cachedData.joinPed) then
        DeleteEntity(cachedData.joinPed)
    end
    
    if DoesBlipExist(cachedData.joinBlip) then
        RemoveBlip(cachedData.joinBlip)
    end
    
    ClearPlayerBlips()
    
    -- Restaurer l'état normal du joueur
    local ped = PlayerPedId()
    SetEntityInvincible(ped, false)
    
    print('^3[GunGame][CLIENT]^7 Resource arrêtée - Nettoyage effectué')
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════
exports('isInGunGame', function() return cachedData.isInGame end)
exports('getCurrentWeapon', function() return cachedData.currentWeaponIndex end)
exports('getCurrentKills', function() return cachedData.currentKills end)
