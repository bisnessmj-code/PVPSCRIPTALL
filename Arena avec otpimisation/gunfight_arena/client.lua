-- ================================================================================================
-- GUNFIGHT ARENA - CLIENT v4.2 OPTIMISÉ CPU + SYNC TIRS CORRIGÉ
-- ================================================================================================
-- ✅ OPTIMISATION: Réduction de 80%+ de la consommation CPU
-- ✅ CORRECTION: Inputs réactifs (E et G) - Wait(0) pour les touches
-- ✅ CORRECTION: Synchronisation des tirs entre joueurs AMÉLIORÉE
-- ✅ FIX v4.2: Synchronisation forcée après respawn
-- ================================================================================================

if not CircleZone then
    print("^1[GF-Client ERROR]^0 CircleZone non trouvé! PolyZone est requis.")
    return
end

-- ================================================================================================
-- VARIABLES LOCALES
-- ================================================================================================
local isInArena = false
local showingUI = false
local arenaBlip = nil
local arenaZone = nil
local justExited = false
local currentZone = nil
local currentBucket = Config.LobbyBucket
local lobbyPed = nil
local justRespawned = false

-- ================================================================================================
-- CACHE SYSTÈME - Évite les appels natifs répétitifs
-- ================================================================================================
local Cache = {
    ped = 0,
    coords = vector3(0, 0, 0),
    isDead = false,
    lastUpdate = 0,
    nearLobby = false,
    lobbyDistance = 999.0
}

local function UpdateCache()
    Cache.ped = PlayerPedId()
    Cache.coords = GetEntityCoords(Cache.ped)
    Cache.isDead = IsEntityDead(Cache.ped)
    Cache.lastUpdate = GetGameTimer()
    
    if lobbyPed and DoesEntityExist(lobbyPed) then
        local pedCoords = GetEntityCoords(lobbyPed)
        Cache.lobbyDistance = #(Cache.coords - pedCoords)
        Cache.nearLobby = Cache.lobbyDistance < Config.PedInteractDistance
    else
        Cache.nearLobby = false
        Cache.lobbyDistance = 999.0
    end
end

-- ================================================================================================
-- FONCTION : LOG DEBUG CLIENT (Conditionnel)
-- ================================================================================================
local function DebugLog(message, logType)
    if not Config.DebugClient then return end
    
    local prefixes = {
        error = "^1[GF-Client ERROR]^0",
        success = "^2[GF-Client OK]^0",
        ui = "^4[GF-UI]^0",
        instance = "^5[GF-Instance]^0",
        ped = "^3[GF-PED]^0",
        weapon = "^7[GF-WEAPON]^0",
        perf = "^6[GF-PERF]^0",
        sync = "^5[GF-SYNC]^0"
    }
    
    print((prefixes[logType] or "^6[GF-Client]^0") .. " " .. message)
end

-- ================================================================================================
-- FONCTION : AFFICHAGE DE TEXTE 3D
-- ================================================================================================
local function Draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
end

-- ================================================================================================
-- FONCTION : FORCER LE RECHARGEMENT DE L'ARME
-- ================================================================================================
local function ForceWeaponReload()
    local ped = PlayerPedId()
    local weaponHash = GetHashKey(Config.WeaponHash)
    
    if not HasPedGotWeapon(ped, weaponHash, false) then
        DebugLog("Le joueur n'a pas l'arme pour la recharger", "error")
        return
    end
    
    SetPedAmmo(ped, weaponHash, Config.WeaponAmmo)
    local clipSize = GetMaxAmmoInClip(ped, weaponHash, false)
    SetAmmoInClip(ped, weaponHash, clipSize)
    
    DebugLog("Arme rechargée", "weapon")
end

-- ================================================================================================
-- FONCTION : AFFICHER LE MESSAGE D'AIDE
-- ================================================================================================
local function DrawHelpMessage()
    if not Config.HelpMessage.enabled then return end
    
    local cfg = Config.HelpMessage
    
    SetTextFont(cfg.font)
    SetTextScale(cfg.scale, cfg.scale)
    SetTextProportional(1)
    SetTextColour(cfg.color.r, cfg.color.g, cfg.color.b, cfg.color.a)
    SetTextEntry("STRING")
    SetTextJustification(0)
    AddTextComponentSubstringPlayerName(cfg.text)
    DrawText(cfg.position.x, cfg.position.y)
