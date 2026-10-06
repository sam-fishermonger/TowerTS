class_name EnemyData
extends Resource
## Statistiques d'un type d'ennemi.

@export var display_name := "Ennemi"
@export var max_health := 50.0
## Dégâts retirés à chaque coup reçu (un coup inflige toujours au moins 1).
@export var armor := 0.0
## Vitesse de déplacement le long du chemin, en pixels par seconde.
@export var speed := 80.0
## Or gagné quand l'ennemi est détruit.
@export var reward := 5
## Vies retirées au joueur si l'ennemi atteint la fin du chemin.
@export var damage := 1
@export var color := Color.RED
@export var radius := 12.0
## Image de l'ennemi, tournée dans le sens de la marche (dessin de remplacement en code si vide).
@export var texture: Texture2D
## Taille de l'image par rapport au rayon (pour les images avec beaucoup de marge).
@export var sprite_scale := 1.0

@export_group("Division")
## Ennemi qui apparaît à sa place quand il est détruit (aucun si vide).
@export var split_into: EnemyData
## Nombre d'ennemis qui apparaissent à sa mort.
@export var split_count := 0

@export_group("Bouclier")
## Bouclier d'énergie : il encaisse les coups avant les points de vie, sans armure
## (0 = pas de bouclier).
@export var max_shield := 0.0
## Points de bouclier rechargés par seconde, après HealthComponent.shield_regen_delay
## secondes sans être touché.
@export var shield_regen := 0.0

@export_group("Soin")
## Points de vie rendus à chaque soin aux ennemis blessés autour de lui (0 = ne soigne pas).
@export var heal_amount := 0.0
## Portée du soin, en pixels.
@export var heal_radius := 120.0
## Secondes entre deux soins.
@export var heal_interval := 2.0
