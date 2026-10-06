class_name TitleDemo
extends SubViewportContainer
## Partie qui se joue toute seule derrière l'écran titre : un niveau de la campagne
## tiré au hasard, des tours posées et améliorées automatiquement, des vagues lancées
## dès que la carte se vide. À la fin de la partie, un autre niveau prend la suite en
## fondu. La caméra glisse lentement sur la carte. Pas de sons ni de commandes, et
## rien n'est enregistré (voir Level.is_demo).

## Émis à chaque nouveau niveau simulé.
signal level_started(level: Level)

const CAMPAIGN: Campaign = preload("res://resources/campaign.tres")
const NO_CELL := Vector2i(-1, -1)
## Délai entre deux décisions (achat, amélioration), en secondes de jeu.
const THINK_INTERVAL := 0.5
## Attente avant la première vague, pour laisser le temps de poser les premières tours.
const FIRST_WAVE_DELAY := 2.5
## Attente entre une carte vidée et la vague suivante.
const WAVE_PAUSE := 1.5
## Attente entre la fin de partie et le fondu vers le niveau suivant.
const END_DELAY := 2.5
const FADE_DURATION := 0.8
## Zoom de la caméra : la carte (sous la barre du haut) remplit tout l'écran.
const CAMERA_ZOOM := 1.25
## Vitesse du va-et-vient de la caméra, en radians par seconde.
const CAMERA_DRIFT_SPEED := 0.15
## Les améliorations ne sont envisagées qu'à partir de ce nombre de tours posées.
const MIN_TOWERS_BEFORE_UPGRADES := 4
const UPGRADE_CHANCE := 0.35
## La démo commence avec plus d'or qu'une vraie partie, pour que la carte se
## remplisse vite de tours.
const STARTING_GOLD_MULTIPLIER := 3
## Écart entre deux points du chemin pris en compte pour placer les tours, en pixels.
const PATH_SAMPLE_SPACING := 24.0

## Niveau en cours de simulation.
var level: Level

var _viewport := SubViewport.new()
var _camera := Camera2D.new()
var _rng := RandomNumberGenerator.new()
var _level_path := ""
var _time := 0.0
var _think_timer := 0.0
var _wave_timer := 0.0
var _end_timer := 0.0
## Prochain achat prévu : une tour à poser, ou une tour posée à améliorer.
var _planned_tower: TowerData
var _planned_upgrade: Tower
## Points des chemins ennemis, pour choisir les cases qui en couvrent le plus.
var _path_points := PackedVector2Array()


func _init() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport.gui_disable_input = true
	_viewport.audio_listener_enable_2d = false
	_camera.zoom = Vector2.ONE * CAMERA_ZOOM
	_viewport.add_child(_camera)
	add_child(_viewport)


func _enter_tree() -> void:
	Sound.effects_muted = true


func _exit_tree() -> void:
	Sound.effects_muted = false


func _ready() -> void:
	_rng.randomize()
	start_level(_pick_level())


## Lance la simulation du niveau donné, à la place du précédent.
func start_level(path: String) -> void:
	if level:
		level.queue_free()
		_viewport.remove_child(level)
	_level_path = path
	level = (load(path) as PackedScene).instantiate()
	level.is_demo = true
	level.starting_gold *= STARTING_GOLD_MULTIPLIER
	_viewport.add_child(level)
	_think_timer = 0.0
	_wave_timer = 0.0
	_end_timer = 0.0
	_planned_tower = null
	_planned_upgrade = null
	_path_points = _sample_paths(level.map)
	level_started.emit(level)


func _process(delta: float) -> void:
	_time += delta
	_move_camera()
	if level == null:
		return
	if level.is_over:
		_end_timer += delta
		if _end_timer >= END_DELAY and _end_timer - delta < END_DELAY:
			_fade_to_next_level()
		return
	_think_timer += delta
	if _think_timer >= THINK_INTERVAL:
		_think_timer = 0.0
		_think()
	_launch_waves(delta)


