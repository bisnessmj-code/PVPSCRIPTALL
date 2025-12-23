# 🚀 GUIDE D'INSTALLATION - ESX SafeZone v2.0.0

## 📋 PRÉ-REQUIS

### Serveur FiveM
- ✅ FiveM Server (version récente recommandée)
- ✅ ESX Legacy installé et fonctionnel
- ✅ MySQL/MariaDB configuré

### Scripts recommandés (optionnel)
- qs-multicharacter (1.4.50+)
- qs_inventory / ox_inventory

---

## 📦 INSTALLATION COMPLÈTE

### Étape 1 : Téléchargement

**Option A : GitHub**
```bash
cd resources/[standalone]
git clone https://github.com/votre-repo/esx_safezone.git
```

**Option B : Manuel**
```bash
# Téléchargez le ZIP
# Extrayez dans resources/[standalone]/esx_safezone/
```

### Étape 2 : Structure des fichiers

Vérifiez que la structure est correcte :

```
esx_safezone/
├── client/
│   └── main.lua          # ✅ Script client optimisé
├── server/
│   └── main.lua          # ✅ Script serveur
├── config.lua            # ✅ Configuration des zones
├── fxmanifest.lua        # ✅ Manifest FiveM
├── README.md             # ✅ Documentation
├── CHANGELOG.md          # ✅ Historique
└── INSTALLATION.md       # ✅ Ce fichier
```

### Étape 3 : Configuration server.cfg

Ajoutez dans votre `server.cfg` :

```cfg
# SafeZone System (v2.0.0 - Optimisé)
ensure esx_safezone
```

**Position recommandée** :
```cfg
ensure es_extended
ensure esx_multicharacter  # ou qs-multicharacter
# ... autres scripts ESX ...
ensure esx_safezone        # ⚠️ Après les scripts de base
```

### Étape 4 : Configuration des zones

Éditez `config.lua` selon vos besoins :

#### Configuration de base
```lua
Config.Debug = false       -- false en production
Config.ServerLogs = false  -- false en production

Config.Visual = {
    showMarkers = true,    -- Afficher les markers
    showBlips = true,      -- Afficher les blips
}

Config.Notifications = {
    enabled = true,
    type = 'chat',         -- 'esx' ou 'chat'
}
```

#### Ajout d'une zone
```lua
Config.SafeZones = {
    {
        name = 'Spawn Principal',
        id = 'spawn_main',
        geometry = {
            type = 'cylinder',  -- ou 'sphere'
            position = vector3(-269.4, -955.3, 31.2),  -- Vos coordonnées
            radius = 25.0,
            height = 20.0,
        },
        effects = {
            disableWeapons = true,
            speedMultiplier = 2.0,
            godMode = true,
        },
        teleport = {
            enabled = false,  -- ⚠️ Désactivé pour compatibilité
            position = vector4(x, y, z, heading),
            onExit = false,
        },
        visual = {
            marker = {
                enabled = true,
                type = 1,
                color = {r = 0, g = 255, b = 0, a = 20},
            },
            blip = {
                enabled = true,
                sprite = 310,
                color = 2,
                label = 'Zone Sécurisée',
            }
        },
        enabled = true,
    },
}
```

### Étape 5 : Obtention des coordonnées

#### Méthode 1 : En jeu
```lua
-- Tapez /pos en jeu (ou utilisez un script de coordonnées)
-- Exemple de sortie : vector3(-269.4, -955.3, 31.2)
```

#### Méthode 2 : Script temporaire
```lua
-- Dans F8 console
RegisterCommand('getpos', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    print(string.format("vector3(%.1f, %.1f, %.1f)", coords.x, coords.y, coords.z))
end)
```

### Étape 6 : Démarrage

```bash
# Dans la console serveur ou F8
restart esx_safezone

# Vérification
safezone info
```

---

## 🔧 CONFIGURATION AVANCÉE

