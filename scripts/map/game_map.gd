class_name GameMap
extends Node2D
## Carte d'un niveau : grille de placement, chemins des ennemis (les Path2D
## enfants), cases bloquées par le décor et cases occupées par les tours.
## Avec les tuiles d'un biome (tileset), le sol est pavé de tuiles teintées de la
## couleur du sol, parsemé de détails, les cases bloquées reçoivent les obstacles du
## biome et le chemin quelques cailloux. Le tirage dépend du niveau : la carte est la
## même à chaque partie.

@export var cell_size := 64
## Coin haut-gauche de la grille (sous la barre du HUD).
@export var grid_origin := Vector2(0, 64)
@export var columns := 20
@export var rows := 10
## Cases où l'on ne peut pas construire (rochers).
@export var blocked_cells: Array[Vector2i] = []
@export var path_width := 48.0

@export_group("Couleurs")
@export var background_color := Color(0.13, 0.17, 0.13)
@export var ground_color := Color(0.2, 0.32, 0.2)
@export var path_color := Color(0.72, 0.6, 0.42)
@export var rock_color := Color(0.42, 0.42, 0.45)

@export_group("Décor")
## Tuiles du biome : rang 0 = 8 sols (en gris, teintés avec ground_color), rang 1 = 8
## détails du sol, rang 2 = 4 obstacles (teintés avec rock_color) puis 4 détails du
## chemin. Vide : sol uni et rochers, et le niveau y met les tuiles de son monde.
@export var tileset: TileSet:
	set(value):
		tileset = value
		if is_node_ready():
			_build_decor()
## Part des cases libres qui reçoivent un détail (œufs, boulons, herbes…).
@export_range(0.0, 1.0) var decal_density := 0.16
## Écart moyen entre deux détails semés sur le chemin, en pixels.
@export var path_detail_spacing := 56.0

@export_group("Vue de trois quarts")
## Vue de trois quarts : sol peint, chemin aux bords irréguliers, décor debout du biome
## (arbres, caisses, tombes…) que la pose d'une tour abat, tours et monstres en volume
## triés en profondeur (voir Relief). Le niveau ajoute le décor (populate_decor).
## Décoché : l'ancienne vue de dessus, en tuiles.
@export var relief := true
## Part des cases éloignées du chemin qui reçoivent un arbre (plus au bord de la carte).
@export_range(0.0, 1.0) var tree_density := 0.2

## Rangs de la planche de tuiles.
const GROUND_ROW := 0
const DECAL_ROW := 1
const OBSTACLE_ROW := 2
## Fréquence de chaque sol de la planche : les plus simples (0 et 4) reviennent le plus
## souvent, ceux aux motifs marqués (2 et 6 : grilles, pavés…) rarement.
const GROUND_WEIGHTS: Array[float] = [8.0, 3.0, 1.0, 3.0, 8.0, 2.0, 1.0, 2.0]

const BASE_TEXTURE: Texture2D = preload("res://assets/sprites/map/base.svg")
## Image de rocher en gris clair, teintée avec rock_color.
const ROCK_TEXTURE: Texture2D = preload("res://assets/sprites/map/rock.svg")

## Chemins des ennemis, dans l'ordre des nœuds enfants.
var paths: Array[Path2D] = []

var _path_cells := {}
var _blocked := {}
var _occupants := {}
## Calques de tuiles du sol et de ses détails (null sans tileset).
var _ground_layer: TileMapLayer
var _decal_layer: TileMapLayer
## Obstacle de chaque case bloquée et détails du chemin (position, angle, tuile).
var _obstacles := {}
var _path_details: Array[Dictionary] = []
## Vue de trois quarts : ronds qui dessinent le chemin (position, rayon), touffes d'herbe
## et fleurs (position, sorte, teinte), éléments de décor de chaque case.
var _path_stamps: Array[Vector3] = []
var _tufts: Array[Dictionary] = []
var _pebbles: Array[Vector3] = []
## Pavés (la Cité) et joints des plaques (la Fonderie) : position et sens du chemin.
var _cobbles: Array[Vector3] = []
var _seams: Array[Vector4] = []
var _rocks_by_cell := {}
var _ground: ColorRect
## Habillage du monde (BiomeTheme), choisi d'après les tuiles du niveau.
var _theme: Dictionary = {}
var _decor_by_cell := {}


