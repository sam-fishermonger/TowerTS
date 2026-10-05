# TowerTS

Jeu 2D de type Tower Defense, développé avec [Godot 4.7](https://godotengine.org/) (GDScript).

## Prérequis

- Godot **4.7.2-stable** (version standard, pas .NET) : https://godotengine.org/download

## Lancer le projet

1. Ouvrir Godot, cliquer sur **Importer** et sélectionner le fichier `project.godot`.
2. Appuyer sur **F5** : le jeu démarre sur l'écran titre.

## Comment jouer

- Choisir une tour dans la barre d'achat, en bas à gauche (une case par tour : son image, son nom et son prix, grisée quand l'or manque), puis cliquer sur une case libre hors du chemin.
- **Maj + clic** pour poser plusieurs tours d'affilée, **clic droit** ou **Échap** pour annuler.
- Survoler une case de la barre d'achat affiche, juste au-dessus, la fiche de la tour : description, statistiques et prix.
- Cliquer sur une tour posée ouvre sa fiche, avec le bouton **Améliorer** : chaque tour a 2 améliorations (niveau 3 maximum), dont les gains sont affichés en vert avant l'achat.
- Dans la même fiche, **Vendre** retire la tour et rend 70 % de ce qu'elle a coûté (améliorations comprises), et le bouton **Cible** choisit l'ennemi visé en priorité : Premier (le plus avancé, par défaut), Dernier, Le plus fort (le plus de vie) ou Le plus proche. Le Givre frappe tout ce qui est à portée et n'a donc pas ce choix.
- **✕** ou **Échap** ferme la fiche.
- **Lancer la vague** envoie la vague suivante. Chaque ennemi détruit rapporte de l'or, et chaque vague nettoyée donne un bonus.
- Sous le bouton, un encadré annonce la composition de la prochaine vague. La lancer alors que des ennemis sont encore en jeu rapporte une prime : la moitié de son bonus, versée tout de suite (réglable dans la propriété `early_call_bonus_ratio` du niveau).
- Les dégâts infligés s'affichent au-dessus des ennemis touchés. Un ennemi détruit affiche l'or gagné et laisse au sol une tache qui s'estompe en 20 secondes.
- Quand un ennemi atteint la base, l'écran rougit brièvement, le compteur de vies grossit en rouge et « -N » s'affiche à la sortie.
- En bas à droite : **Pause** (ou **Espace**) fige la partie (on peut toujours poser, améliorer et vendre des tours, mais pas lancer de vague), et **x1 / x2 / x3** (ou les touches **1, 2, 3**, aussi sur le pavé numérique et en AZERTY) règlent la vitesse du jeu. Les vitesses proposées se changent dans la propriété `game_speeds` du niveau.
- La partie est perdue quand les vies tombent à 0, gagnée quand toutes les vagues du niveau sont repoussées. Une victoire rapporte des étoiles : 3 sans perdre de vie, 2 en gardant au moins la moitié des vies, 1 sinon. Après une victoire, **Niveau suivant** ouvre le niveau d'après.
- La progression est enregistrée : chaque niveau gagné débloque le suivant, et l'écran titre affiche le meilleur résultat de chaque niveau. **Continuer** reprend au premier niveau pas encore gagné ; **Effacer la progression** (en bas à gauche) repart de zéro.
- **Améliorations** (écran titre) ouvre l'arbre des améliorations permanentes, payées avec les étoiles gagnées sur les niveaux. Trois branches : **Tours** (dégâts, portée, cadence, ralentissement), **Or** (or de départ, or par ennemi, bonus de vague, prix réduits, meilleure revente) et **Vies** (vies de départ, vies rendues à chaque vague repoussée). Chaque amélioration se débloque quand celles qui la précèdent sont achetées. L'arbre complet coûte plus d'étoiles que la campagne n'en rapporte : il faut choisir, et **Réinitialiser l'arbre** rend toutes les étoiles pour essayer une autre combinaison. Les améliorations, leurs prix et leurs bonus se règlent dans `resources/perk_tree.tres`.

- Chaque tour a son bruit de tir, et les explosions, les ennemis détruits, les achats, les vagues et la fin de partie ont le leur, avec une musique en boucle. **Musique** et **Sons** se coupent séparément, sur l'écran titre comme en jeu (en bas à droite, même pendant la pause) ; le choix est enregistré.

## Images

Les tours, les ennemis, les rochers et la base sont des images SVG dans `assets/sprites/` (importées en 2x pour rester nettes). Chaque type de tour a sa tourelle (`turret_texture`, qui pivote vers la cible sauf si `turret_rotates` est décoché) posée sur un socle commun ; chaque ennemi a son image (`texture`), tournée dans le sens de la marche. Sans image, la tour ou l'ennemi est dessiné en code comme avant : on peut remplacer les SVG par d'autres images sans toucher au code.

## Sons

Tous les sons et la musique sont synthétisés par `tools/generate_sounds.py` (Python 3 et ffmpeg), sans banque de sons : modifier le script puis le relancer réécrit les fichiers de `assets/audio/`. Le son de tir d'une tour se choisit dans sa ressource (`attack_sound`).

