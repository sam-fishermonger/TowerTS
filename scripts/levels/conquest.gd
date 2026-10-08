class_name Conquest
extends Node2D
## Mode Conquête : les tours coûtent de l'or et de la pierre, et des ouvriers les
## bâtissent. Les ouvriers minent la pierre des rochers de la carte et l'essence de ses
## filons, et les rapportent au QG (la base) ou au Dépôt le plus proche ; un gisement
## vidé disparaît et libère sa case. Une tour posée n'est d'abord qu'un chantier, qui ne
## tire qu'une fois bâti, et il en va de même des bâtiments (Building). L'essence paie
## les dernières améliorations des tours et la Caserne. Des Pillards (EnemyData.raider)
## s'ajoutent aux vagues et quittent le chemin pour frapper ouvriers et bâtiments.
## Les vagues partent seules au bout d'un compte à rebours, qu'on peut toujours devancer
## avec « Lancer la vague ».
## Le joueur peut choisir des ouvriers et les affecter à la main à un gisement, un
## chantier ou au QG (Worker.Order), à autant qu'il veut sur la même tâche. L'Atelier
## lance des améliorations (Research) qui valent pour le reste de la partie.
## Le niveau crée ce nœud quand il a `conquest_mode`.

enum Ore { STONE, ESSENCE }

## Ouvriers au plus sans Maison, et au plus avec toutes les Maisons.
const BASE_WORKERS := 6
const MAX_WORKERS := 14
## Prix d'un ouvrier, en or.
const WORKER_COST := 40
## Pierre d'un rocher, essence d'un filon.
const ROCK_STONE := 30
const VEIN_ESSENCE := 16
## Pierre d'une tour, par or de son prix.
const STONE_PER_GOLD := 0.4
## Essence demandée par une amélioration, à partir du niveau 3 de la tour : celle-ci
## pour le niveau 3, le double pour le 4 (spécialisation)…
const UPGRADE_ESSENCE := 3
const UPGRADE_ESSENCE_FROM_LEVEL := 3
## Part de la pierre et de l'essence rendue à la vente d'une tour ou d'un bâtiment bâti.
const SELL_RATIO := 0.7
## Ouvriers qui bâtissent un même chantier, au plus.
const BUILDERS_PER_SITE := 2
## Ouvriers qui vont d'eux-mêmes miner l'essence, au plus (le joueur peut en envoyer
## plus en cliquant sur un filon).
const AUTO_ESSENCE_MINERS := 1
## Secondes avant la première vague, puis entre la fin d'une vague et la suivante.
const FIRST_WAVE_DELAY := 45.0
const WAVE_DELAY := 25.0
## Pillards : secondes entre deux apparitions, et après le début de la vague.
const RAIDER_INTERVAL := 2.5
const RAIDER_DELAY := 3.0
const STONE_COLOR := Color(0.78, 0.8, 0.88)
const ESSENCE_COLOR := Color(0.78, 0.5, 1.0)
const NO_CELL := Vector2i(-1000, -1000)
## Groupe des cibles des Pillards : ouvriers et bâtiments.
const RAID_TARGET_GROUP := "raid_targets"

## Émis quand la pierre, l'essence, les ouvriers, les bâtiments ou le compte à rebours
## changent.
signal changed
## Émis quand les ouvriers choisis par le joueur changent.
signal selection_changed

var level: Level
var stone := 0
var essence := 0
## Pierre restante de chaque rocher, essence de chaque filon (case -> quantité).
var rocks := {}
var veins := {}
## Gisement désigné par le joueur : les mineurs y vont tant qu'il en reste.
var preferred_rock := NO_CELL
## QG : au bout du chemin, point de dépôt où les ouvriers sont à l'abri.
var depot_position := Vector2.ZERO
## Secondes avant le départ de la prochaine vague (négatif : pas de compte à rebours).
var wave_countdown := -1.0
## Bilan de la partie.
var stone_mined := 0
var essence_mined := 0
var workers_lost := 0
var buildings_lost := 0
## Ouvriers en même temps, au plus, depuis le début de la partie.
var peak_workers := 0
## Niveau atteint de chaque amélioration de l'Atelier (Research), pour cette partie.
var research_levels := {}

## Ouvriers choisis par le joueur : le prochain clic sur un gisement, un chantier ou le
## QG leur donne une tâche.
var _selected: Array[Worker] = []

## Chantiers pas encore finis : des tours (Tower) et des bâtiments (Building), sans
## type commun qui ait is_built() (d'où les variables sans type).
var _sites: Array = []
var _buildings: Array[Building] = []
## Vue de trois quarts : les cristaux debout de chaque filon (case -> EssenceVein), triés
## en profondeur avec le reste, et les jauges des gisements, par-dessus tout.
var _vein_nodes := {}
var _gauges: DepositGauges


## Pierre demandée pour un type de tour.
static func stone_cost(data: TowerData) -> int:
	return ceili(data.get_cost() * STONE_PER_GOLD)


