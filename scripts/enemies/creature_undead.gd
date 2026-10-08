class_name CreatureUndead
## Morts de La Nécropole pour la vue de trois quarts (voir Creature) : squelettes,
## goules, momies et chevaliers sur le squelette des gens (CreatureHumanoid.rig), plus
## l'asticot, la charogne à quatre pattes et la Liche qui flotte. Tournés vers la
## droite, autour du centre du corps ; le pied est à SHAPES[forme][0] unités dessous.

## Forme -> [hauteur du corps, hauteur du haut au-dessus du corps, longueur de l'ombre],
## en unités (voir Creature.unit).
const SHAPES := {
	"squelette": [1.05, 1.4, 0.7],
	"goule": [0.95, 1.2, 0.85],
	"momie": [1.05, 1.4, 0.8],
	"chevalier": [1.05, 1.6, 0.85],
	"asticot": [0.5, 1.0, 1.25],
	"charogne": [0.85, 0.95, 1.25],
	"abomination": [1.1, 1.15, 1.05],
	"liche": [1.25, 1.55, 0.8],
	"pilleur": [1.0, 1.35, 0.8],
	"banshee": [1.1, 1.3, 0.9],
	"revenant": [1.05, 1.5, 0.8],
}
const BONE := Color(0.93, 0.9, 0.8)
const SOUL := Color(0.45, 1.0, 0.55)