func _ready() -> void:
	for child in get_children():
		if child is Path2D:
			paths.append(child)
	for path in paths:
		for point in path.curve.get_baked_points():
			var cell := world_to_cell(path.to_global(point))
			if is_cell_in_grid(cell):
				_path_cells[cell] = true
	for cell in blocked_cells:
		_blocked[cell] = true
	Relief.enabled = relief
	if relief:
		_build_relief()
	elif tileset:
		_build_decor()


# --- Grille ---------------------------------------------------------------

func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(((to_local(world_position) - grid_origin) / cell_size).floor())


func cell_to_world(cell: Vector2i) -> Vector2:
	return to_global(grid_origin + (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size)


func is_cell_in_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < columns and cell.y < rows


func is_cell_on_path(cell: Vector2i) -> bool:
	return _path_cells.has(cell)


func is_cell_blocked(cell: Vector2i) -> bool:
	return _blocked.has(cell)


func is_cell_buildable(cell: Vector2i) -> bool:
	return is_cell_in_grid(cell) and not is_cell_on_path(cell) \
		and not is_cell_blocked(cell) and not _occupants.has(cell)


# --- Occupation -------------------------------------------------------------

func occupy(cell: Vector2i, node: Node) -> void:
	_occupants[cell] = node
	# Vue de trois quarts : la tour abat les arbres et les buissons de sa case.
	_clear_decor(cell)


## Vue de trois quarts : abat le décor d'une case (sauf son rocher).
func _clear_decor(cell: Vector2i) -> void:
	for item in _decor_by_cell.get(cell, []):
		if is_instance_valid(item):
			item.queue_free()
	_decor_by_cell.erase(cell)


func release(cell: Vector2i) -> void:
	_occupants.erase(cell)


func get_occupant(cell: Vector2i) -> Node:
	return _occupants.get(cell)


## Bloque une case sans y dessiner d'obstacle (mode Conquête : un filon d'essence,
## dessiné par le mode lui-même).
func block_cell(cell: Vector2i) -> void:
	_blocked[cell] = true
	_clear_decor(cell)


## Retire le rocher d'une case (mode Conquête : il a été miné) : la case devient
## constructible.
func remove_rock(cell: Vector2i) -> void:
	_blocked.erase(cell)
	blocked_cells.erase(cell)
	_obstacles.erase(cell)
	if is_instance_valid(_rocks_by_cell.get(cell)):
		_rocks_by_cell[cell].queue_free()
	_rocks_by_cell.erase(cell)
	queue_redraw()


# --- Chemins ----------------------------------------------------------------

## Chemin d'index donné, ou le premier si l'index n'existe pas.
func get_enemy_path(index: int) -> Path2D:
	return paths[index] if index >= 0 and index < paths.size() else paths[0]


## Point des chemins le plus proche d'un point de la carte (repère global), pris sur la
## partie des chemins qui est dans la grille.
func get_closest_path_point(world_position: Vector2) -> Vector2:
	var best := world_position
	var best_distance := INF
	for path in paths:
		for point in path.curve.get_baked_points():
			var global_point := path.to_global(point)
			var distance := global_point.distance_squared_to(world_position)
			if distance < best_distance and is_cell_in_grid(world_to_cell(global_point)):
				best = global_point
				best_distance = distance
	return best


## Base du joueur (repère global), au bout du premier chemin : sur sa dernière case s'il
## finit dans la carte, sinon une case avant la sortie de l'écran.
func get_base_position() -> Vector2:
	var points := _local_points(paths[0])
	var base := points[points.size() - 1]
	if not is_cell_in_grid(world_to_cell(to_global(base))):
		base -= (base - points[points.size() - 2]).normalized() * cell_size
	return to_global(base)


# --- Décor ------------------------------------------------------------------

## Pose les tuiles du biome : sol, détails, obstacles et cailloux du chemin.
func _build_decor() -> void:
	if relief:
		return
	for layer in [_ground_layer, _decal_layer]:
		if layer:
			remove_child(layer)
			layer.queue_free()
	_ground_layer = null
	_decal_layer = null
	_obstacles.clear()
	_path_details.clear()
	if tileset:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(owner.scene_file_path if owner else String(name))
		var weights := PackedFloat32Array(GROUND_WEIGHTS)
		_ground_layer = _add_tile_layer("Sol", ground_color)
		_decal_layer = _add_tile_layer("Details", Color.WHITE)
		for y in rows:
			for x in columns:
				var cell := Vector2i(x, y)
				_ground_layer.set_cell(cell, 0, Vector2i(rng.rand_weighted(weights), GROUND_ROW))
				var free_cell := not is_cell_on_path(cell) and not is_cell_blocked(cell)
				if rng.randf() < decal_density and free_cell:
					_decal_layer.set_cell(cell, 0, Vector2i(rng.randi_range(0, 7), DECAL_ROW))
		for cell in blocked_cells:
			_obstacles[cell] = rng.randi_range(0, 3)
		for path in paths:
			_scatter_path_details(path, rng)
	queue_redraw()


## Calque de tuiles dessiné sous la carte (sous les chemins et les obstacles).
func _add_tile_layer(layer_name: String, color: Color) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tileset
	layer.show_behind_parent = true
	layer.position = grid_origin
	layer.modulate = color
	add_child(layer)
	return layer


func _scatter_path_details(path: Path2D, rng: RandomNumberGenerator) -> void:
	var curve := path.curve
	var length := curve.get_baked_length()
	var distance := rng.randf_range(0.0, path_detail_spacing)
	while distance < length:
		var point := to_local(path.to_global(curve.sample_baked(distance)))
		var side := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, path_width * 0.3)
		if is_cell_in_grid(world_to_cell(to_global(point))):
			_path_details.append({"position": point + side, "angle": rng.randf() * TAU,
				"tile": rng.randi_range(4, 7)})
		distance += path_detail_spacing * rng.randf_range(0.5, 1.5)


