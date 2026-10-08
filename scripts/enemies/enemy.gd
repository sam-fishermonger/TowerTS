class_name Enemy
extends Entity
## Ennemi qui avance le long d'un chemin (Path2D) jusqu'à la base du joueur.

signal died(enemy: Enemy)
## Émis à chaque coup reçu, avec les dégâts réellement subis (après armure).
signal damaged(enemy: Enemy, amount: float)
signal reached_end(enemy: Enemy)
## Émis quand un soigneur rend des points de vie à cet ennemi.
signal healed(enemy: Enemy, amount: float)
## Émis quand l'ennemi appelle des renforts (EnemyData.summon_enemy) : le niveau les
## fait apparaître derrière lui.
signal summoned(enemy: Enemy)

const GROUP := "enemies"
const SHIELD_COLOR := Color(0.4, 0.85, 1.0)
const HEAL_COLOR := Color(0.45, 1.0, 0.55)
## Durée de l'onde verte dessinée autour d'un soigneur quand il soigne.
const HEAL_PULSE_DURATION := 0.5
## Soigneur qui n'a trouvé personne à soigner : secondes avant de chercher de nouveau.
const HEAL_RETRY := 0.1
## Une brûlure ou un poison frappe à ce rythme, en secondes.
const DOT_TICK := 0.5
const HEAL_BLOCK_COLOR := Color(0.9, 0.25, 0.3)
## Marque d'un ennemi consacré, qui ne peut plus se relever.
const CONSECRATED_COLOR := Color(1.0, 0.9, 0.55)
const JAMMED_SHIELD_COLOR := Color(0.6, 0.6, 0.7)
## Distance, avant et après l'ennemi sur le chemin, qui donne le sens de la marche pour
## son décalage sur le côté : les virages sont arrondis au lieu de faire un saut.
const TURN_SMOOTHING := 16.0
## Recul (Électroaimant) : un ennemi de ce rayon ou moins recule de toute la distance,
## un plus gros d'autant moins qu'il est gros (au moins KNOCKBACK_MIN_RATIO).
const KNOCKBACK_FULL_RADIUS := 13.0
const KNOCKBACK_MIN_RATIO := 0.35
## Secondes après un recul pendant lesquelles l'ennemi ne peut plus reculer : plusieurs
## Électroaimants ne peuvent pas le bloquer sur place.
const KNOCKBACK_COOLDOWN := 1.5
const FROZEN_COLOR := Color(0.7, 0.92, 1.0)
## Volants : décalage de l'ombre portée au sol, et transparence d'un furtif caché.
const FLYING_SHADOW_OFFSET := Vector2(7.0, 12.0)
const HIDDEN_ALPHA := 0.3
## Furtif caché dessiné d'une seule image (Creature.get_sheet()) : ses formes ne se
## superposent plus en s'opacifiant, il lui faut un peu plus d'opacité pour être aussi visible.
const HIDDEN_SPRITE_ALPHA := 0.45
## Groupe des tours qui détectent les furtifs (Tower.DETECTOR_GROUP).
const DETECTOR_GROUP := "stealth_detectors"
const FLIGHT_CURVE_META := &"flight_curve"
## Lissages du trajet des volants (voir get_flight_curve()).
const FLIGHT_SMOOTHING_PASSES := 3
## Pillards : secondes au plus loin du chemin, puis avant de repartir piller, et entre
## deux recherches de cible.
const RAID_MAX_TIME := 8.0
const RAID_COOLDOWN := 3.0
const RAID_SEARCH_INTERVAL := 0.5
const RAID_COLOR := Color(1.0, 0.55, 0.2)
## Porteurs (voir `carried`) : vie multipliée, et taille du butin dessiné au-dessus d'eux.
const CARRIER_HEALTH := 1.5
const CARRIER_COLOR := Color(1.0, 0.82, 0.25)
const CARRIED_SIZE := 0.85

## Pillard : sur le chemin, en route vers sa cible, ou de retour vers le chemin.
enum RaidState { NONE, GOING, RETURNING }

@export var data: EnemyData