static func draw(canvas: CanvasItem, shape: String, u: float, color: Color, phase: float, tint: Color) -> void:
	var feet: float = SHAPES[shape][0] * u
	var dark := Relief.OUTLINE
	match shape:
		"squelette":
			var r := CreatureHumanoid.rig(u, feet, phase, 0.3)
			var look := {"cloth": color, "pants": color, "boots": color.darkened(0.1), "skin": color, "torso": Vector2.ZERO,
				"head": 0.44, "limb": 0.12}
			CreatureHumanoid.figure(canvas, u, r, look, func() -> void:
				# Bassin, colonne et côtes.
				Creature.blob(canvas, r.hip + Vector2(0, -0.02 * u), 0.22 * u, 0.1 * u, color.darkened(0.1))
				Creature.limb(canvas, PackedVector2Array([r.hip, r.shoulder + Vector2(-0.08, 0) * u]), maxf(0.1 * u, 2.0), color)
				for i in 3:
					var y := (-0.18 + i * 0.16) * u
					Creature.limb(canvas, PackedVector2Array([r.chest + Vector2(-0.12 * u, y), r.chest + Vector2(0.2 * u, y + 0.04 * u),
						r.chest + Vector2(0.28 * u, y + 0.14 * u)]), maxf(0.07 * u, 1.5), color))
			_skull(canvas, r.head, 0.44 * u, color, Color(1.0, 0.35, 0.25) * tint)
			var hand := CreatureHumanoid.near_hand(u, r, look)
			Creature.limb(canvas, PackedVector2Array([hand + Vector2(-0.05, 0.08) * u, hand + Vector2(0.55, -0.3) * u]), maxf(0.09 * u, 1.8),
				Color(0.62, 0.55, 0.45) * tint)
		"goule":
			var r := CreatureHumanoid.rig(u, feet, phase, 0.36, 0.7)
			var rags := Color(0.38, 0.32, 0.26) * tint
			var look := {"cloth": rags, "sleeves": color, "pants": rags.darkened(0.1), "boots": color.darkened(0.15), "skin": color,
				"arms": "forward", "torso": Vector2(0.75, 0.75)}
			CreatureHumanoid.figure(canvas, u, r, look)
			# Haillons déchirés et gros yeux jaunes.
			canvas.draw_colored_polygon(PackedVector2Array([r.chest + Vector2(-0.38, 0.3) * u, r.chest + Vector2(-0.2, 0.55) * u,
				r.chest + Vector2(-0.05, 0.32) * u, r.chest + Vector2(0.12, 0.55) * u, r.chest + Vector2(0.3, 0.3) * u]), rags)
			for x in [0.05, 0.42]:
				canvas.draw_circle(r.head + Vector2(x, -0.05) * u, 0.13 * u + 1.0, dark, true, -1.0, true)
				canvas.draw_circle(r.head + Vector2(x, -0.05) * u, 0.13 * u, Color(1.0, 0.92, 0.35) * tint, true, -1.0, true)
				canvas.draw_circle(r.head + Vector2(x + 0.03, -0.04) * u, 0.05 * u, dark, true, -1.0, true)
			canvas.draw_line(r.head + Vector2(0.1, 0.25) * u, r.head + Vector2(0.38, 0.22) * u, dark, 1.5, true)
			var hand := CreatureHumanoid.near_hand(u, r, look)
			for i in 3:
				canvas.draw_line(hand, hand + Vector2(0.22, -0.1 + i * 0.1) * u, dark, 1.5, true)
		"momie":
			var r := CreatureHumanoid.rig(u, feet, phase, 0.18)
			var look := {"cloth": color, "pants": color.darkened(0.05), "boots": color.darkened(0.12), "skin": color,
				"arms": "forward", "torso": Vector2(0.78, 0.9)}
			CreatureHumanoid.figure(canvas, u, r, look, func() -> void:
				# Bandelette qui traîne derrière.
				var wave := sin(phase * 0.2) * 0.12 * u
				Creature.limb(canvas, PackedVector2Array([r.chest + Vector2(-0.3, 0.1) * u, r.chest + Vector2(-0.7, 0.3) * u + Vector2(0, wave),
					r.chest + Vector2(-1.0, 0.25) * u - Vector2(0, wave)]), maxf(0.1 * u, 2.0), color.darkened(0.1)))
			# Bandelettes en travers du corps et de la tête.
			var band := Color(color.darkened(0.4), 0.8)
			for i in 4:
				var y := (-0.32 + i * 0.2) * u
				canvas.draw_line(r.chest + Vector2(-0.38 * u, y), r.chest + Vector2(0.38 * u, y + 0.1 * u), band, 1.2, true)
			for i in 3:
				var y := (-0.3 + i * 0.22) * u
				canvas.draw_line(r.head + Vector2(-0.4 * u, y + 0.08 * u), r.head + Vector2(0.4 * u, y - 0.04 * u), band, 1.2, true)
			# Un seul œil qui luit entre deux bandes.
			Creature.glow(canvas, r.head + Vector2(0.28, -0.04) * u, maxf(0.08 * u, 1.5), SOUL * tint)
		"chevalier":
			var r := CreatureHumanoid.rig(u, feet, phase, 0.22)
			var steel := color.lightened(0.15)
			var look := {"cloth": color, "sleeves": steel, "pants": steel.darkened(0.1), "boots": color.darkened(0.3), "skin": steel,
				"hands": steel.darkened(0.15), "torso": Vector2(0.88, 0.9)}
			CreatureHumanoid.figure(canvas, u, r, look, func() -> void:
				# Bouclier sur le dos.
				Creature.box(canvas, r.chest + Vector2(-0.48, 0.0) * u, Vector2(0.3, 0.85) * u, 0.12 * u, color.darkened(0.25)))
			# Plastron, heaume à fente, plumet violet.
			Creature.box(canvas, r.chest + Vector2(0.05, -0.1) * u, Vector2(0.55, 0.42) * u, 0.15 * u, steel.lightened(0.1))
			Creature.limb(canvas, PackedVector2Array([r.head + Vector2(-0.05, -0.45) * u, r.head + Vector2(-0.4, -0.75) * u,
				r.head + Vector2(-0.75, -0.55) * u]), maxf(0.14 * u, 2.5), Color(0.6, 0.25, 0.8) * tint)
			Creature.blob(canvas, r.head, 0.47 * u, 0.47 * u, steel)
			canvas.draw_line(r.head + Vector2(-0.05, -0.05) * u, r.head + Vector2(0.45, -0.05) * u, dark, 0.14 * u, true)
			for x in [0.1, 0.32]:
				Creature.glow(canvas, r.head + Vector2(x, -0.05) * u, maxf(0.05 * u, 1.2), Color(0.85, 0.5, 1.0) * tint)
			canvas.draw_line(r.head + Vector2(0.15, 0.05) * u, r.head + Vector2(0.15, 0.35) * u, Color(dark, 0.6), 1.0, true)
			# Épée levée.
			var hand := CreatureHumanoid.near_hand(u, r, look)
			Creature.limb(canvas, PackedVector2Array([hand, hand + Vector2(0.4, -0.8) * u]), maxf(0.08 * u, 1.8), Color(0.78, 0.8, 0.88) * tint)
			canvas.draw_line(hand + Vector2(-0.12, 0.06) * u, hand + Vector2(0.14, -0.06) * u, dark, 3.0, true)
		"asticot":
			Creature.draw_larva(canvas, u, color, phase)
		"charogne":
			_draw_carrion(canvas, u, feet, color, phase, tint)
		"abomination":
			var r := CreatureHumanoid.rig(u, feet, phase, 0.16)
			# Voûté : la tête basse en avant du torse, le bras proche qui traîne au sol.
			r.head = r.chest + Vector2(0.6, -0.48) * u
			r.shoulder = r.chest + Vector2(0.05, -0.22) * u
			r.elbow_near = r.shoulder + Vector2(0.3, 0.45) * u
			r.hand_near = r.shoulder + Vector2(0.45 + sin(phase * 2.4 / u) * 0.1, 0.95) * u
			r.hand_far = r.shoulder + Vector2(-0.3, 0.6) * u
			r.elbow_far = r.shoulder + Vector2(-0.2, 0.3) * u
			var look := {"cloth": color, "sleeves": color.darkened(0.1), "pants": color.darkened(0.25), "boots": color.darkened(0.45),
				"skin": color.lightened(0.08), "torso": Vector2.ZERO, "head": 0.3, "limb": 0.36}
			CreatureHumanoid.figure(canvas, u, r, look, func() -> void:
				Creature.blob(canvas, r.chest + Vector2(-0.1, -0.1) * u, 0.78 * u, 0.7 * u, color))
			# Coutures, gros bras proche, yeux dépareillés.
			_stitch(canvas, r.chest + Vector2(-0.45, -0.35) * u, r.chest + Vector2(0.2, 0.3) * u, u)
			_stitch(canvas, r.chest + Vector2(-0.6, 0.1) * u, r.chest + Vector2(-0.2, 0.45) * u, u)
			var hand := CreatureHumanoid.near_hand(u, r, look)
			Creature.blob(canvas, hand, 0.28 * u, 0.25 * u, color.lightened(0.05))
			canvas.draw_circle(r.head + Vector2(0.05, -0.05) * u, 0.12 * u + 1.0, dark, true, -1.0, true)
			canvas.draw_circle(r.head + Vector2(0.05, -0.05) * u, 0.12 * u, Color(1.0, 0.9, 0.35) * tint, true, -1.0, true)
			canvas.draw_circle(r.head + Vector2(0.25, -0.02) * u, 0.06 * u, dark, true, -1.0, true)
			canvas.draw_line(r.head + Vector2(0.0, 0.18) * u, r.head + Vector2(0.28, 0.14) * u, dark, 1.5, true)
		"liche":
			_draw_lich(canvas, u, feet, color, phase, tint)
		"banshee":
			_draw_banshee(canvas, u, color, phase, tint)
		"revenant":
			_draw_revenant(canvas, u, feet, color, phase, tint)
		"pilleur":
			var r := CreatureHumanoid.rig(u, feet, phase, 0.36, 0.35)
			var coat := Color(0.38, 0.3, 0.24) * tint
			var look := {"cloth": coat, "pants": coat.darkened(0.25), "boots": Color(0.2, 0.16, 0.12) * tint,
				"skin": Color(0.68, 0.78, 0.55) * tint, "eyes": dark}
			CreatureHumanoid.figure(canvas, u, r, look, func() -> void:
				# Pelle sur l'épaule.
				Creature.limb(canvas, PackedVector2Array([r.shoulder + Vector2(0.3, 0.2) * u, r.shoulder + Vector2(-0.8, -0.35) * u]),
					maxf(0.08 * u, 1.8), Color(0.55, 0.38, 0.22) * tint)
				Creature.polygon(canvas, PackedVector2Array([r.shoulder + Vector2(-0.75, -0.5) * u, r.shoulder + Vector2(-1.1, -0.45) * u,
					r.shoulder + Vector2(-1.05, -0.2) * u, r.shoulder + Vector2(-0.75, -0.25) * u]), Color(0.6, 0.62, 0.66) * tint))
			# Écharpe orange et chapeau rabattu.
			canvas.draw_line(r.shoulder + Vector2(-0.25, 0.0) * u, r.shoulder + Vector2(0.3, 0.02) * u, color, 0.18 * u, true)
			CreatureHumanoid.cap(canvas, r.head + Vector2(0, -0.14) * u, 0.42 * u, coat.darkened(0.3), 0.6)
			Creature.box(canvas, r.head + Vector2(0.05, -0.28) * u, Vector2(1.2, 0.12) * u, 0.05 * u, coat.darkened(0.3))


