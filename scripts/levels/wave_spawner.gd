class_name WaveSpawner
extends Node
## Fait apparaître les ennemis de chaque vague sur les chemins de la carte, selon les WaveData.

signal wave_started(wave_index: int)
signal wave_spawning_finished(wave_index: int)
signal enemy_spawned(enemy: Enemy)

const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")

@export var map: GameMap
## Nœud qui reçoit les ennemis créés.
@export var enemy_container: Node
@export var waves: Array[WaveData] = []

## Index de la vague en cours (-1 tant qu'aucune vague n'a commencé).
var current_wave := -1
var is_spawning := false

var _queue: Array[Dictionary] = []
var _elapsed := 0.0


func has_next_wave() -> bool:
	return current_wave + 1 < waves.size()


func start_next_wave() -> void:
	if is_spawning or not has_next_wave():
		return
	current_wave += 1
	_elapsed = 0.0
	_queue.clear()
	for group in waves[current_wave].groups:
		for i in group.count:
			_queue.append({"time": group.start_delay + i * group.interval, "group": group})
	_queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.time < b.time)
	is_spawning = true
	wave_started.emit(current_wave)


func _process(delta: float) -> void:
	if not is_spawning:
		return
	_elapsed += delta
	while not _queue.is_empty() and _queue[0].time <= _elapsed:
		_spawn(_queue.pop_front().group)
	if _queue.is_empty():
		is_spawning = false
		wave_spawning_finished.emit(current_wave)


func _spawn(group: SpawnGroup) -> void:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = group.enemy
	enemy.path = map.get_enemy_path(group.path_index)
	enemy_container.add_child(enemy)
	enemy_spawned.emit(enemy)