func _tile_region(tile: Vector2i) -> Rect2:
	var size := Vector2(tileset.tile_size)
	return Rect2(Vector2(tile) * size, size)


func _tile_texture() -> Texture2D:
	return (tileset.get_source(0) as TileSetAtlasSource).texture


# --- Vue de trois quarts -----------------------------------------------------

## Sol peint (un shader sous la carte), bords du chemin, pavés et touffes. Les couleurs
## viennent du monde (apply_theme), connu une fois les tuiles du niveau posées.
func _build_relief() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(owner.scene_file_path if owner else String(name))
	var ground := ColorRect.new()
	ground.name = "Herbe"
	ground.position = grid_origin
	ground.size = Vector2(columns, rows) * cell_size
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ground.show_behind_parent = true
	var material := ShaderMaterial.new()
	material.shader = preload("res://scripts/map/relief_ground.gdshader")
	material.set_shader_parameter("size", ground.size)
	material.set_shader_parameter("seed", rng.randf())
	ground.material = material
	add_child(ground)
	_ground = ground
	# Le chemin est fait de ronds dont le rayon varie doucement : ses bords ondulent.
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 0.04
	for path in paths:
		var curve := path.curve
		var distance := 0.0
		while distance < curve.get_baked_length():
			var point := to_local(path.to_global(curve.sample_baked(distance)))
			_path_stamps.append(Vector3(point.x, point.y, path_width / 2.0 + 4.0 + noise.get_noise_1d(distance) * 6.0))
			if rng.randf() < 0.05:
				var side := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, path_width * 0.38)
				_pebbles.append(Vector3(point.x + side.x, point.y + side.y, rng.randf_range(2.0, 4.0)))
			var ahead := to_local(path.to_global(curve.sample_baked(distance + 2.0)))
			var angle := point.angle_to_point(ahead) if not ahead.is_equal_approx(point) else 0.0
			if int(distance) % 12 == 0:
				for lane in range(-2, 3):
					var across := Vector2.from_angle(angle + PI / 2.0) * (lane * 9.5 + (3.0 if int(distance) % 24 == 0 else -1.5))
					_cobbles.append(Vector3(point.x + across.x, point.y + across.y, rng.randf_range(-0.1, 0.1)))
			if int(distance) % 36 == 0:
				_seams.append(Vector4(point.x, point.y, angle, 0.0))
			distance += 6.0
	for i in columns * rows * 2:
		var at := grid_origin + Vector2(rng.randf() * columns, rng.randf() * rows) * cell_size
		if is_cell_on_path(world_to_cell(to_global(at))):
			continue
		_tufts.append({"position": at, "flower": rng.randf(), "shade": rng.randf_range(-0.12, 0.12)})


