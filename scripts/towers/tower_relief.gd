class_name TowerRelief
## Tours de la vue de trois quarts, dessinées en code : socle de pierre et plancher
## (Relief.draw_plinth), donjon de pierre crénelé ceint d'une bande à la couleur de la
## tour, et au sommet son arme vue de biais, qui pivote vers sa cible. L'arme vient du
## nom de l'image de tourelle (cannon, gatling, frost…) ; une tour inconnue garde son
## image, écrasée.
## Les améliorations se voient : une rangée de pierres de plus et des liserés dorés au
## niveau 2, une bannière au niveau 3.

## Hauteur du donjon au niveau 1, et ce que chaque amélioration ajoute.
const KEEP_HEIGHT := 18.0
const LEVEL_HEIGHT := 5.0
const KEEP_RX := 16.0
const KEEP_RY := 8.0
const STONE := Color(0.72, 0.69, 0.63)
const METAL := Color(0.42, 0.45, 0.5)
const GOLD := Color(1.0, 0.82, 0.3)
## Raccourci de la profondeur : une arme tournée vers le haut de l'écran paraît plus courte.
const DEPTH := 0.4


## Hauteur du sommet du donjon au-dessus du pied, d'où partent les tirs.
static func top_height(upgrades := 0) -> float:
	return 9.0 + KEEP_HEIGHT + LEVEL_HEIGHT * upgrades + 16.0


static func weapon_of(data: TowerData) -> String:
	return data.turret_texture.resource_path.get_file().get_basename() if data.turret_texture else ""


static func draw(canvas: CanvasItem, data: TowerData, foot: Vector2, aim := -PI / 2.0, tint := Color.WHITE,
		upgrades := 0) -> void:
	var deck := Relief.draw_plinth(canvas, foot, tint)
	var top := _draw_keep(canvas, deck + Vector2(0, 2), data.color, tint, upgrades)
	_draw_merlons(canvas, top, tint, true)
	_draw_merlons(canvas, top, tint, false)
	_draw_weapon(canvas, data, top + Vector2(0, -8), aim if data.turret_rotates else -PI / 2.0, tint)
	if upgrades >= 2:
		_draw_banner(canvas, top + Vector2(-KEEP_RX + 2, -2), data.color, tint)


## Donjon : cylindre de pierre, joints des pierres, bande de la couleur de la tour sous
## les créneaux. Renvoie le centre de son sommet.
static func _draw_keep(canvas: CanvasItem, base: Vector2, color: Color, tint: Color, upgrades: int) -> Vector2:
	var height := KEEP_HEIGHT + LEVEL_HEIGHT * upgrades
	var top := Relief.draw_cylinder(canvas, base, KEEP_RX, KEEP_RY, height, STONE, tint)
	var joint := Color(Relief.OUTLINE, 0.35) * tint
	var rows := int(height / 6.0)
	for row in rows:
		var y := -6.0 * (row + 1)
		if y < -height + 7.0:
			break
		canvas.draw_polyline(Relief.ellipse(base + Vector2(0, y), KEEP_RX, KEEP_RY, 0.15, PI - 0.15, 12), joint, 1.0, true)
		for x in ([-8.0, 4.0] if row % 2 == 0 else [-2.0, 10.0]):
			var bottom := KEEP_RY * sqrt(1.0 - pow(x / KEEP_RX, 2.0))
			canvas.draw_line(base + Vector2(x, y + bottom), base + Vector2(x, y + bottom + 6.0), joint, 1.0)
	# Bande de couleur juste sous le sommet.
	var band := PackedVector2Array()
	band.append_array(Relief.ellipse(top + Vector2(0, 7), KEEP_RX, KEEP_RY, 0.0, PI, 14))
	band.append_array(Relief.ellipse(top + Vector2(0, 2), KEEP_RX, KEEP_RY, PI, 0.0, 14))
	canvas.draw_colored_polygon(band, color.darkened(0.1) * tint)
	canvas.draw_polyline(Relief.ellipse(top + Vector2(0, 7), KEEP_RX, KEEP_RY, 0.0, PI, 14), Relief.OUTLINE * tint, 1.5, true)
	if upgrades >= 1:
		canvas.draw_polyline(Relief.ellipse(top + Vector2(0, 4.5), KEEP_RX, KEEP_RY, 0.2, PI - 0.2, 14), GOLD * tint, 1.5, true)
	# Le sommet : un chemin de ronde plus sombre.
	canvas.draw_colored_polygon(Relief.ellipse(top, KEEP_RX - 3.0, KEEP_RY - 1.5), STONE.darkened(0.4) * tint)
	return top


