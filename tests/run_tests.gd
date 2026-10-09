extends SceneTree
## Tests de fumée, sans fenêtre :
##   godot --headless --fixed-fps 60 --path . -s res://tests/run_tests.gd
## --fixed-fps rend les parties simulées déterministes : chaque image avance le jeu
## du même pas, quelle que soit la vitesse de la machine.

const TITLE_SCREEN := preload("res://scenes/ui/title_screen.tscn")
const PERK_TREE_SCREEN := preload("res://scenes/ui/perk_tree_screen.tscn")
const WORLD_SELECT_SCREEN := preload("res://scenes/ui/world_select_screen.tscn")
const LEVEL_01 := preload("res://scenes/levels/level_01.tscn")
const LEVEL_02 := preload("res://scenes/levels/level_02.tscn")
const LEVEL_03 := preload("res://scenes/levels/level_03.tscn")
const LEVEL_04 := preload("res://scenes/levels/level_04.tscn")
const LEVEL_05 := preload("res://scenes/levels/level_05.tscn")
const LEVEL_06 := preload("res://scenes/levels/level_06.tscn")
const LEVEL_07 := preload("res://scenes/levels/level_07.tscn")
const MECHA_01 := preload("res://scenes/levels/mecha_01.tscn")
const HUMANOID_01 := preload("res://scenes/levels/humanoid_01.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const CANNON := preload("res://resources/towers/cannon.tres")
const SNIPER := preload("res://resources/towers/sniper.tres")
const GATLING := preload("res://resources/towers/gatling.tres")
const MORTAR := preload("res://resources/towers/mortar.tres")
const FROST := preload("res://resources/towers/frost.tres")
const BEAM := preload("res://resources/towers/beam.tres")
const FLAME := preload("res://resources/towers/flame.tres")
const PESTICIDE := preload("res://resources/towers/pesticide.tres")
const JAMMER := preload("res://resources/towers/jammer.tres")
const RAIL := preload("res://resources/towers/rail.tres")
const MARKSMAN := preload("res://resources/towers/marksman.tres")
const TEARGAS := preload("res://resources/towers/teargas.tres")
const ARC := preload("res://resources/towers/arc.tres")
const COIL := preload("res://resources/towers/coil.tres")
const MAGNET := preload("res://resources/towers/magnet.tres")
const CHENILLARD := preload("res://resources/enemies/mecha/chenillard.tres")
const LARVE := preload("res://resources/enemies/insectoid/larve.tres")
const SCARABEE := preload("res://resources/enemies/insectoid/scarabee.tres")
const COUVEUSE := preload("res://resources/enemies/insectoid/couveuse.tres")
const SENTINELLE := preload("res://resources/enemies/mecha/sentinelle.tres")
const SOLDAT := preload("res://resources/enemies/humanoid/soldat.tres")
const MEDECIN := preload("res://resources/enemies/humanoid/medecin.tres")
const REINE := preload("res://resources/enemies/insectoid/reine.tres")
const GENERAL := preload("res://resources/enemies/humanoid/general.tres")
const FRELON := preload("res://resources/enemies/insectoid/frelon.tres")
const MANTE := preload("res://resources/enemies/insectoid/mante.tres")
const TUNNELIER := preload("res://resources/enemies/mecha/tunnelier.tres")
const SABOTEUR := preload("res://resources/enemies/humanoid/saboteur.tres")
const BANSHEE := preload("res://resources/enemies/undead/banshee.tres")
const REVENANT := preload("res://resources/enemies/undead/revenant.tres")
const LEXICON_SCREEN := preload("res://scenes/ui/lexicon_screen.tscn")
const ACHIEVEMENTS_SCREEN := preload("res://scenes/ui/achievements_screen.tscn")
const BEHEMOTH := preload("res://resources/enemies/mecha/behemoth.tres")
const UNDEAD_01 := preload("res://scenes/levels/undead_01.tscn")
const CENSER := preload("res://resources/towers/censer.tres")
const BELL := preload("res://resources/towers/bell.tres")
const CHEVALIER := preload("res://resources/enemies/undead/chevalier.tres")
const SQUELETTE := preload("res://resources/enemies/undead/squelette.tres")
const LICHE := preload("res://resources/enemies/undead/liche.tres")
const CONQUEST_01 := preload("res://scenes/levels/conquest_01.tscn")
const CONQUEST_06 := preload("res://scenes/levels/conquest_06.tscn")
const TUTORIAL := preload("res://scenes/levels/tutorial.tscn")
const FREEZE_POWER := preload("res://resources/powers/freeze.tres")
const CONQUEST_SELECT_SCREEN := preload("res://scenes/ui/conquest_select_screen.tscn")
const PILLARDE := preload("res://resources/enemies/insectoid/pillarde.tres")
const CHAPARDEUSE := preload("res://resources/enemies/insectoid/chapardeuse.tres")
const FREE_01 := preload("res://scenes/levels/free_01.tscn")
const FREE_SELECT_SCREEN := preload("res://scenes/ui/free_select_screen.tscn")

## Accélération des parties simulées (avec --fixed-fps 60 : 1/15 s de jeu par image).
const GAME_SPEED := 4.0

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# Progression à part, vidée à chaque lancement : les tests ne touchent pas à celle du joueur.
	Engine.set_meta(Progress.SAVE_PATH_META, "user://test_progress.cfg")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Progress.get_save_path()))
	Progress.clear_cache()
	SavedGame.clear()
	# Les textes vérifiés sont ceux du jeu en français, quelle que soit la langue du système.
	GameSettings.apply_language()
	GameSettings.apply_accessibility()
	await _test_title_screen()
	await _test_unlocks()
	await _test_progress()
	await _test_perk_tree()
	await _test_perks_in_level()
	await _test_biome_towers_in_tree()
	await _test_sound()
	await _test_language()
	await _test_health_component()
	await _test_entity_despawn()
	await _test_tower_placement()
	await _test_tower_upgrade_stats()
	await _test_tower_upgrade_in_level()
	await _test_tower_info_panels()
	await _test_touch_controls()
	await _test_gamepad()
	await _test_accessibility()
	await _test_sell_tower()
	await _test_undo_placement()
	await _test_saved_game()
	await _test_target_modes()
	await _test_level_02_map()
	await _test_level_02_uses_both_paths()
	await _test_enemy_slow_and_armor()
	await _test_explosive_projectile()
	await _test_damage_and_death_feedback()
	await _test_pulse_tower()
	await _test_lives_lost_feedback()
	await _test_pause_and_game_speed()
	await _test_shop_hotkeys()
	await _test_fire_rate_independent_of_speed()
	await _test_wave_bonus_when_waves_overlap()
	await _test_wave_preview_and_early_call()
	await _test_interest()
	await _test_powers_in_tree()
	await _test_meteors()
	await _test_freeze()
	await _test_reinforcements()
	await _test_path_preview()
	await _test_defeat_without_towers()
	await _test_victory_level_01()
	await _test_victory_level_02()
	await _test_level_02_with_earned_gold()
	await _test_level_03_map()
	await _test_splitting_enemy()
	await _test_beam_tower()
	await _test_shielded_enemy()
	await _test_healer_enemy()
	await _test_burn_and_flame_tower()
	await _test_gas_clouds()
	await _test_jammer_and_rail()
	await _test_marksman()
	await _test_arc_tower()
	await _test_coil_tower()
	await _test_magnet_tower()
	await _test_flying_enemies()
	await _test_stealthy_enemies()
	await _test_burrowing_enemies()
	await _test_saboteurs()
	await _test_necropolis_flyer_and_stealth()
	await _test_crossings_in_tree()
	await _test_tower_choice()
	await _test_worlds()
	await _test_spawn_spread()
	await _test_endless_mode()
	await _test_daily_challenge()
	await _test_daily_history()
	await _test_mutators()
	await _test_difficulties()
	await _test_specializations()
	await _test_konami_code()
	await _test_elites()
	await _test_carriers_and_chests()
	await _test_expedition()
	await _test_bosses()
	await _test_necropolis()
	await _test_level_editor()
	await _test_conquest()
	await _test_conquest_victory()
	await _test_tutorial()
	await _test_conquest_buildings()
	await _test_conquest_hud()
	await _test_conquest_worker_orders()
	await _test_conquest_workshop()
	await _test_conquest_top_bar()
	await _test_raiders()
	await _test_thieves()
	await _test_corvee()
	await _test_logistics()
	await _test_conquest_progress()
	await _test_free_levels()
	await _test_free_level_enemies()
	await _test_free_levels_progress()
	await _test_free_conquest()
	await _test_free_level_editor()
	await _test_detail_windows()
	await _test_lexicon()
	await _test_end_stats()
	await _test_achievements()
	await _test_biome_tiles()
	await _test_relief()
	await _test_sprite_cache()
	await _test_level_03_with_earned_gold()
	await _test_levels_04_to_06_maps()
	await _test_levels_04_to_06_with_earned_gold()
	await _test_world_levels_maps()
	await _test_world_levels_balance()
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


## `relief` à false : l'ancienne vue de dessus, en tuiles.
func _spawn_level(scene: PackedScene, relief := true) -> Level:
	paused = false
	var level: Level = scene.instantiate()
	(level.get_node("Map") as GameMap).relief = relief
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


## Joue une partie sans or bonus, comme un joueur prudent : les `tower_count` premières
## tours de `build_order` ([case, type] par tour) sont achetées dans l'ordre dès que l'or
## le permet, et chaque vague n'est lancée qu'une fois la carte vidée. Avec `upgrade`, une
## fois toutes les tours posées, l'or qui reste améliore la tour la moins chère à améliorer.
## La partie est libérée à la fin ; renvoie { won, lives, bought }.
func _play_build_order(scene: PackedScene, build_order: Array, tower_count: int,
		max_game_seconds := 1500.0, upgrade := false) -> Dictionary:
	var level := await _spawn_level(scene)
	var bought := [0]
	await _play_until_over(level, max_game_seconds, true, func() -> void:
		while bought[0] < tower_count and level.gold >= build_order[bought[0]][1].get_cost():
			var item: Array = build_order[bought[0]]
			if level.place_tower(item[0], item[1]) == null:
				_check(false, "achat de la tour %d en %s" % [bought[0] + 1, item[0]])
			bought[0] += 1
		if upgrade and bought[0] >= tower_count:
			var cheapest: Tower = null
			for tower: Tower in level.towers.get_children():
				if tower.is_alive and tower.can_upgrade() \
						and (cheapest == null or tower.get_upgrade_cost() < cheapest.get_upgrade_cost()):
					cheapest = tower
			if cheapest and level.gold >= cheapest.get_upgrade_cost():
				level.upgrade_tower(cheapest))
	var result := { won = level.is_over and level.lives > 0, lives = level.lives, bought = bought[0] }
	await _free(level)
	return result


## Place une tour sur chaque case, en alternant les types. Renvoie le nombre de tours posées.
func _place_defense(level: Level, cells: Array, types: Array) -> int:
	var placed := 0
	for i in cells.size():
		if level.place_tower(cells[i], types[i % types.size()]):
			placed += 1
	return placed


func _test_title_screen() -> void:
	print("Écran titre et sélection des mondes")
	var title := TITLE_SCREEN.instantiate()
	root.add_child(title)
	await process_frame
	_check(title.get_node("%PlayButton") is Button, "le bouton Jouer existe")
	_check(title.get_node("%PlayButton").has_focus(), "le bouton Jouer a le focus")
	_check(title.get_node("%LexiconButton").text == "Lexique", "le bouton Lexique existe")
	_check(title.get_main_buttons().all(func(b: Button) -> bool: return b.visible)
		and title.get_play_buttons().all(func(b: Button) -> bool: return not b.visible),
		"le menu principal ne montre que Jouer, Améliorations, Lexique, Succès, Options et Quitter")
	title.get_node("%PlayButton").pressed.emit()
	_check(title.is_play_menu_open() and title.get_play_buttons().all(func(b: Button) -> bool: return b.visible)
		and not title.get_node("%PerksButton").visible and title.get_node("%CampaignButton").has_focus(),
		"Jouer ouvre le choix du mode, Campagne a le focus")
	_check(title.get_node("%WorldsButton").text == "Mondes", "le bouton Mondes ouvre la sélection")
	_check(title.get_node("%DailyButton").text.begins_with("Défi du jour"), "le bouton Défi du jour existe")
	_check(title.get_node("%EditorButton").text.begins_with("Éditeur de niveau"), "le bouton Éditeur de niveau existe")
	_check(title.get_node("%ConquestButton").text.begins_with("Conquête"), "le bouton Conquête existe")
	_check(title.is_locked(title.get_node("%ExpeditionButton")) and title.get_node("%ExpeditionButton").text.begins_with("Expédition"),
		"le bouton Expédition attend la progression de la campagne")
	_check(title.get_node("%CampaignButton").text == "Campagne" and not title.get_node("%ResetButton").visible,
		"pas de progression à reprendre ni à effacer")
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	Input.parse_input_event(cancel)
	await process_frame
	_check(not title.is_play_menu_open() and title.get_node("%PlayButton").has_focus(), "Échap revient au menu principal")
	title.get_node("%PlayButton").pressed.emit()
	title.get_node("%BackButton").pressed.emit()
	_check(not title.is_play_menu_open() and title.get_node("%PerksButton").visible, "Retour aussi")
	await _free(title)
	await _test_title_demo()
	var screen := await _spawn_world_select()
	_check(screen.get_node("%Worlds").get_child_count() == 4, "une carte par monde")
	var first: Button = screen.get_level_button(LEVEL_01.resource_path)
	var second: Button = screen.get_level_button(LEVEL_02.resource_path)
	_check(not first.disabled and first.has_focus() and second.disabled and second.text.ends_with("Verrouillé"),
		"au départ, seul le niveau 1-1 est débloqué, et il a le focus")
	_check(screen.get_level_button(MECHA_01.resource_path).disabled
		and screen.get_card(1).find_child("LockedHint", true, false) != null, "La Fonderie est verrouillée")
	_check(screen.get_card(0).find_child("LockedHint", true, false) == null, "La Ruche est ouverte")
	await _free(screen)


## La partie simulée derrière l'écran titre se joue toute seule, en silence, sans
## rien enregistrer ni mettre le jeu en pause à la fin.
func _test_title_demo() -> void:
	var title := TITLE_SCREEN.instantiate()
	root.add_child(title)
	await process_frame
	var demo: TitleDemo = title.get_node("%Demo")
	var level := demo.level
	_check(level != null and level.is_demo and not level.hud.visible, "un niveau tourne derrière le menu, sans HUD")
	_check(not title.get_node("%DemoLabel").text.is_empty(), "le niveau simulé est affiché")
	_check(Sound.are_effects_muted(), "la démo ne joue pas de sons")
	var elapsed := 0.0
	while elapsed < 10.0:
		elapsed += await _step()
	_check(level.towers.get_child_count() >= 3, "la démo pose des tours (%d)" % level.towers.get_child_count())
	_check(level.spawner.current_wave == 0, "la démo lance la première vague")
	# Carte vidée d'un coup : la vague suivante part peu après.
	while level.spawner.is_spawning:
		elapsed += await _step()
	for enemy in get_nodes_in_group(Enemy.GROUP):
		enemy.queue_free()
	elapsed = 0.0
	while elapsed < 3.0:
		elapsed += await _step()
	_check(level.spawner.current_wave == 1, "la démo lance la vague suivante une fois la carte vidée")
	level._end_game(true)
	await process_frame
	_check(not paused and Perks.get_earned_stars() == 0, "la fin de la démo ne met pas en pause et n'enregistre rien")
	var finished_path := level.scene_file_path
	elapsed = 0.0
	while demo.level == level and elapsed < 20.0:
		elapsed += await _step()
	_check(demo.level != level and demo.level.scene_file_path != finished_path, "un autre niveau prend la suite")
	await _free(title)
	_check(not Sound.are_effects_muted(), "les sons reviennent en quittant l'écran titre")


## Les modes s'ouvrent au fil de la campagne (Unlocks) ; verrouillé, un bouton n'ouvre rien
## et montre une bulle qui dit comment le débloquer.
func _test_unlocks() -> void:
	print("Déblocage progressif des modes")
	Progress.reset_campaign()
	var campaign: Campaign = load("res://resources/campaign.tres")
	_check(Unlocks.get_levels_won() == 0 and not Unlocks.is_unlocked(Unlocks.Feature.DAILY),
		"au départ, aucun mode n'est ouvert")
	var order := Unlocks.LEVELS_WON.keys().map(func(f: int) -> int: return Unlocks.LEVELS_WON[f])
	var sorted := order.duplicate()
	sorted.sort()
	_check(order == sorted, "les modes s'ouvrent dans l'ordre de la liste : %s" % [order])
	var title := TITLE_SCREEN.instantiate()
	root.add_child(title)
	await process_frame
	title.get_node("%PlayButton").pressed.emit()
	var daily: Button = title.get_node("%DailyButton")
	var editor: Button = title.get_node("%EditorButton")
	_check(title.is_locked(daily) and daily.text == "Défi du jour  ·  Verrouillé" and daily.self_modulate != Color.WHITE
		and not daily.disabled, "le défi du jour est verrouillé, assombri, mais garde le focus")
	_check([title.get_node("%ConquestButton"), title.get_node("%FreeButton"), title.get_node("%ExpeditionButton"), editor].all(
		func(b: Button) -> bool: return title.is_locked(b) and b.tooltip_text.is_empty()),
		"Conquête, Niveaux libres, Expédition et Éditeur aussi, sans infobulle")
	var children := root.get_child_count()
	daily.pressed.emit()
	await process_frame
	await process_frame
	_check(root.get_child_count() == children and title.is_inside_tree(), "appuyer sur un mode verrouillé n'ouvre rien")
	_check(title.lock_bubble.visible and title.lock_bubble.button == daily
		and title.lock_bubble.label.text == "Gagnez 3 niveaux de la campagne pour débloquer le défi du jour.\nNiveaux gagnés : 0 / 3",
		"une bulle dit comment le débloquer : %s" % title.lock_bubble.label.text)
	var bubble_rect: Rect2 = title.lock_bubble.get_global_rect()
	_check(bubble_rect.position.x >= daily.get_global_rect().end.x and get_root().get_visible_rect().encloses(bubble_rect),
		"la bulle est à côté du bouton, dans l'écran")
	editor.grab_focus()
	_check(title.lock_bubble.button == editor and title.lock_bubble.label.text.ends_with("0 / 5"),
		"le focus (clavier, manette) passe la bulle au bouton suivant")
	title.get_node("%CampaignButton").grab_focus()
	_check(not title.lock_bubble.visible, "la bulle se cache en quittant le bouton")
	for i in 3:
		Progress.record_victory(campaign.levels[i], 1)
	title._refresh()
	_check(not title.is_locked(daily) and daily.text == "Défi du jour" and daily.self_modulate == Color.WHITE,
		"trois niveaux gagnés ouvrent le défi du jour")
	_check(title.is_locked(editor) and Unlocks.get_hint(Unlocks.Feature.EDITOR).ends_with("3 / 5"),
		"l'éditeur attend toujours, la bulle compte les niveaux gagnés")
	await _free(title)

	# Écran des mondes : Mode infini et Mutateurs.
	var screen := await _spawn_world_select()
	var mode_button: Button = screen.get_node("%ModeButton")
	_check(mode_button.text.ends_with("Verrouillé") and screen.mutators_button.text.ends_with("Verrouillé"),
		"Mode infini et Mutateurs sont verrouillés")
	mode_button.toggled.emit(true)
	_check(not screen.endless_mode and not mode_button.button_pressed and screen.lock_bubble.visible
		and screen.lock_bubble.label.text.contains("le mode infini"), "le mode infini verrouillé montre sa bulle")
	screen.mutators_button.pressed.emit()
	_check(screen.mutators_panel == null and screen.lock_bubble.button == screen.mutators_button
		and screen.lock_bubble.label.text.contains("12 niveaux"), "les mutateurs aussi")
	Mutators.set_active([DailyChallenge.RAPIDES])
	_check(Mutators.get_active().is_empty(), "verrouillés, les mutateurs choisis ne s'appliquent pas")
	await _free(screen)

	# Le niveau gagné qui ouvre un mode le dit sur l'écran de fin.
	Progress.record_victory(campaign.levels[3], 1)
	var level := await _spawn_level(LEVEL_05)
	level._end_game(true)
	_check(level.hud.end_message.text.contains("Vous avez débloqué l'éditeur de niveau !")
		and Unlocks.is_unlocked(Unlocks.Feature.EDITOR), "la victoire qui ouvre l'éditeur l'annonce")
	await _free(level)
	for i in 14:
		Progress.record_victory(campaign.levels[i], 1)
	_check(Mutators.get_active() == [DailyChallenge.RAPIDES] and Unlocks.is_unlocked(Unlocks.Feature.CONQUEST),
		"quatorze niveaux ouvrent tout, et les mutateurs choisis reviennent")
	screen = await _spawn_world_select()
	_check(screen.get_node("%ModeButton").text == "∞  Mode infini" and screen.mutators_button.text.ends_with("1"),
		"Mode infini et Mutateurs sont ouverts")
	await _free(screen)
	Mutators.set_active([])
	Progress.reset_campaign()


## Gagne (une étoile) les derniers niveaux de la campagne, sans toucher aux premiers :
## tous les modes s'ouvrent (Unlocks).
func _unlock_all_modes() -> void:
	var levels: Array[String] = (load("res://resources/campaign.tres") as Campaign).levels
	var needed: int = Unlocks.LEVELS_WON.values().max()
	for i in needed:
		Progress.record_victory(levels[levels.size() - 1 - i], 1)


func _spawn_world_select() -> Control:
	var screen := WORLD_SELECT_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	return screen


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
	# La progression est gardée en mémoire : modifier une valeur lue ne la change pas.
	var scores := Progress.get_daily_scores()
	scores["copie"] = 1
	_check(not Progress.get_daily_scores().has("copie") and Progress.get_stars(LEVEL_01.resource_path) == 2,
		"les valeurs lues sont des copies de la progression en mémoire")
	var screen := await _spawn_world_select()
	_check(screen.get_level_button(LEVEL_01.resource_path).text == "1-1\n★★☆"
		and not screen.get_level_button(LEVEL_02.resource_path).disabled,
		"la sélection montre les étoiles et le niveau débloqué")
	_check(screen.get_card(0).find_child("Stars", true, false).text == "★ 2 / 84", "la carte du monde compte ses étoiles")
	await _free(screen)
	var title := TITLE_SCREEN.instantiate()
	root.add_child(title)
	await process_frame
	_check(title.get_node("%CampaignButton").text == "Continuer", "le bouton Campagne devient Continuer")
	_check(title.get_node("%WorldsButton").text.ends_with("★ 2 / 336"), "l'écran titre montre les étoiles de la campagne")
	title.get_node("%ResetDialog").confirmed.emit()
	await process_frame
	_check(Progress.get_stars(LEVEL_01.resource_path) == 0 and not Progress.is_unlocked(campaign, 1),
		"Effacer la progression reverrouille les niveaux")
	await _free(title)


func _test_perk_tree() -> void:
	print("Arbre des améliorations")
	var tree := Perks.TREE
	var ids := {}
	var consistent := true
	for perk in tree.perks:
		consistent = consistent and not ids.has(perk.id) and perk.cost > 0
		ids[perk.id] = true
		for required in perk.requires:
			consistent = consistent and tree.perks.has(required) and required.row < perk.row
	_check(consistent, "identifiants uniques, et chaque amélioration demande des améliorations des rangs au-dessus")
	_check(tree.get_page_branches(0).size() == 3, "page Bonus : 3 branches, tours, or, vies")
	var poudre := tree.get_perk("poudre")
	var longue_vue := tree.get_perk("longue_vue")
	_check(Perks.get_available_stars() == 0 and not Perks.can_buy(poudre), "sans étoiles, rien à acheter")
	Progress.record_victory(LEVEL_01.resource_path, 3)
	Progress.record_victory(LEVEL_01.resource_path, 3, Difficulty.FACILE)
	Progress.record_victory(LEVEL_02.resource_path, 2)
	_check(Perks.get_earned_stars() == 8 and Perks.get_available_stars() == 8,
		"les étoiles des niveaux gagnés, dans chaque difficulté, sont la monnaie")

	var title := TITLE_SCREEN.instantiate()
	root.add_child(title)
	await process_frame
	_check(title.get_node("%PerksButton").text.ends_with("★ 8"), "l'écran titre signale les étoiles à dépenser")
	await _free(title)

	var screen := PERK_TREE_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	_check(screen.get_button(longue_vue).text.ends_with("Verrouillé"), "Longue-vue est verrouillée tant que Poudre fine n'est pas achetée")
	screen.get_button(longue_vue).pressed.emit()
	_check(not Perks.is_owned(longue_vue), "une amélioration verrouillée ne s'achète pas")
	_check(screen.info_status.text.contains("Poudre fine"), "la fiche dit ce qui manque")
	screen.get_button(poudre).pressed.emit()
	_check(Perks.is_owned(poudre) and Perks.get_available_stars() == 8 - poudre.cost,
		"acheter Poudre fine coûte %d étoiles" % poudre.cost)
	_check(screen.get_button(poudre).text.ends_with("Acquis")
		and screen.get_button(longue_vue).text.ends_with("★ %d" % longue_vue.cost),
		"Poudre fine est acquise et débloque Longue-vue")
	_check(screen.stars_label.text.begins_with("★ %d à dépenser" % (8 - poudre.cost)), "le compteur d'étoiles se met à jour")
	_check(not screen.buy(poudre), "une amélioration ne s'achète qu'une fois")
	_check(is_equal_approx(CANNON.get_stats_at_level(1).damage, 25.0 * 1.1), "Poudre fine : +10 % de dégâts sur les tours")
	_check(Perks.is_unlocked(longue_vue) and not Perks.buy(longue_vue) and Perks.get_available_stars() == 8 - poudre.cost,
		"une amélioration trop chère ne s'achète pas (Longue-vue : %d étoiles)" % longue_vue.cost)
	screen.get_node("%RefundButton").pressed.emit()
	_check(Perks.get_owned_ids().is_empty() and Perks.get_available_stars() == 8, "Réinitialiser l'arbre rend toutes les étoiles")
	_check(is_equal_approx(CANNON.get_stats_at_level(1).damage, 25.0), "et retire les bonus")
	Perks.buy(poudre)
	Progress.reset_campaign()
	_check(Perks.get_owned_ids().is_empty(), "Effacer la progression efface aussi les améliorations")
	await _free(screen)


func _test_perks_in_level() -> void:
	print("Arbre des améliorations : effets en jeu")
	_win_in_all_difficulties([LEVEL_01.resource_path, LEVEL_02.resource_path, LEVEL_03.resource_path,
		LEVEL_04.resource_path])
	for id in ["tresor", "architecte", "brocanteur", "remparts", "infirmerie", "pillage"]:
		_check(Perks.buy(Perks.TREE.get_perk(id)), "achat : %s" % Perks.TREE.get_perk(id).display_name)
	var level := await _spawn_level(LEVEL_01)
	_check(level.gold == 200 and level.lives == 25 and level.starting_lives == 25,
		"Trésor de guerre et Remparts : 200 or et 25 vies au départ")
	_check(CANNON.get_cost() == 45 and CANNON.get_upgrade_cost(1) == 36, "Architecte : tours et améliorations 10 % moins chères")
	var tower := level.place_tower(Vector2i(2, 4), CANNON)
	_check(tower != null and level.gold == 155, "la pose coûte le prix réduit")
	tower.refundable = false
	_check(tower.get_sell_value() == roundi(45 * 0.85), "Brocanteur : la vente rend 85 %")
	_check(level.get_enemy_reward(LARVE) == roundi(LARVE.reward * 1.2), "Pillage : +20 % d'or par ennemi")
	level.lives = 20
	level.spawner.current_wave = 0
	level._check_wave_cleared()
	_check(level.lives == 21, "Infirmerie : une vague repoussée rend 1 vie")
	level.lives = 25
	level.spawner.current_wave = 1
	level._check_wave_cleared()
	_check(level.lives == 25, "sans dépasser les vies de départ")
	await _free(level)
	Progress.reset_campaign()


## Enregistre une victoire à 3 étoiles dans chaque difficulté pour chacun des niveaux.
func _win_in_all_difficulties(paths: Array[String]) -> void:
	for path in paths:
		for d in Difficulty.COUNT:
			Progress.record_victory(path, 3, d)


func _test_biome_towers_in_tree() -> void:
	print("Arbre des améliorations : tours des mondes")
	var campaign: Campaign = load("res://resources/campaign.tres")
	var tree := Perks.TREE
	var tower_perks := tree.perks.filter(func(p: Perk) -> bool: return not p.unlocks_tower.is_empty())
	var per_world := [0, 0, 0, 0]
	for perk: Perk in tower_perks:
		if perk.required_world >= 0:
			per_world[perk.required_world] += 1
	_check(per_world == [2, 2, 2, 2], "2 tours par monde (%s)" % [per_world])
	_check(tower_perks.all(func(p: Perk) -> bool: return tree.get_page(p) == 1 and p.get_unlocked_tower() != null),
		"elles sont toutes sur la page Tours des mondes")
	var campaign_stars := campaign.size() * Progress.MAX_LEVEL_STARS
	# La page Logistique (bonus de la Conquête) se paie avec les étoiles de la Conquête.
	var logistics := tree.page_names.find("Logistique")
	var logistics_cost := 0
	for perk in tree.get_page_perks(logistics):
		logistics_cost += perk.cost
	var main_cost := tree.get_total_cost() - logistics_cost
	_check(main_cost <= campaign_stars and main_cost >= campaign_stars * 0.9,
		"l'arbre sans la Logistique (%d étoiles) coûte presque toutes les étoiles de la campagne (%d)" % [main_cost, campaign_stars])
	_check(main_cost > campaign.size() * 3 * 3,
		"il faut des étoiles de Cauchemar pour tout acheter")
	var conquest_stars := ConquestLevels.size() * Progress.MAX_LEVEL_STARS
	_check(logistics_cost <= conquest_stars and logistics_cost >= conquest_stars * 0.85,
		"la page Logistique (%d étoiles) coûte presque toutes les étoiles de la Conquête (%d)" % [logistics_cost, conquest_stars])

	var flame := tree.get_perk("flame")
	var jammer := tree.get_perk("jammer")
	for path in campaign.worlds[0].levels:
		Progress.record_victory(path, 3)
	_check(Perks.is_unlocked(flame) and Perks.is_unlocked(jammer) and not Perks.is_unlocked(tree.get_perk("marksman")),
		"finir La Ruche ouvre les branches de La Ruche et de La Fonderie, pas celle de La Cité")
	var screen := PERK_TREE_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	_check(not screen.get_button(flame).is_visible_in_tree(), "les tours des mondes sont sur un autre onglet")
	screen.show_page(1)
	_check(screen.get_button(flame).is_visible_in_tree() and not screen.get_button(tree.get_perk("poudre")).is_visible_in_tree(),
		"l'onglet Tours des mondes les affiche")
	_check(screen._lock_labels[5].text.contains("La Fonderie"), "la branche de La Cité dit quel monde finir pour l'ouvrir")
	screen._show_info(tree.get_perk("marksman"))
	_check(screen.info_status.text.contains("La Fonderie"), "la fiche aussi")
	_check(screen.buy(flame) and Perks.is_owned(flame), "le Lance-flammes s'achète")
	await _free(screen)

	var level := await _spawn_level(LEVEL_01)
	_check(level.tower_types.size() == 4 and level.tower_types.has(FLAME), "le Lance-flammes s'ajoute à la barre d'achat")
	var fresh: Level = LEVEL_01.instantiate()
	_check(fresh.tower_types.size() == 3, "sans changer la liste du niveau lui-même")
	fresh.free()
	await _free(level)

	_win_in_all_difficulties(campaign.levels)
	for perk: Perk in tower_perks:
		Perks.buy(perk)
	_check(Perks.get_unlocked_towers().size() == 11, "les 11 tours achetées (8 des mondes, 3 croisements)")
	# En Facile, on prend jusqu'à 9 tours : la barre d'achat doit les tenir.
	Difficulty.set_current(Difficulty.FACILE)
	level = await _spawn_level(HUMANOID_01)
	level.choose_towers(level.get_default_tower_choice())
	await process_frame
	_check(level.tower_types.size() == 9 and level.hud.tower_shop.get_child_count() == 9, "9 tours dans la barre d'achat")
	var bar := level.hud.bottom_bar.get_global_rect()
	var controls := level.hud.pause_button.get_global_rect()
	var last_slot: Control = level.hud.tower_shop.get_child(8)
	_check(is_equal_approx(bar.size.y, 96.0) and bar.end.x <= 1280.0 and last_slot.get_global_rect().end.x < controls.position.x,
		"elles tiennent dans la barre, sans pousser les boutons de droite")
	_check(not level.hud.shop_hint.visible, "le rappel des commandes laisse sa place")
	await _free(level)
	Difficulty.set_current(Difficulty.MOYEN)
	Progress.reset_campaign()


func _test_sound() -> void:
	print("Sons et musique")
	var sound := Sound.get_player()
	_check(sound != null and sound.name == "SoundPlayer", "le nœud des sons est chargé au démarrage")
	_check(AudioServer.get_bus_index(&"Music") != -1 and AudioServer.get_bus_index(&"Sfx") != -1,
		"bus Musique et Sons créés")
	for data: TowerData in [CANNON, GATLING, SNIPER, MORTAR, FROST, BEAM]:
		_check(data.attack_sound != null, "%s : son de tir défini" % data.display_name)
	for sound_name: StringName in sound.SOUNDS:
		_check(sound.SOUNDS[sound_name] is AudioStream, "son « %s » chargé" % sound_name)
	var music_bus := AudioServer.get_bus_index(&"Music")
	var sfx_bus := AudioServer.get_bus_index(&"Sfx")
	var title := TITLE_SCREEN.instantiate()
	root.add_child(title)
	await process_frame
	var options: OptionsMenu = title.open_options()
	await process_frame
	_check(options.music_check.button_pressed and options.sound_check.button_pressed
		and options.music_slider.value == 100.0, "Options : musique et sons à 100 %")
	options.music_check.button_pressed = false
	_check(AudioServer.is_bus_mute(music_bus) and not options.music_slider.editable,
		"la case Musique coupe la musique")
	_check(Progress.get_setting("music", true) == false, "le choix est enregistré")
	options.music_check.button_pressed = true
	_check(not AudioServer.is_bus_mute(music_bus), "et la remet")
	options.sound_check.button_pressed = false
	_check(AudioServer.is_bus_mute(sfx_bus), "la case Sons coupe les effets")
	options.sound_check.button_pressed = true
	var full_db := AudioServer.get_bus_volume_db(music_bus)
	options.music_slider.value = 50.0
	_check(is_equal_approx(Sound.get_music_volume(), 0.5)
		and is_equal_approx(AudioServer.get_bus_volume_db(music_bus), full_db + linear_to_db(0.5)),
		"le curseur règle le volume de la musique")
	_check(is_equal_approx(AudioServer.get_bus_volume_db(sfx_bus), Sound.BUS_BASE_DB[&"Sfx"]),
		"sans toucher aux sons")
	options.sound_slider.value = 0.0
	_check(AudioServer.is_bus_mute(sfx_bus) and Sound.is_sound_enabled(), "le curseur des sons à 0 les coupe")
	options.sound_slider.value = 80.0
	_check(not AudioServer.is_bus_mute(sfx_bus) and is_equal_approx(Sound.get_sound_volume(), 0.8),
		"et à 80 % les remet")
	options.fullscreen_check.button_pressed = true
	_check(Progress.get_setting("fullscreen", false) == true, "le plein écran est enregistré")
	options.fullscreen_check.button_pressed = false
	options.speed_buttons[1].pressed.emit()
	_check(GameSettings.get_default_speed() == 2.0, "vitesse au départ : x2 enregistrée")
	options.close_button.pressed.emit()
	await process_frame
	_check(not is_instance_valid(options), "Fermer referme les options")
	await _free(title)

	# En jeu : la partie démarre à la vitesse choisie, et les options la mettent en pause.
	var level := await _spawn_level(LEVEL_01)
	_check(Engine.time_scale == 2.0 and level.hud.speed_buttons.get_child(1).button_pressed,
		"le niveau démarre à la vitesse des options")
	level.hud.options_button.pressed.emit()
	await process_frame
	_check(level.is_paused and paused and level.hud.options_menu != null, "le bouton Options met la partie en pause")
	level.hud.options_menu.music_slider.value = 30.0
	_check(is_equal_approx(Sound.get_music_volume(), 0.3), "les volumes se règlent en jeu")
	level.hud.options_menu.close()
	await process_frame
	_check(not level.is_paused and not paused and level.hud.options_menu == null, "la partie reprend en fermant")
	level.set_paused(true)
	level.hud.open_options()
	level.hud.options_menu.close()
	_check(level.is_paused, "mais reste en pause si elle l'était")
	await _free(level)
	title = TITLE_SCREEN.instantiate()
	root.add_child(title)
	await process_frame
	options = title.open_options()
	await process_frame
	_check(options.music_slider.value == 30.0 and options.sound_slider.value == 80.0
		and options.speed_buttons[1].button_pressed, "l'écran titre reprend les réglages choisis en jeu")
	Sound.set_music_volume(1.0)
	Sound.set_sound_volume(1.0)
	GameSettings.set_default_speed(1.0)
	await _free(title)


