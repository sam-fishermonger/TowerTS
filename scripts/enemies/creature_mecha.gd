class_name CreatureMecha
## Robots de La Fonderie pour la vue de trois quarts (voir Creature) : boîtes et
## cylindres de métal cernés de noir, visière ou œil lumineux, pattes mécaniques ou
## chenilles qui défilent. Dessinés de profil, tournés vers la droite, autour du centre
## du corps ; le pied est à SHAPES[forme][0] unités sous ce centre.

## Forme -> [hauteur du corps, hauteur du haut au-dessus du corps, longueur de l'ombre],
## en unités (voir Creature.unit).
const SHAPES := {
	"drone": [1.05, 0.95, 0.7],
	"chasseur": [2.2, 0.8, 1.2],
	"sentinelle": [1.2, 1.1, 0.8],
	"spectre": [1.15, 0.75, 0.9],
	"titan": [1.3, 1.15, 1.05],
	"chenillard": [0.75, 0.95, 1.15],
	"porte_drones": [1.15, 0.95, 1.3],
	"behemoth": [1.0, 1.35, 1.3],
	"recuperateur": [0.75, 1.0, 1.0],
	"tunnelier": [0.75, 0.9, 1.3],
}
const STEEL := Color(0.62, 0.64, 0.7)
const DARK_STEEL := Color(0.27, 0.28, 0.33)
const VISOR := Color(0.12, 0.13, 0.18)


static func draw(canvas: CanvasItem, shape: String, u: float, color: Color, phase: float, tint: Color) -> void:
	var feet: float = SHAPES[shape][0] * u
	match shape:
		"drone":
			_draw_drone(canvas, u, color, phase, tint)
		"chasseur":
			_draw_fighter(canvas, u, color, phase, tint)
		"sentinelle":
			_walker_legs(canvas, u, feet, Vector2(-0.22, 0.3) * u, 0.2 * u, phase, DARK_STEEL * tint, true)
			Creature.box(canvas, Vector2(0, -0.1) * u, Vector2(1.2, 1.05) * u, 0.32 * u, color)
			# Antenne et sa lampe.
			Creature.limb(canvas, PackedVector2Array([Vector2(-0.25, -0.55) * u, Vector2(-0.3, -0.95) * u]), 1.5, DARK_STEEL * tint)
			Creature.glow(canvas, Vector2(-0.3, -0.98) * u, maxf(0.08 * u, 1.6), Color(1.0, 0.35, 0.25) * tint)
			_visor(canvas, Vector2(0.28, -0.22) * u, Vector2(0.55, 0.3) * u, Color(1.0, 0.6, 0.15) * tint, u)
			# Plaque de poitrine et rivets.
			canvas.draw_line(Vector2(-0.4, 0.12) * u, Vector2(0.4, 0.12) * u, Color(Relief.OUTLINE, 0.5), 1.0, true)
			_walker_legs(canvas, u, feet, Vector2(0.18, 0.32) * u, 0.2 * u, phase + PI, STEEL.darkened(0.15) * tint, false)
		"spectre":
			_draw_specter(canvas, u, color, phase, tint)
		"titan":
			_walker_legs(canvas, u, feet, Vector2(-0.35, 0.3) * u, 0.3 * u, phase, DARK_STEEL * tint, true)
			# Bras du côté lointain.
			Creature.limb(canvas, PackedVector2Array([Vector2(-0.2, -0.35) * u, Vector2(-0.05, 0.25) * u,
				Vector2(0.35, 0.35) * u]), 0.3 * u, color.darkened(0.45))
			Creature.box(canvas, Vector2(-0.05, -0.15) * u, Vector2(1.35, 1.05) * u, 0.22 * u, color)
			# Tête basse, visière rouge.
			Creature.box(canvas, Vector2(0.25, -0.78) * u, Vector2(0.6, 0.42) * u, 0.12 * u, color.lightened(0.08))
			_visor(canvas, Vector2(0.38, -0.78) * u, Vector2(0.38, 0.18) * u, Color(1.0, 0.2, 0.2) * tint, u)
			# Bouches d'aération sur le flanc.
			for i in 3:
				var y := (-0.02 + i * 0.14) * u
				canvas.draw_line(Vector2(-0.55 * u, y), Vector2(-0.25 * u, y), Color(Relief.OUTLINE, 0.55), 1.5, true)
			_walker_legs(canvas, u, feet, Vector2(0.2, 0.32) * u, 0.3 * u, phase + PI, STEEL.darkened(0.2) * tint, false)
			# Épaulière et bras canon du côté proche.
			Creature.blob(canvas, Vector2(-0.12, -0.42) * u, 0.38 * u, 0.3 * u, color.lightened(0.1))
			Creature.limb(canvas, PackedVector2Array([Vector2(-0.1, -0.3) * u, Vector2(0.1, 0.15) * u]), 0.3 * u, DARK_STEEL * tint)
			Creature.box(canvas, Vector2(0.45, 0.2) * u, Vector2(0.85, 0.32) * u, 0.1 * u, DARK_STEEL.lightened(0.15) * tint)
			canvas.draw_circle(Vector2(0.88, 0.2) * u, 0.09 * u, Color(1.0, 0.45, 0.2) * tint, true, -1.0, true)
		"tunnelier":
			_draw_borer(canvas, u, color, phase, tint)
		"chenillard":
			_treads(canvas, Vector2(0, 0.42) * u, Vector2(2.0, 0.62) * u, phase, tint)
			Creature.box(canvas, Vector2(-0.05, -0.12) * u, Vector2(1.8, 0.6) * u, 0.14 * u, color)
			# Bandes de danger sur la caisse.
			for i in 4:
				var x := (-0.75 + i * 0.22) * u
				canvas.draw_line(Vector2(x, 0.08 * u), Vector2(x + 0.18 * u, -0.3 * u), Color(Relief.OUTLINE, 0.6), 0.08 * u, true)
			# Tourelle, canon, visière.
			Creature.limb(canvas, PackedVector2Array([Vector2(0.3, -0.62) * u, Vector2(1.15, -0.62) * u]), 0.16 * u, DARK_STEEL * tint)
			Creature.box(canvas, Vector2(0.0, -0.62) * u, Vector2(0.85, 0.42) * u, 0.15 * u, color.darkened(0.1))
			_visor(canvas, Vector2(0.18, -0.64) * u, Vector2(0.4, 0.16) * u, Color(0.45, 0.85, 1.0) * tint, u)
		"porte_drones":
			_draw_carrier(canvas, u, feet, color, phase, tint)
		"behemoth":
			_draw_behemoth(canvas, u, color, phase, tint)
		"recuperateur":
			_draw_scavenger(canvas, u, color, phase, tint)