## Créneaux du sommet (ceux du fond d'abord). L'arme se dresse au-dessus.
static func _draw_merlons(canvas: CanvasItem, top: Vector2, tint: Color, back: bool) -> void:
	for i in 8:
		var angle := TAU * (i + 0.5) / 8.0
		if (sin(angle) < 0.0) != back:
			continue
		var at := top + Vector2(cos(angle) * (KEEP_RX - 2.5), sin(angle) * (KEEP_RY - 1.0))
		var block := PackedVector2Array([at + Vector2(-3, 1), at + Vector2(-3, -4), at + Vector2(3, -4), at + Vector2(3, 1)])
		canvas.draw_colored_polygon(block, STONE.lightened(0.05) * tint)
		canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(-3, -4), at + Vector2(3, -4), at + Vector2(2, -5.5),
			at + Vector2(-2, -5.5)]), STONE.lightened(0.25) * tint)
		block.append(block[0])
		canvas.draw_polyline(block, Relief.OUTLINE * tint, 1.5, true)


static func _draw_banner(canvas: CanvasItem, at: Vector2, color: Color, tint: Color) -> void:
	canvas.draw_line(at, at + Vector2(0, -22), Relief.OUTLINE * tint, 2.0)
	var flag := PackedVector2Array([at + Vector2(1, -22), at + Vector2(12, -19), at + Vector2(1, -15)])
	canvas.draw_colored_polygon(flag, color.lightened(0.15) * tint)
	flag.append(flag[0])
	canvas.draw_polyline(flag, Relief.OUTLINE * tint, 1.2, true)


# --- Armes ---------------------------------------------------------------------

## Direction de l'arme à l'écran : raccourcie quand elle pointe vers le haut ou le bas.
static func _direction(aim: float) -> Vector2:
	return Vector2(cos(aim), sin(aim) * DEPTH)


