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
const LEXICON_SCREEN := preload("res://scenes/ui/lexicon_screen.tscn")
const ACHIEVEMENTS_SCREEN := preload("res://scenes/ui/achievements_screen.tscn")
const BEHEMOTH := preload("res://resources/enemies/mecha/behemoth.tres")

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
	await _test_perk_tree()
	await _test_perks_in_level()
	await _test_biome_towers_in_tree()
	await _test_sound()
	await _test_health_component()
	await _test_entity_despawn()
	await _test_tower_placement()
	await _test_tower_upgrade_stats()
	await _test_tower_upgrade_in_level()
	await _test_tower_info_panels()
	await _test_touch_controls()
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
	await _test_crossings_in_tree()
	await _test_tower_choice()
	await _test_worlds()
	await _test_spawn_spread()
	await _test_endless_mode()
	await _test_difficulties()
	await _test_specializations()
	await _test_konami_code()
	await _test_elites()
	await _test_bosses()
	await _test_detail_windows()
	await _test_lexicon()
	await _test_end_stats()
	await _test_achievements()
	await _test_biome_tiles()
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


## Joue une partie sans or bonus, comme un joueur prudent : les `tower_count` premières
## tours de `build_order` ([case, type] par tour) sont achetées dans l'ordre dès que l'or
## le permet, et chaque vague n'est lancée qu'une fois la carte vidée. La partie est
## libérée à la fin ; renvoie { won, lives, bought }.
func _play_build_order(scene: PackedScene, build_order: Array, tower_count: int,
		max_game_seconds := 1500.0) -> Dictionary:
	var level := await _spawn_level(scene)
	var bought := [0]
	await _play_until_over(level, max_game_seconds, true, func() -> void:
		while bought[0] < tower_count and level.gold >= build_order[bought[0]][1].get_cost():
			var item: Array = build_order[bought[0]]
			if level.place_tower(item[0], item[1]) == null:
				_check(false, "achat de la tour %d en %s" % [bought[0] + 1, item[0]])
			bought[0] += 1)
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
	_check(title.get_node("%WorldsButton").text == "Mondes", "le bouton Mondes ouvre la sélection")
	_check(title.get_node("%LexiconButton").text == "Lexique", "le bouton Lexique existe")
	_check(title.get_node("%PlayButton").text == "Jouer" and not title.get_node("%ResetButton").visible,
		"pas de progression à reprendre ni à effacer")
	await _free(title)
	await _test_title_demo()
	var screen := await _spawn_world_select()
	_check(screen.get_node("%Worlds").get_child_count() == 3, "une carte par monde")
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
	var screen := await _spawn_world_select()
	_check(screen.get_level_button(LEVEL_01.resource_path).text == "1-1\n★★☆"
		and not screen.get_level_button(LEVEL_02.resource_path).disabled,
		"la sélection montre les étoiles et le niveau débloqué")
	_check(screen.get_card(0).find_child("Stars", true, false).text == "★ 2 / 72", "la carte du monde compte ses étoiles")
	await _free(screen)
	var title := TITLE_SCREEN.instantiate()
	root.add_child(title)
	await process_frame
	_check(title.get_node("%PlayButton").text == "Continuer", "le bouton devient Continuer")
	_check(title.get_node("%WorldsButton").text.ends_with("★ 2 / 216"), "l'écran titre montre les étoiles de la campagne")
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
	var rouages := tree.get_perk("rouages")
	Perks.buy(longue_vue)
	_check(Perks.is_unlocked(rouages) and not Perks.can_buy(rouages) and Perks.get_available_stars() == 8 - poudre.cost - longue_vue.cost,
		"une amélioration trop chère ne s'achète pas")
	screen.get_node("%RefundButton").pressed.emit()
	_check(Perks.get_owned_ids().is_empty() and Perks.get_available_stars() == 8, "Réinitialiser l'arbre rend toutes les étoiles")
	_check(is_equal_approx(CANNON.get_stats_at_level(1).damage, 25.0), "et retire les bonus")
	Perks.buy(poudre)
	Progress.reset_campaign()
	_check(Perks.get_owned_ids().is_empty(), "Effacer la progression efface aussi les améliorations")
	await _free(screen)


