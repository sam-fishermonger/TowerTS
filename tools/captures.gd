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
	"libre": ["res://scenes/levels/free_02.tscn", 9.0, true],
	"expedition": ["res://scenes/levels/mecha_02.tscn", 9.0, true],
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
		if shot_name == "expedition":
			_prepare_expedition()
		var node: Node = load(shot[0]).instantiate()
		root.add_child(node)
		await process_frame
		if shot[2]:
			# Une vague qui montre la spécialité du monde : la troisième de La Ruche (un porteur
			# de butin et un porteur de coffre), les Tunneliers de la quatrième vague de La
			# Fonderie, les Saboteurs de la Cité, les Banshees de la troisième de La Nécropole.
			var waves_before := {"ruche": 1, "fonderie": 2, "cite": 2, "necropole": 1}
			if waves_before.has(shot_name):
				(node as Level).spawner.current_wave = waves_before[shot_name]
			_start_battle(node as Level)
		elif shot_name == "conquete":
			_stage_conquest(node as Level)
		elif shot_name != "titre":
			# Sans focus, pas de fenêtre de détail ouverte sur le premier bouton.
			root.gui_release_focus()
		await create_timer(shot[1]).timeout
		if shot_name == "expedition":
			# Un coffre ramassé : le choix de son bonus s'ouvre par-dessus la partie.
			(node as Level).open_chest(Vector2.ZERO)
			for i in 3:
				await process_frame
		await RenderingServer.frame_post_draw
		var path := OUT_DIR + shot_name + ".webp"
		root.get_texture().get_image().save_webp(path, true, 0.9)
		print("Capture : ", path)
		node.queue_free()
		Engine.time_scale = 1.0
		await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	Progress.clear_cache()
	quit()


## Premier monde gagné avec 3 étoiles, et la moitié du deuxième.
func _prepare_progress() -> void:
	Engine.set_meta(Progress.SAVE_PATH_META, SAVE_PATH)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	Progress.clear_cache()
	# Pas de partie enregistrée : l'écran titre n'a pas de bouton Reprendre.
	SavedGame.clear()
	var stars := [3, 3, 3, 3, 3, 3, 3, 3, 2, 3]
	for i in stars.size():
		Progress.record_victory(CAMPAIGN.levels[i], stars[i])


## Mode Expédition : troisième étape, avec deux bonus de coffre déjà gagnés et des vies
## perdues en route.
func _prepare_expedition() -> void:
	var run := Expedition.new()
	run.rng_seed = 3
	run.levels.assign([CAMPAIGN.levels[1], CAMPAIGN.levels[4], "res://scenes/levels/mecha_02.tscn",
		CAMPAIGN.levels[9], CAMPAIGN.levels[10]])
	run.index = 2
	run.max_lives = 20
	run.lives = 14
	run.chest_levels = {ChestBonus.DAMAGE: 1, ChestBonus.BOUNTY: 1}
	Engine.set_meta(Level.EXPEDITION_META, run.to_dict())


## Pose une défense le long du chemin, avec toutes les tours du niveau, puis lance les
## vagues en accéléré pour que la capture montre un combat.
func _start_battle(level: Level) -> void:
	var gold := level.gold
	level.gold = 100000
	var map := level.map
	if map.free_layout:
		_build_maze(level, 16)
		level.gold = gold
		level.set_game_speed(2.0)
		level.start_next_wave()
		return
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


## Conquête : quelques tours et bâtiments déjà bâtis, deux ouvriers choisis envoyés miner
## un rocher, et la fiche de l'Atelier ouverte sur une recherche en cours.
func _stage_conquest(level: Level) -> void:
	var conquest := level.conquest
	level.gold = 100000
	conquest.stone = 10000
	conquest.essence = 100
	var cannon: TowerData = level.tower_types[0]
	for cell in [Vector2i(14, 4), Vector2i(11, 3), Vector2i(14, 7)]:
		var tower := level.place_tower(cell, cannon)
		if tower:
			conquest.build(tower, 999.0)
	var site := level.place_tower(Vector2i(16, 2), level.tower_types[1])
	if site:
		conquest.build(site, Conquest.build_time(site) * 0.4)
	for item in [[Vector2i(12, 6), Building.Kind.WORKSHOP], [Vector2i(10, 7), Building.Kind.HOUSE]]:
		var building := conquest.place_building(item[0], item[1])
		if building:
			conquest.build(building, 999.0)
	var workshop: Building = conquest.get_buildings(Building.Kind.WORKSHOP)[0]
	conquest.research_levels[Research.WORKER_SPEED] = 1
	conquest.research_levels[Research.TOWER_DAMAGE] = 1
	conquest.start_research(workshop, Research.TOWER_RANGE)
	level.gold = 420
	conquest.stone = 85
	conquest.essence = 6
	var workers := conquest.get_workers()
	conquest.select_workers([workers[0], workers[1]])
	var rock: Vector2i = conquest.rocks.keys()[0]
	for cell: Vector2i in conquest.rocks:
		if cell.x > rock.x or (cell.x == rock.x and cell.y < rock.y):
			rock = cell
	conquest.order_selected(rock)
	# La Corvée en cours, et un Voleur qui repart d'un Dépôt, le sac plein.
	conquest.start_corvee(30.0)
	var path := level.map.get_enemy_path(0)
	var progress := path.curve.get_baked_length() * 0.12
	var on_path := level.map.world_to_cell(path.to_global(path.curve.sample_baked(progress)))
	for offset in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
		level.gold = 1000
		conquest.stone = 1000
		var depot := conquest.place_building(on_path + offset, Building.Kind.DEPOT)
		if depot:
			conquest.build(depot, 999.0)
			break
	level.gold = 420
	conquest.stone = 85
	create_timer(5.6).timeout.connect(func() -> void:
		conquest.stone = 105
		conquest.essence = 11
		level.spawner.spawn(level.thief, path, progress - 40.0))


## Niveau libre : pose les tours une à une là où elles allongent le plus le chemin des
## monstres (sans fermer le passage), pour que la capture montre un labyrinthe.
func _build_maze(level: Level, count: int) -> void:
	var map := level.map
	var types := level.tower_types
	for i in count if not types.is_empty() else 0:
		var best := GameMap.NO_CELL
		var best_length := -1.0
		for y in map.rows:
			for x in map.columns:
				var cell := Vector2i(x, y)
				if not map.is_cell_buildable(cell) or not _touches_path(map, cell):
					continue
				var length := 0.0
				for points in map.get_routes_with(cell):
					for p in points.size() - 1:
						length += points[p].distance_to(points[p + 1])
				if length > best_length + 0.5:
					best = cell
					best_length = length
		if best == GameMap.NO_CELL or level.place_tower(best, types[i % types.size()]) == null:
			return


func _touches_path(map: GameMap, cell: Vector2i) -> bool:
	if map.free_layout:
		# Niveau libre : une case voisine du chemin actuel des monstres.
		for path in map.paths:
			for point in path.curve.get_baked_points():
				if (map.world_to_cell(path.to_global(point)) - cell).abs().x <= 1 \
						and (map.world_to_cell(path.to_global(point)) - cell).abs().y <= 1:
					return true
		return false
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if map.is_cell_on_path(cell + Vector2i(dx, dy)):
				return true
	return false