## Crâne : orbites creuses, petite lueur au fond, mâchoire.
static func _skull(canvas: CanvasItem, head: Vector2, radius: float, color: Color, light: Color) -> void:
	Creature.box(canvas, head + Vector2(0.18, 0.62) * radius, Vector2(0.75, 0.38) * radius, 0.12 * radius, color.darkened(0.08))
	Creature.blob(canvas, head, radius, radius * 0.92, color)
	for x in [0.02, 0.5]:
		var socket := head + Vector2(x, 0.05) * radius
		canvas.draw_colored_polygon(Relief.ellipse(socket, radius * 0.2, radius * 0.24, 0.0, TAU, 10), Relief.OUTLINE)
		canvas.draw_circle(socket, maxf(radius * 0.08, 1.0), light, true, -1.0, true)
	canvas.draw_line(head + Vector2(0.26, 0.32) * radius, head + Vector2(0.3, 0.42) * radius, Relief.OUTLINE, 1.2, true)


## Couture grossière : un trait et des points en travers.
static func _stitch(canvas: CanvasItem, from: Vector2, to: Vector2, u: float) -> void:
	canvas.draw_line(from, to, Color(Relief.OUTLINE, 0.75), 1.2, true)
	var across := (to - from).normalized().orthogonal() * 0.08 * u
	for i in 4:
		var at := from.lerp(to, (i + 0.5) / 4.0)
		canvas.draw_line(at - across, at + across, Color(Relief.OUTLINE, 0.75), 1.2, true)


