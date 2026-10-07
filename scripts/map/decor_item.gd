class_name DecorItem
extends Node2D
## Élément de décor debout de la vue de trois quarts (arbre, maison, tombe, caisse…),
## dessiné au-dessus de son pied (la position du nœud) et trié en profondeur avec les
## tours et les monstres. Chaque monde a le sien (BiomeTheme). Poser une tour sur sa case
## l'abat (voir GameMap.occupy), sauf un rocher.

enum Kind { TREE, BUSH, ROCK, HIVE, EGGS, MUSHROOM, CRATE, BARREL, SCRAP, CHIMNEY, HOUSE, LAMP, FENCE,
	DEAD_TREE, TOMB, CROSS }

var kind := Kind.TREE
## Taille relative (1 = normale).
var scale_factor := 1.0
## Tirage de la forme : deux éléments de même graine sont identiques.
var shape_seed := 0
## Feuillage : sombre, moyen, clair.
var leaves: Array[Color] = [Color(0.2, 0.4, 0.13), Color(0.33, 0.58, 0.2), Color(0.55, 0.76, 0.27)]
var rock_color := Color(0.55, 0.55, 0.58)


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = shape_seed
	match kind:
		Kind.TREE:
			_draw_tree(rng)
		Kind.BUSH:
			_draw_bush(rng)
		Kind.ROCK:
			_draw_rock(rng)
		Kind.HIVE:
			_draw_hive(rng)
		Kind.EGGS:
			_draw_eggs(rng)
		Kind.MUSHROOM:
			_draw_mushrooms(rng)
		Kind.CRATE:
			_draw_crates(rng)
		Kind.BARREL:
			_draw_barrels(rng)
		Kind.SCRAP:
			_draw_scrap(rng)
		Kind.CHIMNEY:
			_draw_chimney(rng)
		Kind.HOUSE:
			_draw_house(rng)
		Kind.LAMP:
			_draw_lamp()
		Kind.FENCE:
			_draw_fence(rng)
		Kind.DEAD_TREE:
			_draw_dead_tree(rng)
		Kind.TOMB:
			_draw_tomb(rng)
		Kind.CROSS:
			_draw_cross(rng)


func _draw_tree(rng: RandomNumberGenerator) -> void:
	var s := scale_factor
	var radius := 26.0 * s
	Relief.draw_shadow(self, Vector2(3, 1) * s, radius * 0.95, radius * 0.38, 0.3)
	# Tronc, un peu évasé au pied.
	var trunk := Color(0.42, 0.27, 0.15)
	var height := 14.0 * s
	var points := PackedVector2Array([Vector2(-5, 1) * s, Vector2(-3, -height), Vector2(3, -height), Vector2(5, 1) * s])
	draw_colored_polygon(points, trunk)
	draw_polyline(points, Relief.OUTLINE, 2.0, true)
	draw_line(Vector2(1, -2) * s, Vector2(1.5, -height + 2), trunk.darkened(0.35), 2.0)
	# Feuillage : des boules qui se chevauchent, contour d'abord, puis volume éclairé en haut à gauche.
	var center := Vector2(0, -height - radius * 0.75)
	var blobs: Array[Vector3] = [Vector3(0, 0, radius * 0.72)]
	for i in rng.randi_range(5, 7):
		var angle := TAU * i / 6.0 + rng.randf_range(-0.4, 0.4)
		var offset := Vector2(cos(angle) * radius * 0.5, sin(angle) * radius * 0.38)
		blobs.append(Vector3(offset.x, offset.y, radius * rng.randf_range(0.45, 0.6)))
	_draw_blobs(center, blobs, rng)


func _draw_bush(rng: RandomNumberGenerator) -> void:
	var s := scale_factor
	var radius := 12.0 * s
	Relief.draw_shadow(self, Vector2(2, 1) * s, radius * 1.2, radius * 0.42, 0.25)
	var blobs: Array[Vector3] = []
	for i in rng.randi_range(3, 4):
		var x := lerpf(-radius * 0.8, radius * 0.8, float(i) / 3.0) + rng.randf_range(-2, 2)
		blobs.append(Vector3(x, rng.randf_range(-3, 1) * s, radius * rng.randf_range(0.55, 0.75)))
	_draw_blobs(Vector2(0, -radius * 0.55), blobs, rng)


