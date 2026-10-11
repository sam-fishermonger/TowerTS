class_name BaseRelief
## QG du joueur dans la vue de trois quarts, au bout du chemin (ou sur sa case dans un
## niveau libre) : dessiné en code comme les tours et les bâtiments (BuildingRelief),
## vu de face, flanc droit dans l'ombre, cerné de sombre. Le pied du QG est en `at`.

const STONE := BuildingRelief.STONE
const ROOF := Color(0.25, 0.42, 0.8)
const GOLD := Color(1.0, 0.8, 0.2)
const GROUND := Color(0.5, 0.42, 0.32)
## Demi-largeur du dessin : le QG se décale pour tenir dans l'écran au bord de la carte.
const HALF_WIDTH := 56.0

## Agrandissement du dessin, pour qu'il domine les tours voisines.
const SCALE := 1.18


## Forteresse : une enceinte carrée vue de biais, quatre tours rondes aux toits bleus,
## un donjon dans la cour et sa bannière, une porte à herse. Dessinée agrandie autour de
## `at` (le repère du canevas revient ensuite à zéro).
static func draw(canvas: CanvasItem, at: Vector2) -> void:
	canvas.draw_set_transform(at, 0.0, Vector2.ONE * SCALE)
	_draw_fortress(canvas)
	canvas.draw_set_transform(Vector2.ZERO)


static func _draw_fortress(canvas: CanvasItem) -> void:
	var at := Vector2.ZERO
	var width := 56.0
	var depth := 30.0
	var wall := 18.0
	var d := BuildingRelief.DEPTH * depth
	var corner := at - Vector2(width / 2.0, 0) - d / 2.0 + Vector2(0, 2)
	Relief.draw_shadow(canvas, at + Vector2(8, 6), 46.0, 17.0, 0.35)
	var top_left := corner + Vector2(0, -wall)
	var top_right := corner + Vector2(width, -wall)
	# Flanc droit, dans l'ombre.
	var side := PackedVector2Array([corner + Vector2(width, 0), corner + Vector2(width, 0) + d, top_right + d, top_right])
	_face(canvas, side, STONE.darkened(0.38))
	# Chemin de ronde, et la cour en contrebas avec le pied du mur du fond.
	_face(canvas, PackedVector2Array([top_left, top_right, top_right + d, top_left + d]), STONE.lightened(0.15))
	var inset := 5.0
	var yard := PackedVector2Array([top_left + Vector2(inset, 0) + d * 0.18, top_right + Vector2(-inset, 0) + d * 0.18,
		top_right + Vector2(-inset, 0) + d * 0.84, top_left + Vector2(inset, 0) + d * 0.84])
	canvas.draw_colored_polygon(yard, GROUND)
	canvas.draw_colored_polygon(PackedVector2Array([yard[3], yard[2], yard[2] + Vector2(0, 6), yard[3] + Vector2(0, 6)]),
		STONE.darkened(0.2))
	yard.append(yard[0])
	canvas.draw_polyline(yard, Color(Relief.OUTLINE, 0.6), 1.5, true)
	# Tours du fond.
	for at_corner in [top_left + d, top_right + d]:
		_round_tower(canvas, at_corner + Vector2(0, wall), 8.5, 4.5, wall + 16.0, 11.5, 18.0)
	# Donjon au milieu de la cour, toit en pavillon et bannière.
	var keep_foot := top_left + Vector2(width / 2.0, 0) + d * 0.55 + Vector2(-2, 6)
	var keep_corner := BuildingRelief._box(canvas, keep_foot, 20.0, 12.0, 22.0, STONE.lightened(0.05), Color.WHITE)
	canvas.draw_rect(Rect2(keep_corner + Vector2(7, -17), Vector2(5, 7)), BuildingRelief.WINDOW)
	canvas.draw_rect(Rect2(keep_corner + Vector2(7, -17), Vector2(5, 7)), Relief.OUTLINE, false, 1.5)
	var apex := _pyramid(canvas, keep_corner + Vector2(0, -22), 20.0, 12.0, 16.0)
	_flag(canvas, apex, 14.0)
	# Façade, créneaux et porte.
	_face(canvas, PackedVector2Array([corner, corner + Vector2(width, 0), top_right, top_left]), STONE)
	_merlons(canvas, top_left, top_right, 4)
	_gate(canvas, corner + Vector2(width / 2.0, 0), 14.0, 15.0)
	# Tours de devant.
	for at_corner in [corner, corner + Vector2(width, 0)]:
		_round_tower(canvas, at_corner + Vector2(0, 2), 9.5, 5.0, wall + 14.0, 12.5, 20.0)


# --- Pièces ---------------------------------------------------------------------

static func _face(canvas: CanvasItem, face: PackedVector2Array, color: Color) -> void:
	canvas.draw_colored_polygon(face, color)
	face.append(face[0])
	canvas.draw_polyline(face, Relief.OUTLINE, 2.0, true)


