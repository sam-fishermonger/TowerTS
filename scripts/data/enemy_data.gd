class_name EnemyData
extends Resource
## Statistiques d'un type d'ennemi. Un ennemi peut aussi apparaître en élite (voir
## make_elite()) : une version plus grosse et plus résistante, qui rapporte plus.

## Élites : vie et bouclier multipliés…
const ELITE_HEALTH := 3.0
## … taille…
const ELITE_SIZE := 1.25
## … or rapporté…
const ELITE_REWARD := 4.0
## … et vies retirées s'il atteint la base.
const ELITE_DAMAGE := 2
const ELITE_COLOR := Color(1.0, 0.8, 0.25)
const BOSS_COLOR := Color(1.0, 0.35, 0.3)

@export var display_name := "Ennemi"
## Courte présentation, affichée dans le lexique.
@export_multiline var description := ""
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

@export_group("Déplacement")
## Volant : survole le chemin en coupant les virages (Enemy.get_flight_curve()), hors
## d'atteinte des tours qui tirent au sol (TowerData.hits_air).
@export var flying := false
## Furtif : invisible, et donc pas visé par les tours, sauf à portée de détection d'une
## tour qui en a une (TowerData.detection_range). Les dégâts de zone le touchent quand même.
@export var stealthy := false

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

@export_group("Renforts")
## Ennemi appelé en renfort pendant la marche, derrière celui-ci (aucun si vide).
@export var summon_enemy: EnemyData
## Nombre d'ennemis appelés à chaque fois.
@export var summon_count := 0
## Secondes entre deux appels.
@export var summon_interval := 6.0

@export_group("Boss")
## Boss : un seul par vague, quelle que soit la difficulté ; sa vie s'affiche en haut
## de l'écran pendant qu'il est en jeu.
@export var is_boss := false
## Version élite d'un ennemi (voir make_elite()), pas à cocher à la main.
@export var is_elite := false

@export_group("Soin")
## Points de vie rendus à chaque soin aux ennemis blessés autour de lui (0 = ne soigne pas).
@export var heal_amount := 0.0
## Portée du soin, en pixels.
@export var heal_radius := 120.0
## Secondes entre deux soins.
@export var heal_interval := 2.0


## Version élite de cet ennemi : vie et bouclier x3, 25 % plus gros, 4 fois plus d'or,
## 2 vies de plus s'il atteint la base. Les ennemis qu'il libère ou appelle restent
## normaux. Une copie : l'ennemi d'origine n'est pas modifié.
func make_elite() -> EnemyData:
	if is_elite or is_boss:
		return self
	var elite: EnemyData = duplicate()
	elite.is_elite = true
	elite.display_name = "%s élite" % display_name
	elite.max_health = max_health * ELITE_HEALTH
	elite.max_shield = max_shield * ELITE_HEALTH
	elite.shield_regen = shield_regen * ELITE_HEALTH
	elite.radius = radius * ELITE_SIZE
	elite.reward = roundi(reward * ELITE_REWARD)
	elite.damage = damage + ELITE_DAMAGE
	return elite


## Capacités particulières, une courte phrase chacune (lexique, fiches de vague et de
## monstre).
func get_abilities() -> Array[String]:
	var result: Array[String] = []
	if is_boss:
		result.append("Boss : un seul par vague, sa vie s'affiche en haut de l'écran.")
	if is_elite:
		result.append("Élite : vie x%s, %d fois plus d'or." % [str(ELITE_HEALTH).trim_suffix(".0"),
			roundi(ELITE_REWARD)])
	if flying:
		result.append("Volant : survole le chemin en coupant les virages. Mortier, Lance-flammes et nuages ne l'atteignent pas.")
	if stealthy:
		result.append("Furtif : les tours ne le visent que près d'une tour qui détecte (Sniper, Franc-tireur, Bobine). Les ondes et les explosions le touchent quand même.")
	if armor > 0.0:
		result.append("Armure : chaque coup perd %s dégâts (au moins 1 passe)." % str(armor).trim_suffix(".0"))
	if max_shield > 0.0:
		result.append("Bouclier d'énergie de %d points, qui encaisse en premier et se recharge (%d/s)."
			% [roundi(max_shield), roundi(shield_regen)])
	if heal_amount > 0.0:
		result.append("Soigne de %d points les ennemis autour de lui, toutes les %s s."
			% [roundi(heal_amount), str(heal_interval).trim_suffix(".0")])
	if summon_enemy and summon_count > 0:
		result.append("Appelle %d %s en renfort toutes les %s s."
			% [summon_count, plural(summon_enemy.display_name, summon_count), str(summon_interval).trim_suffix(".0")])
	if split_into and split_count > 0:
		result.append("Libère %d %s à sa mort." % [split_count, plural(split_into.display_name, split_count)])
	return result


## Nom au pluriel s'il y en a plusieurs : « 3 Larves », « 2 Porte-drones ».
static func plural(name: String, count: int) -> String:
	if count <= 1 or name.ends_with("s") or name.ends_with("x"):
		return name
	var words := name.split(" ")
	words[0] += "s"
	return " ".join(words)
