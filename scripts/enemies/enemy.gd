class_name Enemy
extends Entity
## Ennemi qui avance le long d'un chemin (Path2D) jusqu'à la base du joueur.

signal died(enemy: Enemy)
## Émis à chaque coup reçu, avec les dégâts réellement subis (après armure).
signal damaged(enemy: Enemy, amount: float)
signal reached_end(enemy: Enemy)
## Émis quand un soigneur rend des points de vie à cet ennemi.
signal healed(enemy: Enemy, amount: float)

const GROUP := "enemies"
const SHIELD_COLOR := Color(0.4, 0.85, 1.0)
const HEAL_COLOR := Color(0.45, 1.0, 0.55)
## Durée de l'onde verte dessinée autour d'un soigneur quand il soigne.
const HEAL_PULSE_DURATION := 0.5
## Une brûlure ou un poison frappe à ce rythme, en secondes.
const DOT_TICK := 0.5
const HEAL_BLOCK_COLOR := Color(0.9, 0.25, 0.3)
const JAMMED_SHIELD_COLOR := Color(0.6, 0.6, 0.7)
## Distance, avant et après l'ennemi sur le chemin, qui donne le sens de la marche pour
## son décalage sur le côté : les virages sont arrondis au lieu de faire un saut.
const TURN_SMOOTHING := 16.0

@export var data: EnemyData

## Chemin suivi. À définir avant d'ajouter l'ennemi à l'arbre.
var path: Path2D
## Distance parcourue sur le chemin, en pixels.
var progress := 0.0
## Décalage sur le côté du chemin, en pixels (positif : à droite de la marche). Le
## WaveSpawner le tire au hasard, pour que les ennemis ne marchent pas tous en file.
var lateral_offset := 0.0
## Multiplicateur de la vie et du bouclier (vagues du mode infini). À définir avant
## d'ajouter l'ennemi à l'arbre.
var health_multiplier := 1.0

var _path_length := 0.0
var _slow_factor := 1.0
var _slow_time_left := 0.0
## Direction de la marche (angle), pour orienter l'image.
var _heading := 0.0
var _heal_cooldown := 0.0
var _heal_pulse_left := 0.0
## Brûlure ou poison en cours : dégâts par seconde, temps restant, couleur.
var _dot_damage := 0.0
var _dot_left := 0.0
var _dot_tick_left := 0.0
var _dot_color := Color.ORANGE
## Secondes pendant lesquelles l'ennemi ne peut ni être soigné ni soigner.
var _heal_block_left := 0.0

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
	health.setup(data.max_health * health_multiplier, data.armor, data.max_shield * health_multiplier,
		data.shield_regen)
	health.depleted.connect(_on_health_depleted)
	if data.max_shield > 0.0:
		health.shield_changed.connect(func(_shield: float, _max: float) -> void: queue_redraw())
	_heal_cooldown = data.heal_interval
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
	if _dot_left > 0.0:
		_update_dot(delta)
		if not is_alive:
			return
	if _heal_block_left > 0.0:
		_heal_block_left -= delta
		if _heal_block_left <= 0.0:
			queue_redraw()
	if data.heal_amount > 0.0:
		_update_healing(delta)
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
func take_damage(amount: float, ignore_armor := false, shield_multiplier := 1.0) -> float:
	if not is_alive:
		return 0.0
	var dealt := health.take_damage(amount, ignore_armor, shield_multiplier)
	if dealt > 0.0:
		damaged.emit(self, dealt)
	return dealt


## Coup porté par une tour : les dégâts donnés, puis les effets de ses statistiques
## (ralentissement, brûlure ou poison, bouclier brouillé, soins bloqués).
## Renvoie les dégâts réellement subis.
func hit(amount: float, stats: TowerData) -> float:
	if not is_alive:
		return 0.0
	if stats.shield_jam_duration > 0.0:
		health.jam_shield(stats.shield_jam_duration)
	if stats.heal_block_duration > 0.0:
		block_healing(stats.heal_block_duration)
	var dealt := take_damage(amount, stats.armor_piercing, stats.shield_damage_multiplier)
	apply_slow(stats.slow_factor, stats.slow_duration)
	apply_dot(stats.dot_damage, stats.dot_duration, stats.color)
	return dealt


## Ralentit l'ennemi. Le ralentissement le plus fort et la durée la plus longue l'emportent.
func apply_slow(factor: float, duration: float) -> void:
	if not is_alive or factor >= 1.0 or duration <= 0.0:
		return
	_slow_factor = minf(_slow_factor, factor) if is_slowed() else factor
	_slow_time_left = maxf(_slow_time_left, duration)
	queue_redraw()


