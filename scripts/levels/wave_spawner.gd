class_name WaveSpawner
extends Node
## Fait apparaître les ennemis de chaque vague sur les chemins de la carte, selon les WaveData,
## changés par la difficulté du niveau (voir apply_difficulty()). Un groupe peut être
## d'élites (SpawnGroup.elite), et une vague peut avoir son boss (EnemyData.is_boss).
## Chaque ennemi marche un peu sur le côté du chemin, tiré au hasard, pour que les vagues
## ne forment pas une seule file. En mode infini, des vagues de plus en plus dures
## suivent celles du niveau, sans fin.

signal wave_started(wave_index: int)
signal wave_spawning_finished(wave_index: int)
signal enemy_spawned(enemy: Enemy)

const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
## Décalage maximal d'un ennemi sur le côté : son centre reste sur le chemin, son corps
## peut déborder un peu sur le bord (cette part de son rayon)…
const LATERAL_OVERHANG := 0.6
## … et sans aller tout à fait jusque-là.
const LATERAL_SPREAD := 0.9
## Mode infini : les vagues créées reprennent, en boucle, les dernières vagues du niveau…
const ENDLESS_CYCLE := 3
## … avec, à chaque vague de plus, cette part d'ennemis en plus…
const ENDLESS_COUNT_GROWTH := 0.1
## … une vie (et un bouclier) multipliée par ce facteur…
const ENDLESS_HEALTH_GROWTH := 1.13
## … et un bonus de vague augmenté de cette part.
const ENDLESS_BONUS_GROWTH := 0.1
## Écart minimal entre deux ennemis d'un groupe des vagues créées, en secondes.
const ENDLESS_MIN_INTERVAL := 0.2
## Porteurs (Enemy.carried) : un porteur de butin dans chaque vague à partir de la
## deuxième, et un porteur de coffre de plus toutes les CHEST_EVERY vagues (la 3e, la 6e…).
const LOOT_CARRIERS_FROM_WAVE := 1
const CHEST_EVERY := 3

@export var map: GameMap
## Nœud qui reçoit les ennemis créés.
@export var enemy_container: Node
@export var waves: Array[WaveData] = []

## Index de la vague en cours (-1 tant qu'aucune vague n'a commencé).
var current_wave := -1
var is_spawning := false
## Mode infini : après les vagues du niveau, il y en a toujours une suivante. À régler
## avant la première vague.
var endless := false
## Multiplicateur de la vitesse des ennemis (difficulté).
var speed_multiplier := 1.0
## Des porteurs de butin et de coffres arrivent dans les vagues (pas dans le tutoriel).
var carriers := true
## Butins (Loot.Kind) que peut porter un porteur de butin : de l'or, et en Conquête de la
## pierre et de l'essence.
var loot_kinds: Array[int] = [Loot.Kind.GOLD]

var _queue: Array[Dictionary] = []
var _elapsed := 0.0
## Vagues créées pour le mode infini, à la suite de `waves`.
var _endless_waves: Array[WaveData] = []
## Tirage du décalage des ennemis. La graine dépend du niveau : une partie rejouée de
## la même façon donne le même résultat (les tests d'équilibrage en dépendent).
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = hash(owner.scene_file_path if owner else name)


func has_next_wave() -> bool:
	return endless or current_wave + 1 < waves.size()


## Nombre de vagues du niveau (sans les vagues sans fin du mode infini).
func get_wave_count() -> int:
	return waves.size()


## Applique une difficulté (Difficulty) aux vagues du niveau : vie et bouclier, nombre
## d'ennemis de chaque groupe (le groupe dure à peu près aussi longtemps) et vitesse.
## À appeler avant la première vague. Les vagues de la scène ne sont pas modifiées :
## le spawner garde des copies.
func apply_difficulty(difficulty: int) -> void:
	apply_modifiers(Difficulty.HEALTH[difficulty], Difficulty.ENEMY_COUNT[difficulty], Difficulty.SPEED[difficulty])


## Change la vie (et le bouclier), le nombre et la vitesse des ennemis de toutes les
## vagues (difficulté, règles du défi du jour), comme apply_difficulty().
func apply_modifiers(health_multiplier: float, count_multiplier: float, enemy_speed_multiplier: float) -> void:
	speed_multiplier = enemy_speed_multiplier
	var scaled: Array[WaveData] = []
	for wave in waves:
		var copy := WaveData.new()
		copy.bonus_gold = wave.bonus_gold
		copy.health_multiplier = wave.health_multiplier * health_multiplier
		for group in wave.groups:
			copy.groups.append(_scale_group(group, count_multiplier))
		scaled.append(copy)
	waves = scaled
	_endless_waves.clear()


## Vague d'index donné : une de celles du niveau, ou au-delà, une vague du mode infini.
func get_wave(index: int) -> WaveData:
	if index < waves.size():
		return waves[index]
	while _endless_waves.size() <= index - waves.size():
		_endless_waves.append(_make_endless_wave(waves.size() + _endless_waves.size()))
	return _endless_waves[index - waves.size()]