static func _draw_weapon(canvas: CanvasItem, data: TowerData, at: Vector2, aim: float, tint: Color) -> void:
	var color := data.color
	var dir := _direction(aim)
	var head := at + Vector2(0, -4)
	# L'arme tournée vers le fond passe derrière la tourelle.
	var behind := sin(aim) < 0.0
	match weapon_of(data):
		"cannon":
			_turret(canvas, head, 12.5, color, tint, behind, func() -> void:
				_barrel(canvas, head, head + dir * 20.0, 7.0, METAL, tint, true))
		"gatling":
			_turret(canvas, head, 12.0, color, tint, behind, func() -> void:
				var side := Vector2(-dir.y, dir.x).normalized() * 3.2
				for offset in [-1.0, 0.0, 1.0]:
					_barrel(canvas, head + side * offset, head + side * offset + dir * 19.0, 3.0, METAL, tint, false)
				_barrel(canvas, head + dir * 11.0, head + dir * 12.5, 10.0, METAL.darkened(0.2), tint, false))
		"sniper", "marksman":
			_turret(canvas, head, 11.0, color, tint, behind, func() -> void:
				_barrel(canvas, head, head + dir * 28.0, 3.5, METAL.darkened(0.15), tint, true)
				_barrel(canvas, head + Vector2(0, -5), head + Vector2(0, -5) + dir * 9.0, 3.5, color.darkened(0.3), tint, false))
		"mortar":
			_turret(canvas, head + Vector2(0, 2), 12.5, color, tint, behind, func() -> void:
				var mouth := head + dir * 6.0 + Vector2(0, -10)
				_barrel(canvas, head, mouth, 11.0, METAL, tint, false)
				canvas.draw_colored_polygon(Relief.ellipse(mouth, 6.0, 3.0), Color(0.08, 0.08, 0.1) * tint))
		"rail":
			_turret(canvas, head, 11.5, color, tint, behind, func() -> void:
				var side := Vector2(-dir.y, dir.x).normalized() * 3.0
				for offset in [-1.0, 1.0]:
					_barrel(canvas, head + side * offset, head + side * offset + dir * 24.0, 3.0, METAL, tint, false)
				canvas.draw_line(head + dir * 5.0, head + dir * 21.0, color.lightened(0.5) * tint, 1.5, true))
		"flame":
			_tank(canvas, head + Vector2(-9, 4) - dir * 3.0, Color(0.75, 0.2, 0.15), tint)
			_turret(canvas, head, 11.0, color, tint, behind, func() -> void:
				_barrel(canvas, head, head + dir * 20.0, 5.0, METAL, tint, true)
				canvas.draw_circle(head + dir * 21.0, 2.5, Color(1.0, 0.7, 0.2) * tint, true, -1.0, true))
		"pesticide", "teargas":
			_tank(canvas, head + Vector2(-9, 4) - dir * 3.0, color.lightened(0.15), tint)
			_turret(canvas, head, 11.0, color.darkened(0.15), tint, behind, func() -> void:
				_barrel(canvas, head, head + dir * 17.0, 4.5, METAL, tint, true))
		"beam":
			_turret(canvas, head, 11.5, color, tint, behind, func() -> void:
				_barrel(canvas, head, head + dir * 16.0, 6.0, METAL.darkened(0.2), tint, false)
				_orb(canvas, head + dir * 18.0, 5.0, color.lightened(0.45), tint))
		"arc":
			_rod(canvas, at, at + Vector2(0, -20), tint)
			for ring in 3:
				canvas.draw_polyline(Relief.ellipse(at + Vector2(0, -5 - ring * 5.0), 6.0 - ring, 2.5, 0.0, TAU, 12),
					Color(0.85, 0.55, 0.25) * tint, 2.0, true)
			_orb(canvas, at + Vector2(0, -23), 6.5, color.lightened(0.3), tint)
		"coil":
			_rod(canvas, at, at + Vector2(0, -18), tint)
			for ring in 5:
				var c := at + Vector2(0, -3 - ring * 3.5)
				canvas.draw_polyline(Relief.ellipse(c, 8.0, 3.2, 0.0, TAU, 14), Relief.OUTLINE * tint, 3.5, true)
				canvas.draw_polyline(Relief.ellipse(c, 8.0, 3.2, 0.0, TAU, 14), Color(0.85, 0.5, 0.2) * tint, 2.0, true)
			_orb(canvas, at + Vector2(0, -22), 4.5, color.lightened(0.3), tint)
		"frost":
			var crystal := PackedVector2Array([at + Vector2(0, -28), at + Vector2(8, -12), at + Vector2(0, -2), at + Vector2(-8, -12)])
			canvas.draw_colored_polygon(crystal, Color(0.7, 0.92, 1.0) * tint)
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -28), at + Vector2(0, -2), at + Vector2(-8, -12)]),
				Color(0.88, 0.98, 1.0) * tint)
			crystal.append(crystal[0])
			canvas.draw_polyline(crystal, Relief.OUTLINE * tint, 2.0, true)
			for side in [-1.0, 1.0]:
				var shard := PackedVector2Array([at + Vector2(side * 7, -4), at + Vector2(side * 13, -14), at + Vector2(side * 10, -2)])
				canvas.draw_colored_polygon(shard, Color(0.6, 0.85, 1.0) * tint)
				shard.append(shard[0])
				canvas.draw_polyline(shard, Relief.OUTLINE * tint, 1.5, true)
		"jammer":
			_rod(canvas, at, at + Vector2(0, -10), tint)
			var dish := at + Vector2(0, -15)
			var face := Relief.ellipse(dish, 11.0, 7.0, 0.0, TAU, 20)
			canvas.draw_colored_polygon(face, Color(0.85, 0.87, 0.9) * tint)
			canvas.draw_colored_polygon(Relief.ellipse(dish + Vector2(-1, -1), 7.0, 4.5), Color(0.7, 0.72, 0.78) * tint)
			face.append(face[0])
			canvas.draw_polyline(face, Relief.OUTLINE * tint, 2.0, true)
			canvas.draw_line(dish, dish + Vector2(4, -9), Relief.OUTLINE * tint, 1.5)
			canvas.draw_circle(dish + Vector2(4, -9), 2.5, color.lightened(0.3) * tint, true, -1.0, true)
		"magnet":
			var magnet := PackedVector2Array()
			magnet.append_array(Relief.ellipse(at + Vector2(0, -10), 10.0, 10.0, PI, TAU, 12))
			magnet.append_array(Relief.ellipse(at + Vector2(0, -10), 4.5, 4.5, TAU, PI, 10))
			canvas.draw_colored_polygon(magnet, Color(0.85, 0.2, 0.2) * tint)
			magnet.append(magnet[0])
			canvas.draw_polyline(magnet, Relief.OUTLINE * tint, 2.0, true)
			for side in [-1.0, 1.0]:
				var tip := Rect2(at + Vector2(side * 7.25 - 2.75, -10), Vector2(5.5, 7))
				canvas.draw_rect(tip, Color(0.85, 0.87, 0.9) * tint)
				canvas.draw_rect(tip, Relief.OUTLINE * tint, false, 1.5)
		"bell":
			for side in [-1.0, 1.0]:
				canvas.draw_line(at + Vector2(side * 10, 0), at + Vector2(side * 10, -22), Relief.OUTLINE * tint, 5.0)
				canvas.draw_line(at + Vector2(side * 10, 0), at + Vector2(side * 10, -22), Color(0.5, 0.33, 0.18) * tint, 3.0)
			var roof := PackedVector2Array([at + Vector2(-14, -21), at + Vector2(0, -31), at + Vector2(14, -21)])
			canvas.draw_colored_polygon(roof, color.darkened(0.2) * tint)
			roof.append(roof[0])
			canvas.draw_polyline(roof, Relief.OUTLINE * tint, 2.0, true)
			var bell := PackedVector2Array([at + Vector2(-3, -18), at + Vector2(3, -18), at + Vector2(7, -7), at + Vector2(-7, -7)])
			canvas.draw_colored_polygon(bell, GOLD.darkened(0.15) * tint)
			bell.append(bell[0])
			canvas.draw_polyline(bell, Relief.OUTLINE * tint, 1.5, true)
		"censer":
			canvas.draw_line(at + Vector2(-9, -24), at + Vector2(9, -24), Relief.OUTLINE * tint, 3.0)
			canvas.draw_line(at + Vector2(0, -24), at + Vector2(0, -15), Relief.OUTLINE * tint, 1.5)
			_orb(canvas, at + Vector2(0, -10), 6.0, GOLD.darkened(0.1), tint)
			for puff in 3:
				canvas.draw_circle(at + Vector2(5 + puff * 3, -18 - puff * 5), 2.5 + puff, Color(color.lightened(0.5), 0.5) * tint, true, -1.0, true)
		_:
			if data.turret_texture:
				var size := Tower.SIZE * Tower.TURRET_SCALE
				canvas.draw_set_transform_matrix(Transform2D(aim, Vector2.ZERO).scaled(Vector2(1.0, Relief.GROUND_SQUASH))
					.translated(head))
				canvas.draw_texture_rect(data.turret_texture, Rect2(-Vector2.ONE * size / 2.0, Vector2.ONE * size), false, tint)
				canvas.draw_set_transform(Vector2.ZERO)
			else:
				_orb(canvas, head, 9.0, color, tint)