## Couleurs et décor du monde de la carte (d'après ses tuiles).
func apply_theme() -> void:
	_theme = BiomeTheme.get_theme(BiomeTheme.biome_of(tileset))
	if _ground:
		var material := _ground.material as ShaderMaterial
		material.set_shader_parameter("grass_dark", _theme.grass[0])
		material.set_shader_parameter("grass", _theme.grass[1])
		material.set_shader_parameter("grass_light", _theme.grass[2])
	queue_redraw()


func _get_theme() -> Dictionary:
	if _theme.is_empty():
		apply_theme()
	return _theme


## Décor debout du monde, ajouté à `container` (trié en profondeur avec les tours et les
## monstres) : le grand décor (arbres, maisons, cheminées, tombes…) loin du chemin,
## surtout au bord de la carte, le petit (buissons, caisses…) le long du chemin, et un
## rocher par case bloquée.
func populate_decor(container: Node2D) -> void:
	apply_theme()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(owner.scene_file_path if owner else String(name)) + 1
	for y in rows:
		for x in columns:
			var cell := Vector2i(x, y)
			var center := cell_to_world(cell)
			if is_cell_blocked(cell):
				_add_decor(container, cell, DecorItem.Kind.ROCK, center + Vector2(0, 10), rng)
				continue
			if is_cell_on_path(cell):
				continue
			var near_path := false
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					near_path = near_path or is_cell_on_path(cell + Vector2i(dx, dy))
			var edge := mini(mini(x, columns - 1 - x), mini(y, rows - 1 - y))
			var tree_chance := 0.0 if near_path else tree_density * (3.0 if edge == 0 else 1.6 if edge == 1 else 1.0)
			if rng.randf() < tree_chance:
				var kind := BiomeTheme.pick(_theme.far, rng)
				# Les grandes pièces (maison, cheminée, termitière) prennent la case à elles seules.
				var big := kind in [DecorItem.Kind.HOUSE, DecorItem.Kind.CHIMNEY, DecorItem.Kind.HIVE]
				var count := 1 if big else rng.randi_range(1, 3 if edge == 0 else 2)
				for i in count:
					var jitter := Vector2(rng.randf_range(-18, 18), rng.randf_range(-4, 22))
					if big:
						jitter = Vector2(rng.randf_range(-6, 2), rng.randf_range(10, 18))
					_add_decor(container, cell, kind, center + jitter, rng,
						rng.randf_range(0.95, 1.2) if count == 1 else rng.randf_range(0.8, 1.05))
					if i == 0 and not big:
						kind = BiomeTheme.pick(_theme.far, rng)
						if kind in [DecorItem.Kind.HOUSE, DecorItem.Kind.CHIMNEY, DecorItem.Kind.HIVE]:
							break
			elif rng.randf() < (0.22 if near_path else 0.1):
				var jitter := Vector2(rng.randf_range(-18, 18), rng.randf_range(-10, 20))
				_add_decor(container, cell, BiomeTheme.pick(_theme.near, rng), center + jitter, rng, rng.randf_range(0.8, 1.15))


