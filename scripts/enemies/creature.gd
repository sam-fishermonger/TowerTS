class_name Creature
## Monstres de la vue de trois quarts, dessinés en code et vus de profil : corps en
## boules ou en boîtes cernées de noir, pattes qui marchent, yeux tournés vers la
## caméra. La forme vient du nom du monstre (larve, drone, soldat, squelette…), la
## couleur de EnemyData.color ; un monstre inconnu devient une fourmi de sa couleur.
## Les insectes de La Ruche sont ici ; les robots de La Fonderie, les gens de La Cité
## et les morts de La Nécropole dans CreatureMecha, CreatureHumanoid et CreatureUndead.
## Le pied du monstre est en (0, 0) : le corps est au-dessus, l'ombre dessous.

## Formes des insectes (nom du monstre, sans extension).
const SHAPES := ["larve", "rodeur", "scarabee", "ravageur", "couveuse", "frelon", "mante", "reine", "pillarde"]
## Monstres reconnus à leur nom affiché plutôt qu'à leur image : les pillards
## empruntent l'image d'un autre monstre, et leurs élites (des copies sans fichier)
## gardent leur nom d'origine dans base_name.
const NAMES := {"Pillarde": "pillarde", "Récupérateur": "recuperateur", "Maraudeur": "maraudeur",
	"Pilleur de tombes": "pilleur"}


## Forme d'un type de monstre : le nom de son fichier, sinon son nom, sinon son image.
static func shape_of(data: EnemyData) -> String:
	var name := data.resource_path.get_file().get_basename()
	if _is_known(name):
		return name
	for label in [data.base_name, data.display_name]:
		if NAMES.has(label):
			return NAMES[label]
	name = data.texture.resource_path.get_file().get_basename() if data.texture else ""
	return name if _is_known(name) else "rodeur"


static func _is_known(shape: String) -> bool:
	return SHAPES.has(shape) or CreatureMecha.SHAPES.has(shape) or CreatureHumanoid.SHAPES.has(shape) \
		or CreatureUndead.SHAPES.has(shape)


## Proportions d'une forme des autres mondes, en unités : [hauteur du corps, hauteur
## du haut au-dessus du corps, longueur de l'ombre]. Vide pour un insecte.
static func _profile(shape: String) -> Array:
	for world: Dictionary in [CreatureMecha.SHAPES, CreatureHumanoid.SHAPES, CreatureUndead.SHAPES]:
		if world.has(shape):
			return world[shape]
	return []


## Unité de taille : le rayon du monstre, grossi comme son image.
static func unit(data: EnemyData) -> float:
	return data.radius * clampf(data.sprite_scale, 1.0, 1.3)


## Hauteur du centre du corps au-dessus du pied.
static func body_height(data: EnemyData) -> float:
	var u := unit(data)
	if data.flying:
		return u * 2.2
	var shape := shape_of(data)
	var profile := _profile(shape)
	if not profile.is_empty():
		return u * profile[0]
	return u * (0.5 if shape == "larve" else 0.75)


## Hauteur du haut du monstre au-dessus du pied (pour placer sa barre de vie).
static func top_height(data: EnemyData) -> float:
	var shape := shape_of(data)
	var profile := _profile(shape)
	var extra: float = profile[1] if not profile.is_empty() else (1.4 if shape in ["mante", "reine", "frelon"] else 1.0)
	return body_height(data) + unit(data) * extra


## Ombre au sol, juste sous le pied (plus petite et plus pâle sous un volant).
static func draw_shadow(canvas: CanvasItem, data: EnemyData) -> void:
	var u := unit(data)
	var shape := shape_of(data)
	var profile := _profile(shape)
	var length: float = profile[2] if not profile.is_empty() else (1.25 if shape in ["larve", "mante", "reine", "couveuse"] else 1.0)
	var size := Vector2(u * length, u * 0.38) * (0.7 if data.flying else 1.0)
	Relief.draw_shadow(canvas, Vector2(0, 1), size.x, size.y, 0.22 if data.flying else 0.32)