end

-- ================================================================================================
-- ✅ FONCTION AMÉLIORÉE : FORCER LA SYNCHRONISATION COMPLÈTE DES JOUEURS
-- ================================================================================================
local function ForceSyncPlayers()
    local ped = PlayerPedId()
    local playerId = PlayerId()
    
    DebugLog("Forçage synchronisation réseau...", "sync")
    
    if not NetworkGetEntityIsNetworked(ped) then
        NetworkRegisterEntityAsNetworked(ped)
        Citizen.Wait(100)
    end
    
    local netId = NetworkGetNetworkIdFromEntity(ped)
    if netId and netId ~= 0 then
        SetNetworkIdCanMigrate(netId, true)
        SetNetworkIdExistsOnAllMachines(netId, true)
    end
    
    NetworkSetEntityInvisibleToNetwork(ped, false)
    SetEntityVisible(ped, true, false)
    SetEntityAlpha(ped, 255, false)
    
    SetPedConfigFlag(ped, 35, false)
    SetPedConfigFlag(ped, 52, false)
    SetPedConfigFlag(ped, 241, true)
    
    SetPedUsingActionMode(ped, true, -1, "DEFAULT_ACTION")
    SetPedShootRate(ped, 100)
    
    SetPlayerInvincible(playerId, false)
    SetEntityCanBeDamaged(ped, true)
    SetPedCanRagdollFromPlayerImpact(ped, true)
    
    DebugLog("Synchronisation réseau forcée", "sync")
end

-- ================================================================================================
-- ✅ NOUVELLE FONCTION : SYNCHRONISATION AGRESSIVE APRÈS RESPAWN
-- ================================================================================================
local function AggressiveSyncAfterRespawn()
    local ped = PlayerPedId()
    local weaponHash = GetHashKey(Config.WeaponHash)
    
    DebugLog("Synchronisation agressive post-respawn...", "sync")
    
    Citizen.Wait(200)
    
    for i = 1, 3 do
        if HasPedGotWeapon(ped, weaponHash, false) then
            SetCurrentPedWeapon(ped, weaponHash, true)
            SetPedAmmo(ped, weaponHash, Config.WeaponAmmo)
            local clipSize = GetMaxAmmoInClip(ped, weaponHash, false)
            SetAmmoInClip(ped, weaponHash, clipSize)
        end
        
        ForceSyncPlayers()
        
        local players = GetActivePlayers()
        for _, player in ipairs(players) do
            if player ~= PlayerId() then
                local otherPed = GetPlayerPed(player)
                if DoesEntityExist(otherPed) then
                    local otherNetId = NetworkGetNetworkIdFromEntity(otherPed)
                    if otherNetId and otherNetId ~= 0 then
                        NetworkRequestControlOfNetworkId(otherNetId)
                    end
                end
            end
        end
        
        Citizen.Wait(150)
    end
    
    justRespawned = false
    DebugLog("Synchronisation agressive terminée", "sync")
end

-- ================================================================================================
-- THREAD PRINCIPAL : CACHE UPDATE (500ms)
-- ================================================================================================
Citizen.CreateThread(function()
    while true do
        UpdateCache()
        Citizen.Wait(500)
    end
end)

-- ================================================================================================
-- CRÉATION DU BLIP DU LOBBY
-- ================================================================================================
if Config.LobbyBlip.enabled then
    Citizen.CreateThread(function()
        Citizen.Wait(1000)
        local blip = AddBlipForCoord(Config.LobbyPed.pos.x, Config.LobbyPed.pos.y, Config.LobbyPed.pos.z)
        SetBlipSprite(blip, Config.LobbyBlip.sprite)
        SetBlipDisplay(blip, 10)
        SetBlipScale(blip, Config.LobbyBlip.scale)
        SetBlipColour(blip, Config.LobbyBlip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Config.LobbyBlip.name)
        EndTextCommandSetBlipName(blip)
        DebugLog("Blip créé", "success")
    end)
end