## Chemin suivi. À définir avant d'ajouter l'ennemi à l'arbre.
var path: Path2D
## Niveau libre : trajet propre (dans le repère du chemin) à suivre au lieu de la courbe
## du chemin, à définir avant l'ajout (ou set_route()).
var route: Curve2D
## Distance parcourue sur le chemin, en pixels.
var progress := 0.0
## Décalage sur le côté du chemin, en pixels (positif : à droite de la marche). Le
## WaveSpawner le tire au hasard, pour que les ennemis ne marchent pas tous en file.
var lateral_offset := 0.0
## Multiplicateur de la vie et du bouclier (vagues du mode infini). À définir avant
## d'ajouter l'ennemi à l'arbre.
var health_multiplier := 1.0
## Multiplicateur de la vitesse (difficulté du niveau).
var speed_multiplier := 1.0
## Fois où l'ennemi peut encore se relever (-1 : celles de sa ressource, lues à l'ajout).
var revives_left := -1
## Part de sa vie avec laquelle il apparaît (moins de 1 pour un ennemi qui se relève).
var health_ratio := 1.0
## Porteur : butin (Loot.Kind) qu'il porte sur le dos et lâche à sa mort, -1 sinon. Le
## WaveSpawner en choisit quelques-uns par vague, plus résistants (CARRIER_HEALTH) ; un
## porteur qui atteint la base emporte son butin.
var carried := -1

## Trajet suivi : la courbe du chemin, ou celle du vol pour un volant.
var _curve: Curve2D
var _path_length := 0.0
var _slow_factor := 1.0
var _slow_time_left := 0.0
## Direction de la marche (angle), pour orienter l'image.
var _heading := 0.0
var _heal_cooldown := 0.0
var _summon_cooldown := 0.0
## Temps écoulé, pour l'aura qui pulse autour des élites et des boss.
var _aura_time := 0.0
var _heal_pulse_left := 0.0
## Brûlure ou poison en cours : dégâts par seconde, temps restant, couleur.
var _dot_damage := 0.0
var _dot_left := 0.0
var _dot_tick_left := 0.0
var _dot_color := Color.ORANGE
## Secondes pendant lesquelles l'ennemi ne peut ni être soigné ni soigner.
var _heal_block_left := 0.0
var _knockback_cooldown := 0.0
## Tour qui porte le coup en cours (identifiant d'instance, 0 = aucune) : lue par le niveau
## quand l'ennemi émet `damaged` ou `died`, pour les statistiques de fin de niveau.
var damage_source_id := 0
## Tour qui a posé la brûlure ou le poison en cours.
var _dot_source_id := 0
## Gel (pouvoir) : secondes restantes, et part des dégâts subis en plus pendant ce temps.
var _frozen_left := 0.0
var _frozen_vulnerability := 0.0
## Soldat (renforts) qui retient l'ennemi : il ne marche plus tant que le soldat tient.
var holder: Node2D
## Secondes pendant lesquelles l'ennemi est consacré : il ne peut plus se relever.
var _consecrated_left := 0.0
## Furtif : vrai tant qu'il est à portée de détection d'une tour.
var _revealed := false
## Pillard : ouvrier ou bâtiment visé, état du pillage, point du chemin où revenir,
## secondes depuis le départ et avant la prochaine recherche.
var raid_target: Node2D
var _raid_state := RaidState.NONE
var _raid_return := Vector2.ZERO
var _raid_time := 0.0
var _raid_cooldown := 0.0

@onready var health: HealthComponent = $Health
@onready var health_bar: HealthBar = $HealthBar


## Ennemis encore en jeu dans un rayon donné autour d'un point. Avec les statistiques
## d'une tour (`stats`), seulement ceux qu'elle peut toucher : pas les volants si elle
## tire au sol.
static func get_alive_in_radius(tree: SceneTree, center: Vector2, radius: float,
		stats: TowerData = null) -> Array[Enemy]:
	var result: Array[Enemy] = []
	for node in tree.get_nodes_in_group(GROUP):
		var enemy := node as Enemy
		if enemy and enemy.is_alive and center.distance_to(enemy.global_position) <= radius \
				and (stats == null or enemy.can_be_hit_by(stats)):
			result.append(enemy)
	return result


