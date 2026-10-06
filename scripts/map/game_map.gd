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
	if tileset:
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


func release(cell: Vector2i) -> void:
	_occupants.erase(cell)


func get_occupant(cell: Vector2i) -> Node:
	return _occupants.get(cell)


# --- Chemins ----------------------------------------------------------------

## Chemin d'index donné, ou le premier si l'index n'existe pas.
func get_enemy_path(index: int) -> Path2D:
	return paths[index] if index >= 0 and index < paths.size() else paths[0]


# --- Décor ------------------------------------------------------------------

## Pose les tuiles du biome : sol, détails, obstacles et cailloux du chemin.
func _build_decor() -> void:
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


# --- Affichage --------------------------------------------------------------

func _draw() -> void:
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
		# Base du joueur au bout du premier chemin : sur la dernière case s'il finit
		# dans la carte, sinon une case avant la sortie de l'écran.
		var points := _local_points(paths[0])
		var base := points[points.size() - 1]
		if not is_cell_in_grid(world_to_cell(to_global(base))):
			base -= (base - points[points.size() - 2]).normalized() * cell_size
		draw_texture_rect(BASE_TEXTURE, Rect2(base - Vector2(32, 48), Vector2(64, 96)), false)


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
