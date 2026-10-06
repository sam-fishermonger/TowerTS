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

- Sur l'écran titre, une partie se joue toute seule derrière le menu : un niveau de la campagne tiré au hasard (son nom s'affiche en haut à droite), avec des tours posées et améliorées automatiquement. Quand elle se termine, un autre niveau prend la suite. Elle est muette et n'enregistre rien.
- Choisir une tour dans la barre d'achat, en bas à gauche (une case par tour : son image, son nom et son prix, grisée quand l'or manque), ou avec les touches **1 à 9 puis 0** (rangée des chiffres ou pavé numérique, aussi en AZERTY) pour les dix premières cases, dont le chiffre est rappelé dans un coin. Puis cliquer sur une case libre hors du chemin. La même touche repose la tour.
- **Maj + clic** pour poser plusieurs tours d'affilée, **clic droit** ou **Échap** pour annuler.
- Survoler une case de la barre d'achat affiche, juste au-dessus, la fiche de la tour : description, statistiques et prix.
- Cliquer sur une tour posée ouvre sa fiche, avec le bouton **Améliorer** : chaque tour a 2 améliorations (niveau 3 maximum), dont les gains sont affichés en vert avant l'achat.
- Dans la même fiche, **Vendre** retire la tour et rend 70 % de ce qu'elle a coûté (améliorations comprises), et le bouton **Cible** choisit l'ennemi visé en priorité : Premier (le plus avancé, par défaut), Dernier, Le plus fort (le plus de vie) ou Le plus proche. Le Givre frappe tout ce qui est à portée et n'a donc pas ce choix.
- **✕** ou **Échap** ferme la fiche.
- **Lancer la vague** envoie la vague suivante. Chaque ennemi détruit rapporte de l'or, et chaque vague nettoyée donne un bonus. Les ennemis ne marchent pas tous en file au milieu du chemin : chacun tire au hasard sa place sur sa largeur (le tirage dépend du niveau, il est le même à chaque partie).
- Sous le bouton, un encadré annonce la composition de la prochaine vague (élites et boss signalés). Le survoler ouvre sa fenêtre de détail : chaque sorte de monstre avec son nombre, sa vie (difficulté comprise), son armure, son bouclier, sa vitesse, l'or qu'il rapporte, les vies qu'il retire et ses capacités, plus le bonus de la vague.
- Survoler un monstre sur la carte ouvre sa fiche, qui le suit : nom, rang, vie et bouclier restants, statistiques et capacités.
- Lancer la vague alors que des ennemis sont encore en jeu rapporte une prime : la moitié de son bonus, versée tout de suite (réglable dans la propriété `early_call_bonus_ratio` du niveau).
- **Intérêts** : chaque fois que la carte est vidée, l'or gardé rapporte 5 % d'intérêts (25 or au plus), comptés avant le bonus de vague et affichés en « +N intérêts » sous l'or. Le HUD annonce sous l'or ce que rapporterait l'or gardé à ce moment-là. Épargner entre deux vagues rapporte donc un peu, sans dépasser le plafond. Le taux et le plafond se règlent dans les propriétés `interest_rate` et `interest_cap` du niveau.
- **Pouvoirs** : achetés dans l'arbre des améliorations (onglet **Pouvoirs**), ils ont chacun leur bouton en haut de l'écran, à gauche de **Lancer la vague**, et leur touche : **A**, **Z** et **E** en AZERTY (Q, W, E en QWERTY), la lettre étant rappelée dans le coin du bouton. Après chaque usage, un pouvoir se recharge (en temps de jeu : x2 et x3 accélèrent la recharge, la pause l'arrête) ; son bouton montre les secondes restantes. **Météores** et **Renforts** se lancent sur la carte : leur zone suit la souris jusqu'au clic (clic droit ou Échap pour annuler, et la même touche aussi). Le **Gel** part tout de suite. Voir le tableau plus bas.
- Les dégâts infligés s'affichent au-dessus des ennemis touchés. Un ennemi détruit affiche l'or gagné et laisse au sol une tache qui s'estompe en 20 secondes.
- Quand un ennemi atteint la base, l'écran rougit brièvement, le compteur de vies grossit en rouge et « -N » s'affiche à la sortie.
- En bas à droite : **Pause** (ou **Espace**) fige la partie (on peut toujours poser, améliorer et vendre des tours, mais pas lancer de vague), et **x1 / x2 / x3** règlent la vitesse du jeu (**V** passe à la vitesse suivante). Les vitesses proposées se changent dans la propriété `game_speeds` du niveau.
- La partie est perdue quand les vies tombent à 0, gagnée quand toutes les vagues du niveau sont repoussées. Une victoire rapporte des étoiles : 3 sans perdre de vie, 2 en gardant au moins la moitié des vies, 1 sinon. Après une victoire, **Niveau suivant** ouvre le niveau d'après.
- **Difficulté** : en bas de la sélection des mondes, **Facile**, **Moyen**, **Difficile** ou **Cauchemar** règle les parties suivantes (le choix est enregistré, et rappelé en haut à gauche en jeu). Chaque difficulté a ses propres étoiles : un niveau en rapporte jusqu'à 3 par difficulté, soit 12, et 216 pour toute la campagne. Les boutons des niveaux montrent les étoiles de la difficulté choisie (celles des quatre en bulle d'aide), les cartes des mondes le total. Gagner un niveau dans n'importe quelle difficulté débloque le suivant.

  | Difficulté | Vie et bouclier des monstres | Nombre de monstres | Vitesse |
  |---|---|---|---|
  | Facile | -30 % | -25 % | -10 % |
  | Moyen | l'équilibrage des niveaux | | |
  | Difficile | +35 % | +25 % | +10 % |
  | Cauchemar | +75 % | +50 % | +20 % |

  Chaque groupe d'une vague garde à peu près sa durée : les monstres en plus se resserrent, ceux en moins s'espacent. Le mode infini et la partie de l'écran titre se jouent toujours en Moyen. Les réglages sont dans `scripts/data/difficulty.gd`.