## Trajet d'un volant sur un chemin (dans le repère du chemin) : il coupe les virages,
## en allant tout droit d'un virage sur deux, puis en arrondissant. Calculé une fois par
## chemin.
static func get_flight_curve(path: Path2D) -> Curve2D:
	if path.has_meta(FLIGHT_CURVE_META):
		return path.get_meta(FLIGHT_CURVE_META)
	var source := path.curve
	var points := PackedVector2Array([source.get_point_position(0)])
	for i in range(2, source.point_count - 1, 2):
		points.append(source.get_point_position(i))
	points.append(source.get_point_position(source.point_count - 1))
	# Chaikin : chaque coin est remplacé par deux points, au quart et aux trois quarts.
	for pass_index in FLIGHT_SMOOTHING_PASSES:
		var smoothed := PackedVector2Array([points[0]])
		for i in points.size() - 1:
			if i > 0:
				smoothed.append(points[i].lerp(points[i + 1], 0.25))
			if i < points.size() - 2:
				smoothed.append(points[i].lerp(points[i + 1], 0.75))
		smoothed.append(points[points.size() - 1])
		points = smoothed
	var curve := Curve2D.new()
	for point in points:
		curve.add_point(point)
	path.set_meta(FLIGHT_CURVE_META, curve)
	return curve


## La tour peut le toucher : un volant échappe aux tours qui tirent au sol.
func can_be_hit_by(stats: TowerData) -> bool:
	return stats.hits_air or not data.flying


## Visible des tours : pas furtif, ou à portée de détection d'une tour.
func is_revealed() -> bool:
	return not data.stealthy or _revealed


func _ready() -> void:
	add_to_group(GROUP)
	health.setup(data.max_health * health_multiplier, data.armor, data.max_shield * health_multiplier,
		data.shield_regen)
	if health_ratio < 1.0:
		health.health = health.max_health * health_ratio
		health.shield = health.max_shield * health_ratio
		health.health_changed.emit(health.health, health.max_health)
		health.shield_changed.emit(health.shield, health.max_shield)
	if revives_left < 0:
		revives_left = data.revive_count
	health.depleted.connect(_on_health_depleted)
	if data.max_shield > 0.0:
		health.shield_changed.connect(func(_shield: float, _max: float) -> void: queue_redraw())
	_heal_cooldown = data.heal_interval
	_summon_cooldown = data.summon_interval
	health_bar.width = data.radius * 2.0
	health_bar.position = Vector2(0, -data.radius - 8.0)
	if Relief.enabled:
		health_bar.position.y = -Creature.top_height(data) - 6.0
		if not Relief.headless and SpriteCache.enabled:
			material = SpriteCache.get_material()
	if data.flying:
		# Il vole au-dessus des tours et des autres monstres.
		z_index = 1
	if route:
		_curve = route
	else:
		_curve = get_flight_curve(path) if data.flying else path.curve
	_path_length = _curve.get_baked_length()
	if data.stealthy:
		modulate.a = _hidden_alpha()
		_update_detection()
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
	if _knockback_cooldown > 0.0:
		_knockback_cooldown -= delta
	if _consecrated_left > 0.0:
		_consecrated_left -= delta
		if _consecrated_left <= 0.0:
			queue_redraw()
	# Gelé : il ne marche plus, ne soigne plus et n'appelle plus de renforts.
	if _frozen_left > 0.0:
		_frozen_left -= delta
		if _frozen_left <= 0.0:
			_frozen_vulnerability = 0.0
			queue_redraw()
		return
	if _heal_block_left > 0.0:
		_heal_block_left -= delta
		if _heal_block_left <= 0.0:
			queue_redraw()
	if data.heal_amount > 0.0:
		_update_healing(delta)
	if data.summon_enemy and data.summon_count > 0:
		_summon_cooldown -= delta
		if _summon_cooldown <= 0.0:
			_summon_cooldown += data.summon_interval
			summoned.emit(self)
	if data.is_elite or data.is_boss:
		_aura_time += delta
		queue_redraw()
	if data.stealthy:
		_update_detection()
	if is_held():
		return
	if data.raider and _update_raid(delta):
		return
	progress += get_speed() * delta
	if progress >= _path_length:
		despawn()
		reached_end.emit(self)
		return
	_update_position()