func _test_perks_in_level() -> void:
	print("Arbre des améliorations : effets en jeu")
	_win_in_all_difficulties([LEVEL_01.resource_path, LEVEL_02.resource_path, LEVEL_03.resource_path])
	for id in ["tresor", "architecte", "brocanteur", "remparts", "infirmerie", "pillage"]:
		_check(Perks.buy(Perks.TREE.get_perk(id)), "achat : %s" % Perks.TREE.get_perk(id).display_name)
	var level := await _spawn_level(LEVEL_01)
	_check(level.gold == 200 and level.lives == 25 and level.starting_lives == 25,
		"Trésor de guerre et Remparts : 200 or et 25 vies au départ")
	_check(CANNON.get_cost() == 45 and CANNON.get_upgrade_cost(1) == 36, "Architecte : tours et améliorations 10 % moins chères")
	var tower := level.place_tower(Vector2i(2, 4), CANNON)
	_check(tower != null and level.gold == 155, "la pose coûte le prix réduit")
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
	var per_world := [0, 0, 0]
	for perk: Perk in tower_perks:
		if perk.required_world >= 0:
			per_world[perk.required_world] += 1
	_check(per_world == [2, 2, 2], "2 tours par monde (%s)" % [per_world])
	_check(tower_perks.all(func(p: Perk) -> bool: return tree.get_page(p) == 1 and p.get_unlocked_tower() != null),
		"elles sont toutes sur la page Tours des mondes")
	var campaign_stars := campaign.size() * Progress.MAX_LEVEL_STARS
	_check(tree.get_total_cost() <= campaign_stars and tree.get_total_cost() >= campaign_stars * 0.9,
		"l'arbre complet (%d étoiles) coûte presque toutes les étoiles de la campagne (%d)" % [tree.get_total_cost(), campaign_stars])
	_check(tree.get_total_cost() > campaign.size() * 3 * 3,
		"il faut des étoiles de Cauchemar pour tout acheter")

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
	_check(Perks.get_unlocked_towers().size() == 9, "les 9 tours achetées (6 des mondes, 3 croisements)")
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
		if not perk.get_power_path().is_empty():
			_check(Perks.buy(perk), "achat : %s" % perk.display_name)