## Brûlure ou poison : `damage_per_second` pendant `duration`, en ignorant l'armure.
## Le plus fort et le plus long l'emportent, comme pour le ralentissement.
func apply_dot(damage_per_second: float, duration: float, color := Color.ORANGE) -> void:
	if not is_alive or damage_per_second <= 0.0 or duration <= 0.0:
		return
	if _dot_left <= 0.0:
		_dot_damage = damage_per_second
		_dot_tick_left = DOT_TICK
	else:
		_dot_damage = maxf(_dot_damage, damage_per_second)
	_dot_left = maxf(_dot_left, duration)
	_dot_color = color
	queue_redraw()


func is_burning() -> bool:
	return _dot_left > 0.0


func _update_dot(delta: float) -> void:
	_dot_left -= delta
	_dot_tick_left -= delta
	if _dot_tick_left <= 0.0:
		_dot_tick_left += DOT_TICK
		take_damage(_dot_damage * DOT_TICK, true)
	if _dot_left <= 0.0:
		_dot_damage = 0.0
		queue_redraw()


## Empêche l'ennemi d'être soigné, et de soigner s'il est soigneur, pendant la durée donnée.
func block_healing(duration: float) -> void:
	if not is_alive or duration <= 0.0:
		return
	if _heal_block_left <= 0.0:
		queue_redraw()
	_heal_block_left = maxf(_heal_block_left, duration)


func can_be_healed() -> bool:
	return _heal_block_left <= 0.0


## Soigneur : soigne régulièrement les autres ennemis blessés à sa portée.
func _update_healing(delta: float) -> void:
	if _heal_pulse_left > 0.0:
		_heal_pulse_left -= delta
		queue_redraw()
	_heal_cooldown -= delta
	# Un soigneur touché par une tour qui bloque les soins ne soigne plus.
	if _heal_cooldown > 0.0 or not can_be_healed():
		return
	var patients: Array[Enemy] = []
	for enemy in get_alive_in_radius(get_tree(), global_position, data.heal_radius):
		if enemy != self and enemy.can_be_healed() and enemy.health.health < enemy.health.max_health:
			patients.append(enemy)
	# Personne à soigner : il réessaie à l'image suivante, sans attendre.
	if patients.is_empty():
		return
	_heal_cooldown = data.heal_interval
	_heal_pulse_left = HEAL_PULSE_DURATION
	for enemy in patients:
		var amount := enemy.health.heal(data.heal_amount)
		if amount > 0.0:
			enemy.healed.emit(enemy, amount)


func _update_position() -> void:
	var point := path.curve.sample_baked(progress)
	var offset := Vector2.ZERO
	if lateral_offset != 0.0:
		var behind := path.curve.sample_baked(maxf(progress - TURN_SMOOTHING, 0.0))
		var further := path.curve.sample_baked(minf(progress + TURN_SMOOTHING, _path_length))
		offset = (further - behind).normalized().orthogonal() * lateral_offset
	global_position = path.to_global(point + offset)
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
	if _heal_pulse_left > 0.0:
		var t := 1.0 - _heal_pulse_left / HEAL_PULSE_DURATION
		draw_arc(Vector2.ZERO, lerpf(data.radius, data.heal_radius, t), 0.0, TAU, 48,
			Color(HEAL_COLOR, 0.6 * (1.0 - t)), 3.0)
	if data.max_shield > 0.0 and health.shield > 0.0:
		var ratio := health.shield / data.max_shield
		var shield_color := JAMMED_SHIELD_COLOR if health.is_shield_jammed() else SHIELD_COLOR
		draw_circle(Vector2.ZERO, data.radius * 1.45, Color(shield_color, 0.12 + 0.12 * ratio))
		draw_arc(Vector2.ZERO, data.radius * 1.45, 0.0, TAU, 32, Color(shield_color, 0.35 + 0.45 * ratio), 2.0)
	if is_burning():
		# Halo de la couleur de la tour qui brûle ou empoisonne.
		draw_circle(Vector2.ZERO, data.radius * 1.2, Color(_dot_color, 0.3))
	if not can_be_healed():
		# Croix barrée rouge : plus de soins.
		var center := Vector2(data.radius * 0.9, -data.radius * 0.9)
		draw_circle(center, 5.5, HEAL_BLOCK_COLOR)
		draw_line(center + Vector2(-3, 0), center + Vector2(3, 0), Color.WHITE, 2.0)
		draw_line(center + Vector2(0, -3), center + Vector2(0, 3), Color.WHITE, 2.0)
		draw_line(center + Vector2(-4, 4), center + Vector2(4, -4), Color(0.2, 0, 0), 1.5)
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