func get_speed() -> float:
	return data.speed * speed_multiplier * _slow_factor


func is_slowed() -> bool:
	return _slow_time_left > 0.0


func is_frozen() -> bool:
	return _frozen_left > 0.0


## Retenu par un soldat encore debout.
func is_held() -> bool:
	return is_instance_valid(holder) and holder.is_alive


## Gel (pouvoir) : l'ennemi s'arrête pendant `duration` et subit `vulnerability` de
## dégâts en plus. Un boss ne gèle pas : il ralentit de moitié.
func freeze(duration: float, vulnerability := 0.0) -> void:
	if not is_alive or duration <= 0.0:
		return
	if data.is_boss:
		apply_slow(0.5, duration)
		return
	_frozen_left = maxf(_frozen_left, duration)
	_frozen_vulnerability = maxf(_frozen_vulnerability, vulnerability)
	queue_redraw()


## Niveau libre : nouveau trajet (le passage a changé), qui part de là où il est.
func set_route(curve: Curve2D) -> void:
	route = curve
	_curve = curve
	_path_length = curve.get_baked_length()
	progress = 0.0
	# Un Pillard parti piller reste où il est : il rejoindra le nouveau trajet à son retour.
	if not is_raiding():
		_update_position()


## Trajet suivi (courbe du chemin, du vol, ou trajet propre), dans le repère du chemin.
func get_route() -> Curve2D:
	return _curve


## Point du trajet où il en est, sans son décalage sur le côté (repère global).
func get_route_position() -> Vector2:
	return path.to_global(_curve.sample_baked(progress))


## Distance restant à parcourir avant la base : plus elle est petite, plus
## l'ennemi est dangereux.
func distance_to_end() -> float:
	return _path_length - progress


## Applique un coup et renvoie les dégâts réellement subis.
func take_damage(amount: float, ignore_armor := false, shield_multiplier := 1.0) -> float:
	if not is_alive:
		return 0.0
	if is_frozen():
		amount *= 1.0 + _frozen_vulnerability
	var dealt := health.take_damage(amount, ignore_armor, shield_multiplier)
	if dealt > 0.0:
		damaged.emit(self, dealt)
	return dealt


## Coup porté par une tour : les dégâts donnés, puis les effets de ses statistiques
## (ralentissement, brûlure ou poison, bouclier brouillé, soins bloqués). Rien si la
## tour ne peut pas le toucher (volant), et ses dégâts contre les volants comptent.
## Renvoie les dégâts réellement subis.
func hit(amount: float, stats: TowerData) -> float:
	if not is_alive or not can_be_hit_by(stats):
		return 0.0
	if data.flying:
		amount *= stats.air_damage_multiplier
	if stats.shield_jam_duration > 0.0:
		health.jam_shield(stats.shield_jam_duration)
	if stats.heal_block_duration > 0.0:
		block_healing(stats.heal_block_duration)
	damage_source_id = stats.source_tower_id
	if stats.revive_block_duration > 0.0:
		consecrate(stats.revive_block_duration)
	var dealt := take_damage(amount, stats.armor_piercing, stats.shield_damage_multiplier)
	damage_source_id = 0
	apply_slow(stats.slow_factor, stats.slow_duration)
	if apply_dot(stats.dot_damage, stats.dot_duration, stats.color):
		_dot_source_id = stats.source_tower_id
	if stats.knockback > 0.0:
		push_back(stats.knockback)
	return dealt