## Tour ronde posée en `foot`, coiffée d'un toit conique bleu. Renvoie la pointe du toit.
static func _round_tower(canvas: CanvasItem, foot: Vector2, rx: float, ry: float, height: float, roof_rx: float,
		rise: float) -> Vector2:
	var top := Relief.draw_cylinder(canvas, foot, rx, ry, height, STONE)
	canvas.draw_rect(Rect2(foot + Vector2(-2, -height * 0.62), Vector2(3, 6)), Relief.OUTLINE)
	return _cone(canvas, top + Vector2(0, 2), roof_rx, roof_rx * 0.42, rise)


## Toit conique bleu sur `base` (centre de son bord), pan gauche éclairé. Renvoie la pointe.
static func _cone(canvas: CanvasItem, base: Vector2, rx: float, ry: float, rise: float) -> Vector2:
	var apex := base + Vector2(0, -rise)
	var cone := PackedVector2Array([apex])
	cone.append_array(Relief.ellipse(base, rx, ry, 0.0, PI, 14))
	canvas.draw_colored_polygon(cone, ROOF)
	var lit := PackedVector2Array([apex])
	lit.append_array(Relief.ellipse(base, rx, ry, PI * 0.62, PI, 6))
	canvas.draw_colored_polygon(lit, ROOF.lightened(0.22))
	canvas.draw_polyline(Relief.ellipse(base, rx * 0.97, ry * 0.97, 0.15, PI - 0.15, 12), ROOF.darkened(0.3), 2.0, true)
	cone.append(apex)
	canvas.draw_polyline(cone, Relief.OUTLINE, 2.0, true)
	return apex


## Toit en pavillon bleu sur une boîte (coin avant gauche de son haut `corner`) : pan
## avant éclairé, pan droit dans l'ombre. Renvoie la pointe.
static func _pyramid(canvas: CanvasItem, corner: Vector2, width: float, depth: float, rise: float) -> Vector2:
	var d := BuildingRelief.DEPTH * depth
	var overhang := Vector2(2.5, 0)
	var front_left := corner - overhang + Vector2(0, 1)
	var front_right := corner + Vector2(width, 0) + overhang + Vector2(0, 1)
	var back_right := front_right + d
	var apex := corner + Vector2(width / 2.0, -rise) + d / 2.0
	_face(canvas, PackedVector2Array([front_right, back_right, apex]), ROOF.darkened(0.3))
	_face(canvas, PackedVector2Array([front_left, front_right, apex]), ROOF.lightened(0.08))
	return apex


## Mât et fanion doré au-dessus de `from`.
static func _flag(canvas: CanvasItem, from: Vector2, height: float, size := 1.0) -> void:
	var top := from + Vector2(0, -height)
	canvas.draw_line(from, top, Relief.OUTLINE, 2.0)
	var flag := PackedVector2Array([top, top + Vector2(12, 4) * size, top + Vector2(0, 8) * size])
	canvas.draw_colored_polygon(flag, GOLD)
	flag.append(flag[0])
	canvas.draw_polyline(flag, Relief.OUTLINE, 1.2, true)


## Créneaux le long d'un bord du haut de mur, de `from` à `to`.
static func _merlons(canvas: CanvasItem, from: Vector2, to: Vector2, count: int) -> void:
	var step := (to.x - from.x) / count
	var width := step * 0.55
	var d := BuildingRelief.DEPTH * 3.0
	for i in count:
		var left := from + Vector2(step * (i + 0.5) - width / 2.0, 0)
		var front := Rect2(left + Vector2(0, -5), Vector2(width, 5))
		var top := PackedVector2Array([front.position, front.position + Vector2(width, 0), front.position + Vector2(width, 0) + d,
			front.position + d])
		canvas.draw_colored_polygon(top, STONE.lightened(0.2))
		canvas.draw_rect(front, STONE)
		top.append(top[0])
		canvas.draw_polyline(top, Relief.OUTLINE, 1.2, true)
		canvas.draw_rect(front, Relief.OUTLINE, false, 1.2)


## Porte voûtée et sa herse, centrée sur `foot` (le bas de la façade).
static func _gate(canvas: CanvasItem, foot: Vector2, width: float, height: float) -> void:
	var half := width / 2.0
	var arch := PackedVector2Array([foot + Vector2(-half, 0), foot + Vector2(-half, -height + half)])
	arch.append_array(Relief.ellipse(foot + Vector2(0, -height + half), half, half, PI, TAU, 10))
	arch.append(foot + Vector2(half, 0))
	canvas.draw_colored_polygon(arch, Color(0.14, 0.09, 0.06))
	for x in [-half * 0.5, 0.0, half * 0.5]:
		canvas.draw_line(foot + Vector2(x, -height + 2.0 + absf(x) * 0.4), foot + Vector2(x, -2), Color(0.45, 0.42, 0.4), 1.2)
	for y in [-height * 0.6, -height * 0.3]:
		canvas.draw_line(foot + Vector2(-half + 1.0, y), foot + Vector2(half - 1.0, y), Color(0.45, 0.42, 0.4), 1.2)
	canvas.draw_polyline(arch, Relief.OUTLINE, 2.0, true)
