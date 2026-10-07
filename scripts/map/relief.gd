class_name Relief
## Vue de trois quarts (prototype) : la carte reste à plat dans le jeu (positions,
## portées, chemins), mais ce qui se tient debout (tours, monstres, arbres) est dessiné
## en volume au-dessus de son point au sol, avec une ombre, et trié en profondeur : ce
## qui est plus bas sur l'écran passe devant.
## Activée par la carte du niveau (GameMap.relief) ; les tours et les monstres lisent
## `enabled` pour savoir comment se dessiner.

## La carte du niveau en cours est en vue de trois quarts.
static var enabled := false

## Écrasement vertical de ce qui est posé à plat sur le sol (vu de biais).
const GROUND_SQUASH := 0.72
## Contour sombre des dessins, façon bande dessinée.
const OUTLINE := Color(0.13, 0.1, 0.07)


## Le jeu n'est pas affiché (tests, serveur) : les monstres et les tours ne se
## redessinent pas pour s'animer, ce qui coûte cher en volume.
static var headless := DisplayServer.get_name() == "headless"


static func ellipse(center: Vector2, rx: float, ry: float, from := 0.0, to := TAU, points := 28) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in points + 1:
		var angle := lerpf(from, to, float(i) / points)
		result.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	return result


## Ombre douce au sol, en ellipse.
static func draw_shadow(canvas: CanvasItem, center: Vector2, rx: float, ry: float, alpha := 0.28) -> void:
	canvas.draw_colored_polygon(ellipse(center, rx * 1.12, ry * 1.12), Color(0, 0, 0, alpha * 0.45))
	canvas.draw_colored_polygon(ellipse(center, rx, ry), Color(0, 0, 0, alpha))


## Cylindre vu de biais, posé sur `base` : flanc éclairé à gauche, dessus plus clair,
## contour sombre. Renvoie le centre du dessus.
static func draw_cylinder(canvas: CanvasItem, base: Vector2, rx: float, ry: float, height: float,
		color: Color, tint := Color.WHITE) -> Vector2:
	var top := base - Vector2(0, height)
	var side := PackedVector2Array()
	var colors := PackedColorArray()
	var light := (color.lightened(0.12) * tint)
	var dark := (color.darkened(0.45) * tint)
	for point in ellipse(base, rx, ry, 0.0, PI, 16):
		side.append(point)
		colors.append(dark.lerp(light, (point.x - base.x + rx) / (2.0 * rx) * -1.0 + 1.0))
	for point in ellipse(top, rx, ry, PI, 0.0, 16):
		side.append(point)
		colors.append(dark.lerp(light, (point.x - top.x + rx) / (2.0 * rx) * -1.0 + 1.0))
	canvas.draw_polygon(side, colors)
	var outline := OUTLINE * tint
	canvas.draw_polyline(ellipse(base, rx, ry, 0.0, PI, 16), outline, 2.0, true)
	canvas.draw_line(base + Vector2(rx, 0), top + Vector2(rx, 0), outline, 2.0, true)
	canvas.draw_line(base - Vector2(rx, 0), top - Vector2(rx, 0), outline, 2.0, true)
	canvas.draw_colored_polygon(ellipse(top, rx, ry), color.lightened(0.18) * tint)
	canvas.draw_polyline(ellipse(top, rx, ry), outline, 2.0, true)
	return top


## Socle de pierre et plancher de bois d'une tour, posés autour de `foot`. Renvoie le
## centre du plancher, où se dresse le fût.
static func draw_plinth(canvas: CanvasItem, foot: Vector2, tint := Color.WHITE) -> Vector2:
	draw_shadow(canvas, foot + Vector2(6, 7), 30.0, 13.0, 0.3 * tint.a)
	var top := draw_cylinder(canvas, foot + Vector2(0, 7), 27.0, 13.5, 8.0, Color(0.58, 0.55, 0.5), tint)
	# Joints des pierres sur le flanc.
	for x in [-14.0, 3.0, 18.0]:
		var y := 13.5 * sqrt(1.0 - pow(x / 27.0, 2.0))
		canvas.draw_line(foot + Vector2(x, 7.0 + y), foot + Vector2(x, y - 1.0), Color(OUTLINE, 0.5) * tint, 1.5)
	# Plancher de bois.
	var wood := Color(0.62, 0.43, 0.24)
	canvas.draw_colored_polygon(ellipse(top, 21.0, 10.5), wood * tint)
	for x in [-10.5, 0.0, 10.5]:
		var y := 10.5 * sqrt(1.0 - pow(x / 21.0, 2.0))
		canvas.draw_line(top + Vector2(x, -y), top + Vector2(x, y), wood.darkened(0.35) * tint, 1.5)
	canvas.draw_polyline(ellipse(top, 21.0, 10.5), wood.darkened(0.5) * tint, 1.5, true)
	return top