### Optimisation Performances

#### Serveur bas de gamme (1-20 joueurs)
```lua
Config.Performance = {
    checkIntervals = {
        inZone = 500,
        nearBorder = 250,
        outsideZone = 1000,
    },
}
```

#### Serveur moyen (20-64 joueurs)
```lua
Config.Performance = {
    checkIntervals = {
        inZone = 750,      -- Augmenté
        nearBorder = 500,  -- Augmenté
        outsideZone = 1500, -- Augmenté
    },
}
```

#### Serveur haut de gamme (64-128 joueurs)
```lua
Config.Performance = {
    checkIntervals = {
        inZone = 500,
        nearBorder = 250,
        outsideZone = 1000,
    },
    streamingDistance = 300.0,  // Augmenté
}
```

### Configuration Multi-Zones

```lua
Config.SafeZones = {
    -- Zone 1 : Hôpital
    {
        name = 'Hôpital Pillbox',
        id = 'hospital',
        geometry = {
            type = 'cylinder',
            position = vector3(297.5, -584.5, 43.3),
            radius = 30.0,
            height = 25.0,
        },
        effects = {
            disableWeapons = true,
            godMode = true,
        },
        enabled = true,
    },
    
    -- Zone 2 : Commissariat
    {
        name = 'Commissariat LSPD',
        id = 'lspd',
        geometry = {
            type = 'cylinder',
            position = vector3(441.5, -982.0, 30.7),
            radius = 35.0,
            height = 30.0,
        },
        effects = {
            disableWeapons = true,
            speedMultiplier = 1.5,
        },
        enabled = true,
    },
    
    -- Zone 3 : Garage Central
    {
        name = 'Garage Central',
        id = 'central_garage',
        geometry = {
            type = 'sphere',
            position = vector3(215.9, -809.5, 30.7),
            radius = 20.0,
        },
        effects = {
            disableWeapons = true,
        },
        enabled = true,
    },
}
```

---

## 🔄 MISE À JOUR DEPUIS v1.x

### Sauvegarde (IMPORTANT)

```bash
# 1. Sauvegardez l'ancienne version
cd resources/[standalone]
mv esx_safezone esx_safezone_BACKUP_$(date +%Y%m%d)

# 2. Sauvegardez votre config.lua
cp esx_safezone_BACKUP_*/config.lua ~/config_backup.lua
```

### Installation v2.0.0

```bash
# 1. Installez la nouvelle version
# (suivez Étape 1-3 ci-dessus)

# 2. Récupérez vos zones depuis l'ancienne config
# Copiez UNIQUEMENT la section Config.SafeZones
```

### Modifications requises

#### Dans config.lua

**AVANT (v1.x)** :
```lua
teleport = {
    enabled = true,
    onExit = true,
}
```

**APRÈS (v2.0.0)** :
```lua
teleport = {
    enabled = false,  -- ⚠️ CHANGÉ pour compatibilité
    onExit = false,   -- ⚠️ CHANGÉ pour éviter freeze
}
```

### Test après migration

```
1. Redémarrez le serveur
2. Connectez-vous
3. Tapez /safezone info
4. Vérifiez que "Intervalle: 500-1000ms" (pas 10-20ms)
5. Testez l'entrée/sortie de zone
```

---

## 🐛 RÉSOLUTION DE PROBLÈMES

### Problème 1 : Serveur freeze au spawn

**Symptôme** :
```
[server] Error: Loop svMain seems hung!
[tx:FxMonitor] Restarting server
```

**Solution** :
```lua
// Vérifiez que vous utilisez bien la v2.0.0
// Dans fxmanifest.lua :
version '2.0.0'

// Dans client/main.lua, vérifiez l'absence de :
Wait(10)  // ❌ NE DOIT PAS EXISTER

// Doit avoir :
Wait(250)  // ✅ Thread contrôles
Wait(500)  // ✅ Thread principal (zone)
Wait(1000) // ✅ Thread principal (hors zone)
```