## Dessine le monstre, tourné vers la gauche si `facing_left`. `phase` fait marcher
## les pattes (la distance parcourue), `tint` colore tout (ralenti, gelé).
static func draw(canvas: CanvasItem, data: EnemyData, facing_left: bool, phase: float, tint := Color.WHITE) -> void:
	var u := unit(data)
	var center := Vector2(0, -body_height(data))
	if data.flying:
		center.y += sin(phase * 0.35) * 2.0
	canvas.draw_set_transform(center, 0.0, Vector2(-1.0 if facing_left else 1.0, 1.0))
	var color := data.color * tint
	var legs := u * (0.75 if not data.flying else 0.55)
	var shape := shape_of(data)
	if CreatureMecha.SHAPES.has(shape):
		CreatureMecha.draw(canvas, shape, u, color, phase, tint)
	elif CreatureHumanoid.SHAPES.has(shape):
		CreatureHumanoid.draw(canvas, shape, u, color, phase, tint)
	elif CreatureUndead.SHAPES.has(shape):
		CreatureUndead.draw(canvas, shape, u, color, phase, tint)
	match shape:
		"larve":
			draw_larva(canvas, u, color, phase)
		"scarabee", "ravageur":
			_draw_legs(canvas, u, Vector2(-0.3, 0.2) * u, 0.5 * u, legs, phase, color, true)
			blob(canvas, Vector2(0.75, 0.05) * u, 0.36 * u, 0.32 * u, color.darkened(0.45))
			blob(canvas, Vector2(-0.12, -0.08) * u, 0.85 * u, 0.62 * u, color)
			canvas.draw_line(Vector2(-0.12, -0.7) * u, Vector2(-0.12, 0.5) * u, Color(Relief.OUTLINE, 0.6), 1.5, true)
			canvas.draw_circle(Vector2(-0.45, -0.38) * u, 0.18 * u, Color(1, 1, 1, 0.55), true, -1.0, true)
			if shape == "ravageur":
				var horn := PackedVector2Array([Vector2(0.8, -0.2) * u, Vector2(1.35, -0.85) * u, Vector2(1.0, 0.05) * u])
				canvas.draw_colored_polygon(horn, Color(0.92, 0.86, 0.7) * tint)
				horn.append(horn[0])
				canvas.draw_polyline(horn, Relief.OUTLINE, 1.5, true)
			_draw_legs(canvas, u, Vector2(-0.2, 0.3) * u, 0.5 * u, legs, phase + PI, color, false)
			eye(canvas, Vector2(0.88, -0.05) * u, 0.13 * u)
		"couveuse":
			_draw_legs(canvas, u, Vector2(0.35, 0.15) * u, 0.3 * u, legs, phase, color, true)
			blob(canvas, Vector2(-0.35, -0.15) * u, 0.85 * u, 0.75 * u, color.lightened(0.15))
			for spot in [Vector2(-0.7, -0.3), Vector2(-0.2, -0.55), Vector2(-0.3, 0.15), Vector2(-0.85, 0.2)]:
				canvas.draw_circle(spot * u, 0.13 * u, Color(0.95, 0.88, 0.7) * tint, true, -1.0, true)
			blob(canvas, Vector2(0.55, 0.1) * u, 0.3 * u, 0.26 * u, color.darkened(0.3))
			blob(canvas, Vector2(0.88, -0.05) * u, 0.24 * u, 0.22 * u, color.darkened(0.15))
			_draw_legs(canvas, u, Vector2(0.45, 0.25) * u, 0.3 * u, legs, phase + PI, color, false)
			eye(canvas, Vector2(0.95, -0.1) * u, 0.1 * u)
		"frelon", "reine":
			var queen := shape == "reine"
			_draw_wings(canvas, u, phase, tint, true)
			if not data.flying:
				_draw_legs(canvas, u, Vector2(0.15, 0.2) * u, 0.3 * u, legs, phase, color, true)
			_draw_striped(canvas, Vector2(-0.6, 0.12) * u, 0.7 * u, 0.48 * u, color, tint)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-1.25, 0.15) * u, Vector2(-1.6, 0.3) * u,
				Vector2(-1.22, 0.32) * u]), Relief.OUTLINE)
			blob(canvas, Vector2(0.15, -0.05) * u, 0.36 * u, 0.32 * u, color.darkened(0.5))
			blob(canvas, Vector2(0.6, -0.15) * u, 0.32 * u, 0.3 * u, color)
			if queen:
				var crown := PackedVector2Array([Vector2(0.4, -0.38) * u, Vector2(0.45, -0.75) * u, Vector2(0.55, -0.5) * u,
					Vector2(0.65, -0.82) * u, Vector2(0.73, -0.5) * u, Vector2(0.85, -0.72) * u, Vector2(0.82, -0.36) * u])
				canvas.draw_colored_polygon(crown, Color(1.0, 0.82, 0.25) * tint)
				crown.append(crown[0])
				canvas.draw_polyline(crown, Relief.OUTLINE, 1.5, true)
			else:
				_antennae(canvas, Vector2(0.65, -0.4) * u, u)
			if not data.flying:
				_draw_legs(canvas, u, Vector2(0.25, 0.3) * u, 0.3 * u, legs, phase + PI, color, false)
			_draw_wings(canvas, u, phase, tint, false)
			eye(canvas, Vector2(0.72, -0.2) * u, 0.12 * u)
		"mante":
			_draw_legs(canvas, u, Vector2(-0.4, 0.2) * u, 0.35 * u, legs, phase, color, true)
			blob(canvas, Vector2(-0.6, 0.1) * u, 0.75 * u, 0.3 * u, color)
			blob(canvas, Vector2(0.3, -0.45) * u, 0.18 * u, 0.55 * u, color.darkened(0.1))
			var arm := Vector2(0.5, -0.35) * u
			canvas.draw_polyline(PackedVector2Array([Vector2(0.35, -0.6) * u, arm + Vector2(0.45, 0.25) * u,
				arm + Vector2(0.55, -0.15) * u]), Relief.OUTLINE, 4.5, true)
			canvas.draw_polyline(PackedVector2Array([Vector2(0.35, -0.6) * u, arm + Vector2(0.45, 0.25) * u,
				arm + Vector2(0.55, -0.15) * u]), color.lightened(0.15), 2.5, true)
			var head := PackedVector2Array([Vector2(0.2, -1.2) * u, Vector2(0.7, -1.15) * u, Vector2(0.48, -0.85) * u])
			canvas.draw_colored_polygon(head, color.lightened(0.1))
			head.append(head[0])
			canvas.draw_polyline(head, Relief.OUTLINE, 1.5, true)
			_antennae(canvas, Vector2(0.4, -1.2) * u, u)
			_draw_legs(canvas, u, Vector2(-0.3, 0.3) * u, 0.35 * u, legs, phase + PI, color, false)
			eye(canvas, Vector2(0.55, -1.08) * u, 0.1 * u)
		"rodeur", "pillarde":
			# Fourmi : abdomen, thorax, tête.
			_draw_legs(canvas, u, Vector2(0.0, 0.2) * u, 0.35 * u, legs, phase, color, true)
			blob(canvas, Vector2(-0.72, -0.05) * u, 0.62 * u, 0.48 * u, color)
			blob(canvas, Vector2(0.0, 0.05) * u, 0.34 * u, 0.28 * u, color.darkened(0.2))
			blob(canvas, Vector2(0.62, -0.2) * u, 0.4 * u, 0.36 * u, color)
			_antennae(canvas, Vector2(0.7, -0.5) * u, u)
			_draw_legs(canvas, u, Vector2(0.1, 0.3) * u, 0.35 * u, legs, phase + PI, color, false)
			eye(canvas, Vector2(0.8, -0.25) * u, 0.14 * u)
	canvas.draw_set_transform(Vector2.ZERO)


