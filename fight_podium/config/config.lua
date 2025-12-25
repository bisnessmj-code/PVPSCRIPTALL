--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                    CONFIGURATION PODIUM                       ║
    ║           Fichier de configuration principal du script        ║
    ╚═══════════════════════════════════════════════════════════════╝
]]

Config = {}

-- ═══════════════════════════════════════════════════════════════
--  PARAMÈTRES GÉNÉRAUX
-- ═══════════════════════════════════════════════════════════════

Config.Debug = false                     -- Active les logs de debug dans F8
Config.RenderDistance = 50.0           -- Distance de rendu des props (mètres)
Config.UseCollisions = true            -- Active/désactive les collisions des props
Config.FreezeProps = true              -- Gèle les props (recommandé: true)
Config.PlaceOnGround = false           -- Place automatiquement les props au sol

-- ═══════════════════════════════════════════════════════════════
--  CONFIGURATION DES PROPS DU PODIUM
-- ═══════════════════════════════════════════════════════════════

--[[
    PROPS RECOMMANDÉS POUR PODIUM:
    
    Plateformes/Cubes:
    - prop_boxpile_07d        : Caisse carrée moyenne
    - prop_palletsack_01      : Palette avec sacs
    - prop_crate_11e          : Caisse en bois
    - prop_rub_cont_01b       : Container plat
    - prop_consign_02a        : Caisse de consignation
    
    Podium custom:
    - prop_podium_mic         : Podium avec micro
    - prop_lectern_01         : Lutrin
    - v_ilev_uvbox            : Boîte UV (moderne)
    
    Marches/Escaliers:
    - prop_palletsack_01      : Palette (empilable)
    - hei_prop_heist_wooden_box : Caisse en bois empilable
]]

Config.Props = {
    -- ═══════════════════════════════════════════════════════════
    --  POSITION 1 - 1ÈRE PLACE (La plus haute)
    -- ═══════════════════════════════════════════════════════════
    {
        name = "Podium_1st_Place",              -- Nom pour identification
        model = "prop_boxpile_07d",             -- Modèle du prop
        position = vector3(-2650.034912, -775.476135, 2.454208),
        rotation = vector3(0.0, 0.0, 190.980030), -- Rotation X, Y, Z (heading = Z)
        zOffset = 0.5,                          -- Offset en hauteur (ajustement fin)
        
        -- Options avancées
        -- IMPORTANT: La fonction scale n'est PAS supportée dans FiveM
        -- Pour créer différentes hauteurs, utilisez stackedProps (empilement)
        -- ou utilisez des modèles de props différents
        alpha = 255,                            -- Transparence (0-255)
        textureVariation = 0,                   -- Variation de texture
        dynamic = false,                        -- Si true, le prop peut bouger
        visible = true,                         -- Visibilité du prop
        
        -- Props additionnels (empilés)
        stackedProps = {}
    },
    
    -- ═══════════════════════════════════════════════════════════
    --  POSITION 2 - 2ÈME PLACE (Hauteur moyenne)
    -- ═══════════════════════════════════════════════════════════
    {
        name = "Podium_2nd_Place",
        model = "prop_boxpile_07a",
        position = vector3(-2649.384033, -776.21746, 3.073953),
        rotation = vector3(0.0, 0.0, 31.938431),
        zOffset = 0.3,
        
        alpha = 255,
        textureVariation = 0,
        dynamic = false,
        visible = true,
        
        stackedProps = {}
    },
    
    -- ═══════════════════════════════════════════════════════════
    --  POSITION 2 - 2ÈME PLACE (Hauteur moyenne)
    -- ═══════════════════════════════════════════════════════════
    {
        name = "Podium_5nd_Place",
        model = "prop_boxpile_07a",
        position = vector3(-2648.342285, -767.230408, 2.962413),
        rotation = vector3(0.0, 0.0, 98.706520),
        zOffset = 0.3,
        
        alpha = 255,
        textureVariation = 0,
        dynamic = false,
        visible = true,
        
        stackedProps = {}
    },
	
    {
        name = "Podium_8nd_Place",
        model = "w_ar_assaultrifle",
        position = vector3(-2649.432617, -766.294739, 3.787268),
        rotation = vector3(0.0, 250.0, 180.309639),
        zOffset = 0.3,
        
        alpha = 255,
        textureVariation = 0,
        dynamic = false,
        visible = true,
        
        stackedProps = {}
    },

	{
        name = "Podium_9nd_Place",
        model = "w_ar_assaultrifle",
        position = vector3(-2649.213135, -768.191223, 3.587268),
        rotation = vector3(0.0, 250.0, 180.309639),
        zOffset = 0.3,
        
        alpha = 255,
        textureVariation = 0,
        dynamic = false,
        visible = true,
        
        stackedProps = {}
    },

    
    -- ═══════════════════════════════════════════════════════════
    --  POSITION 3 - 3ÈME PLACE (La plus basse)
    -- ═══════════════════════════════════════════════════════════


    {
            name = "Podium_vst_Place",              -- Nom pour identification
            model = "prop_rub_carwreck_9",             -- Modèle du prop
            position = vector3(-2647.956543, -760.336609, 3.01452),
            rotation = vector3(0.0, -10.0, 190.238831), -- Rotation X, Y, Z (heading = Z)
            zOffset = 0.5,                          -- Offset en hauteur (ajustement fin)

            -- Options avancées
            -- IMPORTANT: La fonction scale n'est PAS supportée dans FiveM
            -- Pour créer différentes hauteurs, utilisez stackedProps (empilement)
            -- ou utilisez des modèles de props différents
            alpha = 255,                            -- Transparence (0-255)
            textureVariation = 0,                   -- Variation de texture
            dynamic = false,                        -- Si true, le prop peut bouger
            visible = true,                         -- Visibilité du prop

            -- Props additionnels (empilés)
            stackedProps = {}
        },
}

