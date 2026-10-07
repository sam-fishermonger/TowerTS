class_name Soldier
extends Entity
## Soldat du pouvoir Renforts : il attend sur le chemin, arrête le premier ennemi qui
## passe à sa portée et le combat. L'ennemi retenu ne marche plus mais frappe le soldat
## (plus fort s'il coûte plus de vies). Un boss ne s'arrête pas : le soldat le frappe au
## passage, sans être frappé. Le soldat repart au bout de sa durée, ou tombe.

## Les coups sont portés à ce rythme, en secondes (des dégâts par image feraient
## défiler un chiffre à chaque image).
const ATTACK_INTERVAL := 0.5
## Dégâts par seconde que fait un ennemi retenu, par vie qu'il coûterait en passant.
const ENEMY_DAMAGE_PER_LIFE := 12.0
## Secondes pendant lesquelles le soldat s'efface en repartant.
const FADE_TIME := 1.0
const BODY_RADIUS := 9.0
const COLOR := Color(0.5, 0.75, 1.0)

## Statistiques du pouvoir (Power) : vie, dégâts par seconde, portée et durée.
var power: Power
var health := 0.0
var max_health := 0.0
var time_left := 0.0
## Ennemi combattu, ou null.
var target: Enemy

var _attack_left := 0.0
## Secondes depuis le dernier coup porté, pour l'animation de l'épée.
var _swing := 1.0


func _ready() -> void:
	max_health = power.health
	health = max_health
	time_left = power.duration
	_attack_left = ATTACK_INTERVAL


func _process(delta: float) -> void:
	time_left -= delta
	if time_left <= 0.0:
		_release()
		despawn()
		return
	_swing += delta
	if not is_instance_valid(target) or not _is_valid_target(target):
		_release()
		target = _find_target()
		if target and not target.data.is_boss:
			target.holder = self
	if target == null:
		queue_redraw()
		return
	_attack_left -= delta
	if _attack_left <= 0.0:
		_attack_left += ATTACK_INTERVAL
		_swing = 0.0
		target.take_damage(power.damage * ATTACK_INTERVAL)
	# L'ennemi retenu frappe le soldat (un boss passe sans s'arrêter, ni frapper).
	if is_instance_valid(target) and target.is_alive and target.holder == self:
		health -= target.data.damage * ENEMY_DAMAGE_PER_LIFE * delta
		if health <= 0.0:
			_release()
			despawn()
			return
	queue_redraw()


## Se bat contre l'ennemi tant qu'il est en vie et à portée (il bouge s'il n'est pas retenu).
func _is_valid_target(enemy: Enemy) -> bool:
	# Un soldat au sol ne retient pas un volant.
	return enemy.is_alive and not enemy.data.flying \
		and global_position.distance_to(enemy.global_position) <= power.radius + enemy.data.radius


## L'ennemi le plus avancé à portée qu'aucun autre soldat ne retient ; un boss seulement
## s'il n'y a personne d'autre.
func _find_target() -> Enemy:
	var best: Enemy = null
	for enemy in Enemy.get_alive_in_radius(get_tree(), global_position, power.radius + 24.0):
		if not _is_valid_target(enemy) or enemy.is_held():
			continue
		if best == null or (best.data.is_boss and not enemy.data.is_boss) \
				or (best.data.is_boss == enemy.data.is_boss and enemy.distance_to_end() < best.distance_to_end()):
			best = enemy
	return best


func _release() -> void:
	if is_instance_valid(target) and target.holder == self:
		target.holder = null
	target = null


func _draw() -> void:
	var alpha := clampf(time_left / FADE_TIME, 0.0, 1.0)
	var facing := 1.0
	if is_instance_valid(target):
		facing = signf(target.global_position.x - global_position.x)
		if facing == 0.0:
			facing = 1.0
	if Relief.enabled:
		_draw_relief(facing, alpha)
		return
	# Ombre, corps, casque et bouclier.
	draw_circle(Vector2(0, BODY_RADIUS * 0.8), BODY_RADIUS * 0.9, Color(0, 0, 0, 0.25 * alpha))
	draw_circle(Vector2.ZERO, BODY_RADIUS, Color(COLOR.darkened(0.35), alpha))
	draw_arc(Vector2.ZERO, BODY_RADIUS, 0.0, TAU, 20, Color(COLOR.darkened(0.7), alpha), 1.5)
	draw_circle(Vector2(0, -BODY_RADIUS * 0.6), BODY_RADIUS * 0.55, Color(0.85, 0.85, 0.9, alpha))
	draw_rect(Rect2(Vector2(-facing * BODY_RADIUS - 3.0, -4.0), Vector2(6.0, 9.0)), Color(COLOR, alpha))
	# Épée, qui s'abat à chaque coup.
	var angle := lerpf(-1.2, 0.3, clampf(_swing / 0.15, 0.0, 1.0)) if _swing < 0.3 else -0.6
	var hand := Vector2(facing * BODY_RADIUS * 0.8, 0.0)
	var tip := hand + Vector2.from_angle(angle if facing > 0.0 else PI - angle) * 13.0
	draw_line(hand, tip, Color(0.92, 0.92, 0.95, alpha), 2.5)
	# Barre de vie dès qu'il est blessé.
	if health < max_health:
		var top_left := Vector2(-11.0, -BODY_RADIUS - 9.0)
		draw_rect(Rect2(top_left, Vector2(22.0, 3.0)), Color(0.15, 0.15, 0.15, alpha))
		draw_rect(Rect2(top_left, Vector2(22.0 * health / max_health, 3.0)), Color(0.4, 0.75, 1.0, alpha))