## Visière sombre et son œil qui luit.
static func _visor(canvas: CanvasItem, center: Vector2, size: Vector2, light: Color, u: float) -> void:
	canvas.draw_colored_polygon(Creature.rounded_rect(center, size + Vector2(2, 2), size.y / 2.0 + 1.0), Relief.OUTLINE)
	canvas.draw_colored_polygon(Creature.rounded_rect(center, size, size.y / 2.0), VISOR)
	Creature.glow(canvas, center + Vector2(size.x * 0.22, 0), maxf(size.y * 0.32, 1.6), light)


## Deux pattes mécaniques d'un côté (genou vers l'arrière, pied plat), qui marchent à
## tour de rôle. `far` : celles de derrière, plus sombres, dessinées avant le corps.
static func _walker_legs(canvas: CanvasItem, u: float, feet: float, hip: Vector2, width: float, phase: float,
		color: Color, far: bool) -> void:
	var step := sin(phase * 2.2 / u)
	var lift := maxf(0.0, cos(phase * 2.2 / u)) * 0.14 * u
	var foot := Vector2(hip.x + step * 0.3 * u, feet - lift - (0.0 if far else 0.03 * u))
	var knee := (hip + foot) / 2.0 + Vector2(-0.2 * u, 0)
	Creature.limb(canvas, PackedVector2Array([hip, knee, foot]), width, color)
	canvas.draw_circle(knee, width * 0.42, color.lightened(0.25), true, -1.0, true)
	Creature.box(canvas, foot + Vector2(0.05 * u, 0), Vector2(width * 1.9, width * 0.6), width * 0.2, color)