func _add_decor(container: Node2D, cell: Vector2i, kind: DecorItem.Kind, at: Vector2, rng: RandomNumberGenerator,
		size := 1.0) -> void:
	var item := DecorItem.new()
	item.kind = kind
	item.scale_factor = size
	item.shape_seed = rng.randi()
	item.rock_color = rock_color.lightened(0.3)
	item.leaves.assign(_get_theme().leaves)
	item.position = container.to_local(at)
	container.add_child(item)
	if kind == DecorItem.Kind.ROCK:
		_rocks_by_cell[cell] = item
	else:
		if not _decor_by_cell.has(cell):
			_decor_by_cell[cell] = []
		_decor_by_cell[cell].append(item)


## Chemin : ombre sur le sol, bord sombre, terre, puis une bande plus claire au milieu,
## là où l'on marche ; des pavés à la Cité, des plaques rivetées à la Fonderie.
func _draw_relief_path() -> void:
	var theme := _get_theme()
	var dirt: Color = theme.dirt
	for stamp in _path_stamps:
		draw_circle(Vector2(stamp.x, stamp.y + 3.0), stamp.z + 4.0, Color(0.1, 0.16, 0.05, 0.3), true, -1.0, true)
	for stamp in _path_stamps:
		draw_circle(Vector2(stamp.x, stamp.y), stamp.z + 2.0, dirt.darkened(0.42), true, -1.0, true)
	for stamp in _path_stamps:
		draw_circle(Vector2(stamp.x, stamp.y), stamp.z, dirt, true, -1.0, true)
	for stamp in _path_stamps:
		draw_circle(Vector2(stamp.x - 2.0, stamp.y - 3.0), stamp.z * 0.55, dirt.lightened(0.1), true, -1.0, true)
	match theme.path_style:
		"cobble":
			for cobble in _cobbles:
				var stone := dirt.lerp(Color.WHITE, 0.12 + cobble.z) if int(cobble.x + cobble.y) % 3 else dirt.darkened(0.08)
				var at := Vector2(cobble.x, cobble.y)
				draw_colored_polygon(Relief.ellipse(at, 4.6, 3.6, 0.0, TAU, 10), dirt.darkened(0.3))
				draw_colored_polygon(Relief.ellipse(at - Vector2(0.4, 0.6), 3.8, 2.8, 0.0, TAU, 10), stone)
			return
		"plates":
			for seam in _seams:
				var across := Vector2.from_angle(seam.z + PI / 2.0) * (path_width / 2.0 - 2.0)
				var at := Vector2(seam.x, seam.y)
				draw_line(at - across, at + across, dirt.darkened(0.35), 2.0, true)
				draw_line(at - across + Vector2(0, 1.5), at + across + Vector2(0, 1.5), dirt.lightened(0.15), 1.0, true)
				for side in [-0.7, 0.7]:
					var rivet: Vector2 = at + across * side + Vector2.from_angle(seam.z) * 5.0
					draw_circle(rivet, 1.8, dirt.darkened(0.4), true, -1.0, true)
					draw_circle(rivet - Vector2(0.4, 0.5), 0.9, dirt.lightened(0.3), true, -1.0, true)
	for pebble in _pebbles:
		var at := Vector2(pebble.x, pebble.y)
		draw_colored_polygon(Relief.ellipse(at, pebble.z, pebble.z * 0.6, 0.0, TAU, 10), dirt.darkened(0.25))
		draw_colored_polygon(Relief.ellipse(at - Vector2(0.5, 0.8), pebble.z * 0.6, pebble.z * 0.35, 0.0, TAU, 8),
			dirt.lightened(0.25))