## Boule cernée de noir, éclairée en haut à gauche.
static func blob(canvas: CanvasItem, center: Vector2, rx: float, ry: float, color: Color) -> void:
	canvas.draw_colored_polygon(Relief.ellipse(center, rx + 1.5, ry + 1.5, 0.0, TAU, 24), Relief.OUTLINE)
	canvas.draw_colored_polygon(Relief.ellipse(center, rx, ry, 0.0, TAU, 24), color)
	canvas.draw_colored_polygon(Relief.ellipse(center + Vector2(0, ry * 0.35), rx * 0.85, ry * 0.5, 0.0, TAU, 20),
		Color(color.darkened(0.25), 0.7))
	canvas.draw_colored_polygon(Relief.ellipse(center - Vector2(rx * 0.28, ry * 0.38), rx * 0.42, ry * 0.3, 0.0, TAU, 16),
		Color(color.lightened(0.4), 0.85))


## Rectangle aux coins arrondis, centré sur `center`.
static func rounded_rect(center: Vector2, size: Vector2, corner: float) -> PackedVector2Array:
	corner = minf(corner, minf(size.x, size.y) / 2.0)
	var half := size / 2.0 - Vector2(corner, corner)
	var result := PackedVector2Array()
	for i in 4:
		var at := center + Vector2(half.x if i == 0 or i == 3 else -half.x, half.y if i < 2 else -half.y)
		for j in 5:
			var point := at + Vector2.from_angle(PI / 2.0 * (i + j / 4.0)) * corner
			# Pas de points en double (côté de longueur nulle) : le polygone ne se dessinerait pas.
			if result.is_empty() or not point.is_equal_approx(result[result.size() - 1]):
				result.append(point)
	if result.size() > 1 and result[0].is_equal_approx(result[result.size() - 1]):
		result.remove_at(result.size() - 1)
	return result


