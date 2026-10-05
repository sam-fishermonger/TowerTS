# TowerTS

Jeu 2D de type Tower Defense, développé avec [Godot 4.7](https://godotengine.org/) (GDScript).

## Prérequis

- Godot **4.7.2-stable** (version standard, pas .NET) : https://godotengine.org/download

## Lancer le projet

1. Ouvrir Godot, cliquer sur **Importer** et sélectionner le fichier `project.godot`.
2. Appuyer sur **F5** : le jeu démarre sur l'écran titre.

## Comment jouer

- Choisir une tour dans la barre du haut (Canon, Mitrailleuse, Sniper), puis cliquer sur une case libre hors du chemin.
- **Maj + clic** pour poser plusieurs tours d'affilée, **clic droit** ou **Échap** pour annuler.
- Survoler une tour de la barre d'achat affiche sa fiche : description, statistiques et prix.
- Cliquer sur une tour posée ouvre sa fiche, avec le bouton **Améliorer** : chaque tour a 2 améliorations (niveau 3 maximum), dont les gains sont affichés en vert avant l'achat. **✕** ou **Échap** ferme la fiche.
- **Lancer la vague** envoie la vague suivante. Chaque ennemi détruit rapporte de l'or, et chaque vague nettoyée donne un bonus.
- La partie est perdue quand les vies tombent à 0, gagnée quand toutes les vagues du niveau sont repoussées. Après une victoire, **Niveau suivant** ouvre le niveau 2 ; l'écran titre permet aussi de choisir un niveau.

## Niveaux

| Niveau | Carte | Tours | Vagues |
|---|---|---|---|
| 1 | Un chemin en zigzag | Canon, Mitrailleuse, Sniper | 5 |
| 2 | Deux entrées (nord et sud) qui se rejoignent, rochers où l'on ne peut pas construire | + Mortier (explosion de zone), Givre (onde qui ralentit) | 6, avec la Carapace (ennemi blindé : les petits dégâts rebondissent) |

## Tests

```
godot --headless --fixed-fps 60 --path . -s res://tests/run_tests.gd
```

`--fixed-fps 60` fait avancer le jeu du même pas à chaque image : les parties simulées donnent alors toujours le même résultat, quelle que soit la machine.

## Architecture

Les objets de jeu héritent de quelques classes de base, et chaque scène ne contient que ce qui lui est propre :

```
Entity (Node2D)              scripts/entities/entity.gd   cycle de vie commun : is_alive, despawn()
├── Enemy                    scripts/enemies/             suit un Path2D, santé, ralentissement
├── Tower                    scripts/towers/tower.gd      ciblage + cadence ; _attack() et _draw_body() à redéfinir
│   ├── ProjectileTower      tire le projectile défini dans TowerData (Canon, Mitrailleuse, Sniper, Mortier)
│   └── PulseTower           onde qui frappe et ralentit tout ce qui est à portée (Givre)
└── Projectile               scripts/projectiles/         tête chercheuse, un seul ennemi touché
    └── ExplosiveProjectile  dégâts de zone à l'impact

Composants                   scripts/components/          HealthComponent (vie, armure), HealthBar
GameMap (Node2D)             scripts/map/game_map.gd      grille, chemins (Path2D enfants), rochers, cases occupées
Level (Node2D)               scripts/levels/level.gd      or, vies, vagues, fin de partie, navigation
├── TowerPlacer              sélection, aperçu et pose des tours à la souris
└── WaveSpawner              fait apparaître les ennemis sur les chemins de la carte
```

`scenes/levels/level.tscn` est la scène de base de tous les niveaux. `level_01.tscn` et `level_02.tscn` en héritent et n'ajoutent que leurs données : chemins, rochers, couleurs, tours disponibles et vagues. Pour créer un niveau 3 : **Scène > Nouvelle scène héritée** depuis `level.tscn`, ajouter un ou plusieurs `Path2D` sous `Map`, puis remplir les vagues du `WaveSpawner`.

Une nouvelle tour se crée sans code si elle réutilise un comportement existant (un `.tres` `TowerData` qui pointe vers `projectile_tower.tscn` ou `pulse_tower.tscn`), ou en sous-classant `Tower` pour un nouveau comportement.

## Structure

```
project.godot        Configuration du projet
scenes/ui/           Écran titre (scène de démarrage) et HUD
scenes/levels/       level.tscn (base) et les niveaux qui en héritent
scenes/enemies/      Ennemi générique (Enemy + Health + HealthBar)
scenes/towers/       ProjectileTower et PulseTower
scenes/projectiles/  Projectile et ExplosiveProjectile
scripts/             Scripts GDScript (.gd), même découpage que scenes/, plus :
scripts/entities/    Classe de base Entity
scripts/components/  Composants réutilisables (santé, barre de vie)
scripts/map/         GameMap
scripts/effects/     Effets visuels (explosion)
scripts/data/        Ressources de données : EnemyData, TowerData, TowerUpgrade, WaveData, SpawnGroup
resources/           Statistiques des ennemis et des tours, améliorations comprises (.tres, modifiables dans l'inspecteur)
tests/               Tests exécutables sans fenêtre
assets/sprites/      Images et sprites
assets/audio/        Musiques et effets sonores
assets/fonts/        Polices
```