## Tourelle en dôme, à la couleur de la tour, avec son arme devant ou derrière elle.
static func _turret(canvas: CanvasItem, head: Vector2, radius: float, color: Color, tint: Color, behind: bool,
		weapon: Callable) -> void:
	if behind:
		weapon.call()
	# Couronne sombre au pied, puis le dôme, plus large que haut.
	canvas.draw_colored_polygon(Relief.ellipse(head + Vector2(0, 5), radius + 2.0, (radius + 2.0) * 0.45),
		color.darkened(0.45) * tint)
	var dome := Relief.ellipse(head + Vector2(0, 4), radius, radius * 0.95, PI, TAU, 16)
	dome.append_array(Relief.ellipse(head + Vector2(0, 4), radius, radius * 0.4, 0.0, PI, 12))
	canvas.draw_colored_polygon(dome, color * tint)
	canvas.draw_colored_polygon(Relief.ellipse(head + Vector2(-radius * 0.35, -radius * 0.2), radius * 0.3, radius * 0.22),
		Color(1, 1, 1, 0.45) * tint)
	canvas.draw_polyline(Relief.ellipse(head + Vector2(0, 4), radius, radius * 0.4, 0.0, PI, 12),
		color.darkened(0.4) * tint, 1.5, true)
	dome.append(dome[0])
	canvas.draw_polyline(dome, Relief.OUTLINE * tint, 2.0, true)
	if not behind:
		weapon.call()


