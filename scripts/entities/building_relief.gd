class_name BuildingRelief
## Bâtiments de la Conquête dans la vue de trois quarts, dessinés en code comme les tours
## (TowerRelief) : de petites constructions de bois, de toile et de pierre debout sur leur
## case, vues de face, le flanc droit dans l'ombre (la lumière vient du haut à gauche),
## cernées de sombre. Le pied du bâtiment (le centre de sa case) est en `foot`.
## Un chantier montre le bâtiment en transparence dans un échafaudage.

## Un pas vers le fond, à l'écran : il monte et part un peu à droite.
const DEPTH := Vector2(0.45, -0.5)
const WOOD := Color(0.62, 0.43, 0.24)
const STONE := Color(0.72, 0.69, 0.63)
const PLASTER := Color(0.93, 0.88, 0.76)
const ROOF := Color(0.6, 0.33, 0.22)
const WINDOW := Color(1.0, 0.85, 0.4)


## Hauteur du haut du bâtiment au-dessus du pied (pour placer sa barre de vie).
static func top_height(kind: int) -> float:
	match kind:
		Building.Kind.HOUSE:
			return 36.0
		Building.Kind.EXTRACTOR:
			return 52.0
		Building.Kind.BARRICADE:
			return 28.0
		Building.Kind.BARRACKS:
			return 46.0
	return 32.0


static func draw(canvas: CanvasItem, kind: int, foot: Vector2, tint := Color.WHITE) -> void:
	var color: Color = Building.get_definition(kind).color
	match kind:
		Building.Kind.DEPOT:
			_draw_depot(canvas, foot, color, tint)
		Building.Kind.HOUSE:
			_draw_house(canvas, foot, color, tint)
		Building.Kind.EXTRACTOR:
			_draw_extractor(canvas, foot, color, tint)
		Building.Kind.BARRICADE:
			_draw_barricade(canvas, foot, color, tint)
		Building.Kind.BARRACKS:
			_draw_barracks(canvas, foot, color, tint)


## Chantier : une dalle de pierre, le bâtiment en transparence, et un échafaudage de
## perches et de planches autour.
static func draw_site(canvas: CanvasItem, kind: int, foot: Vector2, tint := Color.WHITE) -> void:
	var low := kind == Building.Kind.BARRICADE
	var width := 50.0
	var depth := 30.0
	var height := 18.0 if low else minf(top_height(kind) - 4.0, 38.0)
	Relief.draw_shadow(canvas, foot + Vector2(5, 4), 30.0, 12.0, 0.25 * tint.a)
	if not low:
		_box(canvas, foot, width - 4.0, depth - 4.0, 3.0, STONE, tint, STONE.lightened(0.2))
	draw(canvas, kind, foot, Color(1, 1, 1, 0.45) * tint)
	var d := DEPTH * depth
	var corner := foot - Vector2(width / 2.0, 0) - d / 2.0
	var pole := WOOD.darkened(0.1)
	# Perches du fond, puis planches et perches de devant.
	for at in [corner + d, corner + Vector2(width, 0) + d]:
		_beam(canvas, at, at + Vector2(0, -height), 3.0, pole.darkened(0.25), tint)
	for level: float in ([0.5, 1.0] if not low else [0.8]):
		var y := -height * level
		_beam(canvas, corner + Vector2(width, y), corner + Vector2(width, y) + d, 3.5, WOOD, tint)
		_beam(canvas, corner + Vector2(-3, y), corner + Vector2(width + 3, y), 3.5, WOOD.lightened(0.1), tint)
	_beam(canvas, corner + Vector2(4, 0), corner + Vector2(width - 4, -height * 0.5), 2.0, pole, tint)
	for x in [0.0, width]:
		_beam(canvas, corner + Vector2(x, 0), corner + Vector2(x, -height - 3.0), 3.0, pole, tint)


# --- Bâtiments ------------------------------------------------------------------