func _test_powers_in_tree() -> void:
	print("Pouvoirs : arbre des améliorations")
	var tree := Perks.TREE
	var unlocks := tree.perks.filter(func(p: Perk) -> bool: return not p.unlocks_power.is_empty())
	var on_page := unlocks.all(func(p: Perk) -> bool: return tree.get_page(p) == 3 and not p.paid_with_endless_stars)
	_check(unlocks.size() == 3 and on_page, "3 pouvoirs, payés en étoiles, sur la page Pouvoirs")
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
	_check(level.available_tower_types.size() == 15 and level.is_choosing_towers and level.hud.tower_picker != null,
		"avec 15 tours débloquées, le niveau s'ouvre sur le choix des tours")
	_check(level.tower_types.is_empty() and level.hud.tower_shop.get_child_count() == 0 and not level.can_start_next_wave(),
		"pas de tour à poser ni de vague avant d'avoir choisi")
	var picker := level.hud.tower_picker
	_check(picker.get_selected() == level.available_tower_types.slice(0, 5), "5 tours cochées d'avance : celles du niveau d'abord")
	_check(picker.get_button(ARC).disabled, "une fois 5 tours cochées, les autres sont grisées")
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
	print("Mondes : trois biomes de 6 niveaux, débloqués l'un après l'autre")
	var campaign: Campaign = load("res://resources/campaign.tres")
	_check(campaign.worlds.size() == 3 and campaign.worlds.all(func(w: World) -> bool: return w.levels.size() == 6),
		"3 mondes de 6 niveaux")
	_check(campaign.size() == 18 and campaign.levels[0] == LEVEL_01.resource_path, "la campagne commence au niveau 1-1")
	_check(campaign.get_next(LEVEL_06.resource_path) == MECHA_01.resource_path, "après le niveau 1-6 vient le 2-1")
	_check(campaign.get_next(campaign.worlds[2].levels[5]) == "", "le niveau 3-6 est le dernier")
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
	var level := await _spawn_level(LEVEL_06)
	_check(level.get_next_world_name() == "La Fonderie", "le niveau 1-6 ouvre La Fonderie")
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
	_check(screen.get_card(0).find_child("Stars", true, false).text.contains("0 / 30"), "la carte compte les étoiles infinies du monde")
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
	_check(Perks.get_earned_stars(true) == 1 and Perks.get_earned_stars() == 3, "les étoiles infinies sont une monnaie à part")
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
	_check(screen.get_card(0).find_child("Stars", true, false).text == "★ 6 / 72", "la carte compte les étoiles des 4 difficultés")
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
	_check(Perks.get_earned_stars() == campaign.size() * Progress.MAX_LEVEL_STARS and Progress.is_world_unlocked(campaign, 2),
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
	_check(title.get_node("%PlayButton").text == "Continuer" and announced, "l'écran titre se met à jour et l'annonce")
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
	_check(Perks.get_earned_stars() == campaign.size() * Progress.MAX_LEVEL_STARS, "les flèches du pavé numérique et le A d'un clavier QWERTY comptent")
	_check(not title._konami_label.visible, "les pastilles disparaissent une fois le code entré")
	await _free(title)
	Progress.reset_campaign()


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
		_check(boss_levels == [3, 6], "%s : un boss tous les 3 niveaux (%s)" % [world.display_name, boss_levels])
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
	_check(names.size() == 20 and names[0] == "Élites" and names.any(func(n: String) -> bool: return n.contains("Béhémoth")),
		"onglet Monstres : les élites, les 16 monstres et les 3 boss")
	var general: Button = screen.get_entry_buttons().filter(func(b: Button) -> bool: return b.text.contains("Général"))[0]
	general.pressed.emit()
	_check(screen.detail_text.get_parsed_text().contains("Soldats en renfort"), "la fiche d'un boss donne ses capacités")
	screen.show_tab(2)
	_check(screen.get_entry_buttons().size() == 3 and screen.detail_text.get_parsed_text().contains("Reine de la Ruche"),
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
	await _free(level)


func _test_achievements() -> void:
	print("Succès")
	# Progression à part : les succès débloqués par les autres tests ne comptent pas.
	var save_path := Progress.get_save_path()
	Engine.set_meta(Progress.SAVE_PATH_META, "user://test_achievements.cfg")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Progress.get_save_path()))
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
	Engine.set_meta(Progress.SAVE_PATH_META, save_path)


func _test_biome_tiles() -> void:
	print("Tuiles des biomes sur les cartes")
	var campaign: Campaign = load("res://resources/campaign.tres")
	_check(campaign.worlds.all(func(w: World) -> bool: return w.tileset != null), "chaque monde a ses tuiles")
	var level := await _spawn_level(LEVEL_01)
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
	level = await _spawn_level(LEVEL_01)
	_check(_ground_tiles(level.map.get_node("Sol")) == first, "la même carte à chaque partie")
	await _free(level)
	level = await _spawn_level(MECHA_01)
	_check(level.map.tileset == campaign.worlds[1].tileset, "La Fonderie a les siennes")
	await _free(level)


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
func _check_build_order_balance(scene: PackedScene, build_order: Array) -> void:
	var small := await _play_build_order(scene, build_order, 6)
	_check(not small.won and small.lives == 0, "perdu avec 6 tours seulement")
	var full := await _play_build_order(scene, build_order, build_order.size())
	_check(full.won, "la partie est gagnée (vies restantes : %d, tours achetées : %d)" % [full.lives, full.bought])


func _test_levels_04_to_06_maps() -> void:
	print("Niveaux 4 à 6 : cartes")
	var expected := [
		[LEVEL_04, "Niveau 1-4", 1, 8, LEVEL_05], [LEVEL_05, "Niveau 1-5", 3, 8, LEVEL_06], [LEVEL_06, "Niveau 1-6", 1, 10, MECHA_01],
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


## Ordres de construction des mondes 2 et 3 pour l'équilibrage (18 tours par niveau).
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
}


func _test_world_levels_maps() -> void:
	print("Mondes 2 et 3 : cartes")
	var campaign: Campaign = load("res://resources/campaign.tres")
	for w in [1, 2]:
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
		print("%s : gagnable avec l'or gagné, mais pas avec une petite défense" % level.level_name)
		level.free()
		await _check_build_order_balance(scene, WORLD_BUILD_ORDERS[path])
