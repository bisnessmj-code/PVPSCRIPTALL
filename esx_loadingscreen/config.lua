--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║          CONFIGURATION LOADING SCREEN - 2025                 ║
    ║              Serveur GunFight                                ║
    ╚══════════════════════════════════════════════════════════════╝
]]

Config = {}

-- ════════════════════════════════════════════════════════════════
-- TEXTES PERSONNALISABLES
-- ════════════════════════════════════════════════════════════════

Config.ServerTitle = " Fight League GunFight"
Config.ServerSubtitle = "Préparez-vous au combat"
Config.LoadingText = "Chargement"

-- ════════════════════════════════════════════════════════════════
-- PARAMÈTRES VISUELS
-- ════════════════════════════════════════════════════════════════

-- Nom du fichier image de fond (dans le dossier /images/)
Config.BackgroundImage = "background.webp"

-- Active l'effet de flou sur le fond
Config.EnableBlur = true
Config.BlurIntensity = 8

-- Opacité de l'overlay sombre (0.0 à 1.0)
Config.OverlayOpacity = 0.5

-- ════════════════════════════════════════════════════════════════
-- MUSIQUE DE FOND
-- ════════════════════════════════════════════════════════════════

-- Active la musique
Config.EnableMusic = true

-- Nom du fichier audio (dans /audio/)
Config.MusicFile = "loading_music.mp3"

-- Volume par défaut (0.0 à 1.0)
Config.DefaultVolume = 0.4

-- Boucle automatique
Config.MusicLoop = true

-- Afficher les contrôles audio
Config.ShowMusicControls = true

-- Position des contrôles : "bottom-left", "bottom-right", "top-left", "top-right"
Config.ControlsPosition = "bottom-left"

-- ════════════════════════════════════════════════════════════════
-- PARAMÈTRES D'ANIMATION
-- ════════════════════════════════════════════════════════════════

Config.DotsAnimationSpeed = 1.5
Config.ContentFadeInDuration = 2

-- ════════════════════════════════════════════════════════════════
-- FADE
-- ════════════════════════════════════════════════════════════════

Config.Fade = true
Config.FadeOutDuration = 0
Config.FadeInDuration = 2500
Config.FadeDelay = 3000

-- ════════════════════════════════════════════════════════════════
-- DEBUG (LOGS DANS LA CONSOLE)
-- ════════════════════════════════════════════════════════════════

Config.Debug = true -- TOUJOURS TRUE pour voir les logs !