## Fait reculer l'ennemi sur son chemin (moins s'il est gros), sauf s'il vient déjà de
## reculer. Renvoie la distance reculée.
func push_back(distance: float) -> float:
	if not is_alive or _knockback_cooldown > 0.0 or distance <= 0.0:
		return 0.0
	var ratio := clampf(KNOCKBACK_FULL_RADIUS / data.radius, KNOCKBACK_MIN_RATIO, 1.0)
	var moved := minf(distance * ratio, progress)
	progress -= moved
	_knockback_cooldown = KNOCKBACK_COOLDOWN
	_update_position()
	return moved


## Ralentit l'ennemi. Le ralentissement le plus fort et la durée la plus longue l'emportent.
func apply_slow(factor: float, duration: float) -> void:
	if not is_alive or factor >= 1.0 or duration <= 0.0:
		return
	_slow_factor = minf(_slow_factor, factor) if is_slowed() else factor
	_slow_time_left = maxf(_slow_time_left, duration)
	queue_redraw()


## Brûlure ou poison : `damage_per_second` pendant `duration`, en ignorant l'armure.
## Le plus fort et le plus long l'emportent, comme pour le ralentissement.
## Renvoie true si l'effet a été posé.
func apply_dot(damage_per_second: float, duration: float, color := Color.ORANGE) -> bool:
	if not is_alive or damage_per_second <= 0.0 or duration <= 0.0:
		return false
	if _dot_left <= 0.0:
		_dot_damage = damage_per_second
		_dot_tick_left = DOT_TICK
	else:
		_dot_damage = maxf(_dot_damage, damage_per_second)
	_dot_left = maxf(_dot_left, duration)
	_dot_color = color
	queue_redraw()
	return true


func is_burning() -> bool:
	return _dot_left > 0.0


func _update_dot(delta: float) -> void:
	_dot_left -= delta
	_dot_tick_left -= delta
	if _dot_tick_left <= 0.0:
		_dot_tick_left += DOT_TICK
		damage_source_id = _dot_source_id
		take_damage(_dot_damage * DOT_TICK, true)
		damage_source_id = 0
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


## Consacre l'ennemi : il ne pourra pas se relever s'il meurt pendant la durée donnée.
func consecrate(duration: float) -> void:
	if not is_alive or duration <= 0.0:
		return
	if _consecrated_left <= 0.0:
		queue_redraw()
	_consecrated_left = maxf(_consecrated_left, duration)


func is_consecrated() -> bool:
	return _consecrated_left > 0.0


## L'ennemi se relèvera s'il meurt maintenant.
func can_revive() -> bool:
	return revives_left > 0 and not is_consecrated()


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
	# Personne à soigner : il regarde de nouveau un peu plus tard (chercher à chaque
	# image, parmi tous les monstres, coûte cher quand ils sont nombreux).
	if patients.is_empty():
		_heal_cooldown = HEAL_RETRY
		return
	_heal_cooldown = data.heal_interval
	_summon_cooldown = data.summon_interval
	_heal_pulse_left = HEAL_PULSE_DURATION
	for enemy in patients:
		var amount := enemy.health.heal(data.heal_amount)
		if amount > 0.0:
			enemy.healed.emit(enemy, amount)


func is_raiding() -> bool:
	return _raid_state != RaidState.NONE


## Pillard : cherche une cible à portée, va la frapper, puis revient sur le chemin là où
## il l'a quitté. Renvoie true tant qu'il est hors du chemin (il n'y avance pas).
func _update_raid(delta: float) -> bool:
	if _raid_state == RaidState.NONE:
		_raid_cooldown -= delta
		if _raid_cooldown > 0.0:
			return false
		raid_target = _find_raid_target()
		if raid_target == null:
			_raid_cooldown = RAID_SEARCH_INTERVAL
			return false
		_raid_state = RaidState.GOING
		_raid_return = global_position
		_raid_time = 0.0
	var step := get_speed() * delta
	if _raid_state == RaidState.GOING:
		_raid_time += delta
		if not is_instance_valid(raid_target) or not raid_target.can_be_raided() or _raid_time > RAID_MAX_TIME:
			_raid_state = RaidState.RETURNING
		elif global_position.distance_to(raid_target.global_position) > data.radius + 14.0:
			_move_toward(raid_target.global_position, step)
		else:
			raid_target.take_damage(data.raid_damage * delta)
	if _raid_state == RaidState.RETURNING and _move_toward(_raid_return, step):
		_raid_state = RaidState.NONE
		raid_target = null
		_raid_cooldown = RAID_COOLDOWN
		_update_position()
	return true