func _draw_blobs(center: Vector2, blobs: Array[Vector3], rng: RandomNumberGenerator) -> void:
	for blob in blobs:
		draw_circle(center + Vector2(blob.x, blob.y), blob.z + 2.0, Relief.OUTLINE, true, -1.0, true)
	for blob in blobs:
		draw_circle(center + Vector2(blob.x, blob.y), blob.z, leaves[0], true, -1.0, true)
	for blob in blobs:
		draw_circle(center + Vector2(blob.x, blob.y) - Vector2(blob.z, blob.z) * 0.14, blob.z * 0.82, leaves[1], true, -1.0, true)
	for blob in blobs:
		if blob.y < 0.0 or rng.randf() < 0.5:
			draw_circle(center + Vector2(blob.x, blob.y) - Vector2(blob.z, blob.z) * 0.36, blob.z * 0.4, leaves[2], true, -1.0, true)


func _draw_rock(rng: RandomNumberGenerator) -> void:
	var s := scale_factor
	Relief.draw_shadow(self, Vector2(2, 3) * s, 26.0 * s, 9.0 * s, 0.3)
	for i in 3:
		var x := (i - 1) * 13.0 * s + rng.randf_range(-3, 3)
		var r := (14.0 if i == 1 else 10.0) * s
		var base := Vector2(x, 4.0 * s - (4.0 if i == 1 else 0.0))
		var points := PackedVector2Array()
		for j in 7:
			var angle := PI + PI * j / 6.0
			var radius := r * rng.randf_range(0.85, 1.1)
			points.append(base + Vector2(cos(angle) * radius, sin(angle) * radius * 1.15))
		draw_colored_polygon(points, rock_color.darkened(0.15))
		var top := PackedVector2Array()
		for point in points:
			top.append(base + (point - base) * 0.72 - Vector2(r * 0.18, r * 0.2))
		draw_colored_polygon(top, rock_color.lightened(0.15))
		points.append(points[0])
		draw_polyline(points, Relief.OUTLINE, 2.0, true)


# --- Formes communes ----------------------------------------------------------

## Polygone rempli et cerné.
func _shape(points: PackedVector2Array, color: Color, width := 2.0) -> void:
	draw_colored_polygon(points, color)
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, Relief.OUTLINE, width, true)


## Boîte vue de trois quarts posée sur `foot` : face avant, dessus plus clair.
func _box(foot: Vector2, width: float, height: float, depth: float, color: Color) -> void:
	var left := foot.x - width / 2.0
	var right := foot.x + width / 2.0
	_shape(PackedVector2Array([Vector2(left, foot.y - height - depth), Vector2(right, foot.y - height - depth),
		Vector2(right, foot.y - height), Vector2(left, foot.y - height)]), color.lightened(0.2))
	_shape(PackedVector2Array([Vector2(left, foot.y - height), Vector2(right, foot.y - height), Vector2(right, foot.y),
		Vector2(left, foot.y)]), color)


# --- La Ruche -----------------------------------------------------------------