- **Tours par niveau** : on ne peut prendre qu'un nombre limité de tours différentes dans un niveau, selon la difficulté : **9** en Facile, **8** en Moyen, **6** en Difficile et **5** en Cauchemar (le mode infini, joué en Moyen, en prend 8). Quand le niveau et l'arbre des améliorations en proposent plus, le niveau s'ouvre sur **Choisir les tours** : une case par tour (sa fiche s'affiche au survol), on en coche jusqu'à la limite, puis **Jouer**. Le dernier choix est coché d'avance au niveau suivant (et en recommençant). Les limites sont dans `TOWER_LIMITS` (`scripts/data/difficulty.gd`).
- **Élites** : chaque niveau a 2 ou 3 monstres élites (aura dorée, « élite » dans leur nom) : vie et bouclier x3, 25 % plus gros, 4 fois plus d'or, 2 vies de plus s'ils passent. Les monstres qu'ils libèrent ou appellent restent normaux.
- **Boss** : un par monde, à la dernière vague des niveaux 3 et 6 (plus coriace au 6). Une aura rouge l'entoure et sa vie s'affiche en haut de la carte tant qu'il est en jeu. La difficulté change sa vie, mais il n'arrive jamais qu'un boss à la fois (en mode infini, il revient avec sa vague, toutes les 3 vagues). Chacun appelle des renforts en marchant :

  | Monde | Boss | Vie | Capacités |
  |---|---|---|---|
  | La Ruche | **Reine de la Ruche** | 4000 (x1,4 au 1-3, x1,5 au 1-6) | Pond 3 Larves toutes les 5 s. |
  | La Fonderie | **Béhémoth** | 3500, bouclier 900, armure 6 (x1,7 au 2-6) | Lâche 2 Drones toutes les 6 s. |
  | La Cité | **Le Général** | 4200, armure 4 (x1,5 au 3-6) | Soigne de 30 points les ennemis autour de lui toutes les 3 s, appelle 3 Soldats toutes les 6 s. |

  Un boss coûte 10 vies s'il atteint la base et rapporte 150 à 170 or. Les élites se règlent dans `scripts/data/enemy_data.gd` (`ELITE_*`) ; un groupe de vague devient élite avec sa case `elite` (`SpawnGroup`), qui a aussi son propre multiplicateur de vie (`health_multiplier`). Un ennemi est un boss avec `is_boss`, et appelle des renforts avec le groupe **Renforts** de sa ressource.
