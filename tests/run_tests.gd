extends SceneTree
## Tests de fumée, sans fenêtre :
##   godot --headless --fixed-fps 60 --path . -s res://tests/run_tests.gd
## --fixed-fps rend les parties simulées déterministes : chaque image avance le jeu
## du même pas, quelle que soit la vitesse de la machine.

const TITLE_SCREEN := preload("res://scenes/ui/title_screen.tscn")
const LEVEL_01 := preload("res://scenes/levels/level_01.tscn")
const LEVEL_02 := preload("res://scenes/levels/level_02.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const CANNON := preload("res://resources/towers/cannon.tres")
const SNIPER := preload("res://resources/towers/sniper.tres")
const GATLING := preload("res://resources/towers/gatling.tres")
const MORTAR := preload("res://resources/towers/mortar.tres")
const FROST := preload("res://resources/towers/frost.tres")
const SLIME := preload("res://resources/enemies/slime.tres")
const SHELL := preload("res://resources/enemies/shell.tres")

## Accélération des parties simulées (avec --fixed-fps 60 : 1/15 s de jeu par image).
const GAME_SPEED := 4.0

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_title_screen()
	await _test_health_component()
	await _test_entity_despawn()
	await _test_tower_placement()
	await _test_level_02_map()
	await _test_level_02_uses_both_paths()
	await _test_enemy_slow_and_armor()
	await _test_explosive_projectile()
	await _test_pulse_tower()
	await _test_defeat_without_towers()
	await _test_victory_level_01()
	await _test_victory_level_02()
	await _test_level_02_with_earned_gold()
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


func _spawn_level(scene: PackedScene) -> Level:
	paused = false
	var level: Level = scene.instantiate()
	root.add_child(level)
	await process_frame
	return level


func _free(node: Node) -> void:
	node.queue_free()
	paused = false
	Engine.time_scale = 1.0
	await process_frame


## Ajoute un ennemi immobile sur un chemin du niveau, à la distance donnée du départ.
func _add_still_enemy(level: Level, data: EnemyData, path_index: int, progress: float) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = data
	enemy.path = level.map.get_enemy_path(path_index)
	enemy.progress = progress
	level.enemies.add_child(enemy)
	enemy.set_process(false)
	return enemy


## Avance d'une image en jeu accéléré et renvoie le temps de jeu écoulé, en secondes.
func _step() -> float:
	Engine.time_scale = GAME_SPEED
	await process_frame
	return root.get_process_delta_time()


## Fait tourner le jeu jusqu'à la fin de partie (ou le délai maximal, en temps de jeu).
## Par défaut, chaque vague est lancée dès que la précédente a fini d'apparaître ;
## avec `wait_for_clear`, seulement quand plus aucun ennemi n'est en jeu, comme un joueur prudent.
## `before_frame` est appelé à chaque image, avant le lancement des vagues.
func _play_until_over(level: Level, max_game_seconds: float, wait_for_clear := false,
		before_frame := Callable()) -> void:
	var elapsed := 0.0
	while not level.is_over and elapsed < max_game_seconds:
		if before_frame.is_valid():
			before_frame.call()
		var cleared := get_nodes_in_group(Enemy.GROUP).is_empty()
		if not level.spawner.is_spawning and level.spawner.has_next_wave() and (cleared or not wait_for_clear):
			level.start_next_wave()
		elapsed += await _step()


## Place une tour sur chaque case, en alternant les types. Renvoie le nombre de tours posées.
func _place_defense(level: Level, cells: Array, types: Array) -> int:
	var placed := 0
	for i in cells.size():
		if level.place_tower(cells[i], types[i % types.size()]):
			placed += 1
	return placed


func _test_title_screen() -> void:
	print("Écran titre")
	var title := TITLE_SCREEN.instantiate()
	root.add_child(title)
	await process_frame
	_check(title.get_node("%PlayButton") is Button, "le bouton Jouer existe")
	_check(title.get_node("%PlayButton").has_focus(), "le bouton Jouer a le focus")
	_check(title.get_node("%LevelButtons").get_child_count() == 2, "un bouton par niveau")
	await _free(title)


func _test_health_component() -> void:
	print("Composant de santé")
	var health := HealthComponent.new()
	root.add_child(health)
	health.setup(20.0, 6.0)
	var depleted := [0]
	health.depleted.connect(func() -> void: depleted[0] += 1)
	_check(is_equal_approx(health.take_damage(10.0), 4.0), "l'armure réduit les dégâts")
	_check(is_equal_approx(health.take_damage(2.0), 1.0), "un coup inflige toujours au moins 1")
	health.take_damage(100.0)
	_check(health.is_depleted() and health.health == 0.0, "les points de vie ne passent pas sous 0")
	health.take_damage(10.0)
	_check(depleted[0] == 1, "le signal depleted n'est émis qu'une fois")
	await _free(health)


func _test_entity_despawn() -> void:
	print("Cycle de vie des entités")
	var entity := Entity.new()
	root.add_child(entity)
	entity.add_to_group("test_group")
	var count := [0]
	entity.despawned.connect(func(_e: Entity) -> void: count[0] += 1)
	entity.despawn()
	entity.despawn()
	_check(not entity.is_alive, "l'entité n'est plus vivante")
	_check(not entity.is_in_group("test_group"), "l'entité quitte ses groupes")
	_check(count[0] == 1, "despawned n'est émis qu'une fois")
	await process_frame
	_check(not is_instance_valid(entity), "l'entité est libérée")


func _test_tower_placement() -> void:
	print("Placement des tours (niveau 1)")
	var level := await _spawn_level(LEVEL_01)
	_check(level.gold == 150 and level.lives == 20, "or et vies de départ")
	_check(level.spawner.waves.size() == 5, "5 vagues définies")
	_check(level.tower_types.size() == 3, "3 types de tours proposés")
	_check(level.map.paths.size() == 1, "un seul chemin")
	var path_cell := Vector2i(4, 2)
	var free_cell := Vector2i(2, 4)
	_check(not level.map.is_cell_buildable(path_cell), "impossible de construire sur le chemin")
	_check(level.place_tower(path_cell, CANNON) == null, "placement refusé sur le chemin")
	_check(level.place_tower(Vector2i(-1, 0), CANNON) == null, "placement refusé hors de la grille")
	var tower := level.place_tower(free_cell, CANNON)
	_check(tower is ProjectileTower, "la tour placée vient de la scène de ses données")
	_check(level.gold == 100, "le coût de la tour est déduit")
	_check(tower.position == Vector2(160, 352), "la tour est centrée sur sa case")
	_check(level.map.get_occupant(free_cell) == tower, "la carte connaît l'occupant de la case")
	_check(level.place_tower(free_cell, CANNON) == null, "placement refusé sur une case occupée")
	_check(level.place_tower(Vector2i(2, 5), SNIPER) == null, "placement refusé sans assez d'or")
	_check(level.gold == 100, "un placement refusé ne coûte rien")
	level.select_tower(GATLING)
	_check(level.placer.selected_tower == GATLING, "le placeur garde la tour sélectionnée")
	_check(level.hud.tower_buttons.get_child(1).button_pressed, "le bouton de la tour sélectionnée est enfoncé")
	level.select_tower(null)
	_check(not level.hud.tower_buttons.get_child(1).button_pressed, "désélection")
	await _free(level)


func _test_level_02_map() -> void:
	print("Niveau 2 : carte")
	var level := await _spawn_level(LEVEL_02)
	_check(level.level_name == "Niveau 2" and level.gold == 220 and level.lives == 20, "nom, or et vies de départ")
	_check(level.spawner.waves.size() == 6, "6 vagues définies")
	_check(level.tower_types.size() == 5, "5 types de tours proposés")
	_check(level.map.paths.size() == 2, "deux chemins")
	_check(not level.has_next_level(), "c'est le dernier niveau")
	_check(level.map.is_cell_on_path(Vector2i(2, 1)), "le chemin nord bloque la construction")
	_check(level.map.is_cell_on_path(Vector2i(1, 9)), "le chemin sud bloque la construction")
	_check(level.map.is_cell_on_path(Vector2i(16, 6)), "le tronc commun bloque la construction")
	_check(level.map.is_cell_blocked(Vector2i(9, 7)), "les rochers sont des cases bloquées")
	_check(level.place_tower(Vector2i(9, 7), CANNON) == null, "placement refusé sur un rocher")
	for cell in level.map.blocked_cells:
		if level.map.is_cell_on_path(cell):
			_check(false, "le rocher %s est sur le chemin" % cell)
	_check(level.place_tower(Vector2i(8, 7), CANNON) != null, "placement accepté à côté d'un rocher")
	var paths := level.map.paths
	_check(paths[0].to_global(paths[0].curve.sample_baked(paths[0].curve.get_baked_length())) \
		.is_equal_approx(paths[1].to_global(paths[1].curve.sample_baked(paths[1].curve.get_baked_length()))),
		"les deux chemins mènent à la même base")
	await _free(level)


func _test_level_02_uses_both_paths() -> void:
	print("Niveau 2 : les vagues utilisent les deux chemins")
	var level := await _spawn_level(LEVEL_02)
	var used := {}
	level.spawner.enemy_spawned.connect(func(enemy: Enemy) -> void: used[enemy.path.name] = true)
	level.start_next_wave()
	var elapsed := 0.0
	while level.spawner.is_spawning and elapsed < 60.0:
		elapsed += await _step()
	_check(used.has("NorthPath") and used.has("SouthPath"), "des ennemis arrivent par le nord et par le sud")
	await _free(level)


func _test_enemy_slow_and_armor() -> void:
	print("Ennemis : ralentissement et armure")
	var level := await _spawn_level(LEVEL_02)
	var slime := _add_still_enemy(level, SLIME, 0, 100.0)
	_check(slime.global_position.is_equal_approx(Vector2(68, 160)), "l'ennemi est placé sur son chemin")
	slime.apply_slow(0.5, 1.0)
	_check(is_equal_approx(slime.get_speed(), SLIME.speed * 0.5), "le ralentissement réduit la vitesse")
	slime.apply_slow(0.8, 3.0)
	_check(is_equal_approx(slime.get_speed(), SLIME.speed * 0.5), "le ralentissement le plus fort l'emporte")
	slime.set_process(true)
	var elapsed := 0.0
	while slime.is_slowed() and elapsed < 10.0:
		elapsed += await _step()
	_check(is_equal_approx(slime.get_speed(), SLIME.speed), "la vitesse revient à la normale")
	Engine.time_scale = 1.0
	var shell := _add_still_enemy(level, SHELL, 1, 100.0)
	shell.take_damage(GATLING.damage)
	_check(is_equal_approx(shell.health.health, SHELL.max_health - 1.0), "la mitrailleuse rebondit sur la carapace")
	shell.take_damage(SNIPER.damage)
	_check(is_equal_approx(shell.health.health, SHELL.max_health - 1.0 - (SNIPER.damage - SHELL.armor)),
		"le sniper perce la carapace")
	await _free(level)


func _test_explosive_projectile() -> void:
	print("Projectile explosif")
	var level := await _spawn_level(LEVEL_02)
	var group: Array[Enemy] = []
	for offset in [0.0, 20.0, 40.0]:
		group.append(_add_still_enemy(level, SLIME, 0, 200.0 + offset))
	var far := _add_still_enemy(level, SLIME, 0, 400.0)
	var projectile: Projectile = MORTAR.projectile_scene.instantiate()
	projectile.setup(group[1], MORTAR)
	level.projectiles.add_child(projectile)
	projectile.global_position = group[1].global_position + Vector2(0, 100)
	var elapsed := 0.0
	while is_instance_valid(projectile) and elapsed < 10.0:
		elapsed += await _step()
	var all_hit := group.all(func(e: Enemy) -> bool: return e.health.health == SLIME.max_health - MORTAR.damage)
	_check(all_hit, "l'explosion touche tous les ennemis dans son rayon")
	_check(far.health.health == SLIME.max_health, "un ennemi hors du rayon n'est pas touché")
	await _free(level)


func _test_pulse_tower() -> void:
	print("Tour de givre")
	var level := await _spawn_level(LEVEL_02)
	# Case (4, 2) : juste sous le chemin nord, entre x = 192 et 320.
	var tower := level.place_tower(Vector2i(4, 2), FROST)
	_check(tower is PulseTower, "la tour de givre est une PulseTower")
	var near := _add_still_enemy(level, SLIME, 0, 290.0)
	var other := _add_still_enemy(level, SLIME, 0, 320.0)
	var far := _add_still_enemy(level, SLIME, 0, 30.0)
	await process_frame
	await process_frame
	_check(near.is_slowed() and other.is_slowed(), "l'onde ralentit tous les ennemis à portée")
	_check(near.health.health < SLIME.max_health and other.health.health < SLIME.max_health, "l'onde inflige des dégâts")
	_check(not far.is_slowed() and far.health.health == SLIME.max_health, "un ennemi hors de portée n'est pas touché")
	await _free(level)


func _test_defeat_without_towers() -> void:
	print("Défaite sans tours")
	var level := await _spawn_level(LEVEL_01)
	level.start_next_wave()
	_check(level.spawner.current_wave == 0 and level.spawner.is_spawning, "la vague 1 démarre")
	await _play_until_over(level, 600.0)
	_check(level.is_over and level.lives == 0, "la partie est perdue")
	_check(level.hud.end_panel.visible and level.hud.end_title.text == "Défaite", "écran de défaite affiché")
	_check(not level.hud.next_level_button.visible, "pas de niveau suivant après une défaite")
	_check(paused, "le jeu est en pause")
	await _free(level)


func _test_victory_level_01() -> void:
	print("Niveau 1 : victoire avec une défense")
	var level := await _spawn_level(LEVEL_01)
	level.gold = 5000
	var placed := _place_defense(level, [Vector2i(3, 3), Vector2i(5, 3), Vector2i(3, 6), Vector2i(5, 6),
			Vector2i(9, 2), Vector2i(11, 2), Vector2i(9, 6), Vector2i(11, 6),
			Vector2i(14, 2), Vector2i(16, 2), Vector2i(14, 7), Vector2i(16, 7)], [CANNON, GATLING])
	level.place_tower(Vector2i(7, 4), SNIPER)
	level.place_tower(Vector2i(13, 4), SNIPER)
	_check(placed == 12, "12 tours placées le long du chemin")
	var gold_before := level.gold
	await _play_until_over(level, 900.0)
	_check(level.is_over and level.lives > 0, "la partie est gagnée (vies restantes : %d)" % level.lives)
	_check(level.spawner.current_wave == 4, "les 5 vagues ont été jouées")
	_check(level.gold > gold_before, "les ennemis détruits rapportent de l'or")
	_check(level.hud.end_title.text == "Victoire !", "écran de victoire affiché")
	_check(level.hud.next_level_button.visible, "le bouton Niveau suivant est proposé")
	# Le niveau ajouté à la main n'est pas la scène courante : on le libère avant de changer de scène.
	level.hud.next_level_button.pressed.emit()
	await _free(level)
	await process_frame
	_check(current_scene != null and current_scene.scene_file_path == LEVEL_02.resource_path,
		"Niveau suivant ouvre le niveau 2")
	_check(not paused, "le jeu reprend au niveau suivant")
	if current_scene:
		await _free(current_scene)


func _test_victory_level_02() -> void:
	print("Niveau 2 : victoire avec une défense")
	var level := await _spawn_level(LEVEL_02)
	level.gold = 10000
	var placed := _place_defense(level, [
			Vector2i(1, 2), Vector2i(3, 2), Vector2i(5, 2), Vector2i(2, 6), Vector2i(4, 7), Vector2i(2, 8),
			Vector2i(5, 4), Vector2i(7, 4), Vector2i(9, 4), Vector2i(11, 4), Vector2i(7, 6), Vector2i(9, 6),
			Vector2i(11, 6), Vector2i(13, 4), Vector2i(13, 1), Vector2i(15, 3), Vector2i(15, 5), Vector2i(17, 4),
			Vector2i(15, 7), Vector2i(17, 7)],
		[CANNON, MORTAR, SNIPER, FROST, GATLING])
	_check(placed == 20, "20 tours placées le long des deux chemins (%d)" % placed)
	await _play_until_over(level, 1200.0)
	_check(level.is_over and level.lives > 0, "la partie est gagnée (vies restantes : %d)" % level.lives)
	_check(level.spawner.current_wave == 5, "les 6 vagues ont été jouées")
	_check(level.hud.end_title.text == "Victoire !", "écran de victoire affiché")
	_check(not level.hud.next_level_button.visible, "pas de niveau suivant après le dernier niveau")
	await _free(level)


## Rejoue le niveau 2 sans or bonus : les tours sont achetées dans l'ordre de la liste
## dès que l'or le permet. Vérifie que le niveau est gagnable avec son économie.
func _test_level_02_with_earned_gold() -> void:
	print("Niveau 2 : gagnable avec l'or de départ et l'or gagné")
	var level := await _spawn_level(LEVEL_02)
	var build_order: Array = [
		[Vector2i(5, 4), CANNON], [Vector2i(7, 4), CANNON], [Vector2i(9, 4), MORTAR],
		[Vector2i(7, 6), FROST], [Vector2i(11, 4), SNIPER], [Vector2i(9, 6), CANNON],
		[Vector2i(13, 4), MORTAR], [Vector2i(11, 6), GATLING], [Vector2i(15, 3), SNIPER],
		[Vector2i(13, 1), FROST], [Vector2i(15, 5), MORTAR], [Vector2i(17, 7), SNIPER],
		[Vector2i(15, 7), CANNON], [Vector2i(17, 4), MORTAR], [Vector2i(5, 6), SNIPER],
	]
	var bought := [0]
	await _play_until_over(level, 1200.0, true, func() -> void:
		while bought[0] < build_order.size() and level.gold >= build_order[bought[0]][1].cost:
			var item: Array = build_order[bought[0]]
			_check(level.place_tower(item[0], item[1]) != null, "achat de la tour %d" % (bought[0] + 1))
			bought[0] += 1)
	_check(level.is_over and level.lives > 0,
		"la partie est gagnée (vies restantes : %d, tours achetées : %d)" % [level.lives, bought[0]])
	await _free(level)