## Niveaux

| Niveau | Carte | Tours | Vagues |
|---|---|---|---|
| 1 | Un chemin en zigzag | Canon, Mitrailleuse, Sniper | 5 |
| 2 | Deux entrées (nord et sud) qui se rejoignent, rochers où l'on ne peut pas construire | + Mortier (explosion de zone), Givre (onde qui ralentit) | 6, avec la Carapace (ennemi blindé : les petits dégâts rebondissent) |
| 3 | Un long chemin en serpentin dans un marais | + Rayon (rayon continu dont les dégâts montent jusqu'à x3 sur la même cible) | 7, avec le Slime géant (se divise en 3 Slimes à sa mort) |
| 4 | Le carrefour : un chemin qui se recoupe lui-même, deux allées parallèles | Les 6 | 8 |
| 5 | Le canyon : trois entrées (ouest, sud et nord) qui se rejoignent au centre | Les 6 | 8, réparties sur les trois entrées |
| 6 | La spirale : le chemin tourne jusqu'à la base, au centre de la carte | Les 6 | 10 |

Les niveaux se suivent dans l'ordre de `resources/campaign.tres` : pour ajouter un niveau, il suffit de l'y ajouter.

## Tests

```
godot --headless --fixed-fps 60 --path . -s res://tests/run_tests.gd
```

`--fixed-fps 60` fait avancer le jeu du même pas à chaque image : les parties simulées donnent alors toujours le même résultat, quelle que soit la machine.

## Architecture

Les objets de jeu héritent de quelques classes de base, et chaque scène ne contient que ce qui lui est propre :

```
Entity (Node2D)              scripts/entities/entity.gd   cycle de vie commun : is_alive, despawn()
├── Enemy                    scripts/enemies/             suit un Path2D, santé, ralentissement, division à la mort
├── Tower                    scripts/towers/tower.gd      ciblage + cadence ; _attack() et _draw_body() à redéfinir
│   ├── ProjectileTower      tire le projectile défini dans TowerData (Canon, Mitrailleuse, Sniper, Mortier)
│   ├── PulseTower           onde qui frappe et ralentit tout ce qui est à portée (Givre)
│   └── BeamTower            rayon continu dont les dégâts montent sur la même cible (Rayon)
└── Projectile               scripts/projectiles/         tête chercheuse, un seul ennemi touché
    └── ExplosiveProjectile  dégâts de zone à l'impact

Composants                   scripts/components/          HealthComponent (vie, armure), HealthBar
GameMap (Node2D)             scripts/map/game_map.gd      grille, chemins (Path2D enfants), rochers, cases occupées
Level (Node2D)               scripts/levels/level.gd      or, vies, vagues, fin de partie, navigation
├── TowerPlacer              sélection, aperçu et pose des tours à la souris
└── WaveSpawner              fait apparaître les ennemis sur les chemins de la carte
```

`scenes/levels/level.tscn` est la scène de base de tous les niveaux. Les niveaux (`level_01.tscn` à `level_06.tscn`) en héritent et n'ajoutent que leurs données : chemins, rochers, couleurs, tours disponibles et vagues. La base est dessinée au bout du premier chemin. Pour créer un nouveau niveau : **Scène > Nouvelle scène héritée** depuis `level.tscn`, ajouter un ou plusieurs `Path2D` sous `Map`, puis remplir les vagues du `WaveSpawner`.

Une nouvelle tour se crée sans code si elle réutilise un comportement existant (un `.tres` `TowerData` qui pointe vers `projectile_tower.tscn` ou `pulse_tower.tscn`), ou en sous-classant `Tower` pour un nouveau comportement.

## Structure

```
project.godot        Configuration du projet
scenes/ui/           Écran titre (scène de démarrage), arbre des améliorations et HUD
scenes/levels/       level.tscn (base) et les niveaux qui en héritent
scenes/enemies/      Ennemi générique (Enemy + Health + HealthBar)
scenes/towers/       ProjectileTower et PulseTower
scenes/projectiles/  Projectile et ExplosiveProjectile
scripts/             Scripts GDScript (.gd), même découpage que scenes/, plus :
scripts/entities/    Classe de base Entity
scripts/components/  Composants réutilisables (santé, barre de vie)
scripts/map/         GameMap
scripts/effects/     Effets visuels (explosion, textes flottants, taches, voile rouge de perte de vies)
scripts/data/        Ressources de données : EnemyData, TowerData, TowerUpgrade, WaveData, SpawnGroup, Perk, PerkTree
scripts/save/        Progression enregistrée (Progress) et améliorations permanentes achetées (Perks)
resources/           Statistiques des ennemis et des tours, améliorations comprises (.tres, modifiables dans l'inspecteur)
tests/               Tests exécutables sans fenêtre
assets/sprites/      Images et sprites
assets/audio/        Musiques et effets sonores
assets/fonts/        Polices
```