## L'ouvrier ou le bâtiment le plus proche à portée (null si aucun).
func _find_raid_target() -> Node2D:
	var best: Node2D = null
	var best_distance := data.raid_radius
	for node in get_tree().get_nodes_in_group(Conquest.RAID_TARGET_GROUP):
		var target := node as Node2D
		var distance := global_position.distance_to(target.global_position)
		if distance <= best_distance and target.can_be_raided():
			best = target
			best_distance = distance
	return best


## Marche tout droit vers un point. Renvoie true une fois arrivé.
func _move_toward(point: Vector2, step: float) -> bool:
	var offset := point - global_position
	if offset.length() <= step:
		global_position = point
		return true
	_set_heading(offset.angle())
	global_position += offset.normalized() * step
	return false


## Furtif : révélé tant qu'une tour qui détecte l'a à portée de détection.
func _update_detection() -> void:
	var revealed := false
	for node in get_tree().get_nodes_in_group(DETECTOR_GROUP):
		var tower := node as Tower
		if tower and tower.stats and global_position.distance_to(tower.global_position) <= tower.stats.detection_range:
			revealed = true
			break
	if revealed != _revealed:
		_revealed = revealed
		modulate.a = 1.0 if revealed else _hidden_alpha()
		queue_redraw()


func _hidden_alpha() -> float:
	return HIDDEN_SPRITE_ALPHA if material == SpriteCache.get_material() else HIDDEN_ALPHA


## Vue de trois quarts : distance parcourue entre deux dessins de la marche.
const ANIMATION_STEP := Creature.WALK_STEP
var _animation_step := -1


func _update_position() -> void:
	var point := _curve.sample_baked(progress)
	var offset := Vector2.ZERO
	if lateral_offset != 0.0:
		var behind := _curve.sample_baked(maxf(progress - TURN_SMOOTHING, 0.0))
		var further := _curve.sample_baked(minf(progress + TURN_SMOOTHING, _path_length))
		offset = (further - behind).normalized().orthogonal() * lateral_offset
	global_position = path.to_global(point + offset)
	var ahead := _curve.sample_baked(minf(progress + 4.0, _path_length))
	if not ahead.is_equal_approx(point):
		_set_heading(point.angle_to_point(ahead))
	if Relief.enabled and not Relief.headless:
		# Ses pattes bougent en marchant : un dessin tous les quelques pixels suffit (le
		# dessin en volume coûte cher, le déplacement, lui, ne demande pas de redessiner).
		var step := int(progress / ANIMATION_STEP)
		if step != _animation_step:
			_animation_step = step
			queue_redraw()


## Change la direction de la marche. Vue de dessus, l'image tourne avec elle ; en trois
## quarts, le monstre ne fait que regarder à gauche ou à droite : il ne se redessine que
## quand il se retourne (et pas à chaque virage).
func _set_heading(heading: float) -> void:
	if is_equal_approx(heading, _heading):
		return
	var turned := _is_facing_left(heading) != _is_facing_left(_heading)
	_heading = heading
	if turned or not Relief.enabled:
		queue_redraw()


static func _is_facing_left(heading: float) -> bool:
	return cos(heading) < -0.1


func _on_health_depleted() -> void:
	despawn()
	died.emit(self)