## Secondes pour bâtir un type de tour avec un seul ouvrier.
static func tower_build_time(data: TowerData) -> float:
	return 3.0 + data.get_cost() / 25.0


## Secondes pour bâtir un chantier (tour ou bâtiment) avec un seul ouvrier.
static func build_time(site) -> float:
	if site is Building:
		return Building.get_definition(site.kind).build_time
	return tower_build_time((site as Tower).data)


## Essence demandée par la prochaine amélioration d'une tour (0 = aucune).
static func upgrade_essence_cost(tower: Tower) -> int:
	var next_level := tower.level + 1
	return UPGRADE_ESSENCE * (next_level - UPGRADE_ESSENCE_FROM_LEVEL + 1) if next_level >= UPGRADE_ESSENCE_FROM_LEVEL else 0


## Contour d'un cristal d'essence (losange irrégulier) de hauteur `height`.
static func crystal_points(center: Vector2, height: float) -> PackedVector2Array:
	var half := height / 2.0
	return PackedVector2Array([center + Vector2(0, -half), center + Vector2(half * 0.55, -half * 0.2),
		center + Vector2(half * 0.35, half), center + Vector2(-half * 0.35, half), center + Vector2(-half * 0.55, -half * 0.2)])


func setup(owner_level: Level) -> void:
	level = owner_level
	level.stats.conquest = true
	stone = level.conquest_starting_stone
	depot_position = level.map.get_base_position()
	for cell in level.map.blocked_cells:
		rocks[cell] = ROCK_STONE
	for cell in level.essence_cells:
		veins[cell] = VEIN_ESSENCE
		level.map.block_cell(cell)
	if Relief.enabled:
		_setup_relief()
	for i in level.conquest_starting_workers:
		_add_worker(depot_position + Vector2.from_angle(PI * (0.8 + 0.4 * i)) * 30.0)
	_add_raiders()
	wave_countdown = FIRST_WAVE_DELAY
	level.spawner.wave_started.connect(func(_index: int) -> void:
		wave_countdown = -1.0
		changed.emit())


## Vue de trois quarts : ouvriers et bâtiments (enfants de ce nœud) se trient en
## profondeur avec les tours et les monstres ; chaque filon devient un groupe de
## cristaux debout, et les jauges passent par-dessus tout.
func _setup_relief() -> void:
	y_sort_enabled = true
	for cell: Vector2i in veins:
		var vein := EssenceVein.new()
		vein.conquest = self
		vein.cell = cell
		add_child(vein)
		vein.global_position = level.map.cell_to_world(cell) + Vector2(0, EssenceVein.FOOT_OFFSET)
		_vein_nodes[cell] = vein
	_gauges = DepositGauges.new()
	_gauges.conquest = self
	_gauges.z_index = 1
	add_child(_gauges)


## Redessine les gisements : jauges, cristaux et gisement désigné.
func _refresh_deposits() -> void:
	queue_redraw()
	if _gauges:
		_gauges.queue_redraw()
	for cell: Vector2i in _vein_nodes.keys():
		var vein: EssenceVein = _vein_nodes[cell]
		if not veins.has(cell):
			vein.queue_free()
			_vein_nodes.erase(cell)
		else:
			vein.queue_redraw()



## Ajoute les Pillards du niveau aux vagues (sur des copies : la scène ne change pas),
## en nombre réglé par la difficulté.
func _add_raiders() -> void:
	if level.raider == null:
		return
	var spawner := level.spawner
	var waves: Array[WaveData] = []
	for i in spawner.waves.size():
		var wave := spawner.waves[i]
		var count := level.raiders_per_wave[i] if i < level.raiders_per_wave.size() else 0
		if count > 0:
			wave = wave.duplicate()
			wave.groups = wave.groups.duplicate()
			var group := SpawnGroup.new()
			group.enemy = level.raider
			group.count = maxi(roundi(count * Difficulty.ENEMY_COUNT[level.difficulty]), 1)
			group.interval = RAIDER_INTERVAL
			group.start_delay = RAIDER_DELAY
			group.path_index = i % maxi(level.map.paths.size(), 1)
			wave.groups.append(group)
		waves.append(wave)
	spawner.waves = waves


func get_workers() -> Array[Worker]:
	var result: Array[Worker] = []
	for child in get_children():
		if child is Worker and child.is_alive:
			result.append(child)
	return result


## Ouvriers au plus : ceux du QG, et 2 de plus par Maison bâtie.
func get_max_workers() -> int:
	var houses := get_buildings(Building.Kind.HOUSE).size()
	return mini(BASE_WORKERS + houses * Building.HOUSE_WORKERS, MAX_WORKERS)


# --- Pierre, essence et gisements ----------------------------------------------

func has_stone(cell: Vector2i) -> bool:
	return rocks.has(cell)


## Filon d'essence qu'un ouvrier peut miner (pas sous un Extracteur).
func has_free_vein(cell: Vector2i) -> bool:
	return veins.has(cell) and not level.map.get_occupant(cell) is Building