## Boîte aux coins arrondis cernée de noir : bas plus sombre, reflet en haut à gauche
## (corps des robots, des gens, des véhicules).
static func box(canvas: CanvasItem, center: Vector2, size: Vector2, corner: float, color: Color) -> void:
	canvas.draw_colored_polygon(rounded_rect(center, size + Vector2(3, 3), corner + 1.5), Relief.OUTLINE)
	canvas.draw_colored_polygon(rounded_rect(center, size, corner), color)
	var low := size * Vector2(1.0, 0.38)
	canvas.draw_colored_polygon(rounded_rect(center + Vector2(0, (size.y - low.y) / 2.0), low, corner),
		Color(color.darkened(0.25), 0.75))
	var shine := size * Vector2(0.45, 0.16)
	canvas.draw_colored_polygon(rounded_rect(center - size * Vector2(0.18, 0.3), shine, shine.y / 2.0),
		Color(color.lightened(0.4), 0.7))


## Polygone plein cerné de noir.
static func polygon(canvas: CanvasItem, points: PackedVector2Array, color: Color, outline := 1.5) -> void:
	canvas.draw_colored_polygon(points, color)
	var closed := points.duplicate()
	closed.append(points[0])
	canvas.draw_polyline(closed, Relief.OUTLINE, outline, true)


## Membre ou tube : un trait épais cerné de noir.
static func limb(canvas: CanvasItem, points: PackedVector2Array, width: float, color: Color) -> void:
	canvas.draw_polyline(points, Relief.OUTLINE, width + 3.0, true)
	for point in points:
		canvas.draw_circle(point, (width + 3.0) / 2.0, Relief.OUTLINE, true, -1.0, true)
	canvas.draw_polyline(points, color, width, true)
	for point in points:
		canvas.draw_circle(point, width / 2.0, color, true, -1.0, true)