## Charogne : une bête gonflée sur quatre pattes courtes, côtes à nu, asticots.
static func _draw_carrion(canvas: CanvasItem, u: float, feet: float, color: Color, phase: float, tint: Color) -> void:
	var angle := phase * 2.0 / u
	for i in 2:
		var x := (0.5 - i * 1.0) * u
		var step := sin(angle + i * PI) * 0.15 * u
		Creature.limb(canvas, PackedVector2Array([Vector2(x, 0.2 * u), Vector2(x - step, feet - 0.05 * u)]), maxf(0.22 * u, 2.5), color.darkened(0.45))
	Creature.blob(canvas, Vector2(-0.05, -0.05) * u, 0.95 * u, 0.7 * u, color)
	# Taches de pourriture et côtes.
	for spot in [Vector2(-0.55, -0.25), Vector2(0.1, -0.4), Vector2(-0.2, 0.15)]:
		canvas.draw_colored_polygon(Relief.ellipse(spot * u, 0.18 * u, 0.12 * u), Color(color.darkened(0.3), 0.8))
	for i in 3:
		var at := Vector2(-0.3 + i * 0.25, -0.05) * u
		canvas.draw_arc(at, 0.16 * u, PI * 1.1, PI * 1.9, 8, BONE * tint, maxf(0.06 * u, 1.5), true)
	# Asticots qui sortent du dos.
	for i in 2:
		var wiggle := sin(phase * 0.4 + i * 2.0) * 0.05 * u
		Creature.limb(canvas, PackedVector2Array([Vector2(-0.4 + i * 0.4, -0.58) * u, Vector2(-0.35 + i * 0.4, -0.78) * u + Vector2(wiggle, 0)]),
			maxf(0.08 * u, 2.0), Color(0.95, 0.92, 0.8) * tint)
	for i in 2:
		var x := (0.45 - i * 0.95) * u
		var step := sin(angle + i * PI + PI) * 0.15 * u
		Creature.limb(canvas, PackedVector2Array([Vector2(x, 0.3 * u), Vector2(x - step, feet)]), maxf(0.22 * u, 2.5), color.darkened(0.25))
	# Tête basse, gueule qui bave.
	Creature.blob(canvas, Vector2(0.92, 0.12) * u, 0.32 * u, 0.28 * u, color.darkened(0.1))
	canvas.draw_line(Vector2(1.0, 0.25) * u, Vector2(1.2, 0.22) * u, Relief.OUTLINE, 1.5, true)
	canvas.draw_line(Vector2(1.05, 0.26) * u, Vector2(1.05, 0.26 + 0.15 + 0.08 * sin(phase * 0.3)) * u, Color(0.75, 0.9, 0.55, 0.8) * tint, 1.5, true)
	Creature.eye(canvas, Vector2(1.0, 0.02) * u, 0.1 * u)


