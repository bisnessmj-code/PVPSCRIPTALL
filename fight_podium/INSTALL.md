# 🚀 INSTALLATION RAPIDE - Fight League Podium

## ⏱️ Installation en 5 minutes

### Étape 1 : Extraction
```
1. Téléchargez fight_podium.zip
2. Extrayez dans votre dossier resources/
3. Vérifiez que la structure est correcte:
   resources/
   └── fight_podium/
       ├── fxmanifest.lua
       ├── config/
       ├── client/
       └── README.md
```

### Étape 2 : Configuration
Ouvrez `config/config.lua` et modifiez les coordonnées:

```lua
Config.Props = {
    {
        name = "Podium_1st_Place",
        model = "prop_boxpile_07d",
        position = vector3(-2658.698974, -765.586792, 5.993408),  -- VOS COORDONNÉES ICI
        rotation = vector3(0.0, 0.0, 90.708656),
        zOffset = 0.5,
        scale = vector3(1.0, 1.0, 1.5),
    }
}
```

### Étape 3 : Ajout au server.cfg
Ajoutez cette ligne dans votre `server.cfg`:

```cfg
ensure fight_podium
```

**Position recommandée**: Après ESX/QBCore mais avant vos scripts custom

### Étape 4 : Démarrage
```
1. Redémarrez votre serveur
   OU
2. En jeu: /refresh puis /start fight_podium
```

### Étape 5 : Vérification
```
1. Ouvrez la console F8
2. Activez le debug dans config.lua: Config.Debug = true
3. Allez aux coordonnées configurées
4. Vous devriez voir:
   [PODIUM] Système de podium démarré
   [PODIUM] Prop Podium_1st_Place spawné avec succès
```

## 🎯 Configuration minimale

**Pour commencer rapidement, configurez uniquement:**

```lua
-- Dans config/config.lua

Config.Debug = true  -- Pour voir les logs
Config.RenderDistance = 50.0  -- Distance de rendu

Config.Props = {
    -- Ajoutez vos 3 positions de podium
}
```

Le reste peut rester par défaut!

## 📍 Comment obtenir vos coordonnées?

### Méthode 1: Utilitaire intégré (RECOMMANDÉ)
1. Activez coords_helper.lua dans fxmanifest.lua:
```lua
client_scripts {
    'client/client.lua',
    'client/coords_helper.lua'  -- Décommentez cette ligne
}
```
2. En jeu, utilisez `/getcoords`
3. Copiez depuis la console F8
4. Collez dans config.lua

### Méthode 2: Script externe
Utilisez un script de coordonnées existant (savecoords, etc.)

### Méthode 3: Manuelle
```lua
-- Ajoutez temporairement dans client.lua:
RegisterCommand("mycoords", function()
    local coords = GetEntityCoords(PlayerPedId())
    print(string.format("%.6f, %.6f, %.6f", coords.x, coords.y, coords.z))
end)
```

## ⚡ Commandes utiles

| Commande | Action |
|----------|--------|
| `/podium_reload` | Recharge les props |
| `/podium_clear` | Supprime tous les props |
| `/podium_toggle` | Active/désactive le système |
| `/getcoords` | Affiche vos coordonnées (si coords_helper activé) |

## 🐛 Problèmes courants

### Les props n'apparaissent pas
✅ Vérifiez que vous êtes aux bonnes coordonnées
✅ Activez Config.Debug = true
✅ Regardez la console F8 pour les erreurs
✅ Essayez `/podium_reload`

### Erreur "model not found"
✅ Le nom du prop est incorrect
✅ Utilisez un prop existant dans GTA V
✅ Voir la liste dans README.md

### Props mal orientés
✅ Ajustez le paramètre `rotation`
✅ Le heading est l'angle Z (0-360°)

### Props dans le sol
✅ Augmentez `zOffset`
✅ Ou activez `Config.PlaceOnGround = true`

## 📞 Support rapide

**Avant de demander de l'aide:**
1. ✅ Lisez le README.md complet
2. ✅ Activez Config.Debug = true
3. ✅ Vérifiez la console F8
4. ✅ Essayez `/podium_reload`

**Si le problème persiste:**
- Discord Fight League
- Incluez les logs F8
- Incluez votre config.lua

## 🔧 Optimisation production

**Avant de mettre en prod:**

```lua
Config.Debug = false  // Désactivez le debug
```

**Désactivez coords_helper:**
```lua
// Dans fxmanifest.lua, commentez:
-- 'client/coords_helper.lua'
```

**Ajustez les performances:**
```lua
Config.RenderDistance = 50.0  // Selon vos besoins
Config.Performance.distanceCheckInterval = 1000  // 1 seconde
```

## ✅ Checklist finale

Avant de dire "C'est prêt!":
- [ ] Props apparaissent aux bonnes coordonnées
- [ ] Orientations correctes
- [ ] Config.Debug = false en production
- [ ] coords_helper.lua désactivé
- [ ] Commandes admin testées
- [ ] Performance vérifiée (F8 → resmon)
- [ ] Pas d'erreurs dans F8

## 🎉 C'est parti!

Votre podium est maintenant installé et fonctionnel!

Pour aller plus loin:
- Lisez le README.md complet
- Explorez les options avancées dans config.lua
- Testez les props décoratifs
- Personnalisez les hauteurs avec scale

**Bon jeu! 🎮**
