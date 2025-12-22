# 🎯 HEADSHOT SYSTEM - Installation Complète

## 📦 Contenu

- **fxmanifest.lua** - Configuration de la ressource
- **client.lua** - Script de détection headshot x5 + anti-casque
- **data/weapons.meta** - Modification des dégâts des armes

## 🚀 Installation

### 1. Extraction
Extraire le dossier `headshot_system` dans votre dossier `resources/[custom]/` de votre serveur FiveM.

Structure finale :
```
resources/
└── [custom]/
    └── headshot_system/
        ├── fxmanifest.lua
        ├── client.lua
        ├── data/
        │   └── weapons.meta
        └── README.md
```

### 2. Activation dans server.cfg
Ajouter cette ligne dans votre `server.cfg` :
```
ensure headshot_system
```

### 3. Redémarrage
Redémarrer votre serveur FiveM.

## ✅ Vérification

Une fois le serveur lancé, vous devriez voir dans la console :
```
Starting resource headshot_system
Started resource headshot_system
```

## 🎮 Fonctionnement

### Headshot x5
- **Dégâts normaux** : ~34 HP
- **Headshot** : ~170 HP (x5)
- **Résultat** : 1-2 headshots = mort garantie

### Anti-Casque
- Les casques sont automatiquement retirés
- Protection pare-balle désactivée (Flag 438)
- Headshots critiques forcés

### Compatibilité
✅ Compatible avec GunGame
✅ Compatible avec PVP Gunfight
✅ Fonctionne avec tous les frameworks (ESX, QB, standalone)

## 🔧 Configuration

### Modifier le multiplicateur
Dans `client.lua`, ligne 8 :
```lua
DamageMultiplier = 5.0,  -- Changer ici (1.0 à 10.0)
```

### Activer les logs de debug
Dans `client.lua`, ligne 10 :
```lua
Debug = true,  -- Mettre à true pour voir les logs
```

### Commandes en jeu
```
/hsdebug  - Toggle les logs de debug
/hsinfo   - Afficher la configuration
```

## 📝 Armes modifiées

### Pistolets (x10 multiplicateur)
- SNS Pistol, Pistol, Combat Pistol
- Pistol .50, Heavy Pistol, Revolver
- AP Pistol

### SMG (x10 multiplicateur)
- Micro SMG, Mini SMG, SMG
- Assault SMG, Combat PDW
- Machine Pistol

### Fusils d'Assaut (x10 multiplicateur)
- Assault Rifle, Carbine Rifle
- Advanced Rifle, Special Carbine
- Bullpup Rifle, Compact Rifle

### Shotguns (x10 multiplicateur)
- Pump Shotgun, Sawed-Off Shotgun
- Assault Shotgun, Combat Shotgun
- Heavy Shotgun, Bullpup Shotgun

### Snipers (x15 multiplicateur)
- Sniper Rifle
- Heavy Sniper, Heavy Sniper MK2
- Marksman Rifle, Marksman Rifle MK2

## ⚠️ Notes importantes

1. **Performances** : Le script vérifie les casques toutes les 5 secondes pour optimiser les performances.

2. **Compatibilité** : Si vous avez déjà un `weapons.meta` custom, il faudra fusionner les fichiers.

3. **OneSync** : Fonctionne avec ou sans OneSync, mais OneSync améliore la détection à longue distance.

## 🐛 Problèmes connus

### "Suicide" détecté au lieu du tueur
→ Activez OneSync dans votre `server.cfg` :
```
set onesync on
```

### Headshot ne fait pas assez de dégâts
→ Augmentez le multiplicateur dans `client.lua` :
```lua
DamageMultiplier = 10.0,  -- x10 au lieu de x5
```

### Les casques protègent encore
→ Vérifiez que le script est bien démarré :
```
restart headshot_system
```

## 📞 Support

Si vous rencontrez des problèmes :
1. Vérifiez les logs F8 (client)
2. Vérifiez la console serveur
3. Activez le debug : `/hsdebug`
4. Tapez `/hsinfo` pour voir la config

## 🎯 Résumé

**Avant :**
- 4-6 tirs pour tuer
- Casques protègent
- Headshots = dégâts normaux

**Après :**
- 1-2 headshots pour tuer
- Casques désactivés
- Headshots x5 dégâts

---

**Version:** 1.0.0  
**Auteur:** Headshot System  
**License:** MIT