## La Liche : une robe qui flotte sans jambes, crâne couronné, bâton à l'orbe verte.
static func _draw_lich(canvas: CanvasItem, u: float, feet: float, color: Color, phase: float, tint: Color) -> void:
	var r := CreatureHumanoid.rig(u, feet, 0.0, 0.0)
	var float_y := sin(phase * 0.08) * 0.08 * u
	for key in r:
		r[key] += Vector2(0, float_y)
	r.hand_near = r.shoulder + Vector2(0.45, 0.4) * u
	r.elbow_near = r.shoulder + Vector2(0.2, 0.35) * u
	r.hand_far = r.shoulder + Vector2(-0.35, 0.5) * u
	r.elbow_far = r.shoulder + Vector2(-0.25, 0.3) * u
	var look := {"cloth": color, "sleeves": color.darkened(0.1), "pants": Color(0, 0, 0, 0), "skin": BONE * tint, "torso": Vector2.ZERO,
		"limb": 0.24}
	CreatureHumanoid.figure(canvas, u, r, look, func() -> void:
		# Robe en loques qui ondule au ras du sol.
		var hem := feet - 0.12 * u + float_y
		var robe := PackedVector2Array([r.shoulder + Vector2(-0.3, -0.1) * u, r.shoulder + Vector2(0.3, -0.1) * u])
		for i in 6:
			var t := i / 5.0
			var x := lerpf(0.55, -0.7, t) * u
			robe.append(Vector2(x, hem + (0.1 * u if i % 2 == 0 else -0.05 * u) + sin(phase * 0.15 + i) * 0.04 * u))
		Creature.polygon(canvas, robe, color)
		canvas.draw_colored_polygon(PackedVector2Array([robe[0], r.shoulder + Vector2(0.05, -0.1) * u, Vector2(-0.1 * u, hem), robe[robe.size() - 1]]),
			Color(color.darkened(0.3), 0.6))
		canvas.draw_line(r.chest + Vector2(-0.4, 0.3) * u, r.chest + Vector2(0.38, 0.3) * u, Color(0.85, 0.7, 0.3) * tint, 0.08 * u, true)
		# Capuche relevée derrière la tête.
		Creature.blob(canvas, r.head + Vector2(-0.12, 0.0) * u, 0.55 * u, 0.55 * u, color.darkened(0.25)))
	# Bâton, tenu devant la robe.
	var hand: Vector2 = r.hand_near
	Creature.limb(canvas, PackedVector2Array([hand + Vector2(0.05, 0.75) * u, hand + Vector2(0.15, -0.85) * u]), maxf(0.08 * u, 2.0),
		Color(0.45, 0.3, 0.2) * tint)
	var orb := hand + Vector2(0.16, -0.98) * u
	Creature.glow(canvas, orb, 0.14 * u * (0.9 + 0.1 * sin(phase * 0.2)), SOUL * tint)
	canvas.draw_circle(hand, 0.13 * u + 1.5, Relief.OUTLINE, true, -1.0, true)
	canvas.draw_circle(hand, 0.13 * u, BONE * tint, true, -1.0, true)
	_skull(canvas, r.head, 0.42 * u, BONE * tint, SOUL * tint)
	# Couronne dorée.
	var crown := PackedVector2Array()
	var base: Vector2 = r.head + Vector2(0, -0.32) * u
	for i in 7:
		var x := lerpf(-0.36, 0.36, i / 6.0)
		crown.append(base + Vector2(x, -0.3 if i % 2 == 1 else -0.12) * u)
	crown.append(base + Vector2(0.38, 0.04) * u)
	crown.append(base + Vector2(-0.38, 0.04) * u)
	Creature.polygon(canvas, crown, CreatureHumanoid.GOLD * tint)
	canvas.draw_circle(base + Vector2(0, -0.05) * u, 0.06 * u, Color(0.4, 1.0, 0.6) * tint, true, -1.0, true)


