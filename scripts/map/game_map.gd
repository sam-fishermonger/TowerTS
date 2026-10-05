class_name GameMap
extends Node2D
## Carte d'un niveau : grille de placement, chemins des ennemis (les Path2D
## enfants), cases bloquées par le décor et cases occupées par les tours.

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

## Chemins des ennemis, dans l'ordre des nœuds enfants.
var paths: Array[Path2D] = []

var _path_cells := {}
var _blocked := {}
var _occupants := {}


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


# --- Affichage --------------------------------------------------------------

func _draw() -> void:
	var grid_size := Vector2(columns, rows) * cell_size
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), background_color)
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
	if not paths.is_empty():
		# Base du joueur au bout du premier chemin.
		var points := _local_points(paths[0])
		var base := points[points.size() - 1] + Vector2(-64, 0)
		draw_rect(Rect2(base - Vector2(24, 32), Vector2(48, 64)), Color(0.35, 0.5, 0.85))


func _draw_rock(center: Vector2) -> void:
	var r := cell_size * 0.36
	draw_circle(center + Vector2(-r * 0.3, r * 0.2), r * 0.75, rock_color.darkened(0.2))
	draw_circle(center + Vector2(r * 0.25, -r * 0.1), r * 0.8, rock_color)
	draw_circle(center + Vector2(r * 0.1, -r * 0.35), r * 0.3, rock_color.lightened(0.25))


func _local_points(path: Path2D) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point in path.curve.get_baked_points():
		points.append(to_local(path.to_global(point)))
	return points
