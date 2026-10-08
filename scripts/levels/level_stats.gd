class_name LevelStats
extends RefCounted
## Statistiques d'une partie, affichées sur l'écran de fin : dégâts et destructions de
## chaque tour posée (les tours vendues gardent les leurs), or dépensé et gagné, monstres
## détruits, vies perdues, durée. Le niveau les remplit au fil de la partie ; les succès
## (Achievements) s'en servent aussi.

## Une tour posée pendant la partie.
class TowerRecord:
	var data: TowerData
	## Niveau d'amélioration atteint (le plus haut, même si elle a été vendue ensuite).
	var level := 1
	var damage := 0.0
	var kills := 0
	var sold := false

	func _init(tower_data: TowerData) -> void:
		data = tower_data


## Bilan d'un type de tour : toutes les tours de ce type posées pendant la partie.
class TypeRecord:
	var data: TowerData
	var count := 0
	var damage := 0.0
	var kills := 0

	func _init(tower_data: TowerData) -> void:
		data = tower_data


## Tours posées, par identifiant d'instance, dans l'ordre de pose.
var towers := {}
var gold_spent := 0
## Or dépensé en améliorations (compris dans gold_spent).
var gold_spent_on_upgrades := 0
## Or gagné : monstres détruits, bonus de vague, intérêts, primes de lancement en avance et ventes.
var gold_earned := 0
var kills := 0
var elite_kills := 0
var boss_kills := 0
var lives_lost := 0
var towers_built := 0
var upgrades_bought := 0
var towers_sold := 0
## Vagues lancées avant d'avoir vidé la carte.
var early_calls := 0
## Butins ramassés (Loot), dont les coffres ouverts.
var loot_collected := 0
var chests_opened := 0
## Durée de la partie, en secondes de jeu (sans la pause ni le choix des tours).
var duration := 0.0
## Mode Conquête : la partie en est une, pierre et essence récoltées, bâtiments bâtis et
## ouvriers perdus.
var conquest := false
var stone_mined := 0
var essence_mined := 0
var buildings_built := 0
var workers_lost := 0
## Pierre et essence emportées par les Voleurs.
var resources_stolen := 0


func on_tower_placed(tower: Tower) -> void:
	towers[tower.get_instance_id()] = TowerRecord.new(tower.data)
	towers_built += 1
	gold_spent += tower.data.get_cost()


func on_tower_upgraded(tower: Tower, cost: int) -> void:
	var record: TowerRecord = towers.get(tower.get_instance_id())
	if record:
		record.level = maxi(record.level, tower.level)
	upgrades_bought += 1
	gold_spent += cost
	gold_spent_on_upgrades += cost


## Pose annulée (Level.undo_last_placement()) : la tour n'a jamais existé, ni ce qu'elle a coûté.
func on_tower_undone(tower: Tower) -> void:
	towers.erase(tower.get_instance_id())
	var upgrades := tower.get_total_cost() - tower.data.get_cost()
	towers_built -= 1
	upgrades_bought -= tower.level - 1
	gold_spent -= tower.get_total_cost()
	gold_spent_on_upgrades -= upgrades


func on_tower_sold(tower: Tower, value: int) -> void:
	var record: TowerRecord = towers.get(tower.get_instance_id())
	if record:
		record.sold = true
	towers_sold += 1
	gold_earned += value


## Dégâts réellement subis par un monstre, comptés à la tour `source_id` (0 = aucune).
func on_damage(source_id: int, amount: float) -> void:
	var record: TowerRecord = towers.get(source_id)
	if record:
		record.damage += amount


## Monstre détruit ; le coup fatal est compté à la tour `source_id`.
func on_kill(source_id: int, data: EnemyData) -> void:
	kills += 1
	if data.is_elite:
		elite_kills += 1
	if data.is_boss:
		boss_kills += 1
	var record: TowerRecord = towers.get(source_id)
	if record:
		record.kills += 1