- **Lexique** (écran titre) : la fiche de chaque tour (statistiques, améliorations, comment la débloquer, spécialisation), de chaque monstre (statistiques, capacités, version élite), des élites et des boss, et de chaque monde (monstres, boss, tours du monde, étoiles). Il lit les ressources du jeu : une tour ajoutée dans `resources/towers/` ou un monstre ajouté à un monde y apparaît tout seul.
- **Statistiques de fin de niveau** : l'écran de fin (victoire, défaite ou fin du mode infini) montre à droite le bilan de la partie : durée (en temps de jeu), monstres détruits (dont élites et boss), dégâts infligés, vies perdues, or dépensé (poses et améliorations) et gagné (monstres, bonus de vague, intérêts, primes, ventes), tours posées et améliorations achetées. Puis la **meilleure tour**, celle qui a infligé le plus de dégâts (son niveau, ses dégâts, ses destructions), et les **dégâts par tour** : une ligne par type de tour posé, avec le nombre de tours, une barre, les dégâts et leur part. Chaque coup est compté à la tour qui l'a porté, brûlures et poisons compris, et une tour vendue garde ce qu'elle a fait. Le calcul est dans `scripts/levels/level_stats.gd`.
- **Succès** : 21 objectifs à remplir en jouant, dans n'importe quelle difficulté. Un bandeau doré les annonce en jeu au moment où ils sont remplis, et l'écran de fin liste ceux de la partie. **Succès** (écran titre, avec le compte) ouvre leur page : une vignette par succès, grisée tant qu'il n'est pas débloqué, avec l'avancement des objectifs chiffrés et la date du déblocage. La partie de l'écran titre n'en débloque pas, et **Effacer la progression** les garde.

  | Succès | Objectif |
  |---|---|
  | Premier pas | Gagner un niveau. |
  | Sans une égratignure | Gagner un niveau sans perdre de vie. |
  | Sur le fil | Gagner un niveau avec une seule vie restante. |
  | La Ruche nettoyée, La Fonderie éteinte, La Cité libérée | Gagner tous les niveaux du monde. |
  | Régicide, Démolition, Coup d'État | Vaincre la Reine de la Ruche, le Béhémoth, le Général (mode infini compris). |
  | Commando | Vaincre un boss avec 3 tours ou moins sur la carte. |
  | Minimaliste | Gagner un niveau en posant 5 tours au plus (ventes comprises). |
  | Brut de pose | Gagner un niveau sans améliorer aucune tour. |
  | Monoculture | Gagner un niveau avec un seul type de tour. |
  | Impatient | Lancer 5 vagues en avance dans une même partie. |
  | Trésor de guerre | Gagner un niveau avec 1000 pièces d'or en poche. |
  | Cauchemar vaincu | Gagner un niveau en Cauchemar. |
  | Infatigable | Repousser 30 vagues dans une partie du mode infini. |
  | Chasseur d'élites | Détruire 50 monstres élites (toutes parties confondues). |
  | Exterminateur | Détruire 5000 monstres (toutes parties confondues). |
  | Constellation | Obtenir 100 étoiles. |
  | Jardinier | Acheter 15 améliorations dans l'arbre. |

  Le code Konami, qui gagne tous les niveaux et achète tout l'arbre, débloque du même coup les succès de mondes, d'étoiles et de l'arbre. Les succès sont dans `scripts/save/achievements.gd` (`LIST`) : un succès s'ajoute là, avec son objectif.