## Vue de trois quarts : un petit chevalier de profil au-dessus de son pied, tourné vers
## l'ennemi qu'il combat : casque à plumet, tabard bleu, bouclier devant lui, épée qui
## s'abat à chaque coup. `alpha` l'efface quand il repart.
func _draw_relief(facing: float, alpha: float) -> void:
	var fade := Color(1, 1, 1, alpha)
	var outline := Relief.OUTLINE * fade
	var steel := Color(0.78, 0.8, 0.86)
	Relief.draw_shadow(self, Vector2(1, 0), 10.0, 3.8, 0.32 * alpha)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
	# Jambes écartées, celle du fond plus sombre.
	for leg in [-1.0, 1.0]:
		var hip := Vector2(leg * 1.5, -9)
		var foot := Vector2(leg * 4.0, 0)
		draw_line(hip, foot, outline, 5.0, true)
		draw_line(hip, foot, steel.darkened(0.4 if leg < 0.0 else 0.15) * fade, 3.0, true)
		draw_line(foot + Vector2(-1.5, 0), foot + Vector2(2.5, 0), outline, 3.5, true)
	# Épée : levée au repos, elle s'abat à chaque coup.
	var angle := lerpf(-2.0, 0.2, clampf(_swing / 0.15, 0.0, 1.0)) if _swing < 0.3 else -1.3
	var hand := Vector2(4, -14)
	var blade := Vector2.from_angle(angle)
	draw_line(hand, hand + blade * 15.0, outline, 4.5, true)
	draw_line(hand + blade * 3.0, hand + blade * 15.0, Color(0.92, 0.93, 0.97) * fade, 2.2, true)
	draw_line(hand + blade * 2.5 + blade.orthogonal() * 3.5, hand + blade * 2.5 - blade.orthogonal() * 3.5,
		Color(0.85, 0.65, 0.25) * fade, 2.5, true)
	# Corps en cotte de mailles et tabard à la couleur des renforts.
	draw_colored_polygon(Relief.ellipse(Vector2(0, -14), 6.8, 8.0, 0.0, TAU, 16), outline)
	draw_colored_polygon(Relief.ellipse(Vector2(0, -14), 5.3, 6.5, 0.0, TAU, 16), steel.darkened(0.15) * fade)
	var tabard := PackedVector2Array([Vector2(-3.5, -18), Vector2(3.5, -18), Vector2(4, -8), Vector2(-4, -8)])
	draw_colored_polygon(tabard, COLOR.darkened(0.15) * fade)
	draw_line(Vector2(-4, -10), Vector2(4, -10), Color(0.85, 0.65, 0.25) * fade, 1.5)
	# Bras qui tient l'épée.
	draw_line(Vector2(0, -16), hand, outline, 4.5, true)
	draw_line(Vector2(0, -16), hand, steel * fade, 2.5, true)
	# Casque à visière, plumet bleu.
	var head := Vector2(0.5, -24)
	var plume := PackedVector2Array([head + Vector2(-1, -4), head + Vector2(-7, -9), head + Vector2(-9, -4), head + Vector2(-3, -2)])
	draw_colored_polygon(plume, COLOR * fade)
	plume.append(plume[0])
	draw_polyline(plume, outline, 1.5, true)
	draw_circle(head, 6.0, outline, true, -1.0, true)
	draw_circle(head, 4.6, steel * fade, true, -1.0, true)
	draw_circle(head + Vector2(-1.5, -1.8), 1.8, Color(1, 1, 1, 0.7 * alpha), true, -1.0, true)
	draw_line(head + Vector2(0.5, 0.2), head + Vector2(5, 0.2), outline, 1.8)
	# Bouclier tenu devant, à la couleur des renforts, frappé d'une croix dorée.
	var shield := PackedVector2Array([Vector2(3, -19), Vector2(11, -19), Vector2(11, -12), Vector2(7, -6), Vector2(3, -12)])
	draw_colored_polygon(shield, COLOR * fade)
	draw_colored_polygon(PackedVector2Array([Vector2(3, -19), Vector2(7, -19), Vector2(7, -6), Vector2(3, -12)]),
		COLOR.lightened(0.25) * fade)
	draw_line(Vector2(7, -18), Vector2(7, -8), Color(1.0, 0.82, 0.3) * fade, 1.5)
	draw_line(Vector2(4, -15), Vector2(10, -15), Color(1.0, 0.82, 0.3) * fade, 1.5)
	shield.append(shield[0])
	draw_polyline(shield, outline, 1.8, true)
	draw_set_transform(Vector2.ZERO)
	# Barre de vie dès qu'il est blessé.
	if health < max_health:
		var top_left := Vector2(-11.0, -40.0)
		draw_rect(Rect2(top_left - Vector2.ONE, Vector2(24.0, 5.0)), outline)
		draw_rect(Rect2(top_left, Vector2(22.0 * health / max_health, 3.0)), Color(0.4, 0.75, 1.0, alpha))