## Ce qui est semé sur le sol : touffes d'herbe et fleurs, boulons et taches d'huile
## (la Fonderie), herbe morte et os (la Nécropole).
func _draw_tufts() -> void:
	var theme := _get_theme()
	for tuft in _tufts:
		var at: Vector2 = tuft.position
		if tuft.flower < theme.flowers:
			for i in 3:
				var petal := at + Vector2.from_angle(TAU * i / 3.0) * 2.5
				draw_circle(petal, 2.2, theme.flower_color)
			draw_circle(at, 1.6, Color(1.0, 0.75, 0.2))
			continue
		var color: Color = theme.tuft_color.lightened(tuft.shade)
		if theme.tufts == "bolts":
			if tuft.flower > 0.8:
				draw_colored_polygon(Relief.ellipse(at, 7.0, 3.5, 0.0, TAU, 12), Color(0.08, 0.07, 0.07, 0.35))
			elif tuft.flower > 0.5:
				draw_circle(at, 2.2, Color(0.55, 0.55, 0.58), true, -1.0, true)
				draw_circle(at, 0.9, Color(0.25, 0.25, 0.27), true, -1.0, true)
			else:
				draw_line(at, at + Vector2(4, -2), color, 2.0, true)
			continue
		if theme.tufts == "dead_grass" and tuft.flower > 0.93:
			draw_line(at - Vector2(4, 1), at + Vector2(4, -1), Color(0.88, 0.86, 0.78), 2.0, true)
			for end in [at - Vector2(4, 1), at + Vector2(4, -1)]:
				draw_circle(end, 1.6, Color(0.88, 0.86, 0.78), true, -1.0, true)
			continue
		for i in 3:
			var x := (i - 1) * 3.0
			draw_line(at + Vector2(x, 0), at + Vector2(x * 1.6, -6.0 + absf(x) * 0.5), color, 1.5, true)


# --- Affichage --------------------------------------------------------------

func _draw() -> void:
	if relief:
		_draw_relief()
		return
	var grid_size := Vector2(columns, rows) * cell_size
	var screen := get_viewport_rect().size
	if tileset:
		# Le sol est fait de tuiles, dessinées avant la carte : on ne peint que les bandes
		# hors de la grille.
		draw_rect(Rect2(0, 0, screen.x, grid_origin.y), background_color)
		var bottom := grid_origin.y + grid_size.y
		draw_rect(Rect2(0, bottom, screen.x, maxf(screen.y - bottom, 0.0)), background_color)
	else:
		draw_rect(Rect2(Vector2.ZERO, screen), background_color)
		draw_rect(Rect2(grid_origin, grid_size), ground_color)
	for x in range(columns + 1):
		var from := grid_origin + Vector2(x * cell_size, 0)
		draw_line(from, from + Vector2(0, grid_size.y), Color(1, 1, 1, 0.06))
	for y in range(rows + 1):
		var from := grid_origin + Vector2(0, y * cell_size)
		draw_line(from, from + Vector2(grid_size.x, 0), Color(1, 1, 1, 0.06))
	for cell in blocked_cells:
		_draw_rock(to_local(cell_to_world(cell)))
	# Bordure de tous les chemins d'abord, pour que les croisements restent propres.
	for path in paths:
		draw_polyline(_local_points(path), path_color.darkened(0.25), path_width + 8.0, true)
	for path in paths:
		draw_polyline(_local_points(path), path_color, path_width, true)
	if tileset:
		var texture := _tile_texture()
		var size := Vector2(tileset.tile_size)
		for detail in _path_details:
			draw_set_transform(detail.position, detail.angle)
			draw_texture_rect_region(texture, Rect2(-size / 2.0, size), _tile_region(Vector2i(detail.tile, OBSTACLE_ROW)))
		draw_set_transform(Vector2.ZERO)
	if not paths.is_empty():
		var base := to_local(get_base_position())
		draw_texture_rect(BASE_TEXTURE, Rect2(base - Vector2(32, 48), Vector2(64, 96)), false)