## Gisement qu'un ouvrier peut miner : un rocher ou un filon libre.
func has_resource(cell: Vector2i) -> bool:
	return has_stone(cell) or has_free_vein(cell)


func resource_at(cell: Vector2i) -> Ore:
	return Ore.ESSENCE if veins.has(cell) else Ore.STONE


func can_afford(data: TowerData) -> bool:
	return stone >= stone_cost(data)


## Prend jusqu'à `amount` pierres d'un rocher ; vidé, il disparaît de la carte.
func take_stone(cell: Vector2i, amount: int) -> int:
	return take_resource(cell, amount)


## Prend jusqu'à `amount` pierres ou essences d'un gisement ; vidé, il disparaît.
func take_resource(cell: Vector2i, amount: int) -> int:
	var deposits := veins if veins.has(cell) else rocks
	if not deposits.has(cell):
		return 0
	var taken := mini(amount, deposits[cell])
	deposits[cell] -= taken
	if deposits[cell] <= 0:
		deposits.erase(cell)
		level.map.remove_rock(cell)
		if preferred_rock == cell:
			preferred_rock = NO_CELL
	_refresh_deposits()
	return taken


## Pierre ou essence rapportée à un dépôt.
func deposit(amount: int, kind := Ore.STONE, at := Vector2.INF) -> void:
	if amount <= 0:
		return
	var shown_at := (depot_position if at == Vector2.INF else at) + Vector2(0, -40)
	if kind == Ore.ESSENCE:
		add_essence(amount, shown_at)
		return
	stone += amount
	stone_mined += amount
	level.stats.stone_mined += amount
	_show_text(tr("+%d pierre") % amount, STONE_COLOR, shown_at, 14)
	changed.emit()


## Essence gagnée (rapportée par un ouvrier, ou tirée par un Extracteur).
func add_essence(amount: int, at: Vector2) -> void:
	essence += amount
	essence_mined += amount
	level.stats.essence_mined += amount
	_show_text(tr("+%d essence") % amount, ESSENCE_COLOR, at, 14)
	changed.emit()


## Dépôt le plus proche d'un point : le QG ou un Dépôt bâti.
func nearest_depot(from: Vector2) -> Vector2:
	var best := depot_position
	for building in get_buildings(Building.Kind.DEPOT):
		if building.global_position.distance_squared_to(from) < best.distance_squared_to(from):
			best = building.global_position
	return best


## Près du QG, les ouvriers sont à l'abri des monstres.
func is_safe(at: Vector2) -> bool:
	return at.distance_to(depot_position) < Worker.SAFE_RADIUS


## Désigne le gisement où miner (clic sur un rocher ou un filon) : les mineurs y vont
## tout de suite. Renvoie false si la case n'a pas de gisement libre.
func set_preferred_rock(cell: Vector2i) -> bool:
	if not has_resource(cell):
		return false
	preferred_rock = cell
	for worker in get_workers():
		if worker.order == Worker.Order.AUTO and (worker.is_mining() or (worker.state == Worker.State.IDLE and worker.cargo == 0)):
			worker.go_mine(cell, level.map.cell_to_world(cell))
	_refresh_deposits()
	return true


# --- Ouvriers --------------------------------------------------------------

func can_recruit() -> bool:
	return not level.is_over and get_workers().size() < get_max_workers() and level.gold >= WORKER_COST


## Recrute un ouvrier au QG contre de l'or. Renvoie l'ouvrier, ou null.
func recruit() -> Worker:
	if not can_recruit():
		return null
	level.gold -= WORKER_COST
	level.stats.gold_spent += WORKER_COST
	Sound.play(&"build")
	return _add_worker(depot_position)


func _add_worker(at: Vector2) -> Worker:
	var worker := Worker.new()
	worker.conquest = self
	worker.killed.connect(_on_worker_killed)
	add_child(worker)
	worker.global_position = at
	peak_workers = maxi(peak_workers, get_workers().size())
	if level.counts_achievements() and peak_workers >= Achievements.FOREMAN_WORKERS:
		level.unlock_achievements(["contremaitre"])
	changed.emit()
	return worker


func _on_worker_killed(worker: Worker) -> void:
	if _selected.has(worker):
		_selected.erase(worker)
		selection_changed.emit.call_deferred()
	workers_lost += 1
	level.stats.workers_lost += 1
	Sound.play(&"lives_lost", -6.0)
	_show_text(tr("Ouvrier perdu"), Color(1.0, 0.45, 0.4), worker.global_position + Vector2(0, -16), 14)
	changed.emit.call_deferred()


# --- Chantiers ---------------------------------------------------------------

## Paie la pierre d'une tour posée, qui devient un chantier.
func start_site(tower: Tower) -> void:
	stone -= stone_cost(tower.data)
	apply_research_to_tower(tower)
	tower.start_construction()
	_sites.append(tower)
	changed.emit()


## Un ouvrier bâtit un chantier (tour ou bâtiment) pendant `delta` secondes.
func build(site, delta: float) -> void:
	if not site.advance_construction(delta / build_time(site)):
		return
	_sites.erase(site)
	if site is Building:
		_on_building_built(site)
	else:
		level.on_tower_built(site)


