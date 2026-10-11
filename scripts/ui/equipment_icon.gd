class_name EquipmentIcon
extends Control
## Badge d'un objet d'équipement (Equipment) ou d'un coffret : un carré teinté de la
## couleur de sa rareté, avec un petit dessin de l'objet. Dessiné en code, sans police de
## symboles (la version web n'a pas de police de secours).

## Dessin de l'objet (Equipment.DEFINITIONS, `icon`), ou "box" pour un coffret.
var icon := "box":
	set(value):
		icon = value
		queue_redraw()
var rarity := Equipment.COMMUN:
	set(value):
		rarity = value
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var color := Equipment.rarity_color(rarity)
	var side := minf(size.x, size.y)
	var rect := Rect2((size - Vector2.ONE * side) / 2.0, Vector2.ONE * side)
	draw_rect(rect, Color(color, 0.18))
	draw_rect(rect, color, false, maxf(1.0, side / 24.0))
	var c := size / 2.0
	var r := side * 0.32
	var ink := color.lightened(0.35)
	var width := maxf(1.5, side / 16.0)
	match icon:
		"powder":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-r, r * 0.8), c + Vector2(r, r * 0.8),
				c + Vector2(0, -r * 0.6)]), ink)
			for offset in [Vector2(-0.5, -0.9), Vector2(0.15, -1.0), Vector2(0.6, -0.7)]:
				draw_circle(c + offset * r, width * 0.6, ink)
		"lens":
			draw_arc(c + Vector2(-0.15, -0.15) * r, r * 0.65, 0.0, TAU, 24, ink, width)
			draw_line(c + Vector2(0.32, 0.32) * r, c + Vector2(0.95, 0.95) * r, ink, width * 1.6)
		"gear":
			for i in 8:
				var direction := Vector2.from_angle(i * TAU / 8.0)
				draw_line(c + direction * r * 0.55, c + direction * r, ink, width * 1.8)
			draw_circle(c, r * 0.7, ink)
			draw_circle(c, r * 0.28, Color(color, 0.18).blend(Color(0, 0, 0, 0.6)))
		"crosshair":
			draw_arc(c, r * 0.7, 0.0, TAU, 24, ink, width)
			for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
				draw_line(c + direction * r * 0.3, c + direction * r, ink, width)
			draw_circle(c, width * 0.7, ink)
		"crown":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-r, r * 0.6), c + Vector2(-r, -r * 0.5),
				c + Vector2(-r * 0.5, 0), c + Vector2(0, -r * 0.8), c + Vector2(r * 0.5, 0),
				c + Vector2(r, -r * 0.5), c + Vector2(r, r * 0.6)]), ink)
		"wing":
			for i in 3:
				var y := (i - 1) * r * 0.55
				draw_polyline(PackedVector2Array([c + Vector2(-r, y + r * 0.35), c + Vector2(0, y - r * 0.2),
					c + Vector2(r, y + r * 0.35)]), ink, width)
		"flame":
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.55, -r * 0.1),
				c + Vector2(r * 0.7, r * 0.45), c + Vector2(r * 0.35, r * 0.9), c + Vector2(-r * 0.35, r * 0.9),
				c + Vector2(-r * 0.7, r * 0.45), c + Vector2(-r * 0.4, -r * 0.05), c + Vector2(-r * 0.1, r * 0.1)]), ink)
		"snow":
			for i in 3:
				var direction := Vector2.from_angle(i * PI / 3.0 + PI / 2.0)
				draw_line(c - direction * r, c + direction * r, ink, width)
				for flip: float in [-1.0, 1.0]:
					var tip: Vector2 = c + direction * r * 0.6 * flip
					draw_line(tip, tip + direction.rotated(0.8) * r * 0.3 * flip, ink, width * 0.7)
					draw_line(tip, tip + direction.rotated(-0.8) * r * 0.3 * flip, ink, width * 0.7)
		"eye":
			var points := PackedVector2Array()
			for i in 17:
				var t := i / 16.0
				points.append(c + Vector2(lerpf(-r, r, t), -sin(t * PI) * r * 0.6))
			for i in range(15, 0, -1):
				var t := i / 16.0
				points.append(c + Vector2(lerpf(-r, r, t), sin(t * PI) * r * 0.6))
			points.append(points[0])
			draw_polyline(points, ink, width)
			draw_circle(c, r * 0.3, ink)
		"bomb":
			draw_circle(c + Vector2(-0.1, 0.15) * r, r * 0.7, ink)
			draw_line(c + Vector2(0.35, -0.4) * r, c + Vector2(0.75, -0.85) * r, ink, width)
			draw_circle(c + Vector2(0.85, -0.95) * r, width, Color(1.0, 0.85, 0.3))
		"bullet":
			draw_rect(Rect2(c + Vector2(-0.3, -0.2) * r, Vector2(0.6, 1.1) * r), ink)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-0.3, -0.2) * r, c + Vector2(0, -r),
				c + Vector2(0.3, -0.2) * r]), ink)
		"cloud":
			for circle in [[Vector2(-0.45, 0.15), 0.42], [Vector2(0.1, -0.15), 0.55], [Vector2(0.55, 0.2), 0.38]]:
				draw_circle(c + circle[0] * r, circle[1] * r, ink)
		"bolt":
			draw_colored_polygon(PackedVector2Array([c + Vector2(0.2, -1.0) * r, c + Vector2(-0.6, 0.15) * r,
				c + Vector2(-0.05, 0.15) * r, c + Vector2(-0.25, 1.0) * r, c + Vector2(0.6, -0.2) * r,
				c + Vector2(0.05, -0.2) * r]), ink)
		"drop":
			var points := PackedVector2Array([c + Vector2(0, -r)])
			for i in 13:
				points.append(c + Vector2(0, r * 0.35) + Vector2.from_angle(-PI * 0.15 + i * PI * 1.3 / 12.0) * r * 0.6)
			draw_colored_polygon(points, ink)
		_:
			# Coffret : caisse, couvercle et fermoir.
			var body := Rect2(c + Vector2(-1.0, -0.15) * r, Vector2(2.0, 1.05) * r)
			draw_rect(body, color.darkened(0.25))
			draw_rect(Rect2(c + Vector2(-1.05, -0.65) * r, Vector2(2.1, 0.5) * r), ink)
			draw_rect(body, ink, false, width * 0.7)
			draw_rect(Rect2(c + Vector2(-0.18, -0.3) * r, Vector2(0.36, 0.45) * r), Color(1.0, 0.9, 0.5))
