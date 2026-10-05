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
	# Progression à part, vidée à chaque lancement : les tests ne touchent pas à celle du joueur.
	Engine.set_meta(Progress.SAVE_PATH_META, "user://test_progress.cfg")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Progress.get_save_path()))
	await _test_title_screen()
	await _test_progress()
	await _test_health_component()
	await _test_entity_despawn()
	await _test_tower_placement()
	await _test_tower_upgrade_stats()
	await _test_tower_upgrade_in_level()
	await _test_tower_info_panels()
	await _test_sell_tower()
	await _test_target_modes()
	await _test_level_02_map()
	await _test_level_02_uses_both_paths()
	await _test_enemy_slow_and_armor()
	await _test_explosive_projectile()
	await _test_damage_and_death_feedback()
	await _test_pulse_tower()
	await _test_lives_lost_feedback()
	await _test_pause_and_game_speed()
	await _test_fire_rate_independent_of_speed()
	await _test_wave_bonus_when_waves_overlap()
	await _test_wave_preview_and_early_call()
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
	var buttons: Array[Node] = title.get_node("%LevelButtons").get_children()
	_check(buttons.size() == title.CAMPAIGN.size(), "un bouton par niveau de la campagne")
	_check(not buttons[0].disabled and buttons[1].disabled and buttons[1].text.ends_with("Verrouillé"),
		"au départ, seul le niveau 1 est débloqué")
	_check(title.get_node("%PlayButton").text == "Jouer" and not title.get_node("%ResetButton").visible,
		"pas de progression à reprendre ni à effacer")
	await _free(title)


func _test_progress() -> void:
	print("Progression et étoiles")
	var campaign: Campaign = load("res://resources/campaign.tres")
	_check(campaign.get_next(LEVEL_01.resource_path) == LEVEL_02.resource_path, "la campagne enchaîne le niveau 1 et le 2")
	_check(Progress.stars_for(20, 20) == 3 and Progress.stars_for(10, 20) == 2 and Progress.stars_for(9, 20) == 1,
		"3 étoiles sans perte, 2 avec la moitié des vies, 1 sinon")
	_check(Progress.get_next_to_play(campaign) == LEVEL_01.resource_path, "Jouer ouvre le niveau 1")
	_check(Progress.record_victory(LEVEL_01.resource_path, 2), "une première victoire est un record")
	_check(not Progress.record_victory(LEVEL_01.resource_path, 1), "un moins bon résultat ne remplace pas le record")
	_check(Progress.get_stars(LEVEL_01.resource_path) == 2, "le meilleur résultat est gardé")
	_check(Progress.is_unlocked(campaign, 1), "gagner le niveau 1 débloque le niveau 2")
	_check(Progress.get_next_to_play(campaign) == LEVEL_02.resource_path, "Continuer ouvre le niveau 2")
	var saved := ConfigFile.new()
	_check(saved.load(Progress.get_save_path()) == OK and saved.get_value("stars", LEVEL_01.resource_path) == 2,
		"la progression est enregistrée sur le disque")
	var title := TITLE_SCREEN.instantiate()
	root.add_child(title)
	await process_frame
	var buttons: Array[Node] = title.get_node("%LevelButtons").get_children()
	_check(buttons[0].text == "Niveau 1\n★★☆" and not buttons[1].disabled, "l'écran titre montre les étoiles et le niveau débloqué")
	_check(title.get_node("%PlayButton").text == "Continuer", "le bouton devient Continuer")
	title.get_node("%ResetDialog").confirmed.emit()
	await process_frame
	buttons = title.get_node("%LevelButtons").get_children()
	_check(Progress.get_stars(LEVEL_01.resource_path) == 0 and buttons[1].disabled, "Effacer la progression reverrouille les niveaux")
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