func start_next_wave() -> void:
	if is_spawning or not has_next_wave():
		return
	current_wave += 1
	_elapsed = 0.0
	_queue.clear()
	var wave := get_wave(current_wave)
	for group in wave.groups:
		for i in group.count:
			_queue.append({"time": group.start_delay + i * group.interval, "group": group,
				"health": wave.health_multiplier * group.health_multiplier})
	_queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.time < b.time)
	if carriers:
		_pick_carriers(current_wave)
	is_spawning = true
	wave_started.emit(current_wave)


func _process(delta: float) -> void:
	if not is_spawning:
		return
	_elapsed += delta
	while not _queue.is_empty() and _queue[0].time <= _elapsed:
		var entry: Dictionary = _queue.pop_front()
		spawn(entry.group.get_enemy(), map.get_enemy_path(entry.group.path_index), 0.0,
			entry.health * (Enemy.CARRIER_HEALTH if entry.has("carried") else 1.0), 1.0, -1, null, entry.get("carried", -1))
	if _queue.is_empty():
		is_spawning = false
		wave_spawning_finished.emit(current_wave)


## Fait apparaître un ennemi sur un chemin, à la distance donnée du départ, un peu
## sur le côté. Sert aussi aux ennemis qui se divisent à leur mort.
## Un ennemi qui se relève (EnemyData.revive_count) n'a que `health_ratio` de sa vie, et
## `revives_left` résurrections restantes (-1 : celles de sa ressource). Niveau libre :
## `route` est le trajet propre de l'ennemi dont il sort.
func spawn(data: EnemyData, path: Path2D, progress := 0.0, health_multiplier := 1.0, health_ratio := 1.0,
		revives_left := -1, route: Curve2D = null, carried := -1) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = data
	enemy.path = path
	enemy.route = route
	enemy.progress = progress
	enemy.health_multiplier = health_multiplier
	enemy.health_ratio = health_ratio
	enemy.revives_left = revives_left
	enemy.speed_multiplier = speed_multiplier
	enemy.carried = carried
	var spread := get_max_lateral_offset(data)
	enemy.lateral_offset = _rng.randf_range(-spread, spread)
	enemy_container.add_child(enemy)
	enemy_spawned.emit(enemy)
	return enemy


## Choisit les porteurs de la vague parmi les ennemis à venir (pas les boss), vers le
## milieu de la vague. Le tirage dépend du niveau et de la vague, pas du reste de la
## partie : une vague rejouée a les mêmes porteurs.
func _pick_carriers(wave_index: int) -> void:
	if wave_index < LOOT_CARRIERS_FROM_WAVE:
		return
	var candidates: Array[int] = []
	for i in _queue.size():
		if not _queue[i].group.enemy.is_boss:
			candidates.append(i)
	if candidates.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([owner.scene_file_path if owner else name, wave_index])
	var picks: Array[int] = [loot_kinds[rng.randi() % loot_kinds.size()]]
	if (wave_index + 1) % CHEST_EVERY == 0:
		picks.append(Loot.Kind.CHEST)
	# Au milieu de la vague : ni le premier arrivé, ni le dernier.
	var from := candidates.size() / 4
	var to := maxi(candidates.size() * 3 / 4, from + 1)
	for kind in picks:
		var index := candidates[rng.randi_range(from, to - 1)]
		if _queue[index].has("carried"):
			# Déjà porteur : on prend le suivant libre.
			for candidate in candidates:
				if not _queue[candidate].has("carried"):
					index = candidate
					break
		if not _queue[index].has("carried"):
			_queue[index].carried = kind


## Décalage maximal sur le côté du chemin pour un ennemi, en pixels.
func get_max_lateral_offset(data: EnemyData) -> float:
	return maxf(map.path_width / 2.0 - data.radius * (1.0 - LATERAL_OVERHANG), 0.0) * LATERAL_SPREAD


## Vague du mode infini d'index donné (après les vagues du niveau) : une des dernières
## vagues du niveau, avec plus d'ennemis, plus résistants, à chaque vague.
func _make_endless_wave(index: int) -> WaveData:
	var extra := index - waves.size() + 1
	var cycle := mini(ENDLESS_CYCLE, waves.size())
	var base := waves[waves.size() - cycle + (extra - 1) % cycle]
	var wave := WaveData.new()
	wave.bonus_gold = roundi(base.bonus_gold * (1.0 + ENDLESS_BONUS_GROWTH * extra))
	wave.health_multiplier = base.health_multiplier * pow(ENDLESS_HEALTH_GROWTH, extra)
	for group in base.groups:
		wave.groups.append(_scale_group(group, 1.0 + ENDLESS_COUNT_GROWTH * extra))
	return wave


## Copie d'un groupe avec plus (ou moins) d'ennemis, au moins un. Le groupe dure à peu
## près aussi longtemps : les ennemis en plus se resserrent, ceux en moins s'espacent.
## Un groupe de boss garde son nombre : la difficulté ne change que leur vie.
func _scale_group(group: SpawnGroup, count_multiplier: float) -> SpawnGroup:
	var copy: SpawnGroup = group.duplicate()
	if group.enemy.is_boss:
		return copy
	copy.count = ceili(group.count * count_multiplier) if count_multiplier > 1.0 \
		else maxi(roundi(group.count * count_multiplier), 1)
	copy.interval = maxf(group.interval * group.count / copy.count, minf(group.interval, ENDLESS_MIN_INTERVAL))
	return copy