func _draw_relief() -> void:
	var grid_size := Vector2(columns, rows) * cell_size
	var screen := get_viewport_rect().size
	draw_rect(Rect2(0, 0, screen.x, grid_origin.y), background_color)
	var bottom := grid_origin.y + grid_size.y
	draw_rect(Rect2(0, bottom, screen.x, maxf(screen.y - bottom, 0.0)), background_color)
	_draw_tufts()
	_draw_relief_path()
	if not paths.is_empty():
		var base := to_local(get_base_position())
		_draw_relief_base(base)


## Base du joueur en vue de trois quarts : un rempart entre deux tours rondes au toit
## bleu, porte ouverte sur le chemin.
func _draw_relief_base(at: Vector2) -> void:
	var stone := Color(0.7, 0.68, 0.64)
	var roof := Color(0.25, 0.42, 0.8)
	Relief.draw_shadow(self, at + Vector2(8, 18), 44.0, 16.0, 0.35)
	for side in [-1.0, 1.0]:
		var foot: Vector2 = at + Vector2(side * 19.0, 8.0 - 22.0)
		var top := Relief.draw_cylinder(self, foot, 11.0, 5.5, 34.0, stone)
		var cone := PackedVector2Array([top + Vector2(-15, 2), top + Vector2(0, -26), top + Vector2(15, 2)])
		draw_colored_polygon(Relief.ellipse(top + Vector2(0, 2), 15.0, 6.0), roof.darkened(0.3))
		draw_colored_polygon(cone, roof)
		draw_colored_polygon(PackedVector2Array([top + Vector2(-15, 2), top + Vector2(0, -26), top + Vector2(-4, 4)]), roof.lightened(0.2))
		cone.append(cone[0])
		draw_polyline(cone, Relief.OUTLINE, 2.0, true)
		draw_line(top + Vector2(0, -26), top + Vector2(0, -38), Relief.OUTLINE, 2.0)
		draw_colored_polygon(PackedVector2Array([top + Vector2(0, -38), top + Vector2(10, -34), top + Vector2(0, -30)]),
			Color(1.0, 0.8, 0.2))
	# Rempart et porte.
	var wall := Rect2(at + Vector2(-12, -34), Vector2(24, 36))
	draw_rect(wall, stone.darkened(0.12))
	for x in 2:
		draw_rect(Rect2(wall.position + Vector2(2 + x * 12, -6), Vector2(8, 6)), stone.darkened(0.12))
		draw_rect(Rect2(wall.position + Vector2(2 + x * 12, -6), Vector2(8, 6)), Relief.OUTLINE, false, 1.5)
	draw_rect(wall, Relief.OUTLINE, false, 2.0)
	var door := PackedVector2Array([at + Vector2(-8, 2), at + Vector2(-8, -12)])
	door.append_array(Relief.ellipse(at + Vector2(0, -12), 8.0, 8.0, PI, TAU, 10))
	door.append(at + Vector2(8, 2))
	draw_colored_polygon(door, Color(0.2, 0.13, 0.08))
	draw_polyline(door, Relief.OUTLINE, 2.0, true)


func _draw_rock(center: Vector2) -> void:
	var cell := world_to_cell(to_global(center))
	if tileset and _obstacles.has(cell):
		draw_texture_rect_region(_tile_texture(), Rect2(center - Vector2.ONE * cell_size / 2.0, Vector2.ONE * cell_size),
			_tile_region(Vector2i(_obstacles[cell], OBSTACLE_ROW)), rock_color.lightened(0.45))
		return
	var size := cell_size * 0.9
	draw_texture_rect(ROCK_TEXTURE, Rect2(center - Vector2.ONE * size / 2.0, Vector2.ONE * size), false,
		rock_color.lightened(0.45))


func _local_points(path: Path2D) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point in path.curve.get_baked_points():
		points.append(to_local(path.to_global(point)))
	return points
