# 🏆 Gunfight Podium v3.0.0

Système d'affichage de podiums pour FiveM - Compatible **qs-appearance** et **pvp_stats_modes**.

## 📋 Fonctionnalités

- **Double podium** : Gunfight Arena et PVP Stats
- **Compatible qs-appearance** : Gestion automatique des skins (modèles freemode ET peds custom)
- **Support pvp_stats_modes** : Classement par mode (1v1, 2v2, 3v3, 4v4)
- **Affichage 3D** : Noms et statistiques au-dessus des PEDs
- **PEDs invincibles** : Protection complète contre les dégâts
- **Animations** : Scénarios configurables par place
- **Mise à jour automatique** : Rafraîchissement périodique des classements
- **Commandes admin** : Gestion via commandes serveur

## 📦 Dépendances

- `es_extended`
- `mysql-async`
- `qs-appearance` (pour les skins)

## 🗄️ Structure Base de Données

### Table `gunfight_stats`
```sql
CREATE TABLE `gunfight_stats` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `player_name` VARCHAR(100) DEFAULT NULL,
    `kills` INT(11) DEFAULT 0,
    `deaths` INT(11) DEFAULT 0,
    `best_streak` INT(11) DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `identifier` (`identifier`)
);
```

### Table `pvp_stats_modes`
```sql
CREATE TABLE `pvp_stats_modes` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `mode` ENUM('1v1','2v2','3v3','4v4') NOT NULL,
    `elo` INT(11) DEFAULT 1000,
    `rank_id` INT(11) DEFAULT 1,
    `best_elo` INT(11) DEFAULT 1000,
    `kills` INT(11) DEFAULT 0,
    `deaths` INT(11) DEFAULT 0,
    `wins` INT(11) DEFAULT 0,
    `losses` INT(11) DEFAULT 0,
    `matches_played` INT(11) DEFAULT 0,
    `win_streak` INT(11) DEFAULT 0,
    `best_win_streak` INT(11) DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `identifier_mode` (`identifier`, `mode`)
);
```

### Table `users` (existante - qs-appearance)
Le script récupère le skin depuis la colonne `skin` de la table `users` au format JSON qs-appearance.

## ⚙️ Configuration

### Positions des Podiums
```lua
Config.PodiumGunfight = {
    [1] = { pos = vector3(x, y, z), heading = 0.0, label = "🥇" },
    [2] = { pos = vector3(x, y, z), heading = 0.0, label = "🥈" },
    [3] = { pos = vector3(x, y, z), heading = 0.0, label = "🥉" }
}

Config.PodiumPVP = {
    [1] = { pos = vector3(x, y, z), heading = 0.0, label = "🥇" },
    [2] = { pos = vector3(x, y, z), heading = 0.0, label = "🥈" },
    [3] = { pos = vector3(x, y, z), heading = 0.0, label = "🥉" }
}
```

### Mode PVP
```lua
Config.PVPMode = "1v1" -- "1v1", "2v2", "3v3", "4v4"
```

### Critères de Classement
```lua
Config.RankingCriteria = {
    gunfight = "kd",  -- "kd" ou "kills"
    pvp = "elo"       -- "elo" ou "wins"
}
```

## 🎮 Commandes

### Serveur (Console & Admin)
| Commande | Description |
|----------|-------------|
| `refreshpodium` | Rafraîchir tous les podiums |
| `showpodium [gunfight/pvp/all]` | Afficher le top 3 actuel |
| `setpvpmode <1v1/2v2/3v3/4v4>` | Changer le mode PVP affiché |

### Client
| Commande | Description |
|----------|-------------|
| `podiumdebug` | Afficher les infos de debug |
| `podiumrefresh` | Demander un rafraîchissement |

## 📤 Exports

```lua
-- Serveur
exports['gunfight_podium']:GetTop3Gunfight()
exports['gunfight_podium']:GetTop3PVP()
exports['gunfight_podium']:GetAllTop3()
exports['gunfight_podium']:GetCurrentPVPMode()
```

## 🎨 Format Skin qs-appearance

Le script gère automatiquement le format qs-appearance :
- `model` : Nom du modèle (freemode ou custom)
- `components` : Vêtements `[{component_id, drawable, texture}]`
- `props` : Accessoires `[{prop_id, drawable, texture}]`
- `headBlend` : Mélange du visage
- `headOverlays` : Barbe, sourcils, maquillage, etc.
- `faceFeatures` : Traits du visage
- `hair` : Style et couleur des cheveux
- `eyeColor` : Couleur des yeux

### Support des PEDs Custom
Le script détecte automatiquement si le modèle est un ped freemode (`mp_m_freemode_01` / `mp_f_freemode_01`) ou un ped custom (ex: `u_m_y_zombie_01`).

- **Freemode** : Application complète du skin (components, props, head, etc.)
- **Custom** : Chargement du modèle + application basique des components/props

## 📝 Changelog

### v3.0.0
- ✅ Compatibilité qs-appearance
- ✅ Support pvp_stats_modes avec modes
- ✅ Gestion des PEDs custom
- ✅ Commande setpvpmode pour changer le mode affiché
- ✅ Amélioration du debug
- ✅ Optimisation du parsing JSON

### v2.4.0
- Version initiale (esx_skin)

## 🐛 Dépannage

### Les PEDs n'apparaissent pas
1. Vérifier les coordonnées dans `config.lua`
2. Activer `Config.Debug = true`
3. Utiliser `/podiumdebug` pour voir l'état

### Le skin ne s'applique pas
1. Vérifier que la colonne `skin` dans `users` contient des données JSON valides
2. Vérifier les logs serveur pour les erreurs de parsing
3. S'assurer que le modèle existe dans le jeu

### Aucune donnée PVP
1. Vérifier que la table `pvp_stats_modes` existe
2. Vérifier que des joueurs ont joué dans le mode configuré
3. Utiliser `/showpodium pvp` pour voir le top 3

## 📄 Licence

Script développé pour usage FiveM.
