extends SceneTree
## Tests de fumée, sans fenêtre :
##   godot --headless --path . -s res://tests/run_tests.gd

const TITLE_SCREEN := preload("res://scenes/ui/title_screen.tscn")
const LEVEL_01 := preload("res://scenes/levels/level_01.tscn")
const CANNON := preload("res://resources/towers/cannon.tres")
const SNIPER := preload("res://resources/towers/sniper.tres")
const GATLING := preload("res://resources/towers/gatling.tres")

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_title_screen()
	await _test_tower_placement()
	await _test_defeat_without_towers()
	await _test_victory_with_towers()
	if _failures == 0:
		print("TOUS LES TESTS SONT PASSÉS")
	else:
		printerr("%d échec(s)" % _failures)
	quit(1 if _failures else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("  ok   ", message)
	else:
		_failures += 1
		printerr("  ÉCHEC ", message)


func _spawn_level() -> Level:
	paused = false
	var level: Level = LEVEL_01.instantiate()
	root.add_child(level)
	await process_frame
	return level


func _free(node: Node) -> void:
	node.queue_free()
	paused = false
	Engine.time_scale = 1.0
	await process_frame


## Fait tourner le jeu jusqu'à la fin de partie (ou le délai maximal, en temps de jeu).
func _play_until_over(level: Level, max_game_seconds: float) -> void:
	Engine.time_scale = 20.0
	var start := Time.get_ticks_msec()
	while not level.is_over and (Time.get_ticks_msec() - start) * 20.0 / 1000.0 < max_game_seconds:
		if not level.spawner.is_spawning and level.spawner.has_next_wave():
			level.start_next_wave()
		await process_frame


func _test_title_screen() -> void:
	print("Écran titre")
	var title := TITLE_SCREEN.instantiate()
	root.add_child(title)
	await process_frame
	_check(title.get_node("%PlayButton") is Button, "le bouton Jouer existe")
	_check(title.get_node("%PlayButton").has_focus(), "le bouton Jouer a le focus")
	await _free(title)


func _test_tower_placement() -> void:
	print("Placement des tours")
	var level := await _spawn_level()
	_check(level.gold == 150 and level.lives == 20, "or et vies de départ")
	_check(level.spawner.waves.size() == 5, "5 vagues définies")
	_check(level.tower_types.size() == 3, "3 types de tours proposés")
	var path_cell := Vector2i(4, 2)
	var free_cell := Vector2i(2, 4)
	_check(not level.is_cell_buildable(path_cell), "impossible de construire sur le chemin")
	_check(level.place_tower(path_cell, CANNON) == null, "placement refusé sur le chemin")
	_check(level.place_tower(Vector2i(-1, 0), CANNON) == null, "placement refusé hors de la grille")
	var tower := level.place_tower(free_cell, CANNON)
	_check(tower != null, "placement accepté sur une case libre")
	_check(level.gold == 100, "le coût de la tour est déduit")
	_check(tower.position == Vector2(160, 352), "la tour est centrée sur sa case")
	_check(level.place_tower(free_cell, CANNON) == null, "placement refusé sur une case occupée")
	_check(level.place_tower(Vector2i(2, 5), SNIPER) == null, "placement refusé sans assez d'or")
	_check(level.gold == 100, "un placement refusé ne coûte rien")
	level.select_tower(GATLING)
	_check(level.hud.tower_buttons.get_child(1).button_pressed, "le bouton de la tour sélectionnée est enfoncé")
	level.select_tower(null)
	_check(not level.hud.tower_buttons.get_child(1).button_pressed, "désélection")
	await _free(level)


func _test_defeat_without_towers() -> void:
	print("Défaite sans tours")
	var level := await _spawn_level()
	level.start_next_wave()
	_check(level.spawner.current_wave == 0 and level.spawner.is_spawning, "la vague 1 démarre")
	await _play_until_over(level, 600.0)
	_check(level.is_over and level.lives == 0, "la partie est perdue")
	_check(level.hud.end_panel.visible and level.hud.end_title.text == "Défaite", "écran de défaite affiché")
	_check(paused, "le jeu est en pause")
	await _free(level)


func _test_victory_with_towers() -> void:
	print("Victoire avec une défense")
	var level := await _spawn_level()
	level.gold = 5000
	var placed := 0
	for cell: Vector2i in [Vector2i(3, 3), Vector2i(5, 3), Vector2i(3, 6), Vector2i(5, 6),
			Vector2i(9, 2), Vector2i(11, 2), Vector2i(9, 6), Vector2i(11, 6),
			Vector2i(14, 2), Vector2i(16, 2), Vector2i(14, 7), Vector2i(16, 7)]:
		if level.place_tower(cell, GATLING if placed % 2 else CANNON):
			placed += 1
	level.place_tower(Vector2i(7, 4), SNIPER)
	level.place_tower(Vector2i(13, 4), SNIPER)
	_check(placed == 12, "12 tours placées le long du chemin")
	var gold_before := level.gold
	await _play_until_over(level, 900.0)
	_check(level.is_over and level.lives > 0, "la partie est gagnée (vies restantes : %d)" % level.lives)
	_check(level.spawner.current_wave == 4, "les 5 vagues ont été jouées")
	_check(level.gold > gold_before, "les ennemis détruits rapportent de l'or")
	_check(level.hud.end_title.text == "Victoire !", "écran de victoire affiché")
	await _free(level)