## Une tour vendue rend sa pierre : toute pour un chantier, la même part que l'or sinon.
func refund(tower: Tower) -> void:
	_sites.erase(tower)
	var cost := stone_cost(tower.data)
	stone += cost if not tower.is_built() else roundi(cost * SELL_RATIO)
	changed.emit()


## Chantiers pas encore finis.
func get_sites() -> Array:
	return _sites.filter(func(site) -> bool: return is_instance_valid(site) and site.is_alive)


# --- Améliorations -----------------------------------------------------------

func can_afford_upgrade(tower: Tower) -> bool:
	return essence >= upgrade_essence_cost(tower)


## Paie l'essence d'une amélioration (avant qu'elle soit faite).
func pay_upgrade(tower: Tower) -> void:
	essence -= upgrade_essence_cost(tower)
	changed.emit()


# --- Bâtiments ---------------------------------------------------------------

## Bâtiments posés (bâtis ou en chantier) ; d'un seul type si `kind` est donné, et
## alors seulement ceux qui sont bâtis.
func get_buildings(kind := -1) -> Array[Building]:
	var result: Array[Building] = []
	for building in _buildings:
		if is_instance_valid(building) and building.is_alive and (kind < 0 or (building.kind == kind and building.is_built())):
			result.append(building)
	return result


func can_afford_building(kind: int) -> bool:
	var definition := Building.get_definition(kind)
	return level.gold >= definition.gold and stone >= definition.stone and essence >= definition.essence


## La case convient au bâtiment : une case libre, un filon libre (Extracteur) ou une case
## du chemin (Barricade ; dans un niveau libre, une case du chemin actuel des monstres).
func is_cell_suitable(cell: Vector2i, kind: int) -> bool:
	var map := level.map
	if not map.is_cell_in_grid(cell) or map.get_occupant(cell) != null:
		return false
	match Building.get_definition(kind).placement:
		Building.Placement.VEIN:
			return veins.has(cell)
		Building.Placement.PATH:
			return map.is_cell_walked(cell) and not map.is_cell_blocked(cell) \
				and map.cell_to_world(cell).distance_to(depot_position) > map.cell_size
	# Niveau libre : un bâtiment est un mur, comme une tour.
	return map.is_cell_buildable(cell) and not level.blocks_passage(cell)


func can_place_building(cell: Vector2i, kind: int) -> bool:
	return not level.is_over and kind >= 0 and is_cell_suitable(cell, kind) and can_afford_building(kind)


## Pose un bâtiment en chantier, payé tout de suite. Renvoie le bâtiment, ou null.
func place_building(cell: Vector2i, kind: int) -> Building:
	if not can_place_building(cell, kind):
		return null
	var definition := Building.get_definition(kind)
	level.gold -= definition.gold
	level.stats.gold_spent += definition.gold
	stone -= definition.stone
	essence -= definition.essence
	var building := Building.new()
	building.kind = kind
	building.conquest = self
	building.cell = cell
	building.destroyed.connect(_on_building_destroyed)
	add_child(building)
	move_child(building, 0)
	building.global_position = level.map.cell_to_world(cell)
	# Niveau libre : les monstres passent par une Barricade (ils la cassent), pas par les
	# autres bâtiments.
	level.map.occupy(cell, building, kind == Building.Kind.BARRICADE)
	_buildings.append(building)
	_sites.append(building)
	Sound.play(&"build")
	if preferred_rock == cell:
		preferred_rock = NO_CELL
	_refresh_deposits()
	changed.emit()
	return building


## Or, pierre et essence rendus à la démolition : tout pour un chantier, une part sinon.
func get_building_refund(building: Building) -> Dictionary:
	var definition := Building.get_definition(building.kind)
	var ratio := 1.0 if not building.is_built() else SELL_RATIO
	return {gold = roundi(definition.gold * ratio), stone = roundi(definition.stone * ratio),
		essence = roundi(definition.essence * ratio)}


## Démolit un bâtiment et en rend une part. Renvoie l'or rendu (0 si impossible).
func sell_building(building: Building) -> int:
	if not is_instance_valid(building) or not building.is_alive or level.is_over:
		return 0
	var refund_amounts := get_building_refund(building)
	if building.research_id != &"":
		# Atelier démoli en pleine recherche : elle est rendue en entier.
		var cost := Research.get_cost(building.research_id, building.research_level)
		refund_amounts.gold += cost.gold
		refund_amounts.stone += cost.stone
		refund_amounts.essence += cost.essence
		building.research_id = &""
	level.gold += refund_amounts.gold
	level.stats.gold_earned += refund_amounts.gold
	stone += refund_amounts.stone
	essence += refund_amounts.essence
	_show_text("+%d" % refund_amounts.gold, Level.GOLD_TEXT_COLOR, building.global_position, 16)
	Sound.play(&"sell")
	_remove_building(building)
	building.despawn()
	return refund_amounts.gold