func _test_language() -> void:
	print("Langue")
	_check(GameSettings.get_language() == "fr" and TranslationServer.get_locale() == "fr",
		"le jeu est en français par défaut")
	var title := TITLE_SCREEN.instantiate()
	root.add_child(title)
	await process_frame
	var options: OptionsMenu = title.open_options()
	await process_frame
	_check(options.language_buttons.size() == GameSettings.LANGUAGES.size()
		and options.language_buttons[0].button_pressed, "Options : une case par langue, Français cochée")
	options.language_buttons[1].pressed.emit()
	await process_frame
	_check(GameSettings.get_language() == "en" and Progress.get_setting("language", "") == "en"
		and options.language_buttons[1].button_pressed, "English se choisit et s'enregistre")
	_check(tr("Jouer") == "Play" and title.tr("Jouer") == "Play", "les textes passent en anglais")
	var worlds_button: Button = title.get_node("%WorldsButton")
	_check(worlds_button.text == "Worlds", "les textes composés de l'écran titre sont refaits")
	_check(options.language_buttons[0].text == "Français" and options.language_buttons[0].auto_translate_mode
		== Node.AUTO_TRANSLATE_MODE_DISABLED, "chaque langue garde son propre nom")
	# Chaque texte traduit doit l'être entièrement : pas de msgstr vide dans le fichier.
	var english: Translation = load("res://translations/en.po")
	var untranslated := Array(english.get_message_list()).filter(func(message: String) -> bool:
		return english.get_message(message).is_empty())
	_check(english.locale == "en" and english.get_message_count() > 20 and untranslated.is_empty(),
		"translations/en.po : chaque texte a sa traduction %s" % [untranslated])
	options.language_buttons[0].pressed.emit()
	await process_frame
	_check(GameSettings.get_language() == "fr" and worlds_button.text == "Mondes", "retour au français")
	await _free(title)
	# En jeu : les Options du HUD changent la langue, et le HUD refait ses textes composés.
	var level: Level = LEVEL_01.instantiate()
	root.add_child(level)
	await process_frame
	level.hud.open_options()
	level.hud.options_menu.language_buttons[1].pressed.emit()
	await process_frame
	_check(level.hud.level_label.text.begins_with("Level 1-1") and level.hud.gold_label.text.begins_with("Gold: "),
		"en jeu, le HUD passe en anglais : %s, %s" % [level.hud.level_label.text, level.hud.gold_label.text])
	_check(EnemyData.plural("Momie", 3) == "Mummies" and EnemyData.plural("Larve", 2) == "Larvae",
		"pluriels anglais des monstres")
	level.hud.options_menu.language_buttons[0].pressed.emit()
	await process_frame
	_check(level.hud.level_label.text.begins_with("Niveau 1-1") and level.hud.gold_label.text.begins_with("Or : "),
		"et revient au français")
	level.hud.options_menu.close()
	await _free(level)


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

	health = HealthComponent.new()
	root.add_child(health)
	health.setup(50.0, 5.0, 20.0, 10.0)
	_check(is_equal_approx(health.take_damage(8.0), 8.0) and health.shield == 12.0 and health.health == 50.0,
		"le bouclier encaisse le coup en entier, sans armure")
	_check(is_equal_approx(health.take_damage(20.0), 12.0 + 3.0) and health.shield == 0.0 and health.health == 47.0,
		"le reste du coup passe sur les points de vie, avec l'armure")
	health._process(1.0)
	_check(health.shield == 0.0, "le bouclier ne se recharge pas juste après un coup")
	health._process(1.5)
	_check(is_equal_approx(health.shield, 15.0), "puis il se recharge quand l'entité n'est plus touchée")
	health._process(1.0)
	_check(health.shield == 20.0, "sans dépasser son maximum")
	_check(is_equal_approx(health.heal(10.0), 3.0) and health.health == 50.0, "un soin ne dépasse pas les points de vie maximum")
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
	_check(level.hud.tower_shop.get_child(1).button_pressed, "le bouton de la tour sélectionnée est enfoncé")
	_check(level.hud.tower_shop.get_child(2).disabled and level.hud.tower_shop.get_child(2).modulate.a < 1.0,
		"une tour trop chère est grisée dans la barre d'achat")
	level.select_tower(null)
	_check(not level.hud.tower_shop.get_child(1).button_pressed, "désélection")
	await _free(level)


