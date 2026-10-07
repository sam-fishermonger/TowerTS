extends SceneTree

## Refait les captures d'écran du README (docs/captures/*.webp). Il faut une fenêtre :
##   godot --path . --resolution 1280x800 -s res://tools/captures.gd
## Sur une machine sans écran, préfixer par : xvfb-run -a -s "-screen 0 1280x800x24"
## Une seule capture : ajouter -- <nom> (par exemple -- titre).

const OUT_DIR := "res://docs/captures/"
## Sauvegarde à part, pour ne pas toucher à celle du joueur : elle est refaite à chaque
## lancement, avec la progression d'un joueur qui a fini le premier monde.
const SAVE_PATH := "user://captures_progress.cfg"
const CAMPAIGN: Campaign = preload("res://resources/campaign.tres")

## Nom du fichier => [scène, secondes de jeu avant la capture, partie lancée ?]
const SHOTS := {
	"titre": ["res://scenes/ui/title_screen.tscn", 4.0, false],
	"mondes": ["res://scenes/ui/world_select_screen.tscn", 0.5, false],
	"ruche": ["res://scenes/levels/level_03.tscn", 14.0, true],
	"fonderie": ["res://scenes/levels/mecha_04.tscn", 14.0, true],
	"cite": ["res://scenes/levels/humanoid_04.tscn", 14.0, true],
	"necropole": ["res://scenes/levels/undead_04.tscn", 14.0, true],
	"conquete": ["res://scenes/levels/conquest_01.tscn", 8.0, false],
	"ameliorations": ["res://scenes/ui/perk_tree_screen.tscn", 0.5, false],
	"editeur": ["res://scenes/ui/level_editor.tscn", 0.5, false],
}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_prepare_progress()
	var only := OS.get_cmdline_user_args()
	for shot_name: String in SHOTS:
		if not only.is_empty() and shot_name not in only:
			continue
		var shot: Array = SHOTS[shot_name]
		var node: Node = load(shot[0]).instantiate()
		root.add_child(node)
		await process_frame
		if shot[2]:
			_start_battle(node as Level)
		elif shot_name != "titre":
			# Sans focus, pas de fenêtre de détail ouverte sur le premier bouton.
			root.gui_release_focus()
		await create_timer(shot[1]).timeout
		await RenderingServer.frame_post_draw
		var path := OUT_DIR + shot_name + ".webp"
		root.get_texture().get_image().save_webp(path, true, 0.9)
		print("Capture : ", path)
		node.queue_free()
		Engine.time_scale = 1.0
		await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	quit()


## Premier monde gagné avec 3 étoiles, et la moitié du deuxième.
func _prepare_progress() -> void:
	Engine.set_meta(Progress.SAVE_PATH_META, SAVE_PATH)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var stars := [3, 3, 3, 3, 3, 3, 3, 2, 3]
	for i in stars.size():
		Progress.record_victory(CAMPAIGN.levels[i], stars[i])


## Pose une défense le long du chemin, avec toutes les tours du niveau, puis lance les
## vagues en accéléré pour que la capture montre un combat.
func _start_battle(level: Level) -> void:
	var gold := level.gold
	level.gold = 100000
	var map := level.map
	var cells: Array[Vector2i] = []
	for y in map.rows:
		for x in map.columns:
			var cell := Vector2i(x, y)
			if map.is_cell_buildable(cell) and _touches_path(map, cell):
				cells.append(cell)
	var types := level.tower_types
	var placed := 0
	# Une case sur trois, pour ne pas murer le chemin.
	for i in range(0, cells.size(), 3):
		if placed >= 10 or types.is_empty():
			break
		if level.place_tower(cells[i], types[placed % types.size()]):
			placed += 1
	level.gold = gold
	level.set_game_speed(2.0)
	level.start_next_wave()


func _touches_path(map: GameMap, cell: Vector2i) -> bool:
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if map.is_cell_on_path(cell + Vector2i(dx, dy)):
				return true
	return false
