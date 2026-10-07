class_name CreatureHumanoid
## Gens de La Cité pour la vue de trois quarts (voir Creature) : personnages de profil,
## grosse tête aux yeux tournés vers la caméra, bras et jambes qui marchent, vêtements
## de la couleur du monstre. Tournés vers la droite, autour du centre du corps ; le pied
## est à SHAPES[forme][0] unités sous ce centre. CreatureUndead reprend leur squelette
## (rig() et figure()).

## Forme -> [hauteur du corps, hauteur du haut au-dessus du corps, longueur de l'ombre],
## en unités (voir Creature.unit).
const SHAPES := {
	"soldat": [1.05, 1.45, 0.75],
	"eclaireur": [1.05, 1.4, 0.75],
	"garde": [1.05, 1.5, 0.85],
	"medecin": [1.05, 1.45, 0.75],
	"infiltre": [1.05, 1.45, 0.8],
	"aviateur": [1.05, 1.45, 0.9],
	"colosse": [1.1, 1.25, 1.0],
	"transport": [0.85, 1.05, 1.35],
	"general": [1.05, 1.65, 0.9],
	"maraudeur": [1.05, 1.4, 0.8],
}
const SKIN := Color(0.96, 0.78, 0.62)
const BOOTS := Color(0.3, 0.22, 0.16)
const GOLD := Color(1.0, 0.8, 0.25)


## Articulations d'un personnage qui marche (en pixels, autour du centre du corps) :
## hanche, genoux, pieds, épaule, coudes, mains, tête. `feet` : hauteur du centre du
## corps au-dessus du sol ; `stride` : longueur du pas ; `lean` : penché en avant.
static func rig(u: float, feet: float, phase: float, stride := 0.3, lean := 0.0) -> Dictionary:
	var angle := phase * 2.4 / u
	var step := sin(angle)
	var bob := absf(step) * 0.05 * u * signf(stride)
	var r := {}
	var hip := Vector2(0, feet - 0.7 * u - bob)
	r.hip = hip
	for side in ["near", "far"]:
		var sign := 1.0 if side == "near" else -1.0
		var lift := maxf(0.0, cos(angle) * sign) * 0.16 * u * signf(stride)
		var foot := Vector2(sign * step * stride * u, feet - lift)
		r["foot_" + side] = foot
		r["knee_" + side] = (hip + foot) / 2.0 + Vector2(0.1 * u + lift * 0.4, 0)
	var shoulder := Vector2(lean * 0.4 * u, -0.28 * u - bob)
	r.shoulder = shoulder
	for side in ["near", "far"]:
		var sign := -1.0 if side == "near" else 1.0
		var hand := shoulder + Vector2(sign * step * stride * u, 0.6 * u)
		r["hand_" + side] = hand
		r["elbow_" + side] = (shoulder + hand) / 2.0 + Vector2(-0.06 * u, 0)
	r.chest = Vector2(lean * 0.2 * u, -bob)
	r.head = Vector2(0.08 * u + lean * 0.6 * u, -0.86 * u - bob + absf(lean) * 0.25 * u)
	return r