## Chenille : bande arrondie, roues, maillons qui défilent (vers l'arrière au sol,
## vers l'avant en haut).
static func _treads(canvas: CanvasItem, center: Vector2, size: Vector2, phase: float, tint: Color) -> void:
	canvas.draw_colored_polygon(Creature.rounded_rect(center, size + Vector2(3, 3), size.y / 2.0 + 1.5), Relief.OUTLINE)
	canvas.draw_colored_polygon(Creature.rounded_rect(center, size, size.y / 2.0), Color(0.2, 0.2, 0.23) * tint)
	var wheels := 4
	for i in wheels:
		var at := center + Vector2(lerpf(-size.x / 2.0 + size.y / 2.0, size.x / 2.0 - size.y / 2.0, i / float(wheels - 1)), 0)
		var radius := size.y * (0.36 if i in [0, wheels - 1] else 0.28)
		canvas.draw_circle(at, radius, Color(0.5, 0.5, 0.55) * tint, true, -1.0, true)
		canvas.draw_circle(at, radius * 0.4, Color(0.3, 0.3, 0.34) * tint, true, -1.0, true)
	var spacing := size.y * 0.42
	var count := int(size.x / spacing)
	var link := Color(0.55, 0.55, 0.6) * tint
	var straight := size.x - size.y
	for i in count:
		var top := fposmod(i * spacing + phase, straight) - straight / 2.0
		var bottom := fposmod(i * spacing - phase, straight) - straight / 2.0
		canvas.draw_line(center + Vector2(top, -size.y / 2.0 + 0.5), center + Vector2(top, -size.y / 2.0 + size.y * 0.16), link, 2.0)
		canvas.draw_line(center + Vector2(bottom, size.y / 2.0 - 0.5), center + Vector2(bottom, size.y / 2.0 - size.y * 0.16), link, 2.0)


## Tunnelier : une foreuse sur chenilles, gros cône vissé à l'avant qui tourne, cheminée
## qui fume à l'arrière.
static func _draw_borer(canvas: CanvasItem, u: float, color: Color, phase: float, tint: Color) -> void:
	_treads(canvas, Vector2(-0.2, 0.42) * u, Vector2(1.6, 0.6) * u, phase, tint)
	# Cheminée et petite fumée.
	Creature.box(canvas, Vector2(-0.75, -0.6) * u, Vector2(0.2, 0.45) * u, 0.05 * u, DARK_STEEL * tint)
	var puff := fposmod(phase * 0.05, 1.0)
	canvas.draw_circle(Vector2(-0.8 - 0.2 * puff, -0.95 - 0.4 * puff) * u, (0.12 + 0.12 * puff) * u,
		Color(0.55, 0.55, 0.58, 0.6 * (1.0 - puff)) * tint, true, -1.0, true)
	Creature.box(canvas, Vector2(-0.25, -0.15) * u, Vector2(1.3, 0.7) * u, 0.18 * u, color)
	# Hublot de la cabine.
	_visor(canvas, Vector2(-0.35, -0.25) * u, Vector2(0.35, 0.22) * u, Color(1.0, 0.7, 0.2) * tint, u)
	# Bandes de danger sur le flanc.
	for i in 3:
		var x := (-0.65 + i * 0.2) * u
		canvas.draw_line(Vector2(x, 0.05 * u), Vector2(x + 0.12 * u, -0.08 * u), Color(0.15, 0.15, 0.15, 0.6) * tint, 2.0, true)
	# Le cône de la foreuse : un triangle à spires qui défilent.
	var tip := Vector2(1.35, 0.05) * u
	var base_top := Vector2(0.4, -0.45) * u
	var base_bottom := Vector2(0.4, 0.55) * u
	Creature.polygon(canvas, PackedVector2Array([base_top, tip, base_bottom]), STEEL * tint)
	var turn := fposmod(phase * 0.12, 1.0)
	for i in 4:
		var t := (i + turn) / 4.0
		var top := base_top.lerp(tip, t)
		var bottom := base_bottom.lerp(tip, minf(t + 0.12, 1.0))
		canvas.draw_line(top, bottom, Color(DARK_STEEL, 0.9) * tint, maxf(0.06 * u, 1.2), true)
	Creature.box(canvas, Vector2(0.38, 0.05) * u, Vector2(0.16, 1.05) * u, 0.05 * u, DARK_STEEL * tint)