## Dépôt : un hangar de planches à grande porte, une caisse et un tas de pierres devant.
static func _draw_depot(canvas: CanvasItem, foot: Vector2, color: Color, tint: Color) -> void:
	Relief.draw_shadow(canvas, foot + Vector2(6, 3), 30.0, 12.0, 0.3 * tint.a)
	var width := 40.0
	var depth := 24.0
	var wall := 15.0
	var corner := _box(canvas, foot + Vector2(0, -2), width, depth, wall, color.darkened(0.1), tint)
	# Planches de la façade.
	for y in [-4.0, -8.0, -12.0]:
		canvas.draw_line(corner + Vector2(1, y), corner + Vector2(width - 1, y), Color(Relief.OUTLINE, 0.3) * tint, 1.0)
	# Grande porte à deux battants, croisillons de bois.
	var door := Rect2(corner + Vector2(width / 2.0 - 8.0, -12.0), Vector2(16, 12))
	canvas.draw_rect(door, Color(0.25, 0.16, 0.1) * tint)
	canvas.draw_line(door.position, door.end, color.darkened(0.3) * tint, 1.5)
	canvas.draw_line(door.position + Vector2(door.size.x, 0), door.position + Vector2(0, door.size.y),
		color.darkened(0.3) * tint, 1.5)
	canvas.draw_rect(door, Relief.OUTLINE * tint, false, 1.5)
	_gable_roof(canvas, corner, width, depth, wall, 11.0, ROOF, color.darkened(0.25), tint)
	# Une caisse à gauche, des pierres à droite.
	_box(canvas, foot + Vector2(-17, 12), 9.0, 7.0, 8.0, WOOD.lightened(0.15), tint, WOOD.lightened(0.3))
	for stone in [Vector3(15, 13, 4.0), Vector3(21, 12, 3.5), Vector3(18, 9, 3.5)]:
		_pebble(canvas, foot + Vector2(stone.x, stone.y), stone.z, STONE, tint)


## Maison : murs blanchis à colombages, porte, fenêtre éclairée, toit de tuiles à la
## couleur du bâtiment et une cheminée.
static func _draw_house(canvas: CanvasItem, foot: Vector2, color: Color, tint: Color) -> void:
	Relief.draw_shadow(canvas, foot + Vector2(6, 3), 25.0, 11.0, 0.3 * tint.a)
	var width := 30.0
	var depth := 22.0
	var wall := 15.0
	var corner := _box(canvas, foot + Vector2(-1, 0), width, depth, wall, PLASTER, tint)
	var timber := Color(0.42, 0.27, 0.15) * tint
	canvas.draw_line(corner + Vector2(0, -wall * 0.5), corner + Vector2(width, -wall * 0.5), timber, 1.5)
	canvas.draw_line(corner + Vector2(width, -wall * 0.5), corner + Vector2(width, -wall * 0.5) + DEPTH * depth, timber, 1.5)
	var door := Rect2(corner + Vector2(5, -10), Vector2(7, 10))
	canvas.draw_rect(door, color.darkened(0.55) * tint)
	canvas.draw_rect(door, Relief.OUTLINE * tint, false, 1.5)
	var window := Rect2(corner + Vector2(17, -11), Vector2(8, 6))
	canvas.draw_rect(window, WINDOW * tint)
	canvas.draw_line(window.position + Vector2(4, 0), window.position + Vector2(4, 6), timber, 1.0)
	canvas.draw_rect(window, Relief.OUTLINE * tint, false, 1.5)
	# Cheminée sur le pan du fond, avant le toit qui la cache en partie.
	var chimney := corner + Vector2(width * 0.72, -wall - 8.0) + DEPTH * depth * 0.75
	_box(canvas, chimney + Vector2(0, 2), 5.0, 4.0, 12.0, Color(0.6, 0.4, 0.35), tint, Color(0.2, 0.15, 0.12))
	_gable_roof(canvas, corner, width, depth, wall, 13.0, color.darkened(0.1), PLASTER, tint)


## Extracteur : une margelle de pierre sur le filon, un grand cristal d'essence qui en
## sort, et un chevalement de bois au-dessus, avec sa poulie.
static func _draw_extractor(canvas: CanvasItem, foot: Vector2, color: Color, tint: Color) -> void:
	Relief.draw_shadow(canvas, foot + Vector2(5, 4), 26.0, 11.0, 0.3 * tint.a)
	var apex := foot + Vector2(1, -48)
	# Pied du fond du chevalement, derrière le reste.
	_beam(canvas, foot + Vector2(4, -10), apex, 3.5, WOOD.darkened(0.3), tint)
	var top := Relief.draw_cylinder(canvas, foot + Vector2(0, 5), 17.0, 8.5, 7.0, STONE, tint)
	canvas.draw_colored_polygon(Relief.ellipse(top, 13.0, 6.0), Color(0.1, 0.05, 0.15) * tint)
	canvas.draw_colored_polygon(Relief.ellipse(top, 11.0, 5.0), Color(color, 0.45) * tint)
	draw_crystal(canvas, top + Vector2(0, 2), 30.0, 11.0, color, tint)
	# Corde de la poulie jusqu'au cristal.
	canvas.draw_line(apex + Vector2(0, 4), top + Vector2(0, -27), Relief.OUTLINE * tint, 1.0)
	for x in [-18.0, 18.0]:
		_beam(canvas, foot + Vector2(x, 6), apex, 3.5, WOOD, tint)
	_beam(canvas, foot + Vector2(-11, -16), foot + Vector2(13, -16), 3.0, WOOD.lightened(0.1), tint)
	canvas.draw_circle(apex + Vector2(0, 2), 5.0, Relief.OUTLINE * tint, true, -1.0, true)
	canvas.draw_circle(apex + Vector2(0, 2), 3.5, Color(0.42, 0.45, 0.5) * tint, true, -1.0, true)
	canvas.draw_circle(apex + Vector2(0, 2), 1.2, Relief.OUTLINE * tint, true, -1.0, true)


