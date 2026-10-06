class_name Conquest
extends Node2D
## Mode Conquête (prototype) : les tours coûtent de l'or et de la pierre, et des ouvriers
## les bâtissent. Les ouvriers minent la pierre des rochers de la carte et la rapportent
## au QG (la base) ; un rocher vidé disparaît et libère sa case. Une tour posée n'est
## d'abord qu'un chantier, qui ne tire qu'une fois bâti. Les vagues partent seules au bout
## d'un compte à rebours, qu'on peut toujours devancer avec « Lancer la vague ».
## Le niveau crée ce nœud quand il a `conquest_mode`.

const STARTING_STONE := 40
const STARTING_WORKERS := 3
const MAX_WORKERS := 8
## Prix d'un ouvrier, en or.
const WORKER_COST := 40
## Pierre d'un rocher.
const ROCK_STONE := 30
## Pierre d'une tour, par or de son prix.
const STONE_PER_GOLD := 0.4
## Ouvriers qui bâtissent un même chantier, au plus.
const BUILDERS_PER_SITE := 2
## Secondes avant la première vague, puis entre la fin d'une vague et la suivante.
const FIRST_WAVE_DELAY := 45.0
const WAVE_DELAY := 25.0
const STONE_COLOR := Color(0.78, 0.8, 0.88)
const NO_CELL := Vector2i(-1000, -1000)

## Émis quand la pierre, les ouvriers ou le compte à rebours changent.
signal changed

var level: Level
var stone := 0
## Pierre restante de chaque rocher (case -> pierre).
var rocks := {}
## Rocher désigné par le joueur : les ouvriers y minent tant qu'il reste de la pierre.
var preferred_rock := NO_CELL
## Point de dépôt de la pierre : le QG, au bout du chemin.
var depot_position := Vector2.ZERO
## Secondes avant le départ de la prochaine vague (négatif : pas de compte à rebours).
var wave_countdown := -1.0
## Bilan de la partie.
var stone_mined := 0
var workers_lost := 0

var _sites: Array[Tower] = []


## Pierre demandée pour un type de tour.
static func stone_cost(data: TowerData) -> int:
	return ceili(data.get_cost() * STONE_PER_GOLD)


## Secondes pour bâtir un type de tour avec un seul ouvrier.
static func build_time(data: TowerData) -> float:
	return 3.0 + data.get_cost() / 25.0


func setup(owner_level: Level) -> void:
	level = owner_level
	stone = STARTING_STONE
	depot_position = level.map.get_base_position()
	for cell in level.map.blocked_cells:
		rocks[cell] = ROCK_STONE
	for i in STARTING_WORKERS:
		_add_worker(depot_position + Vector2.from_angle(PI * (0.8 + 0.4 * i)) * 30.0)
	wave_countdown = FIRST_WAVE_DELAY
	level.spawner.wave_started.connect(func(_index: int) -> void:
		wave_countdown = -1.0
		changed.emit())


func get_workers() -> Array[Worker]:
	var result: Array[Worker] = []
	for child in get_children():
		if child is Worker and child.is_alive:
			result.append(child)
	return result


# --- Pierre et rochers -----------------------------------------------------

func has_stone(cell: Vector2i) -> bool:
	return rocks.has(cell)


func can_afford(data: TowerData) -> bool:
	return stone >= stone_cost(data)


## Prend jusqu'à `amount` pierres d'un rocher ; vidé, il disparaît de la carte.
func take_stone(cell: Vector2i, amount: int) -> int:
	if not rocks.has(cell):
		return 0
	var taken := mini(amount, rocks[cell])
	rocks[cell] -= taken
	if rocks[cell] <= 0:
		rocks.erase(cell)
		level.map.remove_rock(cell)
		if preferred_rock == cell:
			preferred_rock = NO_CELL
	queue_redraw()
	return taken


## Pierre rapportée au QG.
func deposit(amount: int) -> void:
	stone += amount
	stone_mined += amount
	_show_text("+%d pierre" % amount, STONE_COLOR, depot_position + Vector2(0, -40), 14)
	changed.emit()