## Banshee : un spectre qui vole, longue traîne de voiles, cheveux au vent, bras tendus,
## bouche ouverte sur un cri.
static func _draw_banshee(canvas: CanvasItem, u: float, color: Color, phase: float, tint: Color) -> void:
	var wave := sin(phase * 0.2)
	# Traîne de voiles qui ondule derrière elle.
	var trail := PackedVector2Array([Vector2(-0.2, -0.45) * u, Vector2(0.35, -0.2) * u, Vector2(0.3, 0.5) * u])
	for i in 5:
		var t := i / 4.0
		trail.append(Vector2(lerpf(0.1, -1.45, t), 0.55 - 0.35 * t + (0.12 if i % 2 == 0 else -0.04)) * u
			+ Vector2(0, sin(phase * 0.25 + i * 1.3) * 0.08 * u))
	Creature.polygon(canvas, trail, Color(color, 0.85))
	canvas.draw_colored_polygon(PackedVector2Array([trail[0], trail[1], trail[trail.size() - 1]]), Color(color.lightened(0.25), 0.4))
	# Cheveux qui flottent en arrière.
	for i in 3:
		var root := Vector2(-0.05, -0.75 + i * 0.12) * u
		Creature.limb(canvas, PackedVector2Array([root, root + Vector2(-0.55, 0.05 + wave * 0.08) * u,
			root + Vector2(-1.0, 0.18 - wave * 0.1 + i * 0.05) * u]), maxf(0.1 * u, 2.0), Color(0.82, 0.85, 0.92) * tint)
	# Bras décharnés tendus vers l'avant.
	for i in 2:
		var shoulder := Vector2(0.15, -0.3) * u
		var hand := Vector2(0.95 - i * 0.12, -0.15 + i * 0.18 + wave * 0.05) * u
		Creature.limb(canvas, PackedVector2Array([shoulder, (shoulder + hand) / 2.0 + Vector2(0, 0.05 * u), hand]),
			maxf(0.12 * u, 2.0), (BONE * tint).darkened(0.15 * (1 - i)))
	# Tête pâle, orbites vides, bouche qui hurle.
	var head := Vector2(0.15, -0.72) * u
	Creature.blob(canvas, head, 0.36 * u, 0.4 * u, Color(0.88, 0.92, 0.95) * tint)
	for x in [0.05, 0.3]:
		canvas.draw_colored_polygon(Relief.ellipse(head + Vector2(x, -0.05) * u, 0.07 * u, 0.1 * u, 0.0, TAU, 10), Relief.OUTLINE)
		canvas.draw_circle(head + Vector2(x, -0.04) * u, maxf(0.03 * u, 0.8), SOUL * tint, true, -1.0, true)
	canvas.draw_colored_polygon(Relief.ellipse(head + Vector2(0.2, 0.2) * u, 0.08 * u, 0.13 * u * (0.8 + 0.2 * absf(wave)), 0.0, TAU, 12),
		Relief.OUTLINE)


