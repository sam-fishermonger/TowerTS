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
const CHENILLARD := preload("res://resources/enemies/mecha/chenillard.tres")
const LARVE := preload("res://resources/enemies/insectoid/larve.tres")
const SCARABEE := preload("res://resources/enemies/insectoid/scarabee.tres")
const COUVEUSE := preload("res://resources/enemies/insectoid/couveuse.tres")
const SENTINELLE := preload("res://resources/enemies/mecha/sentinelle.tres")
const SOLDAT := preload("res://resources/enemies/humanoid/soldat.tres")
const MEDECIN := preload("res://resources/enemies/humanoid/medecin.tres")

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
	await _test_worlds()
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
	_check(title.get_node("%PlayButton").text == "Jouer" and not title.get_node("%ResetButton").visible,
		"pas de progression à reprendre ni à effacer")
	await _free(title)
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
	_check(screen.get_card(0).find_child("Stars", true, false).text == "★ 2 / 18", "la carte du monde compte ses étoiles")
	await _free(screen)
	var title := TITLE_SCREEN.instantiate()
	root.add_child(title)
	await process_frame
	_check(title.get_node("%PlayButton").text == "Continuer", "le bouton devient Continuer")
	_check(title.get_node("%WorldsButton").text.ends_with("★ 2 / 54"), "l'écran titre montre les étoiles de la campagne")
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
	Progress.record_victory(LEVEL_02.resource_path, 2)
	_check(Perks.get_earned_stars() == 5 and Perks.get_available_stars() == 5, "les étoiles des niveaux gagnés sont la monnaie")

	var title := TITLE_SCREEN.instantiate()
	root.add_child(title)
	await process_frame
	_check(title.get_node("%PerksButton").text.ends_with("★ 5"), "l'écran titre signale les étoiles à dépenser")
	await _free(title)

	var screen := PERK_TREE_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	_check(screen.get_button(longue_vue).text.ends_with("Verrouillé"), "Longue-vue est verrouillée tant que Poudre fine n'est pas achetée")
	screen.get_button(longue_vue).pressed.emit()
	_check(not Perks.is_owned(longue_vue), "une amélioration verrouillée ne s'achète pas")
	_check(screen.info_status.text.contains("Poudre fine"), "la fiche dit ce qui manque")
	screen.get_button(poudre).pressed.emit()
	_check(Perks.is_owned(poudre) and Perks.get_available_stars() == 4, "acheter Poudre fine coûte 1 étoile")
	_check(screen.get_button(poudre).text.ends_with("Acquis") and screen.get_button(longue_vue).text.ends_with("★ 1"),
		"Poudre fine est acquise et débloque Longue-vue")
	_check(screen.stars_label.text.begins_with("★ 4 à dépenser"), "le compteur d'étoiles se met à jour")
	_check(not screen.buy(poudre), "une amélioration ne s'achète qu'une fois")
	_check(is_equal_approx(CANNON.get_stats_at_level(1).damage, 25.0 * 1.1), "Poudre fine : +10 % de dégâts sur les tours")
	var artilleur := tree.get_perk("artilleur")
	Perks.buy(longue_vue)
	Perks.buy(tree.get_perk("rouages"))
	_check(Perks.is_unlocked(artilleur) and not Perks.can_buy(artilleur) and Perks.get_available_stars() == 1,
		"une amélioration trop chère ne s'achète pas")
	screen.get_node("%RefundButton").pressed.emit()
	_check(Perks.get_owned_ids().is_empty() and Perks.get_available_stars() == 5, "Réinitialiser l'arbre rend toutes les étoiles")
	_check(is_equal_approx(CANNON.get_stats_at_level(1).damage, 25.0), "et retire les bonus")
	Perks.buy(poudre)
	Progress.reset_campaign()
	_check(Perks.get_owned_ids().is_empty(), "Effacer la progression efface aussi les améliorations")
	await _free(screen)


func _test_perks_in_level() -> void:
	print("Arbre des améliorations : effets en jeu")
	Progress.record_victory(LEVEL_01.resource_path, 3)
	Progress.record_victory(LEVEL_02.resource_path, 3)
	Progress.record_victory(LEVEL_03.resource_path, 3)
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