func _test_tower_upgrade_stats() -> void:
	print("Améliorations : statistiques")
	for data: TowerData in [CANNON, GATLING, SNIPER, MORTAR, FROST, BEAM]:
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
	_add_still_enemy(level, LARVE, 0, 224.0)
	var projectile: Projectile = null
	var elapsed := 0.0
	while projectile == null and elapsed < 5.0:
		elapsed += await _step()
		if level.projectiles.get_child_count() > 0:
			projectile = level.projectiles.get_child(0)
	_check(projectile != null and is_equal_approx(projectile.stats.damage, tower.stats.damage),
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


func _joy_button(index: JoyButton, pressed := true) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = pressed
	return event


func _test_gamepad() -> void:
	print("Manette")
	Gamepad.setup_input_map()
	_check(InputMap.event_is_action(_joy_button(JOY_BUTTON_A), &"ui_accept")
		and InputMap.event_is_action(_joy_button(JOY_BUTTON_B), &"ui_cancel"),
		"A valide et B annule dans les menus")
	var stick := InputEventJoypadMotion.new()
	stick.axis = JOY_AXIS_LEFT_X
	stick.axis_value = -1.0
	_check(not InputMap.event_is_action(stick, &"ui_left"), "le stick gauche ne sert qu'au pointeur")

	var level := await _spawn_level(LEVEL_01)
	var hud := level.hud
	var shop_types: Array[TowerData] = []
	for button: TowerShopButton in hud.tower_shop.get_children():
		shop_types.append(button.data)
	level.gold = 10000
	await process_frame
	hud._unhandled_input(_joy_button(JOY_BUTTON_RIGHT_SHOULDER))
	_check(level.placer.selected_tower == shop_types[0], "RB choisit la première tour de la barre")
	hud._unhandled_input(_joy_button(JOY_BUTTON_RIGHT_SHOULDER))
	_check(level.placer.selected_tower == shop_types[1], "RB encore : la tour suivante")
	hud._unhandled_input(_joy_button(JOY_BUTTON_LEFT_SHOULDER))
	_check(level.placer.selected_tower == shop_types[0], "LB revient à la précédente")
	hud._unhandled_input(_joy_button(JOY_BUTTON_START))
	_check(level.is_paused, "Start met en pause")
	hud._unhandled_input(_joy_button(JOY_BUTTON_START))
	_check(not level.is_paused, "et relance la partie")
	var waves := [0]
	hud.next_wave_requested.connect(func() -> void: waves[0] += 1)
	hud._unhandled_input(_joy_button(JOY_BUTTON_Y))
	_check(waves[0] == 1, "Y lance la vague suivante")

	var manette := root.get_node_or_null(^"Manette") as Gamepad
	_check(manette != null, "la manette est chargée au démarrage")
	if manette:
		level.select_tower(CANNON)
		var cell := Vector2i(2, 4)
		var at := level.get_viewport().get_canvas_transform() * level.map.cell_to_world(cell)
		manette.set_cursor(at)
		_check(Gamepad.has_cursor() and Gamepad.is_active(), "le pointeur apparaît")
		manette._input(_joy_button(JOY_BUTTON_A))
		manette._input(_joy_button(JOY_BUTTON_A, false))
		for i in 3:
			await process_frame
		_check(level.map.get_occupant(cell) is Tower, "A pose la tour sous le pointeur")
		hud._process(0.0)
		_check(hud.shop_hint.text == Hud.GAMEPAD_HINT, "le rappel des commandes parle de la manette")
		var previous_scene := current_scene
		current_scene = level
		var from := Gamepad.get_cursor()
		manette._input(_joy_button(JOY_BUTTON_DPAD_RIGHT))
		manette._input(_joy_button(JOY_BUTTON_DPAD_RIGHT, false))
		_check(Gamepad.get_cursor().is_equal_approx(from + Vector2(Gamepad.DPAD_STEP, 0)),
			"en partie, la croix avance le pointeur d'une case")
		current_scene = previous_scene
		var motion := InputEventMouseMotion.new()
		motion.position = Vector2(5, 5)
		manette._input(motion)
		_check(not Gamepad.has_cursor() and not Gamepad.is_active(), "la souris reprend la main")
	await _free(level)


func _test_accessibility() -> void:
	print("Accessibilité : taille du texte, mode daltonien, vibrations")
	var options := OptionsMenu.new()
	root.add_child(options)
	await process_frame
	_check(options.text_scale_buttons.size() == GameSettings.TEXT_SCALES.size()
		and options.text_scale_buttons[0].button_pressed, "les Options proposent la taille du texte (normale au départ)")
	var label := Label.new()
	label.text = "Texte"
	label.add_theme_font_size_override(&"font_size", 20)
	root.add_child(label)
	await process_frame
	options.text_scale_buttons[2].pressed.emit()
	await process_frame
	_check(is_equal_approx(GameSettings.get_text_scale(), GameSettings.TEXT_SCALES[2])
		and label.get_theme_font_size(&"font_size") == roundi(20 * GameSettings.TEXT_SCALES[2]),
		"le texte déjà affiché grandit tout de suite")
	label.add_theme_font_size_override(&"font_size", 10)
	await process_frame
	await process_frame
	_check(label.get_theme_font_size(&"font_size") == 13, "une taille posée ensuite par le code grandit aussi")
	var late := Button.new()
	late.text = "Plus tard"
	root.add_child(late)
	await process_frame
	var theme_size := ThemeDB.get_project_theme().get_font_size(&"font_size", &"Button") \
		if ThemeDB.get_project_theme() and ThemeDB.get_project_theme().has_font_size(&"font_size", &"Button") \
		else ThemeDB.fallback_font_size
	_check(late.get_theme_font_size(&"font_size") == roundi(theme_size * GameSettings.TEXT_SCALES[2]),
		"un bouton ouvert ensuite a la taille choisie")
	options.text_scale_buttons[0].pressed.emit()
	await process_frame
	_check(label.get_theme_font_size(&"font_size") == 10 and late.get_theme_font_size(&"font_size") == theme_size,
		"revenir à la taille normale rend les tailles d'origine")
	label.free()
	late.free()

	_check(not UiStyle.is_colorblind() and UiStyle.invalid_color() == UiStyle.INVALID_COLOR,
		"sans le mode daltonien, une case interdite est rouge")
	options.colorblind_check.button_pressed = true
	_check(GameSettings.is_colorblind() and UiStyle.invalid_color() == UiStyle.COLORBLIND_INVALID_COLOR
		and UiStyle.valid_color() == UiStyle.COLORBLIND_VALID_COLOR
		and EnemyData.boss_color() == EnemyData.COLORBLIND_BOSS_COLOR,
		"mode daltonien : bleu et orange, boss magenta")
	Progress.clear_cache()
	GameSettings.apply_accessibility()
	_check(UiStyle.is_colorblind(), "le mode daltonien est enregistré")
	options.colorblind_check.button_pressed = false
	_check(EnemyData.boss_color() == EnemyData.BOSS_COLOR, "et se retire")

	_check(Gamepad.is_vibration_enabled() and options.vibration_check.button_pressed and Gamepad.rumble(&"boss"),
		"les vibrations sont permises au départ")
	options.vibration_check.button_pressed = false
	_check(not Gamepad.is_vibration_enabled() and not Gamepad.rumble(&"life_lost"), "la case Vibrations les coupe")
	Gamepad.set_vibration_enabled(true)
	options.close()
	await process_frame


func _test_touch_controls() -> void:
	print("Commandes tactiles")
	GameSettings.set_touch_mode(true)
	var level := await _spawn_level(LEVEL_01)
	var cell := Vector2i(2, 4)
	var at := level.map.cell_to_world(cell)
	level.select_tower(CANNON)
	await _click(level, at)
	_check(level.map.get_occupant(cell) == null and level.placer.preview.visible,
		"premier toucher : l'aperçu de la tour, rien n'est posé")
	_check(level.placer.touch_hint.visible and level.placer.touch_hint.text == "Touchez encore pour poser",
		"un rappel invite à toucher encore")
	await _click(level, level.map.cell_to_world(Vector2i(4, 2)))
	_check(level.map.get_occupant(Vector2i(4, 2)) == null and level.placer.touch_hint.text == "Impossible ici",
		"toucher une autre case y déplace l'aperçu (sur le chemin : impossible)")
	await _click(level, at)
	_check(level.map.get_occupant(cell) == null, "revenir sur la case ne la pose pas encore")
	await _click(level, at)
	var tower := level.map.get_occupant(cell) as Tower
	_check(tower != null and level.placer.selected_tower == null and not level.placer.touch_hint.visible,
		"second toucher sur la même case : la tour est posée")
	await _click(level, at)
	_check(level.placer.inspected_tower == tower and level.hud.tower_details.visible, "toucher une tour ouvre sa fiche")
	await _click(level, level.map.cell_to_world(Vector2i(4, 2)))
	_check(level.placer.inspected_tower == null, "toucher la carte ailleurs la ferme")
	_check(level.hud.shop_hint.text == Hud.TOUCH_HINT, "le rappel des commandes parle du tactile")

	var enemy := _add_still_enemy(level, SCARABEE, 0, 100.0)
	await process_frame
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = enemy.get_global_transform_with_canvas().origin
	level.hud._input(touch)
	await process_frame
	_check(level.hud.enemy_details.visible and level.hud.hovered_enemy == enemy, "toucher un monstre ouvre sa fiche")
	touch.position = Vector2(20, 400)
	level.hud._input(touch)
	await process_frame
	_check(not level.hud.enemy_details.visible, "toucher ailleurs la ferme")
	await _free(level)

	var button := Button.new()
	_check(not GameSettings.confirm_touch(button) and GameSettings.confirm_touch(button),
		"un bouton à fiche (niveau, amélioration) agit au second toucher")
	GameSettings.set_touch_mode(false)
	_check(GameSettings.confirm_touch(button), "et tout de suite à la souris")
	button.free()
	level = await _spawn_level(LEVEL_01)
	_check(level.hud.shop_hint.text == Hud.MOUSE_HINT, "le rappel revient à la souris")
	await _free(level)


func _test_tower_info_panels() -> void:
	print("Fiches des tours")
	var level := await _spawn_level(LEVEL_01)
	var hud := level.hud
	var screen := root.get_visible_rect()
	var slots := hud.tower_shop.get_children()
	var first_rect: Rect2 = slots[0].get_global_rect()
	_check(first_rect.position.x < 32.0 and first_rect.end.y > screen.end.y - 32.0, "barre d'achat en bas à gauche")
	_check(slots.all(func(slot: TowerShopButton) -> bool: return slot.size == first_rect.size),
		"toutes les cases ont la même taille (%s)" % first_rect.size)
	_check(slots[0].find_children("*", "TowerIcon", true, false).size() == 1, "chaque case montre l'image de la tour")
	_check(first_rect.position.y >= level.map.cell_to_world(Vector2i(0, level.map.rows - 1)).y + level.map.cell_size / 2.0,
		"la barre ne cache aucune case de la carte")
	var button: Button = hud.tower_shop.get_child(0)
	button.mouse_entered.emit()
	await process_frame
	var shop := hud.shop_info
	_check(shop.visible and shop.name_label.text == "Canon", "survol d'un bouton d'achat : fiche de la tour")
	_check(shop.footer_label.text.begins_with("Prix : 50 or"), "la fiche indique le prix")
	_check(not shop.upgrade_button.is_visible_in_tree() and not shop.sell_button.is_visible_in_tree() \
		and not shop.target_button.visible and not shop.close_button.visible, "pas de boutons sur l'aperçu")
	_check(shop.stats_grid.get_child_count() == 4 * 3, "4 statistiques pour le canon")
	_check(shop.get_global_rect().end.y <= button.get_global_rect().position.y, "la fiche s'ouvre au-dessus du bouton")
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

	# Fermée aussi par la HUD, avant tout le reste : Échap, ou un clic en dehors de la fiche.
	await _click(level, tower.global_position)
	level.hud._input(escape)
	_check(not details.visible and level.placer.inspected_tower == null, "Échap ferme la fiche, même si un bouton a le focus")
	await _click(level, tower.global_position)
	var inside := InputEventMouseButton.new()
	inside.button_index = MOUSE_BUTTON_LEFT
	inside.pressed = true
	inside.position = details.get_global_rect().get_center()
	level.hud._input(inside)
	_check(details.visible, "un clic dans la fiche la garde ouverte")
	var outside := inside.duplicate() as InputEventMouseButton
	outside.position = level.get_viewport().get_canvas_transform() * level.map.cell_to_world(Vector2i(14, 6))
	level.hud._input(outside)
	_check(not details.visible and level.placer.inspected_tower == null, "un clic en dehors de la fiche la ferme")

	await _click(level, tower.global_position)
	level.select_tower(GATLING)
	_check(not details.visible, "choisir une tour à poser ferme la fiche")
	await _free(level)


func _test_undo_placement() -> void:
	print("Annuler la dernière pose")
	var level := await _spawn_level(LEVEL_01)
	level.gold = 1000
	var first := level.place_tower(Vector2i(2, 4), CANNON)
	var second := level.place_tower(Vector2i(5, 3), GATLING)
	level.upgrade_tower(second)
	var paid := GATLING.get_cost() + GATLING.get_upgrade_cost(1)
	_check(second.refundable and second.get_sell_value() == paid, "une tour qui vient d'être posée est remboursée en entier")
	await _click(level, second.global_position)
	var details := level.hud.tower_details
	_check(details.sell_button.text == "Annuler la pose  ·  %d or" % paid, "le bouton Vendre devient Annuler la pose")
	var event := InputEventKey.new()
	event.keycode = KEY_Z
	event.physical_keycode = KEY_W
	event.ctrl_pressed = true
	event.pressed = true
	level.hud._unhandled_key_input(event)
	_check(not second.is_alive and level.gold == 1000 - CANNON.get_cost(), "Ctrl+Z annule la dernière pose, améliorations comprises")
	_check(level.stats.towers_built == 1 and level.stats.gold_spent == CANNON.get_cost() and level.stats.upgrades_bought == 0
		and level.stats.towers_sold == 0, "elle ne compte ni comme posée ni comme vendue")
	_press_key(level, KEY_BACKSPACE)
	_check(not first.is_alive and level.gold == 1000 and level.map.is_cell_buildable(Vector2i(2, 4)),
		"Retour arrière annule la pose d'avant")
	_check(level.undo_last_placement() == 0, "plus rien à annuler")
	await process_frame
	var third := level.place_tower(Vector2i(2, 4), CANNON)
	level.start_next_wave()
	_check(not third.refundable and third.get_sell_value() == 35, "une fois la vague lancée, la tour se revend 70 %")
	_check(level.undo_last_placement() == 0 and third.is_alive, "et sa pose ne s'annule plus")
	var during := level.place_tower(Vector2i(5, 3), CANNON)
	_check(during.refundable, "une tour posée pendant la vague s'annule…")
	var waited := 0.0
	while during.refundable and waited < 60.0:
		waited += await _step()
	_check(not during.refundable, "… jusqu'à son premier tir")
	await _free(level)


func _test_saved_game() -> void:
	print("Partie enregistrée entre deux vagues")
	SavedGame.clear()
	var level := await _spawn_level(LEVEL_01)
	_check(not SavedGame.exists() and not level.autosave(), "rien d'enregistré avant d'avoir commencé")
	level.gold = 1000
	var cannon := level.place_tower(Vector2i(3, 3), CANNON)
	level.place_tower(Vector2i(5, 3), GATLING)
	level.place_tower(Vector2i(7, 4), SNIPER)
	level.upgrade_tower(cannon)
	cannon.set_target_mode(Tower.TargetMode.STRONGEST)
	_check(SavedGame.exists(), "une tour posée avant la première vague enregistre la partie")
	level.start_next_wave()
	_check(not level.autosave(), "pas d'enregistrement pendant une vague")
	var waited := 0.0
	while not level.is_between_waves() and waited < 120.0:
		waited += await _step()
	var saved := SavedGame.load_data()
	_check(level.spawner.current_wave == 0 and saved.get("wave") == 0, "la carte vidée, la partie est enregistrée")
	var gold := level.gold
	var lives := level.lives
	var kills := level.stats.kills
	var damage := level.stats.get_total_damage()
	var duration := level.stats.duration
	var wave_text := level.hud.wave_label.text
	_check(saved.gold == gold and saved.lives == lives and saved.towers.size() == 3, "avec l'or, les vies et les tours")
	_check(SavedGame.describe(saved) == "Niveau 1-1  ·  Moyen  ·  vague 2 / 5", "décrite par son niveau, son mode et la vague à venir")
	await _free(level)

	var title := TITLE_SCREEN.instantiate()
	root.add_child(title)
	await process_frame
	var resume_button: Button = title.get_node("%ResumeButton")
	_check(resume_button.visible and resume_button.has_focus() and title.get_node("%ResumeInfo").text.ends_with("vague 2 / 5"),
		"l'écran titre propose de la reprendre")
	title.show_play_menu(true)
	_check(not resume_button.visible, "le bouton se cache dans le menu Jouer")
	title.show_play_menu(false)
	resume_button.pressed.emit()
	await process_frame
	await process_frame
	level = current_scene as Level
	_check(level != null and level.scene_file_path == LEVEL_01.resource_path, "Reprendre rouvre le niveau")
	if level == null:
		return
	_check(level.gold == gold and level.lives == lives and level.spawner.current_wave == 0, "même or, mêmes vies, même vague")
	_check(level.hud.wave_label.text == wave_text, "le HUD en est à la même vague (%s)" % wave_text)
	var restored := level.map.get_occupant(Vector2i(3, 3)) as Tower
	_check(level.get_towers().size() == 3 and restored != null and restored.data == CANNON and restored.level == 2
		and restored.target_mode == Tower.TargetMode.STRONGEST, "les tours reviennent à leur place, améliorées, avec leur cible")
	_check(not restored.refundable and level.undo_last_placement() == 0, "leurs poses d'avant la vague ne s'annulent plus")
	_check(level.stats.kills == kills and is_equal_approx(level.stats.get_total_damage(), damage)
		and absf(level.stats.duration - duration) < 1.0 and level.stats.towers_built == 3, "les statistiques suivent")
	_check(level.can_start_next_wave(), "la vague suivante peut partir")
	level.start_next_wave()
	_check(level.spawner.current_wave == 1, "et c'est la deuxième")
	level._end_game(false)
	_check(not SavedGame.exists(), "la partie finie, la sauvegarde est effacée")
	await _free(level)

	# Mode infini et Conquête.
	Engine.set_meta(Level.ENDLESS_META, true)
	level = await _spawn_level(LEVEL_01)
	level.spawner.current_wave = 7
	level._wave_bonus_paid = 7
	_check(level.autosave() and SavedGame.load_data().endless, "le mode infini s'enregistre aussi")
	await _free(level)
	SavedGame.resume(self)
	await process_frame
	await process_frame
	level = current_scene as Level
	_check(level != null and level.is_endless and level.spawner.current_wave == 7, "et se reprend en mode infini")
	if level:
		level._on_restart_requested()
		_check(not SavedGame.exists(), "Recommencer abandonne la partie enregistrée")
		await process_frame
		await process_frame
		if current_scene:
			await _free(current_scene)
	var challenge := DailyChallenge.for_date("2026-10-06")
	Engine.set_meta(Level.CHALLENGE_META, challenge.date_key)
	level = await _spawn_level(load(challenge.level_path))
	level.spawner.current_wave = 2
	level._wave_bonus_paid = 2
	level.add_score(450)
	_check(level.autosave() and SavedGame.load_data().challenge == "2026-10-06", "le défi du jour s'enregistre avec sa date")
	await _free(level)
	SavedGame.resume(self)
	await process_frame
	await process_frame
	level = current_scene as Level
	_check(level != null and level.challenge != null and level.challenge.date_key == "2026-10-06" and level.score == 450
		and level.spawner.current_wave == 2, "et se reprend avec ses règles et son score")
	if level:
		await _free(level)
	SavedGame.clear()
	var run := Expedition.new()
	run.rng_seed = 5
	run.levels.assign([LEVEL_02.resource_path, LEVEL_01.resource_path, LEVEL_03.resource_path,
		LEVEL_04.resource_path, LEVEL_05.resource_path])
	run.index = 1
	run.lives = 7
	run.max_lives = 25
	Engine.set_meta(Level.EXPEDITION_META, run.to_dict())
	level = await _spawn_level(LEVEL_01)
	level.spawner.current_wave = 1
	level._wave_bonus_paid = 1
	level.lives = 6
	_check(level.autosave() and SavedGame.describe(SavedGame.load_data()).contains("Expédition"),
		"une étape d'Expédition s'enregistre")
	await _free(level)
	SavedGame.resume(self)
	await process_frame
	await process_frame
	level = current_scene as Level
	_check(level != null and level.expedition != null and level.expedition.index == 1 and level.lives == 6
		and level.starting_lives == 25 and level.spawner.current_wave == 1, "et se reprend à la même étape, avec ses vies")
	if level:
		await _free(level)
	SavedGame.clear()
	level = await _spawn_level(CONQUEST_01)
	level.spawner.current_wave = 0
	level._wave_bonus_paid = 0
	_check(not level.can_save_game() and not level.autosave(), "la Conquête ne s'enregistre pas")
	await _free(level)
	await _free(title)


func _test_sell_tower() -> void:
	print("Vente des tours")
	var level := await _spawn_level(LEVEL_01)
	level.gold = 1000
	var cell := Vector2i(2, 4)
	var tower := level.place_tower(cell, CANNON)
	# Comme après le lancement d'une vague : la pose ne peut plus être annulée.
	tower.refundable = false
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
	var tough: EnemyData = LARVE.duplicate()
	tough.max_health = 500.0
	# Trois ennemis immobiles à portée : en tête, en queue, et le plus résistant au milieu.
	var ahead := _add_still_enemy(level, LARVE, 0, 260.0)
	var strong := _add_still_enemy(level, tough, 0, 200.0)
	var behind := _add_still_enemy(level, LARVE, 0, 120.0)
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
	_check(level.level_name == "Niveau 1-2" and level.gold == 220 and level.lives == 20, "nom, or et vies de départ")
	_check(level.spawner.waves.size() == 6, "6 vagues définies")
	_check(level.tower_types.size() == 5, "5 types de tours proposés")
	_check(level.map.paths.size() == 2, "deux chemins")
	_check(level.get_next_level() == LEVEL_03.resource_path, "le niveau 3 suit")
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
	var larve := _add_still_enemy(level, LARVE, 0, 100.0)
	_check(larve.global_position.is_equal_approx(Vector2(68, 160)), "l'ennemi est placé sur son chemin")
	larve.apply_slow(0.5, 1.0)
	_check(is_equal_approx(larve.get_speed(), LARVE.speed * 0.5), "le ralentissement réduit la vitesse")
	larve.apply_slow(0.8, 3.0)
	_check(is_equal_approx(larve.get_speed(), LARVE.speed * 0.5), "le ralentissement le plus fort l'emporte")
	larve.set_process(true)
	var elapsed := 0.0
	while larve.is_slowed() and elapsed < 10.0:
		elapsed += await _step()
	_check(is_equal_approx(larve.get_speed(), LARVE.speed), "la vitesse revient à la normale")
	Engine.time_scale = 1.0
	var scarabee := _add_still_enemy(level, SCARABEE, 1, 100.0)
	scarabee.take_damage(GATLING.damage)
	_check(is_equal_approx(scarabee.health.health, SCARABEE.max_health - 1.0), "la mitrailleuse rebondit sur la carapace")
	scarabee.take_damage(SNIPER.damage)
	_check(is_equal_approx(scarabee.health.health, SCARABEE.max_health - 1.0 - (SNIPER.damage - SCARABEE.armor)),
		"le sniper perce la carapace")
	await _free(level)


func _test_explosive_projectile() -> void:
	print("Projectile explosif")
	var level := await _spawn_level(LEVEL_02)
	var group: Array[Enemy] = []
	for offset in [0.0, 20.0, 40.0]:
		group.append(_add_still_enemy(level, LARVE, 0, 200.0 + offset))
	var far := _add_still_enemy(level, LARVE, 0, 400.0)
	var projectile: Projectile = MORTAR.projectile_scene.instantiate()
	projectile.setup(group[1], MORTAR)
	level.projectiles.add_child(projectile)
	projectile.global_position = group[1].global_position + Vector2(0, 100)
	var elapsed := 0.0
	while is_instance_valid(projectile) and elapsed < 10.0:
		elapsed += await _step()
	var all_hit := group.all(func(e: Enemy) -> bool: return e.health.health == LARVE.max_health - MORTAR.damage)
	_check(all_hit, "l'explosion touche tous les ennemis dans son rayon")
	_check(far.health.health == LARVE.max_health, "un ennemi hors du rayon n'est pas touché")
	await _free(level)


func _test_damage_and_death_feedback() -> void:
	print("Dégâts affichés, or gagné et tache au sol")
	var level := await _spawn_level(LEVEL_02)
	var scarabee := _add_still_enemy(level, SCARABEE, 1, 100.0)
	level._on_enemy_spawned(scarabee)
	_check(is_equal_approx(scarabee.take_damage(SNIPER.damage), SNIPER.damage - SCARABEE.armor),
		"take_damage renvoie les dégâts après armure")
	var texts := level.effects.get_children().filter(func(n: Node) -> bool: return n is FloatingText)
	_check(texts.size() == 1 and texts[0].text == str(roundi(SNIPER.damage - SCARABEE.armor)),
		"les dégâts réellement subis s'affichent au-dessus de l'ennemi")
	var gold_before := level.gold
	var death_position := scarabee.global_position
	scarabee.take_damage(10000.0)
	_check(level.gold == gold_before + SCARABEE.reward, "la mort rapporte la prime")
	var gold_texts := level.effects.get_children().filter(
		func(n: Node) -> bool: return n is FloatingText and n.text == "+%d" % SCARABEE.reward)
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
	var near := _add_still_enemy(level, LARVE, 0, 290.0)
	var other := _add_still_enemy(level, LARVE, 0, 320.0)
	var far := _add_still_enemy(level, LARVE, 0, 30.0)
	await process_frame
	await process_frame
	_check(near.is_slowed() and other.is_slowed(), "l'onde ralentit tous les ennemis à portée")
	_check(near.health.health < LARVE.max_health and other.health.health < LARVE.max_health, "l'onde inflige des dégâts")
	_check(not far.is_slowed() and far.health.health == LARVE.max_health, "un ennemi hors de portée n'est pas touché")
	await _free(level)


func _test_lives_lost_feedback() -> void:
	print("Effet de perte de vies")
	var level := await _spawn_level(LEVEL_01)
	var enemy := _add_still_enemy(level, LARVE, 0, 0.0)
	level._on_enemy_spawned(enemy)
	var material := level.hud.damage_flash.material as ShaderMaterial
	_check(material.get_shader_parameter("intensity") == 0.0, "pas de voile rouge au départ")
	enemy.reached_end.emit(enemy)
	await process_frame
	_check(level.lives == level.starting_lives - LARVE.damage, "le joueur perd des vies")
	_check(material.get_shader_parameter("intensity") > 0.3, "un voile rouge apparaît")
	_check(level.hud.lives_label.scale.x > 1.0, "le compteur de vies grossit")
	var texts := level.effects.get_children().filter(func(n: Node) -> bool: return n is FloatingText)
	_check(texts.any(func(t: FloatingText) -> bool: return t.text == "-%d" % LARVE.damage),
		"« -%d » s'affiche à la sortie" % LARVE.damage)
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
	key.physical_keycode = KEY_V
	key.pressed = true
	hud._unhandled_key_input(key)
	_check(Engine.time_scale == 1.0, "V après x3 revient en x1")
	hud._unhandled_key_input(key)
	_check(Engine.time_scale == 2.0 and hud.speed_buttons.get_child(1).button_pressed, "V passe à la vitesse suivante")

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
	level.select_tower(CANNON)
	_check(level.placer.selected_tower == null
		and hud.tower_shop.get_children().all(func(b: Button) -> bool: return b.disabled),
		"plus de tour à choisir après la fin de partie")
	_check(hud.pause_button.disabled, "pause indisponible après la fin de partie")
	level.set_paused(false)
	_check(paused, "la pause de fin de partie ne peut pas être levée")
	hud.speed_buttons.get_child(2).pressed.emit()
	var old_vignette := hud.damage_flash.material
	await _free(level)
	level = await _spawn_level(LEVEL_01)
	_check(Engine.time_scale == 1.0, "un nouveau niveau repart en x1")
	_check(level.hud.damage_flash.material != old_vignette, "chaque niveau a son propre voile rouge")
	await _free(level)


## Les touches 1 à 9 puis 0 choisissent les tours de la barre d'achat, dans l'ordre.
func _test_shop_hotkeys() -> void:
	print("Touches de la barre d'achat")
	var level := await _spawn_level(LEVEL_01)
	var hud := level.hud
	level.gold = 10000
	var slots := hud.tower_shop.get_children()
	_check((slots[0] as TowerShopButton).hotkey == "1" and (slots[1] as TowerShopButton).hotkey == "2",
		"le chiffre de la touche est affiché sur la case")
	var key := InputEventKey.new()
	key.pressed = true
	# En AZERTY, la touche 3 sans Maj donne « " » : c'est sa position qui compte.
	key.keycode = KEY_QUOTEDBL
	key.physical_keycode = KEY_3
	hud._unhandled_key_input(key)
	_check(level.placer.selected_tower == level.tower_types[2] and (slots[2] as Button).button_pressed,
		"la touche 3 choisit la troisième tour, même en AZERTY")
	await _click(level, level.map.cell_to_world(Vector2i(2, 4)))
	_check(level.map.get_occupant(Vector2i(2, 4)) is Tower, "un clic pose la tour choisie au clavier")
	key.keycode = KEY_NONE
	key.physical_keycode = KEY_KP_1
	hud._unhandled_key_input(key)
	_check(level.placer.selected_tower == level.tower_types[0], "le 1 du pavé numérique choisit la première tour")
	hud._unhandled_key_input(key)
	_check(level.placer.selected_tower == null and not (slots[0] as Button).button_pressed,
		"la même touche repose la tour")
	key.physical_keycode = KEY_0
	hud._unhandled_key_input(key)
	_check(level.placer.selected_tower == null, "une touche sans case ne fait rien")
	level.gold = 0
	key.physical_keycode = KEY_1
	hud._unhandled_key_input(key)
	_check(level.placer.selected_tower == null, "pas de tour trop chère choisie au clavier")
	await _free(level)
	_check(TowerShop.slot_for_key(KEY_0) == 9 and TowerShop.slot_for_key(KEY_KP_0) == 9
		and TowerShop.slot_for_key(KEY_A) == -1, "0 choisit la dixième case")


## Nombre de coups reçus par un ennemi immobile pendant `game_seconds` secondes de jeu.
func _count_hits(tower_data: TowerData, speed: float, game_seconds: float) -> int:
	var level := await _spawn_level(LEVEL_01)
	level.gold = 10000
	var tower := level.place_tower(Vector2i(2, 4), tower_data)
	level.upgrade_tower(tower)
	var target_data: EnemyData = LARVE.duplicate()
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
	# Les intérêts, eux, ne sont versés qu'une fois : sur l'or gardé quand la carte est vidée.
	var interest := mini(floori((gold_before + rewards) * level.interest_rate), level.interest_cap)
	_check(level.gold == gold_before + rewards + interest + bonuses,
		"les bonus des deux vagues sont versés, et les intérêts une fois (%d or attendus, %d reçus)"
		% [rewards + interest + bonuses, level.gold - gold_before])
	await _free(level)


func _test_wave_preview_and_early_call() -> void:
	print("Aperçu de la prochaine vague et prime d'avance")
	var level := await _spawn_level(LEVEL_02)
	var hud := level.hud
	await process_frame
	_check(hud.wave_preview.visible and hud.wave_preview_label.get_parsed_text().contains("12 Larve"),
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


func _test_interest() -> void:
	print("Intérêts sur l'or gardé")
	var level := await _spawn_level(LEVEL_01)
	level.gold = 300
	_check(level.get_interest() == 15, "300 or gardés rapportent 15 or d'intérêts (5 %)")
	_check(level.hud.interest_label.visible and level.hud.interest_label.text == "Intérêts : +15",
		"le HUD les annonce sous l'or (%s)" % level.hud.interest_label.text)
	_check(level.hud.interest_label.tooltip_text.contains("5 %") and level.hud.interest_label.tooltip_text.contains("25"),
		"sa bulle d'aide donne le taux et le plafond")
	level.gold = 5000
	_check(level.get_interest() == 25, "plafonnés à 25 or")
	level.gold = 300
	level.spawner.current_wave = 0
	level._check_wave_cleared()
	var bonus := level.get_wave_bonus(0)
	_check(level.gold == 300 + 15 + bonus, "versés avec le bonus de vague, calculés sur l'or d'avant le bonus (%d)" % level.gold)
	_check(level.effects.get_children().any(func(n: Node) -> bool: return n is FloatingText and n.text == "+15 intérêts"),
		"« +15 intérêts » s'affiche sous l'or")
	var gold := level.gold
	level._check_wave_cleared()
	_check(level.gold == gold, "rien de plus tant qu'aucune nouvelle vague n'est repoussée")
	await _free(level)


## Débloque les mondes et achète les pouvoirs et leurs renforts (étoiles infinies comprises).
func _buy_all_powers() -> void:
	Perks.unlock_everything()
	Progress.set_value("perks", "owned", PackedStringArray())
	for perk in Perks.TREE.perks:
		# La Corvée (page Logistique) a ses propres tests.
		if not perk.get_power_path().is_empty() and Perks.TREE.get_page(perk) == 3:
			_check(Perks.buy(perk), "achat : %s" % perk.display_name)


func _test_powers_in_tree() -> void:
	print("Pouvoirs : arbre des améliorations")
	var tree := Perks.TREE
	var unlocks := tree.perks.filter(func(p: Perk) -> bool: return not p.unlocks_power.is_empty())
	var corvee_perk := tree.get_perk("pouvoir_corvee")
	unlocks.erase(corvee_perk)
	var on_page := unlocks.all(func(p: Perk) -> bool: return tree.get_page(p) == 3 and not p.paid_with_endless_stars)
	_check(unlocks.size() == 3 and on_page, "3 pouvoirs, payés en étoiles, sur la page Pouvoirs")
	_check(tree.get_page(corvee_perk) == tree.page_names.find("Logistique"), "la Corvée est sur la page Logistique")
	var upgrades := tree.perks.filter(func(p: Perk) -> bool: return not p.improves_power.is_empty())
	_check(upgrades.size() == 6 and upgrades.all(func(p: Perk) -> bool: return p.paid_with_endless_stars),
		"6 renforts de pouvoirs, payés en étoiles infinies")
	_check(tree.get_total_cost(true) <= Progress.ENDLESS_MAX_STARS * Perks.CAMPAIGN.size(),
		"les étoiles infinies suffisent à tout acheter (%d)" % tree.get_total_cost(true))
	_check(Perks.get_powers().is_empty(), "aucun pouvoir sans achat")
	var level := await _spawn_level(LEVEL_01)
	_check(level.powers.is_empty() and not level.hud.power_bar.visible, "ni bouton de pouvoir en jeu")
	await _free(level)

	_win_in_all_difficulties(Perks.CAMPAIGN.worlds[0].levels)
	var meteors := tree.get_perk("pouvoir_meteores")
	_check(Perks.is_unlocked(meteors) and Perks.is_unlocked(tree.get_perk("pouvoir_gel"))
		and not Perks.is_unlocked(tree.get_perk("pouvoir_renforts")),
		"Météores ouverts d'emblée, Gel avec La Fonderie, Renforts avec La Cité")
	var screen := PERK_TREE_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	screen.show_page(3)
	_check(screen.get_button(meteors).is_visible_in_tree() and screen.get_button(meteors).get_child(0) is PowerIcon,
		"la page Pouvoirs montre le pouvoir avec son image")
	_check(screen.stars_label.text.contains("★") and screen.stars_label.text.contains("∞ ★"),
		"et les deux monnaies (%s)" % screen.stars_label.text)
	_check(screen.buy(meteors), "les Météores s'achètent")
	await _free(screen)
	var powers := Perks.get_powers()
	_check(powers.size() == 1 and powers[0].id == "meteors" and is_equal_approx(powers[0].damage, 80.0),
		"le pouvoir débloqué est disponible")
	Progress.reset_campaign()

	_buy_all_powers()
	powers = Perks.get_powers()
	_check(powers.size() == 3, "les 3 pouvoirs")
	_check(is_equal_approx(powers[0].damage, 120.0) and is_equal_approx(powers[0].cooldown, 28.0),
		"Pluie battante et Comètes : 120 dégâts, 28 s de recharge")
	_check(is_equal_approx(powers[1].duration, 5.0) and is_equal_approx(powers[1].vulnerability, 0.3),
		"Blizzard et Engelures : 5 s de gel, +30 % de dégâts subis")
	_check(powers[2].count == 5 and is_equal_approx(powers[2].health, 225.0), "Vétérans et Escouade : 5 soldats de 225 vie")
	var resource: Power = load("res://resources/powers/meteors.tres")
	_check(is_equal_approx(resource.damage, 80.0), "sans toucher à la ressource du pouvoir")
	level = await _spawn_level(LEVEL_01)
	await process_frame
	var buttons := level.hud.power_buttons
	_check(buttons.size() == 3 and level.hud.power_bar.visible, "un bouton par pouvoir en haut de l'écran")
	var top := level.hud.top_bar.get_global_rect()
	_check(buttons.all(func(b: PowerButton) -> bool: return top.encloses(b.get_global_rect()))
		and buttons[2].get_global_rect().end.x <= level.hud.next_wave_button.get_global_rect().position.x
		and level.hud.wave_label.get_global_rect().end.x < buttons[0].get_global_rect().position.x,
		"ils tiennent dans la barre du haut, entre la vague et le bouton de vague")
	await _free(level)
	Progress.reset_campaign()


func _press_key(level: Level, physical: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = physical
	event.pressed = true
	level.hud._unhandled_key_input(event)


func _test_meteors() -> void:
	print("Pouvoir : Météores")
	_buy_all_powers()
	var level := await _spawn_level(LEVEL_01)
	var meteors := level.powers[0]
	var at := level.map.get_enemy_path(0).to_global(level.map.get_enemy_path(0).curve.sample_baked(400.0))
	var near := _add_enemy_at(level, LARVE, at)
	var far := _add_enemy_at(level, LARVE, at + Vector2(400, 0))
	var health := near.health.health
	_press_key(level, KEY_Q)
	_check(level.placer.selected_power == meteors and level.hud.power_buttons[0].button_pressed,
		"Q (A en AZERTY) vise les Météores, et leur bouton reste enfoncé")
	_press_key(level, KEY_Q)
	_check(level.placer.selected_power == null, "la même touche annule")
	level.select_tower(CANNON)
	level.select_power(meteors)
	_check(level.placer.selected_tower == null and level.placer.selected_power == meteors, "viser un pouvoir lâche la tour choisie")
	level.select_tower(CANNON)
	_check(level.placer.selected_power == null, "et inversement")
	level.select_tower(null)
	level.select_power(meteors)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = at
	await _send_to_placer(level, click)
	_check(level.placer.selected_power == null and level.get_power_cooldown(meteors) > meteors.cooldown - 0.5,
		"un clic sur la carte lance la pluie, et le pouvoir se recharge")
	_check(not level.can_use_power(meteors) and level.hud.power_buttons[0].disabled, "en recharge, il ne se relance pas")
	var elapsed := 0.0
	while elapsed < 2.0:
		elapsed += await _step()
	_check(not is_instance_valid(near) or not near.is_alive or near.health.health < health - meteors.damage * 0.9,
		"les météores frappent les ennemis de la zone")
	_check(far.health.health == far.health.max_health, "et pas ceux d'ailleurs")
	_check(level.get_power_cooldown(meteors) < meteors.cooldown - 1.0, "la recharge avance avec le jeu")
	_check(level.hud.power_buttons[0].text.ends_with(" s"), "le bouton montre les secondes restantes")
	level.power_cooldowns[0] = 0.0
	level.set_paused(true)
	_check(not level.use_power(meteors, at), "pas de pouvoir pendant la pause")
	await _free(level)
	Progress.reset_campaign()


func _test_freeze() -> void:
	print("Pouvoir : Gel")
	_buy_all_powers()
	var level := await _spawn_level(LEVEL_01)
	var freeze := level.powers[1]
	var walker := _add_still_enemy(level, LARVE, 0, 200.0)
	walker.set_process(true)
	var boss := _add_still_enemy(level, REINE, 0, 100.0)
	boss.set_process(true)
	await process_frame
	level.select_power(freeze)
	_check(walker.is_frozen() and level.get_power_cooldown(freeze) > 0.0, "le Gel part tout de suite, sans viser")
	_check(not boss.is_frozen() and boss.is_slowed(), "un boss ne gèle pas : il ralentit")
	var progress := walker.progress
	var elapsed := 0.0
	while elapsed < 2.0:
		elapsed += await _step()
	_check(walker.progress == progress, "un ennemi gelé ne bouge plus")
	var dealt := walker.take_damage(10.0, true)
	_check(is_equal_approx(dealt, 13.0), "Engelures : il subit 30 %% de dégâts en plus (%.1f)" % dealt)
	while elapsed < freeze.duration + 0.5:
		elapsed += await _step()
	_check(not walker.is_frozen() and walker.progress > progress, "puis il repart")
	await _free(level)
	Progress.reset_campaign()


func _test_reinforcements() -> void:
	print("Pouvoir : Renforts")
	_buy_all_powers()
	var level := await _spawn_level(LEVEL_01)
	var reinforcements := level.powers[2]
	var path := level.map.get_enemy_path(0)
	var post := path.to_global(path.curve.sample_baked(500.0))
	_check(level.map.get_closest_path_point(post + Vector2(3, 4)).distance_to(post) < 6.0,
		"le point du chemin le plus proche d'un clic")
	_check(level.use_power(reinforcements, post), "les renforts se lancent sur le chemin")
	var soldiers := level.get_soldiers()
	_check(soldiers.size() == reinforcements.count, "%d soldats arrivent" % reinforcements.count)
	_check(soldiers.all(func(s: Soldier) -> bool: return s.global_position.distance_to(post) < 20.0),
		"ils se postent autour du point visé")
	var enemy := _add_still_enemy(level, SCARABEE, 0, 460.0)
	enemy.set_process(true)
	var boss := _add_still_enemy(level, REINE, 0, 380.0)
	boss.set_process(true)
	var elapsed := 0.0
	while elapsed < 1.5:
		elapsed += await _step()
	_check(enemy.is_held(), "un soldat arrête le premier ennemi qui arrive")
	var progress := enemy.progress
	var health := enemy.health.health
	while elapsed < 2.5:
		elapsed += await _step()
	_check(not enemy.is_alive or (enemy.progress == progress and enemy.health.health < health),
		"l'ennemi retenu ne marche plus et se fait frapper")
	_check(not boss.is_held(), "un boss ne s'arrête pas")
	_check(soldiers.any(func(s: Soldier) -> bool: return s.health < s.max_health) or not enemy.is_alive,
		"l'ennemi retenu frappe son soldat")
	boss.despawn()
	while elapsed < reinforcements.duration + 1.0:
		elapsed += await _step()
	_check(level.get_soldiers().is_empty(), "les soldats repartent au bout de %d s" % reinforcements.duration)
	_check(not is_instance_valid(enemy) or not enemy.is_alive or not enemy.is_held(), "et lâchent leur ennemi")
	await _free(level)
	Progress.reset_campaign()


func _test_path_preview() -> void:
	print("Trajet des ennemis mis en évidence avant la première vague")
	var level := await _spawn_level(LEVEL_02)
	var preview: PathPreview = level.get_node("PathPreview")
	_check(preview.visible and preview.map == level.map and level.map.paths.size() == 2,
		"le trajet est affiché sur les deux chemins à l'ouverture du niveau")
	level.set_paused(true)
	var time_before := preview._time
	await process_frame
	await process_frame
	_check(preview._time > time_before, "l'animation continue pendant la pause")
	level.set_paused(false)
	level.start_next_wave()
	for i in 60:
		if not is_instance_valid(preview):
			break
		await process_frame
	_check(not is_instance_valid(preview), "le trajet s'efface quand la première vague est lancée")
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
	_check(level.hud.next_level_button.visible, "le niveau 3 est proposé ensuite")
	await _free(level)


## Rejoue le niveau 2 sans or bonus : les tours sont achetées dans l'ordre de la liste
## dès que l'or le permet. Vérifie que le niveau est gagnable avec son économie.
func _test_level_02_with_earned_gold() -> void:
	print("Niveau 2 : gagnable avec l'or de départ et l'or gagné")
	var build_order: Array = [
		[Vector2i(5, 4), CANNON], [Vector2i(7, 4), CANNON], [Vector2i(9, 4), MORTAR],
		[Vector2i(7, 6), FROST], [Vector2i(11, 4), SNIPER], [Vector2i(9, 6), CANNON],
		[Vector2i(13, 4), MORTAR], [Vector2i(11, 6), GATLING], [Vector2i(15, 3), SNIPER],
		[Vector2i(13, 1), FROST], [Vector2i(15, 5), MORTAR], [Vector2i(17, 7), SNIPER],
		[Vector2i(15, 7), CANNON], [Vector2i(17, 4), MORTAR], [Vector2i(5, 6), SNIPER],
	]
	var result := await _play_build_order(LEVEL_02, build_order, build_order.size(), 1200.0)
	_check(result.won, "la partie est gagnée (vies restantes : %d, tours achetées : %d)" % [result.lives, result.bought])


func _test_level_03_map() -> void:
	print("Niveau 3 : carte")
	var level := await _spawn_level(LEVEL_03)
	_check(level.level_name == "Niveau 1-3" and level.gold == 250 and level.lives == 20, "nom, or et vies de départ")
	_check(level.spawner.waves.size() == 7, "7 vagues définies")
	_check(level.tower_types.size() == 6 and level.tower_types.has(BEAM), "6 types de tours, dont le Rayon")
	_check(level.get_next_level() == LEVEL_04.resource_path, "le niveau 4 suit")
	var uses_couveuse := false
	for wave in level.spawner.waves:
		for group in wave.groups:
			uses_couveuse = uses_couveuse or group.enemy == COUVEUSE
	_check(uses_couveuse, "les vagues contiennent des Couveuses")
	for cell in level.map.blocked_cells:
		_check(not level.map.is_cell_on_path(cell), "le rocher %s est hors du chemin" % cell)
	_check(level.map.is_cell_on_path(Vector2i(10, 1)) and level.map.is_cell_on_path(Vector2i(10, 4))
		and level.map.is_cell_on_path(Vector2i(10, 7)), "le chemin traverse la carte trois fois")
	await _free(level)


func _test_splitting_enemy() -> void:
	print("Couveuse : se divise à sa mort")
	var level := await _spawn_level(LEVEL_03)
	var couveuse := level.spawner.spawn(COUVEUSE, level.map.get_enemy_path(0), 400.0)
	var spawned: Array[Enemy] = []
	level.spawner.enemy_spawned.connect(func(enemy: Enemy) -> void: spawned.append(enemy))
	var gold_before := level.gold
	couveuse.take_damage(1e9)
	_check(spawned.size() == COUVEUSE.split_count and spawned.all(func(e: Enemy) -> bool: return e.data == LARVE),
		"%d Larves apparaissent à sa mort" % COUVEUSE.split_count)
	_check(spawned.all(func(e: Enemy) -> bool: return e.progress <= 400.0 and e.progress > 300.0),
		"ils apparaissent à sa place, en file sur le chemin")
	_check(level.gold == gold_before + COUVEUSE.reward, "la Couveuse rapporte sa prime")
	for enemy in spawned:
		enemy.take_damage(1e9)
	_check(level.gold == gold_before + COUVEUSE.reward + LARVE.reward * COUVEUSE.split_count,
		"chaque Larve rapporte aussi la sienne")
	_check(get_nodes_in_group(Enemy.GROUP).is_empty(), "plus aucun ennemi : les petits ne se divisent pas")
	await _free(level)


func _test_shielded_enemy() -> void:
	print("Sentinelle : bouclier d'énergie qui se recharge")
	var level := await _spawn_level(MECHA_01)
	var sentinelle := _add_still_enemy(level, SENTINELLE, 0, 200.0)
	_check(sentinelle.health.shield == SENTINELLE.max_shield, "la Sentinelle arrive avec son bouclier plein")
	_check(is_equal_approx(sentinelle.take_damage(GATLING.damage), GATLING.damage)
		and sentinelle.health.health == SENTINELLE.max_health, "le bouclier encaisse la mitrailleuse, sans armure")
	sentinelle.take_damage(SENTINELLE.max_shield)
	_check(sentinelle.health.shield == 0.0 and sentinelle.health.health < SENTINELLE.max_health,
		"une fois le bouclier vidé, les coups passent sur les points de vie")
	var elapsed := 0.0
	while sentinelle.health.shield < SENTINELLE.max_shield and elapsed < 10.0:
		elapsed += await _step()
	_check(sentinelle.health.shield == SENTINELLE.max_shield and elapsed > sentinelle.health.shield_regen_delay,
		"le bouclier se recharge après quelques secondes sans être touché (%.1f s)" % elapsed)
	await _free(level)


func _test_healer_enemy() -> void:
	print("Médecin : soigne les ennemis blessés autour de lui")
	var level := await _spawn_level(HUMANOID_01)
	var medecin := _add_still_enemy(level, MEDECIN, 0, 300.0)
	var close := _add_still_enemy(level, SOLDAT, 0, 300.0 + MEDECIN.heal_radius * 0.5)
	var far := _add_still_enemy(level, SOLDAT, 0, 300.0 + MEDECIN.heal_radius * 3.0)
	level._on_enemy_spawned(close)
	close.take_damage(40.0)
	far.take_damage(40.0)
	medecin.take_damage(40.0)
	# Seul le Médecin avance dans le temps (les soldats restent immobiles, à distance fixe).
	medecin.data = MEDECIN.duplicate()
	medecin.data.speed = 0.0
	medecin.set_process(true)
	var elapsed := 0.0
	while close.health.health < SOLDAT.max_health and elapsed < MEDECIN.heal_interval * 4.0:
		elapsed += await _step()
	_check(close.health.health == SOLDAT.max_health, "le soldat blessé à côté est soigné")
	_check(far.health.health == SOLDAT.max_health - 40.0, "pas celui qui est trop loin")
	_check(medecin.health.health == MEDECIN.max_health - 40.0, "le Médecin ne se soigne pas lui-même")
	var heal_shown := level.effects.get_children().any(func(n: Node) -> bool:
		return n is FloatingText and n.text.begins_with("+") and n.color == Level.HEAL_TEXT_COLOR)
	_check(heal_shown, "le soin s'affiche en vert")
	await _free(level)


## Pose une tour au centre de la carte (case libre la plus proche de x, y) et renvoie la tour.
func _place_test_tower(level: Level, data: TowerData) -> Tower:
	level.gold = 100000
	for cell in [Vector2i(4, 2), Vector2i(4, 4), Vector2i(2, 2), Vector2i(6, 6)]:
		var tower := level.place_tower(cell, data)
		if tower:
			return tower
	return null


## Ennemi immobile posé à un endroit précis (hors du chemin si besoin).
func _add_enemy_at(level: Level, data: EnemyData, at: Vector2) -> Enemy:
	var enemy := _add_still_enemy(level, data, 0, 0.0)
	enemy.global_position = at
	return enemy


func _test_burn_and_flame_tower() -> void:
	print("Lance-flammes : cône de flammes et brûlure qui passe sous l'armure")
	var level := await _spawn_level(LEVEL_03)
	var still: EnemyData = SCARABEE.duplicate()
	still.speed = 0.0
	var scarabee := _add_still_enemy(level, still, 0, 200.0)
	scarabee.set_process(true)
	scarabee.apply_dot(10.0, 2.0)
	var elapsed := 0.0
	while elapsed < 3.0:
		elapsed += await _step()
	_check(is_equal_approx(scarabee.health.health, SCARABEE.max_health - 20.0),
		"la brûlure fait 10/s pendant 2 s, sans armure (%s PV restants)" % scarabee.health.health)
	_check(not scarabee.is_burning(), "puis s'éteint")

	var tower := _place_test_tower(level, FLAME) as FlameTower
	_check(tower != null, "le Lance-flammes vient de sa scène")
	tower.set_process(false)
	var at := tower.global_position
	var front := _add_enemy_at(level, LARVE, at + Vector2(60, 0))
	var side := _add_enemy_at(level, LARVE, at + Vector2(60, 15))
	var behind := _add_enemy_at(level, LARVE, at + Vector2(-60, 0))
	var too_far := _add_enemy_at(level, LARVE, at + Vector2(FLAME.attack_range + 30.0, 0))
	tower._attack(front)
	_check(front.health.health < LARVE.max_health and side.health.health < LARVE.max_health and front.is_burning(),
		"les ennemis dans le cône sont touchés et brûlent")
	_check(behind.health.health == LARVE.max_health and too_far.health.health == LARVE.max_health,
		"pas ceux derrière la tour ou hors de portée")
	await _free(level)


func _test_gas_clouds() -> void:
	print("Pesticide et Lacrymogène : nuages")
	var level := await _spawn_level(LEVEL_03)
	var tower := _place_test_tower(level, PESTICIDE)
	tower.set_process(false)
	var still: EnemyData = SCARABEE.duplicate()
	still.speed = 0.0
	var target := _add_still_enemy(level, still, 0, 300.0)
	target.set_process(true)
	tower._attack(target)
	var cloud: GasCloud = null
	var elapsed := 0.0
	while cloud == null and elapsed < 5.0:
		elapsed += await _step()
		for node in level.projectiles.get_children():
			if node is GasCloud:
				cloud = node
	_check(cloud != null, "la grenade laisse un nuage à l'impact")
	_check(target.is_burning(), "le Scarabée dans le nuage est empoisonné")
	var walker := _add_still_enemy(level, still, 0, 300.0)
	walker.set_process(true)
	await _step()
	await _step()
	_check(walker.is_burning(), "un ennemi qui arrive dans le nuage est empoisonné à son tour")
	var health_before := target.health.health
	elapsed = 0.0
	while elapsed < 2.0:
		elapsed += await _step()
	_check(target.health.health < health_before - 10.0, "le poison passe sous la carapace (%s → %s)" % [health_before, target.health.health])
	elapsed = 0.0
	while is_instance_valid(cloud) and elapsed < 10.0:
		elapsed += await _step()
	_check(not is_instance_valid(cloud), "le nuage se dissipe")
	await _free(level)

	level = await _spawn_level(HUMANOID_01)
	var soldier := _add_still_enemy(level, SOLDAT, 0, 300.0)
	var cloud_stats := TEARGAS.get_stats_at_level(1)
	var gas := GasCloud.new()
	gas.stats = cloud_stats
	level.projectiles.add_child(gas)
	gas.global_position = soldier.global_position
	await _step()
	_check(soldier.is_slowed() and not soldier.can_be_healed(), "le gaz lacrymogène ralentit et empêche les soins")
	await _free(level)


func _test_jammer_and_rail() -> void:
	print("Brouilleur IEM et Perforateur : contre les boucliers et les blindés")
	var level := await _spawn_level(MECHA_01)
	var still: EnemyData = SENTINELLE.duplicate()
	still.speed = 0.0
	var sentinelle := _add_still_enemy(level, still, 0, 200.0)
	sentinelle.set_process(true)
	var stats := JAMMER.get_stats_at_level(1)
	sentinelle.hit(stats.damage, stats)
	_check(is_equal_approx(sentinelle.health.shield, SENTINELLE.max_shield - stats.damage * 5.0),
		"l'onde fait 5 fois plus de dégâts au bouclier")
	_check(sentinelle.health.is_shield_jammed(), "et le brouille")
	var shield_before := sentinelle.health.shield
	var elapsed := 0.0
	while elapsed < stats.shield_jam_duration - 0.3:
		elapsed += await _step()
	_check(sentinelle.health.shield == shield_before, "un bouclier brouillé ne se recharge pas")
	while elapsed < stats.shield_jam_duration + SENTINELLE.max_shield / SENTINELLE.shield_regen + 1.0:
		elapsed += await _step()
	_check(sentinelle.health.shield == SENTINELLE.max_shield, "puis se recharge une fois le brouillage fini")
	_check(is_equal_approx(sentinelle.take_damage(SENTINELLE.max_shield), SENTINELLE.max_shield),
		"les autres tours font des dégâts normaux au bouclier")

	var rail := _place_test_tower(level, RAIL) as RailTower
	_check(rail != null, "le Perforateur vient de sa scène")
	rail.set_process(false)
	var at := rail.global_position
	var first := _add_enemy_at(level, CHENILLARD, at + Vector2(60, 0))
	var second := _add_enemy_at(level, CHENILLARD, at + Vector2(120, 0))
	var third := _add_enemy_at(level, CHENILLARD, at + Vector2(180, 0))
	var aside := _add_enemy_at(level, CHENILLARD, at + Vector2(120, 60))
	rail._attack(first)
	var full := CHENILLARD.max_health - RAIL.get_stats_at_level(1).damage
	_check([first, second, third].all(func(e: Enemy) -> bool: return is_equal_approx(e.health.health, full)),
		"le tir traverse les 3 Chenillards alignés, sans compter leur armure")
	_check(aside.health.health == CHENILLARD.max_health, "pas celui qui est à côté de la ligne")
	await _free(level)


func _test_marksman() -> void:
	print("Franc-tireur : abat les Médecins et bloque les soins")
	var level := await _spawn_level(HUMANOID_01)
	var tower := _place_test_tower(level, MARKSMAN)
	tower.set_process(false)
	var ahead := _add_still_enemy(level, SOLDAT, 0, 400.0)
	var medecin := _add_still_enemy(level, MEDECIN, 0, 300.0)
	tower.stats.attack_range = 10000.0
	_check(tower.find_target() == medecin, "il vise le Médecin avant le soldat plus avancé")
	tower.set_target_mode(Tower.TargetMode.STRONGEST)
	_check(tower.find_target() == medecin, "quelle que soit la règle de ciblage")
	_check(CANNON.get_stats_at_level(1).prefers_healers == false, "les autres tours n'ont pas cette priorité")
	# Un Médecin qui arrive à portée fait lâcher la cible en cours au moment de tirer.
	tower.set_target_mode(Tower.TargetMode.FIRST)
	medecin.visible = false
	medecin.remove_from_group(Enemy.GROUP)
	tower._target = tower.find_target()
	_check(tower._target == ahead, "(sans Médecin, il vise le soldat)")
	medecin.add_to_group(Enemy.GROUP)
	medecin.visible = true
	tower._cooldown = 0.0
	tower._process(0.0)
	_check(tower._target == medecin, "il change de cible quand un Médecin arrive à portée")
	# Le Médecin touché ne soigne plus, et le soldat touché ne peut plus être soigné.
	var patient := _add_still_enemy(level, SOLDAT, 0, 300.0 + MEDECIN.heal_radius * 0.5)
	patient.take_damage(40.0)
	medecin.hit(1.0, tower.stats)
	medecin.data = MEDECIN.duplicate()
	medecin.data.speed = 0.0
	medecin.set_process(true)
	var elapsed := 0.0
	while elapsed < MARKSMAN.heal_block_duration - 0.5:
		elapsed += await _step()
	_check(patient.health.health == SOLDAT.max_health - 40.0, "un Médecin touché ne soigne plus")
	while elapsed < MARKSMAN.heal_block_duration + MEDECIN.heal_interval * 2.0:
		elapsed += await _step()
	_check(patient.health.health > SOLDAT.max_health - 40.0, "il reprend une fois l'effet passé")
	patient.take_damage(40.0)
	patient.hit(1.0, tower.stats)
	var hurt := patient.health.health
	elapsed = 0.0
	while elapsed < MARKSMAN.heal_block_duration - 0.5:
		elapsed += await _step()
	_check(patient.health.health == hurt, "un ennemi touché ne peut plus être soigné")
	_check(ahead.health.health == SOLDAT.max_health, "(le soldat hors de portée du soin n'a rien)")
	await _free(level)

func _test_arc_tower() -> void:
	print("Arc électrique : un éclair qui rebondit d'ennemi en ennemi")
	var level := await _spawn_level(MECHA_01)
	var arc := _place_test_tower(level, ARC) as ArcTower
	_check(arc != null, "l'Arc électrique vient de sa scène")
	arc.set_process(false)
	var at := arc.global_position
	var still: EnemyData = CHENILLARD.duplicate()
	still.armor = 0.0
	var targets: Array[Enemy] = []
	for i in 5:
		targets.append(_add_enemy_at(level, still, at + Vector2(60 + i * 90, 0)))
	var far := _add_enemy_at(level, still, at + Vector2(60 + 3 * 90, 300))
	var chain := arc.get_chain(targets[0])
	_check(chain == targets.slice(0, 4), "3 rebonds : il touche les 4 ennemis les plus proches l'un de l'autre, dans l'ordre")
	arc._attack(targets[0])
	var damage := ARC.get_stats_at_level(1).damage
	var lost: Array[float] = []
	for enemy in targets:
		lost.append(still.max_health - enemy.health.health)
	_check(is_equal_approx(lost[0], damage) and is_equal_approx(lost[1], damage * 0.75)
		and is_equal_approx(lost[3], damage * pow(0.75, 3)), "un quart de dégâts en moins à chaque rebond")
	_check(lost[4] == 0.0 and far.health.health == still.max_health, "pas de quatrième rebond, ni de saut trop long")
	_check(ARC.get_stats_at_level(3).chain_count == 5, "chaque amélioration ajoute un rebond")
	var sentinelle := _add_enemy_at(level, SENTINELLE, at + Vector2(0, 80))
	sentinelle.hit(10.0, ARC.get_stats_at_level(1))
	_check(is_equal_approx(sentinelle.health.shield, SENTINELLE.max_shield - 15.0), "50 % de dégâts en plus sur les boucliers")
	await _free(level)


func _test_coil_tower() -> void:
	print("Bobine : renforce les tours voisines")
	var level := await _spawn_level(MECHA_01)
	level.gold = 100000
	var cannon := level.place_tower(Vector2i(4, 2), CANNON)
	var far := level.place_tower(Vector2i(6, 6), CANNON)
	var base_damage := cannon.stats.damage
	var base_rate := cannon.stats.fire_rate
	var coil := level.place_tower(Vector2i(5, 3), COIL) as CoilTower
	_check(coil != null and coil.find_target() == null, "la Bobine se pose et ne tire pas")
	_check(is_equal_approx(cannon.stats.damage, base_damage * 1.25) and is_equal_approx(cannon.stats.fire_rate, base_rate * 1.15),
		"le Canon voisin (en diagonale) fait 25 % de dégâts en plus et tire 15 % plus vite")
	_check(not far.is_boosted() and coil.boosted_towers == [cannon], "pas le Canon plus loin")
	var second := level.place_tower(Vector2i(3, 3), COIL) as CoilTower
	level.upgrade_tower(second)
	_check(is_equal_approx(cannon.boost_damage, 0.35) and second.boosted_towers.has(cannon) and not coil.boosted_towers.has(cannon),
		"deux Bobines ne s'additionnent pas : le Canon garde la plus forte")
	_check(not second.is_boosted(), "une Bobine ne renforce pas une autre Bobine")
	level.upgrade_tower(cannon)
	_check(is_equal_approx(cannon.stats.damage, CANNON.get_stats_at_level(2).damage * 1.35), "le bonus suit les améliorations de la tour")
	level.inspect_tower(cannon)
	_check(level.hud.tower_details.description_label.text.contains("Renforcée par une Bobine"), "la fiche le dit")
	level.inspect_tower(second)
	_check(level.hud.tower_details.stats_grid.get_child(1).text == "+35 %", "la fiche de la Bobine montre son bonus")
	level.sell_tower(second)
	level.sell_tower(coil)
	_check(not cannon.is_boosted() and is_equal_approx(cannon.stats.damage, CANNON.get_stats_at_level(2).damage),
		"vendre les Bobines retire le bonus")
	await _free(level)


func _test_magnet_tower() -> void:
	print("Électroaimant : fait reculer les ennemis")
	var level := await _spawn_level(LEVEL_01)
	var magnet := _place_test_tower(level, MAGNET) as PulseTower
	_check(magnet != null, "l'Électroaimant est une tour à onde")
	magnet.set_process(false)
	var path := level.map.get_enemy_path(0)
	var near: float = path.curve.get_closest_offset(path.to_local(magnet.global_position))
	var small := _add_still_enemy(level, LARVE, 0, near)
	var big := _add_still_enemy(level, COUVEUSE, 0, near + 10.0)
	small._update_position()
	big._update_position()
	magnet._attack(null)
	var knockback := MAGNET.get_stats_at_level(1).knockback
	_check(is_equal_approx(small.progress, near - knockback), "une Larve recule de %d pixels" % knockback)
	_check(is_equal_approx(big.progress, near + 10.0 - knockback * Enemy.KNOCKBACK_FULL_RADIUS / COUVEUSE.radius),
		"une Couveuse, plus grosse, recule moins")
	var before := small.progress
	magnet._attack(null)
	_check(small.progress == before, "un ennemi qui vient de reculer ne recule plus tout de suite")
	await _free(level)


func _test_flying_enemies() -> void:
	print("Monstres volants : trajet qui coupe les virages, tours qui tirent au sol ou en l'air")
	var level := await _spawn_level(LEVEL_01)
	var path := level.map.get_enemy_path(0)
	var flight := Enemy.get_flight_curve(path)
	var last := path.curve.point_count - 1
	_check(flight.get_baked_length() < path.curve.get_baked_length() * 0.85
			and flight.get_point_position(0) == path.curve.get_point_position(0)
			and flight.get_point_position(flight.point_count - 1) == path.curve.get_point_position(last),
		"le volant part de l'entrée, arrive à la base et coupe les virages (%d px contre %d)"
			% [flight.get_baked_length(), path.curve.get_baked_length()])
	_check(Enemy.get_flight_curve(path) == flight, "le trajet de vol est calculé une fois par chemin")
	var walker := _add_still_enemy(level, FRELON, 0, 0.0)
	walker.set_process(true)
	var elapsed := 0.0
	while elapsed < 2.0:
		elapsed += await _step()
	_check(walker.progress > 0.0 and walker.z_index > 0, "il avance, au-dessus des tours et des autres monstres")
	walker.despawn()

	var mortar := _place_test_tower(level, MORTAR)
	mortar.set_process(false)
	var at := mortar.global_position + Vector2(70, 0)
	var flier := _add_enemy_at(level, FRELON, at)
	_check(mortar.find_target() == null, "le Mortier ne vise pas un volant")
	var larve := _add_enemy_at(level, LARVE, at)
	_check(mortar.find_target() == larve, "mais vise un monstre au sol")
	var shell := Projectile.new()
	shell.stats = mortar.stats
	shell.global_position = at
	level.add_child(shell)
	shell._hit_all_in_radius(mortar.stats.splash_radius)
	_check(flier.health.health == FRELON.max_health and larve.health.health < LARVE.max_health,
		"son explosion épargne le volant au-dessus de la cible")
	shell.free()
	larve.despawn()

	var gatling := _place_near(level, GATLING, level.map.world_to_cell(mortar.global_position))
	gatling.set_process(false)
	var near := _add_enemy_at(level, FRELON, gatling.global_position + Vector2(40, 0))
	_check(gatling.find_target() != null, "la Mitrailleuse vise les volants")
	var dealt := near.hit(10.0, gatling.stats)
	_check(is_equal_approx(dealt, 15.0), "et leur fait 50 %% de dégâts en plus (%s)" % dealt)
	_check(not FRELON.get_abilities().is_empty() and FRELON.get_abilities()[0].begins_with("Volant"),
		"sa capacité « Volant » est décrite")
	await _free(level)

	var flying_level := await _spawn_level(LEVEL_02)
	var preview: PathPreview = flying_level.get_node("PathPreview")
	_check(not preview._flight_paths.is_empty(), "l'aperçu du trajet montre aussi le vol des volants du niveau")
	await _free(flying_level)


## Pose une tour sur la case libre la plus proche de `around` (au plus 2 cases autour).
func _place_near(level: Level, data: TowerData, around: Vector2i) -> Tower:
	level.gold = 100000
	for radius in range(1, 3):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var tower := level.place_tower(around + Vector2i(dx, dy), data)
				if tower:
					return tower
	return null


func _test_stealthy_enemies() -> void:
	print("Monstres furtifs : invisibles sauf près d'une tour qui détecte")
	var level := await _spawn_level(LEVEL_01)
	var cannon := _place_test_tower(level, CANNON)
	cannon.set_process(false)
	var mante := _add_enemy_at(level, MANTE, cannon.global_position + Vector2(60, 0))
	mante._update_detection()
	_check(not mante.is_revealed() and mante.modulate.a < 1.0, "un furtif est caché, à demi transparent")
	_check(cannon.find_target() == null, "le Canon ne le voit pas")
	_check(not cannon.stats.detects_stealth() and SNIPER.detects_stealth() and MARKSMAN.detects_stealth()
			and COIL.detects_stealth(), "Sniper, Franc-tireur et Bobine détectent les furtifs, pas le Canon")
	var frost := _place_near(level, FROST, level.map.world_to_cell(cannon.global_position))
	frost.set_process(false)
	var hidden := _add_enemy_at(level, MANTE, frost.global_position + Vector2(40, 0))
	hidden._update_detection()
	_check(not hidden.is_revealed() and frost.find_target() != null,
		"l'onde du Givre, qui ne vise pas, part quand même sur un furtif caché")
	hidden.despawn()
	var sniper := _place_near(level, SNIPER, level.map.world_to_cell(cannon.global_position))
	sniper.set_process(false)
	_check(sniper.is_in_group(Enemy.DETECTOR_GROUP), "le Sniper posé détecte autour de lui")
	mante._update_detection()
	_check(mante.is_revealed() and mante.modulate.a == 1.0, "le furtif à portée de détection est révélé")
	_check(cannon.find_target() == mante, "et le Canon peut alors le viser")
	sniper.despawn()
	await process_frame
	mante._update_detection()
	_check(not mante.is_revealed(), "il redevient invisible quand le Sniper n'est plus là")
	await _free(level)


func _test_burrowing_enemies() -> void:
	print("Tunnelier : il plonge sous le chemin, hors d'atteinte des tours, et remonte avant la base")
	var level := await _spawn_level(LEVEL_01)
	var cannon := _place_test_tower(level, CANNON)
	cannon.set_process(false)
	var borer := _add_enemy_at(level, TUNNELIER, cannon.global_position + Vector2(60, 0))
	_check(cannon.find_target() == borer, "en surface, le Canon le vise")
	borer._set_burrowed(true)
	_check(borer.is_burrowed() and cannon.find_target() == null and not borer.health_bar.visible,
		"sous terre, aucune tour ne le voit et sa barre de vie disparaît")
	_check(borer.take_damage(50.0) == 0.0 and borer.hit(50.0, CANNON.get_stats_at_level(1)) == 0.0
			and Enemy.get_alive_in_radius(self, borer.global_position, 50.0).is_empty(),
		"ni les coups, ni les ondes, ni les explosions ne l'atteignent")
	_check(is_equal_approx(borer.get_speed(), TUNNELIER.speed * TUNNELIER.burrow_speed_multiplier), "il creuse plus vite qu'il ne roule")
	borer.despawn()
	# Il plonge et remonte de lui-même en avançant sur le chemin.
	var walker := _add_still_enemy(level, TUNNELIER, 0, 0.0)
	walker.set_process(true)
	var dove := false
	var surfaced := false
	var elapsed := 0.0
	while elapsed < TUNNELIER.burrow_interval + TUNNELIER.burrow_duration + 0.5 and walker.is_alive:
		elapsed += await _step()
		dove = dove or walker.is_burrowed()
		surfaced = dove and not walker.is_burrowed()
	_check(dove and surfaced, "il plonge toutes les %s s et remonte au bout de %s s" % [TUNNELIER.burrow_interval, TUNNELIER.burrow_duration])
	# Près de la base, il reste en surface.
	walker.progress = walker._path_length - Enemy.BURROW_SURFACE_DISTANCE + 10.0
	walker._burrow_cooldown = 0.0
	walker._update_burrow(0.1)
	_check(not walker.is_burrowed(), "il ne plonge plus près de la base")
	walker.despawn()
	_check(TUNNELIER.get_abilities()[0].begins_with("Tunnelier"), "sa capacité est décrite dans sa fiche")
	await _free(level)


func _test_saboteurs() -> void:
	print("Saboteur : il éteint quelques secondes la tour la plus proche")
	var level := await _spawn_level(LEVEL_01)
	var sniper := _place_test_tower(level, SNIPER)
	var cannon := _place_near(level, CANNON, Vector2i(10, 8))
	var saboteur := _add_enemy_at(level, SABOTEUR, sniper.global_position + Vector2(50, 0))
	var mante := _add_enemy_at(level, MANTE, sniper.global_position + Vector2(70, 0))
	mante._update_detection()
	_check(mante.is_revealed(), "le Sniper détecte la Mante")
	saboteur._sabotage_cooldown = 0.0
	saboteur._update_sabotage(0.1)
	_check(sniper.is_sabotaged() and not cannon.is_sabotaged(), "il éteint la tour la plus proche, pas celle qui est loin")
	_check(sniper.find_target() != null and not sniper.is_in_group(Enemy.DETECTOR_GROUP),
		"la tour éteinte ne détecte plus les furtifs")
	mante._update_detection()
	_check(not mante.is_revealed(), "la Mante redevient invisible")
	sniper._cooldown = 0.0
	var health := saboteur.health.health
	var elapsed := 0.0
	while elapsed < 1.0:
		elapsed += await _step()
	_check(saboteur.health.health == health and sniper._target == null, "la tour éteinte ne tire plus")
	while elapsed < SABOTEUR.sabotage_duration + 0.3:
		elapsed += await _step()
	_check(not sniper.is_sabotaged() and sniper.is_in_group(Enemy.DETECTOR_GROUP),
		"au bout de %s s, elle se rallume et détecte de nouveau" % SABOTEUR.sabotage_duration)
	# Une Bobine éteinte ne renforce plus ses voisines.
	var coil := _place_near(level, COIL, sniper.cell)
	_check(sniper.is_boosted(), "la Bobine renforce le Sniper")
	coil.sabotage(2.0)
	_check(not sniper.is_boosted(), "éteinte, elle ne le renforce plus")
	_check(SABOTEUR.get_abilities()[0].begins_with("Saboteur"), "sa capacité est décrite dans sa fiche")
	await _free(level)


func _test_necropolis_flyer_and_stealth() -> void:
	print("La Nécropole a aussi son volant et son furtif")
	var world: World = (load("res://resources/campaign.tres") as Campaign).worlds[3]
	_check(BANSHEE.flying and BANSHEE in world.enemies, "la Banshee vole et fait partie de La Nécropole")
	_check(REVENANT.stealthy and REVENANT.revive_count == 1 and REVENANT in world.enemies,
		"le Revenant est furtif et se relève une fois")
	var shapes := [Creature.shape_of(BANSHEE), Creature.shape_of(REVENANT), Creature.shape_of(TUNNELIER), Creature.shape_of(SABOTEUR)]
	_check(shapes == ["banshee", "revenant", "tunnelier", "saboteur"], "chacun a son dessin en trois quarts (%s)" % [shapes])


func _test_crossings_in_tree() -> void:
	print("Arbre des améliorations : croisements de tours")
	var tree := Perks.TREE
	var arc := tree.get_perk("arc")
	var coil := tree.get_perk("coil")
	var magnet := tree.get_perk("magnet")
	var crossings := tree.perks.filter(func(p: Perk) -> bool: return p.is_crossing())
	_check([arc, coil, magnet].all(func(p: Perk) -> bool: return tree.get_page(p) == 1 and p.get_unlocked_tower() != null),
		"l'Arc électrique, la Bobine et l'Électroaimant se débloquent dans l'onglet Tours des mondes")
	_check([arc, coil, magnet].all(func(p: Perk) -> bool:
			return p.requires.size() == 2 and tree.get_branch(p.requires[0]) != tree.get_branch(p.requires[1])),
		"chacune demande deux tours de branches différentes")
	_check(crossings.size() == 2 and crossings.all(func(p: Perk) -> bool:
			return tree.get_page(p) == 1 and not p.paid_with_endless_stars and p.get_partner_tower_path() != p.specializes_tower),
		"2 croisements où deux tours s'échangent un effet, payés en étoiles")
	var campaign: Campaign = load("res://resources/campaign.tres")
	_win_in_all_difficulties(campaign.levels)
	for id in ["flame", "pesticide", "jammer", "rail"]:
		Perks.buy(tree.get_perk(id))
	_check(Perks.is_unlocked(arc) and not Perks.is_unlocked(coil), "le Pesticide et le Perforateur ouvrent l'Arc électrique")
	_check(Perks.buy(arc) and Perks.get_unlocked_towers().has(ARC), "l'Arc électrique s'achète et s'ajoute aux tours")
	var cross := tree.get_perk("cross_pesticide_arc")
	_check(ARC.get_stats_at_level(1).dot_damage == 0.0 and Perks.buy(cross), "Nuage ionisé s'achète")
	var arc_stats := ARC.get_stats_at_level(1)
	_check(arc_stats.dot_damage > 0.0 and arc_stats.dot_is_poison, "l'Arc empoisonne, comme le Pesticide")
	_check(PESTICIDE.get_stats_at_level(1).shield_jam_duration > 0.0 and CANNON.get_stats_at_level(1).shield_jam_duration == 0.0,
		"et les nuages du Pesticide brouillent les boucliers, comme une décharge (et pas les autres tours)")
	var screen := PERK_TREE_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	screen.show_page(1)
	_check(screen.get_button(cross).get_child_count() == 2, "la case d'un croisement montre ses deux tours")
	_check(screen._joins_branches(arc) and not screen._joins_branches(tree.get_perk("pesticide")),
		"les traits des croisements vont droit d'une branche à l'autre")
	await _free(screen)
	for id in ["marksman", "teargas", "coil", "cross_teargas_coil"]:
		Perks.buy(tree.get_perk(id))
	var coil_stats := COIL.get_stats_at_level(1)
	_check(coil_stats.slow_factor < 1.0 and coil_stats.heal_block_duration > 0.0, "Gaz sous tension : la Bobine ralentit et bloque les soins")
	_check(is_equal_approx(TEARGAS.get_stats_at_level(1).attack_range, TEARGAS.attack_range * 1.2),
		"et le Lacrymogène porte plus loin")
	var level := await _spawn_level(LEVEL_01)
	var placed := _place_test_tower(level, COIL) as CoilTower
	var larve := _add_enemy_at(level, LARVE, placed.global_position + Vector2(40, 0))
	_check(placed.find_target() == larve, "la Bobine vise alors les ennemis à portée")
	placed._attack(larve)
	_check(larve.is_slowed() and not larve.can_be_healed(), "son onde les ralentit et bloque leurs soins")
	level.inspect_tower(placed)
	_check(level.hud.tower_details.description_label.text.contains("Croisement : Gaz sous tension"), "la fiche le rappelle")
	await _free(level)
	_check(Perks.buy(magnet) and Perks.get_unlocked_towers().size() == 9, "l'Électroaimant demande l'Arc et la Bobine")
	Progress.reset_campaign()


func _test_tower_choice() -> void:
	print("Nombre de tours différentes par niveau, selon la difficulté")
	_check(Difficulty.TOWER_LIMITS == [9, 8, 6, 5], "9 en Facile, 8 en Moyen, 6 en Difficile, 5 en Cauchemar")
	Perks.unlock_everything()
	Difficulty.set_current(Difficulty.CAUCHEMAR)
	var level := await _spawn_level(HUMANOID_01)
	_check(level.available_tower_types.size() == 17 and level.is_choosing_towers and level.hud.tower_picker != null,
		"avec 17 tours débloquées, le niveau s'ouvre sur le choix des tours")
	_check(level.tower_types.is_empty() and level.hud.tower_shop.get_child_count() == 0 and not level.can_start_next_wave(),
		"pas de tour à poser ni de vague avant d'avoir choisi")
	var picker := level.hud.tower_picker
	_check(picker.get_selected() == level.available_tower_types.slice(0, 5), "5 tours cochées d'avance : celles du niveau d'abord")
	_check(picker.get_button(ARC).disabled, "une fois 5 tours cochées, les autres sont grisées")
	picker._show_info(picker.get_button(CANNON))
	_check(picker._info.visible and picker._info.mouse_filter == Control.MOUSE_FILTER_IGNORE
		and picker._info.find_children("*", "Control", true, false).all(func(c: Control) -> bool:
			return c is BaseButton or c.mouse_filter == Control.MOUSE_FILTER_IGNORE),
		"la fiche d'une tour survolée laisse passer la souris vers les cases qu'elle recouvre")
	picker.set_tower_selected(CANNON, false)
	picker.set_tower_selected(ARC, true)
	_check(picker.get_selected().size() == 5 and picker.get_selected().has(ARC), "on remplace une tour par une autre")
	_check(not level.choose_towers(level.available_tower_types.slice(0, 6)), "pas plus de 5 tours en Cauchemar")
	picker.confirm()
	_check(not level.is_choosing_towers and level.hud.tower_picker == null and level.tower_types.size() == 5
		and level.tower_types.has(ARC) and not level.tower_types.has(CANNON), "Jouer valide le choix")
	_check(level.hud.tower_shop.get_child_count() == 5 and level.can_start_next_wave(), "les 5 tours sont dans la barre d'achat")
	await _free(level)
	level = await _spawn_level(HUMANOID_01)
	_check(level.get_default_tower_choice().has(ARC) and not level.get_default_tower_choice().has(CANNON),
		"le dernier choix est coché d'avance la fois suivante")
	await _free(level)
	Difficulty.set_current(Difficulty.FACILE)
	level = await _spawn_level(HUMANOID_01)
	_check(level.hud.tower_picker.get_selected().size() == 9 and level.tower_limit == 9, "9 tours en Facile")
	await _free(level)
	Progress.reset_campaign()
	level = await _spawn_level(LEVEL_01)
	_check(not level.is_choosing_towers and level.tower_types.size() == 3, "pas de choix quand le niveau a assez peu de tours")
	await _free(level)
	Difficulty.set_current(Difficulty.MOYEN)


func _test_worlds() -> void:
	print("Mondes : quatre biomes de 7 niveaux, débloqués l'un après l'autre")
	var campaign: Campaign = load("res://resources/campaign.tres")
	_check(campaign.worlds.size() == 4 and campaign.worlds.all(func(w: World) -> bool: return w.levels.size() == 7),
		"4 mondes de 7 niveaux")
	_check(campaign.size() == 28 and campaign.levels[0] == LEVEL_01.resource_path, "la campagne commence au niveau 1-1")
	_check(campaign.get_next(LEVEL_06.resource_path) == campaign.worlds[0].levels[6]
		and campaign.get_next(campaign.worlds[0].levels[6]) == MECHA_01.resource_path, "après le niveau 1-6 vient le 1-7, puis le 2-1")
	_check(campaign.get_next(campaign.worlds[2].levels[6]) == campaign.worlds[3].levels[0], "après le niveau 3-7 vient le 4-1")
	_check(campaign.get_next(campaign.worlds[3].levels[6]) == "", "le niveau 4-7 est le dernier")
	# Le dernier niveau de chaque monde est un niveau libre : les tours font le labyrinthe.
	_check(campaign.worlds.all(func(w: World) -> bool:
		var level: Level = load(w.levels[6]).instantiate()
		var free: bool = level.get_node("Map").free_layout
		level.free()
		return free), "le niveau 7 de chaque monde est un niveau libre")
	# Chaque monde n'envoie que ses propres monstres.
	for w in campaign.worlds.size():
		var world := campaign.worlds[w]
		var foreign := []
		var seen := {}
		for path in world.levels:
			var level: Level = load(path).instantiate()
			for wave in level.get_node("WaveSpawner").waves:
				for group in wave.groups:
					seen[group.enemy] = true
					if not world.enemies.has(group.enemy) and not world.bosses.has(group.enemy):
						foreign.append(group.enemy.display_name)
			level.free()
		_check(foreign.is_empty(), "%s : seulement les monstres du biome %s" % [world.display_name, foreign])
		_check(world.enemies.all(func(e: EnemyData) -> bool: return seen.has(e) and e.texture != null),
			"%s : chacun de ses monstres apparaît, avec son image" % world.display_name)
	_check(not Progress.is_world_unlocked(campaign, 1), "La Fonderie est verrouillée au départ")
	for path in campaign.worlds[0].levels:
		Progress.record_victory(path, 1)
	_check(Progress.is_world_unlocked(campaign, 1) and not Progress.is_world_unlocked(campaign, 2),
		"finir La Ruche ouvre La Fonderie, pas encore La Cité")
	_check(Progress.get_next_to_play(campaign) == MECHA_01.resource_path, "Continuer ouvre le niveau 2-1")
	Progress.reset_campaign()
	# Fin du dernier niveau d'un monde : le bouton annonce le monde suivant.
	var level := await _spawn_level(LEVEL_07)
	_check(level.get_next_world_name() == "La Fonderie", "le niveau 1-7 ouvre La Fonderie")
	level._end_game(true)
	_check(level.hud.next_level_button.visible and level.hud.next_level_button.text == "Monde suivant"
		and level.hud.end_message.text.contains("La Fonderie"), "l'écran de victoire annonce le nouveau monde")
	await _free(level)
	Progress.reset_campaign()


## Les ennemis marchent un peu sur le côté du chemin, chacun à sa place, et le tirage
## est le même à chaque partie du niveau.
func _test_spawn_spread() -> void:
	print("Ennemis : un peu d'aléatoire dans leur place sur le chemin")
	var offsets := []
	for attempt in 2:
		var level := await _spawn_level(LEVEL_01)
		var row := []
		for i in 8:
			var enemy := level.spawner.spawn(LARVE, level.map.get_enemy_path(0), 200.0)
			enemy.set_process(false)
			row.append(enemy.lateral_offset)
		offsets.append(row)
		if attempt == 0:
			var spread := level.spawner.get_max_lateral_offset(LARVE)
			_check(row.all(func(o: float) -> bool: return absf(o) <= spread + 0.01),
				"chaque ennemi reste sur le chemin (décalage d'au plus %d px)" % spread)
			var distinct := {}
			for o: float in row:
				distinct[snappedf(o, 0.5)] = true
			_check(distinct.size() >= 6 and spread >= 12.0, "les ennemis ne sont pas tous sur la même ligne")
			var on_path: Enemy = level.get_tree().get_nodes_in_group(Enemy.GROUP)[0]
			var center := level.map.get_enemy_path(0).curve.sample_baked(200.0)
			_check(is_equal_approx(on_path.global_position.distance_to(level.map.get_enemy_path(0).to_global(center)),
				absf(on_path.lateral_offset)), "le décalage est perpendiculaire à la marche")
		await _free(level)
	_check(offsets[0] == offsets[1], "le tirage est le même d'une partie à l'autre (les tests d'équilibrage restent stables)")


func _test_endless_mode() -> void:
	print("Mode infini")
	_unlock_all_modes()
	var unlock_stars := Perks.get_earned_stars()
	_check(not Progress.is_endless_unlocked(LEVEL_01.resource_path), "fermé tant que le niveau n'a pas 3 étoiles")
	Progress.record_victory(LEVEL_01.resource_path, 2)
	_check(not Progress.is_endless_unlocked(LEVEL_01.resource_path), "toujours fermé avec 2 étoiles")
	Progress.record_victory(LEVEL_01.resource_path, 3)
	_check(Progress.is_endless_unlocked(LEVEL_01.resource_path), "ouvert avec 3 étoiles")
	_check(Progress.endless_stars_for(4) == 0 and Progress.endless_stars_for(5) == 1
		and Progress.endless_stars_for(12) == 2 and Progress.endless_stars_for(99) == Progress.ENDLESS_MAX_STARS,
		"une étoile infinie toutes les 5 vagues de plus que le niveau, 5 au plus")

	var screen := await _spawn_world_select()
	var mode_button: Button = screen.get_node("%ModeButton")
	mode_button.toggled.emit(true)
	await process_frame
	var endless_button: Button = screen.get_level_button(LEVEL_01.resource_path)
	_check(screen.endless_mode and screen.get_node("%Title").text == "Mode infini", "le bouton Mode infini change les cartes")
	_check(not endless_button.disabled and endless_button.text.ends_with("☆☆☆☆☆")
		and screen.get_level_button(LEVEL_02.resource_path).disabled, "seul le niveau à 3 étoiles s'ouvre en mode infini")
	_check(screen.get_card(0).find_child("Stars", true, false).text.contains("0 / 35"), "la carte compte les étoiles infinies du monde")
	await _free(screen)

	Engine.set_meta(Level.ENDLESS_META, true)
	var level := await _spawn_level(LEVEL_01)
	var count := level.spawner.get_wave_count()
	_check(level.is_endless and not Engine.has_meta(Level.ENDLESS_META), "le niveau s'ouvre en mode infini")
	_check(level.hud.wave_label.text.ends_with("/ ∞") and level.hud.level_label.text.ends_with("Mode infini"),
		"le HUD l'annonce")
	level.spawner.current_wave = count - 1
	_check(level.spawner.has_next_wave(), "après la dernière vague du niveau, il y en a toujours une autre")
	var last := level.spawner.get_wave(count - 1)
	var first_extra := level.spawner.get_wave(count)
	var later := level.spawner.get_wave(count + 9)
	var enemies_in := func(wave: WaveData) -> int:
		var total := 0
		for group in wave.groups:
			total += group.count
		return total
	_check(first_extra.health_multiplier > 1.0 and later.health_multiplier > first_extra.health_multiplier * 2.0,
		"les ennemis des vagues en plus sont de plus en plus résistants")
	_check(enemies_in.call(later) > enemies_in.call(last), "et de plus en plus nombreux")
	_check(level.spawner.get_wave(count) == first_extra, "une vague créée reste la même")
	level.start_next_wave()
	while level.spawner.is_spawning:
		await _step()
	var spawned: Enemy = get_nodes_in_group(Enemy.GROUP)[0]
	_check(is_equal_approx(spawned.health.max_health, spawned.data.max_health * first_extra.health_multiplier),
		"la vie des ennemis suit la vague")
	for enemy in get_nodes_in_group(Enemy.GROUP):
		enemy.queue_free()
	await process_frame
	# Quatre vagues de plus repoussées, puis la cinquième : la première étoile infinie.
	level.spawner.current_wave = count + 4
	level._check_wave_cleared()
	_check(level.get_waves_cleared() == count + 5 and not level.is_over, "la partie continue après les vagues du niveau")
	_check(Progress.get_endless_waves(LEVEL_01.resource_path) == count + 5
		and Progress.get_endless_stars(LEVEL_01.resource_path) == 1, "chaque vague repoussée compte pour le record et les étoiles")
	_check(Perks.get_earned_stars(true) == 1 and Perks.get_earned_stars() == unlock_stars + 3, "les étoiles infinies sont une monnaie à part")
	level.lives = 1
	level._on_enemy_reached_end(_add_still_enemy(level, LARVE, 0, 0.0))
	_check(level.is_over and level.hud.end_title.text == "Fin de la partie"
		and level.hud.end_message.text.contains("%d vagues" % (count + 5)) and level.hud.end_message.text.contains("Nouveau record")
		and level.hud.end_stars.text == "★☆☆☆☆" and not level.hud.next_level_button.visible,
		"l'écran de fin donne les vagues repoussées, le record et les étoiles infinies")
	_check(Progress.get_stars(LEVEL_01.resource_path) == 3, "le mode infini ne touche pas aux étoiles du niveau")
	await _free(level)
	level = await _spawn_level(LEVEL_01)
	_check(not level.is_endless and not level.spawner.endless, "le niveau suivant s'ouvre normalement")
	await _free(level)
	Progress.reset_campaign()
	_check(Progress.get_endless_waves(LEVEL_01.resource_path) == 0, "Effacer la progression efface les records du mode infini")


## Premier jour de 2026 dont le défi a toutes les règles données (et, avec `level_path`,
## ce niveau), ou "".
func _find_challenge_day(rules: Array[int], level_path := "") -> String:
	for day in 365:
		var date := Time.get_date_dict_from_unix_time(Time.get_unix_time_from_datetime_string("2026-01-01") + day * 86400)
		var key := DailyChallenge.date_key_of(date.year, date.month, date.day)
		var challenge := DailyChallenge.for_date(key)
		if rules.all(challenge.has_rule) and (level_path.is_empty() or challenge.level_path == level_path):
			return key
	return ""


func _test_daily_challenge() -> void:
	print("Défi du jour")
	var a := DailyChallenge.for_date("2026-10-06")
	var b := DailyChallenge.for_date("2026-10-06")
	_check(a.level_path == b.level_path and a.rules == b.rules and a.tower_paths == b.tower_paths,
		"le défi d'un jour est toujours le même")
	var levels := {}
	var rule_seen := {}
	var valid := true
	for day in 60:
		var date := Time.get_date_dict_from_unix_time(Time.get_unix_time_from_datetime_string("2026-09-01") + day * 86400)
		var challenge := DailyChallenge.for_date(DailyChallenge.date_key_of(date.year, date.month, date.day))
		levels[challenge.level_path] = true
		for rule in challenge.rules:
			rule_seen[rule] = true
		var few := challenge.has_rule(DailyChallenge.DEUX_TOURS)
		var towers := challenge.get_towers()
		valid = valid and DailyChallenge.CAMPAIGN.levels.has(challenge.level_path) \
			and towers.size() == (DailyChallenge.FEW_TOWER_COUNT if few else DailyChallenge.TOWER_COUNT) \
			and challenge.rules.size() == DailyChallenge.EXTRA_RULES + (1 if few else 0) \
			and towers.filter(func(t: TowerData) -> bool: return t.is_support() or t.knockback > 0.0).size() \
				<= (0 if few else DailyChallenge.UTILITY_TOWERS_MAX)
	_check(valid, "chaque défi a son niveau de la campagne, 2 règles en plus et 4 tours imposées, au plus une qui ne fait presque pas de dégâts (aucune avec Deux tours seulement)")
	_check(levels.size() >= 10 and rule_seen.size() == DailyChallenge.RULE_NAMES.size(), "le niveau et les règles changent d'un jour à l'autre")
	_check(a.get_date_text() == "mardi 6 octobre 2026", "date du défi en toutes lettres")

	# Un défi sans amélioration, en bourse serrée, sur le niveau 1-1.
	var key := _find_challenge_day([DailyChallenge.SANS_AMELIORATION, DailyChallenge.OR_SERRE], LEVEL_01.resource_path)
	_check(not key.is_empty(), "un jour de 2026 a ce défi")
	var challenge := DailyChallenge.for_date(key)
	var raw: Level = LEVEL_01.instantiate()
	var level_gold := raw.starting_gold
	raw.free()
	Progress.set_value("perks", "owned", PackedStringArray(["tresor", "poudre"]))
	_check(Perks.get_bonuses().starting_gold_bonus > 0, "une amélioration d'or achetée")
	Engine.set_meta(Level.CHALLENGE_META, key)
	var level := await _spawn_level(LEVEL_01)
	_check(level.challenge != null and not Engine.has_meta(Level.CHALLENGE_META) and level.difficulty == Difficulty.MOYEN,
		"le niveau s'ouvre en défi du jour")
	_check(level.tower_types == challenge.get_towers() and not level.is_choosing_towers, "les tours du défi, sans choix des tours")
	_check(level.gold == roundi(level_gold * DailyChallenge.GOLD_MULTIPLIER)
		and level.tower_types[0].get_cost() == level.tower_types[0].cost, "l'arbre des améliorations ne compte pas pendant le défi")
	_check(level.hud.level_label.text.begins_with("Défi du jour") and level.hud.score_label.text == "Score : 0"
		and level.hud.challenge_rules != null, "le HUD montre le défi, le score et les règles")
	_check(not level.has_next_level(), "pas de niveau suivant")
	level.gold = 2000
	var tower := level.place_tower(Vector2i(4, 1), level.tower_types[0])
	_check(tower and not level.upgrade_tower(tower), "Sans amélioration : les tours ne s'améliorent pas")
	level.start_next_wave()
	_check(level.hud.challenge_rules == null, "les règles s'effacent à la première vague")
	var enemy := level.spawner.spawn(LARVE, level.map.get_enemy_path(0), 10.0)
	enemy.take_damage(10000.0)
	await process_frame
	_check(level.score == LARVE.reward * DailyChallenge.POINTS_PER_GOLD, "un monstre détruit rapporte 10 points par pièce d'or")
	for node in get_nodes_in_group(Enemy.GROUP):
		node.queue_free()
	level.spawner.current_wave = level.spawner.get_wave_count() - 1
	level.spawner.is_spawning = false
	level.spawner._queue.clear()
	await process_frame
	level._check_wave_cleared()
	var expected := LARVE.reward * DailyChallenge.POINTS_PER_GOLD + level.spawner.get_wave_count() * DailyChallenge.POINTS_PER_WAVE \
		+ level.lives * DailyChallenge.POINTS_PER_LIFE
	_check(level.is_over and level.score == expected, "victoire : 100 points par vague et 50 par vie gardée (%d)" % level.score)
	_check(Progress.get_daily_score(key) == expected and level.hud.end_title.text == "Défi réussi !"
		and level.hud.end_stars.text == "%d points" % expected, "le score est enregistré et affiché")
	_check(Progress.get_stars(LEVEL_01.resource_path) == 0, "le défi ne donne pas d'étoiles")
	_check(Progress.is_daily_won(key) and level.hud.end_message.text.contains("Série : 1 jour") == false,
		"le jour réussi est enregistré (pas de série annoncée pour un seul jour)")
	await _free(level)
	_check(not Engine.has_meta(Perks.DISABLED_META) and Perks.get_bonuses().starting_gold_bonus > 0,
		"l'arbre compte de nouveau après le défi")
	_check(not Progress.record_daily(key, expected - 1) and Progress.record_daily(key, expected + 1)
		and Progress.get_daily_scores()[key] == expected + 1, "seul le meilleur score du jour est gardé")

	var screen: Control = load("res://scenes/ui/daily_challenge_screen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	_check(screen.challenge.date_key == DailyChallenge.today().date_key and screen.play_button.has_focus(),
		"l'écran du défi montre celui d'aujourd'hui, Jouer prêt")
	_check(screen.get_history_text().contains("1 défi joué"), "et l'historique des scores")
	await _free(screen)
	Progress.reset_campaign()
	_check(Progress.get_daily_scores().is_empty(), "Effacer la progression efface les scores du défi")


func _test_daily_history() -> void:
	print("Défi du jour : historique et série")
	Progress.reset_campaign()
	_check(Progress.previous_day("2026-03-01") == "2026-02-28" and Progress.previous_day("2026-01-01") == "2025-12-31",
		"la veille d'un jour")
	_check(Progress.get_daily_streak("2026-10-08") == 0 and Progress.get_best_daily_streak() == 0, "pas de série sans défi réussi")
	for day in ["2026-10-01", "2026-10-02", "2026-10-03", "2026-10-05", "2026-10-06", "2026-10-07"]:
		Progress.record_daily(day, 1000)
		Progress.record_daily_win(day)
	Progress.record_daily("2026-10-04", 300)
	_check(Progress.get_daily_streak("2026-10-08") == 3, "le défi d'aujourd'hui pas encore réussi ne coupe pas la série")
	Progress.record_daily_win("2026-10-08")
	_check(Progress.get_daily_streak("2026-10-08") == 4 and Progress.get_daily_streak("2026-10-10") == 0,
		"la série compte jusqu'à aujourd'hui, et s'arrête au premier jour manqué")
	_check(Progress.get_best_daily_streak() == 4, "meilleure série")
	var screen: Control = load("res://scenes/ui/daily_challenge_screen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	var today := DailyChallenge.today_key()
	var expected_streak := Progress.get_daily_streak(today)
	_check(screen.get_streak_text().begins_with("Série : %d jour" % expected_streak)
		and screen.get_streak_text().ends_with("meilleure série : %d" % Progress.get_best_daily_streak()),
		"l'écran du défi montre la série et la meilleure série")
	var history: String = screen.get_history_text()
	_check(not history.contains("1000 ✕") and history.contains("300 ✕"),
		"les jours perdus sont marqués dans l'historique")
	await _free(screen)
	Progress.reset_campaign()
	_check(Progress.get_daily_wins().is_empty() and Progress.get_best_daily_streak() == 0,
		"Effacer la progression efface les jours réussis")


func _test_mutators() -> void:
	print("Mutateurs")
	Progress.reset_campaign()
	_unlock_all_modes()
	Mutators.set_active([])
	var path := LEVEL_01.resource_path
	var raw: Level = LEVEL_01.instantiate()
	var level_gold := raw.starting_gold
	raw.free()
	Mutators.set_active([DailyChallenge.NOMBREUX, DailyChallenge.RAPIDES, DailyChallenge.OR_SERRE, DailyChallenge.SANS_AMELIORATION])
	_check(Mutators.get_active() == [DailyChallenge.RAPIDES, DailyChallenge.NOMBREUX, DailyChallenge.OR_SERRE,
		DailyChallenge.SANS_AMELIORATION], "les mutateurs choisis sont enregistrés")
	var level := await _spawn_level(LEVEL_01)
	_check(level.mutators.is_empty() and level.gold == level_gold and level.hud.mutator_label == null,
		"pas de mutateurs sur un niveau pas encore gagné")
	await _free(level)

	Progress.record_victory(path, 2)
	var earned_before := Perks.get_earned_stars(true)
	level = await _spawn_level(LEVEL_01)
	_check(level.mutators.size() == 4 and level.difficulty == Difficulty.MOYEN, "les mutateurs s'appliquent au niveau déjà gagné")
	_check(is_equal_approx(level.spawner.speed_multiplier, DailyChallenge.SPEED_MULTIPLIER)
		and level.gold == roundi(level_gold * DailyChallenge.GOLD_MULTIPLIER), "monstres rapides, bourse serrée")
	_check(level.hud.mutator_label != null and level.hud.challenge_rules != null and level.hud.level_label.text.ends_with("✦ 4"),
		"le HUD montre les mutateurs")
	level.gold = 2000
	var tower := level.place_tower(Vector2i(4, 1), level.tower_types[0])
	_check(tower and not level.upgrade_tower(tower), "Sans amélioration : les tours ne s'améliorent pas")
	level.start_next_wave()
	_check(level.hud.challenge_rules == null, "les règles s'effacent à la première vague")
	for node in get_nodes_in_group(Enemy.GROUP):
		node.queue_free()
	level.spawner.current_wave = level.spawner.get_wave_count() - 1
	level.spawner.is_spawning = false
	level.spawner._queue.clear()
	await process_frame
	level._check_wave_cleared()
	_check(level.is_over and Progress.get_mutator_stars(path) == Mutators.MAX_STARS
		and Perks.get_earned_stars(true) == earned_before + Mutators.MAX_STARS,
		"la victoire rapporte une étoile infinie par mutateur, %d au plus" % Mutators.MAX_STARS)
	_check(level.hud.end_message.text.contains("+3 étoiles infinies") and Progress.get_stars(path) > 0,
		"l'écran de fin le dit, et les étoiles du niveau comptent toujours")
	await _free(level)
	_check(not Progress.record_mutators(path, 1) and Progress.get_mutator_stars(path) == Mutators.MAX_STARS,
		"seul le meilleur résultat est gardé")

	# Ni en mode infini, ni au défi du jour.
	Engine.set_meta(Level.ENDLESS_META, true)
	level = await _spawn_level(LEVEL_01)
	_check(level.mutators.is_empty(), "pas de mutateurs en mode infini")
	await _free(level)

	# Le choix des mutateurs, sur l'écran des mondes.
	Mutators.set_active([])
	var screen: Control = WORLD_SELECT_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	_check(screen.mutators_button.text == "✦  Mutateurs" and not screen.get_level_button(path).has_theme_color_override(&"font_color"),
		"aucun mutateur au départ")
	screen.open_mutators()
	_check(screen.mutators_panel != null and screen.get_mutator_check(DailyChallenge.CORIACES) != null
		and screen.get_mutator_check(DailyChallenge.DEUX_TOURS) == null, "la fenêtre propose les règles du défi")
	screen.get_mutator_check(DailyChallenge.CORIACES).button_pressed = true
	_check(Mutators.get_active() == [DailyChallenge.CORIACES] and screen.mutators_button.text.ends_with("1")
		and screen.get_level_button(path).has_theme_color_override(&"font_color")
		and screen.mode_hint.text.contains("Monstres coriaces"), "cocher un mutateur l'active, et marque les niveaux déjà gagnés")
	_check(screen.get_level_details(path).contains("✦ Mutateurs : Monstres coriaces"), "la fenêtre de détail le dit")
	screen.close_mutators()
	screen.set_endless_mode(true)
	_check(not screen.mutators_button.visible, "pas de mutateurs en mode infini")
	await _free(screen)
	Mutators.set_active([])
	Progress.reset_campaign()
	_check(Progress.get_mutator_stars(path) == 0, "Effacer la progression efface les étoiles des mutateurs")


func _test_difficulties() -> void:
	print("Difficultés : Facile, Moyen, Difficile, Cauchemar")
	var campaign: Campaign = load("res://resources/campaign.tres")
	_check(Difficulty.get_current() == Difficulty.MOYEN, "Moyen par défaut")
	_check(Difficulty.describe(Difficulty.DIFFICILE) == "Monstres 35 % plus résistants, 25 % plus nombreux et 10 % plus rapides.",
		"chaque difficulté décrit ses effets")
	# Les boss ne comptent pas : il n'y en a toujours qu'un (vérifié plus bas).
	var counts := func(level: Level) -> Array:
		var result := []
		for wave in level.spawner.waves:
			for group in wave.groups:
				if not group.enemy.is_boss:
					result.append(group.count)
		return result
	var level := await _spawn_level(LEVEL_03)
	var normal: Array = counts.call(level)
	_check(level.difficulty == Difficulty.MOYEN and level.hud.level_label.text.ends_with("Moyen"),
		"le niveau se joue en Moyen et l'affiche")
	await _free(level)

	Difficulty.set_current(Difficulty.DIFFICILE)
	level = await _spawn_level(LEVEL_03)
	var hard: Array = counts.call(level)
	var expected := normal.map(func(c: int) -> int: return ceili(c * 1.25))
	_check(hard == expected, "Difficile : 25 %% de monstres en plus dans chaque groupe (%s)" % [hard])
	var boss_group: SpawnGroup = level.spawner.waves[-1].groups.filter(
		func(g: SpawnGroup) -> bool: return g.enemy.is_boss)[0]
	_check(boss_group.count == 1, "mais toujours un seul boss")
	_check(is_equal_approx(level.spawner.waves[0].health_multiplier, 1.35), "et 35 % de vie en plus")
	_check(level.hud.level_label.text.ends_with("Difficile"), "le nom du niveau affiche la difficulté")
	var enemy := level.spawner.spawn(SCARABEE, level.map.get_enemy_path(0), 0.0, level.spawner.waves[0].health_multiplier)
	_check(is_equal_approx(enemy.get_speed(), SCARABEE.speed * 1.1)
		and is_equal_approx(enemy.health.max_health, SCARABEE.max_health * 1.35), "un monstre est plus rapide et plus résistant")
	var fresh: Level = LEVEL_03.instantiate()
	var untouched := true
	for wave in fresh.get_node("WaveSpawner").waves:
		untouched = untouched and is_equal_approx(wave.health_multiplier, 1.0)
	_check(untouched and fresh.get_node("WaveSpawner").waves[0].groups[0].count == normal[0],
		"les vagues de la scène ne sont pas modifiées")
	fresh.free()
	level._end_game(true)
	_check(Progress.get_stars(LEVEL_03.resource_path, Difficulty.DIFFICILE) == 3
		and Progress.get_stars(LEVEL_03.resource_path, Difficulty.MOYEN) == 0, "la victoire compte en Difficile seulement")
	_check(Progress.is_unlocked(campaign, 3) and Progress.is_endless_unlocked(LEVEL_03.resource_path),
		"elle débloque le niveau suivant et le mode infini")
	await _free(level)
	Progress.record_victory(LEVEL_03.resource_path, 2, Difficulty.FACILE)
	_check(Progress.get_stars(LEVEL_03.resource_path) == 3 and Progress.get_total_stars(LEVEL_03.resource_path) == 5
		and Perks.get_earned_stars() == 5, "les étoiles des difficultés s'additionnent")

	Engine.set_meta(Level.ENDLESS_META, true)
	level = await _spawn_level(LEVEL_03)
	_check(level.difficulty == Difficulty.MOYEN and counts.call(level).slice(0, normal.size()) == normal,
		"le mode infini se joue toujours en Moyen")
	await _free(level)

	Difficulty.set_current(Difficulty.FACILE)
	level = await _spawn_level(LEVEL_03)
	var easy: Array = counts.call(level)
	_check(easy == normal.map(func(c: int) -> int: return maxi(roundi(c * 0.75), 1)), "Facile : 25 % de monstres en moins")
	await _free(level)

	Progress.record_victory(LEVEL_02.resource_path, 1)
	_unlock_all_modes()
	var screen := await _spawn_world_select()
	_check(screen.difficulty_bar.visible and screen.get_difficulty_button(Difficulty.FACILE).button_pressed,
		"la sélection des mondes montre la difficulté choisie")
	_check(screen.get_level_button(LEVEL_03.resource_path).text.ends_with("★★☆"), "et les étoiles du niveau dans celle-ci")
	_check(screen.mode_hint.text.begins_with("Facile : Monstres"), "avec ses effets")
	screen.get_difficulty_button(Difficulty.CAUCHEMAR).pressed.emit()
	_check(Difficulty.get_current() == Difficulty.CAUCHEMAR and screen.get_level_button(LEVEL_03.resource_path).text.ends_with("☆☆☆"),
		"choisir Cauchemar l'enregistre et met les boutons à jour")
	_check(screen.get_level_button(LEVEL_03.resource_path).tooltip_text.contains("★★★  Difficile"),
		"la bulle d'aide du niveau donne les étoiles de chaque difficulté")
	_check(screen.get_card(0).find_child("Stars", true, false).text == "★ 6 / 84", "la carte compte les étoiles des 4 difficultés")
	screen.set_endless_mode(true)
	_check(not screen.difficulty_bar.visible, "pas de difficulté en mode infini")
	await _free(screen)
	Progress.reset_campaign()

	print("Difficultés : équilibrage du niveau 4")
	var order := [
		[Vector2i(7, 2), CANNON], [Vector2i(6, 4), CANNON], [Vector2i(8, 2), MORTAR],
		[Vector2i(4, 2), BEAM], [Vector2i(9, 2), FROST], [Vector2i(4, 6), CANNON],
		[Vector2i(10, 2), SNIPER], [Vector2i(6, 5), MORTAR], [Vector2i(12, 2), BEAM],
		[Vector2i(13, 4), GATLING], [Vector2i(6, 6), FROST], [Vector2i(11, 2), SNIPER],
		[Vector2i(13, 7), MORTAR], [Vector2i(15, 2), BEAM], [Vector2i(6, 7), CANNON],
		[Vector2i(11, 4), MORTAR], [Vector2i(17, 2), SNIPER], [Vector2i(13, 2), BEAM],
	]
	Difficulty.set_current(Difficulty.FACILE)
	var result := await _play_build_order(LEVEL_04, order, 6)
	_check(result.won, "Facile : gagné avec les 6 tours qui perdent en Moyen")
	Difficulty.set_current(Difficulty.CAUCHEMAR)
	result = await _play_build_order(LEVEL_04, order, order.size())
	_check(not result.won, "Cauchemar : perdu avec les 18 tours qui gagnent en Moyen")
	Difficulty.set_current(Difficulty.MOYEN)
	Progress.reset_campaign()


func _test_specializations() -> void:
	print("Spécialisations des tours, payées en étoiles infinies")
	var tree := Perks.TREE
	var page := tree.page_names.find("Spécialisations")
	var specializations := tree.get_page_perks(page)
	_check(page == 2 and tree.get_page_branches(page).size() == 3 and specializations.size() == 12,
		"un onglet Spécialisations : 3 branches, 12 spécialisations")
	var towers := {}
	var all_valid := true
	for perk in specializations:
		towers[perk.specializes_tower] = true
		all_valid = all_valid and perk.paid_with_endless_stars and load(perk.specializes_tower) is TowerData
	_check(all_valid, "chacune spécialise une tour, payée en étoiles infinies")
	_check(towers.size() == 12, "une spécialisation par tour")
	var gatling := tree.get_perk("spe_gatling")
	var sniper := tree.get_perk("spe_sniper")
	var marksman := tree.get_perk("spe_marksman")
	Progress.record_victory(LEVEL_01.resource_path, 3)
	_check(not Perks.can_buy(gatling), "les étoiles des niveaux n'achètent pas les spécialisations")
	Progress.record_endless(LEVEL_01.resource_path, 20, 3)
	var screen := PERK_TREE_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	screen.show_page(page)
	_check(screen.stars_label.text.begins_with("∞ ★ 3 à dépenser"), "l'onglet compte les étoiles infinies")
	screen.get_button(gatling).pressed.emit()
	_check(Perks.is_owned(gatling) and Perks.get_available_stars(true) == 1 and Perks.get_available_stars() == 3,
		"Balles perforantes coûte 2 étoiles infinies, et aucune étoile des niveaux")
	_check(GATLING.get_stats_at_level(1).armor_piercing and GATLING.get_stats_at_level(3).armor_piercing
		and not CANNON.get_stats_at_level(1).armor_piercing, "les balles de la Mitrailleuse, et d'elle seule, ignorent l'armure")
	_check(not Perks.can_buy(sniper) and screen.get_button(sniper).text.ends_with("∞ ★ 3"), "la suivante est trop chère")
	Progress.record_endless(LEVEL_02.resource_path, 40, 5)
	screen.buy(sniper)
	_check(is_equal_approx(SNIPER.get_stats_at_level(1).damage, 80.0 * 1.4) and is_equal_approx(CANNON.get_stats_at_level(1).damage, 25.0),
		"Tir en pleine tête : +40 % de dégâts pour le Sniper seulement")
	_check(not Perks.can_buy(marksman) and screen.get_button(marksman).text.ends_with("Verrouillé"),
		"la spécialisation d'une tour des mondes demande la tour")
	screen.get_button(marksman).mouse_entered.emit()
	_check(screen.info_status.text.contains("Franc-tireur"), "la fiche le dit")
	var level := await _spawn_level(LEVEL_01)
	var tower := level.place_tower(Vector2i(3, 3), GATLING) if level.map.is_cell_buildable(Vector2i(3, 3)) else null
	if tower == null:
		for y in level.map.rows:
			for x in level.map.columns:
				if tower == null and level.map.is_cell_buildable(Vector2i(x, y)):
					tower = level.place_tower(Vector2i(x, y), GATLING)
	level.inspect_tower(tower)
	_check(tower.stats.armor_piercing and level.hud.tower_details.description_label.text.contains("Balles perforantes"),
		"en jeu, la tour posée a sa spécialisation, rappelée sur sa fiche")
	await _free(level)
	screen.get_node("%RefundButton").pressed.emit()
	_check(Perks.get_owned_ids().is_empty() and Perks.get_available_stars(true) == 8, "Réinitialiser rend aussi les étoiles infinies")
	await _free(screen)
	Progress.reset_campaign()


func _test_konami_code() -> void:
	print("Code Konami sur l'écran titre")
	var title := TITLE_SCREEN.instantiate()
	root.add_child(title)
	await process_frame
	var code := [KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT, KEY_B, KEY_A]
	for keycode in [KEY_UP, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_B, KEY_A]:
		title.enter_konami_key(keycode)
	_check(Perks.get_earned_stars() == 0, "un code faux ne débloque rien")
	# Une flèche de trop au début ne gâche pas le code.
	title.enter_konami_key(KEY_UP)
	for keycode in code:
		var event := InputEventKey.new()
		event.keycode = keycode
		event.pressed = true
		title._input(event)
	var campaign: Campaign = load("res://resources/campaign.tres")
	_check(Perks.get_earned_stars() == (campaign.size() + ConquestLevels.size() + FreeLevels.LEVELS.size()) * Progress.MAX_LEVEL_STARS and Progress.is_world_unlocked(campaign, 2),
		"le code débloque tous les mondes et tous les niveaux, avec 3 étoiles dans chaque difficulté")
	var endless_open := true
	for path in campaign.levels:
		endless_open = endless_open and Progress.is_endless_unlocked(path) \
			and Progress.get_endless_stars(path) == Progress.ENDLESS_MAX_STARS
	_check(endless_open, "et tous les modes infinis, avec leurs étoiles")
	_check(Perks.TREE.perks.all(func(p: Perk) -> bool: return Perks.is_owned(p)), "et toutes les améliorations et spécialisations")
	var announced := false
	for child in title.get_children():
		announced = announced or (child is Label and child.text.contains("Konami"))
	_check(title.get_node("%CampaignButton").text == "Continuer" and announced, "l'écran titre se met à jour et l'annonce")
	Progress.reset_campaign()
	# Flèches du pavé numérique, et A lu à sa place sur le clavier (le Q d'un AZERTY).
	var events := [[KEY_KP_8, KEY_KP_8], [KEY_KP_8, KEY_KP_8], [KEY_DOWN, KEY_DOWN], [KEY_DOWN, KEY_DOWN],
		[KEY_LEFT, KEY_LEFT], [KEY_RIGHT, KEY_RIGHT], [KEY_LEFT, KEY_LEFT], [KEY_RIGHT, KEY_RIGHT],
		[KEY_B, KEY_B], [KEY_Q, KEY_A]]
	for i in events.size():
		var event := InputEventKey.new()
		event.keycode = events[i][0]
		event.physical_keycode = events[i][1]
		event.pressed = true
		title._input(event)
		if i == 4:
			_check(title._konami_label.visible and title._konami_label.text.begins_with("● ● ● ● ● ·"),
				"le code en cours s'affiche, une pastille par touche juste")
	_check(Perks.get_earned_stars() == (campaign.size() + ConquestLevels.size() + FreeLevels.LEVELS.size()) * Progress.MAX_LEVEL_STARS, "les flèches du pavé numérique et le A d'un clavier QWERTY comptent")
	_check(not title._konami_label.visible, "les pastilles disparaissent une fois le code entré")
	await _free(title)
	Progress.reset_campaign()


func _test_carriers_and_chests() -> void:
	print("Porteurs de butin et coffres")
	var level := await _spawn_level(LEVEL_01)
	var spawner := level.spawner
	var counts: Array[Dictionary] = []
	for wave in 3:
		spawner.start_next_wave()
		var found := {}
		for entry in spawner._queue:
			if entry.has("carried"):
				found[entry.carried] = found.get(entry.carried, 0) + 1
		counts.append(found)
		spawner.is_spawning = false
	_check(counts[0].is_empty(), "pas de porteur dans la première vague")
	_check(counts[1] == {Loot.Kind.GOLD: 1}, "un porteur d'or dans la deuxième")
	_check(counts[2] == {Loot.Kind.GOLD: 1, Loot.Kind.CHEST: 1}, "et un porteur de coffre de plus dans la troisième")
	spawner._queue.clear()
	var path := level.map.get_enemy_path(0)
	var carrier := spawner.spawn(LARVE, path, 200.0, 1.0, 1.0, -1, null, Loot.Kind.GOLD)
	carrier.set_process(false)
	_check(carrier.carried == Loot.Kind.GOLD, "le porteur sait ce qu'il porte")
	carrier.take_damage(99999.0)
	await process_frame
	var drops := root.get_tree().get_nodes_in_group(Loot.GROUP)
	_check(drops.size() == 1, "il lâche son butin à sa mort")
	var loot := drops[0] as Loot
	var amount := maxi(Level.LOOT_MIN_GOLD, Level.LOOT_GOLD_PER_REWARD * level.get_enemy_reward(LARVE))
	_check(loot.kind == Loot.Kind.GOLD and loot.amount == amount, "un tas de %d or" % amount)
	var gold := level.gold
	await _click_at(level, loot.global_position + Vector2(8, 0))
	_check(level.gold == gold + amount and level.stats.loot_collected == 1, "un clic dessus le ramasse")
	await process_frame
	_check(root.get_tree().get_nodes_in_group(Loot.GROUP).is_empty(), "et il quitte la carte")
	var lost := level.drop_loot(Loot.Kind.GOLD, path.to_global(path.curve.sample_baked(300.0)), LARVE)
	lost._age = Loot.LIFETIME - 0.01
	await _step()
	await process_frame
	_check(not is_instance_valid(lost), "pas ramassé, il disparaît")
	# Coffres : sans pouvoirs ni Conquête, six bonus possibles, trois fois chacun.
	var tower := level.place_tower(Vector2i(2, 4), CANNON)
	var base_damage := tower.stats.damage
	var base_range := tower.stats.attack_range
	var wave_bonus := level.get_wave_bonus(0)
	var chests_before := Achievements.get_counter("chests_opened")
	var chest := level.drop_loot(Loot.Kind.CHEST, level.map.cell_to_world(Vector2i(6, 6)))
	level.collect_loot(chest)
	_check(level.stats.chests_opened == 1 and level.chest_levels.size() == 1, "un coffre ouvert donne un bonus")
	_check(level.hud.chest_panel != null and level.hud.chest_panel.visible, "affiché en haut de la carte")
	var opened: Array[StringName] = []
	for i in 17:
		opened.append(level.open_chest(Vector2.ZERO))
	_check(not opened.has(ChestBonus.POWERS) and not opened.has(ChestBonus.WORKERS),
		"ni Sablier sans pouvoir, ni Pioches hors de la Conquête")
	_check(Achievements.get_counter("chests_opened") == chests_before + 18, "les coffres ouverts comptent pour le succès")
	_check(level.chest_levels.values().all(func(count: int) -> bool: return count == 3) and level.chest_levels.size() == 6,
		"un même bonus retombe, trois fois au plus")
	_check(is_equal_approx(tower.stats.damage, base_damage * 1.3) and is_equal_approx(tower.stats.attack_range, base_range * 1.24),
		"Poudre noire et Lentilles polies : dégâts et portée des tours posées")
	level.gold = 5000
	var later: Tower = null
	for x in 20:
		for y in 10:
			if later == null and level.can_place_tower(Vector2i(x, y), CANNON):
				later = level.place_tower(Vector2i(x, y), CANNON)
	_check(later != null and is_equal_approx(later.stats.damage, base_damage * 1.3), "et des tours posées ensuite")
	_check(level.get_enemy_reward(LARVE) == roundi(LARVE.reward * 1.6), "Bourse du chasseur : or des monstres")
	_check(level.get_wave_bonus(0) == roundi(wave_bonus * 1.75), "Butin de guerre : bonus de vague")
	_check(is_equal_approx(level.get_interest_rate(), level.interest_rate + 0.06) and level.get_interest_cap() == level.interest_cap + 30,
		"Coffre-fort : intérêts et plafond")
	gold = level.gold
	Progress.set_value(Achievements.COUNTERS_SECTION, "chests_opened", 24)
	var was_unlocked := Achievements.is_unlocked("chasseur_de_tresors")
	_check(level.open_chest(Vector2.ZERO) == &"" and level.gold == gold + ChestBonus.FALLBACK_GOLD, "tout au maximum : de l'or")
	_check(level.hud._chest_label.text.contains("Poudre noire") and level.hud.achievement_toasts.get_child_count() > 0,
		"liste des bonus et bandeau du coffre")
	_check(not was_unlocked and Achievements.is_unlocked("chasseur_de_tresors"), "Chasseur de trésors au 25e coffre")
	await _free(level)

	level = await _spawn_level(CONQUEST_01)
	_check(level.spawner.loot_kinds.size() == 3, "Conquête : de l'or, de la pierre ou de l'essence")
	var stone := level.conquest.stone
	level.collect_loot(level.drop_loot(Loot.Kind.STONE, level.map.cell_to_world(Vector2i(6, 6))))
	var essence := level.conquest.essence
	level.collect_loot(level.drop_loot(Loot.Kind.ESSENCE, level.map.cell_to_world(Vector2i(6, 6))))
	_check(level.conquest.stone == stone + Level.LOOT_STONE and level.conquest.essence == essence + Level.LOOT_ESSENCE,
		"pierre et essence ramassées")
	_check(ChestBonus.get_available({}, false, true, true).has(ChestBonus.WORKERS), "Pioches d'acier possibles en Conquête")
	level.chest_levels[ChestBonus.WORKERS] = 2
	_check(is_equal_approx(level.conquest.get_work_speed(), 1.4), "et les ouvriers travaillent plus vite")
	await _free(level)

	level = await _spawn_level(TUTORIAL)
	_check(not level.spawner.carriers, "pas de porteurs dans le tutoriel")
	await _free(level)


## Mode Expédition : cinq niveaux tirés au sort à la suite, vies gardées, coffres au choix.
func _test_expedition() -> void:
	print("Mode Expédition")
	var campaign: Campaign = load("res://resources/campaign.tres")
	var pool := campaign.levels
	var drawn := Expedition.draw_levels(1234, pool)
	var indices := drawn.map(func(path: String) -> int: return pool.find(path))
	var tiers_ok := true
	for i in indices.size():
		tiers_ok = tiers_ok and indices[i] >= floori(float(i) * pool.size() / 5) \
			and indices[i] < floori(float(i + 1) * pool.size() / 5)
	_check(drawn.size() == Expedition.LEVEL_COUNT and tiers_ok, "cinq niveaux, un par tranche de la campagne : %s" % [indices])
	_check(Expedition.draw_levels(1234, pool) == drawn and Expedition.draw_levels(99, pool) != drawn,
		"le tirage dépend de la graine")
	_check(Expedition.is_unlocked() == (Unlocks.is_unlocked(Unlocks.Feature.EXPEDITION) and Expedition.get_pool().size() >= 5),
		"ouvert avec la progression de la campagne")
	var run := Expedition.from_dict(Expedition.create(77).to_dict())
	_check(run.rng_seed == 77 and run.index == 0 and run.lives == -1, "l'expédition passe d'une scène à l'autre en dictionnaire")
	var picked := Expedition.pick_choices(ChestBonus.get_available({}, false, true, false), RandomNumberGenerator.new())
	_check(picked.size() == 3 and picked[0] != picked[1] and picked[1] != picked[2] and picked[0] != picked[2],
		"un coffre propose trois bonus différents")

	# Deuxième étape : les vies et les bonus de la première sont repris.
	run = Expedition.new()
	run.rng_seed = 5
	run.levels.assign([LEVEL_02.resource_path, LEVEL_01.resource_path, LEVEL_03.resource_path,
		LEVEL_04.resource_path, LEVEL_05.resource_path])
	run.index = 1
	run.lives = 7
	run.max_lives = 25
	run.chest_levels = {ChestBonus.DAMAGE: 1}
	Engine.set_meta(Level.EXPEDITION_META, run.to_dict())
	var level := await _spawn_level(LEVEL_01)
	_check(level.expedition != null and not Engine.has_meta(Level.EXPEDITION_META), "le niveau lit l'expédition")
	_check(level.lives == 7 and level.starting_lives == 25, "les vies restantes passent à l'étape suivante")
	_check(level.get_title().begins_with("Expédition 2 / 5"), "le titre dit l'étape")
	_check(level.get_next_level() == LEVEL_03.resource_path, "le niveau suivant est l'étape suivante")
	var tower := level.place_tower(Vector2i(2, 4), CANNON)
	var boosted := tower.stats.damage
	level.chest_levels.clear()
	level.refresh_tower_bonuses(tower)
	_check(is_equal_approx(boosted, tower.stats.damage * 1.1), "les bonus des coffres déjà gagnés comptent tout de suite")
	level.chest_levels = run.chest_levels.duplicate()
	level.refresh_tower_bonuses(tower)
	_check(level.hud.chest_panel != null and level.hud.chest_panel.visible, "et s'affichent")
	level.collect_loot(level.drop_loot(Loot.Kind.CHEST, level.map.cell_to_world(Vector2i(6, 6))))
	var choice := level.hud.chest_choice
	_check(choice != null and choice.choices.size() == 3 and paused and level.chest_levels.size() == 1,
		"un coffre met la partie en pause et propose trois bonus")
	level.open_chest(Vector2.ZERO)
	_check(level.hud.chest_choice == choice, "un deuxième coffre attend son tour")
	var first := choice.choices[0]
	choice.get_buttons()[0].pressed.emit()
	_check(level.chest_levels.get(first, 0) == run.chest_levels.get(first, 0) + 1 and level.expedition.chest_levels == level.chest_levels,
		"le bonus choisi est gardé pour l'expédition")
	_check(level.hud.chest_choice != null and level.hud.chest_choice != choice and paused, "puis le deuxième coffre propose les siens")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_2
	key.pressed = true
	var second := level.hud.chest_choice.choices[1]
	level.hud.chest_choice._unhandled_key_input(key)
	_check(level.chest_levels.get(second, 0) >= 1 and level.hud.chest_choice == null and not paused,
		"la touche 2 prend le deuxième, et la partie reprend")
	level.lives = 5
	level._end_game(true)
	_check(level.expedition.lives == 5 and level.hud.end_title.text == "Étape réussie !"
		and level.hud.next_level_button.visible and not level.hud.get_node("%RestartButton").visible,
		"étape réussie : on passe à la suivante avec 5 vies")
	await _free(level)

	# Dernière étape perdue : l'expédition s'arrête et son record est gardé.
	run.index = 4
	run.lives = 3
	Engine.set_meta(Level.EXPEDITION_META, run.to_dict())
	var best := Expedition.get_best()
	level = await _spawn_level(LEVEL_05)
	level._end_game(false)
	_check(level.hud.end_title.text == "Expédition terminée" and not level.hud.next_level_button.visible
		and level.hud.get_node("%RestartButton").text == "Nouvelle expédition", "défaite : l'expédition est finie")
	_check(Expedition.get_best() == maxi(best, 4), "record : quatre étapes franchies")
	await _free(level)

	# Hors expédition, un coffre donne toujours un bonus au hasard, sans choix.
	level = await _spawn_level(LEVEL_01)
	_check(level.open_chest(Vector2.ZERO) != &"" and level.hud.chest_choice == null, "ailleurs, pas de choix")
	await _free(level)


func _test_elites() -> void:
	print("Élites")
	var elite := SCARABEE.make_elite()
	_check(elite.is_elite and elite.display_name == "Scarabée élite" and not SCARABEE.is_elite,
		"la version élite est une copie nommée « élite »")
	_check(is_equal_approx(elite.max_health, SCARABEE.max_health * 3.0) and elite.reward == SCARABEE.reward * 4
		and elite.damage == SCARABEE.damage + 2 and elite.radius > SCARABEE.radius, "vie x3, or x4, 2 vies de plus, plus gros")
	var sentinel := SENTINELLE.make_elite()
	_check(is_equal_approx(sentinel.max_shield, SENTINELLE.max_shield * 3.0), "le bouclier est aussi multiplié")
	_check(REINE.make_elite() == REINE, "un boss n'a pas de version élite")
	var campaign: Campaign = load("res://resources/campaign.tres")
	var missing := []
	for path in campaign.levels:
		var level: Level = load(path).instantiate()
		var elites := 0
		for wave in level.get_node("WaveSpawner").waves:
			for group in wave.groups:
				if group.elite:
					elites += group.count
		if elites == 0:
			missing.append(path.get_file())
		level.free()
	_check(missing.is_empty(), "chaque niveau a au moins un élite %s" % [missing])
	# Un élite apparaît avec la vie de la difficulté en plus de la sienne, et rapporte plus.
	Difficulty.set_current(Difficulty.DIFFICILE)
	var level := await _spawn_level(LEVEL_03)
	var group := SpawnGroup.new()
	group.enemy = SCARABEE
	group.elite = true
	var enemy := level.spawner.spawn(group.get_enemy(), level.map.get_enemy_path(0), 100.0,
		level.spawner.waves[0].health_multiplier)
	_check(enemy.data.is_elite and is_equal_approx(enemy.health.max_health, SCARABEE.max_health * 3.0 * 1.35),
		"vie d'un élite en Difficile : x3 puis +35 %% (%d)" % enemy.health.max_health)
	var gold := level.gold
	enemy.take_damage(100000.0, true)
	_check(level.gold == gold + level.get_enemy_reward(elite), "il rapporte l'or d'un élite")
	_check(level.hud.wave_preview_label.get_parsed_text().contains("ÉLITE") == level.spawner.waves[0].groups.any(
		func(g: SpawnGroup) -> bool: return g.elite), "l'aperçu de vague signale les élites")
	await _free(level)
	Difficulty.set_current(Difficulty.MOYEN)


func _test_bosses() -> void:
	print("Boss")
	var campaign: Campaign = load("res://resources/campaign.tres")
	for world in campaign.worlds:
		var boss_levels := []
		for i in world.levels.size():
			var level: Level = load(world.levels[i]).instantiate()
			var waves: Array[WaveData] = level.get_node("WaveSpawner").waves
			for wave in waves:
				if wave.groups.any(func(g: SpawnGroup) -> bool: return g.enemy.is_boss):
					boss_levels.append(i + 1)
					_check(wave == waves[-1] and wave.groups.filter(func(g: SpawnGroup) -> bool: return g.enemy.is_boss)
						.all(func(g: SpawnGroup) -> bool: return g.count == 1 and world.bosses.has(g.enemy)),
						"%s : le boss arrive seul, à la dernière vague" % level.level_name)
			level.free()
		_check(boss_levels == [3, 6, 7], "%s : un boss aux niveaux 3 et 6, et au niveau libre qui finit le monde (%s)"
			% [world.display_name, boss_levels])
	var level := await _spawn_level(LEVEL_03)
	var boss := level.spawner.spawn(REINE, level.map.get_enemy_path(0), 300.0)
	await process_frame
	_check(level.hud.boss_bar.visible and level.hud.boss_bar.get_boss() == boss, "la vie du boss s'affiche en haut")
	var before := get_nodes_in_group(Enemy.GROUP).size()
	var elapsed := 0.0
	while elapsed < REINE.summon_interval + 0.5:
		elapsed += await _step()
	var larvae := get_nodes_in_group(Enemy.GROUP).filter(func(e: Enemy) -> bool: return e.data == LARVE)
	_check(get_nodes_in_group(Enemy.GROUP).size() >= before + REINE.summon_count and larvae.size() >= REINE.summon_count
		and larvae.all(func(e: Enemy) -> bool: return e.progress < boss.progress),
		"la Reine pond %d Larves derrière elle" % REINE.summon_count)
	boss.take_damage(1000000.0, true)
	await process_frame
	_check(not level.hud.boss_bar.visible, "la barre disparaît avec le boss")
	await _free(level)
	_check(GENERAL.heal_amount > 0.0 and GENERAL.summon_enemy == SOLDAT, "le Général soigne et appelle des Soldats")


func _test_necropolis() -> void:
	print("La Nécropole : résurrection, Encensoir et Cloche funèbre")
	var level := await _spawn_level(UNDEAD_01)
	level.start_next_wave()
	level.spawner._queue.clear()
	level.spawner.is_spawning = false
	var knight := level.spawner.spawn(CHEVALIER, level.map.get_enemy_path(0), 200.0)
	var gold := level.gold
	knight.take_damage(100000.0, true)
	await process_frame
	_check(level.gold == gold and level._pending_revives == 1 and level._alive_enemy_count() == 1,
		"un Chevalier noir abattu ne rapporte rien tout de suite et va se relever")
	level._check_wave_cleared()
	_check(level.get_waves_cleared() == 0, "la vague n'est pas finie tant qu'il est au sol")
	var elapsed := 0.0
	while elapsed < CHEVALIER.revive_delay + 0.2:
		elapsed += await _step()
	var risen: Array = get_nodes_in_group(Enemy.GROUP).filter(func(e: Enemy) -> bool: return e.data == CHEVALIER)
	_check(risen.size() == 1 and risen[0].revives_left == 0 and level._pending_revives == 0
		and is_equal_approx(risen[0].health.health, risen[0].health.max_health * CHEVALIER.revive_health_ratio)
		and absf(risen[0].progress - 200.0) < 40.0, "il se relève sur place avec la moitié de sa vie")
	gold = level.gold
	risen[0].take_damage(100000.0, true)
	await process_frame
	_check(level.gold >= gold + level.get_enemy_reward(CHEVALIER) and level._pending_revives == 0 and level.get_waves_cleared() == 1,
		"la seconde fois, il meurt pour de bon, rapporte son or et la vague est finie")
	# Consacré par l'Encensoir : il ne se relève pas.
	knight = level.spawner.spawn(CHEVALIER, level.map.get_enemy_path(0), 200.0)
	knight.hit(1.0, CENSER.get_stats_at_level(1))
	_check(knight.is_consecrated() and not knight.can_revive(), "touché par l'Encensoir, il est consacré")
	knight.take_damage(100000.0, true)
	await process_frame
	_check(level._pending_revives == 0, "un ennemi consacré ne se relève pas")
	# Cloche funèbre : l'onde étourdit tout ce qui est à portée.
	var bell := _place_test_tower(level, BELL)
	var target := _add_enemy_at(level, SQUELETTE, bell.global_position + Vector2(40, 0))
	bell._attack(target)
	_check(target.get_speed() == 0.0 and target.is_slowed(), "la Cloche funèbre étourdit les ennemis à portée")
	await _free(level)
	_check(LICHE.is_boss and LICHE.summon_enemy == SQUELETTE and LICHE.revive_count == 1,
		"la Liche relève des Squelettes et se relève une fois")
	_check(CHEVALIER.get_abilities().any(func(a: String) -> bool: return a.begins_with("Se relève une fois")),
		"la fiche du monstre le dit")


func _test_detail_windows() -> void:
	print("Fenêtres de détail")
	var level := await _spawn_level(LEVEL_03)
	var hud := level.hud
	await process_frame
	hud.show_wave_details()
	_check(hud.wave_details.visible and hud.wave_details.get_text().contains("Vague 1")
		and hud.wave_details.get_text().contains("Larve") and hud.wave_details.get_text().contains("Vie 60"),
		"fenêtre de la prochaine vague : monstres et statistiques")
	_check(hud.wave_preview.mouse_filter == Control.MOUSE_FILTER_STOP, "elle s'ouvre au survol de l'aperçu")
	var enemy := _add_still_enemy(level, GENERAL, 0, 400.0)
	enemy.take_damage(100.0, true)
	hud.show_enemy_details(enemy)
	var text := hud.enemy_details.get_text()
	_check(hud.enemy_details.visible and text.contains("Le Général") and text.contains("BOSS")
		and text.contains("Vie :  %d / %d" % [GENERAL.max_health - 100, GENERAL.max_health]) and text.contains("Soigne"),
		"fenêtre du monstre sous la souris : nom, rang, vie restante, capacités")
	var play_area := hud.get_play_area()
	_check(play_area.grow(1.0).encloses(hud.enemy_details.get_global_rect()), "elle reste sur la carte")
	enemy.despawn()
	hud.show_enemy_details(enemy)
	_check(not hud.enemy_details.visible, "elle se ferme quand le monstre disparaît")
	await _free(level)
	var screen := await _spawn_world_select()
	var details: String = screen.get_level_details(LEVEL_03.resource_path)
	_check(details.contains("V7") and details.contains("BOSS") and details.contains("ÉLITE")
		and details.contains("Reine de la Ruche"), "sélection des mondes : vagues du niveau, élites et boss")
	screen.show_level_details(LEVEL_01.resource_path)
	_check(screen.level_details.visible and screen.level_details.get_text().contains("V5"),
		"la fenêtre s'ouvre à côté du bouton du niveau")
	screen.set_difficulty(Difficulty.CAUCHEMAR)
	_check(screen.get_level_details(LEVEL_03.resource_path) != details
		and screen.get_level_details(LEVEL_03.resource_path).contains("Cauchemar"), "elle suit la difficulté choisie")
	screen.set_difficulty(Difficulty.MOYEN)
	await _free(screen)


func _test_lexicon() -> void:
	print("Lexique")
	var screen := LEXICON_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	var towers: Array = screen.get_entry_buttons()
	var tower_files := Array(ResourceLoader.list_directory("res://resources/towers/")).filter(
		func(f: String) -> bool: return f.ends_with(".tres"))
	_check(towers.size() == tower_files.size() and screen.detail_text.get_parsed_text().contains("Prix"),
		"onglet Tours : les %d tours, la première affichée" % tower_files.size())
	towers[-1].pressed.emit()
	_check(screen.detail_text.get_parsed_text().contains("arbre des améliorations"),
		"une tour des mondes dit où la débloquer")
	screen.show_tab(1)
	var names: Array = screen.get_entry_buttons().map(func(b: Button) -> String: return b.text)
	_check(names.size() == 47 and names[0] == "Élites" and names[1] == "Porteurs et coffres" and names.any(func(n: String) -> bool: return n.contains("Béhémoth"))
			and names.has("Frelon") and names.has("Infiltré") and names.has("Banshee") and names.has("Tunnelier") and names.any(func(n: String) -> bool: return n.contains("Liche"))
			and names.has("Pillarde  ·  Conquête") and names.has("Chapardeuse  ·  Conquête"),
		"onglet Monstres : les élites, les porteurs, les 33 monstres (dont les volants, les furtifs, le Tunnelier et le Saboteur), les 4 boss, les 4 Pillards et les 4 Voleurs (%d)"
			% names.size())
	var raider_entry: Button = screen.get_entry_buttons().filter(func(b: Button) -> bool: return b.text.begins_with("Maraudeur"))[0]
	raider_entry.pressed.emit()
	_check(screen.detail_text.get_parsed_text().contains("Mode Conquête seulement"), "la fiche d'un Pillard dit qu'il est de la Conquête")
	var general: Button = screen.get_entry_buttons().filter(func(b: Button) -> bool: return b.text.contains("Général"))[0]
	general.pressed.emit()
	_check(screen.detail_text.get_parsed_text().contains("Soldats en renfort"), "la fiche d'un boss donne ses capacités")
	screen.show_tab(2)
	_check(screen.get_entry_buttons().size() == 4 and screen.detail_text.get_parsed_text().contains("Reine de la Ruche"),
		"onglet Mondes : un par monde, avec ses monstres et son boss")
	await _free(screen)


func _test_end_stats() -> void:
	print("Statistiques de fin de niveau")
	var level := await _spawn_level(LEVEL_03)
	var poison := _place_test_tower(level, PESTICIDE)
	poison.set_process(false)
	var still: EnemyData = SCARABEE.duplicate()
	still.speed = 0.0
	# Apparu par le WaveSpawner : le niveau suit ses dégâts.
	var target := level.spawner.spawn(still, level.map.get_enemy_path(0), 300.0)
	await process_frame
	poison._attack(target)
	var elapsed := 0.0
	while elapsed < 3.0:
		elapsed += await _step()
	var record: LevelStats.TowerRecord = level.stats.towers.get(poison.get_instance_id())
	_check(record != null and record.damage > 10.0 and is_equal_approx(record.damage, still.max_health - target.health.health),
		"le poison est compté à la tour qui l'a posé (%s)" % (record.damage if record else -1.0))
	await _free(level)

	level = await _spawn_level(LEVEL_01)
	level.gold = 5000
	_place_defense(level, [Vector2i(3, 3), Vector2i(5, 3), Vector2i(3, 6), Vector2i(5, 6),
			Vector2i(9, 2), Vector2i(11, 2), Vector2i(9, 6), Vector2i(11, 6),
			Vector2i(14, 2), Vector2i(16, 2), Vector2i(14, 7), Vector2i(16, 7)], [CANNON, GATLING])
	var sniper := level.place_tower(Vector2i(7, 4), SNIPER)
	level.upgrade_tower(sniper)
	# Dans un tableau : la tour vendue est libérée, et une lambda ne peut pas garder un objet libéré.
	var sold := [level.place_tower(Vector2i(13, 4), SNIPER)]
	var expected_spent := 6 * CANNON.get_cost() + 6 * GATLING.get_cost() + 2 * SNIPER.get_cost() + SNIPER.get_upgrade_cost(1)
	await _play_until_over(level, 300.0, false, func() -> void:
		if is_instance_valid(sold[0]) and sold[0].is_alive and level.spawner.current_wave >= 1:
			level.sell_tower(sold[0]))
	var stats := level.stats
	_check(level.is_over and level.lives > 0, "partie gagnée")
	_check(stats.towers_built == 14 and stats.upgrades_bought == 1 and stats.towers_sold == 1,
		"tours posées, améliorées et vendues comptées")
	_check(stats.gold_spent == expected_spent and stats.gold_spent_on_upgrades == SNIPER.get_upgrade_cost(1),
		"or dépensé : poses et améliorations (%d)" % stats.gold_spent)
	_check(stats.gold_earned > 0 and stats.kills > 20 and stats.lives_lost == level.starting_lives - level.lives,
		"or gagné, monstres détruits, vies perdues")
	var types := stats.get_types()
	var type_total := 0.0
	var type_kills := 0
	for type in types:
		type_total += type.damage
		type_kills += type.kills
	_check(types.size() == 3 and types[0].damage >= types[1].damage and types[1].damage >= types[2].damage,
		"un bilan par type de tour, du plus de dégâts au moins")
	_check(is_equal_approx(type_total, stats.get_total_damage()) and stats.get_total_damage() > 1000.0,
		"les dégâts de chaque tour s'additionnent (%d)" % stats.get_total_damage())
	_check(type_kills > stats.kills * 0.9 and type_kills <= stats.kills, "les destructions sont comptées aux tours")
	var best := stats.get_best_tower()
	_check(best != null and stats.towers.values().all(func(r: LevelStats.TowerRecord) -> bool: return r.damage <= best.damage),
		"meilleure tour : celle qui a fait le plus de dégâts")
	_check(stats.towers.values().filter(func(r: LevelStats.TowerRecord) -> bool: return r.sold).size() == 1,
		"la tour vendue garde ses statistiques")
	_check(stats.duration > 10.0, "durée de la partie (%s)" % LevelStats.format_duration(stats.duration))
	var end := level.hud.end_stats
	_check(end.visible and end.type_rows.size() == 3 and end.best_label.text.contains(best.data.display_name)
		and end.summary["Or dépensé"] == LevelStats.format_number(expected_spent),
		"l'écran de fin affiche les statistiques et la meilleure tour")
	_check(level.hud.end_panel.get_global_rect().grow(1.0).encloses(end.get_global_rect())
		and Rect2(Vector2.ZERO, Vector2(1280, 800)).encloses(level.hud.end_panel.get_global_rect()),
		"le panneau de fin tient à l'écran")
	_check(LevelStats.format_number(1234567) == "1 234 567" and LevelStats.format_duration(125.0) == "2:05",
		"nombres et durées lisibles")
	_check(not end.summary.has("Pierre récoltée"), "pas de lignes de Conquête dans une partie de la campagne")
	var conquest_stats := LevelStats.new()
	conquest_stats.conquest = true
	conquest_stats.stone_mined = 1250
	conquest_stats.workers_lost = 2
	var conquest_end := EndStats.new()
	conquest_end.setup(conquest_stats)
	_check(conquest_end.summary.get("Pierre récoltée") == "1 250" and conquest_end.summary.get("Ouvriers perdus") == "2"
		and conquest_end.summary.has("Essence récoltée") and conquest_end.summary.has("Bâtiments bâtis"),
		"mode Conquête : pierre, essence, bâtiments et ouvriers perdus en fin de partie")
	conquest_end.free()
	await _free(level)


func _test_achievements() -> void:
	print("Succès")
	# Progression à part : les succès débloqués par les autres tests ne comptent pas.
	var save_path := Progress.get_save_path()
	Engine.set_meta(Progress.SAVE_PATH_META, "user://test_achievements.cfg")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Progress.get_save_path()))
	Progress.clear_cache()
	var ids := Achievements.LIST.map(func(d: Dictionary) -> String: return d.id)
	_check(ids.size() >= 20 and ids.all(func(id: String) -> bool: return ids.count(id) == 1),
		"%d succès, chacun son identifiant" % ids.size())
	_check(Achievements.LIST.filter(func(d: Dictionary) -> bool: return d.has("boss"))
		.all(func(d: Dictionary) -> bool: return ResourceLoader.exists(d.boss) and load(d.boss).is_boss),
		"les succès de boss visent des boss")
	_check(Achievements.get_unlocked_count() == 0, "aucun succès au départ")

	var level := await _spawn_level(LEVEL_01)
	level.gold = 5000
	_place_defense(level, [Vector2i(3, 3), Vector2i(5, 3), Vector2i(3, 6), Vector2i(5, 6),
			Vector2i(9, 2), Vector2i(11, 2), Vector2i(9, 6), Vector2i(11, 6),
			Vector2i(14, 2), Vector2i(16, 2), Vector2i(14, 7), Vector2i(16, 7)], [CANNON])
	await _play_until_over(level, 600.0, true)
	_check(level.is_over and level.lives > 0, "partie gagnée avec des Canons seulement")
	var expected := ["premier_pas", "brut_de_pose", "monoculture", "tresor"]
	if level.lives == level.starting_lives:
		expected.append("sans_egratignure")
	_check(expected.all(func(id: String) -> bool: return Achievements.is_unlocked(id) and level.unlocked_achievements.has(id))
		and not Achievements.is_unlocked("minimaliste") and not Achievements.is_unlocked("cauchemar"),
		"victoire : Premier pas, Brut de pose, Monoculture, Trésor de guerre (%s)" % ", ".join(level.unlocked_achievements))
	_check(Achievements.get_counter("kills") == level.stats.kills, "les monstres détruits s'ajoutent au compteur")
	_check(level.hud.end_stats.achievements_label != null
		and level.hud.end_stats.achievements_label.text.contains("Premier\u00a0pas"), "l'écran de fin liste les succès débloqués")
	await _free(level)

	level = await _spawn_level(LEVEL_03)
	level.gold = 5000
	level.place_tower(Vector2i(4, 2), CANNON)
	var boss := level.spawner.spawn(REINE, level.map.get_enemy_path(0), 300.0)
	await process_frame
	boss.take_damage(1000000.0, true)
	await process_frame
	_check(Achievements.is_unlocked("regicide") and Achievements.is_unlocked("commando")
		and not Achievements.is_unlocked("demolition"), "vaincre la Reine avec une tour : Régicide et Commando")
	_check(level.hud.achievement_toasts.get_child_count() == 2, "un bandeau annonce chaque succès en jeu")
	for cell in [Vector2i(4, 4), Vector2i(2, 2), Vector2i(6, 6)]:
		level.place_tower(cell, CANNON)
	var behemoth := level.spawner.spawn(BEHEMOTH, level.map.get_enemy_path(0), 300.0)
	await process_frame
	behemoth.take_damage(1000000.0, true)
	await process_frame
	_check(Achievements.is_unlocked("demolition") and level.unlocked_achievements == ["regicide", "commando", "demolition"],
		"Démolition avec 4 tours, sans redébloquer Commando")
	await _free(level)

	var unlocked := Achievements.add_counters({kills = 5000})
	_check(unlocked == ["exterminateur"] and Achievements.add_counters({kills = 10}).is_empty(),
		"Exterminateur à 5000 monstres, une seule fois")
	_check(Achievements.get_progress(Achievements.get_definition("chasseur"))[1] == 50, "avancement des objectifs chiffrés")
	var campaign: Campaign = load("res://resources/campaign.tres")
	for path in campaign.worlds[0].levels:
		Progress.record_victory(path, 3)
	_check(Achievements.check_progress() == ["ruche"], "gagner tous les niveaux de La Ruche")

	var screen := ACHIEVEMENTS_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	var count := Achievements.get_unlocked_count()
	_check(screen.cards.size() == Achievements.LIST.size()
		and screen.counter_label.text == "%d / %d débloqués" % [count, Achievements.LIST.size()],
		"page des succès : une vignette par succès et le compte (%s)" % screen.counter_label.text)
	_check(screen.cards.all(func(c: Control) -> bool: return c.size.x > 300.0), "les vignettes se partagent la largeur")
	await _free(screen)
	var title := TITLE_SCREEN.instantiate()
	root.add_child(title)
	await process_frame
	_check(title.achievements_button.text == "Succès  ·  %d / %d" % [count, Achievements.LIST.size()],
		"le bouton Succès de l'écran titre donne le compte")
	await _free(title)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Progress.get_save_path()))
	Progress.clear_cache()
	Engine.set_meta(Progress.SAVE_PATH_META, save_path)


