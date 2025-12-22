-- ================================================================================================
-- GUNFIGHT ARENA - INVENTORY BRIDGE v2.0 OPTIMISÉ CPU
-- ================================================================================================
-- ✅ Élimination des boucles while infinies
-- ✅ Limitation des tentatives avec timeout
-- ✅ Cache des états pour éviter les appels répétitifs
-- ================================================================================================

InventoryBridge = {}

-- ================================================================================================
-- CONFIGURATION
-- ================================================================================================
local inventoryType = Config.InventorySystem or "auto"
local detectedInventory = "vanilla"
local hasReceivedInitialAmmo = false

-- ================================================================================================
-- FONCTION : DÉTECTION AUTOMATIQUE DE L'INVENTAIRE (Une seule fois)
-- ================================================================================================
local function DetectInventory()
    if inventoryType ~= "auto" then
        detectedInventory = inventoryType
        return inventoryType
    end
    
    if GetResourceState('qs-inventory') == 'started' then
        detectedInventory = "qs-inventory"
    elseif GetResourceState('ox_inventory') == 'started' then
        detectedInventory = "ox_inventory"
    elseif GetResourceState('qb-inventory') == 'started' then
        detectedInventory = "qb-inventory"
    else
        detectedInventory = "vanilla"
    end
    
    return detectedInventory
end

-- ================================================================================================
-- FONCTION : LOG DEBUG (Conditionnel)
-- ================================================================================================
local function DebugLog(message, logType)
    if not Config.DebugClient then return end
    
    local prefixes = {
        error = "^1[GF-Bridge ERROR]^0",
        success = "^2[GF-Bridge OK]^0",
        weapon = "^7[GF-WEAPON]^0"
    }
    
    print((prefixes[logType] or "^6[GF-Bridge]^0") .. " " .. message)
end

-- ================================================================================================
-- FONCTION : FORCER LE RECHARGEMENT DE L'ARME (Sans boucle)
-- ================================================================================================
local function ForceReloadWeapon(weaponHash)
    local playerPed = PlayerPedId()
    
    if not HasPedGotWeapon(playerPed, weaponHash, false) then
        return false
    end
    
    SetPedAmmo(playerPed, weaponHash, Config.WeaponAmmo)
    local clipSize = GetMaxAmmoInClip(playerPed, weaponHash, false)
    SetAmmoInClip(playerPed, weaponHash, clipSize)
    
    DebugLog("Arme rechargée", "success")
    return true
end

-- ================================================================================================
-- FONCTION : FORCER L'ÉQUIPEMENT DE L'ARME (Max 5 tentatives)
-- ================================================================================================
local function ForceEquipWeapon(weaponHash)
    local playerPed = PlayerPedId()
    
    -- Maximum 5 tentatives avec délai croissant
    for attempt = 1, 5 do
        SetCurrentPedWeapon(playerPed, weaponHash, true)
        Citizen.Wait(50 * attempt) -- 50, 100, 150, 200, 250ms
        
        if GetSelectedPedWeapon(playerPed) == weaponHash then
            DebugLog("Arme équipée (tentative " .. attempt .. ")", "success")
            return true
        end
    end
    
    DebugLog("Échec équipement après 5 tentatives", "error")
    return false
end

-- ================================================================================================
-- FONCTION : DONNER UNE ARME
-- ================================================================================================
function InventoryBridge.GiveWeapon(weaponName, ammo, isFirstEntry)
    local playerPed = PlayerPedId()
    local weaponHash = GetHashKey(weaponName)
    
    if isFirstEntry == nil then
        isFirstEntry = not hasReceivedInitialAmmo
    end
    
    DebugLog("Attribution arme: " .. weaponName .. " (Inv: " .. detectedInventory .. ")", "weapon")
    
    -- Gestion par type d'inventaire
    if detectedInventory == "qs-inventory" or detectedInventory == "ox_inventory" or detectedInventory == "qb-inventory" then
        if isFirstEntry then
            TriggerServerEvent('gunfightarena:giveWeapon', weaponName, ammo)
            TriggerServerEvent('gunfightarena:giveAmmo', 'pistol_ammo', 200)
            hasReceivedInitialAmmo = true
            Citizen.Wait(300)
        end
    end
    
    -- Donner l'arme en natif si nécessaire
    if not HasPedGotWeapon(playerPed, weaponHash, false) then
        GiveWeaponToPed(playerPed, weaponHash, ammo, false, true)
    end
    
    -- Équiper et recharger
    Citizen.Wait(100)
    ForceEquipWeapon(weaponHash)
    Citizen.Wait(100)
    ForceReloadWeapon(weaponHash)
    
    DebugLog("Arme attribuée avec succès", "success")
    return true