## Drone : une coque ronde qui flotte au ras du sol sous deux hélices.
static func _draw_drone(canvas: CanvasItem, u: float, color: Color, phase: float, tint: Color) -> void:
	var bob := Vector2(0, sin(phase * 0.25) * 0.08 * u)
	for side in [-1.0, 1.0]:
		var hub := bob + Vector2(side * 0.62, -0.62) * u
		Creature.limb(canvas, PackedVector2Array([bob + Vector2(side * 0.25, -0.3) * u, hub]), maxf(0.1 * u, 2.0), DARK_STEEL * tint)
		# Pales qui tournent : une ellipse floue et une pale qui s'allonge et rétrécit.
		var spin := cos(phase * 1.1 + side)
		canvas.draw_colored_polygon(Relief.ellipse(hub, 0.5 * u, 0.1 * u), Color(0.85, 0.9, 1.0, 0.35) * tint)
		canvas.draw_line(hub - Vector2(spin * 0.5 * u, 0), hub + Vector2(spin * 0.5 * u, 0), Color(Relief.OUTLINE, 0.8), 2.0, true)
		canvas.draw_circle(hub, maxf(0.08 * u, 1.5), Relief.OUTLINE, true, -1.0, true)
	Creature.blob(canvas, bob, 0.55 * u, 0.46 * u, color)
	# Petit réacteur sous la coque.
	Creature.box(canvas, bob + Vector2(-0.05, 0.45) * u, Vector2(0.4, 0.16) * u, 0.06 * u, DARK_STEEL * tint)
	_visor(canvas, bob + Vector2(0.22, -0.02) * u, Vector2(0.55, 0.3) * u, Color(0.45, 0.9, 1.0) * tint, u)


## Chasseur : un avion à réaction de profil, ailes en flèche, flamme au réacteur.
static func _draw_fighter(canvas: CanvasItem, u: float, color: Color, phase: float, tint: Color) -> void:
	# Aile lointaine.
	Creature.polygon(canvas, PackedVector2Array([Vector2(0.25, -0.1) * u, Vector2(-0.45, -0.62) * u,
		Vector2(-0.72, -0.58) * u, Vector2(-0.45, -0.08) * u]), color.darkened(0.4))
	# Flamme du réacteur, qui vacille.
	var flame := 0.35 + 0.15 * absf(sin(phase * 0.9))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-1.05, -0.12) * u, Vector2(-1.1 - flame, 0.02) * u,
		Vector2(-1.05, 0.16) * u]), Color(1.0, 0.55, 0.15, 0.9) * tint)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-1.05, -0.05) * u, Vector2(-1.05 - flame * 0.6, 0.02) * u,
		Vector2(-1.05, 0.09) * u]), Color(1.0, 0.92, 0.5) * tint)
	# Dérive.
	Creature.polygon(canvas, PackedVector2Array([Vector2(-0.62, -0.2) * u, Vector2(-0.98, -0.72) * u,
		Vector2(-1.12, -0.7) * u, Vector2(-1.02, -0.15) * u]), color.darkened(0.15))
	# Fuselage.
	var hull := PackedVector2Array([Vector2(1.3, 0.02) * u, Vector2(0.95, -0.17) * u, Vector2(0.3, -0.27) * u,
		Vector2(-0.85, -0.24) * u, Vector2(-1.08, -0.12) * u, Vector2(-1.08, 0.16) * u, Vector2(-0.8, 0.24) * u,
		Vector2(0.6, 0.22) * u, Vector2(1.05, 0.12) * u])
	Creature.polygon(canvas, hull, color)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(1.05, 0.12) * u, Vector2(0.6, 0.22) * u,
		Vector2(-0.8, 0.24) * u, Vector2(-1.06, 0.15) * u, Vector2(-1.0, 0.06) * u, Vector2(0.9, 0.04) * u]),
		Color(color.darkened(0.3), 0.8))
	canvas.draw_line(Vector2(-0.6, -0.12) * u, Vector2(0.6, -0.14) * u, Color(color.lightened(0.45), 0.8), 1.5, true)
	# Verrière, qui sert d'œil.
	var canopy := Relief.ellipse(Vector2(0.48, -0.24) * u, 0.32 * u, 0.15 * u, PI, TAU, 12)
	Creature.polygon(canvas, canopy, Color(0.35, 0.8, 1.0) * tint)
	canvas.draw_line(Vector2(0.32, -0.32) * u, Vector2(0.5, -0.35) * u, Color(1, 1, 1, 0.8), 1.5, true)
	# Aile proche, vers la caméra.
	Creature.polygon(canvas, PackedVector2Array([Vector2(0.35, 0.08) * u, Vector2(-0.5, 0.72) * u,
		Vector2(-0.82, 0.68) * u, Vector2(-0.5, 0.1) * u]), color.lightened(0.08))
	canvas.draw_circle(Vector2(-0.62, 0.62) * u, maxf(0.06 * u, 1.3), Color(1.0, 0.3, 0.25) * tint, true, -1.0, true)


