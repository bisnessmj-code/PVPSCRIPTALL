--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                        CLIENT - MAIN.LUA                                   ║
    ║           Optimisé : Logging centralisé, zéro spam console                ║
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
    weaponGiven = false,
    lastWeaponWarning = 0
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
    
    Logger.Info('CLIENT', 'Système initialisé')
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
    Logger.Debug('CLIENT', 'PED d\'entrée créé')
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
    
    Logger.Debug('CLIENT', 'Blip créé')
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
                            Logger.Debug('CLIENT', 'Demande de rejoindre envoyée')
                            TriggerServerEvent('gungame:server:requestJoin')
                            Wait(2000)
                        else
                            Logger.Debug('CLIENT', 'Cooldown actif')
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
                
                -- Log périodique (toutes les 10 secondes en mode debug)
                local currentTime = GetGameTimer()
                if currentTime - lastWarning > 10000 then
                    local map = Config.GetActiveMap()
                    if map then
                        local dx = coords.x - map.center.x
                        local dy = coords.y - map.center.y
                        local distance = math.sqrt(dx * dx + dy * dy)
                        Logger.Debug('ZONE', 'Distance: %.1fm / %dm - Dans zone: %s', distance, map.radius, tostring(inZone))
                    end
                    lastWarning = currentTime
                end
                
                if not inZone then
                    Logger.Warn('ZONE', 'Sortie de zone détectée')
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
-- THREAD : BLOCAGE ULTRA-COMPLET QS-INVENTORY
-- ═══════════════════════════════════════════════════════════════════════════
CreateThread(function()
    while true do
        Wait(0)
        
        if cachedData.isInGame then
            local ped = PlayerPedId()
            
            -- Blocage TAB
            DisableControlAction(0, 37, true)
            DisableControlAction(1, 37, true)
            DisableControlAction(2, 37, true)
            
            -- Blocage raccourcis 1-9
            DisableControlAction(0, 157, true)
            DisableControlAction(0, 158, true)
            DisableControlAction(0, 160, true)
            DisableControlAction(0, 164, true)
            DisableControlAction(0, 165, true)
            DisableControlAction(0, 159, true)
            DisableControlAction(0, 161, true)
            DisableControlAction(0, 162, true)
            DisableControlAction(0, 163, true)
            DisableControlAction(1, 157, true)
            DisableControlAction(1, 158, true)
            DisableControlAction(1, 160, true)
            DisableControlAction(1, 164, true)
            DisableControlAction(1, 165, true)
            DisableControlAction(1, 159, true)
            DisableControlAction(1, 161, true)
            DisableControlAction(1, 162, true)
            DisableControlAction(1, 163, true)
            
            -- Blocage scroll
            DisableControlAction(0, 14, true)
            DisableControlAction(0, 15, true)
            DisableControlAction(0, 16, true)
            DisableControlAction(0, 17, true)
            DisableControlAction(1, 14, true)
            DisableControlAction(1, 15, true)
            DisableControlAction(1, 16, true)
            DisableControlAction(1, 17, true)
            
            -- Blocage inventaire
            DisableControlAction(0, 289, true)
            DisableControlAction(0, 170, true)
            DisableControlAction(1, 289, true)
            DisableControlAction(1, 170, true)
            
            -- Blocage roue d'armes
            DisableControlAction(0, 99, true)
            DisableControlAction(0, 115, true)
            
            -- Blocage menus
            DisableControlAction(0, 244, true)
            DisableControlAction(0, 288, true)
            
            -- Forcer l'arme GunGame
            if not cachedData.isRespawning then
                local currentWeapon = GetSelectedPedWeapon(ped)
                local expectedWeapon = Config.GetWeaponHash(cachedData.currentWeaponIndex)
                
                if currentWeapon ~= expectedWeapon and expectedWeapon ~= 0 then
                    SetCurrentPedWeapon(ped, expectedWeapon, true)
                    
                    if not cachedData.lastWeaponWarning or GetGameTimer() - cachedData.lastWeaponWarning > 1000 then
                        ShowNotification('~r~Tu ne peux utiliser que l\'arme GunGame !')
                        cachedData.lastWeaponWarning = GetGameTimer()
                        Logger.Debug('ANTI-WEAPON', 'Arme forcée: %d', expectedWeapon)
                    end
                end
            end
            
            SetPlayerInvincible(PlayerId(), false)
        else
            Wait(500)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- THREAD : NETTOYAGE PÉRIODIQUE DES ARMES
-- ═══════════════════════════════════════════════════════════════════════════
CreateThread(function()
    while true do
        Wait(500)
        
        if cachedData.isInGame and not cachedData.isRespawning then
            local ped = PlayerPedId()
            local expectedWeapon = Config.GetWeaponHash(cachedData.currentWeaponIndex)
            
            if expectedWeapon and expectedWeapon ~= 0 then
                local weaponCount = 0
                local hasExpectedWeapon = false
                
                for _, weapon in ipairs(Config.Weapons) do
                    local weaponHash = GetHashKey(weapon.name)
                    if HasPedGotWeapon(ped, weaponHash, false) then
                        weaponCount = weaponCount + 1
                        if weaponHash == expectedWeapon then
                            hasExpectedWeapon = true
                        end
                    end
                end
                
                if weaponCount > 1 or not hasExpectedWeapon then
                    Logger.Debug('ANTI-INVENTORY', 'Armes multiples détectées: %d', weaponCount)
                    
                    RemoveAllPedWeapons(ped, true)
                    Wait(100)
                    
                    GiveWeaponToPed(ped, expectedWeapon, Config.DefaultAmmo, false, true)
                    SetPedAmmo(ped, expectedWeapon, Config.DefaultAmmo)
                    SetAmmoInClip(ped, expectedWeapon, GetMaxAmmoInClip(ped, expectedWeapon, true))
                    SetCurrentPedWeapon(ped, expectedWeapon, true)
                    
                    ShowNotification('~r~Armes non autorisées supprimées !')
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- THREAD : DÉTECTION DE MORT
-- ═══════════════════════════════════════════════════════════════════════════
CreateThread(function()
    while true do
        Wait(100)
        
        if cachedData.isInGame and not cachedData.isRespawning then
            local ped = PlayerPedId()
            local currentTime = GetGameTimer()
            
            if IsEntityDead(ped) and not cachedData.isDead then
                if currentTime - cachedData.lastDeathCheck < 2000 then
                    goto continue
                end
                
                cachedData.lastDeathCheck = currentTime
                cachedData.isDead = true
                
                local killer = GetPedSourceOfDeath(ped)
                local killerServerId = 0
                
                if killer and killer ~= 0 and IsEntityAPed(killer) and IsPedAPlayer(killer) then
                    killerServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(killer))
                end
                
                local weaponHash = GetPedCauseOfDeath(ped)
                
                Logger.Debug('DEATH', 'Mort détectée - Tueur: %d', killerServerId)
                
                local coords = GetEntityCoords(ped)
                local inZone = Config.IsInCombatZone(coords)
                
                if inZone then
                    TriggerServerEvent('gungame:server:playerDied', killerServerId, weaponHash)
                else
                    Logger.Debug('DEATH', 'Mort hors zone - Ignorée')
                end
                
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
        Logger.Error('RESPAWN', 'Aucun point de respawn trouvé')
        cachedData.isRespawning = false
        return
    end
    
    Logger.Debug('RESPAWN', 'Point choisi: %.1f, %.1f, %.1f', respawn.x, respawn.y, respawn.z)
    
    if Config.RespawnDelay > 0 then
        Wait(Config.RespawnDelay)
    end
    
    local ped = PlayerPedId()
    
    TriggerEvent('esx_ambulancejob:setDeathStatus', false)
    
    DoScreenFadeOut(250)
    Wait(300)
    
    NetworkResurrectLocalPlayer(respawn.x, respawn.y, respawn.z, respawn.w, true, false)
    
    Wait(200)
    ped = PlayerPedId()
    
    SetEntityCoords(ped, respawn.x, respawn.y, respawn.z, false, false, false, false)
    SetEntityHeading(ped, respawn.w)
    
    SetEntityInvincible(ped, true)
    
    Wait(100)
    
    local finalCoords = GetEntityCoords(ped)
    local inZone = Config.IsInCombatZone(finalCoords)
    
    if not inZone then
        Logger.Warn('RESPAWN', 'Hors zone après respawn - Retéléportation')
        SetEntityCoords(ped, respawn.x, respawn.y, respawn.z, false, false, false, false)
        Wait(100)
    end
    
    SetEntityHealth(ped, Config.DefaultHealth)
    SetPedArmour(ped, Config.DefaultArmor)
    ClearPedBloodDamage(ped)
    
    Wait(100)
    SetEntityInvincible(ped, false)
    
    GiveCurrentWeapon()
    
    DoScreenFadeIn(250)
    
    cachedData.isDead = false
    cachedData.isRespawning = false
    
    Logger.Debug('RESPAWN', 'Respawn terminé')
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
    
    Logger.Info('CLIENT', 'Rejoindre la partie - Arme: %d', weaponIndex)
    
    TriggerEvent('esx_ambulancejob:setDeathStatus', false)
    
    local respawn = Config.GetRandomRespawn()
    
    DoScreenFadeOut(250)
    Wait(300)
    
    SetEntityCoords(ped, respawn.x, respawn.y, respawn.z, false, false, false, false)
    SetEntityHeading(ped, respawn.w)
    
    SetEntityInvincible(ped, true)
    
    Wait(200)
    
    SetupPlayerForGame()
    
    Wait(500)
    
    GiveCurrentWeapon()
    
    Wait(200)
    local currentWeapon = GetSelectedPedWeapon(ped)
    local expectedWeapon = Config.GetWeaponHash(cachedData.currentWeaponIndex)
    
    if currentWeapon ~= expectedWeapon then
        Logger.Debug('JOIN', 'Arme non équipée, retry')
        GiveCurrentWeapon()
        Wait(200)
    end
    
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
end)

RegisterNetEvent('gungame:client:leaveGame', function()
    Logger.Info('CLIENT', 'Quitter la partie')
    
    cachedData.isInGame = false
    cachedData.currentWeaponIndex = 1
    cachedData.currentKills = 0
    cachedData.isDead = false
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
    
    Logger.Debug('PROGRESS', 'Arme: %d/40, Kills: %d/%d', weaponIndex, kills, Config.KillsPerWeaponChange)
    
    if weaponIndex ~= previousWeapon then
        Logger.Info('WEAPON_CHANGE', '%d → %d', previousWeapon, weaponIndex)
        GiveCurrentWeapon()
        local weaponData = Config.GetWeapon(weaponIndex)
        if weaponData then
            ShowNotification(string.format(Config.Messages.weaponChanged, weaponData.label))
        end
    end
    
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
    Logger.Debug('KILL', 'Kill confirmé (%d/%d)', kills, neededKills)
    ShowNotification(string.format(Config.Messages.killConfirm, kills, neededKills))
end)

RegisterNetEvent('gungame:client:playerKilled', function(killerName)
    Logger.Debug('DEATH', 'Tué par %s', killerName)
    ShowNotification(string.format(Config.Messages.playerKilled, killerName))
end)

RegisterNetEvent('gungame:client:updateLeaderboard', function(leaderboard)
    Logger.Debug('LEADERBOARD', 'Classement reçu: %d joueurs', #leaderboard)
    
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
    
    Logger.Info('END', 'Partie terminée - Vainqueur: %s', winner)
    
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
    
    Logger.Debug('SETUP', 'Joueur configuré - Santé: %d, Armure: %d', Config.DefaultHealth, Config.DefaultArmor)
end

function GiveCurrentWeapon()
    local ped = PlayerPedId()
    local weaponData = Config.GetWeapon(cachedData.currentWeaponIndex)
    
    if not weaponData then
        Logger.Error('WEAPON', 'Arme invalide à l\'index %d', cachedData.currentWeaponIndex)
        return
    end
    
    RemoveAllPedWeapons(ped, true)
    
    local weaponHash = GetHashKey(weaponData.name)
    
    GiveWeaponToPed(ped, weaponHash, Config.DefaultAmmo, false, true)
    SetPedAmmo(ped, weaponHash, Config.DefaultAmmo)
    SetAmmoInClip(ped, weaponHash, GetMaxAmmoInClip(ped, weaponHash, true))
    SetCurrentPedWeapon(ped, weaponHash, true)
    
    Wait(100)
    SetCurrentPedWeapon(ped, weaponHash, true)
    
    Wait(100)
    local currentWeapon = GetSelectedPedWeapon(ped)
    if currentWeapon ~= weaponHash then
        Logger.Warn('WEAPON', 'Arme non équipée, retry final')
        SetCurrentPedWeapon(ped, weaponHash, true)
    else
        Logger.Debug('WEAPON', 'Arme équipée: %s', weaponData.label)
    end
    
    cachedData.weaponGiven = true
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
    
    Logger.Debug('CLIENT', 'Commande /quitgungame utilisée')
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
    
    local ped = PlayerPedId()
    SetEntityInvincible(ped, false)
    
    Logger.Info('CLIENT', 'Resource arrêtée - Nettoyage effectué')
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════
exports('isInGunGame', function() return cachedData.isInGame end)
exports('getCurrentWeapon', function() return cachedData.currentWeaponIndex end)
exports('getCurrentKills', function() return cachedData.currentKills end)