- Dans la sélection des mondes, survoler un niveau (ou lui donner le focus au clavier) ouvre sa fenêtre de détail : or et vies de départ, et le contenu de chaque vague dans la difficulté choisie, élites et boss compris.
- La campagne compte **trois mondes** de 6 niveaux, un par biome, chacun avec ses monstres : **La Ruche** (insectoïdes et xénomorphes), **La Fonderie** (mecha) et **La Cité** (humanoïdes). **Mondes** (écran titre) ouvre la sélection : une carte par monde, avec ses monstres, ses étoiles et un bouton par niveau.
- La progression est enregistrée : chaque niveau gagné débloque le suivant, et gagner le dernier niveau d'un monde débloque le monde suivant (l'écran de victoire propose alors **Monde suivant**). La sélection affiche le meilleur résultat de chaque niveau. **Continuer** reprend au premier niveau pas encore gagné ; **Effacer la progression** (en bas à gauche de l'écran titre) repart de zéro.
- **Mode infini** : un niveau gagné avec 3 étoiles (dans n'importe quelle difficulté) s'ouvre en mode infini (bouton **∞ Mode infini** en haut à droite de la sélection des mondes, qui fait passer les cartes au mode infini). Après les vagues du niveau, d'autres arrivent sans fin : elles reprennent en boucle ses 3 dernières vagues, avec à chaque fois 10 % d'ennemis en plus et 13 % de vie (et de bouclier) en plus, d'une vague à l'autre. La partie s'arrête quand les vies tombent à 0. Chaque vague repoussée est enregistrée : record de vagues (en bulle d'aide sur le bouton du niveau) et **étoiles infinies**, en bleu, une toutes les 5 vagues repoussées au-delà de celles du niveau, jusqu'à 5 par niveau (90 en tout). Elles sont une monnaie à part, qui achète les spécialisations des tours. Les réglages sont dans `scripts/levels/wave_spawner.gd` (`ENDLESS_*`) et `scripts/save/progress.gd`.
- **Améliorations** (écran titre) ouvre l'arbre des améliorations permanentes, payées avec les étoiles gagnées sur les niveaux. Quatre onglets :
  - **Bonus**, en trois branches : **Tours** (dégâts, portée, cadence, ralentissement), **Or** (or de départ, or par ennemi, bonus de vague, prix réduits, meilleure revente) et **Vies** (vies de départ, vies rendues à chaque vague repoussée) ;
  - **Tours des mondes** : une branche par monde, avec deux nouvelles tours chacune, puis les **croisements**, qui demandent deux tours de branches différentes (voir plus bas). La branche d'un monde s'ouvre quand ce monde est débloqué, et une tour achetée s'ajoute aux tours proposées dans tous les niveaux ;
  - **Spécialisations**, payées en étoiles infinies : un atout de plus pour chacune des 12 tours de base et des mondes, en trois branches (voir plus bas). Celle d'une tour des mondes demande d'avoir débloqué la tour. La fiche d'une tour rappelle sa spécialisation, déjà comptée dans ses statistiques.
  - **Pouvoirs** : les trois pouvoirs actifs, payés en étoiles (le Gel s'ouvre avec La Fonderie, les Renforts avec La Cité), et sous chacun deux renforts payés en étoiles infinies (voir plus bas).

  Chaque amélioration se débloque quand celles qui la précèdent sont achetées. Les prix montent le long de chaque branche (3 étoiles pour la première amélioration, jusqu'à 13 pour la Bobine et l'Électroaimant) : l'arbre complet coûte 216 étoiles, les 216 de la campagne dans les quatre difficultés. Les étoiles de Facile et Moyen suffisent pour les premières améliorations et les tours des mondes ; il faut aller chercher celles de Difficile et Cauchemar pour finir l'arbre, et ces deux difficultés demandent justement des améliorations. Les spécialisations coûtent 42 étoiles infinies, et les renforts des pouvoirs 21. Il faut choisir, et **Réinitialiser l'arbre** rend toutes les étoiles pour essayer une autre combinaison. Les améliorations, leurs prix et leurs bonus se règlent dans `resources/perk_tree.tres`.

- **Code Konami** : sur l'écran titre, **↑ ↑ ↓ ↓ ← → ← → B A** débloque tout : tous les niveaux gagnés avec 3 étoiles dans les quatre difficultés (donc tous les mondes et tous les modes infinis), toutes les étoiles infinies, toutes les améliorations et toutes les spécialisations. **Effacer la progression** revient en arrière. Les lettres suivent la disposition du clavier (le A d'un clavier AZERTY).
- Chaque tour a son bruit de tir, et les explosions, les ennemis détruits, les achats, les vagues et la fin de partie ont le leur, avec une musique en boucle. **Musique** et **Sons** se coupent séparément, sur l'écran titre comme en jeu (en bas à droite, même pendant la pause) ; le choix est enregistré.

### Pouvoirs

| Pouvoir | Prix | Effet | Recharge | Renforts (étoiles infinies) |
|---|---|---|---|---|
| **Météores** | ★ 3 | 6 météores tombent l'un après l'autre dans un rayon de 70 pixels autour du point visé ; chacun fait 80 dégâts à tous les ennemis à 46 pixels de son point de chute. | 40 s | **Pluie battante** (∞ 3) : +50 % de dégâts. **Comètes** (∞ 4) : recharge 30 % plus rapide. |
| **Gel** | ★ 3, avec La Fonderie | Tous les ennemis de la carte s'arrêtent pendant 3 s (ni marche, ni soins, ni renforts appelés). Un boss ne gèle pas : il ralentit de moitié. | 55 s | **Blizzard** (∞ 3) : 2 s de plus. **Engelures** (∞ 4) : les ennemis gelés subissent 30 % de dégâts en plus. |
| **Renforts** | ★ 4, avec La Cité | 3 soldats (150 vie, 24 dégâts/s) se postent sur le chemin, au plus près du point visé, pendant 20 s. Chacun arrête un ennemi à sa portée et le combat ; l'ennemi retenu le frappe (12 vie/s par vie qu'il coûterait en passant). Les boss ne s'arrêtent pas, mais un soldat libre les frappe au passage. | 45 s | **Vétérans** (∞ 3) : +50 % de vie et de dégâts. **Escouade** (∞ 4) : 2 soldats de plus. |