-- ═══════════════════════════════════════════════════════════════
--  CONFIGURATION DES PROPS DÉCORATIFS (Optionnel)
-- ═══════════════════════════════════════════════════════════════

Config.DecorativeProps = {
    enabled = false,                    -- Active les props décoratifs
    
    props = {
        -- Exemple: Barrières autour du podium
        -- {
        --     model = "prop_barrier_work05",
        --     position = vector3(-2660.0, -765.0, 5.99),
        --     rotation = vector3(0.0, 0.0, 90.0)
        -- }
    }
}

-- ═══════════════════════════════════════════════════════════════
--  CONFIGURATION DES EFFETS VISUELS (Optionnel)
-- ═══════════════════════════════════════════════════════════════

Config.VisualEffects = {
    enabled = false,                    -- Active les effets visuels
    
    -- Lumières
    lights = {
        enabled = false,
        color = {r = 255, g = 215, b = 0}, -- Couleur or
        intensity = 10.0,
        range = 15.0
    },
    
    -- Particules (avancé)
    particles = {
        enabled = false,
        effect = "core",
        name = "ent_amb_sparking_wires"
    }
}

-- ═══════════════════════════════════════════════════════════════
--  CONFIGURATION DE PERFORMANCE
-- ═══════════════════════════════════════════════════════════════

Config.Performance = {
    -- Intervalle de vérification de distance (millisecondes)
    distanceCheckInterval = 1000,       -- 1 seconde (recommandé: 500-2000)
    
    -- Nettoie les props au changement de routing bucket
    -- NOTE: Fonctionnalité désactivée car GetPlayerRoutingBucket n'est pas disponible côté client
    cleanOnRoutingBucketChange = false,
    
    -- Nettoie les props en sortant de la zone
    cleanOnPlayerLeft = true,
    
    -- Distance à laquelle les props sont supprimés (si cleanOnPlayerLeft = true)
    cleanDistance = 100.0
}

-- ═══════════════════════════════════════════════════════════════
--  MESSAGES DE DEBUG (Personnalisables)
-- ═══════════════════════════════════════════════════════════════

Config.Messages = {
    propSpawned = "^2[PODIUM]^0 Prop ^3%s^0 spawné avec succès",
    propDeleted = "^1[PODIUM]^0 Prop ^3%s^0 supprimé",
    modelLoaded = "^2[PODIUM]^0 Modèle ^3%s^0 chargé",
    modelFailed = "^1[PODIUM]^0 Échec du chargement du modèle ^3%s^0",
    systemStarted = "^2[PODIUM]^0 Système de podium démarré",
    systemStopped = "^1[PODIUM]^0 Système de podium arrêté",
    propsCleared = "^3[PODIUM]^0 Tous les props ont été nettoyés"
}

-- ═══════════════════════════════════════════════════════════════
--  COMMANDES ADMIN (Optionnel)
-- ═══════════════════════════════════════════════════════════════

Config.AdminCommands = {
    enabled = false,                     -- Active les commandes admin
    
    commands = {
        reload = "podium_reload",       -- Recharge le podium
        clear = "podium_clear",         -- Supprime tous les props
        toggle = "podium_toggle"        -- Active/désactive le podium
    },
    
    -- Permission ACE (optionnel)
    acePermission = "podium.admin"      -- Nécessite: add_ace group.admin podium.admin allow
}

--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                      NOTES IMPORTANTES                        ║
    ╠═══════════════════════════════════════════════════════════════╣
    ║                                                               ║
    ║  1. MODÈLES DE PROPS                                          ║
    ║     • Tous les props doivent exister dans GTA V               ║
    ║     • Vérifiez sur https://wiki.rage.mp/index.php?title=Objects ║
    ║                                                               ║
    ║  2. COORDONNÉES                                               ║
    ║     • Utilisez vector3() pour les positions                   ║
    ║     • Le heading est l'angle de rotation sur l'axe Z          ║
    ║                                                               ║
    ║  3. OPTIMISATION                                              ║
    ║     • Désactivez Config.Debug en production                   ║
    ║     • Ajustez RenderDistance selon vos besoins                ║
    ║     • Utilisez FreezeProps = true pour de meilleures perfs    ║
    ║                                                               ║
    ║  4. EMPILEMENT                                                ║
    ║     • stackedProps permet d'empiler plusieurs props           ║
    ║     • Utile pour créer des hauteurs différentes               ║
    ║                                                               ║
    ╚═══════════════════════════════════════════════════════════════╝
]]