func _test_biome_towers_in_tree() -> void:
	print("Arbre des améliorations : tours des mondes")
	var campaign: Campaign = load("res://resources/campaign.tres")
	var tree := Perks.TREE
	var tower_perks := tree.perks.filter(func(p: Perk) -> bool: return not p.unlocks_tower.is_empty())
	var per_world := [0, 0, 0]
	for perk: Perk in tower_perks:
		per_world[perk.required_world] += 1
	_check(per_world == [2, 2, 2], "2 tours par monde (%s)" % [per_world])
	_check(tower_perks.all(func(p: Perk) -> bool: return tree.get_page(p) == 1 and p.get_unlocked_tower() != null),
		"elles sont toutes sur la page Tours des mondes")
	var campaign_stars := campaign.size() * 3
	_check(tree.get_total_cost() <= campaign_stars and tree.get_total_cost() >= campaign_stars - 3,
		"l'arbre complet (%d étoiles) coûte presque toutes les étoiles de la campagne (%d)" % [tree.get_total_cost(), campaign_stars])

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

	for world in campaign.worlds:
		for path in world.levels:
			Progress.record_victory(path, 3)
	for perk: Perk in tower_perks:
		Perks.buy(perk)
	_check(Perks.get_unlocked_towers().size() == 6, "les 6 tours achetées")
	level = await _spawn_level(HUMANOID_01)
	await process_frame
	_check(level.tower_types.size() == 12 and level.hud.tower_shop.get_child_count() == 12, "12 tours dans la barre d'achat")
	var bar := level.hud.bottom_bar.get_global_rect()
	var controls := level.hud.pause_button.get_global_rect()
	var last_slot: Control = level.hud.tower_shop.get_child(11)
	_check(is_equal_approx(bar.size.y, 96.0) and bar.end.x <= 1280.0 and last_slot.get_global_rect().end.x < controls.position.x,
		"elles tiennent dans la barre, sans pousser les boutons de droite")
	_check(not level.hud.shop_hint.visible, "le rappel des commandes laisse sa place")
	await _free(level)
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
	var title := TITLE_SCREEN.instantiate()
	root.add_child(title)
	await process_frame
	var music_button: Button = title.get_node("%AudioToggles").music_button
	music_button.button_pressed = false
	_check(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Music")) and music_button.text == "Musique : non",
		"le bouton Musique coupe la musique")
	_check(Progress.get_setting("music", true) == false, "le choix est enregistré")
	music_button.button_pressed = true
	_check(not AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Music")), "et la remet")
	var sound_button: Button = title.get_node("%AudioToggles").sound_button
	sound_button.button_pressed = false
	_check(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Sfx")), "le bouton Sons coupe les effets")
	sound_button.button_pressed = true
	await _free(title)

	# Les mêmes réglages en jeu, dans la barre du bas, même pendant la pause.
	var level := await _spawn_level(LEVEL_01)
	var toggles := level.hud.audio_toggles
	_check(toggles.is_visible_in_tree() and toggles.music_button.button_pressed and toggles.sound_button.button_pressed,
		"en jeu : boutons Musique et Sons, à oui")
	level.set_paused(true)
	toggles.music_button.button_pressed = false
	toggles.sound_button.button_pressed = false
	_check(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Music"))
		and AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Sfx")), "en jeu et en pause, ils coupent musique et sons")
	_check(toggles.music_button.text == "Musique : non" and toggles.sound_button.text == "Sons : non",
		"les boutons affichent l'état")
	await _free(level)
	title = TITLE_SCREEN.instantiate()
	root.add_child(title)
	await process_frame
	_check(not title.get_node("%AudioToggles").music_button.button_pressed, "l'écran titre reprend le réglage choisi en jeu")
	Sound.set_music_enabled(true)
	Sound.set_sound_enabled(true)
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
	_check(level.gold == gold_before + rewards + bonuses,
		"les bonus des deux vagues sont versés (%d or attendus, %d reçus)" % [rewards + bonuses, level.gold - gold_before])
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
					if not world.enemies.has(group.enemy):
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