func _on_building_built(building: Building) -> void:
	level.stats.buildings_built += 1
	Sound.play(&"upgrade")
	_show_text(tr("%s bâti") % tr(building.get_display_name()), Color(0.6, 1.0, 0.65),
		building.global_position + Vector2(0, -32), 14)
	changed.emit()


func _on_building_destroyed(building: Building) -> void:
	buildings_lost += 1
	Sound.play(&"lives_lost", -6.0)
	_show_text(tr("%s détruit") % tr(building.get_display_name()), Color(1.0, 0.45, 0.4),
		building.global_position + Vector2(0, -24), 14)
	_remove_building(building)


func _remove_building(building: Building) -> void:
	_sites.erase(building)
	_buildings.erase(building)
	if level.map.get_occupant(building.cell) == building:
		level.map.release(building.cell)
	if level.placer.inspected_building == building:
		level.placer.inspect_building(null)
	_refresh_deposits()
	changed.emit.call_deferred()


# --- Ouvriers choisis -----------------------------------------------------------

func get_selected_workers() -> Array[Worker]:
	var result: Array[Worker] = []
	for worker in _selected:
		if is_instance_valid(worker) and worker.is_alive:
			result.append(worker)
	return result


## Choisit des ouvriers (`add` : en plus de ceux déjà choisis).
func select_workers(workers: Array[Worker], add := false) -> void:
	var chosen := get_selected_workers() if add else ([] as Array[Worker])
	for worker in workers:
		if not chosen.has(worker):
			chosen.append(worker)
	_set_selection(chosen)


## Ajoute un ouvrier aux ouvriers choisis, ou l'en retire s'il l'était.
func toggle_worker(worker: Worker) -> void:
	var chosen := get_selected_workers()
	if chosen.has(worker):
		chosen.erase(worker)
	else:
		chosen.append(worker)
	_set_selection(chosen)


## Choisit tous les ouvriers, ou plus aucun s'ils l'étaient déjà tous.
func toggle_all_workers() -> void:
	var workers := get_workers()
	_set_selection([] as Array[Worker] if get_selected_workers().size() == workers.size() else workers)


func clear_selection() -> void:
	if not _selected.is_empty():
		_set_selection([] as Array[Worker])


func _set_selection(workers: Array[Worker]) -> void:
	for worker in get_selected_workers():
		worker.selected = false
	_selected = workers
	for worker in workers:
		worker.selected = true
	selection_changed.emit()


## Ouvrier sous un point de la carte (le plus proche, à `radius` au plus), ou null.
func worker_at(at: Vector2, radius := Worker.PICK_RADIUS) -> Worker:
	var best: Worker = null
	for worker in get_workers():
		var distance := worker.get_pick_point().distance_to(at)
		if distance < radius and (best == null or distance < best.get_pick_point().distance_to(at)):
			best = worker
	return best


## Ouvriers dont le corps est dans un rectangle de la carte.
func workers_in_rect(rect: Rect2) -> Array[Worker]:
	var result: Array[Worker] = []
	for worker in get_workers():
		if rect.grow(Worker.BODY_RADIUS).has_point(worker.get_pick_point()):
			result.append(worker)
	return result


## Tâche que donnerait un clic sur cette case aux ouvriers choisis : miner son gisement,
## bâtir son chantier, rentrer au QG (Worker.Order.AUTO : aucune).
func order_for_cell(cell: Vector2i) -> Worker.Order:
	if has_resource(cell):
		return Worker.Order.MINE
	var occupant = level.map.get_occupant(cell)
	if (occupant is Tower or occupant is Building) and occupant.is_alive and not occupant.is_built():
		return Worker.Order.BUILD
	if cell == level.map.world_to_cell(depot_position):
		return Worker.Order.HOME
	return Worker.Order.AUTO


## Affecte les ouvriers choisis à la tâche de la case (voir order_for_cell). Renvoie false
## s'il n'y a pas d'ouvrier choisi ou pas de tâche sur la case.
func order_selected(cell: Vector2i) -> bool:
	var workers := get_selected_workers()
	var order := order_for_cell(cell)
	if workers.is_empty() or order == Worker.Order.AUTO:
		return false
	var target = level.map.get_occupant(cell) if order == Worker.Order.BUILD else null
	for i in workers.size():
		workers[i].assign(order, cell, target, i)
	var at := level.map.cell_to_world(cell)
	var texts := {Worker.Order.MINE: tr("Miner ×%d"), Worker.Order.BUILD: tr("Bâtir ×%d"), Worker.Order.HOME: tr("Au QG ×%d")}
	_show_text(texts[order] % workers.size(), Worker.SELECTED_COLOR, at + Vector2(0, -30), 14)
	Sound.play(&"build", -10.0)
	selection_changed.emit()
	return true


## Rend les ouvriers choisis aux ordres automatiques, et les relâche.
func release_selected() -> void:
	for worker in get_selected_workers():
		worker.assign(Worker.Order.AUTO)
	_set_selection([] as Array[Worker])


