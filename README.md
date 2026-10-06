# TowerTS

Jeu 2D de type Tower Defense, développé avec [Godot 4.7](https://godotengine.org/) (GDScript).

## Prérequis

- Godot **4.7.2-stable** (version standard, pas .NET) : https://godotengine.org/download

## Lancer le projet

1. Ouvrir Godot, cliquer sur **Importer** et sélectionner le fichier `project.godot`.
2. Appuyer sur **F5** : le jeu démarre sur l'écran titre.

## Télécharger le jeu

Pas besoin d'installer Godot pour jouer : GitHub construit le jeu tout seul (workflow `.github/workflows/build.yml`).

- **Dernière version** : à chaque push sur `main`, la page [Releases](https://github.com/sam-fishermonger/TowerTS/releases) met à jour la pré-release **« Dernière version (main) »** avec trois fichiers :
  - `TowerTS-windows.zip` : décompresser puis lancer `TowerTS.exe`. Le jeu n'étant pas signé, Windows peut afficher « Windows a protégé votre ordinateur » : **Informations complémentaires** puis **Exécuter quand même**.
  - `TowerTS-linux.zip` : décompresser puis lancer `TowerTS.x86_64`.
  - `TowerTS-web.zip` : la version navigateur, à déposer telle quelle sur un hébergeur (itch.io, GitHub Pages…). Ouvrir `index.html` directement depuis le disque ne marche pas : il faut un serveur web, par exemple `python3 -m http.server` dans le dossier décompressé, puis http://localhost:8000.
- **Version numérotée** : créer un tag qui commence par `v` (par exemple `v0.3`, depuis l'onglet Releases de GitHub ou avec `git tag v0.3 && git push origin v0.3`) publie une Release du même nom avec les trois fichiers.
- **Sur une PR** : les fichiers construits sont dans l'onglet **Actions**, en bas de la page du run (**Artifacts**).

Les fichiers construits ne sont pas commités dans le dépôt : ils pèsent plus de 100 Mo chacun et changeraient à chaque modification, ce qui alourdirait l'historique git pour toujours.

### Exporter soi-même

Les réglages d'export sont dans `export_presets.cfg` (Windows, Linux et Web). Dans l'éditeur : **Éditeur > Gérer les modèles d'export** (une fois, pour télécharger les modèles de Godot 4.7.2), puis **Projet > Exporter**. En ligne de commande :

```
godot --headless --path . --export-release "Windows" build/windows/TowerTS.exe
```

Le dossier `build/` est ignoré par git.

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
- La campagne compte **trois mondes** de 6 niveaux, un par biome, chacun avec ses monstres : **La Ruche** (insectoïdes et xénomorphes), **La Fonderie** (mecha) et **La Cité** (humanoïdes). **Mondes** (écran titre) ouvre la sélection : une carte par monde, avec ses monstres, ses étoiles et un bouton par niveau.
- La progression est enregistrée : chaque niveau gagné débloque le suivant, et gagner le dernier niveau d'un monde débloque le monde suivant (l'écran de victoire propose alors **Monde suivant**). La sélection affiche le meilleur résultat de chaque niveau. **Continuer** reprend au premier niveau pas encore gagné ; **Effacer la progression** (en bas à gauche de l'écran titre) repart de zéro.
- **Améliorations** (écran titre) ouvre l'arbre des améliorations permanentes, payées avec les étoiles gagnées sur les niveaux. Deux onglets :
  - **Bonus**, en trois branches : **Tours** (dégâts, portée, cadence, ralentissement), **Or** (or de départ, or par ennemi, bonus de vague, prix réduits, meilleure revente) et **Vies** (vies de départ, vies rendues à chaque vague repoussée) ;
  - **Tours des mondes** : une branche par monde, avec deux nouvelles tours chacune (voir plus bas). La branche d'un monde s'ouvre quand ce monde est débloqué, et une tour achetée apparaît dans la barre d'achat de tous les niveaux.

  Chaque amélioration se débloque quand celles qui la précèdent sont achetées. L'arbre complet coûte 53 étoiles (la campagne en rapporte 54) : il faut choisir, et **Réinitialiser l'arbre** rend toutes les étoiles pour essayer une autre combinaison. Les améliorations, leurs prix et leurs bonus se règlent dans `resources/perk_tree.tres`.

- Chaque tour a son bruit de tir, et les explosions, les ennemis détruits, les achats, les vagues et la fin de partie ont le leur, avec une musique en boucle. **Musique** et **Sons** se coupent séparément, sur l'écran titre comme en jeu (en bas à droite, même pendant la pause) ; le choix est enregistré.

## Images

Les tours, les ennemis, les rochers et la base sont des images SVG dans `assets/sprites/` (importées en 2x pour rester nettes). Chaque type de tour a sa tourelle (`turret_texture`, qui pivote vers la cible sauf si `turret_rotates` est décoché) posée sur un socle commun ; chaque ennemi a son image (`texture`), tournée dans le sens de la marche. Sans image, la tour ou l'ennemi est dessiné en code comme avant : on peut remplacer les SVG par d'autres images sans toucher au code.

## Sons

Tous les sons et la musique sont synthétisés par `tools/generate_sounds.py` (Python 3 et ffmpeg), sans banque de sons : modifier le script puis le relancer réécrit les fichiers de `assets/audio/`. Le son de tir d'une tour se choisit dans sa ressource (`attack_sound`).

## Mondes et monstres

Chaque monde a ses monstres, rangés dans `resources/enemies/<biome>/` avec leur image dans `assets/sprites/enemies/<biome>/`. Les rôles se répondent d'un monde à l'autre (un ennemi de base, un rapide, un blindé, un qui se divise, un gros), et chaque biome a sa spécialité.

| Monde | Monstres | Spécialité |
|---|---|---|
| 1. La Ruche (insectoïdes) | Larve, Rôdeur (rapide), Scarabée (carapace : les petits dégâts rebondissent), Ravageur (gros), Couveuse (éclate en 3 Larves) | Les essaims et les ennemis qui se divisent |
| 2. La Fonderie (mecha) | Drone (rapide), Sentinelle, Chenillard (très blindé), Porte-drones (libère 3 Drones), Titan (énorme) | **Bouclier d'énergie** (Sentinelle, Titan) : il encaisse les coups en premier, sans armure, et se recharge après 2 secondes sans être touché. Une barre bleue s'affiche au-dessus de la barre de vie. |
| 3. La Cité (humanoïdes) | Soldat, Éclaireur (rapide), Garde (bouclier anti-émeute : armure), Médecin, Transport de troupes (libère 4 Soldats), Colosse (énorme) | **Soin** (Médecin) : il rend régulièrement des points de vie aux ennemis blessés autour de lui (onde et « +N » verts). Mieux vaut l'abattre en premier. |

Le bouclier et le soin se règlent dans la ressource de l'ennemi (`EnemyData`, groupes **Bouclier** et **Soin**) : n'importe quel ennemi peut en avoir.

### Tours des mondes

Chaque monde a deux tours à débloquer dans l'arbre des améliorations (onglet **Tours des mondes**), chacune avec un atout contre les monstres de son biome. Elles s'ajoutent à la barre d'achat de tous les niveaux une fois achetées.

| Monde | Tour | Prix | Atout |
|---|---|---|---|
| La Ruche | **Lance-flammes** | ★ 3 | Jet de flammes en cône qui touche tout un essaim et le fait brûler. La brûlure passe sous l'armure (Scarabée). |
| La Ruche | **Pesticide** | ★ 4 | Grenades qui laissent un nuage de poison sur le chemin pendant 4 s ; le poison passe sous l'armure, et les larves d'une Couveuse naissent dedans. |
| La Fonderie | **Brouilleur IEM** | ★ 4 | Onde qui fait 5 fois plus de dégâts aux boucliers d'énergie, qui ne se rechargent plus pendant 4 s. |
| La Fonderie | **Perforateur** | ★ 5 | Tir instantané qui traverse tous les ennemis alignés en ignorant leur armure (Chenillard, Titan). |
| La Cité | **Franc-tireur** | ★ 5 | Vise les soigneurs en premier ; un ennemi touché ne peut plus être soigné, ni soigner, pendant 4 s. |
| La Cité | **Lacrymogène** | ★ 6 | Grenades dont le nuage ralentit les ennemis et empêche tout soin à l'intérieur. |

Ces effets se règlent dans la ressource de la tour (`TowerData`, groupes **Effets spéciaux**, **Nuage** et **Flammes**) : brûlure ou poison, coups qui ignorent l'armure, dégâts multipliés sur les boucliers, bouclier brouillé, soins bloqués, priorité aux soigneurs. N'importe quelle tour peut les combiner. La seconde tour d'une branche demande la première, et la branche ne s'ouvre qu'avec son monde (`required_world` de l'amélioration).

| Niveau | Carte | Vagues |
|---|---|---|
| 1-1 | Un chemin en zigzag (Canon, Mitrailleuse, Sniper) | 5 |
| 1-2 | Deux entrées (nord et sud) qui se rejoignent, + Mortier et Givre | 6, avec le Scarabée |
| 1-3 | Un long chemin en serpentin dans un marais, + Rayon | 7, avec la Couveuse |
| 1-4 | Le carrefour : un chemin qui se recoupe lui-même | 8 |
| 1-5 | Le canyon : trois entrées (ouest, sud et nord) | 8 |
| 1-6 | La spirale : la base est au centre de la carte | 10 |
| 2-1 | La chaîne de montage : trois allers-retours | 6 |
| 2-2 | Deux convoyeurs (ouest et sud-ouest) qui se rejoignent | 7, avec le Porte-drones |
| 2-3 | Le puits : on entre par le nord, en créneaux | 7 |
| 2-4 | La fonderie à l'envers : de l'est vers l'ouest | 8, avec le Titan |
| 2-5 | Deux chemins qui se croisent deux fois | 8 |
| 2-6 | Le cœur : une boucle autour de la base, et une entrée à l'est | 10 |
| 3-1 | Les faubourgs | 6 |
| 3-2 | Le boulevard en escalier | 7, avec le Médecin |
| 3-3 | La place : entrées au nord et au sud | 7, avec le Transport de troupes |
| 3-4 | Le pont : un chemin qui se recoupe trois fois | 8, avec le Colosse |
| 3-5 | Les trois avenues : ouest, nord et sud | 8 |
| 3-6 | Le palais : un long détour et une entrée au sud | 10 |

À partir du niveau 1-4, les 6 tours sont disponibles. Les mondes et leurs niveaux se suivent dans l'ordre de `resources/campaign.tres`, qui liste les mondes (`resources/worlds/*.tres` : nom, description, couleur, monstres montrés et niveaux) : pour ajouter un niveau, il suffit de l'ajouter à son monde.

## Tests

```
godot --headless --fixed-fps 60 --path . -s res://tests/run_tests.gd
```

`--fixed-fps 60` fait avancer le jeu du même pas à chaque image : les parties simulées donnent alors toujours le même résultat, quelle que soit la machine.

## Architecture

Les objets de jeu héritent de quelques classes de base, et chaque scène ne contient que ce qui lui est propre :

```
Entity (Node2D)              scripts/entities/entity.gd   cycle de vie commun : is_alive, despawn()
├── Enemy                    scripts/enemies/             suit un Path2D, santé, ralentissement, division à la mort, soin
├── Tower                    scripts/towers/tower.gd      ciblage + cadence ; _attack() et _draw_body() à redéfinir
│   ├── ProjectileTower      tire le projectile défini dans TowerData (Canon, Mitrailleuse, Sniper, Mortier, Franc-tireur, Pesticide, Lacrymogène)
│   ├── PulseTower           onde qui frappe tout ce qui est à portée (Givre, Brouilleur IEM)
│   ├── BeamTower            rayon continu dont les dégâts montent sur la même cible (Rayon)
│   ├── FlameTower           cône de flammes qui brûle tout ce qu'il touche (Lance-flammes)
│   └── RailTower            tir instantané qui traverse toute une ligne (Perforateur)
└── Projectile               scripts/projectiles/         tête chercheuse, un seul ennemi touché
    ├── ExplosiveProjectile  dégâts de zone à l'impact
    └── CloudProjectile      laisse un nuage (GasCloud) qui applique les effets de la tour (Pesticide, Lacrymogène)

Composants                   scripts/components/          HealthComponent (vie, armure, bouclier), HealthBar
Hud (CanvasLayer)            scripts/ui/hud.gd            barres du haut et du bas, fiches, écran de fin
├── TowerShop                barre d'achat : une case TowerShopButton (TowerIcon, nom, prix) par tour
├── AudioToggles             boutons Musique et Sons (aussi sur l'écran titre)
└── TowerInfoPanel           fiche d'un type de tour (survol) ou d'une tour posée
GameMap (Node2D)             scripts/map/game_map.gd      grille, chemins (Path2D enfants), rochers, cases occupées
Level (Node2D)               scripts/levels/level.gd      or, vies, vagues, fin de partie, navigation
├── TowerPlacer              sélection, aperçu et pose des tours à la souris
└── WaveSpawner              fait apparaître les ennemis sur les chemins de la carte
```

`scenes/levels/level.tscn` est la scène de base de tous les niveaux. Les niveaux (`level_01.tscn` à `level_06.tscn` pour La Ruche, `mecha_01.tscn` à `mecha_06.tscn` et `humanoid_01.tscn` à `humanoid_06.tscn`) en héritent et n'ajoutent que leurs données : chemins, rochers, couleurs, tours disponibles et vagues. La base est dessinée au bout du premier chemin. Pour créer un nouveau niveau : **Scène > Nouvelle scène héritée** depuis `level.tscn`, ajouter un ou plusieurs `Path2D` sous `Map`, puis remplir les vagues du `WaveSpawner`.

Une nouvelle tour se crée sans code si elle réutilise un comportement existant (un `.tres` `TowerData` qui pointe vers `projectile_tower.tscn` ou `pulse_tower.tscn`), ou en sous-classant `Tower` pour un nouveau comportement.

## Structure

```
project.godot        Configuration du projet
export_presets.cfg   Réglages d'export (Windows, Linux, Web)
scenes/ui/           Écran titre (scène de démarrage), sélection des mondes, arbre des améliorations, HUD, fiches et boutons du son
scenes/levels/       level.tscn (base) et les niveaux qui en héritent
scenes/enemies/      Ennemi générique (Enemy + Health + HealthBar)
scenes/towers/       ProjectileTower, PulseTower, BeamTower, FlameTower et RailTower
scenes/projectiles/  Projectile, ExplosiveProjectile et CloudProjectile
scripts/             Scripts GDScript (.gd), même découpage que scenes/, plus :
scripts/entities/    Classe de base Entity
scripts/components/  Composants réutilisables (santé, barre de vie)
scripts/map/         GameMap
scripts/effects/     Effets visuels (explosion, textes flottants, taches, voile rouge de perte de vies)
scripts/data/        Ressources de données : Campaign, World, EnemyData, TowerData, TowerUpgrade, WaveData, SpawnGroup, Perk, PerkTree
scripts/save/        Progression enregistrée (Progress) et améliorations permanentes achetées (Perks)
resources/           Campagne et mondes, statistiques des ennemis (un dossier par biome) et des tours (.tres, modifiables dans l'inspecteur)
tests/               Tests exécutables sans fenêtre
assets/sprites/      Images et sprites
assets/audio/        Musiques et effets sonores
assets/fonts/        Police de l'interface : Open Sans + symboles ★ ☆ ✕ (voir LICENCES.md)
```
