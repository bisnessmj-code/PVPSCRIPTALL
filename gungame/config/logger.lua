--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                     SYSTÈME DE LOGGING CENTRALISÉ                          ║
    ║              Gestion propre des logs avec niveaux et filtres               ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

Logger = {}

-- Niveaux de log
Logger.Levels = {
    DEBUG = 1,  -- Détails techniques, traces d'exécution
    INFO = 2,   -- Informations générales (join, leave, etc.)
    WARN = 3,   -- Avertissements (joueur non trouvé, etc.)
    ERROR = 4   -- Erreurs critiques uniquement
}

-- Couleurs pour chaque niveau
Logger.Colors = {
    DEBUG = '^6',   -- Cyan
    INFO = '^2',    -- Vert
    WARN = '^3',    -- Orange
    ERROR = '^1'    -- Rouge
}

-- Symboles pour chaque niveau
Logger.Symbols = {
    DEBUG = '🔧',
    INFO = 'ℹ️',
    WARN = '⚠️',
    ERROR = '❌'
}

-- Niveau minimum à afficher (configuré via Config.LogLevel)
Logger.MinLevel = Logger.Levels.ERROR

-- Fonction d'initialisation
function Logger.Init()
    local levelName = Config.LogLevel or 'error'
    Logger.MinLevel = Logger.Levels[levelName:upper()] or Logger.Levels.ERROR
    
    if Config.Debug then
        Logger.MinLevel = Logger.Levels.DEBUG
    end
end

-- Fonction de log principale
function Logger.Log(level, category, message, ...)
    if not Logger.MinLevel then
        Logger.Init()
    end
    
    local levelValue = Logger.Levels[level:upper()] or Logger.Levels.INFO
    
    -- Filtrer selon le niveau minimum
    if levelValue < Logger.MinLevel then
        return
    end
    
    local color = Logger.Colors[level:upper()] or '^7'
    local symbol = Logger.Symbols[level:upper()] or ''
    local prefix = string.format('%s[GunGame][%s][%s]^7', color, level:upper(), category)
    
    -- Formater le message avec les arguments
    local formattedMessage = message
    if select('#', ...) > 0 then
        formattedMessage = string.format(message, ...)
    end
    
    print(prefix, formattedMessage)
end

-- Raccourcis pour chaque niveau
function Logger.Debug(category, message, ...)
    Logger.Log('DEBUG', category, message, ...)
end

function Logger.Info(category, message, ...)
    Logger.Log('INFO', category, message, ...)
end

function Logger.Warn(category, message, ...)
    Logger.Log('WARN', category, message, ...)
end

function Logger.Error(category, message, ...)
    Logger.Log('ERROR', category, message, ...)
end

-- Log de séparation pour les sections importantes
function Logger.Section(category, title)
    if Logger.MinLevel > Logger.Levels.DEBUG then return end
    print(string.format('^5[GunGame][%s]^7 ========== %s ==========', category, title))
end

-- Log conditionnel (seulement si une condition est vraie)
function Logger.If(condition, level, category, message, ...)
    if condition then
        Logger.Log(level, category, message, ...)
    end
end

return Logger