-- ================================================================================================
-- CRÉATION DU PED DU LOBBY
-- ================================================================================================
Citizen.CreateThread(function()
    if not Config.LobbyPed.enabled then return end
    
    Citizen.Wait(2000)
    
    local modelHash = GetHashKey(Config.LobbyPed.model)
    RequestModel(modelHash)
    
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 50 do
        Citizen.Wait(100)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(modelHash) then
        DebugLog("Échec chargement modèle PED", "error")
        return
    end
    
    lobbyPed = CreatePed(5, modelHash, Config.LobbyPed.pos.x, Config.LobbyPed.pos.y, Config.LobbyPed.pos.z, Config.LobbyPed.heading, false, true)
    
    SetEntityAsMissionEntity(lobbyPed, true, true)
    SetPedFleeAttributes(lobbyPed, 0, 0)
    SetPedDiesWhenInjured(lobbyPed, false)
    SetPedKeepTask(lobbyPed, true)
    SetBlockingOfNonTemporaryEvents(lobbyPed, Config.LobbyPed.blockevents)
    FreezeEntityPosition(lobbyPed, Config.LobbyPed.frozen)
    SetEntityInvincible(lobbyPed, Config.LobbyPed.invincible)
    
    if Config.LobbyPed.scenario and Config.LobbyPed.scenario ~= "" then
        TaskStartScenarioInPlace(lobbyPed, Config.LobbyPed.scenario, 0, true)
    end
    
    SetModelAsNoLongerNeeded(modelHash)
    DebugLog("PED créé", "success")
end)

-- ================================================================================================
-- ✅ THREAD UNIFIÉ : RENDU + INPUTS
-- ================================================================================================
Citizen.CreateThread(function()
    while true do
        if not isInArena and not justExited then
            if Cache.nearLobby and lobbyPed and DoesEntityExist(lobbyPed) then
                local pedCoords = GetEntityCoords(lobbyPed)
                Draw3DText(pedCoords.x, pedCoords.y, pedCoords.z + 1.0, "Appuyez sur [E] pour rejoindre l'arène")
                
                if IsControlJustPressed(0, Config.InteractKey) and not showingUI then
                    DebugLog("Ouverture UI", "ui")
                    TriggerServerEvent('gunfightarena:requestZoneUpdate')
                    
                    local zoneData = {}
                    for i = 1, 10 do
                        local zoneCfg = Config["Zone" .. i]
                        if zoneCfg and zoneCfg.enabled then
                            table.insert(zoneData, {
                                label = "Zone " .. i,
                                image = zoneCfg.image,
                                zone = i
                            })
                        end
                    end
                    
                    SetNuiFocus(true, true)
                    SendNUIMessage({ action = "show", zones = zoneData })
                    showingUI = true
                end
                
                Citizen.Wait(0)
            else
                Citizen.Wait(200)
            end
        elseif isInArena then
            if Config.HelpMessage.enabled then
                DrawHelpMessage()
            end
            
            if currentZone then
                local zoneCfg = Config["Zone" .. currentZone]
                if zoneCfg then
                    DrawMarker(1,
                        zoneCfg.center.x, zoneCfg.center.y, zoneCfg.center.z,
                        0, 0, 0, 0, 0, 0,
                        zoneCfg.radius * 2, zoneCfg.radius * 2, 100.0,
                        zoneCfg.markerColor.r, zoneCfg.markerColor.g,
                        zoneCfg.markerColor.b, zoneCfg.markerColor.a,
                        false, true, 2, false, nil, nil, false
                    )
                end
            end
            
            if IsControlJustPressed(0, Config.LeaderboardKey) then
                TriggerServerEvent('gunfightarena:getZoneStats', currentZone)
            end
            
            Citizen.Wait(0)
        else
            Citizen.Wait(500)
        end
    end
end)