Un pouvoir est une ressource `Power` (`resources/powers/`). L'amélioration qui le débloque a son chemin dans `unlocks_power`, et celles qui le renforcent dans `improves_power`, avec les champs du groupe **Pouvoirs** de `Perk` (dégâts, recharge, durée, nombre, vulnérabilité).

### Spécialisations

| Branche | Tour | Spécialisation | Prix | Effet |
|---|---|---|---|---|
| Précision | Mitrailleuse | Balles perforantes | ∞ 2 | Ses balles ignorent l'armure. |
| Précision | Sniper | Tir en pleine tête | ∞ 3 | +40 % de dégâts, +10 % de portée. |
| Précision | Franc-tireur | Lunette thermique | ∞ 4 | Tire 35 % plus vite. |
| Précision | Perforateur | Surcharge | ∞ 5 | +40 % de dégâts. |
| Zone | Canon | Boulets lourds | ∞ 2 | +35 % de dégâts, +10 % de portée. |
| Zone | Mortier | Obus incendiaires | ∞ 3 | Ses explosions brûlent : 8 dégâts/s pendant 2 s, sous l'armure. |
| Zone | Lance-flammes | Napalm | ∞ 4 | Brûlure de 8 dégâts/s en plus, 1,5 s de plus. |
| Zone | Pesticide | Nuage tenace | ∞ 5 | Nuage 30 % plus large, 2 s de plus. |
| Contrôle | Givre | Zéro absolu | ∞ 2 | Ralentit 30 % plus fort, 1 s de plus. |
| Contrôle | Rayon | Focalisation | ∞ 3 | Montée en puissance jusqu'à x4,5 au lieu de x3. |
| Contrôle | Brouilleur IEM | Surtension | ∞ 4 | +50 % de dégâts, boucliers brouillés 2 s de plus. |
| Contrôle | Lacrymogène | Gaz suffocant | ∞ 5 | Son nuage empoisonne aussi : 10 dégâts/s, sous l'armure. |

Une spécialisation est une amélioration de l'arbre (`Perk`) avec `paid_with_endless_stars` et `specializes_tower` (la tour visée) : ses bonus de tour (groupes **Tours** et **Spécialisation**) ne s'appliquent qu'à cette tour.

## Images

Les tours, les ennemis, les rochers et la base sont des images SVG dans `assets/sprites/` (importées en 2x pour rester nettes). Chaque type de tour a sa tourelle (`turret_texture`, qui pivote vers la cible sauf si `turret_rotates` est décoché) posée sur un socle commun ; chaque ennemi a son image (`texture`), tournée dans le sens de la marche. Sans image, la tour ou l'ennemi est dessiné en code comme avant : on peut remplacer les SVG par d'autres images sans toucher au code.