## Dessine un personnage : bras et jambe du fond, `back` (sac, cape), jambe proche,
## buste, tête, puis bras proche. `look` : cloth (buste), sleeves, pants, skin, boots,
## hands, torso (taille du buste en unités), head (rayon de la tête), limb (épaisseur des
## membres), eyes (couleur des yeux), arms ("swing", "forward" ou "none").
static func figure(canvas: CanvasItem, u: float, r: Dictionary, look: Dictionary, back := Callable()) -> void:
	var cloth: Color = look.get("cloth", Color.GRAY)
	var sleeves: Color = look.get("sleeves", cloth)
	var pants: Color = look.get("pants", cloth.darkened(0.25))
	var skin: Color = look.get("skin", SKIN)
	var boots: Color = look.get("boots", BOOTS)
	var hands: Color = look.get("hands", skin)
	var torso: Vector2 = look.get("torso", Vector2(0.8, 0.85))
	var head_r: float = look.get("head", 0.46) * u
	var limb_w: float = maxf(look.get("limb", 0.26) * u, 2.5)
	var arms: String = look.get("arms", "swing")
	var forward := Vector2(0.55 * u, 0.12 * u)
	if arms != "none":
		var far_hand: Vector2 = r.shoulder + forward + Vector2(-0.1 * u, -0.08 * u) if arms == "forward" else r.hand_far
		var far_elbow: Vector2 = (r.shoulder + far_hand) / 2.0 if arms == "forward" else r.elbow_far
		Creature.limb(canvas, PackedVector2Array([r.shoulder, far_elbow, far_hand]), limb_w * 0.9, sleeves.darkened(0.35))
		canvas.draw_circle(far_hand, limb_w * 0.62, hands.darkened(0.3), true, -1.0, true)
	if pants.a > 0.0:
		_leg(canvas, r.hip, r.knee_far, r.foot_far, limb_w, pants.darkened(0.3), boots.darkened(0.3))
	if back.is_valid():
		back.call()
	if pants.a > 0.0:
		_leg(canvas, r.hip, r.knee_near, r.foot_near, limb_w, pants, boots)
	if torso != Vector2.ZERO:
		Creature.box(canvas, r.chest, torso * u, 0.28 * u, cloth)
	Creature.blob(canvas, r.head, head_r, head_r * 0.95, skin)
	if look.has("eyes"):
		eyes(canvas, r.head, head_r, look.eyes)
	if arms != "none":
		var hand: Vector2 = r.shoulder + forward if arms == "forward" else r.hand_near
		var elbow: Vector2 = (r.shoulder + hand) / 2.0 + Vector2(0, 0.04 * u) if arms == "forward" else r.elbow_near
		Creature.limb(canvas, PackedVector2Array([r.shoulder, elbow, hand]), limb_w * 0.9, sleeves)
		canvas.draw_circle(hand, limb_w * 0.62 + 1.5, Relief.OUTLINE, true, -1.0, true)
		canvas.draw_circle(hand, limb_w * 0.62, hands, true, -1.0, true)


## Main proche d'un personnage (là où il tient son arme ou son outil).
static func near_hand(u: float, r: Dictionary, look: Dictionary) -> Vector2:
	return r.shoulder + Vector2(0.55 * u, 0.12 * u) if look.get("arms", "swing") == "forward" else r.hand_near


## Jambe : cuisse, mollet, chaussure tournée vers l'avant.
static func _leg(canvas: CanvasItem, hip: Vector2, knee: Vector2, foot: Vector2, width: float, color: Color, boot: Color) -> void:
	Creature.limb(canvas, PackedVector2Array([hip, knee, foot - Vector2(0, width * 0.3)]), width, color)
	var shoe := Creature.rounded_rect(foot + Vector2(width * 0.35, -width * 0.25), Vector2(width * 1.7, width * 0.85), width * 0.4)
	Creature.polygon(canvas, shoe, boot, 1.5)


## Deux yeux tournés vers la caméra, un peu décalés vers l'avant.
static func eyes(canvas: CanvasItem, head: Vector2, head_r: float, color: Color) -> void:
	var size := Vector2(maxf(head_r * 0.13, 1.1), maxf(head_r * 0.19, 1.6))
	for x in [0.02, 0.5]:
		var at := head + Vector2(x * head_r, -0.02 * head_r)
		canvas.draw_colored_polygon(Relief.ellipse(at, size.x, size.y, 0.0, TAU, 10), color)
		if head_r > 8.0:
			canvas.draw_circle(at - size * 0.3, size.x * 0.45, Color(1, 1, 1, 0.9), true, -1.0, true)


## Calotte posée sur la tête (casque, casquette, bonnet) : la moitié haute d'une ellipse.
static func cap(canvas: CanvasItem, head: Vector2, head_r: float, color: Color, height := 0.75, grow := 1.08) -> void:
	var dome := Relief.ellipse(head + Vector2(0, -head_r * 0.12), head_r * grow, head_r * height, PI, TAU, 16)
	Creature.polygon(canvas, dome, color)