func _draw() -> void:
	if Relief.enabled:
		_draw_relief()
		return
	if data.flying:
		_draw_flying_shadow()
	if data.is_elite or data.is_boss:
		_draw_aura()
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
	if is_consecrated():
		# Petite croix dorée : il ne se relèvera pas.
		var mark := Vector2(-data.radius * 0.9, -data.radius * 0.9)
		draw_circle(mark, 5.5, Color(0.25, 0.2, 0.05, 0.8))
		draw_line(mark + Vector2(0, -4), mark + Vector2(0, 4), CONSECRATED_COLOR, 2.0)
		draw_line(mark + Vector2(-3, -1.5), mark + Vector2(3, -1.5), CONSECRATED_COLOR, 2.0)
	if data.raider:
		_draw_torch()
	if carried >= 0:
		Loot.draw_item(self, carried, Vector2(0, -data.radius - 2.0), CARRIED_SIZE)
	if data.texture:
		# L'image déborde un peu du rayon de collision (ombre, pattes).
		var size := data.radius * 2.6 * data.sprite_scale
		draw_set_transform(Vector2.ZERO, _heading)
		draw_texture_rect(data.texture, Rect2(-size / 2.0, -size / 2.0, size, size), false,
			Color(0.6, 0.8, 1.0) if is_slowed() or is_frozen() else Color.WHITE)
		draw_set_transform(Vector2.ZERO)
		_draw_ice()
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
	_draw_ice()


## Vue de trois quarts : ombre et halos au sol, le monstre de profil (Creature) tourné
## vers où il marche, puis ce qui l'entoure (bouclier, glace) à hauteur de son corps.
func _draw_relief() -> void:
	var body := Vector2(0, -Creature.body_height(data))
	var u := Creature.unit(data)
	var sheet := Creature.get_sheet(data)
	if sheet:
		sheet.draw(self, Creature.SHADOW_FRAME)
	else:
		Creature.draw_shadow(self, data)
	var ground := Vector2(1.0, Relief.GROUND_SQUASH * 0.6)
	if data.is_elite or data.is_boss:
		var pulse := 0.5 + 0.5 * sin(_aura_time * 4.0)
		var color := EnemyData.BOSS_COLOR if data.is_boss else EnemyData.ELITE_COLOR
		var ring := Relief.ellipse(Vector2(0, 1), u * (1.4 + 0.1 * pulse), u * (1.4 + 0.1 * pulse) * ground.y, 0.0, TAU, 32)
		draw_colored_polygon(ring, Color(color, 0.12 + 0.1 * pulse))
		draw_polyline(ring, Color(color, 0.6 + 0.3 * pulse), 2.5 if data.is_boss else 2.0, true)
	if _heal_pulse_left > 0.0:
		var t := 1.0 - _heal_pulse_left / HEAL_PULSE_DURATION
		var radius := lerpf(data.radius, data.heal_radius, t)
		draw_polyline(Relief.ellipse(Vector2.ZERO, radius, radius * ground.y, 0.0, TAU, 40),
			Color(HEAL_COLOR, 0.6 * (1.0 - t)), 3.0, true)
	if data.raider:
		draw_colored_polygon(Relief.ellipse(Vector2(0, 1), u * 1.5, u * 1.5 * ground.y, 0.0, TAU, 24),
			Color(RAID_COLOR, 0.18 if not is_raiding() else 0.32))
	var tint := Color(0.6, 0.8, 1.0) if is_slowed() or is_frozen() else Color.WHITE
	var facing_left := _is_facing_left(_heading)
	var phase := progress if not is_frozen() else 0.0
	if sheet:
		sheet.draw(self, Creature.walk_frame(phase), Vector2.ZERO, facing_left, tint)
	else:
		Creature.draw(self, data, facing_left, phase, tint)
	if is_burning():
		draw_circle(body, u * 1.1, Color(_dot_color, 0.3), true, -1.0, true)
	if data.max_shield > 0.0 and health.shield > 0.0:
		var ratio := health.shield / data.max_shield
		var shield_color := JAMMED_SHIELD_COLOR if health.is_shield_jammed() else SHIELD_COLOR
		# Bulle à peine teintée : le robot reste lisible dedans.
		draw_circle(body, u * 1.45, Color(shield_color, 0.04 + 0.05 * ratio), true, -1.0, true)
		draw_arc(body, u * 1.45, 0.0, TAU, 40, Color(shield_color, 0.3 + 0.45 * ratio), 1.5, true)
	if data.raider:
		draw_set_transform(body + Vector2(0, u * 0.3))
		_draw_torch_only()
		draw_set_transform(Vector2.ZERO)
	var marks := Vector2(0, -Creature.top_height(data) - 14.0)
	if carried >= 0:
		# Le butin flotte au-dessus de sa barre de vie.
		Loot.draw_item(self, carried, Vector2(0, -Creature.top_height(data) - 11.0), CARRIED_SIZE)
	if not can_be_healed():
		var center := marks + Vector2(8, 0)
		draw_circle(center, 5.5, HEAL_BLOCK_COLOR)
		draw_line(center + Vector2(-3, 0), center + Vector2(3, 0), Color.WHITE, 2.0)
		draw_line(center + Vector2(0, -3), center + Vector2(0, 3), Color.WHITE, 2.0)
		draw_line(center + Vector2(-4, 4), center + Vector2(4, -4), Color(0.2, 0, 0), 1.5)
	if is_consecrated():
		var mark := marks - Vector2(8, 0)
		draw_circle(mark, 5.5, Color(0.25, 0.2, 0.05, 0.8))
		draw_line(mark + Vector2(0, -4), mark + Vector2(0, 4), CONSECRATED_COLOR, 2.0)
		draw_line(mark + Vector2(-3, -1.5), mark + Vector2(3, -1.5), CONSECRATED_COLOR, 2.0)
	if is_frozen():
		draw_set_transform(body)
		_draw_ice()
		draw_set_transform(Vector2.ZERO)