## Termitière : un cône bosselé de terre, percé de trous.
func _draw_hive(rng: RandomNumberGenerator) -> void:
	var s := scale_factor
	var earth := Color(0.62, 0.47, 0.32)
	Relief.draw_shadow(self, Vector2(2, 2) * s, 22.0 * s, 8.0 * s, 0.3)
	for i in 2:
		var x := (-7.0 + i * 13.0) * s
		var h := (44.0 if i == 0 else 30.0) * s * rng.randf_range(0.9, 1.1)
		var w := (14.0 if i == 0 else 11.0) * s
		var points := PackedVector2Array([Vector2(x - w, 2), Vector2(x - w * 0.7, -h * 0.5), Vector2(x - w * 0.3, -h),
			Vector2(x + w * 0.3, -h * 0.95), Vector2(x + w * 0.75, -h * 0.45), Vector2(x + w, 2)])
		_shape(points, earth.darkened(0.08 * i))
		draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.7, -h * 0.5), Vector2(x - w * 0.3, -h),
			Vector2(x - w * 0.05, -h * 0.4), Vector2(x - w * 0.4, 0)]), earth.lightened(0.15))
		for j in 2:
			draw_colored_polygon(Relief.ellipse(Vector2(x + rng.randf_range(-w, w) * 0.4, -h * rng.randf_range(0.3, 0.7)),
				2.5 * s, 3.5 * s, 0.0, TAU, 10), Color(0.15, 0.1, 0.07))


## Œufs d'insectes, translucides, en grappe.
func _draw_eggs(rng: RandomNumberGenerator) -> void:
	var s := scale_factor
	Relief.draw_shadow(self, Vector2(1, 2) * s, 16.0 * s, 6.0 * s, 0.25)
	var egg := Color(0.88, 0.9, 0.72)
	for i in rng.randi_range(3, 5):
		var at := Vector2(rng.randf_range(-10, 10), rng.randf_range(-2, 3)) * s
		var r := rng.randf_range(4.5, 6.5) * s
		_shape(Relief.ellipse(at - Vector2(0, r * 1.2), r, r * 1.3, 0.0, TAU, 16), egg, 1.5)
		draw_colored_polygon(Relief.ellipse(at - Vector2(r * 0.3, r * 1.7), r * 0.35, r * 0.45, 0.0, TAU, 10),
			Color(1, 1, 1, 0.6))
		draw_circle(at - Vector2(-r * 0.1, r * 1.0), r * 0.3, Color(0.55, 0.65, 0.3, 0.6), true, -1.0, true)


## Champignons : chapeaux ronds tachetés (lumineux à la Nécropole, selon le feuillage).
func _draw_mushrooms(rng: RandomNumberGenerator) -> void:
	var s := scale_factor
	Relief.draw_shadow(self, Vector2(1, 1) * s, 13.0 * s, 5.0 * s, 0.25)
	var cap := leaves[2].lerp(Color(0.85, 0.3, 0.25), 0.6)
	for i in rng.randi_range(2, 3):
		var at := Vector2(-8 + i * 8 + rng.randf_range(-2, 2), rng.randf_range(-1, 2)) * s
		var h := rng.randf_range(7, 12) * s
		_shape(PackedVector2Array([at + Vector2(-2, 0), at + Vector2(-1.5, -h), at + Vector2(1.5, -h), at + Vector2(2, 0)]),
			Color(0.92, 0.88, 0.78), 1.5)
		var r := rng.randf_range(5, 7) * s
		var top := Relief.ellipse(at - Vector2(0, h), r, r * 0.8, PI, TAU, 12)
		top.append(at + Vector2(r, -h + 1))
		top.append(at + Vector2(-r, -h + 1))
		_shape(top, cap, 1.5)
		draw_circle(at + Vector2(-r * 0.3, -h - r * 0.4), r * 0.18, Color(1, 1, 1, 0.8), true, -1.0, true)


# --- La Fonderie --------------------------------------------------------------

func _draw_crates(rng: RandomNumberGenerator) -> void:
	var s := scale_factor
	var wood := Color(0.66, 0.48, 0.28)
	Relief.draw_shadow(self, Vector2(2, 2) * s, 20.0 * s, 7.0 * s, 0.3)
	var count := rng.randi_range(1, 3)
	var spots := [Vector2(-7, 0), Vector2(8, 3), Vector2(-1, -15)]
	for i in count:
		var foot: Vector2 = spots[i] * s
		var size := 14.0 * s
		_box(foot, size, size, size * 0.4, wood.darkened(0.1 * i))
		draw_line(foot + Vector2(-size / 2.0 + 2, -2), foot + Vector2(size / 2.0 - 2, -size + 2), wood.darkened(0.4), 1.5)
		draw_line(foot + Vector2(-size / 2.0 + 2, -size + 2), foot + Vector2(size / 2.0 - 2, -2), wood.darkened(0.4), 1.5)