func _test_biome_tiles() -> void:
	print("Tuiles des biomes sur les cartes")
	var campaign: Campaign = load("res://resources/campaign.tres")
	_check(campaign.worlds.all(func(w: World) -> bool: return w.tileset != null), "chaque monde a ses tuiles")
	# Les tuiles ne servent qu'à l'ancienne vue de dessus.
	var level := await _spawn_level(LEVEL_02, false)
	var map := level.map
	_check(map.tileset == campaign.worlds[0].tileset, "la carte prend les tuiles de son monde")
	var ground: TileMapLayer = map.get_node("Sol")
	var details: TileMapLayer = map.get_node("Details")
	_check(ground.get_used_cells().size() == map.columns * map.rows, "tout le sol est pavé")
	var on_path := details.get_used_cells().filter(func(c: Vector2i) -> bool: return map.is_cell_on_path(c) or map.is_cell_blocked(c))
	_check(details.get_used_cells().size() > 10 and on_path.is_empty(),
		"des détails sur le sol libre, jamais sur le chemin (%d)" % details.get_used_cells().size())
	_check(not map._path_details.is_empty() and map._obstacles.size() == map.blocked_cells.size(),
		"des cailloux sur le chemin et un obstacle du biome par case bloquée")
	var first := _ground_tiles(ground)
	await _free(level)
	level = await _spawn_level(LEVEL_02, false)
	_check(_ground_tiles(level.map.get_node("Sol")) == first, "la même carte à chaque partie")
	await _free(level)
	level = await _spawn_level(MECHA_01)
	_check(level.map.tileset == campaign.worlds[1].tileset, "La Fonderie a les siennes")
	await _free(level)
	level = await _spawn_level(load(campaign.worlds[3].levels[0]))
	_check(level.map.tileset == campaign.worlds[3].tileset and campaign.worlds[3].tileset != campaign.worlds[2].tileset,
		"La Nécropole aussi")
	await _free(level)


