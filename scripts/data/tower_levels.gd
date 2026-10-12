class_name TowerLevels
extends RefCounted
## Niveaux des tours : chaque type de tour (le Canon, le Sniper…) monte de niveau dans
## l'Armurerie en dépensant des insignes, une monnaie gagnée à chaque victoire. Le niveau
## compte pour toutes les tours de ce type, dans toutes les parties.
##
## Chaque niveau donne un très léger bonus (LEVEL_DAMAGE, LEVEL_RANGE) ; tous les
## TIER_EVERY niveaux, un palier débloque un bonus plus fort, propre à chaque tour (TIERS).
## Les bonus des paliers sont des effets d'équipement (Equipment.apply_effect()).
##
## Les insignes tombent dans les mêmes modes que les coffrets d'équipement (campagne,
## niveaux libres, Conquête), un peu plus en difficulté haute et vers la fin d'un monde,
## et en grand nombre à la première victoire du jour au défi du jour.
##
## Tout est enregistré dans la section « tower_levels » de la progression (Progress) :
## « medals » (insignes à dépenser), « earned » (insignes gagnés en tout) et « levels »
## (chemin de la TowerData -> niveau). Comme l'équipement, les niveaux ne comptent pas
## pendant le défi du jour ni le tutoriel (Perks.DISABLED_META).

const SECTION := "tower_levels"
## Symbole et couleur des insignes.
const SYMBOL := "❖"
const COLOR := Color(0.45, 0.95, 0.6)
## Méta du moteur qui garde le niveau de chaque type de tour (les statistiques des tours
## sont recalculées très souvent).
const CACHE_META := &"tower_levels_cache"

## Niveau maximal d'un type de tour.
const MAX_LEVEL := 20
## Un palier tous les TIER_EVERY niveaux (5, 10, 15, 20).
const TIER_EVERY := 5
## Bonus de chaque niveau : dégâts et portée.
const LEVEL_DAMAGE := 0.01
const LEVEL_RANGE := 0.005
## Prix du niveau suivant : COST_BASE + COST_STEP x niveau actuel (10, 15, 20… 105).
const COST_BASE := 10
const COST_STEP := 5

## Insignes d'une victoire au plus bas (Facile, premier niveau d'une série), multipliés
## par la difficulté et par la place du niveau dans sa série (jusqu'à x LEVEL_MULTIPLIER).
const VICTORY_REWARD := 10
const DIFFICULTY_MULTIPLIERS: Array[float] = [1.0, 1.2, 1.4, 1.7]
const LEVEL_MULTIPLIER := 1.5
## Défi du jour : la première victoire du jour, puis les suivantes.
const DAILY_FIRST_REWARD := 60
const DAILY_REWARD := 10

const CANNON := "res://resources/towers/cannon.tres"
const GATLING := "res://resources/towers/gatling.tres"
const SNIPER := "res://resources/towers/sniper.tres"
const MORTAR := "res://resources/towers/mortar.tres"
const FROST := "res://resources/towers/frost.tres"
const BEAM := "res://resources/towers/beam.tres"
const FLAME := "res://resources/towers/flame.tres"
const PESTICIDE := "res://resources/towers/pesticide.tres"
const ARC := "res://resources/towers/arc.tres"
const COIL := "res://resources/towers/coil.tres"
const MAGNET := "res://resources/towers/magnet.tres"
const CENSER := "res://resources/towers/censer.tres"
const BELL := "res://resources/towers/bell.tres"
const JAMMER := "res://resources/towers/jammer.tres"
const MARKSMAN := "res://resources/towers/marksman.tres"
const RAIL := "res://resources/towers/rail.tres"
const TEARGAS := "res://resources/towers/teargas.tres"