## Pillard : un halo orangé sous lui et une torche à son côté.
func _draw_torch() -> void:
	draw_circle(Vector2.ZERO, data.radius * 1.3, Color(RAID_COLOR, 0.16 if not is_raiding() else 0.3))
	_draw_torch_only()


func _draw_torch_only() -> void:
	var hand := Vector2(data.radius * 0.95, data.radius * 0.35)
	draw_line(hand, hand + Vector2(3, -10), Color(0.45, 0.3, 0.15), 2.5)
	var flame := hand + Vector2(3.5, -12)
	draw_colored_polygon(PackedVector2Array([flame + Vector2(-3.5, 1), flame + Vector2(0, -7), flame + Vector2(3.5, 1)]), RAID_COLOR)
	draw_circle(flame + Vector2(0, -1), 2.0, Color(1.0, 0.9, 0.4))


## Gelé : une gangue de glace par-dessus l'ennemi.
func _draw_ice() -> void:
	if not is_frozen():
		return
	var r := data.radius * 1.15
	draw_circle(Vector2.ZERO, r, Color(FROZEN_COLOR, 0.35))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 6, Color(FROZEN_COLOR, 0.9), 2.0)
	for i in 3:
		var direction := Vector2.from_angle(TAU * i / 3.0 + PI / 6.0) * r * 0.75
		draw_line(-direction, direction, Color(1, 1, 1, 0.55), 1.5)


## Ombre au sol d'un volant, décalée : il paraît en l'air.
func _draw_flying_shadow() -> void:
	var size := Vector2(data.radius * 1.1, data.radius * 0.7)
	draw_set_transform(FLYING_SHADOW_OFFSET, _heading, size / data.radius)
	draw_circle(Vector2.ZERO, data.radius, Color(0, 0, 0, 0.28))
	draw_set_transform(Vector2.ZERO)


## Aura dorée qui pulse autour d'un élite, rouge et dorée autour d'un boss.
func _draw_aura() -> void:
	var pulse := 0.5 + 0.5 * sin(_aura_time * 4.0)
	var color := EnemyData.BOSS_COLOR if data.is_boss else EnemyData.ELITE_COLOR
	var aura_radius := data.radius * (1.25 + 0.08 * pulse)
	draw_circle(Vector2.ZERO, aura_radius, Color(color, 0.12 + 0.1 * pulse))
	draw_arc(Vector2.ZERO, aura_radius, 0.0, TAU, 40, Color(color, 0.55 + 0.3 * pulse), 2.5 if data.is_boss else 2.0)
	if data.is_boss:
		draw_arc(Vector2.ZERO, aura_radius + 5.0, 0.0, TAU, 40, Color(EnemyData.ELITE_COLOR, 0.35 * pulse), 1.5)