func _test_relief() -> void:
	print("Vue de trois quarts")
	var level := await _spawn_level(LEVEL_01)
	var map := level.map
	_check(map.relief and Relief.enabled and level.y_sort_enabled and level.towers.y_sort_enabled,
		"la carte est en vue de trois quarts, triée en profondeur")
	var decor: Node2D = level.get_node("Decor")
	var trees := decor.get_children().filter(func(d: DecorItem) -> bool: return d.kind == DecorItem.Kind.TREE)
	_check(trees.size() > 20, "des arbres sur la carte (%d)" % trees.size())
	_check(map._decor_by_cell.keys().all(func(c: Vector2i) -> bool: return not map.is_cell_on_path(c)),
		"jamais de décor sur le chemin")
	var cell: Vector2i = map._decor_by_cell.keys()[0]
	var items: Array = map._decor_by_cell[cell]
	level.gold = 1000
	var tower := level.place_tower(cell, level.tower_types[0])
	await process_frame
	_check(tower != null and items.all(func(d: Variant) -> bool: return not is_instance_valid(d)),
		"poser une tour abat le décor de sa case")
	_check(tower.get_muzzle_offset().y < -30.0, "les tirs partent du haut de la tour, au-dessus du socle")
	await _free(level)
	var decors := {}
	for scene in [LEVEL_02, MECHA_01, HUMANOID_01, load("res://scenes/levels/undead_01.tscn")]:
		level = await _spawn_level(scene)
		var kinds := {}
		for item: DecorItem in level.get_node("Decor").get_children():
			kinds[item.kind] = true
		decors[BiomeTheme.biome_of(level.map.tileset)] = kinds
		await _free(level)
	_check(decors.keys().size() == 4 and (decors.mecha.has(DecorItem.Kind.CRATE) or decors.mecha.has(DecorItem.Kind.BARREL)),
		"la Fonderie a ses caisses et ses tonneaux")
	_check(decors.humanoid.has(DecorItem.Kind.HOUSE) and decors.undead.has(DecorItem.Kind.TOMB)
		and not decors.undead.has(DecorItem.Kind.HOUSE), "la Cité a ses maisons, la Nécropole ses tombes")
	level = await _spawn_level(LEVEL_02, false)
	_check(not Relief.enabled and not level.y_sort_enabled, "la vue de dessus reste possible (relief décoché)")
	await _free(level)