## Spectre : un éclat de métal sombre à facettes, qui flotte, œil violet en fente.
static func _draw_specter(canvas: CanvasItem, u: float, color: Color, phase: float, tint: Color) -> void:
	var bob := Vector2(0, sin(phase * 0.2) * 0.1 * u)
	# Traînées de propulsion sous lui.
	for i in 3:
		var x := (-0.35 + i * 0.3) * u
		var length := (0.45 + 0.15 * sin(phase * 0.5 + i)) * u
		canvas.draw_colored_polygon(PackedVector2Array([bob + Vector2(x - 0.1 * u, 0.35 * u), bob + Vector2(x + 0.1 * u, 0.35 * u),
			bob + Vector2(x - 0.05 * u, 0.35 * u + length)]), Color(0.7, 0.45, 1.0, 0.55) * tint)
	var body := PackedVector2Array([Vector2(0.85, 0.0), Vector2(0.38, -0.58), Vector2(-0.3, -0.66), Vector2(-0.85, -0.12),
		Vector2(-0.45, 0.45), Vector2(0.42, 0.45)])
	for i in body.size():
		body[i] = bob + body[i] * u
	Creature.polygon(canvas, body, color)
	# Facettes : claires en haut, sombres en bas.
	var middle := bob + Vector2(-0.05, -0.05) * u
	canvas.draw_colored_polygon(PackedVector2Array([middle, body[1], body[2], body[3]]), Color(color.lightened(0.25), 0.9))
	canvas.draw_colored_polygon(PackedVector2Array([middle, body[4], body[5], body[0]]), Color(color.darkened(0.35), 0.9))
	for point in body:
		canvas.draw_line(middle, point, Color(Relief.OUTLINE, 0.5), 1.0, true)
	# Fente de l'œil.
	var eye := bob + Vector2(0.42, -0.12) * u
	canvas.draw_colored_polygon(PackedVector2Array([eye + Vector2(-0.22, -0.02) * u, eye + Vector2(0.2, -0.1) * u,
		eye + Vector2(0.22, 0.04) * u, eye + Vector2(-0.2, 0.08) * u]), Relief.OUTLINE)
	Creature.glow(canvas, eye + Vector2(0.06, -0.01) * u, maxf(0.08 * u, 1.6), Color(0.8, 0.45, 1.0) * tint)


## Porte-drones : un hangar plat sur quatre pattes, des drones dans leurs alvéoles.
static func _draw_carrier(canvas: CanvasItem, u: float, feet: float, color: Color, phase: float, tint: Color) -> void:
	for x in [-0.6, 0.55]:
		_walker_legs(canvas, u, feet, Vector2(x, 0.2) * u, 0.24 * u, phase + x * 3.0, DARK_STEEL * tint, true)
	Creature.box(canvas, Vector2(0, -0.12) * u, Vector2(2.05, 0.75) * u, 0.2 * u, color)
	# Pont du dessus et alvéoles allumées.
	Creature.box(canvas, Vector2(-0.15, -0.55) * u, Vector2(1.5, 0.26) * u, 0.1 * u, color.lightened(0.12))
	for i in 3:
		var bay := Vector2((-0.65 + i * 0.5), -0.58) * u
		canvas.draw_circle(bay, 0.17 * u, Relief.OUTLINE, true, -1.0, true)
		canvas.draw_circle(bay, 0.13 * u, Color(0.5, 0.75, 0.9) * tint, true, -1.0, true)
		canvas.draw_circle(bay, 0.05 * u, Color(0.85, 1.0, 1.0) * tint, true, -1.0, true)
	# Rayures latérales et œil de proue.
	canvas.draw_line(Vector2(-0.9, 0.05) * u, Vector2(0.6, 0.05) * u, Color(1.0, 0.6, 0.2) * tint, 0.08 * u, true)
	_visor(canvas, Vector2(0.72, -0.15) * u, Vector2(0.42, 0.24) * u, Color(0.45, 0.9, 1.0) * tint, u)
	for x in [-0.45, 0.7]:
		_walker_legs(canvas, u, feet, Vector2(x, 0.22) * u, 0.24 * u, phase + x * 3.0 + PI, STEEL.darkened(0.15) * tint, false)