## Compteurs enregistrés avec la partie (SavedGame).
const SAVED_FIELDS: Array[String] = ["gold_spent", "gold_spent_on_upgrades", "gold_earned", "kills", "elite_kills",
	"boss_kills", "lives_lost", "towers_built", "upgrades_bought", "towers_sold", "early_calls", "loot_collected",
	"chests_opened", "duration"]


## Statistiques en valeurs simples, pour la partie enregistrée. Les tours y gardent
## l'identifiant de leur instance (voir from_dict()).
func to_dict() -> Dictionary:
	var result := {}
	for field in SAVED_FIELDS:
		result[field] = get(field)
	var records: Array[Dictionary] = []
	for id: int in towers:
		var record: TowerRecord = towers[id]
		records.append({"id": id, "data": record.data.resource_path, "level": record.level,
			"damage": record.damage, "kills": record.kills, "sold": record.sold})
	result.towers = records
	return result


## Reprend les statistiques d'une partie enregistrée. `new_ids` donne le nouvel
## identifiant de chaque tour reposée (les tours vendues prennent un identifiant négatif).
func from_dict(data: Dictionary, new_ids: Dictionary) -> void:
	for field in SAVED_FIELDS:
		if data.has(field):
			set(field, data[field])
	towers.clear()
	var sold_id := -1
	for entry: Dictionary in data.get("towers", []):
		if not ResourceLoader.exists(entry.get("data", "")):
			continue
		var record := TowerRecord.new(load(entry.data))
		record.level = entry.get("level", 1)
		record.damage = entry.get("damage", 0.0)
		record.kills = entry.get("kills", 0)
		record.sold = entry.get("sold", false)
		var id: int = new_ids.get(entry.get("id", 0), 0)
		if id == 0:
			id = sold_id
			sold_id -= 1
		towers[id] = record


func get_total_damage() -> float:
	var total := 0.0
	for record: TowerRecord in towers.values():
		total += record.damage
	return total


## Bilan par type de tour, du plus de dégâts au moins.
func get_types() -> Array[TypeRecord]:
	var by_type := {}
	var result: Array[TypeRecord] = []
	for record: TowerRecord in towers.values():
		var type: TypeRecord = by_type.get(record.data)
		if not type:
			type = TypeRecord.new(record.data)
			by_type[record.data] = type
			result.append(type)
		type.count += 1
		type.damage += record.damage
		type.kills += record.kills
	result.sort_custom(func(a: TypeRecord, b: TypeRecord) -> bool: return a.damage > b.damage)
	return result


## Tour posée qui a infligé le plus de dégâts (null si aucune n'en a infligé).
func get_best_tower() -> TowerRecord:
	var best: TowerRecord = null
	for record: TowerRecord in towers.values():
		if record.damage > 0.0 and (best == null or record.damage > best.damage):
			best = record
	return best


## Types de tour différents posés pendant la partie.
func get_type_count() -> int:
	return get_types().size()


## « 4:05 » (ou « 1:02:09 » au-delà d'une heure).
static func format_duration(seconds: float) -> String:
	var total := floori(seconds)
	if total >= 3600:
		return "%d:%02d:%02d" % [total / 3600, total / 60 % 60, total % 60]
	return "%d:%02d" % [total / 60, total % 60]


## Grand nombre lisible : « 12 345 » (en anglais : « 12,345 »).
static func format_number(value: float) -> String:
	var digits := str(roundi(value))
	var separator := " " if GameSettings.get_language() == "fr" else ","
	var result := ""
	while digits.length() > 3:
		result = separator + digits.right(3) + result
		digits = digits.left(digits.length() - 3)
	return digits + result


## Nombre à passer à tr_n() : en français, 0 se dit au singulier (« 0 destruction »), alors
## que sans traduction Godot ne garde le singulier que pour 1.
static func plural_count(count: int) -> int:
	return 1 if count == 0 and GameSettings.get_language() == "fr" else count
