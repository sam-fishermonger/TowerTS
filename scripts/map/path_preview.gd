class_name PathPreview
extends Node2D
## Met en évidence le trajet des ennemis tant que la première vague n'est pas lancée :
## des flèches défilent de l'entrée vers la sortie sur chaque chemin, et le chemin
## s'éclaire en pulsant doucement. Si des monstres volants passent par un chemin, leur
## trajet (qui coupe les virages) s'affiche en pointillés bleus. Tout s'efface en
## fondu quand la première vague démarre.

@export var map: GameMap
@export var spawner: WaveSpawner

@export var arrow_color := Color(1.0, 0.95, 0.75)
@export var glow_color := Color(1.0, 0.85, 0.35)
## Écart entre deux flèches, en pixels le long du chemin.
@export var arrow_spacing := 56.0
## Vitesse de défilement des flèches, en pixels par seconde (indépendante de la vitesse de jeu).
@export var arrow_speed := 90.0
@export var arrow_size := 11.0
@export var flight_color := Color(0.55, 0.85, 1.0)
@export var fade_duration := 0.4

## Temps écoulé, en secondes réelles : sert à l'animation.
var _time := 0.0
var _fading := false
## Voile lumineux de chaque chemin. Un Line2D plutôt que draw_polyline : ses angles
## ne se chevauchent pas, ce qui évite des triangles plus clairs dans les virages.
var _glows: Array[Line2D] = []
## Index des chemins empruntés par des monstres volants.
var _flight_paths: Array[int] = []


func _ready() -> void:
	# L'aperçu reste animé pendant la pause : c'est justement le moment où l'on prépare sa défense.
	process_mode = Node.PROCESS_MODE_ALWAYS
	if spawner:
		spawner.wave_started.connect(_on_wave_started)
	if spawner:
		_flight_paths = get_flying_path_indices(spawner.waves)
	if map:
		for path in map.paths:
			var glow := Line2D.new()
			# tessellate() garde un seul point par segment droit : les angles restent nets.
			var points := PackedVector2Array()
			for point in path.curve.tessellate():
				points.append(to_local(path.to_global(point)))
			glow.points = points
			glow.width = map.path_width + 12.0
			glow.joint_mode = Line2D.LINE_JOINT_SHARP
			glow.antialiased = true
			# Sous les flèches, dessinées par ce nœud.
			glow.show_behind_parent = true
			add_child(glow)
			_glows.append(glow)


func _process(delta: float) -> void:
	# delta suit Engine.time_scale : on revient au temps réel pour que x2 ou x3 n'accélère pas les flèches.
	var real_delta := delta / maxf(Engine.time_scale, 0.001)
	_time += real_delta
	if _fading:
		modulate.a = maxf(modulate.a - real_delta / fade_duration, 0.0)
		if modulate.a == 0.0:
			queue_free()
			return
	var pulse := 0.5 + 0.5 * sin(_time * TAU / 1.6)
	for glow in _glows:
		glow.default_color = Color(glow_color, lerpf(0.12, 0.3, pulse))
	queue_redraw()


## Index des chemins dont partent des monstres volants dans ces vagues.
static func get_flying_path_indices(waves: Array[WaveData]) -> Array[int]:
	var result: Array[int] = []
	for wave in waves:
		for group in wave.groups:
			if group.enemy and group.enemy.flying and not result.has(group.path_index):
				result.append(group.path_index)
	return result


func _on_wave_started(_index: int) -> void:
	_fading = true


func _draw() -> void:
	if map == null:
		return
	for path in map.paths:
		_draw_arrows(path)
	for index in _flight_paths:
		if index < map.paths.size():
			_draw_flight_line(map.paths[index])


## Flèches en chevron qui avancent dans le sens de marche des ennemis.
func _draw_arrows(path: Path2D) -> void:
	var curve := path.curve
	var length := curve.get_baked_length()
	if length <= 0.0:
		return
	var shift := fmod(_time * arrow_speed, arrow_spacing)
	var distance := shift
	while distance < length:
		var here := to_local(path.to_global(curve.sample_baked(distance)))
		var ahead := to_local(path.to_global(curve.sample_baked(minf(distance + 4.0, length))))
		var direction := (ahead - here).normalized()
		if direction != Vector2.ZERO:
			# Les flèches apparaissent et disparaissent en fondu aux deux bouts du chemin.
			var color := arrow_color
			color.a = 0.9 * clampf(minf(distance, length - distance) / arrow_spacing, 0.0, 1.0)
			var back := here - direction * arrow_size
			var side := direction.orthogonal() * arrow_size
			draw_polyline(PackedVector2Array([back + side, here, back - side]), color, 4.0, true)
		distance += arrow_spacing


## Trajet des volants : des tirets bleus qui défilent de l'entrée du chemin à la base.
func _draw_flight_line(path: Path2D) -> void:
	var curve := Enemy.get_flight_curve(path)
	var length := curve.get_baked_length()
	var dash := arrow_spacing / 4.0
	var distance := fmod(_time * arrow_speed, arrow_spacing / 2.0)
	while distance < length:
		var color := flight_color
		color.a = 0.75 * clampf(minf(distance, length - distance) / arrow_spacing, 0.0, 1.0)
		var points := PackedVector2Array()
		for step in 4:
			var at := minf(distance + dash * step / 3.0, length)
			points.append(to_local(path.to_global(curve.sample_baked(at))))
		draw_polyline(points, color, 3.0, true)
		distance += arrow_spacing / 2.0