## Envoie les ouvriers choisis à l'abri au QG.
func send_selected_home() -> void:
	for worker in get_selected_workers():
		worker.assign(Worker.Order.HOME)
	selection_changed.emit()


# --- Atelier : améliorations de la partie ----------------------------------------

func get_research_level(id: StringName) -> int:
	return research_levels.get(id, 0)


## Bonus atteint d'une amélioration : son bonus par niveau fois son niveau.
func get_research_bonus(id: StringName) -> float:
	return Research.get_definition(id).per_level * get_research_level(id)


## Atelier qui cherche cette amélioration, ou null.
func get_researching_workshop(id: StringName) -> Building:
	for workshop in get_buildings(Building.Kind.WORKSHOP):
		if workshop.research_id == id:
			return workshop
	return null


## Ce qui empêche de lancer cette amélioration dans cet Atelier ("" : rien).
func research_blocker(workshop: Building, id: StringName) -> String:
	if level.is_over or not is_instance_valid(workshop) or not workshop.is_built():
		return "Atelier pas prêt"
	if get_research_level(id) >= Research.get_max_level(id):
		return "Niveau maximum"
	if get_researching_workshop(id) != null:
		return "Déjà en recherche"
	if workshop.research_id != &"":
		return "Atelier occupé"
	var cost := Research.get_cost(id, get_research_level(id) + 1)
	if level.gold < cost.gold or stone < cost.stone or essence < cost.essence:
		return "Pas assez de ressources"
	return ""


## Paie et lance une amélioration dans un Atelier. Renvoie false si c'est impossible.
func start_research(workshop: Building, id: StringName) -> bool:
	if research_blocker(workshop, id) != "":
		return false
	var next_level := get_research_level(id) + 1
	var cost := Research.get_cost(id, next_level)
	level.gold -= cost.gold
	level.stats.gold_spent += cost.gold
	stone -= cost.stone
	essence -= cost.essence
	workshop.start_research(id, next_level)
	Sound.play(&"build")
	changed.emit()
	return true


## Une amélioration finit sa recherche : elle monte d'un niveau, et ses effets prennent
## tout de suite (tours et bâtiments déjà posés compris).
func complete_research(id: StringName) -> void:
	var before := get_building_health_multiplier()
	research_levels[id] = get_research_level(id) + 1
	if id == Research.TOWER_DAMAGE or id == Research.TOWER_RANGE or id == Research.TOWER_FIRE_RATE:
		for tower in level.get_towers():
			apply_research_to_tower(tower)
	elif id == Research.WORLD_FORTIFY:
		for building in get_buildings():
			building.scale_health(get_building_health_multiplier() / before)
	Sound.play(&"upgrade")
	var definition := Research.get_definition(id)
	var workshop_at := depot_position
	for workshop in get_buildings(Building.Kind.WORKSHOP):
		workshop_at = workshop.global_position
	_show_text(tr("%s : niveau %d") % [tr(definition.name), get_research_level(id)],
		Research.CATEGORY_COLORS[definition.category], workshop_at + Vector2(0, -44), 15)
	changed.emit()


## Bonus des tours (dégâts, portée, cadence) donnés aux tours par l'Atelier.
func apply_research_to_tower(tower: Tower) -> void:
	# Le niveau y ajoute ceux des coffres.
	level.refresh_tower_bonuses(tower)


func get_worker_speed() -> float:
	return Worker.SPEED * (1.0 + get_research_bonus(Research.WORKER_SPEED))


## Vitesse de minage et de construction des ouvriers (1 = sans amélioration).
func get_work_speed() -> float:
	return 1.0 + get_research_bonus(Research.WORKER_TOOLS) + level.get_chest_bonus(ChestBonus.WORKERS)


## Pierre ou essence portée à chaque voyage.
func get_carry(kind: Ore) -> int:
	var bonus := roundi(get_research_bonus(Research.WORKER_CARRY))
	return (Worker.ESSENCE_CARRY if kind == Ore.ESSENCE else Worker.CARRY) + bonus


func get_reward_multiplier() -> float:
	return 1.0 + get_research_bonus(Research.WORLD_BOUNTY)


func get_building_health_multiplier() -> float:
	return 1.0 + get_research_bonus(Research.WORLD_FORTIFY)


## Secondes entre deux essences d'un Extracteur.
func get_extract_interval() -> float:
	return Building.EXTRACT_INTERVAL / (1.0 + get_research_bonus(Research.WORLD_EXTRACTION))


# --- Vagues ------------------------------------------------------------------

## La carte est vidée : la prochaine vague part au bout du compte à rebours.
func on_wave_cleared() -> void:
	if level.spawner.has_next_wave() and wave_countdown < 0.0:
		wave_countdown = WAVE_DELAY
		changed.emit()


# --- Mise à jour -------------------------------------------------------------

func _process(delta: float) -> void:
	if level.is_over:
		return
	if wave_countdown >= 0.0 and not level.is_choosing_towers:
		var before := ceili(wave_countdown)
		wave_countdown -= delta
		if wave_countdown <= 0.0:
			wave_countdown = -1.0
			level.start_next_wave()
		if ceili(wave_countdown) != before:
			changed.emit()
	_assign_workers()