## La caméra va et vient le long de la carte (la partie visible fait 1280 / zoom de large).
func _move_camera() -> void:
	var screen := _viewport.get_visible_rect().size
	var visible_size := screen / CAMERA_ZOOM
	var drift := (screen.x - visible_size.x) / 2.0
	var map_top := level.map.grid_origin.y if level else 0.0
	_camera.position = Vector2(screen.x / 2.0 + sin(_time * CAMERA_DRIFT_SPEED) * drift,
		map_top + visible_size.y / 2.0)


func _fade_to_next_level() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(func() -> void: start_level(_pick_level()))
	tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)


## Un niveau de la campagne au hasard, différent du précédent.
func _pick_level() -> String:
	var levels := CAMPAIGN.levels
	levels.erase(_level_path)
	return levels[_rng.randi() % levels.size()]


# --- Joueur automatique -------------------------------------------------------

## Décide d'un achat (poser une tour ou en améliorer une), puis l'effectue dès que
## l'or le permet.
func _think() -> void:
	# Une tour vendue ou déjà au niveau maximum n'est plus à améliorer.
	if not is_instance_valid(_planned_upgrade) or not _planned_upgrade.is_alive \
			or not _planned_upgrade.can_upgrade():
		_planned_upgrade = null
	if _planned_tower == null and _planned_upgrade == null:
		_plan_next_purchase()
	if _planned_upgrade:
		if level.upgrade_tower(_planned_upgrade):
			_planned_upgrade = null
	elif _planned_tower and level.gold >= _planned_tower.get_cost():
		var cell := _best_cell(_planned_tower)
		if cell != NO_CELL:
			level.place_tower(cell, _planned_tower)
		_planned_tower = null


func _plan_next_purchase() -> void:
	var placed: Array[Tower] = []
	var upgradable: Array[Tower] = []
	for tower: Tower in level.towers.get_children():
		if tower.is_alive:
			placed.append(tower)
			if tower.can_upgrade():
				upgradable.append(tower)
	if placed.size() >= MIN_TOWERS_BEFORE_UPGRADES and not upgradable.is_empty() \
			and _rng.randf() < UPGRADE_CHANCE:
		_planned_upgrade = upgradable[_rng.randi() % upgradable.size()]
	elif not level.tower_types.is_empty():
		_planned_tower = level.tower_types[_rng.randi() % level.tower_types.size()]


## Case libre d'où la tour couvre le plus de chemin (un peu de hasard pour varier
## les parties), ou NO_CELL si aucune ne touche le chemin.
func _best_cell(data: TowerData) -> Vector2i:
	var map := level.map
	var range_squared := data.attack_range * data.attack_range
	var best := NO_CELL
	var best_score := 0.0
	for x in map.columns:
		for y in map.rows:
			var cell := Vector2i(x, y)
			if not map.is_cell_buildable(cell):
				continue
			var center := map.cell_to_world(cell)
			var covered := 0
			for point in _path_points:
				if center.distance_squared_to(point) <= range_squared:
					covered += 1
			var score := covered * _rng.randf_range(0.75, 1.0)
			if score > best_score:
				best_score = score
				best = cell
	return best


## Lance la première vague après un court délai, puis chaque vague une fois la carte vidée.
func _launch_waves(delta: float) -> void:
	if not level.can_start_next_wave():
		_wave_timer = 0.0
		return
	var first_wave := level.spawner.current_wave < 0
	if not first_wave and not get_tree().get_nodes_in_group(Enemy.GROUP).is_empty():
		_wave_timer = 0.0
		return
	_wave_timer += delta
	if _wave_timer >= (FIRST_WAVE_DELAY if first_wave else WAVE_PAUSE):
		level.start_next_wave()


static func _sample_paths(map: GameMap) -> PackedVector2Array:
	var points := PackedVector2Array()
	for path in map.paths:
		var length := path.curve.get_baked_length()
		var offset := 0.0
		while offset <= length:
			points.append(path.to_global(path.curve.sample_baked(offset)))
			offset += PATH_SAMPLE_SPACING
	return points
