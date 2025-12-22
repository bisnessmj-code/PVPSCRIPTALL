-- ================================================================================================
-- GUNFIGHT ARENA - INVENTORY BRIDGE SERVER v2.0 OPTIMISÉ
-- ================================================================================================
-- ✅ Code simplifié et optimisé
-- ✅ Moins de logs en production
-- ================================================================================================

local ESX = exports['es_extended']:getSharedObject()

local inventoryType = Config.InventorySystem or "auto"
local detectedInventory = "vanilla"

-- ================================================================================================
-- FONCTION : DÉTECTION AUTOMATIQUE DE L'INVENTAIRE
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
    if not Config.DebugServer then return end
    
    local prefixes = {
        error = "^1[GF-Bridge-Server ERROR]^0",
        success = "^2[GF-Bridge-Server OK]^0",
        weapon = "^7[GF-WEAPON-Server]^0"
    }
    
    print((prefixes[logType] or "^6[GF-Bridge-Server]^0") .. " " .. message)
end

-- ================================================================================================
-- EVENT : DONNER UNE ARME AU JOUEUR
-- ================================================================================================
RegisterNetEvent('gunfightarena:giveWeapon')
AddEventHandler('gunfightarena:giveWeapon', function(weaponName, ammo)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    if detectedInventory == "qs-inventory" then
        local hasWeapon = exports['qs-inventory']:GetItemTotalAmount(src, weaponName)
        if not hasWeapon or hasWeapon == 0 then
            exports['qs-inventory']:AddItem(src, weaponName, 1)
        end
        
    elseif detectedInventory == "ox_inventory" then
        exports.ox_inventory:AddItem(src, weaponName, 1)
        
    elseif detectedInventory == "qb-inventory" then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.AddItem(weaponName, 1)
        end
    end
    
    DebugLog("Arme donnée à " .. src, "success")
end)

-- ================================================================================================
-- EVENT : DONNER DES MUNITIONS AU JOUEUR
-- ================================================================================================
RegisterNetEvent('gunfightarena:giveAmmo')
AddEventHandler('gunfightarena:giveAmmo', function(ammoType, amount)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    if detectedInventory == "qs-inventory" then
        local currentAmmo = exports['qs-inventory']:GetItemTotalAmount(src, ammoType) or 0
        if currentAmmo > 0 then
            exports['qs-inventory']:RemoveItem(src, ammoType, currentAmmo)
        end
        exports['qs-inventory']:AddItem(src, ammoType, amount)
        
    elseif detectedInventory == "ox_inventory" then
        local currentAmmo = exports.ox_inventory:Search(src, 'count', ammoType) or 0
        if currentAmmo > 0 then
            exports.ox_inventory:RemoveItem(src, ammoType, currentAmmo)
        end
        exports.ox_inventory:AddItem(src, ammoType, amount)
        
    elseif detectedInventory == "qb-inventory" then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            local item = Player.Functions.GetItemByName(ammoType)
            if item then
                Player.Functions.RemoveItem(ammoType, item.amount)
            end
            Player.Functions.AddItem(ammoType, amount)
        end
    end
    
    DebugLog("Munitions données à " .. src, "success")
end)

-- ================================================================================================
-- EVENT : RETIRER UNE ARME DU JOUEUR
-- ================================================================================================
RegisterNetEvent('gunfightarena:removeWeapon')
AddEventHandler('gunfightarena:removeWeapon', function(weaponName)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    if detectedInventory == "qs-inventory" then
        local hasWeapon = exports['qs-inventory']:GetItemTotalAmount(src, weaponName)
        if hasWeapon and hasWeapon > 0 then
            exports['qs-inventory']:RemoveItem(src, weaponName, 1)
        end
        
    elseif detectedInventory == "ox_inventory" then
        exports.ox_inventory:RemoveItem(src, weaponName, 1)
        
    elseif detectedInventory == "qb-inventory" then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.RemoveItem(weaponName, 1)
        end
    end
    
    DebugLog("Arme retirée de " .. src, "success")
end)

-- ================================================================================================
-- EVENT : RETIRER LES MUNITIONS DU JOUEUR
-- ================================================================================================
RegisterNetEvent('gunfightarena:removeAmmo')
AddEventHandler('gunfightarena:removeAmmo', function(ammoType)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    if detectedInventory == "qs-inventory" then
        local ammoCount = exports['qs-inventory']:GetItemTotalAmount(src, ammoType)
        if ammoCount and ammoCount > 0 then
            exports['qs-inventory']:RemoveItem(src, ammoType, ammoCount)
        end
        
    elseif detectedInventory == "ox_inventory" then
        local ammoCount = exports.ox_inventory:Search(src, 'count', ammoType)
        if ammoCount > 0 then
            exports.ox_inventory:RemoveItem(src, ammoType, ammoCount)
        end
        
    elseif detectedInventory == "qb-inventory" then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            local item = Player.Functions.GetItemByName(ammoType)
            if item then
                Player.Functions.RemoveItem(ammoType, item.amount)
            end
        end
    end
    
    DebugLog("Munitions retirées de " .. src, "success")
end)

-- ================================================================================================
-- EVENT : RETIRER TOUTES LES ARMES
-- ================================================================================================
RegisterNetEvent('gunfightarena:removeAllWeapons')
AddEventHandler('gunfightarena:removeAllWeapons', function()
    local src = source
    
    TriggerEvent('gunfightarena:removeWeapon', Config.WeaponHash)
    TriggerEvent('gunfightarena:removeAmmo', 'pistol_ammo')
end)

-- ================================================================================================
-- INITIALISATION
-- ================================================================================================
Citizen.CreateThread(function()
    Citizen.Wait(1000)
    
    local inventory = DetectInventory()
    
    print("^2[Gunfight Bridge Server v2.0-OPT]^0 Initialisé")
    print("^3[Gunfight Bridge Server v2.0-OPT]^0 Inventaire: ^2" .. inventory .. "^0")
end)
