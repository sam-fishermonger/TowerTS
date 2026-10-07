class_name DecorItem
extends Node2D
## Élément de décor debout de la vue de trois quarts (arbre, buisson, rocher), dessiné
## au-dessus de son pied (la position du nœud) et trié en profondeur avec les tours et
## les monstres. Poser une tour sur sa case l'abat (voir GameMap.occupy), sauf un rocher.

enum Kind { TREE, BUSH, ROCK }

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
	Relief.draw_shadow(self, Vector2(6, 4) * s, 26.0 * s, 10.0 * s, 0.3)
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