## Boule cernée, éclairée en haut à gauche.
static func _orb(canvas: CanvasItem, center: Vector2, radius: float, color: Color, tint: Color) -> void:
	canvas.draw_circle(center, radius + 1.5, Relief.OUTLINE * tint, true, -1.0, true)
	canvas.draw_circle(center, radius, color.darkened(0.15) * tint, true, -1.0, true)
	canvas.draw_circle(center + Vector2(-radius * 0.12, -radius * 0.15), radius * 0.78, color * tint, true, -1.0, true)
	canvas.draw_circle(center + Vector2(-radius * 0.35, -radius * 0.4), radius * 0.28, Color(1, 1, 1, 0.6) * tint, true, -1.0, true)


## Canon : un tube cerné, un reflet, et une bouche sombre au bout si `muzzle`.
static func _barrel(canvas: CanvasItem, from: Vector2, to: Vector2, width: float, color: Color, tint: Color,
		muzzle: bool) -> void:
	canvas.draw_line(from, to, Relief.OUTLINE * tint, width + 3.0, true)
	canvas.draw_line(from, to, color * tint, width, true)
	var side := Vector2(-(to - from).y, (to - from).x).normalized() * width * 0.25
	if side.y > 0.0:
		side = -side
	canvas.draw_line(from + side, to + side, color.lightened(0.35) * tint, maxf(width * 0.3, 1.0), true)
	if muzzle:
		canvas.draw_circle(to, width * 0.62 + 1.5, Relief.OUTLINE * tint, true, -1.0, true)
		canvas.draw_circle(to, width * 0.62, color.darkened(0.2) * tint, true, -1.0, true)
		canvas.draw_circle(to, width * 0.32, Color(0.06, 0.06, 0.08) * tint, true, -1.0, true)


## Réservoir posé à l'arrière (lance-flammes, gaz).
static func _tank(canvas: CanvasItem, at: Vector2, color: Color, tint: Color) -> void:
	var rect := Rect2(at + Vector2(-4, -10), Vector2(8, 12))
	canvas.draw_rect(rect.grow(1.5), Relief.OUTLINE * tint)
	canvas.draw_rect(rect, color * tint)
	canvas.draw_rect(Rect2(rect.position + Vector2(1.5, 1.5), Vector2(2, 8)), Color(1, 1, 1, 0.35) * tint)


## Tige de métal (bobines, antennes).
static func _rod(canvas: CanvasItem, from: Vector2, to: Vector2, tint: Color) -> void:
	canvas.draw_line(from, to, Relief.OUTLINE * tint, 5.0)
	canvas.draw_line(from, to, METAL * tint, 3.0)