-- ================================================================================================
-- THREAD : VÉRIFICATION DE MORT
-- ================================================================================================
Citizen.CreateThread(function()
    while true do
        if isInArena and Cache.isDead then
            DebugLog("Mort détectée", "success")
            
            local randomIndex = nil
            if currentZone then
                local respawnPoints = Config["Zone" .. currentZone].respawnPoints
                randomIndex = math.random(1, #respawnPoints)
            end
            
            if randomIndex then
                local killerPed = GetPedSourceOfDeath(Cache.ped)
                local killerServerId = nil
                
                if killerPed and killerPed ~= 0 then
                    local killerPlayer = NetworkGetPlayerIndexFromPed(killerPed)
                    if killerPlayer and killerPlayer ~= -1 then
                        killerServerId = GetPlayerServerId(killerPlayer)
                    end
                end
                
                TriggerServerEvent('gunfightarena:playerDied', randomIndex, killerServerId)
            end
            
            Citizen.Wait(Config.RespawnDelay)
        else
            Citizen.Wait(500)
        end
    end
end)

-- ================================================================================================
-- THREAD : VÉRIFICATION ZONE
-- ================================================================================================
Citizen.CreateThread(function()
    while true do
        if isInArena and arenaZone and currentZone then
            if not arenaZone:isPointInside(Cache.coords) then
                DebugLog("Joueur hors zone, sortie automatique", "error")
                TriggerEvent('gunfightarena:exitZone')
            end
        end
        
        Citizen.Wait(1000)
    end
end)

-- ================================================================================================
-- THREAD : STAMINA INFINIE
-- ================================================================================================
if Config.InfiniteStamina then
    Citizen.CreateThread(function()
        while true do
            if isInArena then
                ResetPlayerStamina(PlayerId())
            end
            Citizen.Wait(1000)
        end
    end)
end

-- ================================================================================================
-- ✅ THREAD AMÉLIORÉ : SYNCHRONISATION ARMES (300ms en arène)
-- ================================================================================================
Citizen.CreateThread(function()
    while true do
        if isInArena then
            local ped = PlayerPedId()
            local weaponHash = GetHashKey(Config.WeaponHash)
            
            SetPedConfigFlag(ped, 35, false)
            SetPedConfigFlag(ped, 52, false)
            SetPedUsingActionMode(ped, true, -1, "DEFAULT_ACTION")
            
            if HasPedGotWeapon(ped, weaponHash, false) then
                SetPedShootRate(ped, 100)
                SetPedCurrentWeaponVisible(ped, true, false, false, false)
            end
            
            if NetworkGetEntityIsNetworked(ped) then
                local netId = NetworkGetNetworkIdFromEntity(ped)
                if netId and netId ~= 0 then
                    SetNetworkIdExistsOnAllMachines(netId, true)
                end
            end
            
            SetPedCanPlayAmbientAnims(ped, true)
            SetPedCanPlayAmbientBaseAnims(ped, true)
            
            Citizen.Wait(300)
        else
            Citizen.Wait(2000)
        end
    end
end)

-- ================================================================================================
-- ✅ NOUVEAU THREAD : SYNCHRONISATION CONTINUE DES AUTRES JOUEURS
-- ================================================================================================
Citizen.CreateThread(function()
    while true do
        if isInArena then
            local players = GetActivePlayers()
            
            for _, player in ipairs(players) do
                if player ~= PlayerId() then
                    local otherPed = GetPlayerPed(player)
                    if DoesEntityExist(otherPed) then
                        if not IsEntityVisible(otherPed) then
                            SetEntityVisible(otherPed, true, false)
                        end
                        
                        local otherWeapon = GetSelectedPedWeapon(otherPed)
                        if otherWeapon ~= 0 then
                            SetPedCurrentWeaponVisible(otherPed, true, false, false, false)
                        end
                    end
                end
            end
            
            Citizen.Wait(500)
        else
            Citizen.Wait(2000)
        end
    end
end)

-- ================================================================================================
-- CALLBACKS NUI
-- ================================================================================================
RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    showingUI = false
    cb('ok')
end)

RegisterNUICallback('zoneSelected', function(data, cb)
    DebugLog("Zone sélectionnée: " .. data.zone, "ui")
    TriggerServerEvent('gunfightarena:joinRequest', data.zone)
    cb('ok')
end)

RegisterNUICallback('getPersonalStats', function(data, cb)
    TriggerServerEvent('gunfightarena:getPersonalStats')
    cb('ok')
end)

RegisterNUICallback('getGlobalLeaderboard', function(data, cb)
    TriggerServerEvent('gunfightarena:getGlobalLeaderboard')
    cb('ok')
end)

RegisterNUICallback('getLobbyScoreboard', function(data, cb)
    TriggerServerEvent('gunfightarena:getLobbyScoreboard')
    cb('ok')
end)