## Donne un ordre aux ouvriers : les chantiers d'abord (on prend les plus proches, même
## en train de miner), puis la mine.
func _assign_workers() -> void:
	var workers := get_workers()
	for site in get_sites():
		var builders := workers.filter(func(worker: Worker) -> bool: return worker.is_building(site)).size()
		while builders < BUILDERS_PER_SITE:
			var best: Worker = null
			for worker in workers:
				var free := worker.order == Worker.Order.AUTO and (worker.state == Worker.State.IDLE or worker.is_mining())
				if free and (best == null or worker.global_position.distance_squared_to(site.global_position)
						< best.global_position.distance_squared_to(site.global_position)):
					best = worker
			if best == null:
				break
			best.go_build(site)
			builders += 1
	for worker in workers:
		if worker.state != Worker.State.IDLE or _follow_order(worker):
			continue
		var cell := _resource_to_mine(worker, workers) if worker.cargo == 0 else NO_CELL
		if cell != NO_CELL:
			worker.go_mine(cell, level.map.cell_to_world(cell))
		elif worker.cargo > 0 or not is_safe(worker.global_position):
			worker.go_deposit()


## Ouvrier inoccupé qui a une tâche donnée à la main : il la reprend (retourne au même
## gisement, au même chantier, reste au QG) et la fonction renvoie true ; une tâche finie
## ou devenue impossible le rend aux ordres automatiques (false).
func _follow_order(worker: Worker) -> bool:
	match worker.order:
		Worker.Order.MINE:
			if worker.cargo > 0:
				worker.go_deposit()
				return true
			if has_resource(worker.order_cell):
				worker.go_mine(worker.order_cell, level.map.cell_to_world(worker.order_cell))
				return true
		Worker.Order.BUILD:
			var site = worker.order_site
			if is_instance_valid(site) and site.is_alive and not site.is_built():
				worker.go_build(site, worker.order_slot)
				return true
		Worker.Order.HOME:
			if worker.cargo > 0 or not is_safe(worker.global_position):
				worker.go_deposit()
			return true
	if worker.order != Worker.Order.AUTO:
		worker.order = Worker.Order.AUTO
		worker.order_site = null
		selection_changed.emit()
	return false


## Gisement à miner pour un ouvrier : celui désigné par le joueur ; sinon un filon libre
## si personne ne mine encore l'essence ; sinon le rocher le plus rentable (le moins de
## marche, aller et retour au dépôt le plus proche).
func _resource_to_mine(worker: Worker, workers: Array[Worker]) -> Vector2i:
	if has_resource(preferred_rock):
		return preferred_rock
	var essence_miners := workers.filter(func(other: Worker) -> bool: return other.is_mining_essence()).size()
	var free_veins: Array = veins.keys().filter(has_free_vein)
	if essence_miners < AUTO_ESSENCE_MINERS and not free_veins.is_empty():
		return _closest_deposit(worker.global_position, free_veins)
	if rocks.is_empty():
		return _closest_deposit(worker.global_position, free_veins) if not free_veins.is_empty() else NO_CELL
	return _closest_deposit(worker.global_position, rocks.keys())


func _closest_deposit(from: Vector2, cells: Array) -> Vector2i:
	var best := NO_CELL
	var best_cost := INF
	for cell: Vector2i in cells:
		var at := level.map.cell_to_world(cell)
		var cost := from.distance_to(at) + at.distance_to(nearest_depot(at)) * 2.0
		if cost < best_cost:
			best = cell
			best_cost = cost
	return best


func _show_text(text: String, color: Color, at: Vector2, font_size: int) -> void:
	var label := FloatingText.new()
	label.text = text
	label.color = color
	label.font_size = font_size
	label.position = level.effects.to_local(at)
	level.effects.add_child(label)