## Béhémoth : forteresse sur chenilles, gros cœur orange en guise d'œil, cheminées
## qui fument.
static func _draw_behemoth(canvas: CanvasItem, u: float, color: Color, phase: float, tint: Color) -> void:
	# Cheminées et fumée, derrière.
	for i in 2:
		var x := (-0.75 + i * 0.32) * u
		Creature.box(canvas, Vector2(x, -0.95 * u), Vector2(0.22, 0.6) * u, 0.05 * u, DARK_STEEL * tint)
		var puff := fposmod(phase * 0.02 + i * 0.5, 1.0)
		canvas.draw_circle(Vector2(x - puff * 0.3 * u, (-1.3 - puff * 0.5) * u), (0.1 + puff * 0.15) * u,
			Color(0.35, 0.33, 0.32, 0.6 * (1.0 - puff)) * tint, true, -1.0, true)
	_treads(canvas, Vector2(0, 0.62) * u, Vector2(2.15, 0.75) * u, phase, tint)
	# Coque blindée et étrave.
	Creature.box(canvas, Vector2(-0.05, -0.2) * u, Vector2(1.95, 1.05) * u, 0.2 * u, color)
	Creature.polygon(canvas, PackedVector2Array([Vector2(0.88, -0.35) * u, Vector2(1.25, 0.1) * u,
		Vector2(1.1, 0.32) * u, Vector2(0.88, 0.3) * u]), DARK_STEEL.lightened(0.2) * tint)
	for i in 4:
		canvas.draw_circle(Vector2(-0.8 + i * 0.25, 0.18) * u, maxf(0.05 * u, 1.2), Color(Relief.OUTLINE, 0.6), true, -1.0, true)
	# Grilles d'aération.
	for i in 3:
		var y := (-0.5 + i * 0.13) * u
		canvas.draw_line(Vector2(-0.75 * u, y), Vector2(-0.3 * u, y), Color(Relief.OUTLINE, 0.55), 1.5, true)
	# Cœur du réacteur, qui palpite.
	var core := Vector2(0.42, -0.3) * u
	var pulse := 0.85 + 0.15 * sin(phase * 0.15)
	canvas.draw_circle(core, 0.36 * u, Relief.OUTLINE, true, -1.0, true)
	canvas.draw_circle(core, 0.3 * u, DARK_STEEL * tint, true, -1.0, true)
	Creature.glow(canvas, core, 0.2 * u * pulse, Color(1.0, 0.55, 0.15) * tint)


## Récupérateur : petit ferrailleur sur chenilles, pince en avant, panier de débris.
static func _draw_scavenger(canvas: CanvasItem, u: float, color: Color, phase: float, tint: Color) -> void:
	# Panier de ferraille à l'arrière.
	for i in 3:
		canvas.draw_circle(Vector2(-0.6 + i * 0.2, -0.62 - (i % 2) * 0.08) * u, 0.14 * u,
			[Color(0.55, 0.55, 0.6), Color(0.65, 0.45, 0.3), Color(0.45, 0.5, 0.55)][i] * tint, true, -1.0, true)
	Creature.box(canvas, Vector2(-0.4, -0.42) * u, Vector2(0.75, 0.38) * u, 0.08 * u, DARK_STEEL.lightened(0.1) * tint)
	_treads(canvas, Vector2(0, 0.45) * u, Vector2(1.6, 0.6) * u, phase, tint)
	Creature.box(canvas, Vector2(0.05, -0.05) * u, Vector2(1.3, 0.62) * u, 0.18 * u, color)
	# Bras et pince qui claque.
	var snap := 0.12 + 0.1 * absf(sin(phase * 0.3))
	var wrist := Vector2(1.0, -0.15) * u
	Creature.limb(canvas, PackedVector2Array([Vector2(0.4, -0.2) * u, Vector2(0.7, -0.6) * u, wrist]), maxf(0.12 * u, 2.0), DARK_STEEL * tint)
	Creature.limb(canvas, PackedVector2Array([wrist, wrist + Vector2(0.25, -snap) * u]), maxf(0.08 * u, 1.5), STEEL * tint)
	Creature.limb(canvas, PackedVector2Array([wrist, wrist + Vector2(0.25, snap) * u]), maxf(0.08 * u, 1.5), STEEL * tint)
	# Gros œil rond.
	canvas.draw_circle(Vector2(0.38, -0.12) * u, 0.24 * u, Relief.OUTLINE, true, -1.0, true)
	Creature.glow(canvas, Vector2(0.4, -0.12) * u, maxf(0.12 * u, 1.8), Color(0.55, 1.0, 0.5) * tint)