## Revenant : un mort en suaire, encapuchonné, qui marche courbé une lanterne à la main.
static func _draw_revenant(canvas: CanvasItem, u: float, feet: float, color: Color, phase: float, tint: Color) -> void:
	var r := CreatureHumanoid.rig(u, feet, phase, 0.22, 0.3)
	var shroud := color
	var look := {"cloth": shroud, "pants": shroud.darkened(0.2), "boots": shroud.darkened(0.35), "skin": BONE * tint,
		"torso": Vector2(0.85, 0.95), "arms": "forward"}
	CreatureHumanoid.figure(canvas, u, r, look, func() -> void:
		# Suaire en lambeaux qui descend jusqu'aux genoux.
		var hem := PackedVector2Array([r.chest + Vector2(-0.45, -0.3) * u, r.chest + Vector2(0.4, -0.3) * u])
		for i in 5:
			var t := i / 4.0
			hem.append(r.chest + Vector2(lerpf(0.45, -0.6, t), 0.9 + (0.12 if i % 2 == 0 else -0.02)) * u
				+ Vector2(sin(phase * 0.2 + i) * 0.04 * u, 0))
		Creature.polygon(canvas, hem, shroud.darkened(0.1)))
	# Capuche profonde, visage de crâne dans l'ombre.
	var hood := Relief.ellipse(r.head + Vector2(-0.08, -0.02) * u, 0.58 * u, 0.6 * u, -PI * 0.1, -PI * 1.45, 18)
	hood.append(r.head + Vector2(0.2, 0.55) * u)
	Creature.polygon(canvas, hood, shroud.lightened(0.08))
	Creature.blob(canvas, r.head + Vector2(0.16, 0.06) * u, 0.3 * u, 0.33 * u, Color(0.07, 0.07, 0.09))
	for x in [0.08, 0.3]:
		Creature.glow(canvas, r.head + Vector2(x, 0.02) * u, maxf(0.06 * u, 1.2), Color(0.55, 0.85, 1.0) * tint)
	# Lanterne à flamme bleue, au bout d'une chaîne.
	var hand := CreatureHumanoid.near_hand(u, r, look)
	var swing := sin(phase * 0.25) * 0.06 * u
	var lantern := hand + Vector2(0.1 * u + swing, 0.45 * u)
	canvas.draw_line(hand, lantern + Vector2(0, -0.2 * u), Relief.OUTLINE, 1.2, true)
	Creature.box(canvas, lantern, Vector2(0.3, 0.38) * u, 0.06 * u, Color(0.3, 0.28, 0.25) * tint)
	Creature.glow(canvas, lantern, 0.12 * u, Color(0.5, 0.85, 1.0) * tint)