func _draw_barrels(rng: RandomNumberGenerator) -> void:
	var s := scale_factor
	var colors := [Color(0.75, 0.25, 0.2), Color(0.3, 0.45, 0.6), Color(0.85, 0.65, 0.2)]
	Relief.draw_shadow(self, Vector2(2, 2) * s, 18.0 * s, 6.5 * s, 0.3)
	for i in rng.randi_range(1, 2):
		var foot := Vector2(-6 + i * 12, i * 3) * s
		var color: Color = colors[rng.randi_range(0, 2)]
		var top := Relief.draw_cylinder(self, foot, 7.0 * s, 3.5 * s, 18.0 * s, color)
		draw_polyline(Relief.ellipse(top + Vector2(0, 6 * s), 7.0 * s, 3.5 * s, 0.0, PI, 10), Relief.OUTLINE, 1.5, true)
		draw_polyline(Relief.ellipse(top + Vector2(0, 13 * s), 7.0 * s, 3.5 * s, 0.0, PI, 10), Relief.OUTLINE, 1.5, true)
		draw_circle(top + Vector2(-2, 0), 1.5 * s, Relief.OUTLINE, true, -1.0, true)


## Tas de ferraille : plaques, poutre et engrenage.
func _draw_scrap(rng: RandomNumberGenerator) -> void:
	var s := scale_factor
	var metal := Color(0.55, 0.55, 0.58)
	Relief.draw_shadow(self, Vector2(1, 2) * s, 20.0 * s, 7.0 * s, 0.3)
	_shape(PackedVector2Array([Vector2(-18, 2) * s, Vector2(-8, -10) * s, Vector2(4, -12) * s, Vector2(16, 2) * s]),
		Color(0.5, 0.36, 0.26))
	_shape(PackedVector2Array([Vector2(-12, -6) * s, Vector2(10, -16) * s, Vector2(12, -12) * s, Vector2(-10, -2) * s]),
		metal.darkened(0.2))
	var gear := Vector2(rng.randf_range(-4, 4), -14) * s
	var teeth := PackedVector2Array()
	for i in 16:
		var angle := TAU * i / 16.0
		var r := (8.0 if i % 2 == 0 else 6.0) * s
		teeth.append(gear + Vector2(cos(angle) * r, sin(angle) * r * 0.85))
	_shape(teeth, metal)
	draw_circle(gear, 2.5 * s, Relief.OUTLINE, true, -1.0, true)


## Cheminée d'usine en briques, avec sa fumée.
func _draw_chimney(rng: RandomNumberGenerator) -> void:
	var s := scale_factor
	var brick := Color(0.6, 0.3, 0.22)
	Relief.draw_shadow(self, Vector2(2, 2) * s, 14.0 * s, 5.5 * s, 0.32)
	var top := Relief.draw_cylinder(self, Vector2.ZERO, 9.0 * s, 4.5 * s, 50.0 * s, brick)
	for y in [12.0, 24.0, 36.0]:
		draw_polyline(Relief.ellipse(Vector2(0, -y * s), 9.0 * s, 4.5 * s, 0.2, PI - 0.2, 10), brick.darkened(0.4), 1.2, true)
	draw_colored_polygon(Relief.ellipse(top, 6.5 * s, 3.0 * s), Color(0.1, 0.08, 0.08))
	for i in 3:
		var puff := top + Vector2(5 + i * 6 + rng.randf_range(-2, 2), -8 - i * 9) * s
		draw_circle(puff, (5.0 + i * 2.0) * s, Color(0.75, 0.73, 0.72, 0.75 - i * 0.18), true, -1.0, true)


# --- La Cité ------------------------------------------------------------------