func _test_tower_upgrade_stats() -> void:
	print("Améliorations : statistiques")
	for data: TowerData in [CANNON, GATLING, SNIPER, MORTAR, FROST]:
		_check(data.get_max_level() == 3 and not data.description.is_empty(),
			"%s : 2 améliorations et une description" % data.display_name)
	var base := CANNON.get_stats_at_level(1)
	_check(base.damage == CANNON.damage and base.attack_range == CANNON.attack_range, "niveau 1 = statistiques de base")
	var level_2 := CANNON.get_stats_at_level(2)
	_check(is_equal_approx(level_2.damage, 35.0) and is_equal_approx(level_2.attack_range, 165.0),
		"niveau 2 : dégâts ×1,4 et portée ×1,1")
	var level_3 := CANNON.get_stats_at_level(3)
	_check(is_equal_approx(level_3.damage, 49.0) and is_equal_approx(level_3.fire_rate, 1.25),
		"niveau 3 : les bonus se cumulent")
	_check(CANNON.damage == 25.0 and CANNON.attack_range == 150.0, "les données du type de tour ne changent pas")
	_check(CANNON.get_upgrade_cost(1) == 40 and CANNON.get_upgrade_cost(2) == 70 and CANNON.get_upgrade_cost(3) == -1,
		"prix des améliorations")
	var frost_3 := FROST.get_stats_at_level(3)
	_check(is_equal_approx(frost_3.slow_duration, FROST.slow_duration + 1.0), "le givre ralentit plus longtemps")
	_check(is_equal_approx(GATLING.get_stats_at_level(1).slow_duration, 0.0), "pas de ralentissement ajouté aux autres tours")


func _test_tower_upgrade_in_level() -> void:
	print("Améliorations : en jeu")
	var level := await _spawn_level(LEVEL_01)
	var tower := level.place_tower(Vector2i(2, 4), CANNON)
	_check(tower.level == 1 and tower.stats.damage == CANNON.damage, "une tour posée est au niveau 1")
	_check(level.upgrade_tower(tower) and level.gold == 60, "l'amélioration coûte 40 or")
	_check(tower.level == 2 and is_equal_approx(tower.stats.damage, 35.0), "la tour passe au niveau 2")
	_check(not level.upgrade_tower(tower) and level.gold == 60 and tower.level == 2,
		"amélioration refusée sans assez d'or")
	level.gold = 500
	_check(level.upgrade_tower(tower) and level.gold == 430 and tower.level == 3, "niveau 3 pour 70 or")
	_check(not tower.can_upgrade() and not level.upgrade_tower(tower) and level.gold == 430,
		"impossible de dépasser le niveau maximal")
	# La tour tire avec ses statistiques améliorées.
	_add_still_enemy(level, SLIME, 0, 224.0)
	var projectile: Projectile = null
	var elapsed := 0.0
	while projectile == null and elapsed < 5.0:
		elapsed += await _step()
		if level.projectiles.get_child_count() > 0:
			projectile = level.projectiles.get_child(0)
	_check(projectile != null and is_equal_approx(projectile.damage, tower.stats.damage),
		"les projectiles infligent les dégâts améliorés")
	await _free(level)


## Envoie un évènement directement au placeur de tours : sans fenêtre, les
## évènements injectés dans le viewport ne lui parviennent pas.
func _send_to_placer(level: Level, event: InputEvent) -> void:
	level.placer._unhandled_input(event)
	await process_frame