## Planches des monstres et des tours (SpriteCache) : sans affichage, rien n'est dessiné
## d'habitude ; on fait ici comme si le jeu était affiché.
func _test_sprite_cache() -> void:
	print("Planches des monstres et des tours")
	Relief.headless = false
	var level := await _spawn_level(LEVEL_01)
	var enemy := _add_still_enemy(level, SCARABEE, 0, 200.0)
	_check(Creature.get_sheet(SCARABEE) == null, "la planche d'un monstre n'est pas prête tout de suite")
	for i in SpriteCache.BAKE_FRAMES + 1:
		await process_frame
	var sheet := Creature.get_sheet(SCARABEE)
	_check(sheet != null and enemy.material == SpriteCache.get_material(), "puis le monstre la recopie")
	_check(sheet != null and Creature.get_sheet(SCARABEE.duplicate()) == sheet,
		"une copie du même monstre partage sa planche")
	_check(sheet != null and sheet.viewport.size.x <= SpriteCache.MAX_SHEET_WIDTH
		and sheet.origin.y / sheet.scale >= Creature.top_height(SCARABEE),
		"la planche tient sur un téléphone et le monstre y tient en entier")
	_check(Creature.walk_frame(0.0) == 0 and Creature.walk_frame(Creature.WALK_STEP * (Creature.WALK_FRAMES + 1) + 1.0) == 1,
		"la marche boucle sur ses images")
	var redraws := [0]
	enemy.draw.connect(func() -> void: redraws[0] += 1)
	enemy._set_heading(0.3)
	await process_frame
	_check(redraws[0] == 0, "un virage ne redessine pas le monstre")
	enemy._set_heading(PI)
	await process_frame
	_check(redraws[0] == 1, "il se redessine quand il se retourne")
	level.gold = 1000
	level.place_tower(Vector2i(5, 5), CANNON)
	await process_frame
	for i in SpriteCache.BAKE_FRAMES + 1:
		await process_frame
	_check(TowerRelief._get_base_sheet(CANNON, 0) != null, "le donjon d'une tour a sa planche")
	await _free(level)
	SpriteCache._instance.clear()
	Relief.headless = true


func _ground_tiles(layer: TileMapLayer) -> Array:
	var tiles := []
	for cell in layer.get_used_cells():
		tiles.append([cell, layer.get_cell_atlas_coords(cell)])
	tiles.sort()
	return tiles


func _test_beam_tower() -> void:
	print("Rayon : dégâts qui montent sur la même cible")
	var level := await _spawn_level(LEVEL_03)
	level.gold = 1000
	var tower: BeamTower = level.place_tower(Vector2i(4, 2), BEAM)
	_check(tower is BeamTower, "le Rayon vient de sa scène")
	var target_data: EnemyData = LARVE.duplicate()
	target_data.max_health = 1e9
	var enemy := _add_still_enemy(level, target_data, 0, 0.0)
	enemy.global_position = tower.global_position + Vector2(60, 0)
	var hits: Array[float] = []
	enemy.damaged.connect(func(_e: Enemy, amount: float) -> void: hits.append(amount))
	var elapsed := 0.0
	while elapsed < 3.0:
		elapsed += await _step()
	_check(hits.size() > 10, "le rayon frappe en continu (%d coups en 3 s)" % hits.size())
	_check(is_equal_approx(hits[0], BEAM.damage), "le premier coup fait les dégâts de base")
	_check(is_equal_approx(hits[hits.size() - 1], BEAM.damage * BEAM.beam_ramp_max),
		"après %s s, les coups font %s fois plus mal" % [BEAM.beam_ramp_time, BEAM.beam_ramp_max])
	# Changer de cible fait repartir de zéro.
	enemy.despawn()
	var other := _add_still_enemy(level, target_data, 0, 0.0)
	other.global_position = tower.global_position + Vector2(0, 60)
	var other_hits: Array[float] = []
	other.damaged.connect(func(_e: Enemy, amount: float) -> void: other_hits.append(amount))
	while other_hits.is_empty():
		await _step()
	_check(other_hits[0] < BEAM.damage * 1.2, "une nouvelle cible repart des dégâts de base")
	var scarabee := _add_still_enemy(level, SCARABEE, 0, 0.0)
	_check(is_equal_approx(scarabee.take_damage(BEAM.damage), 1.0), "l'armure du Scarabée absorbe un coup de base")
	await _free(level)


## Rejoue le niveau 3 sans or bonus, comme pour le niveau 2 : gagnable avec la
## défense complète, mais perdu avec seulement les 6 premières tours.
func _test_level_03_with_earned_gold() -> void:
	print("Niveau 3 : gagnable avec l'or gagné, mais pas avec une petite défense")
	await _check_build_order_balance(LEVEL_03, [
		[Vector2i(15, 2), CANNON], [Vector2i(15, 3), CANNON], [Vector2i(14, 2), MORTAR],
		[Vector2i(4, 5), BEAM], [Vector2i(17, 3), FROST], [Vector2i(5, 5), CANNON],
		[Vector2i(9, 3), SNIPER], [Vector2i(4, 6), MORTAR], [Vector2i(14, 3), BEAM],
		[Vector2i(9, 5), GATLING], [Vector2i(2, 5), FROST], [Vector2i(11, 2), SNIPER],
		[Vector2i(16, 6), MORTAR], [Vector2i(17, 4), BEAM], [Vector2i(2, 6), CANNON],
		[Vector2i(10, 5), MORTAR], [Vector2i(7, 5), SNIPER], [Vector2i(10, 2), BEAM],
	])


## Équilibrage d'un niveau : perdu avec les 6 premières tours de la liste, gagné
## avec toute la liste, en n'achetant qu'avec l'or gagné.
func _check_build_order_balance(scene: PackedScene, build_order: Array, upgrade := false) -> void:
	var small := await _play_build_order(scene, build_order, 6)
	_check(not small.won and small.lives == 0, "perdu avec 6 tours seulement")
	var full := await _play_build_order(scene, build_order, build_order.size(), 1500.0, upgrade)
	_check(full.won, "la partie est gagnée (vies restantes : %d, tours achetées : %d)" % [full.lives, full.bought])


func _test_levels_04_to_06_maps() -> void:
	print("Niveaux 4 à 6 : cartes")
	var expected := [
		[LEVEL_04, "Niveau 1-4", 1, 8, LEVEL_05], [LEVEL_05, "Niveau 1-5", 3, 8, LEVEL_06], [LEVEL_06, "Niveau 1-6", 1, 10, LEVEL_07],
	]
	for item: Array in expected:
		var level := await _spawn_level(item[0])
		var label: String = item[1]
		_check(level.level_name == label and level.tower_types.size() == 6, "%s : nom et 6 types de tours" % label)
		_check(level.map.paths.size() == item[2] and level.spawner.waves.size() == item[3],
			"%s : %d chemin(s) et %d vagues" % [label, item[2], item[3]])
		_check(level.get_next_level() == (item[4].resource_path if item[4] else ""),
			"%s : %s" % [label, "le niveau suivant est le bon" if item[4] else "c'est le dernier niveau"])
		var rocks_off_path := level.map.blocked_cells.all(func(cell: Vector2i) -> bool:
			return not level.map.is_cell_on_path(cell))
		_check(rocks_off_path, "%s : les rochers sont hors des chemins" % label)
		var used_paths := {}
		for wave in level.spawner.waves:
			for group in wave.groups:
				used_paths[group.path_index] = true
		_check(used_paths.size() == level.map.paths.size(), "%s : les vagues passent par tous les chemins" % label)
		if item[0] == LEVEL_04:
			# Le chemin se recoupe : la case du croisement est traversée deux fois.
			_check(_path_visits(level.map, 0, Vector2i(5, 3)) == 2, "Niveau 4 : le chemin se croise lui-même")
		elif item[0] == LEVEL_06:
			var curve := level.map.paths[0].curve
			var end_cell := level.map.world_to_cell(curve.get_point_position(curve.point_count - 1))
			_check(level.map.is_cell_in_grid(end_cell), "Niveau 6 : le chemin finit au centre de la carte, en spirale")
		await _free(level)


## Nombre de passages distincts d'un chemin sur une case.
func _path_visits(map: GameMap, path_index: int, cell: Vector2i) -> int:
	var path := map.paths[path_index]
	var visits := 0
	var inside := false
	for point in path.curve.get_baked_points():
		var now_inside := map.world_to_cell(path.to_global(point)) == cell
		if now_inside and not inside:
			visits += 1
		inside = now_inside
	return visits


func _test_levels_04_to_06_with_earned_gold() -> void:
	print("Niveau 4 : gagnable avec l'or gagné, mais pas avec une petite défense")
	await _check_build_order_balance(LEVEL_04, [
		[Vector2i(7, 2), CANNON], [Vector2i(6, 4), CANNON], [Vector2i(8, 2), MORTAR],
		[Vector2i(4, 2), BEAM], [Vector2i(9, 2), FROST], [Vector2i(4, 6), CANNON],
		[Vector2i(10, 2), SNIPER], [Vector2i(6, 5), MORTAR], [Vector2i(12, 2), BEAM],
		[Vector2i(13, 4), GATLING], [Vector2i(6, 6), FROST], [Vector2i(11, 2), SNIPER],
		[Vector2i(13, 7), MORTAR], [Vector2i(15, 2), BEAM], [Vector2i(6, 7), CANNON],
		[Vector2i(11, 4), MORTAR], [Vector2i(17, 2), SNIPER], [Vector2i(13, 2), BEAM],
	])
	print("Niveau 5 : gagnable avec l'or gagné, mais pas avec une petite défense")
	await _check_build_order_balance(LEVEL_05, [
		[Vector2i(8, 4), CANNON], [Vector2i(10, 4), CANNON], [Vector2i(10, 6), MORTAR],
		[Vector2i(8, 6), BEAM], [Vector2i(12, 4), FROST], [Vector2i(14, 3), CANNON],
		[Vector2i(12, 3), SNIPER], [Vector2i(16, 4), MORTAR], [Vector2i(7, 4), BEAM],
		[Vector2i(14, 4), GATLING], [Vector2i(10, 3), FROST], [Vector2i(16, 6), SNIPER],
		[Vector2i(12, 6), MORTAR], [Vector2i(16, 3), BEAM], [Vector2i(8, 3), CANNON],
		[Vector2i(10, 7), MORTAR], [Vector2i(18, 6), SNIPER], [Vector2i(14, 6), BEAM],
	])
	print("Niveau 6 : gagnable avec l'or gagné, mais pas avec une petite défense")
	await _check_build_order_balance(LEVEL_06, [
		[Vector2i(8, 2), CANNON], [Vector2i(9, 4), CANNON], [Vector2i(10, 5), MORTAR],
		[Vector2i(9, 7), BEAM], [Vector2i(6, 4), FROST], [Vector2i(11, 2), CANNON],
		[Vector2i(5, 5), SNIPER], [Vector2i(13, 5), MORTAR], [Vector2i(16, 5), BEAM],
		[Vector2i(11, 7), GATLING], [Vector2i(4, 4), FROST], [Vector2i(14, 2), SNIPER],
		[Vector2i(6, 7), MORTAR], [Vector2i(3, 4), BEAM], [Vector2i(16, 2), CANNON],
		[Vector2i(9, 5), MORTAR], [Vector2i(3, 7), SNIPER], [Vector2i(13, 4), BEAM],
	])


## Ordres de construction des mondes 2 à 4 pour l'équilibrage (18 tours par niveau).
const WORLD_BUILD_ORDERS := {
	"res://scenes/levels/mecha_01.tscn": [
		[Vector2i(15, 2), CANNON], [Vector2i(15, 3), CANNON], [Vector2i(4, 5), MORTAR],
		[Vector2i(4, 6), BEAM], [Vector2i(16, 2), FROST], [Vector2i(16, 3), CANNON],
		[Vector2i(3, 5), SNIPER], [Vector2i(3, 6), MORTAR], [Vector2i(3, 2), BEAM],
		[Vector2i(4, 2), GATLING], [Vector2i(5, 2), FROST], [Vector2i(6, 2), SNIPER],
		[Vector2i(7, 2), MORTAR], [Vector2i(8, 2), BEAM], [Vector2i(9, 2), CANNON],
		[Vector2i(10, 2), MORTAR], [Vector2i(11, 2), SNIPER], [Vector2i(12, 2), BEAM],
	],
	"res://scenes/levels/mecha_02.tscn": [
		[Vector2i(11, 5), CANNON], [Vector2i(12, 5), CANNON], [Vector2i(14, 5), MORTAR],
		[Vector2i(12, 6), BEAM], [Vector2i(14, 6), FROST], [Vector2i(15, 6), CANNON],
		[Vector2i(5, 3), SNIPER], [Vector2i(7, 3), MORTAR], [Vector2i(8, 3), BEAM],
		[Vector2i(15, 5), GATLING], [Vector2i(11, 6), FROST], [Vector2i(4, 3), SNIPER],
		[Vector2i(4, 2), MORTAR], [Vector2i(5, 2), BEAM], [Vector2i(7, 2), CANNON],
		[Vector2i(9, 3), MORTAR], [Vector2i(10, 3), SNIPER], [Vector2i(11, 3), BEAM],
	],
	"res://scenes/levels/mecha_03.tscn": [
		[Vector2i(10, 3), CANNON], [Vector2i(10, 4), CANNON], [Vector2i(9, 3), MORTAR],
		[Vector2i(11, 3), BEAM], [Vector2i(9, 4), FROST], [Vector2i(11, 4), CANNON],
		[Vector2i(4, 5), SNIPER], [Vector2i(7, 5), MORTAR], [Vector2i(13, 5), BEAM],
		[Vector2i(16, 5), GATLING], [Vector2i(18, 5), FROST], [Vector2i(4, 6), SNIPER],
		[Vector2i(5, 6), MORTAR], [Vector2i(6, 6), BEAM], [Vector2i(7, 6), CANNON],
		[Vector2i(13, 6), MORTAR], [Vector2i(14, 6), SNIPER], [Vector2i(15, 6), BEAM],
	],
	"res://scenes/levels/mecha_04.tscn": [
		[Vector2i(5, 3), CANNON], [Vector2i(6, 3), CANNON], [Vector2i(7, 3), MORTAR],
		[Vector2i(8, 3), BEAM], [Vector2i(15, 3), FROST], [Vector2i(16, 3), CANNON],
		[Vector2i(5, 4), SNIPER], [Vector2i(8, 4), MORTAR], [Vector2i(15, 4), BEAM],
		[Vector2i(3, 5), GATLING], [Vector2i(10, 5), FROST], [Vector2i(13, 5), SNIPER],
		[Vector2i(2, 6), MORTAR], [Vector2i(3, 6), BEAM], [Vector2i(10, 6), CANNON],
		[Vector2i(11, 6), MORTAR], [Vector2i(12, 6), SNIPER], [Vector2i(13, 6), BEAM],
	],
	"res://scenes/levels/mecha_05.tscn": [
		[Vector2i(5, 1), CANNON], [Vector2i(6, 1), CANNON], [Vector2i(8, 1), MORTAR],
		[Vector2i(9, 1), BEAM], [Vector2i(15, 5), FROST], [Vector2i(16, 5), CANNON],
		[Vector2i(3, 1), SNIPER], [Vector2i(7, 1), MORTAR], [Vector2i(11, 1), BEAM],
		[Vector2i(3, 3), GATLING], [Vector2i(5, 3), FROST], [Vector2i(9, 3), SNIPER],
		[Vector2i(11, 3), MORTAR], [Vector2i(12, 3), BEAM], [Vector2i(11, 4), CANNON],
		[Vector2i(13, 4), MORTAR], [Vector2i(15, 4), SNIPER], [Vector2i(12, 5), BEAM],
	],
	"res://scenes/levels/mecha_06.tscn": [
		[Vector2i(17, 3), CANNON], [Vector2i(16, 3), CANNON], [Vector2i(16, 2), MORTAR],
		[Vector2i(17, 2), BEAM], [Vector2i(17, 5), FROST], [Vector2i(17, 6), CANNON],
		[Vector2i(8, 2), SNIPER], [Vector2i(9, 2), MORTAR], [Vector2i(10, 2), BEAM],
		[Vector2i(7, 3), GATLING], [Vector2i(8, 3), FROST], [Vector2i(9, 3), SNIPER],
		[Vector2i(10, 3), MORTAR], [Vector2i(11, 3), BEAM], [Vector2i(2, 6), CANNON],
		[Vector2i(3, 6), MORTAR], [Vector2i(16, 6), SNIPER], [Vector2i(2, 2), BEAM],
	],
	"res://scenes/levels/humanoid_01.tscn": [
		[Vector2i(6, 2), CANNON], [Vector2i(7, 2), CANNON], [Vector2i(9, 2), MORTAR],
		[Vector2i(10, 2), BEAM], [Vector2i(4, 3), FROST], [Vector2i(6, 3), CANNON],
		[Vector2i(10, 3), SNIPER], [Vector2i(3, 4), MORTAR], [Vector2i(4, 4), BEAM],
		[Vector2i(17, 4), GATLING], [Vector2i(12, 5), FROST], [Vector2i(15, 5), SNIPER],
		[Vector2i(17, 5), MORTAR], [Vector2i(12, 6), BEAM], [Vector2i(13, 6), CANNON],
		[Vector2i(14, 6), MORTAR], [Vector2i(15, 6), SNIPER], [Vector2i(3, 3), BEAM],
	],
	"res://scenes/levels/humanoid_02.tscn": [
		[Vector2i(14, 6), CANNON], [Vector2i(14, 5), CANNON], [Vector2i(2, 2), MORTAR],
		[Vector2i(3, 2), BEAM], [Vector2i(5, 2), FROST], [Vector2i(6, 2), CANNON],
		[Vector2i(6, 4), SNIPER], [Vector2i(7, 4), MORTAR], [Vector2i(9, 4), BEAM],
		[Vector2i(10, 4), GATLING], [Vector2i(15, 5), FROST], [Vector2i(17, 5), SNIPER],
		[Vector2i(10, 6), MORTAR], [Vector2i(11, 6), BEAM], [Vector2i(13, 6), CANNON],
		[Vector2i(15, 6), MORTAR], [Vector2i(17, 6), SNIPER], [Vector2i(5, 1), BEAM],
	],
	"res://scenes/levels/humanoid_03.tscn": [
		[Vector2i(11, 5), CANNON], [Vector2i(11, 6), CANNON], [Vector2i(12, 5), MORTAR],
		[Vector2i(12, 6), BEAM], [Vector2i(14, 6), FROST], [Vector2i(14, 7), CANNON],
		[Vector2i(15, 7), SNIPER], [Vector2i(10, 5), MORTAR], [Vector2i(15, 6), BEAM],
		[Vector2i(10, 3), GATLING], [Vector2i(11, 3), FROST], [Vector2i(12, 3), SNIPER],
		[Vector2i(8, 5), MORTAR], [Vector2i(14, 5), BEAM], [Vector2i(10, 6), CANNON],
		[Vector2i(12, 7), MORTAR], [Vector2i(16, 7), SNIPER], [Vector2i(17, 7), BEAM],
	],
	"res://scenes/levels/humanoid_04.tscn": [
		[Vector2i(4, 2), CANNON], [Vector2i(4, 3), CANNON], [Vector2i(3, 3), MORTAR],
		[Vector2i(5, 3), BEAM], [Vector2i(12, 3), FROST], [Vector2i(13, 2), CANNON],
		[Vector2i(14, 2), SNIPER], [Vector2i(13, 3), MORTAR], [Vector2i(14, 3), BEAM],
		[Vector2i(3, 2), GATLING], [Vector2i(5, 2), FROST], [Vector2i(12, 2), SNIPER],
		[Vector2i(15, 2), MORTAR], [Vector2i(7, 3), BEAM], [Vector2i(10, 3), CANNON],
		[Vector2i(15, 3), MORTAR], [Vector2i(3, 5), SNIPER], [Vector2i(4, 5), BEAM],
	],
	"res://scenes/levels/humanoid_05.tscn": [
		[Vector2i(12, 4), CANNON], [Vector2i(13, 3), CANNON], [Vector2i(15, 3), MORTAR],
		[Vector2i(16, 3), BEAM], [Vector2i(13, 4), FROST], [Vector2i(15, 4), CANNON],
		[Vector2i(12, 3), SNIPER], [Vector2i(16, 4), MORTAR], [Vector2i(11, 6), BEAM],
		[Vector2i(13, 6), GATLING], [Vector2i(15, 1), FROST], [Vector2i(16, 1), SNIPER],
		[Vector2i(17, 1), MORTAR], [Vector2i(17, 3), BEAM], [Vector2i(11, 4), CANNON],
		[Vector2i(10, 6), MORTAR], [Vector2i(14, 6), SNIPER], [Vector2i(11, 7), BEAM],
	],
	"res://scenes/levels/humanoid_06.tscn": [
		[Vector2i(11, 6), CANNON], [Vector2i(12, 6), CANNON], [Vector2i(13, 6), MORTAR],
		[Vector2i(14, 6), BEAM], [Vector2i(15, 6), FROST], [Vector2i(16, 6), CANNON],
		[Vector2i(10, 6), SNIPER], [Vector2i(17, 6), MORTAR], [Vector2i(12, 8), BEAM],
		[Vector2i(11, 5), GATLING], [Vector2i(12, 5), FROST], [Vector2i(13, 5), SNIPER],
		[Vector2i(14, 5), MORTAR], [Vector2i(15, 5), BEAM], [Vector2i(16, 5), CANNON],
		[Vector2i(9, 6), MORTAR], [Vector2i(11, 8), SNIPER], [Vector2i(15, 2), BEAM],
	],
	"res://scenes/levels/undead_01.tscn": [
		[Vector2i(7, 3), CANNON], [Vector2i(9, 6), CANNON], [Vector2i(13, 6), MORTAR],
		[Vector2i(15, 3), BEAM], [Vector2i(6, 3), FROST], [Vector2i(7, 4), CANNON],
		[Vector2i(9, 5), SNIPER], [Vector2i(10, 6), MORTAR], [Vector2i(12, 6), BEAM],
		[Vector2i(13, 5), GATLING], [Vector2i(15, 4), FROST], [Vector2i(16, 3), SNIPER],
		[Vector2i(2, 1), MORTAR], [Vector2i(2, 3), BEAM], [Vector2i(3, 1), CANNON],
		[Vector2i(3, 3), MORTAR], [Vector2i(4, 1), SNIPER], [Vector2i(4, 3), BEAM],
	],
	"res://scenes/levels/undead_02.tscn": [
		[Vector2i(11, 6), CANNON], [Vector2i(12, 6), CANNON], [Vector2i(9, 6), MORTAR],
		[Vector2i(11, 4), BEAM], [Vector2i(9, 7), FROST], [Vector2i(12, 4), CANNON],
		[Vector2i(13, 4), SNIPER], [Vector2i(13, 6), MORTAR], [Vector2i(14, 4), BEAM],
		[Vector2i(14, 6), GATLING], [Vector2i(15, 4), FROST], [Vector2i(15, 6), SNIPER],
		[Vector2i(16, 4), MORTAR], [Vector2i(16, 6), BEAM], [Vector2i(17, 4), CANNON],
		[Vector2i(17, 6), MORTAR], [Vector2i(8, 6), SNIPER], [Vector2i(8, 7), BEAM],
	],
	"res://scenes/levels/undead_03.tscn": [
		[Vector2i(15, 6), CANNON], [Vector2i(4, 6), CANNON], [Vector2i(7, 6), MORTAR],
		[Vector2i(9, 3), BEAM], [Vector2i(12, 3), FROST], [Vector2i(14, 6), CANNON],
		[Vector2i(16, 5), SNIPER], [Vector2i(16, 6), MORTAR], [Vector2i(18, 6), BEAM],
		[Vector2i(14, 5), GATLING], [Vector2i(15, 5), FROST], [Vector2i(4, 5), SNIPER],
		[Vector2i(5, 6), MORTAR], [Vector2i(6, 6), BEAM], [Vector2i(7, 5), CANNON],
		[Vector2i(9, 4), MORTAR], [Vector2i(10, 3), SNIPER], [Vector2i(11, 3), BEAM],
	],
	"res://scenes/levels/undead_04.tscn": [
		[Vector2i(7, 3), CANNON], [Vector2i(5, 3), CANNON], [Vector2i(5, 5), MORTAR],
		[Vector2i(7, 2), BEAM], [Vector2i(7, 5), FROST], [Vector2i(7, 6), CANNON],
		[Vector2i(8, 2), SNIPER], [Vector2i(8, 3), MORTAR], [Vector2i(11, 6), BEAM],
		[Vector2i(7, 7), GATLING], [Vector2i(11, 3), FROST], [Vector2i(11, 5), SNIPER],
		[Vector2i(11, 7), MORTAR], [Vector2i(15, 2), BEAM], [Vector2i(17, 5), CANNON],
		[Vector2i(4, 5), MORTAR], [Vector2i(5, 2), SNIPER], [Vector2i(5, 6), BEAM],
	],
	"res://scenes/levels/undead_05.tscn": [
		[Vector2i(14, 4), CANNON], [Vector2i(13, 4), CANNON], [Vector2i(14, 5), MORTAR],
		[Vector2i(16, 5), BEAM], [Vector2i(17, 5), FROST], [Vector2i(16, 4), CANNON],
		[Vector2i(13, 5), SNIPER], [Vector2i(11, 4), MORTAR], [Vector2i(14, 2), BEAM],
		[Vector2i(16, 7), GATLING], [Vector2i(10, 4), FROST], [Vector2i(13, 2), SNIPER],
		[Vector2i(17, 4), MORTAR], [Vector2i(17, 7), BEAM], [Vector2i(14, 6), CANNON],
		[Vector2i(12, 2), MORTAR], [Vector2i(15, 7), SNIPER], [Vector2i(18, 5), BEAM],
	],
	"res://scenes/levels/undead_06.tscn": [
		[Vector2i(11, 5), CANNON], [Vector2i(12, 5), CANNON], [Vector2i(6, 7), MORTAR],
		[Vector2i(12, 3), BEAM], [Vector2i(7, 7), FROST], [Vector2i(10, 5), CANNON],
		[Vector2i(11, 3), SNIPER], [Vector2i(4, 7), MORTAR], [Vector2i(13, 3), BEAM],
		[Vector2i(12, 7), GATLING], [Vector2i(14, 5), FROST], [Vector2i(3, 7), SNIPER],
		[Vector2i(8, 7), MORTAR], [Vector2i(9, 5), BEAM], [Vector2i(9, 7), CANNON],
		[Vector2i(10, 3), MORTAR], [Vector2i(10, 7), SNIPER], [Vector2i(11, 7), BEAM],
	],
}


func _test_world_levels_maps() -> void:
	print("Mondes 2 à 4 : cartes")
	var campaign: Campaign = load("res://resources/campaign.tres")
	for w in [1, 2, 3]:
		var world := campaign.worlds[w]
		for i in world.levels.size():
			var path := world.levels[i]
			var level := await _spawn_level(load(path))
			var label := "Niveau %d-%d" % [w + 1, i + 1]
			_check(level.level_name == label and level.tower_types.size() == 6, "%s : nom et 6 types de tours" % label)
			var rocks_off_path := level.map.blocked_cells.all(func(cell: Vector2i) -> bool:
				return not level.map.is_cell_on_path(cell))
			var used_paths := {}
			for wave in level.spawner.waves:
				for group in wave.groups:
					used_paths[group.path_index] = true
			# Tous les chemins finissent au même endroit : la base.
			var ends := {}
			for enemy_path in level.map.paths:
				var curve := enemy_path.curve
				ends[curve.get_point_position(curve.point_count - 1)] = true
			_check(rocks_off_path and used_paths.size() == level.map.paths.size() and ends.size() == 1,
				"%s : %d chemin(s) qui mènent tous à la base, tous utilisés, rochers hors des chemins"
				% [label, level.map.paths.size()])
			await _free(level)


func _test_world_levels_balance() -> void:
	for path: String in WORLD_BUILD_ORDERS:
		var scene: PackedScene = load(path)
		var level: Level = scene.instantiate()
		print("%s : gagnable avec l'or gagné et l'arbre d'un joueur arrivé là (tours améliorées), mais pas avec une petite défense"
			% level.level_name)
		level.free()
		_grant_campaign_perks(path)
		await _check_build_order_balance(scene, WORLD_BUILD_ORDERS[path], true)
	Progress.reset_campaign()


## Améliorations d'un joueur qui a gagné en Moyen, avec 3 étoiles, les niveaux de la
## campagne avant `path`, et qui a acheté les moins chères d'abord.
func _grant_campaign_perks(path: String) -> void:
	Progress.reset_campaign()
	var campaign: Campaign = load("res://resources/campaign.tres")
	for i in campaign.levels.find(path):
		Progress.record_victory(campaign.levels[i], 3)
	# Un joueur de la campagne laisse de côté la page Logistique (bonus de la Conquête).
	var logistics := Perks.TREE.page_names.find("Logistique")
	while true:
		var cheapest: Perk = null
		for perk in Perks.TREE.perks:
			if not perk.paid_with_endless_stars and Perks.TREE.get_page(perk) != logistics and Perks.can_buy(perk) \
					and (cheapest == null or perk.cost < cheapest.cost):
				cheapest = perk
		if cheapest == null:
			return
		Perks.buy(cheapest)