## Barricade : un cheval de frise, une poutre posée en travers du chemin et hérissée de
## pieux croisés.
static func _draw_barricade(canvas: CanvasItem, foot: Vector2, color: Color, tint: Color) -> void:
	Relief.draw_shadow(canvas, foot + Vector2(4, 4), 32.0, 9.0, 0.3 * tint.a)
	var stake := color.lightened(0.1)
	var xs := [-20.0, 0.0, 20.0]
	# Pieux penchés vers le fond, puis la poutre, puis ceux penchés vers l'avant.
	for x: float in xs:
		_stake(canvas, foot + Vector2(x + 7, 3), foot + Vector2(x - 6, -26), 5.0, stake.darkened(0.3), tint)
	var beam_from := foot + Vector2(-28, -8)
	var beam_to := foot + Vector2(28, -8)
	_beam(canvas, beam_from, beam_to, 8.0, color.darkened(0.1), tint)
	canvas.draw_circle(beam_to, 4.5, Relief.OUTLINE * tint, true, -1.0, true)
	canvas.draw_circle(beam_to, 3.2, color.lightened(0.3) * tint, true, -1.0, true)
	canvas.draw_line(beam_from + Vector2(2, -2), beam_to + Vector2(-4, -2), color.lightened(0.25) * tint, 1.5)
	for x: float in xs:
		_stake(canvas, foot + Vector2(x - 7, 5), foot + Vector2(x + 7, -24), 5.0, stake, tint)
	# Une corde qui les lie.
	for x: float in xs:
		canvas.draw_circle(foot + Vector2(x, -9), 2.0, Color(0.85, 0.75, 0.5) * tint, true, -1.0, true)


