class_name Enemy
extends Entity
## Ennemi qui avance le long d'un chemin (Path2D) jusqu'à la base du joueur.

signal died(enemy: Enemy)
## Émis à chaque coup reçu, avec les dégâts réellement subis (après armure).
signal damaged(enemy: Enemy, amount: float)
signal reached_end(enemy: Enemy)

const GROUP := "enemies"

@export var data: EnemyData

## Chemin suivi. À définir avant d'ajouter l'ennemi à l'arbre.
var path: Path2D
## Distance parcourue sur le chemin, en pixels.
var progress := 0.0

var _path_length := 0.0
var _slow_factor := 1.0
var _slow_time_left := 0.0
## Direction de la marche (angle), pour orienter l'image.
var _heading := 0.0

@onready var health: HealthComponent = $Health
@onready var health_bar: HealthBar = $HealthBar


## Ennemis encore en jeu dans un rayon donné autour d'un point.
static func get_alive_in_radius(tree: SceneTree, center: Vector2, radius: float) -> Array[Enemy]:
	var result: Array[Enemy] = []
	for node in tree.get_nodes_in_group(GROUP):
		var enemy := node as Enemy
		if enemy and enemy.is_alive and center.distance_to(enemy.global_position) <= radius:
			result.append(enemy)
	return result


func _ready() -> void:
	add_to_group(GROUP)
	health.setup(data.max_health, data.armor)
	health.depleted.connect(_on_health_depleted)
	health_bar.width = data.radius * 2.0
	health_bar.position = Vector2(0, -data.radius - 8.0)
	_path_length = path.curve.get_baked_length()
	_update_position()


func _process(delta: float) -> void:
	if _slow_time_left > 0.0:
		_slow_time_left -= delta
		if _slow_time_left <= 0.0:
			_slow_factor = 1.0
			queue_redraw()
	progress += get_speed() * delta
	if progress >= _path_length:
		despawn()
		reached_end.emit(self)
		return
	_update_position()


func get_speed() -> float:
	return data.speed * _slow_factor


func is_slowed() -> bool:
	return _slow_time_left > 0.0


## Distance restant à parcourir avant la base : plus elle est petite, plus
## l'ennemi est dangereux.
func distance_to_end() -> float:
	return _path_length - progress


## Applique un coup et renvoie les dégâts réellement subis.
func take_damage(amount: float) -> float:
	if not is_alive:
		return 0.0
	var dealt := health.take_damage(amount)
	if dealt > 0.0:
		damaged.emit(self, dealt)
	return dealt


## Ralentit l'ennemi. Le ralentissement le plus fort et la durée la plus longue l'emportent.
func apply_slow(factor: float, duration: float) -> void:
	if not is_alive or factor >= 1.0 or duration <= 0.0:
		return
	_slow_factor = minf(_slow_factor, factor) if is_slowed() else factor
	_slow_time_left = maxf(_slow_time_left, duration)
	queue_redraw()


func _update_position() -> void:
	var point := path.curve.sample_baked(progress)
	global_position = path.to_global(point)
	var ahead := path.curve.sample_baked(minf(progress + 4.0, _path_length))
	if not ahead.is_equal_approx(point):
		var heading := point.angle_to_point(ahead)
		if not is_equal_approx(heading, _heading):
			_heading = heading
			queue_redraw()


func _on_health_depleted() -> void:
	despawn()
	died.emit(self)


func _draw() -> void:
	if data.texture:
		# L'image déborde un peu du rayon de collision (ombre, pattes).
		var size := data.radius * 2.6 * data.sprite_scale
		draw_set_transform(Vector2.ZERO, _heading)
		draw_texture_rect(data.texture, Rect2(-size / 2.0, -size / 2.0, size, size), false,
			Color(0.6, 0.8, 1.0) if is_slowed() else Color.WHITE)
		draw_set_transform(Vector2.ZERO)
		return
	var color := data.color.lerp(Color(0.55, 0.8, 1.0), 0.5) if is_slowed() else data.color
	draw_circle(Vector2.ZERO, data.radius, color)
	var outline_width := 4.0 if data.armor > 0.0 else 2.0
	draw_arc(Vector2.ZERO, data.radius, 0.0, TAU, 24, color.darkened(0.5), outline_width)
	# Un ennemi qui se divise laisse voir ceux qu'il contient.
	if data.split_into:
		for i in data.split_count:
			var offset := Vector2.from_angle(TAU * i / data.split_count - PI / 2.0) * data.radius * 0.45
			draw_circle(offset, data.radius * 0.28, data.split_into.color.darkened(0.15))
