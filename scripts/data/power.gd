class_name Power
extends Resource
## Pouvoir actif du joueur en jeu (bouton en haut de l'écran, ou touche) : il se
## débloque dans l'arbre des améliorations (Perk.unlocks_power), puis se recharge
## après chaque usage. Les améliorations de l'arbre (Perk.improves_power) le renforcent.

## Comment le pouvoir agit.
enum Kind {
	## Pluie de météores sur la zone visée.
	METEORS,
	## Gel de tous les ennemis en jeu.
	FREEZE,
	## Soldats posés sur le chemin, qui retiennent les ennemis.
	REINFORCEMENTS,
}

@export var id := ""
@export var display_name := "Pouvoir"
@export_multiline var description := ""
@export var kind := Kind.METEORS
@export var color := Color.WHITE
## Secondes de recharge après chaque usage (de jeu : la vitesse x2/x3 les raccourcit).
@export var cooldown := 40.0

@export_group("Effet")
## Météores : dégâts de chaque météore. Renforts : dégâts par seconde de chaque soldat.
@export var damage := 0.0
## Météores : nombre de météores. Renforts : nombre de soldats.
@export var count := 0
## Météores : rayon de la zone où ils tombent. Renforts : rayon où un soldat engage un ennemi.
@export var radius := 0.0
## Météores : rayon de l'explosion de chacun.
@export var splash_radius := 0.0
## Gel : secondes de gel. Renforts : secondes avant que les soldats repartent.
@export var duration := 0.0
## Renforts : vie de chaque soldat.
@export var health := 0.0
## Gel : part des dégâts subis en plus par un ennemi gelé (0.3 = +30 %).
@export var vulnerability := 0.0


## Le pouvoir se lance sur un point de la carte (sinon, tout de suite).
func is_targeted() -> bool:
	return kind != Kind.FREEZE


## Lignes de statistiques pour les fiches (arbre des améliorations, bulle d'aide).
func get_stats_lines() -> Array[String]:
	var lines: Array[String] = []
	match kind:
		Kind.METEORS:
			lines.append("%d météores de %d dégâts" % [count, roundi(damage)])
		Kind.FREEZE:
			lines.append("Gel de %s s" % _seconds(duration))
			if vulnerability > 0.0:
				lines.append("+%d %% de dégâts subis" % roundi(vulnerability * 100.0))
		Kind.REINFORCEMENTS:
			lines.append("%d soldats, %d vie, %d dégâts/s" % [count, roundi(health), roundi(damage)])
			lines.append("%s s sur le terrain" % _seconds(duration))
	lines.append("Recharge : %s s" % _seconds(cooldown))
	return lines


static func _seconds(value: float) -> String:
	return str(snappedf(value, 0.1)).trim_suffix(".0").replace(".", ",")
