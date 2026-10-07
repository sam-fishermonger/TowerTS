class_name CoilTower
extends PulseTower
## Bobine : elle ne tire pas, elle renforce les tours à sa portée (dégâts et cadence,
## voir Level.refresh_boosts). Plusieurs Bobines ne s'additionnent pas : une tour garde
## le bonus de la plus forte. Avec un croisement qui lui donne des effets (ralentir,
## bloquer les soins), elle envoie aussi une onde sans dégâts sur les ennemis à portée.

## Les arcs vers les tours renforcées changent de forme à ce rythme, en secondes.
const FLICKER := 0.12

## Tours renforcées par cette Bobine (tenu à jour par le niveau).
var boosted_towers: Array[Tower] = []

var _flicker_left := 0.0


func _process(delta: float) -> void:
	super(delta)
	_flicker_left -= delta
	if _flicker_left <= 0.0:
		_flicker_left = FLICKER
		queue_redraw()


## L'onde ne sert qu'avec un effet à appliquer aux ennemis.
func has_pulse_effects() -> bool:
	return stats.damage > 0.0 or stats.slow_factor < 1.0 or stats.heal_block_duration > 0.0


func find_target() -> Enemy:
	return super() if has_pulse_effects() else null


## Une Bobine ne renforce pas une autre Bobine.
func can_boost(tower: Tower) -> bool:
	return tower != self and tower.is_alive and not tower.data.is_support() \
		and global_position.distance_to(tower.global_position) <= stats.attack_range


func _draw_shape() -> void:
	draw_circle(Vector2.ZERO, SIZE * 0.3, data.color.darkened(0.3))
	for i in 3:
		draw_arc(Vector2.ZERO, SIZE * (0.12 + 0.07 * i), 0.0, TAU, 20, data.color.lightened(0.3), 2.0)


func _draw_effects() -> void:
	super()
	var rng := RandomNumberGenerator.new()
	rng.seed = Engine.get_process_frames() / 7
	for tower in boosted_towers:
		if not is_instance_valid(tower) or not tower.is_alive:
			continue
		var to := effect_point(to_local(tower.global_position), -tower.get_muzzle_offset().y)
		var from := to.normalized() * SIZE * 0.35
		to -= to.normalized() * SIZE * 0.35
		var normal := from.direction_to(to).orthogonal()
		var points := PackedVector2Array([from])
		for step in range(1, 4):
			points.append(from.lerp(to, step / 4.0) + normal * rng.randf_range(-5.0, 5.0))
		points.append(to)
		draw_polyline(points, Color(data.color.lightened(0.3), 0.55), 2.0)
