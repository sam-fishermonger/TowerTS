class_name Level
extends Node2D
## Niveau jouable : grille de placement des tours, chemin des ennemis, vagues, or et vies.

signal game_over(victory: bool)

const CELL_SIZE := 64
## Coin haut-gauche de la grille (sous la barre du HUD).
const GRID_ORIGIN := Vector2(0, 64)
const GRID_COLUMNS := 20
const GRID_ROWS := 10
const PATH_WIDTH := 48.0
const TOWER_SCENE := preload("res://scenes/towers/tower.tscn")
const TITLE_SCREEN := "res://scenes/ui/title_screen.tscn"

@export var level_name := "Niveau 1"
@export var starting_gold := 150
@export var starting_lives := 20
@export var tower_types: Array[TowerData] = []

var gold := 0:
	set(value):
		gold = value
		_refresh_hud()
var lives := 0:
	set(value):
		lives = maxi(value, 0)
		_refresh_hud()
var selected_tower: TowerData
var is_over := false

var _path_cells := {}
var _towers_by_cell := {}
var _hovered_tower: Tower
var _wave_bonus_paid := -1

@onready var enemy_path: Path2D = $EnemyPath
@onready var towers: Node2D = $Towers
@onready var projectiles: Node2D = $Projectiles
@onready var preview: PlacementPreview = $PlacementPreview
@onready var spawner: WaveSpawner = $WaveSpawner
@onready var hud: Hud = $HUD


func _ready() -> void:
	_compute_path_cells()
	hud.setup(level_name, tower_types)
	hud.tower_selected.connect(select_tower)
	hud.next_wave_requested.connect(start_next_wave)
	hud.restart_requested.connect(_on_restart_requested)
	hud.menu_requested.connect(_on_menu_requested)
	spawner.enemy_spawned.connect(_on_enemy_spawned)
	spawner.wave_started.connect(func(_index: int) -> void: _refresh_hud())
	spawner.wave_spawning_finished.connect(func(_index: int) -> void: _check_wave_cleared())
	preview.visible = false
	gold = starting_gold
	lives = starting_lives


# --- Grille ---------------------------------------------------------------

func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(((world_position - GRID_ORIGIN) / CELL_SIZE).floor())


func cell_to_world(cell: Vector2i) -> Vector2:
	return GRID_ORIGIN + (Vector2(cell) + Vector2(0.5, 0.5)) * CELL_SIZE


func is_cell_in_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_COLUMNS and cell.y < GRID_ROWS


func is_cell_buildable(cell: Vector2i) -> bool:
	return is_cell_in_grid(cell) and not _path_cells.has(cell) and not _towers_by_cell.has(cell)


func _compute_path_cells() -> void:
	for point in enemy_path.curve.get_baked_points():
		var cell := world_to_cell(enemy_path.to_global(point))
		if is_cell_in_grid(cell):
			_path_cells[cell] = true


# --- Tours ------------------------------------------------------------------

func can_place_tower(cell: Vector2i, data: TowerData) -> bool:
	return data != null and not is_over and is_cell_buildable(cell) and gold >= data.cost


## Place une tour sur la case si c'est possible. Renvoie la tour, ou null.
func place_tower(cell: Vector2i, data: TowerData) -> Tower:
	if not can_place_tower(cell, data):
		return null
	var tower: Tower = TOWER_SCENE.instantiate()
	tower.data = data
	tower.position = cell_to_world(cell)
	tower.projectile_container = projectiles
	towers.add_child(tower)
	_towers_by_cell[cell] = tower
	gold -= data.cost
	return tower


func select_tower(data: TowerData) -> void:
	selected_tower = data
	hud.set_selected_tower(data)
	_update_hover(get_global_mouse_position())


func _unhandled_input(event: InputEvent) -> void:
	if is_over:
		return
	if event is InputEventMouseMotion:
		_update_hover(get_global_mouse_position())
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and selected_tower:
			var placed := place_tower(world_to_cell(get_global_mouse_position()), selected_tower)
			# Maj + clic garde la tour sélectionnée pour en poser plusieurs.
			if placed and not event.shift_pressed:
				select_tower(null)
			else:
				_update_hover(get_global_mouse_position())
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT and selected_tower:
			select_tower(null)
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and selected_tower:
		select_tower(null)
		get_viewport().set_input_as_handled()