Chaque biome a ses **tuiles** (`assets/sprites/tiles/<biome>.png`, une planche de 8 x 3 tuiles de 64 pixels, lue par le `TileSet` de `resources/tilesets/`) :

- 8 sols, en gris, teintés avec la couleur du sol du niveau (`ground_color`) : sol organique en alvéoles pour La Ruche, plaques de métal rivetées (tôle striée, grilles d'aération) pour La Fonderie, dalles et pavés pour La Cité ;
- 8 détails en couleur semés sur le sol libre (œufs, bave, champignons ; taches d'huile, boulons, câbles ; herbes, plaques d'égout, feuilles mortes…) ;
- 4 obstacles qui remplacent les rochers des cases bloquées (ruches, sacs d'œufs, épines ; caisses, barils, machines ; murs en ruine, arbres, barricades), teintés avec `rock_color`, et 4 petits détails semés sur le chemin (cailloux, fissures).

La carte (`GameMap`) prend les tuiles du monde de son niveau (`tileset` de `resources/worlds/*.tres`) et les pose en deux calques `TileMapLayer` sous le chemin ; un niveau peut en choisir d'autres dans sa propriété `tileset`, ou régler `decal_density` et `path_detail_spacing`. Le tirage dépend du niveau : la carte est la même à chaque partie. Les tuiles sont dessinées par `tools/generate_tilesets.py` (Python 3, Pillow et numpy) : modifier le script puis le relancer réécrit les planches.

## Sons

Tous les sons et la musique sont synthétisés par `tools/generate_sounds.py` (Python 3 et ffmpeg), sans banque de sons : modifier le script puis le relancer réécrit les fichiers de `assets/audio/`. Le son de tir d'une tour se choisit dans sa ressource (`attack_sound`).

## Mondes et monstres

Chaque monde a ses monstres, rangés dans `resources/enemies/<biome>/` avec leur image dans `assets/sprites/enemies/<biome>/`. Les rôles se répondent d'un monde à l'autre (un ennemi de base, un rapide, un blindé, un qui se divise, un gros), et chaque biome a sa spécialité.

| Monde | Monstres | Spécialité |
|---|---|---|
| 1. La Ruche (insectoïdes) | Larve, Rôdeur (rapide), Scarabée (carapace : les petits dégâts rebondissent), Ravageur (gros), Couveuse (éclate en 3 Larves) | Les essaims et les ennemis qui se divisent |
| 2. La Fonderie (mecha) | Drone (rapide), Sentinelle, Chenillard (très blindé), Porte-drones (libère 3 Drones), Titan (énorme) | **Bouclier d'énergie** (Sentinelle, Titan) : il encaisse les coups en premier, sans armure, et se recharge après 2 secondes sans être touché. Une barre bleue s'affiche au-dessus de la barre de vie. |
| 3. La Cité (humanoïdes) | Soldat, Éclaireur (rapide), Garde (bouclier anti-émeute : armure), Médecin, Transport de troupes (libère 4 Soldats), Colosse (énorme) | **Soin** (Médecin) : il rend régulièrement des points de vie aux ennemis blessés autour de lui (onde et « +N » verts). Mieux vaut l'abattre en premier. |

Le bouclier, le soin et les renforts se règlent dans la ressource de l'ennemi (`EnemyData`, groupes **Bouclier**, **Soin** et **Renforts**) : n'importe quel ennemi peut en avoir. Sa `description` est celle du lexique.

### Tours des mondes

Chaque monde a deux tours à débloquer dans l'arbre des améliorations (onglet **Tours des mondes**), chacune avec un atout contre les monstres de son biome. Elles s'ajoutent à la barre d'achat de tous les niveaux une fois achetées.

| Monde | Tour | Prix | Atout |
|---|---|---|---|
| La Ruche | **Lance-flammes** | ★ 5 | Jet de flammes en cône qui touche tout un essaim et le fait brûler. La brûlure passe sous l'armure (Scarabée). |
| La Ruche | **Pesticide** | ★ 8 | Grenades qui laissent un nuage de poison sur le chemin pendant 4 s ; le poison passe sous l'armure, et les larves d'une Couveuse naissent dedans. |
| La Fonderie | **Brouilleur IEM** | ★ 7 | Onde qui fait 5 fois plus de dégâts aux boucliers d'énergie, qui ne se rechargent plus pendant 4 s. |
| La Fonderie | **Perforateur** | ★ 10 | Tir instantané qui traverse tous les ennemis alignés en ignorant leur armure (Chenillard, Titan). |
| La Cité | **Franc-tireur** | ★ 9 | Vise les soigneurs en premier ; un ennemi touché ne peut plus être soigné, ni soigner, pendant 4 s. |
| La Cité | **Lacrymogène** | ★ 12 | Grenades dont le nuage ralentit les ennemis et empêche tout soin à l'intérieur. |

Ces effets se règlent dans la ressource de la tour (`TowerData`, groupes **Effets spéciaux**, **Nuage** et **Flammes**) : brûlure ou poison, coups qui ignorent l'armure, dégâts multipliés sur les boucliers, bouclier brouillé, soins bloqués, priorité aux soigneurs. N'importe quelle tour peut les combiner. La seconde tour d'une branche demande la première, et la branche ne s'ouvre qu'avec son monde (`required_world` de l'amélioration).

### Croisements

Sous les tours des mondes, l'arbre se croise : chaque croisement demande deux tours de branches différentes, et ses traits vont en diagonale de l'une à l'autre. Les uns débloquent une nouvelle tour, mélange des deux ; dans les autres, les deux tours s'échangent un effet.

| Croisement | Demande | Prix | Effet |
|---|---|---|---|
| **Arc électrique** | Pesticide + Perforateur | ★ 12 | Débloque l'Arc électrique : un éclair instantané qui rebondit 3 fois d'ennemi en ennemi (le plus proche pas encore touché, à 110 pixels au plus), avec un quart de dégâts en moins à chaque rebond. +50 % de dégâts sur les boucliers d'énergie. Chaque amélioration ajoute un rebond. |
| **Bobine** | Perforateur + Lacrymogène | ★ 13 | Débloque la Bobine : elle ne tire pas, mais les tours des 8 cases autour d'elle font 25 % de dégâts en plus et tirent 15 % plus vite (+10 points par amélioration, et la dernière agrandit sa portée). Plusieurs Bobines ne s'additionnent pas : une tour garde le bonus de la plus forte. La fiche d'une tour renforcée le dit. |
| **Électroaimant** | Arc électrique + Bobine | ★ 13 | Débloque l'Électroaimant : son onde fait reculer de 45 pixels tous les ennemis à portée sur leur chemin. Les gros reculent moins (une Couveuse 30 % de moins), et un ennemi qui vient de reculer ne peut plus reculer pendant 1,5 s : plusieurs Électroaimants ne le bloquent pas sur place. |
| **Nuage ionisé** | Pesticide + Arc électrique | ★ 10 | L'Arc empoisonne ce qu'il touche (8 dégâts/s pendant 2 s, sous l'armure), et les nuages du Pesticide brouillent les boucliers d'énergie pendant 2,5 s. |
| **Gaz sous tension** | Lacrymogène + Bobine | ★ 10 | La Bobine ralentit de 25 % les ennemis à sa portée et bloque leurs soins, comme le gaz, et le Lacrymogène tire 20 % plus loin et 25 % plus vite. |

Un croisement qui échange des effets est une amélioration (`Perk`) avec `crossing`, dont `specializes_tower` reçoit les effets, et `partner_effect` une seconde amélioration avec les effets de l'autre tour (son `specializes_tower`). Comme pour les spécialisations, ces effets ne s'appliquent qu'à leur tour, et la fiche de la tour les rappelle (« Croisement : … »).

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
│   ├── PulseTower           onde qui frappe tout ce qui est à portée (Givre, Brouilleur IEM, Électroaimant)
│   │   └── CoilTower        ne tire pas : renforce les tours voisines (Bobine), voir Level.refresh_boosts()
│   ├── ArcTower             éclair qui rebondit d'ennemi en ennemi (Arc électrique)
│   ├── BeamTower            rayon continu dont les dégâts montent sur la même cible (Rayon)
│   ├── FlameTower           cône de flammes qui brûle tout ce qu'il touche (Lance-flammes)
│   └── RailTower            tir instantané qui traverse toute une ligne (Perforateur)
└── Projectile               scripts/projectiles/         tête chercheuse, un seul ennemi touché
    ├── ExplosiveProjectile  dégâts de zone à l'impact
    └── CloudProjectile      laisse un nuage (GasCloud) qui applique les effets de la tour (Pesticide, Lacrymogène)

Composants                   scripts/components/          HealthComponent (vie, armure, bouclier), HealthBar
Hud (CanvasLayer)            scripts/ui/hud.gd            barres du haut et du bas, fiches, écran de fin, fenêtres de détail (vague, monstre)
├── TowerShop                barre d'achat : une case TowerShopButton (TowerIcon, nom, prix) par tour
├── AudioToggles             boutons Musique et Sons (aussi sur l'écran titre)
├── TowerInfoPanel           fiche d'un type de tour (survol) ou d'une tour posée
├── TowerPicker              choix des tours au lancement du niveau (limite de la difficulté)
├── BossBar                  vie du boss en jeu, en haut de la carte
└── EndStats                 statistiques de la partie sur l'écran de fin (LevelStats)
DetailPopup (PanelContainer) scripts/ui/detail_popup.gd   fenêtre de détail au survol (texte BBCode, reste dans l'écran)
EnemyInfo                    scripts/ui/enemy_info.gd     textes qui décrivent un ennemi ou une vague (lexique, fenêtres de détail)
GameMap (Node2D)             scripts/map/game_map.gd      grille, chemins (Path2D enfants), rochers, cases occupées
Level (Node2D)               scripts/levels/level.gd      or, vies, vagues, fin de partie, succès, navigation
├── LevelStats               dégâts et destructions de chaque tour, or, durée (statistiques de fin de niveau)
├── TowerPlacer              sélection, aperçu et pose des tours à la souris
└── WaveSpawner              fait apparaître les ennemis sur les chemins de la carte
TitleDemo                    scripts/ui/title_demo.gd     partie jouée toute seule derrière l'écran titre (Level.is_demo)
```

`scenes/levels/level.tscn` est la scène de base de tous les niveaux. Les niveaux (`level_01.tscn` à `level_06.tscn` pour La Ruche, `mecha_01.tscn` à `mecha_06.tscn` et `humanoid_01.tscn` à `humanoid_06.tscn`) en héritent et n'ajoutent que leurs données : chemins, rochers, couleurs, tours disponibles et vagues. La base est dessinée au bout du premier chemin. Pour créer un nouveau niveau : **Scène > Nouvelle scène héritée** depuis `level.tscn`, ajouter un ou plusieurs `Path2D` sous `Map`, puis remplir les vagues du `WaveSpawner`.

Une nouvelle tour se crée sans code si elle réutilise un comportement existant (un `.tres` `TowerData` qui pointe vers `projectile_tower.tscn` ou `pulse_tower.tscn`), ou en sous-classant `Tower` pour un nouveau comportement.

## Structure

```
project.godot        Configuration du projet
export_presets.cfg   Réglages d'export (Windows, Linux, Web)
scenes/ui/           Écran titre (scène de démarrage), sélection des mondes, arbre des améliorations, lexique, succès, HUD, fiches et boutons du son
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
resources/tilesets/  Tuiles de chaque biome (TileSet)
tools/               Générateurs des sons (generate_sounds.py) et des tuiles (generate_tilesets.py)
scripts/save/        Progression enregistrée (Progress), améliorations permanentes achetées (Perks) et succès (Achievements)
resources/           Campagne et mondes, statistiques des ennemis (un dossier par biome) et des tours (.tres, modifiables dans l'inspecteur)
tests/               Tests exécutables sans fenêtre
assets/sprites/      Images et sprites
assets/audio/        Musiques et effets sonores
assets/fonts/        Police de l'interface : Open Sans + symboles ★ ☆ ✕ et ceux des succès (voir LICENCES.md)
```