## Sous chaque rocher, une jauge de la pierre restante ; les filons d'essence sont des
## cristaux, avec leur jauge ; le gisement désigné est entouré. Dans la vue de trois
## quarts, seul ce qui est à plat sur le sol reste ici (lueur des filons, cercle du
## gisement désigné) : cristaux et jauges ont leurs nœuds (EssenceVein, DepositGauges).
func _draw() -> void:
	var map := level.map
	if Relief.enabled:
		for cell: Vector2i in veins:
			var foot := to_local(map.cell_to_world(cell)) + Vector2(0, EssenceVein.FOOT_OFFSET)
			draw_colored_polygon(Relief.ellipse(foot, map.cell_size * 0.42, map.cell_size * 0.42 * Relief.GROUND_SQUASH * 0.6),
				Color(ESSENCE_COLOR, 0.22))
		if has_resource(preferred_rock):
			var foot := to_local(map.cell_to_world(preferred_rock)) + Vector2(0, 8)
			var ring := Relief.ellipse(foot, map.cell_size * 0.5, map.cell_size * 0.5 * Relief.GROUND_SQUASH * 0.7, 0.0, TAU, 40)
			draw_polyline(ring, Color(0, 0, 0, 0.4), 5.0, true)
			draw_polyline(ring, Color(1.0, 0.82, 0.25), 2.5, true)
		return
	for cell: Vector2i in rocks:
		_draw_gauge(map.cell_to_world(cell), rocks[cell] / float(ROCK_STONE), STONE_COLOR)
	for cell: Vector2i in veins:
		var center := to_local(map.cell_to_world(cell))
		if not map.get_occupant(cell) is Building:
			for offset: Vector2 in [Vector2(-12, 6), Vector2(11, 8), Vector2(0, -4)]:
				var height := 26.0 if offset.y < 0.0 else 18.0
				draw_colored_polygon(crystal_points(center + offset, height), ESSENCE_COLOR.darkened(0.15))
				draw_polyline(crystal_points(center + offset, height) + PackedVector2Array([crystal_points(center + offset, height)[0]]),
					ESSENCE_COLOR.lightened(0.4), 1.5)
			_draw_gauge(map.cell_to_world(cell), veins[cell] / float(VEIN_ESSENCE), ESSENCE_COLOR)
		else:
			draw_circle(center, map.cell_size * 0.42, Color(ESSENCE_COLOR, 0.18))
	if has_resource(preferred_rock):
		draw_arc(to_local(map.cell_to_world(preferred_rock)), map.cell_size * 0.55, 0.0, TAU, 40, Color(1.0, 0.82, 0.25), 2.5)


func _draw_gauge(world_center: Vector2, ratio: float, color: Color) -> void:
	var cell_size := level.map.cell_size
	var center := to_local(world_center)
	var width := cell_size * 0.7
	var top_left := center + Vector2(-width / 2.0, cell_size * 0.5 - 9.0)
	draw_rect(Rect2(top_left, Vector2(width, 5)), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(top_left, Vector2(width * ratio, 5)), color)


## Vue de trois quarts : les cristaux d'un filon, debout au-dessus de leur pied et triés
## en profondeur. Sous un Extracteur, ils disparaissent (il a son propre cristal).
class EssenceVein extends Node2D:
	## Le pied des cristaux, sous le centre de la case.
	const FOOT_OFFSET := 8.0
	## Cristaux du filon : décalage du pied, hauteur, largeur, inclinaison.
	const CRYSTALS: Array[Vector4] = [Vector4(-13, -4, 20, 9), Vector4(12, -6, 18, 8), Vector4(1, -9, 30, 12),
		Vector4(-6, 4, 14, 7), Vector4(10, 5, 12, 6)]
	const LEANS: Array[float] = [-0.25, 0.3, 0.0, -0.1, 0.2]

	var conquest: Conquest
	var cell := Vector2i.ZERO

	func _draw() -> void:
		if conquest.level.map.get_occupant(cell) is Building:
			return
		Relief.draw_shadow(self, Vector2(4, 0), 24.0, 8.0, 0.28)
		var color := Conquest.ESSENCE_COLOR
		for i in CRYSTALS.size():
			var crystal := CRYSTALS[i]
			BuildingRelief.draw_crystal(self, Vector2(crystal.x, crystal.y), crystal.z, crystal.w,
				color if i != 2 else color.lightened(0.1), Color.WHITE, LEANS[i])


## Vue de trois quarts : les jauges des gisements (pierre restante d'un rocher, essence
## d'un filon), au-dessus de chacun et par-dessus tout ce qui passe devant.
class DepositGauges extends Node2D:
	## Hauteur des jauges au-dessus du centre de la case : au-dessus du rocher, ou des
	## cristaux du filon.
	const ROCK_HEIGHT := 17.0
	const VEIN_HEIGHT := 34.0

	var conquest: Conquest

	func _draw() -> void:
		var map := conquest.level.map
		for cell: Vector2i in conquest.rocks:
			_draw_gauge(map.cell_to_world(cell) + Vector2(0, -ROCK_HEIGHT), conquest.rocks[cell] / float(Conquest.ROCK_STONE),
				Conquest.STONE_COLOR)
		for cell: Vector2i in conquest.veins:
			if not map.get_occupant(cell) is Building:
				_draw_gauge(map.cell_to_world(cell) + Vector2(0, -VEIN_HEIGHT),
					conquest.veins[cell] / float(Conquest.VEIN_ESSENCE), Conquest.ESSENCE_COLOR)

	func _draw_gauge(world_center: Vector2, ratio: float, color: Color) -> void:
		var width := conquest.level.map.cell_size * 0.55
		var top_left := to_local(world_center) - Vector2(width / 2.0, 2.0)
		draw_rect(Rect2(top_left - Vector2.ONE, Vector2(width + 2.0, 6)), Relief.OUTLINE)
		draw_rect(Rect2(top_left, Vector2(width, 4)), Color(0.2, 0.18, 0.16))
		draw_rect(Rect2(top_left, Vector2(width * ratio, 4)), color)
		draw_rect(Rect2(top_left, Vector2(width * ratio, 1.5)), color.lightened(0.4))
