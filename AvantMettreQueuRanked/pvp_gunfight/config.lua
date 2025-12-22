-- ========================================
-- PVP GUNFIGHT - CONFIGURATION
-- Version 4.0.0 - Architecture Ultra-Optimisée
-- ========================================

Config = {}

-- ========================================
-- SYSTÈME DE DEBUG
-- ========================================
Config.Debug = {
    enabled = false, -- 🔴 DÉSACTIVÉ PAR DÉFAUT EN PRODUCTION
    
    levels = {
        info = false,
        success = false,
        warning = true,
        error = true,
        client = false,
        server = false,
        ui = false,
        bucket = false,
        elo = false,
        zones = false,
        groups = false,
        matchmaking = false
    }
}

-- ========================================
-- CONFIGURATION PERFORMANCE (NOUVEAU)
-- ========================================
Config.Performance = {
    -- Intervalles des threads (en ms)
    intervals = {
        pedInteraction = 500,       -- Vérification interaction PED (idle)
        pedInteractionClose = 50,   -- Vérification interaction PED (proche)
        deathDetection = 300,       -- Détection de mort backup
        staminaRestore = 150,       -- Restauration stamina (au lieu de Wait(0)!)
        teammateHudUpdate = 1000,   -- Mise à jour des peds coéquipiers
        zoneCheck = 300,            -- Vérification zone de combat
        zoneDomeIdle = 500,         -- Dessin dôme (loin)
    },
    
    -- Distances d'activation (en mètres)
    distances = {
        pedDrawDistance = 50.0,     -- Distance d'affichage du marker PED
        pedInteractDistance = 2.5,  -- Distance d'interaction PED
        zoneDomeDrawDistance = 50.0,-- Distance d'affichage du dôme
        teammateHudDistance = 50.0, -- Distance d'affichage HUD coéquipiers
    },
    
    -- Cache
    cache = {
        coordsRefreshRate = 100,    -- Rafraîchissement des coordonnées (ms)
        stateRefreshRate = 500,     -- Rafraîchissement des états (ms)
    }
}

-- ========================================
-- CONFIGURATION DISCORD
-- ========================================
Config.Discord = {
    enabled = true,
    botToken = '',
    avatarSize = 128,
    avatarFormat = 'png',
    defaultAvatar = 'https://cdn.discordapp.com/embed/avatars/0.png',
    cacheDuration = 300
}

-- ========================================
-- CONFIGURATION DU PED
-- ========================================
Config.PedLocation = {
    coords = vector4(225.639556, -861.454956, 30.054932, 2.834646),
    model = 's_m_y_dealer_01',
    scenario = 'WORLD_HUMAN_CLIPBOARD'
}

Config.InteractionDistance = 2.5
Config.DrawMarker = false