func _click(level: Level, screen_position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = screen_position
	await _send_to_placer(level, event)


func _test_tower_info_panels() -> void:
	print("Fiches des tours")
	var level := await _spawn_level(LEVEL_01)
	var hud := level.hud
	var button: Button = hud.tower_buttons.get_child(0)
	button.mouse_entered.emit()
	await process_frame
	var shop := hud.shop_info
	_check(shop.visible and shop.name_label.text == "Canon", "survol d'un bouton d'achat : fiche de la tour")
	_check(shop.footer_label.text.begins_with("Prix : 50 or"), "la fiche indique le prix")
	_check(not shop.upgrade_button.is_visible_in_tree() and not shop.sell_button.is_visible_in_tree() \
		and not shop.target_button.visible and not shop.close_button.visible, "pas de boutons sur l'aperçu")
	_check(shop.stats_grid.get_child_count() == 4 * 3, "4 statistiques pour le canon")
	_check(shop.position.y >= button.get_global_rect().end.y, "la fiche s'ouvre sous le bouton")
	button.mouse_exited.emit()
	_check(not shop.visible, "la fiche se ferme quand la souris quitte le bouton")

	var tower := level.place_tower(Vector2i(2, 4), CANNON)
	await _click(level, tower.global_position)
	var details := hud.tower_details
	_check(level.placer.inspected_tower == tower and tower.show_range, "clic sur une tour posée : elle est inspectée")
	_check(details.visible and details.tower == tower, "la fiche de la tour posée s'ouvre")
	_check(details.close_button.visible and details.upgrade_button.visible, "boutons Fermer et Améliorer")
	_check(details.level_label.text == "Niv. 1 / 3", "le niveau de la tour est affiché")
	_check(details.upgrade_button.text.ends_with("40 or") and not details.upgrade_button.disabled,
		"le bouton Améliorer indique son prix")
	await process_frame
	var tower_rect := Rect2(tower.global_position - Vector2.ONE * Tower.SIZE / 2.0, Vector2.ONE * Tower.SIZE)
	_check(not details.get_global_rect().intersects(tower_rect), "la fiche ne cache pas la tour")
	var bonus_shown := false
	for label: Label in details.stats_grid.get_children():
		bonus_shown = bonus_shown or label.text.begins_with("→")
	_check(bonus_shown, "la fiche montre les gains de la prochaine amélioration")

	details.upgrade_button.pressed.emit()
	_check(tower.level == 2 and level.gold == 60, "le bouton Améliorer améliore la tour et la fait payer")
	_check(details.level_label.text == "Niv. 2 / 3", "la fiche se met à jour")
	_check(details.upgrade_button.disabled, "bouton désactivé sans assez d'or")
	level.gold = 200
	_check(not details.upgrade_button.disabled, "bouton réactivé quand l'or suffit")
	details.upgrade_button.pressed.emit()
	_check(tower.level == 3 and details.upgrade_button.disabled and details.upgrade_button.text == "Niveau maximal",
		"niveau maximal")

	details.close_button.pressed.emit()
	_check(not details.visible and level.placer.inspected_tower == null, "le bouton Fermer ferme la fiche")
	_check(not tower.show_range, "la portée n'est plus affichée")

	await _click(level, tower.global_position)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	await _send_to_placer(level, escape)
	_check(not details.visible, "Échap ferme la fiche")

	await _click(level, tower.global_position)
	level.select_tower(GATLING)
	_check(not details.visible, "choisir une tour à poser ferme la fiche")
	await _free(level)


func _test_sell_tower() -> void:
	print("Vente des tours")
	var level := await _spawn_level(LEVEL_01)
	level.gold = 1000
	var cell := Vector2i(2, 4)
	var tower := level.place_tower(cell, CANNON)
	_check(tower.get_sell_value() == 35, "une tour neuve se revend 70 %% de son prix (35 or)")
	level.upgrade_tower(tower)
	_check(tower.get_total_cost() == 90 and tower.get_sell_value() == 63, "les améliorations comptent dans la revente")
	await _click(level, tower.global_position)
	var details := level.hud.tower_details
	_check(details.sell_button.visible and details.sell_button.text.ends_with("63 or"), "le bouton Vendre indique le prix")
	var gold_before := level.gold
	details.sell_button.pressed.emit()
	_check(level.gold == gold_before + 63, "la vente rend l'or")
	_check(not tower.is_alive and level.map.get_occupant(cell) == null, "la tour quitte la carte")
	_check(not details.visible and level.placer.inspected_tower == null, "la fiche se ferme")
	_check(level.map.is_cell_buildable(cell), "la case est de nouveau libre")
	_check(level.sell_tower(tower) == 0 and level.gold == gold_before + 63, "une tour ne se vend qu'une fois")
	await process_frame
	_check(level.place_tower(cell, GATLING) != null, "on peut reconstruire sur la case")
	await _free(level)


func _test_target_modes() -> void:
	print("Choix de la cible")
	var level := await _spawn_level(LEVEL_01)
	level.gold = 1000
	var tower := level.place_tower(Vector2i(2, 4), SNIPER)
	var tough: EnemyData = SLIME.duplicate()
	tough.max_health = 500.0
	# Trois ennemis immobiles à portée : en tête, en queue, et le plus résistant au milieu.
	var ahead := _add_still_enemy(level, SLIME, 0, 260.0)
	var strong := _add_still_enemy(level, tough, 0, 200.0)
	var behind := _add_still_enemy(level, SLIME, 0, 120.0)
	_check(tower.target_mode == Tower.TargetMode.FIRST and tower.find_target() == ahead,
		"par défaut, la tour vise l'ennemi le plus avancé")
	tower.set_target_mode(Tower.TargetMode.LAST)
	_check(tower.find_target() == behind, "Dernier : l'ennemi le moins avancé")
	tower.set_target_mode(Tower.TargetMode.STRONGEST)
	_check(tower.find_target() == strong, "Le plus fort : l'ennemi qui a le plus de vie")
	tower.set_target_mode(Tower.TargetMode.CLOSEST)
	var closest: Enemy = [ahead, strong, behind].reduce(func(a: Enemy, b: Enemy) -> Enemy:
		return a if tower.global_position.distance_to(a.global_position) <= tower.global_position.distance_to(b.global_position) else b)
	_check(tower.find_target() == closest, "Le plus proche : l'ennemi le plus près de la tour")

	await _click(level, tower.global_position)
	var details := level.hud.tower_details
	_check(details.target_button.visible and details.target_button.text == "Cible : Le plus proche",
		"la fiche affiche la règle de ciblage")
	details.target_button.pressed.emit()
	_check(tower.target_mode == Tower.TargetMode.FIRST and details.target_button.text == "Cible : Premier",
		"le bouton passe à la règle suivante")
	var frost := level.place_tower(Vector2i(2, 5), FROST)
	await _click(level, frost.global_position)
	_check(not details.target_button.visible, "pas de choix de cible pour le Givre, qui frappe tout autour de lui")
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


func _test_damage_and_death_feedback() -> void:
	print("Dégâts affichés, or gagné et tache au sol")
	var level := await _spawn_level(LEVEL_02)
	var shell := _add_still_enemy(level, SHELL, 1, 100.0)
	level._on_enemy_spawned(shell)
	_check(is_equal_approx(shell.take_damage(SNIPER.damage), SNIPER.damage - SHELL.armor),
		"take_damage renvoie les dégâts après armure")
	var texts := level.effects.get_children().filter(func(n: Node) -> bool: return n is FloatingText)
	_check(texts.size() == 1 and texts[0].text == str(roundi(SNIPER.damage - SHELL.armor)),
		"les dégâts réellement subis s'affichent au-dessus de l'ennemi")
	var gold_before := level.gold
	var death_position := shell.global_position
	shell.take_damage(10000.0)
	_check(level.gold == gold_before + SHELL.reward, "la mort rapporte la prime")
	var gold_texts := level.effects.get_children().filter(
		func(n: Node) -> bool: return n is FloatingText and n.text == "+%d" % SHELL.reward)
	_check(gold_texts.size() == 1, "le gain de pièces s'affiche à la mort")
	_check(level.stains.get_child_count() == 1 and level.stains.get_child(0).global_position == death_position,
		"une tache reste au sol à l'endroit de la mort")
	var stain: GroundStain = level.stains.get_child(0)
	var elapsed := 0.0
	while elapsed < 2.0:
		elapsed += await _step()
	_check(level.effects.get_child_count() == 0, "les textes flottants disparaissent rapidement")
	_check(is_instance_valid(stain) and stain.get_alpha() < GroundStain.START_ALPHA,
		"la tache s'estompe lentement")
	while is_instance_valid(stain) and elapsed < GroundStain.DURATION + 2.0:
		elapsed += await _step()
	_check(not is_instance_valid(stain), "la tache finit par disparaître")
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


func _test_lives_lost_feedback() -> void:
	print("Effet de perte de vies")
	var level := await _spawn_level(LEVEL_01)
	var enemy := _add_still_enemy(level, SLIME, 0, 0.0)
	level._on_enemy_spawned(enemy)
	var material := level.hud.damage_flash.material as ShaderMaterial
	_check(material.get_shader_parameter("intensity") == 0.0, "pas de voile rouge au départ")
	enemy.reached_end.emit(enemy)
	await process_frame
	_check(level.lives == level.starting_lives - SLIME.damage, "le joueur perd des vies")
	_check(material.get_shader_parameter("intensity") > 0.3, "un voile rouge apparaît")
	_check(level.hud.lives_label.scale.x > 1.0, "le compteur de vies grossit")
	var texts := level.effects.get_children().filter(func(n: Node) -> bool: return n is FloatingText)
	_check(texts.any(func(t: FloatingText) -> bool: return t.text == "-%d" % SLIME.damage),
		"« -%d » s'affiche à la sortie" % SLIME.damage)
	_check(get_root().get_visible_rect().has_point(texts[0].position), "le texte reste dans l'écran")
	for i in 60:
		await process_frame
	_check(is_zero_approx(material.get_shader_parameter("intensity")), "le voile disparaît")
	_check(level.hud.lives_label.scale.is_equal_approx(Vector2.ONE), "le compteur reprend sa taille")
	await _free(level)


func _test_pause_and_game_speed() -> void:
	print("Pause et vitesse de jeu")
	var level := await _spawn_level(LEVEL_01)
	var hud := level.hud
	_check(hud.speed_buttons.get_child_count() == 3, "trois vitesses proposées")
	_check(Engine.time_scale == 1.0 and hud.speed_buttons.get_child(0).button_pressed, "le jeu démarre en x1")
	hud.speed_buttons.get_child(2).pressed.emit()
	_check(Engine.time_scale == 3.0 and level.game_speed == 3.0, "le bouton x3 accélère le jeu")
	_check(hud.speed_buttons.get_child(2).button_pressed and not hud.speed_buttons.get_child(0).button_pressed,
		"le bouton x3 est enfoncé")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_2
	key.pressed = true
	hud._unhandled_key_input(key)
	_check(Engine.time_scale == 2.0, "la touche 2 passe en x2")
	# En AZERTY, la touche 1 sans Maj donne « & » : c'est sa position qui compte.
	key.keycode = KEY_AMPERSAND
	key.physical_keycode = KEY_1
	hud._unhandled_key_input(key)
	_check(Engine.time_scale == 1.0, "la touche 1 passe en x1 en AZERTY")
	key.keycode = KEY_NONE
	key.physical_keycode = KEY_KP_2
	hud._unhandled_key_input(key)
	_check(Engine.time_scale == 2.0, "le 2 du pavé numérique passe en x2")

	level.start_next_wave()
	for i in 30:
		await process_frame
	var enemy: Enemy = get_nodes_in_group(Enemy.GROUP)[0]
	hud.pause_button.pressed.emit()
	_check(paused and level.is_paused and hud.pause_overlay.visible, "le bouton Pause met le jeu en pause")
	_check(hud.pause_button.text == "Reprendre", "le bouton propose de reprendre")
	var progress := enemy.progress
	for i in 10:
		await process_frame
	_check(enemy.progress == progress, "les ennemis ne bougent plus pendant la pause")
	_check(hud.next_wave_button.disabled and not level.can_start_next_wave(), "pas de vague lancée pendant la pause")
	level.gold = 1000
	level.select_tower(CANNON)
	await _click(level, level.map.cell_to_world(Vector2i(2, 4)))
	var paused_tower := level.map.get_occupant(Vector2i(2, 4)) as Tower
	_check(paused_tower != null, "on peut poser une tour pendant la pause")
	await _click(level, paused_tower.global_position)
	_check(hud.tower_details.visible, "on peut ouvrir la fiche d'une tour pendant la pause")
	hud.tower_details.upgrade_button.pressed.emit()
	_check(paused_tower.level == 2, "on peut améliorer pendant la pause")
	hud.tower_details.sell_button.pressed.emit()
	_check(not paused_tower.is_alive, "on peut vendre pendant la pause")
	key.physical_keycode = KEY_SPACE
	hud._unhandled_key_input(key)
	_check(not paused and not hud.pause_overlay.visible, "Espace relance le jeu")
	await process_frame
	_check(enemy.progress > progress, "les ennemis repartent")

	level._end_game(false)
	_check(Engine.time_scale == 1.0, "la fin de partie remet la vitesse à x1")
	_check(hud.pause_button.disabled, "pause indisponible après la fin de partie")
	level.set_paused(false)
	_check(paused, "la pause de fin de partie ne peut pas être levée")
	hud.speed_buttons.get_child(2).pressed.emit()
	await _free(level)
	level = await _spawn_level(LEVEL_01)
	_check(Engine.time_scale == 1.0, "un nouveau niveau repart en x1")
	await _free(level)


## Nombre de coups reçus par un ennemi immobile pendant `game_seconds` secondes de jeu.
func _count_hits(tower_data: TowerData, speed: float, game_seconds: float) -> int:
	var level := await _spawn_level(LEVEL_01)
	level.gold = 10000
	var tower := level.place_tower(Vector2i(2, 4), tower_data)
	level.upgrade_tower(tower)
	var target_data: EnemyData = SLIME.duplicate()
	target_data.max_health = 1e9
	var enemy := _add_still_enemy(level, target_data, 0, 0.0)
	enemy.global_position = tower.global_position + Vector2(40, 0)
	var hits := [0]
	enemy.damaged.connect(func(_enemy: Enemy, _amount: float) -> void: hits[0] += 1)
	Engine.time_scale = speed
	for i in roundi(game_seconds * 60.0 / speed):
		await process_frame
	await _free(level)
	return hits[0]


func _test_fire_rate_independent_of_speed() -> void:
	print("Cadence de tir indépendante de la vitesse de jeu")
	# Mitrailleuse niveau 2 : 6,5 tirs/s, soit 65 tirs en 10 s (à un tir près : le premier part tout de suite).
	var expected := roundi(GATLING.get_stats_at_level(2).fire_rate * 10.0)
	var at_x1 := await _count_hits(GATLING, 1.0, 10.0)
	var at_x3 := await _count_hits(GATLING, 3.0, 10.0)
	_check(absi(at_x1 - expected) <= 1, "x1 : %d tirs pour %d attendus" % [at_x1, expected])
	_check(absi(at_x3 - expected) <= 1, "x3 : %d tirs pour %d attendus" % [at_x3, expected])


func _test_wave_bonus_when_waves_overlap() -> void:
	print("Bonus de vague quand les vagues se chevauchent")
	var level := await _spawn_level(LEVEL_01)
	Engine.time_scale = GAME_SPEED
	level.start_next_wave()
	while level.spawner.is_spawning:
		await process_frame
	# La vague 2 est lancée alors que des ennemis de la vague 1 sont encore en jeu.
	level.start_next_wave()
	while level.spawner.is_spawning:
		await process_frame
	var gold_before := level.gold
	var rewards := 0
	for enemy: Enemy in get_nodes_in_group(Enemy.GROUP):
		rewards += enemy.data.reward
		enemy.take_damage(1e9)
	var bonuses := level.spawner.waves[0].bonus_gold + level.spawner.waves[1].bonus_gold
	_check(level.gold == gold_before + rewards + bonuses,
		"les bonus des deux vagues sont versés (%d or attendus, %d reçus)" % [rewards + bonuses, level.gold - gold_before])
	await _free(level)


func _test_wave_preview_and_early_call() -> void:
	print("Aperçu de la prochaine vague et prime d'avance")
	var level := await _spawn_level(LEVEL_02)
	var hud := level.hud
	await process_frame
	_check(hud.wave_preview.visible and hud.wave_preview_label.get_parsed_text().contains("12 Slime"),
		"l'aperçu annonce la première vague (%s)" % hud.wave_preview_label.get_parsed_text())
	_check(level.get_early_call_bonus() == 0 and not hud.wave_preview_label.get_parsed_text().contains("maintenant"),
		"pas de prime quand la carte est vide")
	level.start_next_wave()
	await process_frame
	_check(level.get_early_call_bonus() == 0, "pas de prime tant que la vague apparaît (le bouton est désactivé)")
	Engine.time_scale = GAME_SPEED
	while level.spawner.is_spawning:
		await process_frame
	await process_frame
	var bonus := roundi(level.spawner.waves[1].bonus_gold * level.early_call_bonus_ratio)
	_check(bonus > 0 and level.get_early_call_bonus() == bonus, "prime de %d or si des ennemis sont encore en jeu" % bonus)
	_check(hud.wave_preview_label.get_parsed_text().contains("Lancer maintenant : +%d or" % bonus),
		"l'aperçu annonce la prime")
	var gold_before := level.gold
	level.start_next_wave()
	_check(level.gold == gold_before + bonus, "la prime est versée au lancement")
	_check(level.effects.get_children().any(func(n: Node) -> bool: return n is FloatingText and n.text == "+%d" % bonus),
		"« +%d » s'affiche sous le bouton" % bonus)
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
	var stars := Progress.stars_for(level.lives, level.starting_lives)
	_check(level.hud.end_stars.visible and level.hud.end_stars.text == Progress.star_text(stars), "les étoiles s'affichent (%d)" % stars)
	_check(Progress.get_stars(LEVEL_01.resource_path) == stars, "la victoire est enregistrée")
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
