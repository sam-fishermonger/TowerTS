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
## Boss en mode daltonien : magenta, que l'on ne confond pas avec l'or des élites.
const COLORBLIND_BOSS_COLOR := Color(0.95, 0.35, 0.95)
## Pluriels anglais irréguliers des noms traduits (voir plural()).
const ENGLISH_PLURALS := {"Larva": "Larvae", "Colossus": "Colossi"}

@export var display_name := "Ennemi"
## Courte présentation, affichée dans le lexique.
@export_multiline var description := ""
## Nom de l'ennemi d'origine d'un élite (make_elite()), pour traduire « Larve élite ».
var base_name := ""
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

@export_group("Terrier")
## Tunnelier : secondes à la surface entre deux plongées sous terre (0 = ne creuse pas).
## Sous terre, aucune tour ne le voit ni ne le touche, même avec une onde ou une
## explosion ; il remonte avant d'arriver près de la base (Enemy.BURROW_SURFACE_DISTANCE).
@export var burrow_interval := 0.0
## Secondes passées sous terre à chaque plongée.
@export var burrow_duration := 3.0
## Vitesse sous terre, par rapport à celle de la surface.
@export var burrow_speed_multiplier := 1.0

@export_group("Sabotage")
## Saboteur : secondes entre deux sabotages (0 = ne sabote pas). Il éteint la tour bâtie
## la plus proche à sa portée : elle ne tire plus et ne détecte plus pendant
## `sabotage_duration`.
@export var sabotage_interval := 0.0
## Portée du sabotage, en pixels.
@export var sabotage_radius := 140.0
## Secondes pendant lesquelles la tour sabotée reste éteinte.
@export var sabotage_duration := 4.0

@export_group("Pillage")
## Pillard (mode Conquête) : il quitte le chemin pour frapper un ouvrier ou un bâtiment
## à portée, puis y revient (voir Enemy).
@export var raider := false
## Portée à laquelle il repère sa cible, en pixels.
@export var raid_radius := 130.0
## Dégâts par seconde qu'il fait à un ouvrier ou à un bâtiment.
@export var raid_damage := 30.0
## Voleur (mode Conquête) : il quitte le chemin pour piller un Dépôt bâti à portée
## (raid_radius), ou le QG s'il l'atteint, et emporte de la pierre et de l'essence (voir
## Enemy). Détruit, il lâche ce qu'il a volé.
@export var thief := false
## Pierre et essence qu'il emporte, au plus.
@export var steal_stone := 20
@export var steal_essence := 5

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