-- ========================================
-- CONFIGURATION DES ARÈNES
-- ========================================
Config.Arenas = {
 ['arena_industrial_2'] = {
        name = "Zone Industrielle #2",
        zone = {
            center = vector3(563.0, -1778.5, 29.2),
            radius = 24.0
        },
        teamA = {
            vector4(560.202210, -1788.725220, 29.195556, 306.141724),
            vector4(558.408814, -1788.039550, 29.195556, 79.370080),
            vector4(556.417602, -1786.654908, 29.195556, 14.173228),
            vector4(556.707702, -1791.679078, 29.195556, 8.503936)
        },
        teamB = {
            vector4(565.885742, -1769.960450, 29.330444, 144.566926),
            vector4(562.799988, -1771.173584, 29.347290, 130.393708),
            vector4(564.791198, -1766.901124, 29.145020, 192.755906),
            vector4(567.758240, -1768.720826, 29.145020, 212.598420)
        }
    },
     ['arena_industrial_1'] = {
        name = "Zone Industrielle #1",
        zone = {
            center = vector3(474.5, -1677.5, 29.2),
            radius = 30.0
        },
        teamA = {
            vector4(463.107696, -1668.487916, 29.313598, 240.944886),
            vector4(464.597808, -1667.208740, 29.313598, 294.803162),
            vector4(462.224182, -1670.769288, 29.313598, 138.897628),
            vector4(460.918670, -1666.180176, 29.161866, 325.984252)
        },
        teamB = {
            vector4(486.013184, -1686.421998, 29.161866, 300.472442),
            vector4(483.969238, -1688.386840, 29.178710, 136.062988),
            vector4(486.896698, -1683.837402, 29.229248, 323.149598),
            vector4(487.450562, -1688.254882, 29.128174, 243.779526)
        }
    },
     ['arena_maison'] = {
        name = "Maison de Luxe",
        zone = {
            center = vector3(-130.0, 1012.5, 235.85),
            radius = 30.0
        },
        teamA = {
            vector4(-119.960434, 1015.832946, 235.808106, 113.385826),
            vector4(-120.791206, 1017.824158, 235.824952, 110.551186),
            vector4(-121.582412, 1019.802186, 235.824952, 110.551186),
            vector4(-118.589012, 1018.734070, 235.892334, 110.551186)
        },
        teamB = {
            vector4(-140.545060, 1012.813172, 235.808106, 291.968506),
            vector4(-139.740662, 1010.967042, 235.858642, 291.968506),
            vector4(-138.843964, 1008.791198, 235.909180, 289.133850),
            vector4(-141.586808, 1009.503296, 235.926026, 291.968506)
        }
    },
    ['arena_chiotes'] = {
        name = "Chiotes",
        zone = {
            center = vector3(-1389.5, -1326.0, 4.15),
            radius = 30.0
        },
        teamA = {
            vector4(-1392.224122, -1335.507690, 4.139892, 348.661408),
            vector4(-1390.232910, -1335.982422, 4.156738, 320.314972),
            vector4(-1387.582398, -1336.496704, 4.156738, 286.299194),
            vector4(-1389.692260, -1338.685668, 4.257934, 17.007874)
        },
        teamB = {
            vector4(-1386.250488, -1316.268188, 4.156738, 170.078736),
            vector4(-1386.698852, -1318.931884, 4.139892, 170.078736),
            vector4(-1384.615356, -1319.327514, 4.139892, 195.590546),
            vector4(-1388.479126, -1318.694458, 4.139892, 161.574798)
        }
    },
     ['arena_lucky'] = {
        name = "Lucky Street",
        zone = {
            center = vector3(142.0, -1471.0, 29.2),
            radius = 30.0
        },
        teamA = {
            vector4(130.206588, -1455.995606, 29.330444, 232.440948),
            vector4(128.452744, -1457.564820, 29.364136, 229.606292),
            vector4(126.659340, -1459.120850, 29.296752, 229.606292),
            vector4(125.406594, -1460.452758, 29.313598, 232.440948)
        },
        teamB = {
            vector4(157.898896, -1479.375854, 29.111328, 51.023624),
            vector4(156.883514, -1480.852784, 29.111328, 51.023624),
            vector4(155.973632, -1478.360474, 29.128174, 53.858268),
            vector4(156.026368, -1482.356080, 29.111328, 51.023624)
        }
    },
    ['antenne_rebel'] = {
        name = "AntenneRebel",
        zone = {
            center = vector3(467.868134, 3559.397706, 38.109130),
            radius = 30.0
        },
        teamA = {
            vector4(480.448364, 3554.927490, 33.239502, 87.874016),
            vector4(480.632966, 3556.694580, 33.239502, 85.039368),
            vector4(480.883514, 3558.448242, 33.239502, 76.535438),
            vector4(481.028564, 3559.819824, 33.239502, 82.204728)
        },
        teamB = {
            vector4(450.567048, 3559.318604, 33.222656, 269.291352),
            vector4(450.514282, 3560.663818, 33.222656, 274.960632),
            vector4(450.474732, 3561.942872, 33.222656, 272.125976),
            vector4(450.989014, 3563.472412, 33.222656, 269.291352)
        }
    },
    ['gerenal_mechanic'] = {
        name = "mechanic",
        zone = {
            center = vector3(54.712090, 2791.068116, 57.722290),
            radius = 30.0
        },
        teamA = {
            vector4(67.595604, 2782.589112, 57.874024, 51.023624),
            vector4(65.169228, 2784.316406, 57.874024, 51.023624),
            vector4(63.019780, 2782.549560, 57.874024, 53.858268),
            vector4(68.465934, 2784.962646, 57.874024, 51.023624)
        },
        teamB = {
            vector4(39.296704, 2801.960450, 57.874024, 235.275588),
            vector4(38.149452, 2800.443848, 57.874024, 235.275588),
            vector4(36.962638, 2798.795654, 57.874024, 238.110230),
            vector4(40.338462, 2802.975830, 57.874024, 235.275588)
        }
    },
    ['arena_skatepark'] = {
        name = "Skatepark",
        zone = {
            center = vector3(-941.0, -792.0, 15.9),
            radius = 30.0
        },
        teamA = {
            vector4(-950.953858, -800.123046, 15.917968, 320.314972),
            vector4(-949.318664, -801.626342, 15.917968, 320.314972),
            vector4(-946.457154, -802.549438, 15.917968, 320.314972),
            vector4(-949.714294, -803.274720, 15.917968, 323.149598)
        },
        teamB = {
            vector4(-931.081298, -783.626342, 15.917968, 130.393708),
            vector4(-933.718688, -783.309876, 15.917968, 136.062988),
            vector4(-935.182434, -780.738464, 15.917968, 136.062988),
            vector4(-932.531860, -779.709900, 15.917968, 138.897628)
        }
    },
    ['arena_mothel'] = {
        name = "mothel",
        zone = {
            center = vector3(167.749450, -1804.048340, 29.583130),
            radius = 20.0
        },
        teamA = {
            vector4(158.927474, -1810.048340, 28.690064, 320.314972),
            vector4(160.549454, -1811.617554, 28.706910, 320.314972),
            vector4(162.435166, -1813.028564, 28.706910, 320.314972),
            vector4(160.364838, -1812.923096, 28.706910, 320.314972)
        },
        teamB = {
            vector4(172.021972, -1796.835206, 29.111328, 147.401580),
            vector4(173.617584, -1798.443970, 29.128174, 141.732284),
            vector4(170.202194, -1795.450562, 29.128174, 141.732284),
            vector4(173.010986, -1795.991210, 29.060792, 136.062988)
        }
    },
    ['arena_villelucky'] = {
        name = "villelucky",
        zone = {
            center = vector3(-583.846130, -884.887940, 26.21313),
            radius = 30.0
        },
        teamA = {
            vector4(-585.006592, -869.406616, 25.673950, 184.251968),
            vector4(-582.672546, -868.826354, 25.690796, 184.251968),
            vector4(-586.852722, -869.037354, 25.690796, 175.748032),
            vector4(-584.821960, -866.716492, 25.741334, 189.92126)
        },
        teamB = {
            vector4(-584.835144, -900.382446, 25.690796, 5.669292),
            vector4(-586.971436, -900.026368, 25.690796, 14.173228),
            vector4(-582.870300, -899.960450, 25.909912, 2.834646),
            vector4(-585.112060, -902.096680, 25.673950, 0.000000)
        }
    },
    ['arena_villeluc'] = {
        name = "villeluc",
        zone = {
            center = vector3(645.850524, 2728.786866, 41.866700),
            radius = 30.0
        },
        teamA = {
            vector4(645.758240, 2743.015380, 41.866700, 184.251968),
            vector4(647.762634, 2742.975830, 41.883544, 181.417312),
            vector4(649.173646, 2742.962646, 41.883544, 184.251968),
            vector4(643.437378, 2743.068116, 41.866700, 184.251968)
        },
        teamB = {
            vector4(648.303284, 2714.109864, 41.243164, 2.834646),
            vector4(646.338440, 2713.978028, 41.226318, 2.834646),
            vector4(644.307678, 2714.109864, 41.192626, 0.000000),
            vector4(650.584594, 2714.465820, 41.310668, 2.834646)
        }
    }
}

-- ========================================
-- CONFIGURATION DES LOADOUTS
-- ========================================
Config.Loadouts = {
    ['classic'] = {
        name = "Classique",
        weapons = {
            {name = 'WEAPON_PISTOL', ammo = 50},
            {name = 'WEAPON_KNIFE', ammo = 1}
        }
    },
    ['assault'] = {
        name = "Assaut",
        weapons = {
            {name = 'WEAPON_ASSAULTRIFLE', ammo = 100},
            {name = 'WEAPON_PISTOL', ammo = 30}
        }
    }
}

-- ========================================
-- CONFIGURATION DES ROUNDS
-- ========================================
Config.RoundTime = 180
Config.MaxRounds = 5
Config.RespawnDelay = 2

-- ========================================
-- CONFIGURATION ELO
-- ========================================
Config.StartingELO = 0
Config.KFactor = 32
