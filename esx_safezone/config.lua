-- Configuration (identique à l'original, pas de changement nécessaire)
Config = {}

Config.Performance = {
    checkIntervals = {
        inZone = 500,
        nearBorder = 250,
        outsideZone = 1000,
    },
    streamingDistance = 250.0,
    streamingRadius = 150.0,
    cacheEnabled = true,
    cacheLifetime = 1000,
    markerStreamDistance = 100.0,
    markerUpdateRate = 250,
    spawnProtectionTime = 2000,
}

Config.Debug = false
Config.ServerLogs = false

Config.Visual = {
    showMarkers = true,
    showBlips = true,
    markerTypes = {
        cylinder = 1,
        circle = 25,
    },
    defaultColor = {r = 0, g = 255, b = 0, a = 20},
    warningColor = {r = 255, g = 165, b = 0, a = 30},
    markerBounce = false,
    markerRotate = false,
}

Config.Notifications = {
    enabled = false,
    type = 'chat',
    messages = {
        entering = '~g~Zone sécurisée - Armes désactivées',
        leaving = '~y~Zone sécurisée désactivée',
        teleported = '~r~Retour dans la zone',
        warning = '~o~⚠️ Limite de zone proche'
    }
}

Config.Gameplay = {
    teleportation = {
        fadeEnabled = false,
        fadeDuration = 300,
        freezeDuration = 100,
        cooldown = 2000,
    }
}

Config.SafeZones = {
    {
        name = 'Legion Square',
        id = 'legion_square',
        geometry = {
            type = 'cylinder',
            position = vector3(-2660.096680, -765.375854, 5.993408),
            radius = 50.0,
            height = 22.0,
        },
        teleport = {
            enabled = false,
            position = vector4(-2660.096680, -765.375854, 5.993408, 255.118104),
            instant = true,
            onExit = false,
        },
        effects = {
            disableWeapons = true,
            disableMelee = true,
            speedMultiplier = 4.0,
            godMode = true,
            disableVehicles = false,
            disablePVP = true,
        },
        warnings = {
            enabled = false,
            distance = 5.0,
            message = nil,
        },
        visual = {
            marker = {
                enabled = true,
                type = 1,
                color = {r = 0, g = 255, b = 0, a = 15},
                scale = 1.5,
            },
            blip = {
                enabled = true,
                sprite = 310,
                color = 2,
                scale = 0.9,
                label = 'Safe Zone - Legion Square'
            }
        },
        enabled = true,
    },
}

function Config.DebugLog(message, level)
    if not Config.Debug then return end
    local prefix = '^3[SafeZone]^7'
    if level == 'error' then
        prefix = '^1[SafeZone ERROR]^7'
    elseif level == 'warn' then
        prefix = '^3[SafeZone WARN]^7'
    elseif level == 'success' then
        prefix = '^2[SafeZone]^7'
    end
    print(string.format('%s %s', prefix, message))
end

function Config.GetActiveZonesCount()
    local count = 0
    for _, zone in ipairs(Config.SafeZones) do
        if zone.enabled then
            count = count + 1
        end
    end
    return count
end

function Config.GetZone(identifier)
    for _, zone in ipairs(Config.SafeZones) do
        if zone.id == identifier or zone.name == identifier then
            return zone
        end
    end
    return nil
end

function Config.ValidateZone(zone)
    if not zone.geometry or not zone.geometry.type then
        Config.DebugLog('Zone invalide: géométrie manquante', 'error')
        return false
    end
    if not zone.geometry.position or not zone.geometry.radius then
        Config.DebugLog('Zone invalide: position ou rayon manquant', 'error')
        return false
    end
    if zone.geometry.type == 'cylinder' and not zone.geometry.height then
        Config.DebugLog('Zone cylindre sans hauteur, utilisation de 22m par défaut', 'warn')
        zone.geometry.height = 22.0
    end
    return true
end

Citizen.CreateThread(function()
    local validZones = 0
    for i, zone in ipairs(Config.SafeZones) do
        if zone.enabled and Config.ValidateZone(zone) then
            validZones = validZones + 1
        end
    end
    Config.DebugLog(string.format('Configuration chargée: %d/%d zones valides', validZones, #Config.SafeZones), 'success')
    Config.DebugLog('═══════════════════════════════════════', 'success')
    Config.DebugLog('🔧 SafeZone v2.0.2 - ULTRA-SÉCURISÉ', 'success')
    Config.DebugLog('💚 CPU: <0.1% | Refresh: 500ms-1s', 'success')
    Config.DebugLog('🔄 Compatible: qs-multicharacter', 'success')
    Config.DebugLog('🥊 PATCH: Coups de poing désactivés', 'success')
    Config.DebugLog('🚨 PATCH v2.0.2: Anti-hang garanti', 'success')
    Config.DebugLog('═══════════════════════════════════════', 'success')
end)