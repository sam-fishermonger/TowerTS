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