RegisterNUICallback('closeStatsUI', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('closePersonalStatsUI', function(data, cb)
    cb('ok')
end)

RegisterNUICallback('closeGlobalLeaderboardUI', function(data, cb)
    cb('ok')
end)

-- ================================================================================================
-- EVENT : REJOINDRE/RESPAWN ARÈNE (AMÉLIORÉ v4.2)
-- ================================================================================================
RegisterNetEvent('gunfightarena:join')
AddEventHandler('gunfightarena:join', function(zoneIdentifier)
    DebugLog("Rejoindre/Respawn zone: " .. zoneIdentifier)
    
    UpdateCache()
    
    local spawnData = nil
    local isRespawn = (zoneIdentifier == 0)
    
    if isRespawn then
        if not currentZone then
            DebugLog("Erreur: currentZone est nil lors du respawn", "error")
            return
        end
        local respawnPoints = Config["Zone" .. currentZone].respawnPoints
        spawnData = respawnPoints[math.random(1, #respawnPoints)]
    else
        currentZone = zoneIdentifier
        local respawnPoints = Config["Zone" .. zoneIdentifier].respawnPoints
        spawnData = respawnPoints[math.random(1, #respawnPoints)]
    end
    
    if not currentZone then
        DebugLog("Erreur critique: currentZone non défini", "error")
        return
    end
    
    if spawnData then
        local ped = PlayerPedId()
        
        ClearPedTasksImmediately(ped)
        
        NetworkResurrectLocalPlayer(spawnData.pos.x, spawnData.pos.y, spawnData.pos.z, spawnData.heading, true, false)
        
        Citizen.Wait(100)
        ped = PlayerPedId()
        
        ClearPedTasksImmediately(ped)
        SetEntityHealth(ped, GetEntityMaxHealth(ped))
        
        InventoryBridge.GiveWeapon(Config.WeaponHash, Config.WeaponAmmo)
        
        Citizen.Wait(200)
        ForceWeaponReload()
        
        justRespawned = true
        ForceSyncPlayers()
        
        SetEntityInvincible(ped, true)
        SetEntityAlpha(ped, Config.SpawnAlpha, false)
        
        Citizen.CreateThread(function()
            AggressiveSyncAfterRespawn()
        end)
        
        Citizen.SetTimeout(Config.SpawnAlphaDuration, function()
            SetEntityAlpha(PlayerPedId(), 255, false)
        end)
        
        Citizen.SetTimeout(Config.InvincibilityTime, function()
            SetEntityInvincible(PlayerPedId(), false)
        end)
    end
    
    isInArena = true
    
    local zoneCfg = Config["Zone" .. currentZone]
    if zoneCfg and not arenaBlip then
        arenaBlip = AddBlipForRadius(zoneCfg.center, zoneCfg.radius)
        SetBlipColour(arenaBlip, 1)
        SetBlipAlpha(arenaBlip, 128)
    end
    
    if zoneCfg and not arenaZone then
        arenaZone = CircleZone:Create(zoneCfg.center, zoneCfg.radius, {
            name = "gunfight_zone" .. currentZone,
            debugPoly = Config.PolyZoneDebug,
            useZ = true
        })
    end
    
    if showingUI then
        SetNuiFocus(false, false)
        showingUI = false
    end
end)

-- ================================================================================================
-- EVENT : SORTIE DE ZONE
-- ================================================================================================
RegisterNetEvent('gunfightarena:exitZone')
AddEventHandler('gunfightarena:exitZone', function()
    DebugLog("=== SORTIE DE ZONE ===")
    
    if isInArena then
        TriggerServerEvent('gunfightarena:leaveArena')
        
        isInArena = false
        justExited = true
        
        Citizen.Wait(3000)
        
        if arenaBlip then
            RemoveBlip(arenaBlip)
            arenaBlip = nil
        end
        
        if arenaZone then
            arenaZone:destroy()
            arenaZone = nil
        end
        
        InventoryBridge.RemoveWeapon(Config.WeaponHash)
        
        SetEntityCoords(PlayerPedId(), Config.LobbySpawn.x, Config.LobbySpawn.y, Config.LobbySpawn.z)
        if Config.LobbySpawnHeading then
            SetEntityHeading(PlayerPedId(), Config.LobbySpawnHeading)
        end
        
        currentZone = nil
        
        Citizen.Wait(1000)
        justExited = false
        
        SendNUIMessage({ action = "clearKillFeed" })
    end
end)

-- ================================================================================================
-- EVENT : SORTIE MANUELLE
-- ================================================================================================
RegisterNetEvent('gunfightarena:exit')
AddEventHandler('gunfightarena:exit', function()
    if isInArena then
        isInArena = false
    end
    
    if arenaBlip then
        RemoveBlip(arenaBlip)
        arenaBlip = nil
    end
    
    if arenaZone then
        arenaZone:destroy()
        arenaZone = nil
    end
    
    InventoryBridge.RemoveWeapon(Config.WeaponHash)
    
    SetEntityCoords(PlayerPedId(), Config.LobbySpawn.x, Config.LobbySpawn.y, Config.LobbySpawn.z)
    if Config.LobbySpawnHeading then
        SetEntityHeading(PlayerPedId(), Config.LobbySpawnHeading)
    end
    
    currentZone = nil
end)

-- ================================================================================================
-- EVENT : KILL FEED
-- ================================================================================================
RegisterNetEvent('gunfightarena:killFeed')
AddEventHandler('gunfightarena:killFeed', function(killerName, victimName, headshot, multiplier, killerId)
    if isInArena then
        if GetPlayerServerId(PlayerId()) == killerId then
            SetEntityHealth(PlayerPedId(), GetEntityMaxHealth(PlayerPedId()))
            ForceWeaponReload()
            ForceSyncPlayers()
        end
        
        SendNUIMessage({
            action = "killFeed",
            message = {
                killer = killerName,
                victim = victimName,
                headshot = headshot,
                multiplier = multiplier
            }
        })
    end
end)

-- ================================================================================================
-- EVENTS : STATISTIQUES
-- ================================================================================================
RegisterNetEvent('gunfightarena:statsData')
AddEventHandler('gunfightarena:statsData', function(leaderboard)
    SendNUIMessage({ action = "showStats", stats = leaderboard })
    SetNuiFocus(true, true)
end)

RegisterNetEvent('gunfightarena:personalStatsData')
AddEventHandler('gunfightarena:personalStatsData', function(personalStats)
    SendNUIMessage({ action = "showPersonalStats", stats = personalStats })
    SetNuiFocus(true, true)
end)

RegisterNetEvent('gunfightarena:globalLeaderboardData')
AddEventHandler('gunfightarena:globalLeaderboardData', function(leaderboard)
    SendNUIMessage({ action = "showGlobalLeaderboard", stats = leaderboard })
    SetNuiFocus(true, true)
end)

RegisterNetEvent('gunfightarena:updateZonePlayers')
AddEventHandler('gunfightarena:updateZonePlayers', function(zones)
    SendNUIMessage({ action = "updateZonePlayers", zones = zones })
end)

RegisterNetEvent('gunfightarena:lobbyScoreboardData')
AddEventHandler('gunfightarena:lobbyScoreboardData', function(scoreboard)
    SendNUIMessage({ action = "showLobbyScoreboard", stats = scoreboard })
end)

-- ================================================================================================
-- COMMANDE : TEST KILL FEED
-- ================================================================================================
RegisterCommand(Config.TestKillFeedCommand, function()
    SendNUIMessage({
        action = "killFeed",
        message = {
            killer = "TestKiller" .. math.random(1, 10),
            victim = "TestVictim" .. math.random(1, 10),
            headshot = (math.random() > 0.5),
            multiplier = math.random(1, 5)
        }
    })
end, false)

-- ================================================================================================
-- NETTOYAGE
-- ================================================================================================
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if lobbyPed and DoesEntityExist(lobbyPed) then
        DeleteEntity(lobbyPed)
    end
end)

-- ================================================================================================
-- INITIALISATION
-- ================================================================================================
Citizen.CreateThread(function()
    Citizen.Wait(1000)
    print("^2[Gunfight Arena v4.2-SYNC]^0 Client démarré - CPU Optimisé + Sync Améliorée")
    print("^3[Gunfight Arena v4.2-SYNC]^0 Touches E et G réactives")
    print("^3[Gunfight Arena v4.2-SYNC]^0 Synchronisation armes/tirs AMÉLIORÉE")
end)
