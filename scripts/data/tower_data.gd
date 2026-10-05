class_name TowerData
extends Resource
## Statistiques d'un type de tour.

@export var display_name := "Tour"
@export var cost := 50
## Scène de la tour (une scène dont la racine hérite de Tower).
@export var scene: PackedScene
## Portée de tir, en pixels.
@export var attack_range := 150.0
@export var damage := 20.0
## Nombre de tirs par seconde.
@export var fire_rate := 1.0
@export var color := Color.STEEL_BLUE

@export_group("Projectile")
## Scène du projectile tiré (tours à projectiles seulement).
@export var projectile_scene: PackedScene
## Vitesse des projectiles, en pixels par seconde.
@export var projectile_speed := 500.0
## Rayon de l'explosion à l'impact (0 = un seul ennemi touché).
@export var splash_radius := 0.0

@export_group("Ralentissement")
## Multiplicateur de vitesse appliqué aux ennemis touchés (1 = aucun effet).
@export_range(0.1, 1.0) var slow_factor := 1.0
## Durée du ralentissement, en secondes.
@export var slow_duration := 0.0
