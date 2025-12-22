-- ========================================
-- PVP GUNFIGHT - SYSTÈME DE DEBUG
-- Version 4.0.0 - Ultra-Optimisé
-- ========================================

-- Cache de la configuration debug (évite les accès répétés)
local debugEnabled = false
local debugLevels = {}

-- Codes couleurs ANSI
local COLORS = {
    reset = '^7',
    white = '^0',
    red = '^1',
    green = '^2',
    yellow = '^3',
    blue = '^4',
    cyan = '^5',
    pink = '^6',
    orange = '^9'
}

-- Préfixes et couleurs par catégorie (table statique, créée une seule fois)
local CATEGORY_CONFIG = {
    success = {color = COLORS.green, prefix = '[PVP SUCCESS]'},
    warning = {color = COLORS.yellow, prefix = '[PVP WARNING]'},
    error = {color = COLORS.red, prefix = '[PVP ERROR]'},
    client = {color = COLORS.cyan, prefix = '[PVP CLIENT]'},
    server = {color = COLORS.blue, prefix = '[PVP SERVER]'},
    ui = {color = COLORS.pink, prefix = '[PVP UI]'},
    bucket = {color = COLORS.orange, prefix = '[PVP BUCKET]'},
    elo = {color = COLORS.green, prefix = '[PVP ELO]'},
    zones = {color = COLORS.yellow, prefix = '[PVP ZONES]'},
    groups = {color = COLORS.cyan, prefix = '[PVP GROUPS]'},
    matchmaking = {color = COLORS.blue, prefix = '[PVP MATCHMAKING]'},
    info = {color = COLORS.white, prefix = '[PVP INFO]'}
}

-- ========================================
-- INITIALISATION DU CACHE
-- ========================================
local function InitDebugCache()
    if Config and Config.Debug then
        debugEnabled = Config.Debug.enabled or false
        debugLevels = Config.Debug.levels or {}
    end
end

-- Initialiser après le chargement de Config
CreateThread(function()
    Wait(0)
    InitDebugCache()
end)

-- ========================================
-- FONCTION PRINCIPALE DE DEBUG
-- ========================================
function DebugPrint(category, message, ...)
    -- Vérification rapide avec cache
    if not debugEnabled then return end
    if not debugLevels[category] then return end
    
    local config = CATEGORY_CONFIG[category] or CATEGORY_CONFIG.info
    
    -- Formatage conditionnel (évite string.format si pas d'arguments)
    local formattedMessage = select('#', ...) > 0 and string.format(message, ...) or message
    
    print(config.color .. config.prefix .. COLORS.reset .. ' ' .. formattedMessage)
end

-- ========================================
-- FONCTIONS RACCOURCIES (inline pour performance)
-- ========================================
function DebugInfo(message, ...)
    if not debugEnabled or not debugLevels.info then return end
    DebugPrint('info', message, ...)
end

function DebugSuccess(message, ...)
    if not debugEnabled or not debugLevels.success then return end
    DebugPrint('success', message, ...)
end

function DebugWarn(message, ...)
    if not debugEnabled or not debugLevels.warning then return end
    DebugPrint('warning', message, ...)
end

function DebugError(message, ...)
    if not debugEnabled or not debugLevels.error then return end
    DebugPrint('error', message, ...)
end

function DebugClient(message, ...)
    if not debugEnabled or not debugLevels.client then return end
    DebugPrint('client', message, ...)
end

function DebugServer(message, ...)
    if not debugEnabled or not debugLevels.server then return end
    DebugPrint('server', message, ...)
end

function DebugUI(message, ...)
    if not debugEnabled or not debugLevels.ui then return end
    DebugPrint('ui', message, ...)
end

function DebugBucket(message, ...)
    if not debugEnabled or not debugLevels.bucket then return end
    DebugPrint('bucket', message, ...)
end

function DebugElo(message, ...)
    if not debugEnabled or not debugLevels.elo then return end
    DebugPrint('elo', message, ...)
end

function DebugZones(message, ...)
    if not debugEnabled or not debugLevels.zones then return end
    DebugPrint('zones', message, ...)
end

function DebugGroups(message, ...)
    if not debugEnabled or not debugLevels.groups then return end
    DebugPrint('groups', message, ...)
end

function DebugMatchmaking(message, ...)
    if not debugEnabled or not debugLevels.matchmaking then return end
    DebugPrint('matchmaking', message, ...)
end

-- ========================================
-- FONCTIONS DE DÉBOGAGE AVANCÉ
-- ========================================
function DebugTable(category, tableName, tbl)
    if not debugEnabled or not debugLevels[category] then return end
    
    DebugPrint(category, '========== TABLE: %s ==========', tableName)
    
    if type(tbl) ~= 'table' then
        DebugPrint(category, 'Valeur: %s (type: %s)', tostring(tbl), type(tbl))
        return
    end
    
    for key, value in pairs(tbl) do
        local valueStr = type(value) == 'table' and '[TABLE]' or tostring(value)
        DebugPrint(category, '  %s = %s', tostring(key), valueStr)
    end
    
    DebugPrint(category, '========================================')
end

function DebugPerformance(category, label, func)
    if not debugEnabled or not debugLevels[category] then
        return func()
    end
    
    local startTime = GetGameTimer()
    local result = func()
    local duration = GetGameTimer() - startTime
    
    DebugPrint(category, '[PERF] %s: %dms', label, duration)
    
    return result
end

function DebugIf(condition, category, message, ...)
    if condition and debugEnabled and debugLevels[category] then
        DebugPrint(category, message, ...)
    end
end

-- ========================================
-- EXPORTS
-- ========================================
if IsDuplicityVersion() then
    exports('DebugPrint', DebugPrint)
    exports('DebugServer', DebugServer)
    exports('DebugTable', DebugTable)
else
    exports('DebugPrint', DebugPrint)
    exports('DebugClient', DebugClient)
    exports('DebugUI', DebugUI)
    exports('DebugZones', DebugZones)
    exports('DebugTable', DebugTable)
end

-- Message de démarrage (après init)
CreateThread(function()
    Wait(100)
    InitDebugCache()
    if debugEnabled then
        DebugSuccess('Système de debug chargé - ACTIVÉ')
    end
end)