func _test_level_editor() -> void:
	print("Éditeur de niveau")
	# Tracé du chemin.
	_check(CustomLevel.extend_path([], Vector2i(5, 5)).is_empty(), "le chemin ne part pas du milieu de la carte")
	var path := CustomLevel.extend_path([], Vector2i(0, 3))
	path = CustomLevel.extend_path(path, Vector2i(1, 3))
	path = CustomLevel.extend_path(path, Vector2i(4, 3))
	_check(path == [Vector2i(0, 3), Vector2i(4, 3)], "une case dans le prolongement rallonge la ligne droite (%s)" % [path])
	path = CustomLevel.extend_path(path, Vector2i(7, 6))
	_check(path == [Vector2i(0, 3), Vector2i(7, 3), Vector2i(7, 6)], "une case pas alignée passe par un coin (%s)" % [path])
	_check(CustomLevel.expand_path(path).size() == 11, "le chemin traverse 11 cases")
	_check(CustomLevel.extend_path(path, Vector2i(7, 1)) == path, "le chemin ne revient pas sur lui-même")
	_check(CustomLevel.extend_path(path, Vector2i(2, 3)) == [Vector2i(0, 3), Vector2i(2, 3)],
		"cliquer sur le chemin le coupe là")
	var points := CustomLevel.get_path_points(path)
	_check(points[0] == Vector2(-32, 288) and points.size() == 4, "les ennemis arrivent du bord de l'écran (%s)" % [points])
	var edge_path := CustomLevel.extend_path(CustomLevel.extend_path([Vector2i(5, 0)], Vector2i(5, 9)), Vector2i(19, 9))
	_check(CustomLevel.get_path_points(edge_path)[-1].x > CustomLevel.COLUMNS * CustomLevel.CELL_SIZE,
		"un chemin qui finit au bord sort de l'écran")

	# Vérification.
	var data := CustomLevel.create_default()
	_check(CustomLevel.validate(data).is_empty(), "le niveau par défaut est jouable")
	var broken := data.duplicate(true)
	broken.path = [Vector2i(0, 2)]
	_check(not CustomLevel.validate(broken).is_empty(), "un chemin d'une case ne se joue pas")
	broken = data.duplicate(true)
	broken.waves = []
	_check(CustomLevel.validate(broken) == "Ajoutez au moins une vague.", "un niveau sans vague ne se joue pas")
	var waves := CustomLevel.build_waves(data)
	_check(waves.size() == 3 and waves[2].groups[1].enemy.is_boss and waves[2].groups[1].count == 1
		and waves[1].groups[1].start_delay == CustomLevel.GROUP_DELAY and waves[2].bonus_gold == 0,
		"les vagues se construisent (un seul boss, groupes décalés, pas de bonus à la dernière)")

	# L'écran de l'éditeur.
	# L'ancien réglage (un seul niveau) devient le premier de la liste.
	Progress.set_setting(CustomLevel.LEVELS_SETTING, null)
	Progress.set_setting(CustomLevel.CURRENT_SETTING, 0)
	var legacy := data.duplicate(true)
	legacy.erase("name")
	legacy.gold = 777
	Progress.set_setting(CustomLevel.LEGACY_SETTING, legacy)
	var migrated := CustomLevel.load_all()
	_check(migrated.size() == 1 and migrated[0].gold == 777 and migrated[0].name == CustomLevel.LEVEL_NAME,
		"le niveau de l'ancien éditeur est repris dans la liste")
	Progress.set_setting(CustomLevel.LEGACY_SETTING, {})
	Progress.set_setting(CustomLevel.LEVELS_SETTING, [])
	var editor: LevelEditor = load("res://scenes/ui/level_editor.tscn").instantiate()
	root.add_child(editor)
	await process_frame
	_check(editor.data.path == data.path and not editor.play_button.disabled, "l'éditeur ouvre le niveau par défaut")
	editor._on_clear_pressed()
	_check(editor.data.path.is_empty() and editor.play_button.disabled
		and editor.status_label.text.begins_with("Tracez le chemin"), "sans chemin, Jouer est grisé et le bas de l'écran dit pourquoi")
	editor.click_cell(Vector2i(0, 5))
	editor.drag_cell(Vector2i(1, 5))
	editor.drag_cell(Vector2i(2, 5))
	editor.click_cell(Vector2i(10, 2))
	editor.click_cell(Vector2i(19, 2))
	_check(editor.data.path == [Vector2i(0, 5), Vector2i(10, 5), Vector2i(10, 2), Vector2i(19, 2)],
		"le chemin se trace en cliquant et en glissant (%s)" % [editor.data.path])
	editor.undo_path()
	_check(editor.data.path[-1] == Vector2i(18, 2), "clic droit : le chemin recule d'une case")
	editor.set_tool(LevelEditor.EditTool.ROCKS)
	editor.click_cell(Vector2i(4, 4))
	editor.click_cell(Vector2i(4, 5))
	_check(editor.data.rocks.has(Vector2i(4, 4)) and not editor.data.rocks.has(Vector2i(4, 5)),
		"un rocher se pose à côté du chemin, pas dessus")
	var wave_count: int = editor.data.waves.size()
	editor.add_wave()
	_check(editor.data.waves.size() == wave_count + 1
		and editor.data.waves[-1].groups[0].count > editor.data.waves[-2].groups[0].count,
		"une vague ajoutée reprend la précédente, avec plus de monstres")
	editor.add_group(0)
	editor.remove_wave(editor.data.waves.size() - 1)
	_check(editor.data.waves.size() == wave_count and editor.data.waves[0].groups.size() == 2, "groupes et vagues s'ajoutent et s'enlèvent")
	editor.data.gold = 5000

	# Plusieurs niveaux.
	editor.show_tab(LevelEditor.Tab.LEVELS)
	_check(editor.levels_view.visible and not editor.map_view.visible and editor.levels_list.get_child_count() == 1,
		"l'onglet Niveaux liste les niveaux")
	var first: Dictionary = editor.data
	editor.rename_level("  Mon labyrinthe  ")
	_check(first.name == "Mon labyrinthe", "le niveau se renomme (%s)" % first.name)
	_check(editor.new_level() and editor.levels.size() == 2 and editor.current == 1 and editor.map_view.visible
		and editor.data.path == data.path and editor.data.name == CustomLevel.LEVEL_NAME,
		"un nouveau niveau s'ouvre sur la carte, avec le chemin de départ")
	editor.duplicate_level(0)
	_check(editor.levels.size() == 3 and editor.current == 2 and editor.data.name == "Copie de Mon labyrinthe"
		and editor.data.path == first.path, "un niveau se duplique")
	var first_size: int = first.path.size()
	editor.data.path.append(Vector2i(19, 9))
	_check(first.path.size() == first_size, "la copie ne touche pas l'original")
	editor.rename_level("Mon labyrinthe")
	_check(editor.data.name == "Mon labyrinthe (2)", "deux niveaux n'ont pas le même nom (%s)" % editor.data.name)
	editor.show_tab(LevelEditor.Tab.LEVELS)
	editor.delete_level(1)
	_check(editor.levels.size() == 3, "supprimer demande une confirmation")
	editor.delete_level(1)
	_check(editor.levels.size() == 2 and editor.current == 1 and editor.data.name == "Mon labyrinthe (2)"
		and editor.levels_list.get_child_count() == 2, "le niveau est supprimé et l'ouvert reste ouvert")
	editor.open_level(0)
	_check(editor.data == first and editor.name_edit.text == "Mon labyrinthe", "un niveau de la liste s'ouvre")

	# Partage par code.
	var code := editor.copy_code(0)
	_check(code.begins_with(CustomLevel.CODE_PREFIX) and code.length() < 600, "le code de partage est court (%d)" % code.length())
	var decoded := CustomLevel.decode(code)
	_check(decoded.path == first.path and decoded.rocks == first.rocks and decoded.waves == first.waves
		and decoded.gold == CustomLevel.MAX_GOLD and decoded.name == first.name and decoded.biome == first.biome,
		"le code redonne le même niveau")
	_check(CustomLevel.decode(" " + code.insert(20, "\n") + " ").path == first.path, "les blancs collés avec le code sont ignorés")
	_check(CustomLevel.decode(code.left(code.length() - 8)).is_empty() and CustomLevel.decode("bonjour").is_empty()
		and CustomLevel.decode(CustomLevel.CODE_PREFIX + "AAAA").is_empty(), "un code abîmé est refusé")
	var sneaky := {n = "x", b = 0, g = 100, l = 5, p = [0, 2, 5, 2], r = [], w = [[["../towers/cannon", 3, 0]]]}
	var sneaky_code := CustomLevel.CODE_PREFIX + Marshalls.raw_to_base64(JSON.stringify(sneaky).to_utf8_buffer()
		.compress(FileAccess.COMPRESSION_DEFLATE)).replace("+", "-").replace("/", "_")
	_check(CustomLevel.decode(sneaky_code).is_empty(), "un code ne charge que des monstres de l'éditeur")
	sneaky.w = [[["mecha/drone", 99999, 1]]]
	sneaky.g = -5
	sneaky_code = CustomLevel.CODE_PREFIX + Marshalls.raw_to_base64(JSON.stringify(sneaky).to_utf8_buffer()
		.compress(FileAccess.COMPRESSION_DEFLATE))
	var clamped := CustomLevel.decode(sneaky_code)
	_check(clamped.gold == CustomLevel.MIN_GOLD and clamped.waves[0].groups[0].count == CustomLevel.MAX_COUNT
		and clamped.waves[0].groups[0].elite, "les nombres d'un code sont bornés")
	_check(not editor.import_code("n'importe quoi") and editor.levels.size() == 2
		and editor.status_label.text.begins_with("Ce code"), "un mauvais code est refusé, le bas de l'écran le dit")
	_check(editor.import_code(code) and editor.levels.size() == 3 and editor.current == 2
		and editor.data.name == "Mon labyrinthe (3)" and editor.data.path == first.path, "un code s'importe comme nouveau niveau")
	editor.open_level(0)
	await _free(editor)
	var saved := CustomLevel.load_all()
	_check(saved.size() == 3 and CustomLevel.load_current_index(saved.size()) == 0 and saved[0].path[0] == Vector2i(0, 5)
		and saved[0].rocks.has(Vector2i(4, 4)) and saved[2].name == "Mon labyrinthe (3)", "les niveaux sont enregistrés")

	# Jouer le niveau.
	var stars_before := Progress.get_total_stars(Level.EMPTY_LEVEL)
	var achievements_before := Achievements.get_unlocked_count()
	data.gold = 2000
	Engine.set_meta(Level.CUSTOM_META, data)
	var level := await _spawn_level(load(Level.EMPTY_LEVEL))
	_check(level.custom_level == data and not Engine.has_meta(Level.CUSTOM_META), "le niveau lit le niveau de l'éditeur")
	_check(level.map.paths.size() == 1 and level.map.is_cell_on_path(Vector2i(8, 5))
		and level.map.is_cell_blocked(Vector2i(3, 5)) and level.spawner.get_wave_count() == 3,
		"la carte a son chemin, ses rochers et ses vagues")
	_check(level.gold == level.starting_gold and level.starting_gold >= 2000 and level.level_name == CustomLevel.LEVEL_NAME,
		"or de départ et nom du niveau")
	_check(level.map.tileset != null and not level.has_next_level(), "tuiles du monde choisi, pas de niveau suivant")
	_check(level.hud.get_node("%MenuButton").text == "Retour à l'éditeur", "la fin de partie ramène à l'éditeur")
	if level.is_choosing_towers:
		level.choose_towers(level.available_tower_types.slice(0, level.tower_limit))
	_place_defense(level, [Vector2i(4, 1), Vector2i(4, 3), Vector2i(7, 4), Vector2i(9, 4), Vector2i(9, 6),
		Vector2i(11, 6), Vector2i(13, 6), Vector2i(14, 5), Vector2i(16, 4), Vector2i(16, 2)], [CANNON])
	await _play_until_over(level, 400.0)
	_check(level.is_over and level.lives > 0, "le niveau se joue jusqu'à la victoire")
	_check(Progress.get_total_stars(Level.EMPTY_LEVEL) == stars_before
		and Achievements.get_unlocked_count() == achievements_before,
		"ni étoiles ni succès dans un niveau de l'éditeur")
	await _free(level)


func _test_conquest() -> void:
	print("Mode Conquête : pierre, ouvriers et chantiers")
	var level := await _spawn_level(CONQUEST_01)
	var conquest := level.conquest
	_check(conquest != null and conquest.stone == level.conquest_starting_stone and conquest.essence == 0
		and conquest.get_workers().size() == level.conquest_starting_workers and level.stats.conquest,
		"pierre et ouvriers de départ")
	_check(level.hud.stone_label.text == "Pierre : %d" % level.conquest_starting_stone
		and level.hud.essence_label.text == "Essence : 0"
		and level.hud.workers_label.text == "Ouvriers : 3 / %d" % Conquest.BASE_WORKERS,
		"la barre du haut montre la pierre, l'essence et les ouvriers")
	_check(level.counts_achievements() and level.get_next_level() == ConquestLevels.LEVELS[1],
		"les succès comptent, et le niveau suivant est celui de la Conquête")
	var rock := Vector2i(17, 6)
	_check(conquest.has_stone(rock) and not level.map.is_cell_buildable(rock), "les rochers de la carte sont des gisements")
	_check(Conquest.stone_cost(CANNON) == 20 and Conquest.stone_cost(SNIPER) == 48, "les tours coûtent aussi de la pierre")
	_check(level.hud.tower_shop.get_child(0).get_child(0).get_child(2).text == "50 or · 20 p",
		"la barre d'achat affiche le prix en pierre")
	_check(level.place_tower(Vector2i(16, 4), SNIPER) == null and level.gold == 150,
		"pas de tour sans assez de pierre, même avec l'or")
	var tower := level.place_tower(Vector2i(16, 7), CANNON)
	_check(tower != null and not tower.is_built() and conquest.stone == 20 and level.gold == 100,
		"une tour posée est un chantier, payé en or et en pierre")
	_check(not level.can_upgrade_tower(tower) and not tower.is_processing(), "un chantier ne tire pas et ne s'améliore pas")
	var elapsed := 0.0
	while not tower.is_built() and elapsed < 20.0:
		elapsed += await _step()
	await _step()
	var builders := conquest.get_workers().filter(func(worker: Worker) -> bool: return worker.site == tower).size()
	_check(tower.is_built() and tower.is_processing() and elapsed < Conquest.tower_build_time(CANNON),
		"deux ouvriers bâtissent la tour plus vite qu'un seul (%.1f s)" % elapsed)
	_check(level.can_upgrade_tower(tower) or level.gold < tower.get_upgrade_cost(), "la tour bâtie peut s'améliorer")
	_check(builders == 0, "les bâtisseurs retournent à la mine")
	var stone_before := conquest.stone
	elapsed = 0.0
	while conquest.stone <= stone_before and elapsed < 30.0:
		elapsed += await _step()
	_check(conquest.stone > stone_before and conquest.stone_mined > 0, "les ouvriers rapportent la pierre au QG")
	_check(conquest.rocks.values().any(func(left: int) -> bool: return left < Conquest.ROCK_STONE),
		"la pierre est prise dans un rocher")
	_check(conquest.set_preferred_rock(Vector2i(12, 3)) and not conquest.set_preferred_rock(Vector2i(16, 4)),
		"on désigne un rocher, pas une case vide")
	_check(conquest.get_workers().filter(func(worker: Worker) -> bool: return worker.is_mining()) \
		.all(func(worker: Worker) -> bool: return worker.rock_cell == Vector2i(12, 3)), "les mineurs vont au rocher désigné")
	conquest.rocks[rock] = 2
	_check(conquest.take_stone(rock, 3) == 2 and not conquest.has_stone(rock) and level.map.is_cell_buildable(rock),
		"un rocher vidé disparaît et libère sa case")
	level.gold = 100
	var recruit := conquest.recruit()
	_check(recruit != null and level.gold == 100 - Conquest.WORKER_COST and conquest.get_workers().size() == 4,
		"recruter un ouvrier coûte de l'or")
	_check(level.hud.workers_label.text == "Ouvriers : 4 / %d" % Conquest.BASE_WORKERS, "le compte des ouvriers suit")
	conquest.stone = 50
	var stone_now := conquest.stone
	var site := level.place_tower(Vector2i(14, 7), CANNON)
	_check(level.sell_tower(site) == CANNON.get_cost() and conquest.stone == stone_now,
		"un chantier vendu rend tout son or et toute sa pierre")
	# Un monstre au sol blesse l'ouvrier qui se trouve sur son passage.
	var enemy := _add_still_enemy(level, LARVE, 0, 700.0)
	elapsed = 0.0
	while is_instance_valid(recruit) and recruit.is_alive and elapsed < 5.0:
		recruit.global_position = enemy.global_position
		elapsed += await _step()
	_check(not is_instance_valid(recruit) and conquest.workers_lost == 1 and conquest.get_workers().size() == 3,
		"un ouvrier touché par un monstre finit par tomber")
	enemy.despawn()
	_check(conquest.wave_countdown > 0.0 and level.hud.next_wave_button.text.begins_with("Vague dans"),
		"le compte à rebours de la première vague s'affiche")
	conquest.wave_countdown = 0.01
	await _step()
	_check(level.spawner.current_wave == 0 and conquest.wave_countdown < 0.0
		and level.hud.next_wave_button.text == "Lancer la vague", "la vague part seule à la fin du compte à rebours")
	await _free(level)


## Tutoriel : la toute première partie de la campagne, ses étapes qui avancent avec ce que
## fait le joueur, et sa victoire qui ouvre le niveau 1-1.
func _test_tutorial() -> void:
	print("Tutoriel")
	Progress.set_setting(Tutorial.DONE_SETTING, false)
	var title := TITLE_SCREEN.instantiate()
	root.add_child(title)
	await process_frame
	var any_stars := Perks.get_earned_stars() > 0
	_check(title.get_node("%TutorialButton").text.begins_with("Tutoriel"), "le bouton Tutoriel existe")
	_check(title.get_campaign_start() == (Progress.get_next_to_play(Perks.CAMPAIGN) if any_stars
		else Tutorial.LEVEL_PATH), "Campagne commence par le tutoriel s'il n'y a encore rien de gagné")
	await _free(title)
	var level := await _spawn_level(TUTORIAL)
	var tutorial := level.tutorial
	_check(tutorial != null and tutorial.bubble.visible and tutorial.current == 0, "la bulle du tutoriel s'ouvre")
	_check(level.tower_types.size() == 3 and not level.is_choosing_towers and level.powers.is_empty()
		and level.difficulty == Difficulty.MOYEN and not level.counts_achievements(),
		"trois tours, pas de choix des tours, pas d'arbre, en Moyen et sans succès")
	tutorial.next_step()
	_check(tutorial.current == 1, "Suivant passe à l'étape suivante")
	level.select_tower(CANNON)
	await process_frame
	_check(tutorial.current == 2, "choisir le Canon passe à sa pose")
	level.select_tower(null)
	await process_frame
	_check(tutorial.current == 1, "le reposer revient au choix du Canon")
	level.place_tower(Tutorial.CANNON_CELL, CANNON)
	await process_frame
	_check(tutorial.current == 3, "le Canon posé, la bulle montre la barre du haut")
	tutorial.next_step()
	await process_frame
	_check(tutorial.current == 4, "puis le bouton de vague")
	level.start_next_wave()
	await process_frame
	_check(tutorial.current == 5, "la vague lancée, la bulle parle de l'or")
	var elapsed := 0.0
	while level.get_waves_cleared() < 1 and elapsed < 120.0:
		elapsed += await _step()
	await process_frame
	_check(tutorial.current == 6 and level.lives == level.starting_lives, "la vague 1 repoussée, place aux intérêts (étape %d, %d vies)" % [tutorial.current, level.lives])
	tutorial.next_step()
	await process_frame
	level.inspect_tower(level.get_towers()[0])
	await process_frame
	_check(tutorial.current == 8, "la fiche ouverte, la bulle propose l'amélioration")
	level.upgrade_tower(level.get_towers()[0])
	await process_frame
	_check(tutorial.current == 9, "puis la cible et la vente")
	tutorial.next_step()
	level.inspect_tower(null)
	await process_frame
	_check(tutorial.current == 10, "puis les volants")
	_check(level.place_tower(Tutorial.GATLING_CELL, GATLING) != null, "assez d'or pour la Mitrailleuse (%d)" % level.gold)
	level.start_next_wave()
	await process_frame
	_check(tutorial.current == 12, "la vague 2 lancée, la bulle montre la pause et la vitesse")
	elapsed = 0.0
	while level.get_waves_cleared() < 2 and elapsed < 120.0:
		elapsed += await _step()
	await process_frame
	_check(tutorial.current == 13, "puis les furtifs (%d vies)" % level.lives)
	_check(level.place_tower(Tutorial.SNIPER_CELL, SNIPER) != null, "assez d'or pour le Sniper (%d)" % level.gold)
	level.start_next_wave()
	elapsed = 0.0
	while level.get_waves_cleared() < 3 and elapsed < 120.0:
		elapsed += await _step()
	await process_frame
	_check(tutorial.current == 16 and level.powers.has(FREEZE_POWER), "avant la dernière vague, le Gel est prêté (%d vies, %d or)" % [level.lives, level.gold])
	# Comme le conseille la bulle, l'or restant passe en améliorations.
	for tower in level.get_towers():
		level.upgrade_tower(tower)
	level.start_next_wave()
	await process_frame
	_check(tutorial.current == 17, "la vague lancée, la bulle demande le Gel")
	elapsed = 0.0
	while get_nodes_in_group(Enemy.GROUP).size() < 6 and elapsed < 30.0:
		elapsed += await _step()
	level.select_power(FREEZE_POWER)
	await process_frame
	_check(tutorial.current == 18, "le Gel lancé, il ne reste qu'à tenir")
	await _play_until_over(level, 300.0)
	_check(level.is_over and level.lives > 0, "le tutoriel suivi à la lettre se gagne (%d vies)" % level.lives)
	_check(Tutorial.is_done() and not tutorial.bubble.visible, "le tutoriel gagné est noté comme fini")
	_check(level.get_next_level() == Perks.CAMPAIGN.levels[0] and level.hud.next_level_button.visible
		and level.hud.next_level_button.text == "Commencer la campagne", "il ouvre le niveau 1-1")
	_check(Progress.get_total_stars(TUTORIAL.resource_path) == 0, "il ne rapporte pas d'étoiles")
	await _free(level)
	_check(not Engine.has_meta(Perks.DISABLED_META), "l'arbre compte de nouveau après le tutoriel")
	title = TITLE_SCREEN.instantiate()
	root.add_child(title)
	await process_frame
	_check(title.get_campaign_start() != Tutorial.LEVEL_PATH and title.get_node("%TutorialButton").text == "Tutoriel",
		"une fois fini, le tutoriel n'est plus imposé ni conseillé")
	await _free(title)


func _test_conquest_victory() -> void:
	print("Mode Conquête : partie complète")
	var level := await _spawn_level(CONQUEST_01)
	var conquest := level.conquest
	var build_order := [[Vector2i(14, 4), CANNON], [Vector2i(16, 2), GATLING], [Vector2i(14, 7), CANNON],
		[Vector2i(11, 3), GATLING], [Vector2i(9, 6), CANNON], [Vector2i(16, 4), CANNON], [Vector2i(14, 2), GATLING],
		[Vector2i(9, 2), CANNON], [Vector2i(5, 5), GATLING], [Vector2i(3, 3), CANNON]]
	var bought := 0
	var elapsed := 0.0
	# Les vagues partent seules : le joueur construit dès qu'il peut, et recrute un ouvrier
	# quand la pierre lui manque mais que l'or suffit.
	while not level.is_over and elapsed < 900.0:
		if bought < build_order.size():
			var data: TowerData = build_order[bought][1]
			if conquest.stone < Conquest.stone_cost(data) and level.gold >= data.get_cost() + Conquest.WORKER_COST \
					and conquest.get_workers().size() < 5:
				conquest.recruit()
		while bought < build_order.size() and level.can_place_tower(build_order[bought][0], build_order[bought][1]):
			level.place_tower(build_order[bought][0], build_order[bought][1])
			bought += 1
		elapsed += await _step()
	_check(level.is_over and level.lives > 0, "la partie est gagnée (vies : %d, tours : %d, pierre minée : %d, ouvriers perdus : %d)"
		% [level.lives, bought, conquest.stone_mined, conquest.workers_lost])
	await _free(level)


## Termine tout de suite un chantier de bâtiment.
func _finish_building(building: Building) -> void:
	building.conquest.build(building, Building.get_definition(building.kind).build_time + 1.0)


func _test_conquest_buildings() -> void:
	print("Mode Conquête : essence et bâtiments")
	var level := await _spawn_level(CONQUEST_01)
	var conquest := level.conquest
	var vein := Vector2i(9, 4)
	_check(conquest.veins.has(vein) and not level.map.is_cell_buildable(vein) and conquest.has_resource(vein),
		"les filons d'essence sont des gisements")
	var elapsed := 0.0
	while conquest.essence == 0 and elapsed < 60.0:
		elapsed += await _step()
	_check(conquest.essence > 0 and conquest.essence_mined == conquest.essence and level.stats.essence_mined > 0,
		"un ouvrier va de lui-même miner l'essence (%.0f s)" % elapsed)
	level.gold = 2000
	conquest.stone = 1000
	conquest.essence = 0
	var free := Vector2i(14, 4)
	var path_cell := Vector2i(15, 4)
	var K := Building.Kind
	_check(conquest.can_place_building(free, K.HOUSE) and not conquest.can_place_building(path_cell, K.HOUSE)
		and not conquest.can_place_building(vein, K.HOUSE), "une Maison se pose sur une case libre")
	_check(conquest.can_place_building(vein, K.EXTRACTOR) and not conquest.can_place_building(free, K.EXTRACTOR),
		"un Extracteur se pose sur un filon")
	_check(conquest.can_place_building(path_cell, K.BARRICADE) and not conquest.can_place_building(free, K.BARRICADE)
		and not conquest.can_place_building(Vector2i(18, 8), K.BARRICADE), "une Barricade se pose sur le chemin, pas contre le QG")
	_check(not conquest.can_place_building(free, K.BARRACKS), "la Caserne demande de l'essence")
	# Maison : un chantier bâti par les ouvriers, puis 2 ouvriers de plus.
	var house := conquest.place_building(free, K.HOUSE)
	_check(house != null and not house.is_built() and level.gold == 2000 - 40 and conquest.stone == 1000 - 30
		and level.map.get_occupant(free) == house, "une Maison posée est un chantier, payé en or et en pierre")
	elapsed = 0.0
	while not house.is_built() and elapsed < 30.0:
		elapsed += await _step()
	_check(house.is_built() and conquest.get_max_workers() == Conquest.BASE_WORKERS + Building.HOUSE_WORKERS
		and level.stats.buildings_built == 1, "les ouvriers bâtissent la Maison : 2 ouvriers de plus au maximum")
	# Dépôt : le plus proche des dépôts reçoit la pierre.
	var depot := conquest.place_building(Vector2i(5, 8), K.DEPOT)
	_finish_building(depot)
	_check(conquest.nearest_depot(level.map.cell_to_world(Vector2i(2, 8))) == depot.global_position
		and conquest.nearest_depot(level.map.cell_to_world(Vector2i(18, 5))) == conquest.depot_position,
		"le Dépôt bâti sert de dépôt aux gisements proches")
	# Extracteur : de l'essence sans ouvrier.
	conquest.set_preferred_rock(Vector2i(12, 3))
	var extractor := conquest.place_building(vein, K.EXTRACTOR)
	_finish_building(extractor)
	_check(not conquest.has_resource(vein), "un filon sous un Extracteur ne se mine plus")
	var miners := conquest.get_workers().filter(func(worker: Worker) -> bool: return worker.is_mining_essence())
	for worker: Worker in miners:
		worker.cargo = 0
		worker.go_deposit()
	conquest.veins.erase(Vector2i(13, 8))
	conquest.essence = 0
	elapsed = 0.0
	while elapsed < Building.EXTRACT_INTERVAL + 0.5:
		elapsed += await _step()
	_check(conquest.essence == 1, "l'Extracteur tire 1 essence toutes les %d s" % Building.EXTRACT_INTERVAL)
	# Caserne : des soldats sur le chemin.
	conquest.essence = 10
	var barracks := conquest.place_building(Vector2i(12, 4), K.BARRACKS)
	_check(barracks != null and conquest.essence == 6, "la Caserne coûte de l'essence")
	_finish_building(barracks)
	await _step()
	_check(level.get_soldiers().size() == Building.BARRACKS_SOLDIERS, "la Caserne bâtie envoie ses soldats")
	conquest.sell_building(barracks)
	for soldier in level.get_soldiers():
		soldier.despawn()
	# Barricade : les monstres au sol s'y arrêtent et la frappent.
	var barricade := conquest.place_building(path_cell, K.BARRICADE)
	_finish_building(barricade)
	var enemy := level.spawner.spawn(LARVE, level.map.get_enemy_path(0))
	elapsed = 0.0
	while not enemy.is_held() and elapsed < 30.0:
		elapsed += await _step()
	var health_before := barricade.health
	await _step()
	_check(enemy.holder == barricade and barricade.health < health_before, "un monstre au sol s'arrête à la Barricade et la frappe")
	var progress := enemy.progress
	barricade.health = 0.01
	for i in 3:
		await _step()
	_check(not is_instance_valid(barricade) and level.map.get_occupant(path_cell) == null and conquest.buildings_lost == 1,
		"la Barricade cassée disparaît")
	_check(enemy.progress > progress, "le monstre repart")
	enemy.despawn()
	# Améliorations : l'essence paie le niveau 3.
	var tower := level.place_tower(Vector2i(16, 4), CANNON)
	conquest.build(tower, 100.0)
	_check(Conquest.upgrade_essence_cost(tower) == 0 and level.upgrade_tower(tower), "le niveau 2 ne demande pas d'essence")
	conquest.essence = 2
	conquest.changed.emit()
	_check(Conquest.upgrade_essence_cost(tower) == Conquest.UPGRADE_ESSENCE and not level.can_upgrade_tower(tower),
		"le niveau 3 demande de l'essence")
	level.inspect_tower(tower)
	await process_frame
	_check(level.hud.tower_details.upgrade_button.text.ends_with("%d essence" % Conquest.UPGRADE_ESSENCE)
		and level.hud.tower_details.upgrade_button.disabled, "la fiche montre l'essence de l'amélioration")
	conquest.essence = 5
	_check(level.upgrade_tower(tower) and conquest.essence == 5 - Conquest.UPGRADE_ESSENCE, "l'amélioration paie son essence")
	level.inspect_tower(null)
	# Démolir : une part du prix rendue ; un chantier, tout.
	var gold_before := level.gold
	_check(conquest.sell_building(house) == roundi(40 * Conquest.SELL_RATIO) and level.gold == gold_before + 28
		and conquest.get_max_workers() == Conquest.BASE_WORKERS, "une Maison démolie rend une part de son prix")
	var site := conquest.place_building(free, K.DEPOT)
	gold_before = level.gold
	var stone_before := conquest.stone
	_check(conquest.sell_building(site) == 50 and level.gold == gold_before + 50 and conquest.stone == stone_before + 30,
		"un chantier démoli rend tout")
	# Un bâtiment détruit par les monstres disparaît.
	depot.take_damage(10000.0)
	await process_frame
	_check(not is_instance_valid(depot) and level.map.get_occupant(Vector2i(5, 8)) == null
		and conquest.nearest_depot(level.map.cell_to_world(Vector2i(2, 8))) == conquest.depot_position,
		"un Dépôt détruit ne sert plus")
	await _free(level)


func _test_conquest_top_bar() -> void:
	print("Mode Conquête : barre du haut avec les pouvoirs")
	_buy_all_powers()
	var level := await _spawn_level(load(ConquestLevels.LEVELS[1]))
	if level.is_choosing_towers:
		level.choose_towers(level.get_default_tower_choice())
	for i in 3:
		await process_frame
	var hud := level.hud
	var row := hud.level_label.get_parent() as Control
	_check(hud.level_label.get_global_rect().position.x >= 0.0 and row.get_global_rect().end.x <= hud.top_bar.size.x,
		"tout tient dans la barre du haut (nom du niveau à x = %d)" % hud.level_label.get_global_rect().position.x)
	_check(hud.power_buttons.size() == 3 and hud.power_buttons.all(func(b: PowerButton) -> bool: return b.compact and b.text.is_empty()),
		"les pouvoirs perdent leur nom pour faire de la place")
	_check(hud.level_label.text.begins_with("Conquête") and hud.level_label.size.x >= Hud.LEVEL_LABEL_MIN_WIDTH,
		"le nom du niveau reste lisible")
	_check(hud.level_label.tooltip_text.is_empty() or hud.level_label.tooltip_text == hud.level_label.text,
		"coupé, le nom du niveau est en entier dans sa bulle d'aide")
	await _free(level)
	level = await _spawn_level(LEVEL_01)
	for i in 3:
		await process_frame
	_check(level.hud.power_buttons.all(func(b: PowerButton) -> bool: return not b.compact)
		and level.hud.level_label.tooltip_text.is_empty(), "campagne : les pouvoirs gardent leur nom, le niveau aussi")
	await _free(level)
	Progress.reset_campaign()


func _test_conquest_hud() -> void:
	print("Mode Conquête : barre des bâtiments et fiche")
	var level := await _spawn_level(CONQUEST_01)
	var conquest := level.conquest
	var hud := level.hud
	level.gold = 500
	conquest.stone = 200
	_check(hud.buildings_button != null and hud.buildings_button.get_parent() == hud.tower_shop.get_parent()
		and not hud.building_shop.visible, "le bouton Bâtiments suit la barre d'achat")
	_press_key(level, KEY_B)
	await process_frame
	_check(hud.building_shop.visible and hud.buildings_button.button_pressed, "B ouvre la barre des bâtiments")
	_check(hud.building_shop.get_button(Building.Kind.BARRACKS).disabled
		and not hud.building_shop.get_button(Building.Kind.HOUSE).disabled, "la Caserne est grisée sans essence")
	_press_key(level, KEY_2)
	_check(level.placer.selected_building == Building.Kind.HOUSE and level.placer.selected_tower == null
		and hud.building_shop.get_button(Building.Kind.HOUSE).button_pressed, "les chiffres choisissent un bâtiment quand la barre est ouverte")
	var cell := Vector2i(14, 4)
	await _click(level, level.get_viewport().get_canvas_transform() * level.map.cell_to_world(cell))
	var house := level.map.get_occupant(cell) as Building
	_check(house != null and house.kind == Building.Kind.HOUSE and level.placer.selected_building == -1
		and not hud.building_shop.visible, "un clic pose le bâtiment, et la barre se referme")
	_press_key(level, KEY_1)
	_check(level.placer.selected_tower != null, "barre fermée, les chiffres choisissent de nouveau une tour")
	level.select_tower(null)
	await _click(level, level.get_viewport().get_canvas_transform() * level.map.cell_to_world(cell))
	_check(level.placer.inspected_building == house and hud.building_details.visible
		and hud.building_details._status_label.text.begins_with("En construction"), "un clic sur un bâtiment ouvre sa fiche")
	hud.building_details.demolish_requested.emit(house)
	await process_frame
	_check(not is_instance_valid(house) and not hud.building_details.visible, "Démolir retire le bâtiment et ferme sa fiche")
	await _click(level, level.get_viewport().get_canvas_transform() * level.map.cell_to_world(Vector2i(13, 8)))
	_check(conquest.preferred_rock == Vector2i(13, 8), "un clic sur un filon y envoie les mineurs")
	await _free(level)


