class_name Level
extends Node2D
## Niveau jouable : relie la carte, les vagues, le placement des tours et le HUD,
## et tient l'économie de la partie (or, vies) jusqu'à la victoire ou la défaite.

signal game_over(victory: bool)

const TITLE_SCREEN := "res://scenes/ui/title_screen.tscn"

@export var level_name := "Niveau"
@export var starting_gold := 150
@export var starting_lives := 20
@export var tower_types: Array[TowerData] = []
## Niveau proposé après une victoire (vide = dernier niveau).
@export_file("*.tscn") var next_level := ""

var gold := 0:
	set(value):
		gold = value
		_refresh_hud()
var lives := 0:
	set(value):
		lives = maxi(value, 0)
		_refresh_hud()
var is_over := false

var _wave_bonus_paid := -1

@onready var map: GameMap = $Map
@onready var enemies: Node2D = $Enemies
@onready var towers: Node2D = $Towers
@onready var projectiles: Node2D = $Projectiles
@onready var placer: TowerPlacer = $TowerPlacer
@onready var spawner: WaveSpawner = $WaveSpawner
@onready var hud: Hud = $HUD


func _ready() -> void:
	placer.level = self
	placer.selection_changed.connect(hud.set_selected_tower)
	hud.setup(level_name, tower_types)
	hud.tower_selected.connect(select_tower)
	hud.next_wave_requested.connect(start_next_wave)
	hud.restart_requested.connect(_on_restart_requested)
	hud.next_level_requested.connect(_on_next_level_requested)
	hud.menu_requested.connect(_on_menu_requested)
	spawner.enemy_spawned.connect(_on_enemy_spawned)
	spawner.wave_started.connect(func(_index: int) -> void: _refresh_hud())
	spawner.wave_spawning_finished.connect(func(_index: int) -> void: _check_wave_cleared())
	gold = starting_gold
	lives = starting_lives


func has_next_level() -> bool:
	return not next_level.is_empty()


# --- Tours ------------------------------------------------------------------

func select_tower(data: TowerData) -> void:
	placer.select(data)


func can_place_tower(cell: Vector2i, data: TowerData) -> bool:
	return data != null and not is_over and map.is_cell_buildable(cell) and gold >= data.cost


## Place une tour sur la case si c'est possible. Renvoie la tour, ou null.
func place_tower(cell: Vector2i, data: TowerData) -> Tower:
	if not can_place_tower(cell, data):
		return null
	var tower: Tower = data.scene.instantiate()
	tower.data = data
	tower.projectile_container = projectiles
	towers.add_child(tower)
	tower.global_position = map.cell_to_world(cell)
	map.occupy(cell, tower)
	gold -= data.cost
	return tower


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
	hud.show_end_screen(victory, victory and has_next_level())
	game_over.emit(victory)
	get_tree().paused = true


# --- Navigation -------------------------------------------------------------

func _on_restart_requested() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_next_level_requested() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(next_level)


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