## Caserne : une tente de toile à la couleur du bâtiment, sa bannière, et un râtelier
## d'armes à côté.
static func _draw_barracks(canvas: CanvasItem, foot: Vector2, color: Color, tint: Color) -> void:
	Relief.draw_shadow(canvas, foot + Vector2(6, 3), 30.0, 12.0, 0.3 * tint.a)
	var width := 38.0
	var depth := 26.0
	var height := 28.0
	var d := DEPTH * depth
	var corner := foot + Vector2(-4, 0) - Vector2(width / 2.0, 0) - d / 2.0
	var apex := corner + Vector2(width / 2.0, -height)
	# Mât de la bannière, au fond, derrière la tente.
	var mast := apex + d
	canvas.draw_line(mast, mast + Vector2(0, -18), Relief.OUTLINE * tint, 2.5)
	var flag := PackedVector2Array([mast + Vector2(1, -18), mast + Vector2(13, -15), mast + Vector2(1, -11)])
	canvas.draw_colored_polygon(flag, Color(1.0, 0.35, 0.3) * tint)
	flag.append(flag[0])
	canvas.draw_polyline(flag, Relief.OUTLINE * tint, 1.2, true)
	# Pan droit dans l'ombre, puis la face avant, éclairée.
	var side := PackedVector2Array([corner + Vector2(width, 0), corner + Vector2(width, 0) + d, apex + d, apex])
	canvas.draw_colored_polygon(side, color.darkened(0.4) * tint)
	var front := PackedVector2Array([corner, corner + Vector2(width, 0), apex])
	canvas.draw_colored_polygon(front, color * tint)
	# Bandes de la toile.
	for t in [0.25, 0.75]:
		canvas.draw_line(corner + Vector2(width * t, 0), apex, color.darkened(0.15) * tint, 2.0)
	for t in [0.33, 0.66]:
		canvas.draw_line(corner + Vector2(width, 0) + d * t, apex + d * t, color.darkened(0.55) * tint, 1.5)
	# Entrée ouverte, un pan de toile replié.
	var door := PackedVector2Array([corner + Vector2(width * 0.36, 0), corner + Vector2(width * 0.64, 0),
		apex + Vector2(0, 11)])
	canvas.draw_colored_polygon(door, Color(0.1, 0.1, 0.16) * tint)
	canvas.draw_colored_polygon(PackedVector2Array([corner + Vector2(width * 0.5, 0), corner + Vector2(width * 0.64, 0),
		apex + Vector2(0, 11)]), color.lightened(0.25) * tint)
	side.append(side[0])
	canvas.draw_polyline(side, Relief.OUTLINE * tint, 2.0, true)
	front.append(front[0])
	canvas.draw_polyline(front, Relief.OUTLINE * tint, 2.0, true)
	canvas.draw_circle(apex, 2.5, Color(1.0, 0.82, 0.3) * tint, true, -1.0, true)
	# Râtelier : deux lances et un bouclier rond, à droite de la tente.
	var rack := foot + Vector2(22, 10)
	for x in [-2.0, 3.0]:
		_beam(canvas, rack + Vector2(x, 0), rack + Vector2(x + 2, -26), 2.0, WOOD, tint)
		canvas.draw_colored_polygon(PackedVector2Array([rack + Vector2(x, -26), rack + Vector2(x + 4.5, -26),
			rack + Vector2(x + 2.5, -33)]), Color(0.85, 0.87, 0.9) * tint)
	canvas.draw_circle(rack + Vector2(1, -9), 6.5, Relief.OUTLINE * tint, true, -1.0, true)
	canvas.draw_circle(rack + Vector2(1, -9), 5.0, color.darkened(0.15) * tint, true, -1.0, true)
	canvas.draw_circle(rack + Vector2(1, -9), 1.8, Color(1.0, 0.82, 0.3) * tint, true, -1.0, true)


# --- Pièces ---------------------------------------------------------------------

## Cristal d'essence debout, posé en `base` : deux faces, celle de gauche éclairée,
## cerné de sombre et nimbé de sa couleur.
static func draw_crystal(canvas: CanvasItem, base: Vector2, height: float, width: float, color: Color,
		tint := Color.WHITE, lean := 0.0) -> void:
	var up := Vector2(lean * height, -height)
	var tip := base + up
	var left := base + Vector2(-width / 2.0, 0) + up * 0.68
	var right := base + Vector2(width / 2.0, 0) + up * 0.62
	var bottom_left := base + Vector2(-width * 0.4, 0)
	var bottom_right := base + Vector2(width * 0.4, 0)
	var middle := base + Vector2(width * 0.05, 1.5)
	var outline := PackedVector2Array([tip, right, bottom_right, middle, bottom_left, left])
	canvas.draw_colored_polygon(Relief.ellipse(base + up * 0.5, width * 0.95, height * 0.6), Color(color, 0.18) * tint)
	canvas.draw_colored_polygon(outline, color.darkened(0.25) * tint)
	canvas.draw_colored_polygon(PackedVector2Array([tip, left, bottom_left, middle, base + up * 0.62 + Vector2(width * 0.05, 0)]),
		color.lightened(0.3) * tint)
	canvas.draw_line(tip + Vector2(-width * 0.12, height * 0.12), left + Vector2(width * 0.15, 0), Color(1, 1, 1, 0.75) * tint, 1.5)
	outline.append(outline[0])
	canvas.draw_polyline(outline, Relief.OUTLINE * tint, 2.0, true)


## Boîte posée au sol, centrée sur `foot` : façade, flanc droit dans l'ombre et dessus
## (s'il a une couleur). Renvoie le coin bas gauche de la façade.
static func _box(canvas: CanvasItem, foot: Vector2, width: float, depth: float, height: float, color: Color,
		tint: Color, top := Color.TRANSPARENT) -> Vector2:
	var d := DEPTH * depth
	var corner := foot - Vector2(width / 2.0, 0) - d / 2.0
	var faces: Array[PackedVector2Array] = [
		PackedVector2Array([corner, corner + Vector2(width, 0), corner + Vector2(width, -height), corner + Vector2(0, -height)]),
		PackedVector2Array([corner + Vector2(width, 0), corner + Vector2(width, 0) + d, corner + Vector2(width, -height) + d,
			corner + Vector2(width, -height)]),
	]
	var colors: Array[Color] = [color, color.darkened(0.38)]
	if top.a > 0.0:
		faces.append(PackedVector2Array([corner + Vector2(0, -height), corner + Vector2(width, -height),
			corner + Vector2(width, -height) + d, corner + Vector2(0, -height) + d]))
		colors.append(top)
	for i in faces.size():
		canvas.draw_colored_polygon(faces[i], colors[i] * tint)
	for face in faces:
		face.append(face[0])
		canvas.draw_polyline(face, Relief.OUTLINE * tint, 2.0, true)
	return corner


