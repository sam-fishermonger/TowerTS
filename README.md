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
- **Lancer la vague** envoie la vague suivante. Chaque ennemi détruit rapporte de l'or, et chaque vague nettoyée donne un bonus.
- La partie est perdue quand les vies tombent à 0, gagnée quand les 5 vagues du niveau 1 sont repoussées.

## Tests

```
godot --headless --path . -s res://tests/run_tests.gd
```

## Structure

```
project.godot     Configuration du projet
scenes/ui/        Écran titre (scène de démarrage) et HUD
scenes/levels/    Niveaux (level_01.tscn : chemin, vagues, tours disponibles)
scenes/enemies/   Ennemi générique (PathFollow2D)
scenes/towers/    Tour et projectile génériques
scripts/          Scripts GDScript (.gd), même découpage que scenes/
scripts/data/     Ressources de données : EnemyData, TowerData, WaveData, SpawnGroup
resources/        Statistiques des ennemis et des tours (.tres, modifiables dans l'inspecteur)
tests/            Tests de fumée exécutables sans fenêtre
assets/sprites/   Images et sprites
assets/audio/     Musiques et effets sonores
assets/fonts/     Polices
```