## Petite maison : murs crépis, toit de tuiles, porte et fenêtre éclairée.
func _draw_house(rng: RandomNumberGenerator) -> void:
	var s := scale_factor
	var walls: Color = [Color(0.93, 0.87, 0.72), Color(0.85, 0.82, 0.78), Color(0.9, 0.78, 0.62)][rng.randi_range(0, 2)]
	var roof: Color = [Color(0.75, 0.3, 0.22), Color(0.35, 0.4, 0.55), Color(0.55, 0.35, 0.25)][rng.randi_range(0, 2)]
	var w := 34.0 * s
	var h := 20.0 * s
	Relief.draw_shadow(self, Vector2(2, 2) * s, w * 0.65, 8.0 * s, 0.32)
	# Pignon de côté (à droite), puis la façade.
	_shape(PackedVector2Array([Vector2(w / 2, 0), Vector2(w / 2 + 8 * s, -6 * s), Vector2(w / 2 + 8 * s, -h - 6 * s),
		Vector2(w / 2, -h)]), walls.darkened(0.2))
	_shape(PackedVector2Array([Vector2(-w / 2, 0), Vector2(w / 2, 0), Vector2(w / 2, -h), Vector2(-w / 2, -h)]), walls)
	_shape(PackedVector2Array([Vector2(-w / 2 - 3 * s, -h + 1), Vector2(-w / 2 + 4 * s, -h - 16 * s),
		Vector2(w / 2 + 12 * s, -h - 22 * s), Vector2(w / 2 + 5 * s, -h - 3 * s)]), roof)
	draw_line(Vector2(-w / 2 + 4 * s, -h - 16 * s), Vector2(w / 2 + 12 * s, -h - 22 * s), roof.lightened(0.3), 2.0)
	_shape(PackedVector2Array([Vector2(-4, 0) * s, Vector2(-4, -11) * s, Vector2(3, -11) * s, Vector2(3, 0) * s]),
		Color(0.45, 0.28, 0.16), 1.5)
	var window := Rect2(Vector2(8, -15) * s, Vector2(7, 7) * s)
	draw_rect(window, Color(1.0, 0.85, 0.45))
	draw_rect(window, Relief.OUTLINE, false, 1.5)
	draw_rect(Rect2(Vector2(-14, -15) * s, Vector2(7, 7) * s), Color(0.55, 0.75, 0.9))
	draw_rect(Rect2(Vector2(-14, -15) * s, Vector2(7, 7) * s), Relief.OUTLINE, false, 1.5)


## Réverbère.
func _draw_lamp() -> void:
	var s := scale_factor
	Relief.draw_shadow(self, Vector2(1, 1) * s, 6.0 * s, 2.5 * s, 0.3)
	draw_line(Vector2(0, 0), Vector2(0, -32 * s), Relief.OUTLINE, 4.5)
	draw_line(Vector2(0, 0), Vector2(0, -32 * s), Color(0.25, 0.27, 0.3), 2.5)
	draw_circle(Vector2(0, -36 * s), 9.0 * s, Color(1.0, 0.9, 0.5, 0.25), true, -1.0, true)
	_shape(PackedVector2Array([Vector2(-4, -32) * s, Vector2(4, -32) * s, Vector2(5, -40) * s, Vector2(-5, -40) * s]),
		Color(1.0, 0.88, 0.5), 1.5)
	_shape(PackedVector2Array([Vector2(-6, -40) * s, Vector2(6, -40) * s, Vector2(0, -45) * s]), Color(0.25, 0.27, 0.3), 1.5)


## Barrière de bois.
func _draw_fence(rng: RandomNumberGenerator) -> void:
	var s := scale_factor
	var wood := Color(0.72, 0.55, 0.35)
	var slope := rng.randf_range(-0.2, 0.2)
	for x in [-14.0, -5.0, 4.0, 13.0]:
		var foot := Vector2(x, x * slope) * s
		_shape(PackedVector2Array([foot + Vector2(-2, 0), foot + Vector2(-2, -14) * s, foot + Vector2(0, -16) * s,
			foot + Vector2(2, -14) * s, foot + Vector2(2, 0)]), wood, 1.5)
	for y in [5.0, 11.0]:
		var from := Vector2(-16, -16 * slope - y) * s
		var to := Vector2(15, 15 * slope - y) * s
		draw_line(from, to, Relief.OUTLINE, 4.0)
		draw_line(from, to, wood.darkened(0.1), 2.0)