static func draw(canvas: CanvasItem, shape: String, u: float, color: Color, phase: float, tint: Color) -> void:
	var feet: float = SHAPES[shape][0] * u
	var skin := SKIN * tint
	var dark := Relief.OUTLINE
	match shape:
		"soldat":
			var r := rig(u, feet, phase)
			var look := {"cloth": color, "skin": skin, "boots": BOOTS * tint, "eyes": dark}
			figure(canvas, u, r, look, func() -> void:
				Creature.box(canvas, r.chest + Vector2(-0.45, -0.05) * u, Vector2(0.35, 0.6) * u, 0.1 * u, color.darkened(0.35)))
			cap(canvas, r.head, 0.46 * u, color.darkened(0.15))
			canvas.draw_line(r.head + Vector2(-0.55, -0.12) * u, r.head + Vector2(0.55, -0.12) * u, dark, 2.0, true)
			canvas.draw_line(r.chest + Vector2(-0.4, 0.28) * u, r.chest + Vector2(0.4, 0.28) * u, BOOTS * tint, 0.12 * u, true)
			_gun(canvas, u, near_hand(u, r, look), 0.9, tint)
		"eclaireur":
			var r := rig(u, feet, phase, 0.42, 0.25)
			var look := {"cloth": color, "pants": color.darkened(0.45), "skin": skin, "boots": BOOTS * tint, "eyes": dark}
			var scarf := Color(0.85, 0.25, 0.2) * tint
			figure(canvas, u, r, look, func() -> void:
				# Écharpe qui flotte derrière lui.
				var wave := sin(phase * 0.3) * 0.1 * u
				Creature.polygon(canvas, PackedVector2Array([r.shoulder + Vector2(-0.1, -0.05) * u,
					r.shoulder + Vector2(-0.85, -0.05) * u + Vector2(0, wave), r.shoulder + Vector2(-0.8, 0.12) * u + Vector2(0, wave),
					r.shoulder + Vector2(-0.1, 0.1) * u]), scarf))
			# Bandeau noué.
			cap(canvas, r.head, 0.46 * u, scarf, 0.5)
			canvas.draw_line(r.chest + Vector2(-0.3, -0.3) * u, r.chest + Vector2(0.3, 0.3) * u, BOOTS * tint, 0.1 * u, true)
			var hand := near_hand(u, r, look)
			Creature.limb(canvas, PackedVector2Array([hand + Vector2(-0.05, 0.05) * u, hand + Vector2(0.35, -0.12) * u]), maxf(0.08 * u, 1.5),
				Color(0.85, 0.87, 0.9) * tint)
		"garde":
			var r := rig(u, feet, phase, 0.22)
			var steel := Color(0.72, 0.76, 0.82) * tint
			var look := {"cloth": color, "sleeves": color.darkened(0.1), "skin": skin, "boots": BOOTS * tint, "eyes": dark,
				"torso": Vector2(0.85, 0.85)}
			figure(canvas, u, r, look)
			Creature.box(canvas, r.chest + Vector2(0.05, -0.08) * u, Vector2(0.6, 0.45) * u, 0.15 * u, steel)
			cap(canvas, r.head, 0.46 * u, steel, 0.8, 1.12)
			canvas.draw_line(r.head + Vector2(0.2, -0.75) * u, r.head + Vector2(-0.1, -0.85) * u, Color(0.85, 0.2, 0.2) * tint, 0.14 * u, true)
			# Grand bouclier tenu devant lui.
			var shield := Vector2(0.38 * u, r.chest.y + 0.3 * u)
			Creature.box(canvas, shield, Vector2(0.72, 1.3) * u, 0.3 * u, steel)
			Creature.box(canvas, shield, Vector2(0.52, 1.1) * u, 0.22 * u, color.lightened(0.1))
			canvas.draw_line(shield - Vector2(0, 0.4 * u), shield + Vector2(0, 0.4 * u), GOLD * tint, maxf(0.08 * u, 1.5))
			canvas.draw_line(shield - Vector2(0.18 * u, 0.1 * u), shield + Vector2(0.18 * u, -0.1 * u), GOLD * tint, maxf(0.08 * u, 1.5))
		"medecin":
			var r := rig(u, feet, phase)
			var red := Color(0.85, 0.15, 0.15) * tint
			var look := {"cloth": color, "pants": Color(0.4, 0.45, 0.55) * tint, "skin": skin, "boots": BOOTS * tint, "eyes": dark}
			figure(canvas, u, r, look, func() -> void:
				# Pans de la blouse.
				Creature.polygon(canvas, PackedVector2Array([r.chest + Vector2(-0.4, 0.2) * u, r.chest + Vector2(0.4, 0.2) * u,
					r.chest + Vector2(0.45, 0.75) * u, r.chest + Vector2(-0.5, 0.75) * u]), color.darkened(0.08)))
			_cross(canvas, r.chest + Vector2(0.05, -0.05) * u, 0.18 * u, red)
			cap(canvas, r.head, 0.46 * u, color, 0.55)
			_cross(canvas, r.head + Vector2(0.05, -0.5) * u, 0.1 * u, red)
			# Trousse à la main.
			var bag := near_hand(u, r, look) + Vector2(0, 0.2 * u)
			Creature.box(canvas, bag, Vector2(0.45, 0.32) * u, 0.08 * u, red)
			_cross(canvas, bag, 0.08 * u, Color.WHITE * tint)
		"infiltre":
			var r := rig(u, feet, phase, 0.3, 0.3)
			var look := {"cloth": color, "skin": color.darkened(0.6), "boots": color.darkened(0.4), "hands": color.darkened(0.3),
				"eyes": Color(0, 0, 0, 0)}
			figure(canvas, u, r, look, func() -> void:
				# Cape qui ondule derrière lui.
				var wave := sin(phase * 0.25) * 0.08 * u
				Creature.polygon(canvas, PackedVector2Array([r.shoulder + Vector2(-0.1, -0.15) * u,
					r.shoulder + Vector2(-0.7, 0.9) * u + Vector2(wave, 0), r.shoulder + Vector2(-0.2, 1.0) * u]), color.darkened(0.3)))
			# Capuche, visage dans l'ombre, yeux verts.
			var hood := Relief.ellipse(r.head + Vector2(-0.06, -0.04) * u, 0.56 * u, 0.56 * u, -PI * 0.12, -PI * 1.4, 18)
			hood.append(r.head + Vector2(0.15, 0.5) * u)
			Creature.polygon(canvas, hood, color.lightened(0.05))
			Creature.blob(canvas, r.head + Vector2(0.18, 0.04) * u, 0.3 * u, 0.32 * u, Color(0.06, 0.06, 0.08))
			for x in [0.08, 0.3]:
				Creature.glow(canvas, r.head + Vector2(x, 0.02) * u, maxf(0.06 * u, 1.2), Color(0.4, 1.0, 0.5) * tint)
			var hand := near_hand(u, r, look)
			Creature.limb(canvas, PackedVector2Array([hand, hand + Vector2(0.32, -0.18) * u]), maxf(0.07 * u, 1.5), Color(0.8, 0.85, 0.9) * tint)
		"aviateur":
			# Il vole : jambes ballantes, réacteur dorsal.
			var r := rig(u, feet, 0.0, 0.0, 0.2)
			var sway := sin(phase * 0.2) * 0.1 * u
			r.foot_near += Vector2(-0.25 * u + sway, -0.1 * u)
			r.foot_far += Vector2(-0.4 * u + sway, -0.15 * u)
			r.knee_near += Vector2(0.05 * u, 0)
			r.hand_near += Vector2(0.25, -0.2) * u
			var look := {"cloth": color, "pants": color.darkened(0.3), "skin": skin, "boots": BOOTS * tint, "eyes": dark}
			figure(canvas, u, r, look, func() -> void:
				var pack: Vector2 = r.chest + Vector2(-0.52, -0.05) * u
				var flame := (0.35 + 0.15 * absf(sin(phase * 0.8))) * u
				for x in [-0.1, 0.1]:
					canvas.draw_colored_polygon(PackedVector2Array([pack + Vector2(x - 0.1, 0.35) * u, pack + Vector2(x, 0.35) * u + Vector2(0, flame),
						pack + Vector2(x + 0.1, 0.35) * u]), Color(1.0, 0.6, 0.15, 0.9) * tint)
				Creature.box(canvas, pack, Vector2(0.4, 0.75) * u, 0.12 * u, Color(0.55, 0.57, 0.62) * tint))
			# Bonnet de cuir et lunettes relevées.
			cap(canvas, r.head, 0.46 * u, Color(0.5, 0.33, 0.2) * tint, 0.7)
			for x in [-0.02, 0.3]:
				canvas.draw_circle(r.head + Vector2(x, -0.32) * u, 0.13 * u + 1.0, dark, true, -1.0, true)
				canvas.draw_circle(r.head + Vector2(x, -0.32) * u, 0.13 * u, Color(0.6, 0.9, 1.0) * tint, true, -1.0, true)
		"colosse":
			var r := rig(u, feet, phase, 0.2, 0.25)
			var look := {"cloth": color, "pants": color.darkened(0.35), "skin": skin.darkened(0.08), "boots": BOOTS * tint,
				"eyes": dark, "torso": Vector2(1.15, 1.0), "head": 0.36, "limb": 0.36}
			figure(canvas, u, r, look)
			# Ceinture de cartouches, cicatrice.
			canvas.draw_line(r.chest + Vector2(-0.45, -0.4) * u, r.chest + Vector2(0.45, 0.35) * u, Color(0.7, 0.55, 0.25) * tint, 0.12 * u, true)
			canvas.draw_line(r.head + Vector2(-0.2, -0.25) * u, r.head + Vector2(-0.05, -0.05) * u, Color(0.6, 0.25, 0.2) * tint, 1.5, true)
			# Mitrailleuse lourde.
			var hand := near_hand(u, r, look)
			Creature.box(canvas, hand + Vector2(0.2, 0) * u, Vector2(0.55, 0.32) * u, 0.08 * u, Color(0.3, 0.3, 0.34) * tint)
			for y in [-0.08, 0.08]:
				Creature.limb(canvas, PackedVector2Array([hand + Vector2(0.45, y) * u, hand + Vector2(0.95, y) * u]), maxf(0.06 * u, 1.5),
					Color(0.45, 0.45, 0.5) * tint)
		"transport":
			_draw_truck(canvas, u, feet, color, phase, tint)
		"general":
			var r := rig(u, feet, phase, 0.22)
			var navy := Color(0.18, 0.2, 0.3) * tint
			var look := {"cloth": navy, "pants": navy.darkened(0.2), "skin": skin, "boots": Color(0.12, 0.1, 0.1) * tint, "eyes": dark}
			figure(canvas, u, r, look, func() -> void:
				# Cape rouge qui claque au vent.
				var wave := sin(phase * 0.12) * 0.1 * u
				Creature.polygon(canvas, PackedVector2Array([r.shoulder + Vector2(-0.05, -0.12) * u, r.shoulder + Vector2(0.15, -0.05) * u,
					r.shoulder + Vector2(-0.5, 1.15) * u + Vector2(wave, 0), r.shoulder + Vector2(-0.95, 1.05) * u + Vector2(wave * 2.0, 0),
					r.shoulder + Vector2(-0.45, 0.1) * u]), color))
			# Épaulettes, médailles, ceinture.
			Creature.blob(canvas, r.shoulder + Vector2(0.0, -0.02) * u, 0.22 * u, 0.1 * u, GOLD * tint)
			canvas.draw_line(r.chest + Vector2(-0.4, 0.28) * u, r.chest + Vector2(0.4, 0.28) * u, Color(0.1, 0.08, 0.06) * tint, 0.1 * u, true)
			for i in 3:
				canvas.draw_circle(r.chest + Vector2(0.12 + i * 0.09, -0.12) * u, 0.05 * u, [GOLD, Color(0.85, 0.2, 0.2), GOLD][i] * tint, true, -1.0, true)
			# Moustache.
			canvas.draw_colored_polygon(Relief.ellipse(r.head + Vector2(0.28, 0.2) * u, 0.18 * u, 0.06 * u), Color(0.75, 0.75, 0.72) * tint)
			# Casquette à visière, bandeau rouge, insigne doré.
			cap(canvas, r.head + Vector2(0, -0.08) * u, 0.46 * u, navy, 0.55, 1.15)
			Creature.box(canvas, r.head + Vector2(0.0, -0.18) * u, Vector2(1.0, 0.14) * u, 0.05 * u, color)
			Creature.polygon(canvas, PackedVector2Array([r.head + Vector2(0.2, -0.12) * u, r.head + Vector2(0.7, -0.08) * u,
				r.head + Vector2(0.55, 0.0) * u, r.head + Vector2(0.2, -0.04) * u]), Color(0.08, 0.08, 0.1) * tint)
			canvas.draw_circle(r.head + Vector2(0.12, -0.4) * u, 0.08 * u, GOLD * tint, true, -1.0, true)
			# Sabre levé.
			var hand := near_hand(u, r, look)
			Creature.limb(canvas, PackedVector2Array([hand, hand + Vector2(0.45, -0.75) * u]), maxf(0.06 * u, 1.5), Color(0.85, 0.88, 0.92) * tint)
			canvas.draw_line(hand + Vector2(-0.1, 0.05) * u, hand + Vector2(0.12, -0.08) * u, GOLD * tint, 2.5, true)
		"maraudeur":
			var r := rig(u, feet, phase, 0.38, 0.2)
			var look := {"cloth": Color(0.5, 0.36, 0.25) * tint, "pants": Color(0.3, 0.27, 0.25) * tint, "skin": skin,
				"boots": BOOTS * tint, "eyes": dark}
			figure(canvas, u, r, look, func() -> void:
				# Sac de butin sur le dos.
				Creature.blob(canvas, r.chest + Vector2(-0.5, -0.2) * u, 0.38 * u, 0.42 * u, Color(0.72, 0.6, 0.38) * tint)
				canvas.draw_line(r.chest + Vector2(-0.55, -0.6) * u, r.chest + Vector2(-0.4, -0.55) * u, dark, 1.5, true))
			# Foulard orange sur le bas du visage, bonnet.
			Creature.polygon(canvas, Relief.ellipse(r.head + Vector2(0.05, 0.15) * u, 0.5 * u, 0.28 * u, 0.0, PI, 12), color)
			cap(canvas, r.head, 0.46 * u, color.darkened(0.35), 0.55)