## Toit à deux pentes sur une boîte (coin bas gauche de la façade `corner`) : faîte
## parallèle à la façade, pan avant éclairé, pignon droit dans l'ombre.
static func _gable_roof(canvas: CanvasItem, corner: Vector2, width: float, depth: float, wall: float, rise: float,
		color: Color, gable_color: Color, tint: Color) -> void:
	var d := DEPTH * depth
	var overhang := 3.0
	var eave_left := corner + Vector2(-overhang, -wall + 2.0)
	var eave_right := corner + Vector2(width + overhang, -wall + 2.0)
	var ridge_left := corner + Vector2(-overhang, -wall - rise) + d / 2.0
	var ridge_right := corner + Vector2(width + overhang, -wall - rise) + d / 2.0
	var gable := PackedVector2Array([corner + Vector2(width, -wall), corner + Vector2(width, -wall) + d,
		corner + Vector2(width, -wall - rise) + d / 2.0])
	canvas.draw_colored_polygon(gable, gable_color.darkened(0.38) * tint)
	gable.append(gable[0])
	canvas.draw_polyline(gable, Relief.OUTLINE * tint, 2.0, true)
	# Rive du toit sur le pignon : l'épaisseur du pan du fond.
	_beam(canvas, ridge_right, corner + Vector2(width + overhang, -wall + 2.0) + d, 3.0, color.darkened(0.35), tint)
	var slope := PackedVector2Array([eave_left, eave_right, ridge_right, ridge_left])
	canvas.draw_colored_polygon(slope, color * tint)
	# Rangées de tuiles ou de bardeaux, et le faîte plus clair.
	for t in [0.33, 0.66]:
		canvas.draw_line(eave_left.lerp(ridge_left, t), eave_right.lerp(ridge_right, t), color.darkened(0.25) * tint, 1.5)
	canvas.draw_line(ridge_left + Vector2(2, 1.5), ridge_right + Vector2(-2, 1.5), color.lightened(0.3) * tint, 1.5)
	slope.append(slope[0])
	canvas.draw_polyline(slope, Relief.OUTLINE * tint, 2.0, true)


## Poutre ou perche de bois, cernée de sombre.
static func _beam(canvas: CanvasItem, from: Vector2, to: Vector2, width: float, color: Color, tint: Color) -> void:
	canvas.draw_line(from, to, Relief.OUTLINE * tint, width + 2.5, true)
	canvas.draw_line(from, to, color * tint, width, true)


## Pieu taillé en pointe, de `from` (en terre) à `to` (la pointe).
static func _stake(canvas: CanvasItem, from: Vector2, to: Vector2, width: float, color: Color, tint: Color) -> void:
	var dir := (to - from).normalized()
	var neck := to - dir * width * 1.4
	_beam(canvas, from, neck, width, color, tint)
	var side := dir.orthogonal() * width * 0.5
	var point := PackedVector2Array([neck + side, to, neck - side])
	canvas.draw_colored_polygon(point, color.lightened(0.3) * tint)
	canvas.draw_polyline(point, Relief.OUTLINE * tint, 1.5, true)


## Petite pierre arrondie, éclairée en haut à gauche.
static func _pebble(canvas: CanvasItem, center: Vector2, radius: float, color: Color, tint: Color) -> void:
	canvas.draw_colored_polygon(Relief.ellipse(center, radius + 1.5, radius * 0.8 + 1.5, 0.0, TAU, 12), Relief.OUTLINE * tint)
	canvas.draw_colored_polygon(Relief.ellipse(center, radius, radius * 0.8, 0.0, TAU, 12), color.darkened(0.1) * tint)
	canvas.draw_colored_polygon(Relief.ellipse(center - Vector2(radius, radius) * 0.25, radius * 0.5, radius * 0.35, 0.0, TAU, 10),
		color.lightened(0.25) * tint)