### Problème 2 : Armes non désactivées

**Symptôme** : Les joueurs peuvent toujours utiliser leurs armes

**Solution** :
```lua
// Dans config.lua, pour chaque zone :
effects = {
    disableWeapons = true,  // ✅ Vérifiez cette ligne
}
```

### Problème 3 : Conflit avec qs-multicharacter

**Symptôme** : Boucle infinie au spawn

**Solution** :
```lua
// Dans config.lua :
teleport = {
    enabled = false,  // ✅ DOIT être false
    onExit = false,   // ✅ DOIT être false
}

// Protection spawn activée :
Config.Performance = {
    spawnProtectionTime = 2000,  // ✅ 2 secondes minimum
}
```

### Problème 4 : Markers invisibles

**Symptôme** : Pas de markers visibles

**Solution** :
```lua
// Vérifiez distance
local dist = #(yourCoords - zone.geometry.position)
// Doit être < 100.0 pour affichage

// Vérifiez config
Config.Visual = {
    showMarkers = true,  // ✅ true
}

visual = {
    marker = {
        enabled = true,  // ✅ true
        color = {r = 0, g = 255, b = 0, a = 50},  // ✅ alpha > 0
    }
}
```

### Problème 5 : Blips manquants

**Symptôme** : Pas de blips sur la carte

**Solution** :
```lua
Config.Visual = {
    showBlips = true,  // ✅ true
}

visual = {
    blip = {
        enabled = true,  // ✅ true
        sprite = 310,
        color = 2,
    }
}

// Rechargez les blips
/safezone reload
```

---

## ✅ VÉRIFICATION POST-INSTALLATION

### Checklist

```
☐ Script démarre sans erreur
☐ Aucun freeze serveur
☐ /safezone info fonctionne
☐ Entrée dans zone détectée
☐ Armes désactivées dans zone
☐ Sortie de zone détectée
☐ Armes réactivées hors zone
☐ Markers visibles (si activés)
☐ Blips visibles (si activés)
☐ Notifications fonctionnelles
☐ Compatible qs-multicharacter
☐ CPU < 0.1% (F8 > resmon)
```

### Tests recommandés

#### Test 1 : Performance
```
1. F8 > resmon
2. Cherchez "esx_safezone"
3. Vérifiez : 0.00ms idle, <0.01ms actif
```

#### Test 2 : Fonctionnalités
```
1. Entrez dans zone → Notification + armes retirées
2. Sortez de zone → Notification + armes rendues
3. Retour dans zone → Système se réactive
```

#### Test 3 : Spawn
```
1. Déconnectez-vous
2. Reconnectez-vous avec qs-multicharacter
3. Vérifiez : pas de freeze, spawn normal
```

---

## 📞 SUPPORT

### Debug Mode

Activez temporairement :
```lua
Config.Debug = true
Config.ServerLogs = true
```

Logs détaillés apparaîtront dans F8 et console serveur.

### Commandes utiles

```
/safezone info      # Informations debug
/safezone reload    # Recharge les blips

# Serveur (admin)
/safezone_list      # Liste joueurs en zones
/safezone_stats     # Statistiques détaillées
```

### Rapport de bug

Incluez :
1. Version FiveM server
2. Version script (2.0.0)
3. Logs avec Config.Debug = true
4. Étapes pour reproduire
5. Comportement attendu vs réel

---

## 🎓 RESSOURCES

### Documentation
- [README.md](README.md) - Documentation complète
- [CHANGELOG.md](CHANGELOG.md) - Historique des changements

### Scripts compatibles
- ESX Legacy : https://github.com/esx-framework/esx-legacy
- qs-multicharacter : https://store.quasar-store.com/

### Communauté
- Discord FiveM
- Forums CFX

---

**Installation validée ✅**  
**Version : 2.0.0**  
**Date : Décembre 2025**