## Fusil tenu à la main, crosse vers l'arrière.
static func _gun(canvas: CanvasItem, u: float, hand: Vector2, length: float, tint: Color) -> void:
	Creature.limb(canvas, PackedVector2Array([hand + Vector2(-0.3, 0.12) * u, hand + Vector2(length - 0.3, -0.12) * u]),
		maxf(0.1 * u, 2.0), Color(0.3, 0.28, 0.27) * tint)
	canvas.draw_line(hand + Vector2(-0.3, 0.12) * u, hand + Vector2(-0.05, 0.05) * u, Color(0.55, 0.35, 0.2) * tint, maxf(0.1 * u, 2.0), true)


## Croix de soin, rouge sur blanc ou blanche sur rouge.
static func _cross(canvas: CanvasItem, center: Vector2, size: float, color: Color) -> void:
	var width := maxf(size * 0.7, 1.5)
	canvas.draw_line(center - Vector2(size, 0), center + Vector2(size, 0), color, width)
	canvas.draw_line(center - Vector2(0, size), center + Vector2(0, size), color, width)


## Transport de troupes : camion bâché, roues qui tournent, casques qui dépassent.
static func _draw_truck(canvas: CanvasItem, u: float, feet: float, color: Color, phase: float, tint: Color) -> void:
	var wheel_r := 0.32 * u
	var axle := feet - wheel_r
	# Bâche arrondie et soldats à l'arrière.
	for x in [-0.75, -0.35]:
		canvas.draw_colored_polygon(Relief.ellipse(Vector2(x, -0.62) * u, 0.17 * u, 0.15 * u, PI, TAU, 10), Relief.OUTLINE)
		canvas.draw_colored_polygon(Relief.ellipse(Vector2(x, -0.6) * u, 0.15 * u, 0.13 * u, PI, TAU, 10), color.darkened(0.3))
	var tarp := Relief.ellipse(Vector2(-0.55, -0.15) * u, 0.75 * u, 0.55 * u, PI, TAU, 18)
	tarp.append(Vector2(0.2, 0.05) * u)
	tarp.append(Vector2(-1.3, 0.05) * u)
	Creature.polygon(canvas, tarp, color.lightened(0.12))
	for x in [-0.95, -0.55, -0.15]:
		canvas.draw_line(Vector2(x, -0.62) * u, Vector2(x, 0.0) * u, Color(Relief.OUTLINE, 0.45), 1.5, true)
	# Châssis et cabine.
	Creature.box(canvas, Vector2(-0.1, 0.18) * u, Vector2(2.3, 0.42) * u, 0.1 * u, color.darkened(0.15))
	Creature.box(canvas, Vector2(0.62, -0.22) * u, Vector2(0.75, 0.82) * u, 0.16 * u, color)
	Creature.box(canvas, Vector2(0.75, -0.38) * u, Vector2(0.4, 0.3) * u, 0.08 * u, Color(0.55, 0.8, 0.95) * tint)
	canvas.draw_circle(Vector2(1.03, 0.08) * u, 0.09 * u, Color(1.0, 0.95, 0.6) * tint, true, -1.0, true)
	# Roues : rayons qui tournent avec la distance parcourue.
	for x in [-0.75, 0.62]:
		var hub := Vector2(x * u, axle)
		canvas.draw_circle(hub, wheel_r + 1.5, Relief.OUTLINE, true, -1.0, true)
		canvas.draw_circle(hub, wheel_r, Color(0.18, 0.18, 0.2) * tint, true, -1.0, true)
		canvas.draw_circle(hub, wheel_r * 0.5, Color(0.6, 0.6, 0.55) * tint, true, -1.0, true)
		for i in 3:
			var spoke := Vector2.from_angle(phase / wheel_r + TAU * i / 3.0) * wheel_r * 0.5
			canvas.draw_line(hub - spoke, hub + spoke, Color(0.3, 0.3, 0.3) * tint, 1.5, true)