@export_group("Résurrection")
## Nombre de fois que l'ennemi se relève après sa mort (0 = jamais), sauf s'il vient
## d'être consacré (TowerData.revive_block_duration).
@export var revive_count := 0
## Part de sa vie (et de son bouclier) qu'il retrouve en se relevant.
@export_range(0.1, 1.0) var revive_health_ratio := 0.5
## Secondes passées au sol avant de se relever : pendant ce temps, les tours ne le voient pas.
@export var revive_delay := 1.5

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
	elite.base_name = display_name
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
		result.append(tr("Boss : un seul par vague, sa vie s'affiche en haut de l'écran."))
	if is_elite:
		result.append(tr("Élite : vie x%s, %d fois plus d'or.") % [str(ELITE_HEALTH).trim_suffix(".0"),
			roundi(ELITE_REWARD)])
	if flying:
		result.append(tr("Volant : survole le chemin en coupant les virages. Mortier, Lance-flammes et nuages ne l'atteignent pas."))
	if raider:
		result.append(tr("Pillard : quitte le chemin pour frapper les ouvriers et les bâtiments à portée (mode Conquête), puis y revient."))
	if thief:
		result.append(tr("Voleur : quitte le chemin pour piller un Dépôt à portée, ou le QG s'il l'atteint, et emporte %d pierre et %d essence (mode Conquête). Détruit, il lâche son butin.")
			% [steal_stone, steal_essence])
	if stealthy:
		result.append(tr("Furtif : les tours ne le visent que près d'une tour qui détecte (Sniper, Franc-tireur, Bobine). Les ondes et les explosions le touchent quand même."))
	if burrow_interval > 0.0:
		result.append(tr("Tunnelier : toutes les %s s, il creuse sous le chemin pendant %s s. Sous terre, aucune tour ne le voit ni ne le touche ; il remonte avant la base.")
			% [_seconds(burrow_interval), _seconds(burrow_duration)])
	if sabotage_interval > 0.0:
		result.append(tr("Saboteur : toutes les %s s, il éteint pendant %s s la tour la plus proche à sa portée (elle ne tire plus et ne détecte plus).")
			% [_seconds(sabotage_interval), _seconds(sabotage_duration)])
	if armor > 0.0:
		result.append(tr("Armure : chaque coup perd %s dégâts (au moins 1 passe).") % str(armor).trim_suffix(".0"))
	if max_shield > 0.0:
		result.append(tr("Bouclier d'énergie de %d points, qui encaisse en premier et se recharge (%d/s).")
			% [roundi(max_shield), roundi(shield_regen)])
	if heal_amount > 0.0:
		result.append(tr("Soigne de %d points les ennemis autour de lui, toutes les %s s.")
			% [roundi(heal_amount), str(heal_interval).trim_suffix(".0")])
	if summon_enemy and summon_count > 0:
		result.append(tr("Appelle %d %s en renfort toutes les %s s.")
			% [summon_count, plural(summon_enemy.display_name, summon_count), str(summon_interval).trim_suffix(".0")])
	if revive_count > 0:
		var percent := roundi(revive_health_ratio * 100.0)
		var delay := _seconds(revive_delay)
		if revive_count == 1:
			result.append(tr("Se relève une fois avec %d %% de sa vie, %s s après sa mort, sauf s'il vient d'être consacré.")
				% [percent, delay])
		else:
			result.append(tr("Se relève %d fois avec %d %% de sa vie, %s s après sa mort, sauf s'il vient d'être consacré.")
				% [revive_count, percent, delay])
	if split_into and split_count > 0:
		result.append(tr("Libère %d %s à sa mort.") % [split_count, plural(split_into.display_name, split_count)])
	return result


## Un nombre de secondes écrit à la française (virgule) ou à l'anglaise. Pas
## GameSettings.decimal() ici : GameSettings dépend (de loin) des ressources d'ennemis.
static func _seconds(value: float) -> String:
	var text := str(value).trim_suffix(".0")
	return text.replace(".", ",") if _is_french() else text


## Nom traduit, au pluriel s'il y en a plusieurs : « 3 Larves », « 2 Porte-drones »
## (en anglais : « 3 Larvae », « 2 Drone Carriers »).
static func plural(name: String, count: int) -> String:
	if not _is_french():
		return _english_plural(TranslationServer.translate(name), count)
	if count <= 1 or name.ends_with("s") or name.ends_with("x"):
		return name
	var words := name.split(" ")
	words[0] += "s"
	return " ".join(words)


## Le jeu est en français (langue d'origine des noms et des textes).
static func _is_french() -> bool:
	return TranslationServer.get_locale().begins_with("fr")


## Pluriel anglais : le dernier mot prend un « s » (« es » après s, x, ch, sh), sauf
## les pluriels irréguliers.
static func _english_plural(name: String, count: int) -> String:
	if count <= 1:
		return name
	if ENGLISH_PLURALS.has(name):
		return ENGLISH_PLURALS[name]
	for ending in ["s", "x", "ch", "sh"]:
		if name.ends_with(ending):
			return name + "es"
	# « Mummy » devient « Mummies ».
	if name.ends_with("y") and not "aeiou".contains(name[-2]):
		return name.left(-1) + "ies"
	return name + "s"


## Nom affiché, traduit : « Larve élite » devient « Elite Larva ».
func get_translated_name() -> String:
	if not base_name.is_empty():
		return tr("%s élite") % tr(base_name)
	return tr(display_name)


## Couleur de l'aura et de la barre de vie d'un boss (magenta en mode daltonien).
static func boss_color() -> Color:
	return COLORBLIND_BOSS_COLOR if UiStyle.is_colorblind() else BOSS_COLOR