## Bonus des paliers de chaque tour, [effet, valeur] aux niveaux 5, 10, 15 et 20 (effets
## d'Equipment.apply_effect()). Une tour absente n'a que les bonus de niveau.
const TIERS := {
	CANNON: [["fire_rate", 0.06], ["knockback", 6.0], ["critical", 8], ["damage", 0.15]],
	GATLING: [["range", 0.06], ["fire_rate", 0.1], ["air", 0.25], ["fire_rate", 0.15]],
	SNIPER: [["fire_rate", 0.06], ["pierce", 0.05], ["boss", 0.25], ["critical", 5]],
	MORTAR: [["range", 0.05], ["splash", 0.12], ["damage", 0.1], ["splash", 0.2]],
	FROST: [["range", 0.06], ["slow_strength", 0.06], ["fire_rate", 0.1], ["slow_strength", 0.1]],
	BEAM: [["range", 0.06], ["beam_ramp", 0.12], ["air", 0.25], ["beam_ramp", 0.25]],
	FLAME: [["range", 0.06], ["dot", 0.15], ["fire_rate", 0.08], ["dot", 0.3]],
	PESTICIDE: [["range", 0.05], ["cloud_duration", 1.0], ["dot", 0.15], ["cloud_duration", 2.0]],
	ARC: [["range", 0.05], ["chain", 1], ["damage", 0.1], ["chain", 1]],
	COIL: [["range", 0.06], ["boost", 0.03], ["range", 0.08], ["boost", 0.05]],
	MAGNET: [["range", 0.06], ["knockback_multiplier", 0.15], ["fire_rate", 0.1], ["knockback_multiplier", 0.25]],
	CENSER: [["range", 0.05], ["revive_block", 1.0], ["splash", 0.12], ["revive_block", 2.0]],
	BELL: [["range", 0.06], ["slow_duration", 0.3], ["fire_rate", 0.1], ["slow_duration", 0.5]],
	JAMMER: [["range", 0.06], ["shield_damage", 0.25], ["fire_rate", 0.1], ["shield_jam", 2.0]],
	MARKSMAN: [["fire_rate", 0.06], ["heal_block", 1.5], ["boss", 0.25], ["critical", 6]],
	RAIL: [["fire_rate", 0.06], ["boss", 0.2], ["range", 0.08], ["damage", 0.15]],
	TEARGAS: [["range", 0.05], ["cloud_duration", 1.0], ["slow_strength", 0.06], ["heal_block", 1.0]],
}


# --- Insignes -----------------------------------------------------------------

## Insignes à dépenser.
static func get_medals() -> int:
	return Progress.get_value(SECTION, "medals", 0)


## Insignes gagnés en tout (dépensés compris).
static func get_earned() -> int:
	return Progress.get_value(SECTION, "earned", 0)


static func add_medals(amount: int) -> void:
	if amount <= 0:
		return
	var config_medals := get_medals() + amount
	Progress.set_value(SECTION, "earned", get_earned() + amount)
	Progress.set_value(SECTION, "medals", config_medals)


## Le niveau donne-t-il des insignes ? Les mêmes que pour les coffrets d'équipement.
static func level_gives_medals(level_path: String) -> bool:
	return Equipment.level_gives_boxes(level_path)


## Insignes d'une victoire sur ce niveau dans cette difficulté (0 si le niveau n'en donne pas).
static func get_victory_reward(level_path: String, difficulty: int) -> int:
	if not level_gives_medals(level_path):
		return 0
	var multiplier: float = DIFFICULTY_MULTIPLIERS[clampi(difficulty, 0, Difficulty.COUNT - 1)] \
		* lerpf(1.0, LEVEL_MULTIPLIER, Equipment.get_level_position(level_path))
	return roundi(VICTORY_REWARD * multiplier)


## Victoire sur un niveau : ajoute ses insignes et renvoie leur nombre.
static func reward_victory(level_path: String, difficulty: int) -> int:
	var amount := get_victory_reward(level_path, difficulty)
	add_medals(amount)
	return amount


## Victoire au défi du jour : beaucoup d'insignes la première fois du jour (`first_today`),
## un peu ensuite. Renvoie leur nombre.
static func reward_daily(first_today: bool) -> int:
	var amount := DAILY_FIRST_REWARD if first_today else DAILY_REWARD
	add_medals(amount)
	return amount