## Clic (ou toucher) sur la carte, avec Maj si demandé.
func _click_at(level: Level, world_position: Vector2, shift := false, button := MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	event.shift_pressed = shift
	event.position = level.get_viewport().get_canvas_transform() * world_position
	await _send_to_placer(level, event)


func _test_conquest_worker_orders() -> void:
	print("Mode Conquête : ouvriers choisis et affectés à la main")
	var level := await _spawn_level(CONQUEST_01)
	var conquest := level.conquest
	var hud := level.hud
	var workers := conquest.get_workers()
	for worker in workers:
		worker.set_process(false)
	# Un clic choisit un ouvrier, Maj + clic en ajoute un autre.
	await _click_at(level, workers[0].get_pick_point())
	_check(conquest.get_selected_workers() == [workers[0]] and workers[0].selected and hud.worker_bar.visible
		and hud._worker_bar_label.text.begins_with("1 ouvrier choisi"), "un clic sur un ouvrier le choisit")
	await _click_at(level, workers[1].get_pick_point(), true)
	_check(conquest.get_selected_workers().size() == 2 and hud._worker_bar_label.text.begins_with("2 ouvriers choisis"),
		"Maj + clic en ajoute un")
	await _click_at(level, workers[1].get_pick_point())
	_check(conquest.get_selected_workers() == [workers[1]] and not workers[0].selected, "un clic seul ne garde que lui")
	_press_key(level, KEY_O)
	_check(conquest.get_selected_workers().size() == workers.size(), "O les choisit tous")
	_press_key(level, KEY_O)
	_check(conquest.get_selected_workers().is_empty() and not hud.worker_bar.visible, "O de nouveau les relâche")
	hud.workers_label.pressed.emit()
	_check(conquest.get_selected_workers().size() == workers.size(), "le compteur des ouvriers les choisit tous")
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	await _send_to_placer(level, cancel)
	_check(conquest.get_selected_workers().is_empty(), "Échap les relâche")
	# Un cadre tiré depuis une case vide choisit les ouvriers qu'il entoure.
	var empty := Vector2i(14, 4)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	var canvas := level.get_viewport().get_canvas_transform()
	press.position = canvas * level.map.cell_to_world(empty)
	await _send_to_placer(level, press)
	var corner := Vector2(INF, INF)
	var far_corner := -corner
	for worker in workers:
		corner = corner.min(worker.global_position - Vector2(20, 30))
		far_corner = far_corner.max(worker.global_position + Vector2(20, 20))
	var start := level.map.cell_to_world(empty)
	var end := far_corner if start.x < far_corner.x else corner
	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.position = canvas * end
	await _send_to_placer(level, motion)
	_check(level.placer._dragging, "un appui qui glisse depuis une case vide tire un cadre")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = motion.position
	await _send_to_placer(level, release)
	var inside := conquest.workers_in_rect(Rect2(start, Vector2.ZERO).expand(end))
	_check(not inside.is_empty() and conquest.get_selected_workers().size() == inside.size() and not level.placer._dragging,
		"le cadre choisit les ouvriers qu'il entoure (%d)" % inside.size())
	await _click_at(level, level.map.cell_to_world(empty))
	await _send_to_placer(level, release)
	_check(conquest.get_selected_workers().is_empty(), "un clic sur une case vide les relâche")
	# Au tactile, chaque toucher sur un ouvrier l'ajoute aux autres.
	GameSettings.set_touch_mode(true)
	await _click_at(level, workers[0].get_pick_point() + Vector2(14, 0))
	await _click_at(level, workers[2].get_pick_point())
	_check(conquest.get_selected_workers().size() == 2, "au tactile, chaque toucher ajoute un ouvrier")
	await _click_at(level, workers[2].get_pick_point())
	_check(conquest.get_selected_workers() == [workers[0]], "et le retire s'il était choisi")
	GameSettings.set_touch_mode(false)
	for worker in workers:
		worker.set_process(true)
	# Un clic sur un rocher y envoie les ouvriers choisis, et eux seuls.
	conquest.select_workers([workers[0], workers[1]])
	var rock: Vector2i = conquest.rocks.keys()[0]
	for cell: Vector2i in conquest.rocks:
		if cell.distance_to(Vector2i(17, 7)) > rock.distance_to(Vector2i(17, 7)):
			rock = cell
	await _click_at(level, level.map.cell_to_world(rock))
	_check(workers[0].order == Worker.Order.MINE and workers[1].order == Worker.Order.MINE and workers[0].order_cell == rock
		and workers[2].order == Worker.Order.AUTO and conquest.preferred_rock == Conquest.NO_CELL,
		"un clic sur un rocher y affecte les ouvriers choisis")
	var elapsed := 0.0
	while conquest.rocks.get(rock, 0) > Conquest.ROCK_STONE - 2 * Worker.CARRY and elapsed < 60.0:
		elapsed += await _step()
	_check(conquest.rocks.get(rock, 0) <= Conquest.ROCK_STONE - 2 * Worker.CARRY, "les deux minent le rocher lointain (%.0f s)" % elapsed)
	_check(workers[0].order == Worker.Order.MINE and workers[0].order_cell == rock, "et s'y tiennent, voyage après voyage")
	# Plusieurs ouvriers sur le même chantier : plus que les 2 des ordres automatiques.
	level.gold = 2000
	conquest.stone = 1000
	var house := conquest.place_building(empty, Building.Kind.HOUSE)
	for worker in workers:
		worker.global_position = house.global_position + Vector2(0, 50)
	conquest.select_workers(workers)
	await _click_at(level, level.map.cell_to_world(empty), false, MOUSE_BUTTON_RIGHT)
	_check(workers.all(func(worker: Worker) -> bool: return worker.order == Worker.Order.BUILD and worker.order_site == house),
		"un clic droit sur un chantier y affecte les ouvriers choisis")
	elapsed = 0.0
	var most_builders := 0
	while is_instance_valid(house) and not house.is_built() and elapsed < 60.0:
		most_builders = maxi(most_builders, workers.filter(func(worker: Worker) -> bool:
			return worker.state == Worker.State.BUILDING and worker.site == house).size())
		elapsed += await _step()
	_check(house.is_built() and most_builders == 3 and most_builders > Conquest.BUILDERS_PER_SITE,
		"les %d ouvriers bâtissent ensemble la Maison (%.0f s)" % [most_builders, elapsed])
	await _step()
	await _step()
	_check(workers.all(func(worker: Worker) -> bool: return worker.order == Worker.Order.AUTO),
		"le chantier fini, ils reviennent aux ordres automatiques")
	# Au QG, puis Automatique.
	hud.workers_sent_home.emit()
	elapsed = 0.0
	while not workers.all(func(worker: Worker) -> bool: return conquest.is_safe(worker.global_position) and worker.cargo == 0) \
			and elapsed < 60.0:
		elapsed += await _step()
	for i in 20:
		await _step()
	_check(workers.all(func(worker: Worker) -> bool: return worker.order == Worker.Order.HOME and conquest.is_safe(worker.global_position)),
		"« Au QG » les fait rentrer, et ils y restent")
	hud.workers_released.emit()
	_check(workers.all(func(worker: Worker) -> bool: return worker.order == Worker.Order.AUTO)
		and conquest.get_selected_workers().is_empty() and not hud.worker_bar.visible, "« Automatique » les rend au jeu et les relâche")
	await _free(level)


func _test_conquest_workshop() -> void:
	print("Mode Conquête : Atelier et améliorations de la partie")
	var level := await _spawn_level(CONQUEST_01)
	var conquest := level.conquest
	var hud := level.hud
	level.gold = 5000
	conquest.stone = 2000
	conquest.essence = 200
	var tower := level.place_tower(Vector2i(14, 2), CANNON)
	conquest.build(tower, 999.0)
	var base_damage := tower.stats.damage
	var base_range := tower.stats.attack_range
	var workshop := conquest.place_building(Vector2i(14, 4), Building.Kind.WORKSHOP)
	_check(workshop != null and conquest.research_blocker(workshop, Research.TOWER_DAMAGE) != "", "un Atelier en chantier ne cherche rien")
	_finish_building(workshop)
	level.placer.inspect_building(workshop)
	await process_frame
	var panel := hud.building_details
	_check(panel.visible and panel._research_box.visible and panel.size.x >= BuildingInfoPanel.WORKSHOP_WIDTH
		and not panel.get_research_button(Research.TOWER_DAMAGE).disabled, "la fiche de l'Atelier montre ses améliorations")
	var gold := level.gold
	panel.get_research_button(Research.TOWER_DAMAGE).pressed.emit()
	await process_frame
	var cost := Research.get_cost(Research.TOWER_DAMAGE, 1)
	_check(workshop.research_id == Research.TOWER_DAMAGE and level.gold == gold - cost.gold, "son bouton lance la recherche, payée")
	_check(panel.get_research_button(Research.WORKER_SPEED).disabled and panel._research_status.text.begins_with("Recherche : Poudre raffinée"),
		"un Atelier ne cherche qu'une amélioration à la fois")
	var second := conquest.place_building(Vector2i(11, 3), Building.Kind.WORKSHOP)
	_finish_building(second)
	_check(not conquest.start_research(second, Research.TOWER_DAMAGE) and conquest.start_research(second, Research.WORKER_SPEED),
		"un second Atelier cherche autre chose, pas la même")
	var elapsed := 0.0
	while workshop.research_id != &"" and elapsed < 30.0:
		elapsed += await _step()
	_check(conquest.get_research_level(Research.TOWER_DAMAGE) == 1 and is_equal_approx(tower.stats.damage, base_damage * 1.08),
		"Poudre raffinée finie : +8 %% de dégâts pour les tours posées (%.0f s)" % elapsed)
	var later := level.place_tower(Vector2i(16, 2), CANNON)
	conquest.build(later, 999.0)
	_check(is_equal_approx(later.stats.damage, base_damage * 1.08), "et pour celles posées ensuite")
	while second.research_id != &"" and elapsed < 60.0:
		elapsed += await _step()
	_check(is_equal_approx(conquest.get_worker_speed(), Worker.SPEED * 1.15), "Bottes de marche : les ouvriers vont plus vite")
	conquest.start_research(workshop, Research.TOWER_RANGE)
	conquest.start_research(second, Research.WORLD_FORTIFY)
	var house := conquest.place_building(Vector2i(9, 6), Building.Kind.HOUSE)
	_finish_building(house)
	var house_health := house.max_health
	while (workshop.research_id != &"" or second.research_id != &"") and elapsed < 120.0:
		elapsed += await _step()
	_check(is_equal_approx(tower.stats.attack_range, base_range * 1.06), "Lunettes de visée : +6 % de portée")
	_check(is_equal_approx(house.max_health, house_health * 1.3) and is_equal_approx(house.health, house.max_health),
		"Fortifications : les bâtiments posés gagnent de la vie")
	var reward := level.get_enemy_reward(PILLARDE)
	conquest.research_levels[Research.WORLD_BOUNTY] = 2
	_check(level.get_enemy_reward(PILLARDE) == roundi(PILLARDE.reward * 1.2) and level.get_enemy_reward(PILLARDE) >= reward,
		"Primes de chasse : les monstres rapportent plus d'or")
	conquest.research_levels[Research.WORKER_CARRY] = 1
	_check(conquest.get_carry(Conquest.Ore.STONE) == Worker.CARRY + 1 and conquest.get_carry(Conquest.Ore.ESSENCE) == Worker.ESSENCE_CARRY + 1,
		"Grandes hottes : une pierre et une essence de plus par voyage")
	conquest.research_levels[Research.WORLD_EXTRACTION] = 2
	_check(is_equal_approx(conquest.get_extract_interval(), Building.EXTRACT_INTERVAL / 1.5), "Forages profonds : Extracteurs plus rapides")
	# Niveau maximum, et Atelier démoli en pleine recherche : elle est rendue.
	conquest.research_levels[Research.TOWER_FIRE_RATE] = Research.get_max_level(Research.TOWER_FIRE_RATE)
	_check(conquest.research_blocker(workshop, Research.TOWER_FIRE_RATE) == "Niveau maximum", "une amélioration s'arrête à son niveau maximum")
	gold = level.gold
	var stone := conquest.stone
	conquest.start_research(workshop, Research.WORKER_TOOLS)
	var refund := conquest.get_building_refund(workshop)
	conquest.sell_building(workshop)
	_check(level.gold == gold + refund.gold and conquest.stone == stone + refund.stone, "démoli en pleine recherche, l'Atelier la rend")
	await _free(level)


func _test_raiders() -> void:
	print("Mode Conquête : Pillards")
	var level := await _spawn_level(CONQUEST_01)
	var conquest := level.conquest
	var raid_groups := level.spawner.waves[2].groups.filter(func(group: SpawnGroup) -> bool: return group.enemy == PILLARDE)
	_check(raid_groups.size() == 1 and raid_groups[0].count == 1
		and level.spawner.waves[1].groups.all(func(group: SpawnGroup) -> bool: return group.enemy != PILLARDE),
		"les Pillards s'ajoutent aux vagues du niveau")
	var original := LEVEL_01.instantiate()
	_check(not original.get_node("WaveSpawner").waves[2].groups.any(
		func(group: SpawnGroup) -> bool: return group.enemy == PILLARDE), "sans changer les vagues de la scène d'origine")
	original.free()
	_check(PILLARDE.get_abilities().any(func(line: String) -> bool: return line.begins_with("Pillard")),
		"la fiche du Pillard décrit son pillage")
	# Un ouvrier loin du QG, près du chemin.
	var worker: Worker = conquest.get_workers()[0]
	worker.set_process(false)
	var raider := level.spawner.spawn(PILLARDE, level.map.get_enemy_path(0), 300.0)
	worker.global_position = raider.global_position + Vector2(0, 90)
	var start := raider.global_position
	var elapsed := 0.0
	while is_instance_valid(worker) and worker.health >= Worker.MAX_HEALTH and elapsed < 5.0:
		elapsed += await _step()
	_check(raider.is_raiding() and raider.global_position.distance_to(start) > 20.0, "le Pillard quitte le chemin vers l'ouvrier")
	_check(not is_instance_valid(worker) or worker.health < Worker.MAX_HEALTH, "il frappe l'ouvrier")
	elapsed = 0.0
	while raider.is_raiding() and elapsed < 20.0:
		elapsed += await _step()
	_check(not raider.is_raiding() and raider.global_position.distance_to(level.map.get_enemy_path(0).to_global(
		level.map.get_enemy_path(0).curve.sample_baked(raider.progress))) < 30.0, "puis il revient sur le chemin")
	# Les ouvriers près du QG sont à l'abri.
	var safe: Worker = conquest.get_workers()[0]
	safe.set_process(false)
	safe.global_position = conquest.depot_position
	_check(not safe.can_be_raided(), "les ouvriers au QG sont à l'abri des Pillards")
	raider.despawn()
	await _free(level)


func _test_thieves() -> void:
	print("Mode Conquête : Voleurs")
	var level := await _spawn_level(CONQUEST_01)
	var conquest := level.conquest
	var thief_groups := level.spawner.waves[2].groups.filter(func(group: SpawnGroup) -> bool: return group.enemy == CHAPARDEUSE)
	_check(thief_groups.size() == 1 and level.spawner.waves[1].groups.all(func(group: SpawnGroup) -> bool: return group.enemy != CHAPARDEUSE),
		"les Voleurs s'ajoutent aux vagues du niveau")
	_check(CHAPARDEUSE.get_abilities().any(func(line: String) -> bool: return line.begins_with("Voleur")),
		"la fiche du Voleur décrit son vol")
	_check(Perks.CAMPAIGN.worlds.all(func(world: World) -> bool: return world.thieves.size() == 1 and world.thieves[0].thief),
		"un Voleur par monde")
	for worker in conquest.get_workers():
		worker.set_process(false)
	level.gold = 1000
	conquest.stone = 200
	conquest.essence = 30
	# Un Dépôt bâti près du chemin attire le Voleur ; un chantier, non.
	var path := level.map.get_enemy_path(0)
	var thief := level.spawner.spawn(CHAPARDEUSE, path, 300.0)
	thief.set_process(false)
	var cell := Conquest.NO_CELL
	var thief_cell := level.map.world_to_cell(thief.global_position)
	for offset in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1),
			Vector2i(0, 2), Vector2i(0, -2), Vector2i(1, 2), Vector2i(-1, 2)]:
		if cell == Conquest.NO_CELL and conquest.is_cell_suitable(thief_cell + offset, Building.Kind.DEPOT):
			cell = thief_cell + offset
	var depot := conquest.place_building(cell, Building.Kind.DEPOT)
	_check(depot != null and thief._find_theft_target() == null, "un Dépôt en chantier n'attire pas les Voleurs")
	_finish_building(depot)
	_check(thief._find_theft_target() == depot, "un Dépôt bâti, si")
	var stone := conquest.stone
	var essence := conquest.essence
	thief.set_process(true)
	var elapsed := 0.0
	while not thief.has_stolen and elapsed < 15.0:
		elapsed += await _step()
	_check(thief.has_stolen and conquest.stone == stone - CHAPARDEUSE.steal_stone and conquest.essence == essence - CHAPARDEUSE.steal_essence
		and thief.stolen_stone == CHAPARDEUSE.steal_stone, "le Voleur pille le Dépôt (%.1f s)" % elapsed)
	elapsed = 0.0
	while thief.is_raiding() and elapsed < 20.0:
		elapsed += await _step()
	_check(not thief.is_raiding() and thief._find_theft_target() == depot and not thief._update_raid(0.0),
		"puis il revient sur le chemin, sans piller une seconde fois")
	# Détruit, il lâche son butin.
	thief.take_damage(9999.0, true)
	await process_frame
	var dropped := get_nodes_in_group(Loot.GROUP).filter(func(node: Node) -> bool:
		return (node as Loot).kind != Loot.Kind.CHEST and (node as Loot).amount in [CHAPARDEUSE.steal_stone, CHAPARDEUSE.steal_essence])
	_check(dropped.size() == 2, "détruit, le Voleur lâche la pierre et l'essence volées")
	for loot in dropped:
		level.collect_loot(loot)
	_check(conquest.stone == stone and conquest.essence == essence, "et on les ramasse")
	_check(level.stats.resources_stolen == CHAPARDEUSE.steal_stone + CHAPARDEUSE.steal_essence, "la fin de partie compte ce qui a été volé")
	# Au QG : il se sert en passant, sans toucher à la réserve.
	conquest.stone = 25
	conquest.essence = 3
	conquest.bonuses.conquest_vault_stone = 10
	var runner := level.spawner.spawn(CHAPARDEUSE, path, path.curve.get_baked_length() - 2.0)
	elapsed = 0.0
	while is_instance_valid(runner) and runner.is_alive and elapsed < 2.0:
		elapsed += await _step()
	_check(conquest.stone == 10 and conquest.essence == 0, "un Voleur qui atteint le QG emporte ce qui n'est pas en réserve")
	await _free(level)


func _test_corvee() -> void:
	print("Mode Conquête : pouvoir Corvée")
	var corvee: Power = load("res://resources/powers/corvee.tres")
	_check(not corvee.is_targeted() and corvee.is_conquest_only(), "la Corvée part tout de suite, en Conquête seulement")
	Perks.unlock_everything()
	var level := await _spawn_level(LEVEL_01)
	_check(level.powers.size() == 3 and not level.powers.any(func(power: Power) -> bool: return power.is_conquest_only()),
		"pas de bouton Corvée hors de la Conquête")
	await _free(level)
	level = await _spawn_level(CONQUEST_01)
	if level.is_choosing_towers:
		level.choose_towers(level.get_default_tower_choice())
	var conquest := level.conquest
	var power: Power = level.powers.filter(func(p: Power) -> bool: return p.kind == Power.Kind.CORVEE).front()
	_check(level.powers.size() == 4 and level.hud.power_buttons.size() == 4, "en Conquête, la Corvée a son bouton (touche T)")
	var walk := conquest.get_worker_speed()
	var work := conquest.get_work_speed()
	_check(level.use_power(power) and conquest.is_corvee(), "la Corvée se lance")
	_check(is_equal_approx(conquest.get_worker_speed(), walk * 2.0) and is_equal_approx(conquest.get_work_speed(), work * 2.0),
		"les ouvriers vont deux fois plus vite")
	var elapsed := 0.0
	while conquest.is_corvee() and elapsed < 30.0:
		elapsed += await _step()
	_check(absf(elapsed - power.duration) < 1.0 and is_equal_approx(conquest.get_worker_speed(), walk),
		"pendant %s s (%.1f s)" % [power.duration, elapsed])
	await _free(level)
	Perks.refund_all()
	Progress.reset_campaign()


func _test_logistics() -> void:
	print("Mode Conquête : page Logistique de l'arbre")
	var tree := Perks.TREE
	var page := tree.page_names.find("Logistique")
	_check(page >= 0 and tree.get_page_perks(page).all(func(p: Perk) -> bool: return not p.paid_with_endless_stars),
		"la page Logistique se paie en étoiles")
	_win_in_all_difficulties(ConquestLevels.LEVELS)
	for perk in tree.get_page_perks(page):
		_check(Perks.buy(perk), "achat : %s" % perk.display_name)
	var level := await _spawn_level(CONQUEST_01)
	var conquest := level.conquest
	_check(conquest.get_workers().size() == level.conquest_starting_workers + 2
		and conquest.stone == level.conquest_starting_stone + 30, "ouvriers et pierre de départ en plus")
	_check(conquest.get_max_workers() == Conquest.BASE_WORKERS + 2, "Dortoirs : 2 ouvriers de plus au maximum")
	_check(Conquest.stone_cost(CANNON) == ceili(CANNON.get_cost() * Conquest.STONE_PER_GOLD * 0.8), "Tailleurs de pierre : tours moins chères en pierre")
	_check(conquest.get_vault().stone == 100 and conquest.get_vault().essence == 25, "Chambre forte : 100 pierres et 25 essences à l'abri")
	level.gold = 1000
	conquest.stone = 500
	var house := conquest.place_building(Vector2i(14, 2), Building.Kind.HOUSE)
	_check(is_equal_approx(house.max_health, Building.get_definition(Building.Kind.HOUSE).health * 1.25 * 1.4),
		"Murs épais et Pierre de taille : bâtiments plus solides")
	var time: float = Building.get_definition(Building.Kind.HOUSE).build_time
	conquest.build(house, time / 1.25 + 0.01)
	_check(house.is_built(), "Charpentiers : chantiers plus rapides")
	var depot := conquest.place_building(Vector2i(11, 3), Building.Kind.DEPOT)
	var near_depot := level.map.cell_to_world(Vector2i(11, 3)) + Vector2(20, 0)
	_check(not conquest.is_safe(near_depot), "un Dépôt en chantier n'abrite pas les ouvriers")
	_finish_building(depot)
	_check(conquest.is_safe(near_depot), "Relais : un Dépôt bâti les abrite")
	await _free(level)
	level = await _spawn_level(LEVEL_01)
	_check(level.conquest == null and level.gold == level.starting_gold, "hors de la Conquête, rien ne change")
	await _free(level)
	var screen := PERK_TREE_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	screen.show_page(page)
	_check(screen.get_button(tree.get_perk("pouvoir_corvee")).is_visible_in_tree()
		and screen.get_button(tree.get_perk("pouvoir_corvee")).get_child(0) is PowerIcon, "l'onglet Logistique montre la Corvée avec son image")
	await _free(screen)
	Perks.refund_all()
	Progress.reset_campaign()


func _test_conquest_progress() -> void:
	print("Mode Conquête : niveaux, étoiles et succès")
	Progress.reset_campaign()
	for id in ["premiere_pierre", "securite", "conquerant", "contremaitre", "carrier"]:
		Progress.set_value(Achievements.SECTION, id, 0)
	_unlock_all_modes()
	var title: Control = TITLE_SCREEN.instantiate()
	root.add_child(title)
	await process_frame
	title.get_node("%ConquestButton").pressed.emit()
	await process_frame
	await process_frame
	_check(current_scene and current_scene.scene_file_path == ConquestLevels.SELECT_SCREEN, "le bouton Conquête ouvre le choix des niveaux")
	if is_instance_valid(title):
		title.queue_free()
	if current_scene:
		current_scene.queue_free()
	await process_frame
	Progress.reset_campaign()
	var screen: Control = CONQUEST_SELECT_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	_check(screen.play_buttons.size() == ConquestLevels.size() and not screen.play_buttons[0].disabled
		and screen.play_buttons[1].disabled, "une carte par niveau, seul le premier ouvert")
	screen.queue_free()
	var stars_before := Perks.get_earned_stars()
	var level := await _spawn_level(CONQUEST_01)
	level.conquest.peak_workers = 0
	for i in Achievements.FOREMAN_WORKERS:
		level.conquest._add_worker(level.conquest.depot_position)
	_check(Achievements.is_unlocked("contremaitre"), "Contremaître : %d ouvriers en même temps" % Achievements.FOREMAN_WORKERS)
	level.stats.stone_mined = 2000
	level._end_game(true)
	_check(Progress.get_stars(ConquestLevels.LEVELS[0]) == 3 and ConquestLevels.is_unlocked(1)
		and Perks.get_earned_stars() == stars_before + 3, "la victoire donne des étoiles, qui comptent pour l'arbre, et ouvre le niveau suivant")
	_check(Achievements.is_unlocked("premiere_pierre") and Achievements.is_unlocked("securite")
		and Achievements.is_unlocked("carrier") and not Achievements.is_unlocked("conquerant"),
		"succès de la Conquête débloqués")
	_check(level.hud.next_level_button.visible and level.unlocked_achievements.has("premiere_pierre"),
		"l'écran de fin propose le niveau suivant et annonce les succès")
	await _free(level)
	for path in ConquestLevels.LEVELS:
		Progress.record_victory(path, 1)
	_check(Achievements.check_progress().has("conquerant"), "Conquérant : tous les niveaux gagnés")
	Progress.reset_campaign()


## Ordre de construction du bot de chaque niveau de Conquête : celui du niveau de la
## campagne dont il reprend la carte et les vagues.
const CONQUEST_BUILD_ORDERS := {
	"res://scenes/levels/conquest_01.tscn": [
		[Vector2i(14, 4), CANNON], [Vector2i(16, 2), GATLING], [Vector2i(14, 7), CANNON],
		[Vector2i(11, 3), GATLING], [Vector2i(9, 6), CANNON], [Vector2i(16, 4), CANNON], [Vector2i(14, 2), GATLING],
		[Vector2i(9, 2), CANNON], [Vector2i(5, 5), GATLING], [Vector2i(3, 3), CANNON],
	],
	"res://scenes/levels/conquest_02.tscn": "res://scenes/levels/mecha_01.tscn",
	"res://scenes/levels/conquest_03.tscn": "res://scenes/levels/humanoid_02.tscn",
	"res://scenes/levels/conquest_04.tscn": "res://scenes/levels/undead_02.tscn",
	"res://scenes/levels/conquest_05.tscn": [
		[Vector2i(8, 2), CANNON], [Vector2i(9, 4), CANNON], [Vector2i(10, 5), MORTAR],
		[Vector2i(9, 7), BEAM], [Vector2i(6, 4), FROST], [Vector2i(11, 2), CANNON],
		[Vector2i(5, 5), SNIPER], [Vector2i(13, 5), MORTAR], [Vector2i(16, 5), BEAM],
		[Vector2i(11, 7), GATLING], [Vector2i(4, 4), FROST], [Vector2i(14, 2), SNIPER],
		[Vector2i(6, 7), MORTAR], [Vector2i(3, 4), BEAM], [Vector2i(16, 2), CANNON],
		[Vector2i(9, 5), MORTAR], [Vector2i(3, 7), SNIPER], [Vector2i(13, 4), BEAM],
	],
}


func _conquest_build_order(path: String) -> Array:
	var order = CONQUEST_BUILD_ORDERS[path]
	return WORLD_BUILD_ORDERS[order] if order is String else order


## Bot du mode Conquête, qui joue comme un joueur appliqué : il pose les `tower_count`
## premières tours de l'ordre de construction du niveau dès qu'il peut les payer, recrute
## un ouvrier quand la pierre manque, bâtit une Maison puis une Caserne, et améliore ses
## tours avec l'or et l'essence en trop (seulement s'il suit tout l'ordre de construction).
## Les vagues partent seules. Renvoie le bilan.
func _play_conquest_bot(level: Level, tower_count := 99, max_time := 1500.0) -> Dictionary:
	var conquest := level.conquest
	var order := _conquest_build_order(level.scene_file_path)
	tower_count = mini(tower_count, order.size())
	if level.is_choosing_towers:
		level.choose_towers(level.get_default_tower_choice())
	var bought := 0
	var house_done := false
	var barracks_done := false
	var elapsed := 0.0
	while not level.is_over and elapsed < max_time:
		if bought < tower_count:
			var cell: Vector2i = order[bought][0]
			var data: TowerData = order[bought][1]
			if not level.map.is_cell_buildable(cell):
				bought += 1
			elif conquest.stone < Conquest.stone_cost(data) and conquest.get_workers().size() < 8 \
					and level.gold >= data.get_cost() + Conquest.WORKER_COST:
				conquest.recruit()
			elif level.place_tower(cell, data):
				bought += 1
		# Maison et Caserne, sur des cases que l'ordre de construction n'utilise pas.
		var spare := func(cell: Vector2i) -> bool: return not order.any(func(item: Array) -> bool: return item[0] == cell)
		if conquest.get_workers().size() < 4 and level.gold >= Conquest.WORKER_COST + 20:
			conquest.recruit()
		if bought >= 4 and not house_done and conquest.get_workers().size() >= conquest.get_max_workers():
			for item: Array in order:
				var cell: Vector2i = item[0] + Vector2i(0, 1)
				if spare.call(cell) and conquest.place_building(cell, Building.Kind.HOUSE):
					house_done = true
					break
		if bought >= 6 and not barracks_done:
			for item: Array in order:
				var cell: Vector2i = item[0] + Vector2i(1, 0)
				if spare.call(cell) and conquest.place_building(cell, Building.Kind.BARRACKS):
					barracks_done = true
					break
		# L'or en trop (la pierre manque, ou toutes les tours sont posées) va aux améliorations.
		var next_cost: int = order[bought][1].get_cost() if bought < tower_count else 0
		if tower_count < order.size():
			pass
		elif bought >= tower_count or (conquest.stone < Conquest.stone_cost(order[bought][1]) and level.gold > next_cost + 60):
			for tower in level.get_towers():
				if level.gold - tower.get_upgrade_cost() >= next_cost and level.upgrade_tower(tower):
					break
		var before := elapsed
		elapsed += await _step()
		if OS.has_environment("BOT_DEBUG") and int(before / 10.0) != int(elapsed / 10.0):
			print("  t=%d or=%d pierre=%d ess=%d ouvriers=%d bâties=%d/%d vague=%d vies=%d" % [elapsed, level.gold,
				conquest.stone, conquest.essence, conquest.get_workers().size(),
				level.get_towers().filter(func(t: Tower) -> bool: return t.is_built()).size(), level.get_towers().size(),
				level.spawner.current_wave + 1, level.lives])
	return {won = level.is_over and level.lives > 0, lives = level.lives, bought = bought,
		text = "%s vies=%d/%d vague=%d/%d tours=%d pierre=%d essence=%d ouvriers_perdus=%d bat_perdus=%d t=%.0f" % [
		"GAGNÉ" if level.is_over and level.lives > 0 else ("PERDU" if level.is_over else "TEMPS"),
		level.lives, level.starting_lives, level.spawner.current_wave + 1, level.spawner.get_wave_count(),
		bought, conquest.stone_mined, conquest.essence_mined, conquest.workers_lost, conquest.buildings_lost, elapsed]}


# --- Niveaux libres -------------------------------------------------------------

## Longueur du chemin des monstres d'un point d'apparition, en pixels.
func _route_length(map: GameMap, index := 0) -> float:
	return map.paths[index].curve.get_baked_length()


## Case traversée par une courbe de trajet (repère du chemin).
func _curve_visits(map: GameMap, curve: Curve2D, cell: Vector2i) -> bool:
	for point in curve.get_baked_points():
		if map.world_to_cell(map.paths[0].to_global(point)) == cell:
			return true
	return false


## Conquête sur une carte libre : bâtiments et rochers minés changent le chemin.
func _test_free_conquest() -> void:
	print("Conquête · Le Dédale : bâtiments et rochers font le labyrinthe")
	var level := await _spawn_level(CONQUEST_06)
	var map := level.map
	var conquest := level.conquest
	_check(map.free_layout and conquest != null and map.paths.size() == 2, "une Conquête sur une carte libre")
	level.gold = 5000
	conquest.stone = 1000
	conquest.essence = 1000
	var K := Building.Kind
	var consistent := true
	for x in map.columns:
		for y in map.rows:
			var cell := Vector2i(x, y)
			if map.is_cell_buildable(cell) and conquest.is_cell_suitable(cell, K.HOUSE) == level.blocks_passage(cell):
				consistent = false
	_check(consistent, "une Maison se pose sur une case libre, sauf si elle fermait le passage")
	# Une Maison est un mur : le chemin la contourne.
	var walked := Vector2i(-1, -1)
	for x in range(4, map.columns - 4):
		for y in map.rows:
			if walked.x < 0 and map.is_cell_walked(Vector2i(x, y)) and map.is_cell_buildable(Vector2i(x, y)) \
					and not level.blocks_passage(Vector2i(x, y)):
				walked = Vector2i(x, y)
	var version := map.layout_version
	var house := conquest.place_building(walked, K.HOUSE)
	_check(house != null and map.layout_version > version and not map.is_cell_walked(walked),
		"une Maison sur le chemin le fait dévier (%s)" % [walked])
	# Une Barricade se pose sur le chemin, et les monstres passent par elle.
	var road := Vector2i(-1, -1)
	for x in range(4, map.columns - 4):
		for y in map.rows:
			if road.x < 0 and conquest.is_cell_suitable(Vector2i(x, y), K.BARRICADE):
				road = Vector2i(x, y)
	version = map.layout_version
	var barricade := conquest.place_building(road, K.BARRICADE)
	_check(barricade != null and map.is_cell_walked(road), "une Barricade se pose sur le chemin, qui passe toujours par elle")
	# Un rocher miné ouvre un passage.
	version = map.layout_version
	var rock: Vector2i = map.blocked_cells[0]
	map.remove_rock(rock)
	_check(map.layout_version > version and not map.is_cell_blocked(rock), "un rocher miné recalcule les chemins")
	await _free(level)


## Éditeur : une carte libre, avec ses terriers et son QG.
func _test_free_level_editor() -> void:
	print("Éditeur : carte libre")
	var data := CustomLevel.create_default()
	CustomLevel.make_free(data)
	_check(CustomLevel.validate(data).begins_with("Posez au moins un terrier"), "une carte libre demande des terriers")
	data.spawns = [Vector2i(0, 2), Vector2i(5, 5)]
	_check(CustomLevel.validate(data).begins_with("Les terriers sont sur le bord"), "un terrier se pose au bord de la carte")
	data.spawns = [Vector2i(0, 2), Vector2i(0, 7)]
	_check(CustomLevel.validate(data).begins_with("Posez le QG"), "une carte libre demande un QG")
	data.base = Vector2i(18, 5)
	data.path = []
	_check(CustomLevel.validate(data).is_empty(), "terriers et QG suffisent, sans chemin tracé")
	var walled := data.duplicate(true)
	for y in CustomLevel.ROWS:
		walled.rocks.append(Vector2i(10, y))
	_check(CustomLevel.validate(walled).begins_with("Un terrier n'a pas de passage"), "un mur de rochers est refusé")
	var waves := CustomLevel.build_waves(data)
	_check(waves[1].groups[0].path_index == 1 and waves[1].groups[1].path_index == 0,
		"les groupes se partagent les terriers")
	# Partage par code.
	var code := CustomLevel.encode(data)
	var decoded := CustomLevel.decode(code)
	_check(CustomLevel.is_free(decoded) and decoded.spawns == data.spawns and decoded.base == data.base
		and decoded.rocks == data.rocks, "le code garde la carte libre")
	# L'écran de l'éditeur.
	Progress.set_setting(CustomLevel.LEVELS_SETTING, [])
	var editor: LevelEditor = load("res://scenes/ui/level_editor.tscn").instantiate()
	root.add_child(editor)
	await process_frame
	editor.set_free(true)
	_check(editor.current_tool == LevelEditor.EditTool.SPAWNS and editor.spawns_tool_button.visible
		and not editor.path_tool_button.visible and editor.play_button.disabled, "passer en carte libre montre les outils Terriers et QG")
	editor.click_cell(Vector2i(6, 6))
	editor.click_cell(Vector2i(0, 4))
	editor.click_cell(Vector2i(19, 9))
	_check(editor.data.spawns == [Vector2i(0, 4), Vector2i(19, 9)], "les terriers se posent au bord (%s)" % [editor.data.spawns])
	editor.click_cell(Vector2i(19, 9))
	_check(editor.data.spawns == [Vector2i(0, 4)], "un clic sur un terrier l'enlève")
	editor.set_tool(LevelEditor.EditTool.BASE)
	editor.click_cell(Vector2i(0, 4))
	editor.click_cell(Vector2i(17, 3))
	_check(editor.data.base == Vector2i(17, 3) and not editor.play_button.disabled, "le QG se pose, hors des terriers, et le niveau se joue")
	editor.set_tool(LevelEditor.EditTool.ROCKS)
	editor._painting_rocks = true
	editor.click_cell(Vector2i(17, 3))
	editor.click_cell(Vector2i(9, 4))
	_check(not editor.data.rocks.has(Vector2i(17, 3)) and editor.data.rocks.has(Vector2i(9, 4)), "pas de rocher sur le QG")
	editor.set_free(false)
	_check(editor.current_tool == LevelEditor.EditTool.PATH and editor.path_tool_button.visible
		and not editor.spawns_tool_button.visible, "revenir au chemin tracé")
	editor.set_free(true)
	var level_data: Dictionary = editor.data.duplicate(true)
	await _free(editor)
	# Jouer la carte libre.
	level_data.gold = 2000
	Engine.set_meta(Level.CUSTOM_META, level_data)
	var level := await _spawn_level(load(Level.EMPTY_LEVEL))
	_check(level.map.free_layout and level.map.paths.size() == 1 and level.map.base_cell == Vector2i(17, 3)
		and level.map.is_cell_blocked(Vector2i(9, 4)), "la carte libre se joue : terrier, QG et rochers")
	if level.is_choosing_towers:
		level.choose_towers(level.available_tower_types.slice(0, level.tower_limit))
	var before := _route_length(level.map)
	var on_route := Vector2i(-1, -1)
	for y in CustomLevel.ROWS:
		if on_route.x < 0 and level.map.is_cell_walked(Vector2i(8, y)):
			on_route = Vector2i(8, y)
	_check(level.place_tower(on_route, CANNON) != null and _route_length(level.map) > before, "une tour allonge le chemin")
	await _free(level)
	Progress.set_setting(CustomLevel.LEVELS_SETTING, [])


func _test_free_levels() -> void:
	print("Niveaux libres : chemin au plus court, les tours font les murs")
	var level := await _spawn_level(FREE_01)
	if level.is_choosing_towers:
		level.choose_towers(level.get_default_tower_choice())
	var map := level.map
	level.gold = 100000
	_check(map.free_layout and map.paths.size() == map.spawn_cells.size() and map.paths.size() == 1,
		"un chemin par point d'apparition")
	var curve := map.paths[0].curve
	var start := map.paths[0].to_global(curve.get_point_position(0))
	var end := map.paths[0].to_global(curve.get_point_position(curve.point_count - 1))
	_check(not map.is_cell_in_grid(map.world_to_cell(start)) and map.world_to_cell(end) == map.base_cell
		and map.get_base_position() == map.cell_to_world(map.base_cell),
		"les monstres arrivent du bord de l'écran et vont jusqu'au QG")
	_check(not map.is_cell_buildable(map.spawn_cells[0]) and not map.is_cell_buildable(map.base_cell)
		and map.is_cell_buildable(Vector2i(9, 4)), "seuls les points d'apparition et le QG sont réservés")
	# Un mur sur toute la hauteur : la dernière case qui laisse passer est refusée.
	var before := _route_length(map)
	var wall: Array[Tower] = []
	for y in map.rows:
		var tower := level.place_tower(Vector2i(12, y), CANNON)
		if tower:
			wall.append(tower)
	var gap := Vector2i(12, map.rows - 1)
	_check(wall.size() == map.rows - 1 and level.blocks_passage(gap) and not level.can_place_tower(gap, CANNON),
		"une tour qui fermerait le passage est refusée (%d tours posées)" % wall.size())
	_check(_route_length(map) > before and _curve_visits(map, map.paths[0].curve, gap),
		"le chemin fait le détour par la seule ouverture (%d → %d px)" % [before, _route_length(map)])
	# Aperçu : le chemin qu'auraient les monstres, et l'avertissement.
	var preview: PathPreview = level.get_node("PathPreview")
	level.placer.select(CANNON)
	level.placer._update_hover(map.cell_to_world(gap))
	_check(level.placer.passage_hint.visible and preview._candidate.is_empty() and not level.placer.preview.is_valid,
		"survoler la dernière ouverture affiche « Fermerait le passage »")
	level.placer._update_hover(map.cell_to_world(Vector2i(15, 2)))
	_check(not level.placer.passage_hint.visible and preview._candidate.size() == 1 and level.placer.preview.is_valid,
		"ailleurs, l'aperçu montre le chemin qu'auraient les monstres")
	level.placer.select(null)
	_check(preview._candidate.is_empty(), "l'aperçu du chemin s'efface quand on ne pose plus de tour")
	# Vendre une tour du mur rouvre le passage.
	var walled := _route_length(map)
	level.sell_tower(wall[map.rows / 2])
	_check(_route_length(map) < walled, "vendre une tour raccourcit le chemin")
	# Les volants vont tout droit.
	var flight := Enemy.get_flight_curve(map.paths[0])
	_check(flight.point_count == 2, "les volants vont tout droit au QG, par-dessus les tours")
	# Le trajet reste affiché pendant les vagues.
	level.start_next_wave()
	for i in 40:
		await process_frame
	_check(is_instance_valid(preview) and preview._alpha > 0.0, "le chemin reste affiché, plus discret, pendant les vagues")
	await _free(level)
	var flat := await _spawn_level(FREE_01, false)
	_check(flat.map.paths.size() == 1 and _route_length(flat.map) > 0.0, "un niveau libre se joue aussi en vue de dessus")
	await _free(flat)


func _test_free_level_enemies() -> void:
	print("Niveaux libres : les monstres changent de chemin quand le passage change")
	var level := await _spawn_level(FREE_01)
	var map := level.map
	level.gold = 100000
	# Assez solide pour traverser les tours posées pendant le test.
	var enemy := level.spawner.spawn(LARVE, map.paths[0], 260.0, 1000.0)
	enemy.lateral_offset = 0.0
	enemy._update_position()
	enemy.set_process(false)
	await process_frame
	var at := enemy.global_position
	var ahead := map.world_to_cell(enemy.get_route_position())
	var cell := Vector2i.ZERO
	# Une tour posée sur le chemin, quelques cases devant lui.
	var route_cells: Array[Vector2i] = []
	for point in enemy.get_route().get_baked_points():
		var c := map.world_to_cell(map.paths[0].to_global(point))
		if not route_cells.has(c):
			route_cells.append(c)
	cell = route_cells[mini(route_cells.find(ahead) + 3, route_cells.size() - 2)]
	var old_route := enemy.get_route()
	_check(level.place_tower(cell, CANNON) != null, "une tour sur le chemin d'un monstre peut être posée")
	_check(enemy.get_route() != old_route and not _curve_visits(map, enemy.get_route(), cell)
		and enemy.global_position.distance_to(at) < 1.0 and enemy.progress == 0.0,
		"le monstre prend un nouveau chemin, depuis là où il est, qui contourne la tour")
	# Un monstre ne peut pas être muré là où il marche.
	var walker := level.spawner.spawn(LARVE, map.paths[0], 0.0, 1.0, 1.0, -1,
		map.get_route_from(map.cell_to_world(Vector2i(7, 0))))
	walker.set_process(false)
	_check(level.place_tower(Vector2i(6, 0), CANNON) != null and level.place_tower(Vector2i(8, 0), CANNON) != null,
		"des tours autour d'un monstre")
	_check(level.blocks_passage(Vector2i(7, 1)) and level.place_tower(Vector2i(7, 1), CANNON) == null,
		"la tour qui l'enfermerait est refusée")
	# Il marche jusqu'au QG par le nouveau chemin.
	enemy.set_process(true)
	walker.queue_free()
	var lives := level.lives
	var elapsed := 0.0
	while is_instance_valid(enemy) and enemy.is_alive and elapsed < 60.0:
		elapsed += await _step()
	_check(level.lives < lives, "le monstre détourné atteint le QG")
	# Un monstre qui se divise : les petits suivent son trajet, pas le chemin du point d'apparition.
	var brood := level.spawner.spawn(COUVEUSE, map.paths[0], 0.0, 1.0, 1.0, -1,
		map.get_route_from(map.cell_to_world(Vector2i(16, 7))))
	brood.set_process(false)
	await process_frame
	var brood_at := brood.global_position
	var brood_id := brood.get_instance_id()
	brood.take_damage(100000.0, true)
	await process_frame
	var near := get_nodes_in_group(Enemy.GROUP).filter(func(node: Node) -> bool:
		return node.get_instance_id() != brood_id and node.is_alive and node.global_position.distance_to(brood_at) < 64.0)
	_check(not near.is_empty(), "les petits d'une Couveuse apparaissent là où elle est tombée (%d)" % near.size())
	await _free(level)


func _test_free_levels_progress() -> void:
	print("Niveaux libres : écran de choix, étoiles et niveau suivant")
	Progress.reset_campaign()
	_unlock_all_modes()
	var title: Control = TITLE_SCREEN.instantiate()
	root.add_child(title)
	await process_frame
	_check(title.get_play_buttons().has(title.get_node("%FreeButton")), "le bouton Niveaux libres est dans le menu Jouer")
	title.get_node("%FreeButton").pressed.emit()
	await process_frame
	await process_frame
	_check(current_scene and current_scene.scene_file_path == FreeLevels.SELECT_SCREEN,
		"le bouton Niveaux libres ouvre le choix des niveaux")
	if is_instance_valid(title):
		title.queue_free()
	if current_scene:
		current_scene.queue_free()
	await process_frame
	Progress.reset_campaign()
	var screen: Control = FREE_SELECT_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	_check(screen.play_buttons.size() == FreeLevels.size() and not screen.play_buttons[0].disabled
		and screen.play_buttons[1].disabled, "une carte par niveau, seul le premier ouvert")
	screen.queue_free()
	for path in FreeLevels.LEVELS:
		var scene: PackedScene = load(path)
		var level: Level = scene.instantiate()
		var map: GameMap = level.get_node("Map")
		var used := {}
		for wave in (level.get_node("WaveSpawner") as WaveSpawner).waves:
			for group in wave.groups:
				used[group.path_index] = true
		_check(map.free_layout and used.size() == map.spawn_cells.size() and map.tileset != null,
			"%s : les vagues partent de chaque point d'apparition" % level.level_name)
		level.free()
	var stars_before := Perks.get_earned_stars()
	var level := await _spawn_level(FREE_01)
	_check(level.get_next_level() == FreeLevels.LEVELS[1], "le niveau suivant est le deuxième niveau libre")
	level._end_game(true)
	_check(Progress.get_stars(FreeLevels.LEVELS[0]) == 3 and FreeLevels.is_unlocked(1)
		and Perks.get_earned_stars() == stars_before + 3, "la victoire donne des étoiles, qui comptent pour l'arbre, et ouvre le niveau suivant")
	await _free(level)
	Progress.reset_campaign()