## Désigne le rocher où miner (clic sur un rocher) : les mineurs y vont tout de suite.
## Renvoie false si la case n'a pas de rocher.
func set_preferred_rock(cell: Vector2i) -> bool:
	if not rocks.has(cell):
		return false
	preferred_rock = cell
	for worker in get_workers():
		if worker.is_mining() or (worker.state == Worker.State.IDLE and worker.cargo < Worker.CARRY):
			worker.go_mine(cell, level.map.cell_to_world(cell))
	queue_redraw()
	return true


# --- Ouvriers --------------------------------------------------------------

func can_recruit() -> bool:
	return not level.is_over and get_workers().size() < MAX_WORKERS and level.gold >= WORKER_COST


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
	changed.emit()
	return worker


func _on_worker_killed(worker: Worker) -> void:
	workers_lost += 1
	Sound.play(&"lives_lost", -6.0)
	_show_text("Ouvrier perdu", Color(1.0, 0.45, 0.4), worker.global_position + Vector2(0, -16), 14)
	changed.emit.call_deferred()


# --- Chantiers ---------------------------------------------------------------

## Paie la pierre d'une tour posée, qui devient un chantier.
func start_site(tower: Tower) -> void:
	stone -= stone_cost(tower.data)
	tower.start_construction()
	_sites.append(tower)
	changed.emit()


## Un ouvrier bâtit le chantier pendant `delta` secondes.
func build(tower: Tower, delta: float) -> void:
	if tower.advance_construction(delta / build_time(tower.data)):
		_sites.erase(tower)
		level.on_tower_built(tower)


## Une tour vendue rend sa pierre : toute pour un chantier, la même part que l'or sinon.
func refund(tower: Tower) -> void:
	_sites.erase(tower)
	var cost := stone_cost(tower.data)
	stone += cost if not tower.is_built() else roundi(cost * Tower.SELL_RATIO)
	changed.emit()


## Chantiers pas encore finis.
func get_sites() -> Array[Tower]:
	return _sites.filter(func(tower: Tower) -> bool: return is_instance_valid(tower) and tower.is_alive)


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
	for tower in get_sites():
		var builders := workers.filter(func(worker: Worker) -> bool: return worker.is_building(tower)).size()
		while builders < BUILDERS_PER_SITE:
			var best: Worker = null
			for worker in workers:
				var free := worker.state == Worker.State.IDLE or worker.is_mining()
				if free and (best == null or worker.global_position.distance_squared_to(tower.global_position)
						< best.global_position.distance_squared_to(tower.global_position)):
					best = worker
			if best == null:
				break
			best.go_build(tower)
			builders += 1
	for worker in workers:
		if worker.state != Worker.State.IDLE:
			continue
		var cell := _rock_to_mine() if worker.cargo < Worker.CARRY else NO_CELL
		if cell != NO_CELL:
			worker.go_mine(cell, level.map.cell_to_world(cell))
		elif worker.cargo > 0 or worker.global_position.distance_to(depot_position) > Worker.SAFE_RADIUS:
			worker.go_deposit()


## Rocher à miner : celui désigné par le joueur, sinon le plus proche du QG.
func _rock_to_mine() -> Vector2i:
	if rocks.has(preferred_rock):
		return preferred_rock
	var best := NO_CELL
	var best_distance := INF
	for cell: Vector2i in rocks:
		var distance := level.map.cell_to_world(cell).distance_squared_to(depot_position)
		if distance < best_distance:
			best = cell
			best_distance = distance
	return best


func _show_text(text: String, color: Color, at: Vector2, font_size: int) -> void:
	var label := FloatingText.new()
	label.text = text
	label.color = color
	label.font_size = font_size
	label.position = level.effects.to_local(at)
	level.effects.add_child(label)


## Sous chaque rocher, une jauge de la pierre restante ; le rocher désigné est entouré.
func _draw() -> void:
	var map := level.map
	for cell: Vector2i in rocks:
		var center := to_local(map.cell_to_world(cell))
		var width := map.cell_size * 0.7
		var top_left := center + Vector2(-width / 2.0, map.cell_size * 0.5 - 9.0)
		draw_rect(Rect2(top_left, Vector2(width, 5)), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(top_left, Vector2(width * rocks[cell] / float(ROCK_STONE), 5)), STONE_COLOR)
		if cell == preferred_rock:
			draw_arc(center, map.cell_size * 0.55, 0.0, TAU, 40, Color(1.0, 0.82, 0.25), 2.5)