## « ❖ 15 ».
static func medal_text(amount: int) -> String:
	return "%s %d" % [SYMBOL, amount]


# --- Niveaux ------------------------------------------------------------------

## Niveau de chaque type de tour : { chemin de la TowerData: niveau }.
static func get_levels() -> Dictionary:
	return Progress.get_value(SECTION, "levels", {})


## Niveau d'un type de tour (0 au départ), gardé en mémoire.
static func get_level(tower_path: String) -> int:
	if not Engine.has_meta(CACHE_META):
		Engine.set_meta(CACHE_META, get_levels())
	return (Engine.get_meta(CACHE_META) as Dictionary).get(tower_path, 0)


## Prix du niveau suivant, ou -1 au niveau maximal.
static func get_cost(tower_path: String) -> int:
	var level := get_level(tower_path)
	return -1 if level >= MAX_LEVEL else COST_BASE + COST_STEP * level


## Insignes pour passer du niveau 0 au niveau maximal.
static func get_total_cost() -> int:
	var total := 0
	for level in MAX_LEVEL:
		total += COST_BASE + COST_STEP * level
	return total


static func can_level_up(tower_path: String) -> bool:
	var cost := get_cost(tower_path)
	return cost >= 0 and get_medals() >= cost


## Monte le type de tour d'un niveau en payant ses insignes. Renvoie true si c'est fait.
static func level_up(tower_path: String) -> bool:
	if tower_path.is_empty() or not can_level_up(tower_path):
		return false
	var levels := get_levels()
	var cost := get_cost(tower_path)
	levels[tower_path] = get_level(tower_path) + 1
	Progress.set_value(SECTION, "medals", get_medals() - cost)
	Progress.set_value(SECTION, "levels", levels)
	return true


## Oublie les niveaux gardés en mémoire (la progression a changé).
static func clear_cache() -> void:
	if Engine.has_meta(CACHE_META):
		Engine.remove_meta(CACHE_META)


# --- Paliers et bonus ---------------------------------------------------------

## Paliers d'un type de tour, [[effet, valeur], …] (vide pour une tour sans palier).
static func get_tiers(tower_path: String) -> Array:
	return TIERS.get(tower_path, [])


## Niveau auquel le palier de rang `index` se débloque (5, 10, 15, 20).
static func tier_level(index: int) -> int:
	return (index + 1) * TIER_EVERY


## Paliers débloqués à ce niveau.
static func get_unlocked_tier_count(level: int) -> int:
	return mini(level / TIER_EVERY, MAX_LEVEL / TIER_EVERY)


## Applique le niveau de ce type de tour à ses statistiques (modifiées sur place) : bonus
## de chaque niveau puis paliers débloqués. Appelé par TowerData.get_stats_at_level(). Rien
## pendant le défi du jour et le tutoriel.
static func apply_to(stats: TowerData, tower_path: String) -> void:
	if tower_path.is_empty() or Engine.has_meta(Perks.DISABLED_META):
		return
	var level := get_level(tower_path)
	if level <= 0:
		return
	stats.scale_stats(1.0 + LEVEL_DAMAGE * level, 1.0 + LEVEL_RANGE * level, 1.0, 0.0)
	var tiers := get_tiers(tower_path)
	for i in mini(get_unlocked_tier_count(level), tiers.size()):
		Equipment.apply_effect(stats, tiers[i][0], tiers[i][1])


## Bonus de tous les niveaux atteints, traduit : « +7 % dégâts, +3,5 % portée ».
static func describe_level_bonus(level: int) -> String:
	return TranslationServer.translate("+%s %% dégâts, +%s %% portée") \
		% [GameSettings.decimal(LEVEL_DAMAGE * level * 100.0), GameSettings.decimal(LEVEL_RANGE * level * 100.0)]


## Bonus du palier de rang `index`, traduit.
static func describe_tier(tower_path: String, index: int) -> String:
	var tiers := get_tiers(tower_path)
	if index < 0 or index >= tiers.size():
		return ""
	return Equipment.describe_effect(tiers[index][0], tiers[index][1])