## Lumière : un halo pâle et un cœur vif (œil de robot, orbe, flamme).
static func glow(canvas: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	canvas.draw_circle(center, radius * 2.0, Color(color, 0.22), true, -1.0, true)
	canvas.draw_circle(center, radius, color, true, -1.0, true)
	canvas.draw_circle(center - Vector2(radius, radius) * 0.25, radius * 0.45, Color(1, 1, 1, 0.8), true, -1.0, true)


## Abdomen rayé (frelon, reine).
static func _draw_striped(canvas: CanvasItem, center: Vector2, rx: float, ry: float, color: Color, tint: Color) -> void:
	blob(canvas, center, rx, ry, color)
	for i in 3:
		var x := center.x + rx * (-0.55 + i * 0.4)
		var half := ry * sqrt(maxf(1.0 - pow((x - center.x) / rx, 2.0), 0.0)) * 0.95
		canvas.draw_line(Vector2(x, center.y - half), Vector2(x, center.y + half), Relief.OUTLINE * tint, rx * 0.16, true)


## Trois pattes d'un côté, qui avancent et reculent à tour de rôle. Celles du côté
## lointain sont plus sombres et dessinées avant le corps.
static func _draw_legs(canvas: CanvasItem, u: float, hip: Vector2, spread: float, length: float, phase: float,
		color: Color, far: bool) -> void:
	var leg_color := color.darkened(0.55 if far else 0.35)
	for i in 3:
		var swing := sin(phase * 0.5 + i * 2.1) * u * 0.18
		var start := hip + Vector2((i - 1) * spread, 0)
		var knee := start + Vector2((i - 1) * u * 0.25 + swing * 0.5, -u * 0.15)
		var foot := start + Vector2((i - 1) * u * 0.35 + swing, length - hip.y + (0.0 if far else -u * 0.05))
		var points := PackedVector2Array([start, knee, foot])
		canvas.draw_polyline(points, Relief.OUTLINE, maxf(u * 0.16, 2.5) + 1.5, true)
		canvas.draw_polyline(points, leg_color, maxf(u * 0.16, 2.5) - 0.5, true)


static func draw_larva(canvas: CanvasItem, u: float, color: Color, phase: float) -> void:
	for i in range(4, -1, -1):
		var t := i / 4.0
		var wave := sin(phase * 0.4 - i * 1.1) * u * 0.08
		var radius := lerpf(0.5, 0.3, t) * u
		var at := Vector2(lerpf(0.55, -0.95, t) * u, wave + (0.5 * u - radius) * 0.8)
		blob(canvas, at, radius * 1.05, radius, color if i > 0 else color.lightened(0.1))
	canvas.draw_line(Vector2(0.95, 0.15) * u, Vector2(1.08, 0.3) * u, Relief.OUTLINE, 2.0, true)
	eye(canvas, Vector2(0.72, -0.12) * u, 0.13 * u)


static func _draw_wings(canvas: CanvasItem, u: float, phase: float, tint: Color, far: bool) -> void:
	var flap := 0.55 + 0.45 * absf(sin(phase * 1.3))
	var base := Vector2(0.05, -0.3) * u
	var tip := base + Vector2(-0.75 if far else -0.55, -0.95 * flap) * u
	var wing := Relief.ellipse((base + tip) / 2.0, u * 0.32, u * 0.62 * flap, 0.0, TAU, 16)
	var turn := Transform2D(-0.6 if far else -0.35, Vector2.ZERO)
	for i in wing.size():
		wing[i] = (base + tip) / 2.0 + turn * (wing[i] - (base + tip) / 2.0)
	canvas.draw_colored_polygon(wing, Color(0.85, 0.95, 1.0, 0.45 if far else 0.6) * tint)
	wing.append(wing[0])
	canvas.draw_polyline(wing, Color(Relief.OUTLINE, 0.7), 1.2, true)


static func _antennae(canvas: CanvasItem, base: Vector2, u: float) -> void:
	for side in [0.0, 0.18]:
		var tip: Vector2 = base + Vector2(0.35 + side, -0.45 + side * 0.5) * u
		canvas.draw_polyline(PackedVector2Array([base, base + Vector2(0.1 + side, -0.3) * u, tip]),
			Relief.OUTLINE, 1.5, true)


## Œil tourné vers la caméra : blanc, pupille noire, reflet.
static func eye(canvas: CanvasItem, center: Vector2, radius: float) -> void:
	radius = maxf(radius, 2.2)
	canvas.draw_circle(center, radius + 1.0, Relief.OUTLINE, true, -1.0, true)
	canvas.draw_circle(center, radius, Color.WHITE, true, -1.0, true)
	canvas.draw_circle(center + Vector2(radius * 0.25, radius * 0.1), radius * 0.55, Color(0.05, 0.05, 0.08), true, -1.0, true)
	canvas.draw_circle(center + Vector2(radius * 0.05, -radius * 0.25), radius * 0.2, Color.WHITE, true, -1.0, true)