# --- La Nécropole -------------------------------------------------------------

## Arbre mort : tronc tordu et branches nues.
func _draw_dead_tree(rng: RandomNumberGenerator) -> void:
	var s := scale_factor
	var bark := Color(0.32, 0.27, 0.27) if leaves[1].b > leaves[1].g else Color(0.4, 0.32, 0.25)
	Relief.draw_shadow(self, Vector2(2, 1) * s, 12.0 * s, 4.5 * s, 0.3)
	var trunk := PackedVector2Array([Vector2(-5, 1) * s, Vector2(-3, -20) * s, Vector2(-6, -38) * s, Vector2(-1, -40) * s,
		Vector2(2, -22) * s, Vector2(5, 1) * s])
	_shape(trunk, bark)
	for branch in 4:
		var from := Vector2(rng.randf_range(-4, 2), rng.randf_range(-36, -18)) * s
		var side := -1.0 if branch % 2 == 0 else 1.0
		var mid := from + Vector2(side * rng.randf_range(7, 11), rng.randf_range(-9, -4)) * s
		var tip := mid + Vector2(side * rng.randf_range(3, 7), rng.randf_range(-8, -3)) * s
		var points := PackedVector2Array([from, mid, tip])
		draw_polyline(points, Relief.OUTLINE, 5.0, true)
		draw_polyline(points, bark, 2.5, true)


## Pierre tombale arrondie, un peu penchée, avec une croix gravée.
func _draw_tomb(rng: RandomNumberGenerator) -> void:
	var s := scale_factor
	var stone := Color(0.6, 0.6, 0.64)
	Relief.draw_shadow(self, Vector2(2, 1) * s, 12.0 * s, 4.5 * s, 0.32)
	var tilt := rng.randf_range(-0.12, 0.12)
	var w := 9.0 * s
	var h := 16.0 * s
	var points := PackedVector2Array([Vector2(-w, 0), Vector2(-w + h * tilt, -h)])
	points.append_array(Relief.ellipse(Vector2(h * tilt, -h), w, w * 0.9, PI, TAU, 10))
	points.append(Vector2(w, 0))
	_shape(points, stone)
	draw_line(Vector2(h * tilt * 1.2, -h - 2 * s), Vector2(h * tilt * 0.5, -h * 0.35), stone.darkened(0.4), 2.0)
	draw_line(Vector2(-4 * s + h * tilt, -h * 0.85), Vector2(4 * s + h * tilt, -h * 0.85), stone.darkened(0.4), 2.0)
	# Petit tertre de terre devant.
	_shape(Relief.ellipse(Vector2(0, 3) * s, w * 1.1, 3.0 * s, 0.0, TAU, 12), Color(0.35, 0.3, 0.28), 1.5)


## Croix de bois plantée.
func _draw_cross(rng: RandomNumberGenerator) -> void:
	var s := scale_factor
	var wood := Color(0.48, 0.38, 0.3)
	Relief.draw_shadow(self, Vector2(1, 1) * s, 8.0 * s, 3.0 * s, 0.3)
	var tilt := rng.randf_range(-3.0, 3.0) * s
	_shape(PackedVector2Array([Vector2(-2.5, 0) * s, Vector2(-2.5 * s + tilt, -26 * s), Vector2(2.5 * s + tilt, -26 * s),
		Vector2(2.5, 0) * s]), wood, 1.5)
	_shape(PackedVector2Array([Vector2(-9 * s + tilt * 0.7, -20 * s), Vector2(9 * s + tilt * 0.7, -20 * s),
		Vector2(9 * s + tilt * 0.7, -15 * s), Vector2(-9 * s + tilt * 0.7, -15 * s)]), wood, 1.5)