func _update_hover(world_position: Vector2) -> void:
	var cell := world_to_cell(world_position)
	var hovered: Tower = _towers_by_cell.get(cell)
	if hovered != _hovered_tower:
		if is_instance_valid(_hovered_tower):
			_hovered_tower.show_range = false
		_hovered_tower = hovered
		if hovered:
			hovered.show_range = true
	if selected_tower and is_cell_in_grid(cell):
		preview.show_at(cell_to_world(cell), selected_tower, can_place_tower(cell, selected_tower))
	else:
		preview.visible = false


# --- Vagues et ennemis ----------------------------------------------------

func start_next_wave() -> void:
	if not is_over:
		spawner.start_next_wave()


func _on_enemy_spawned(enemy: Enemy) -> void:
	enemy.died.connect(_on_enemy_died)
	enemy.reached_end.connect(_on_enemy_reached_end)


func _on_enemy_died(enemy: Enemy) -> void:
	gold += enemy.data.reward
	_check_wave_cleared()


func _on_enemy_reached_end(enemy: Enemy) -> void:
	lives -= enemy.data.damage
	if lives <= 0:
		_end_game(false)
	else:
		_check_wave_cleared()


func _alive_enemy_count() -> int:
	return get_tree().get_nodes_in_group(Enemy.GROUP).size()


func _check_wave_cleared() -> void:
	if is_over or spawner.is_spawning or _alive_enemy_count() > 0:
		return
	if spawner.current_wave >= 0 and _wave_bonus_paid < spawner.current_wave:
		_wave_bonus_paid = spawner.current_wave
		gold += spawner.waves[spawner.current_wave].bonus_gold
	if not spawner.has_next_wave():
		_end_game(true)


func _end_game(victory: bool) -> void:
	if is_over:
		return
	is_over = true
	select_tower(null)
	hud.show_end_screen(victory)
	game_over.emit(victory)
	get_tree().paused = true


func _on_restart_requested() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu_requested() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCREEN)


# --- Affichage --------------------------------------------------------------

func _refresh_hud() -> void:
	if not is_node_ready():
		return
	hud.update_stats(gold, lives, spawner.current_wave + 1, spawner.waves.size())


func _process(_delta: float) -> void:
	# Le bouton de vague dépend de l'état du spawner, qui évolue en continu.
	hud.set_next_wave_available(not is_over and not spawner.is_spawning and spawner.has_next_wave())


func _draw() -> void:
	var grid_rect := Rect2(GRID_ORIGIN, Vector2(GRID_COLUMNS, GRID_ROWS) * CELL_SIZE)
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.13, 0.17, 0.13))
	draw_rect(grid_rect, Color(0.2, 0.32, 0.2))
	for x in range(GRID_COLUMNS + 1):
		var from := GRID_ORIGIN + Vector2(x * CELL_SIZE, 0)
		draw_line(from, from + Vector2(0, GRID_ROWS * CELL_SIZE), Color(1, 1, 1, 0.06))
	for y in range(GRID_ROWS + 1):
		var from := GRID_ORIGIN + Vector2(0, y * CELL_SIZE)
		draw_line(from, from + Vector2(GRID_COLUMNS * CELL_SIZE, 0), Color(1, 1, 1, 0.06))
	var points := enemy_path.curve.get_baked_points()
	draw_polyline(points, Color(0.55, 0.45, 0.3), PATH_WIDTH + 8.0, true)
	draw_polyline(points, Color(0.72, 0.6, 0.42), PATH_WIDTH, true)
	# Base du joueur au bout du chemin.
	var base := points[points.size() - 1] + Vector2(-64, 0)
	draw_rect(Rect2(base - Vector2(24, 32), Vector2(48, 64)), Color(0.35, 0.5, 0.85))
