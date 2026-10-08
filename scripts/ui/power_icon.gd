class_name PowerIcon
extends Control
## Image d'un pouvoir actif, dessinée en code : un météore, un flocon, un bouclier ou
## une pioche.

## Pouvoir dessiné (Power).
var power: Power:
	set(value):
		power = value
		queue_redraw()


func _draw() -> void:
	if power:
		draw_icon(self, power, Rect2(Vector2.ZERO, size), modulate.a)


## Dessine l'image du pouvoir dans `rect`, sur n'importe quel CanvasItem.
static func draw_icon(canvas: CanvasItem, power: Power, rect: Rect2, alpha := 1.0) -> void:
	var c := rect.get_center()
	var r := minf(rect.size.x, rect.size.y) / 2.0
	var color := Color(power.color, alpha)
	match power.kind:
		Power.Kind.METEORS:
			# Un rocher en feu et sa traînée, qui tombe en diagonale.
			var rock := c + Vector2(r * 0.25, r * 0.25)
			canvas.draw_line(rock - Vector2(r, r) * 0.8, rock, Color(color, 0.55 * alpha), r * 0.5)
			canvas.draw_line(rock - Vector2(r, r) * 0.45, rock, Color(1, 0.85, 0.45, 0.7 * alpha), r * 0.3)
			canvas.draw_circle(rock, r * 0.45, color)
			canvas.draw_circle(rock - Vector2(r, r) * 0.12, r * 0.2, Color(1, 0.92, 0.7, alpha))
		Power.Kind.FREEZE:
			# Un flocon : trois branches et leurs petites pointes.
			for i in 3:
				var direction := Vector2.from_angle(PI / 2.0 + TAU * i / 6.0)
				canvas.draw_line(c - direction * r * 0.9, c + direction * r * 0.9, color, maxf(r * 0.14, 1.5))
			for i in 6:
				var direction := Vector2.from_angle(PI / 2.0 + TAU * i / 6.0)
				var base := c + direction * r * 0.55
				for side in [-1.0, 1.0]:
					canvas.draw_line(base, base + direction.rotated(side * 0.8) * r * 0.3, color, maxf(r * 0.1, 1.0))
			canvas.draw_circle(c, r * 0.16, Color(1, 1, 1, alpha))
		Power.Kind.REINFORCEMENTS:
			# Un bouclier et une épée en travers.
			var shield := PackedVector2Array([c + Vector2(-r * 0.6, -r * 0.7), c + Vector2(r * 0.6, -r * 0.7),
				c + Vector2(r * 0.6, 0.0), c + Vector2(0.0, r * 0.85), c + Vector2(-r * 0.6, 0.0)])
			canvas.draw_line(c + Vector2(-r * 0.85, r * 0.85), c + Vector2(r * 0.85, -r * 0.85),
				Color(0.9, 0.9, 0.95, alpha), maxf(r * 0.14, 1.5))
			canvas.draw_colored_polygon(shield, color.darkened(0.25))
			shield.append(shield[0])
			canvas.draw_polyline(shield, Color(1, 1, 1, 0.8 * alpha), maxf(r * 0.1, 1.0))
			canvas.draw_line(c + Vector2(0.0, -r * 0.5), c + Vector2(0.0, r * 0.55), Color(1, 1, 1, 0.6 * alpha),
				maxf(r * 0.1, 1.0))
		Power.Kind.CORVEE:
			# Une pioche en travers, et des traits de vitesse derrière elle.
			for i in 3:
				var y := c.y - r * 0.35 + i * r * 0.35
				canvas.draw_line(Vector2(c.x - r * 0.95, y), Vector2(c.x - r * (0.45 - i * 0.1), y),
					Color(color, 0.6 * alpha), maxf(r * 0.1, 1.0))
			var handle_from := c + Vector2(-r * 0.5, r * 0.8)
			var handle_to := c + Vector2(r * 0.45, -r * 0.55)
			canvas.draw_line(handle_from, handle_to, Color(0.6, 0.42, 0.25, alpha), maxf(r * 0.16, 1.5))
			# Le fer, en croissant autour du haut du manche.
			var head := PackedVector2Array([c + Vector2(-r * 0.3, -r * 0.8), c + Vector2(r * 0.25, -r * 0.75),
				c + Vector2(r * 0.75, -r * 0.3), c + Vector2(r * 0.85, r * 0.15), c + Vector2(r * 0.5, -r * 0.35),
				c + Vector2(r * 0.15, -r * 0.6)])
			canvas.draw_colored_polygon(head, color)
			canvas.draw_polyline(head + PackedVector2Array([head[0]]), Color(1, 1, 1, 0.8 * alpha), maxf(r * 0.08, 1.0))