end

-- ================================================================================================
-- FONCTION : RETIRER UNE ARME
-- ================================================================================================
function InventoryBridge.RemoveWeapon(weaponName)
    local playerPed = PlayerPedId()
    local weaponHash = GetHashKey(weaponName)
    
    RemoveWeaponFromPed(playerPed, weaponHash)
    
    if detectedInventory ~= "vanilla" then
        TriggerServerEvent('gunfightarena:removeWeapon', weaponName)
        TriggerServerEvent('gunfightarena:removeAmmo', 'pistol_ammo')
    end
    
    hasReceivedInitialAmmo = false
    DebugLog("Arme retirée", "success")
end

-- ================================================================================================
-- FONCTION : RETIRER TOUTES LES ARMES
-- ================================================================================================
function InventoryBridge.RemoveAllWeapons()
    local playerPed = PlayerPedId()
    
    InventoryBridge.RemoveWeapon(Config.WeaponHash)
    
    if Config.RemoveAllWeaponsOnExit then
        RemoveAllPedWeapons(playerPed, true)
        
        if detectedInventory ~= "vanilla" then
            TriggerServerEvent('gunfightarena:removeAllWeapons')
        end
    end
    
    hasReceivedInitialAmmo = false
end

-- ================================================================================================
-- FONCTION : VÉRIFIER SI LE JOUEUR A UNE ARME
-- ================================================================================================
function InventoryBridge.HasWeapon(weaponName)
    local playerPed = PlayerPedId()
    local weaponHash = GetHashKey(weaponName)
    return HasPedGotWeapon(playerPed, weaponHash, false)
end

-- ================================================================================================
-- FONCTION : DÉFINIR LES MUNITIONS
-- ================================================================================================
function InventoryBridge.SetAmmo(weaponName, ammo)
    local playerPed = PlayerPedId()
    local weaponHash = GetHashKey(weaponName)
    
    if HasPedGotWeapon(playerPed, weaponHash, false) then
        SetPedAmmo(playerPed, weaponHash, ammo)
    end
end

-- ================================================================================================
-- FONCTION : RECHARGER L'ARME
-- ================================================================================================
function InventoryBridge.ReloadWeapon(weaponName)
    local weaponHash = GetHashKey(weaponName)
    ForceReloadWeapon(weaponHash)
end

-- ================================================================================================
-- FONCTION : RÉINITIALISER LE FLAG MUNITIONS
-- ================================================================================================
function InventoryBridge.ResetAmmoFlag()
    hasReceivedInitialAmmo = false
end

-- ================================================================================================
-- INITIALISATION (Une seule fois)
-- ================================================================================================
Citizen.CreateThread(function()
    Citizen.Wait(1000)
    
    local inventory = DetectInventory()
    
    print("^2[Gunfight Bridge v2.0-OPT]^0 Initialisé")
    print("^3[Gunfight Bridge v2.0-OPT]^0 Inventaire: ^2" .. inventory .. "^0")
end)

-- ================================================================================================
-- EXPORTS
-- ================================================================================================
exports('GiveWeapon', InventoryBridge.GiveWeapon)
exports('RemoveWeapon', InventoryBridge.RemoveWeapon)
exports('HasWeapon', InventoryBridge.HasWeapon)
exports('ReloadWeapon', InventoryBridge.ReloadWeapon)
exports('ResetAmmoFlag', InventoryBridge.ResetAmmoFlag)
exports('GetInventoryType', function() return detectedInventory end)
