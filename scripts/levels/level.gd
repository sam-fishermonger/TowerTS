class_name Level
extends Node2D
## Niveau jouable : relie la carte, les vagues, le placement des tours et le HUD,
## et tient l'économie de la partie (or, vies) jusqu'à la victoire ou la défaite.

signal game_over(victory: bool)

const TITLE_SCREEN := "res://scenes/ui/title_screen.tscn"
const DAMAGE_TEXT_COLOR := Color(1.0, 0.92, 0.85)
const GOLD_TEXT_COLOR := Color(1.0, 0.82, 0.25)
const LIVES_LOST_TEXT_COLOR := Color(1.0, 0.3, 0.3)
const HEAL_TEXT_COLOR := Color(0.45, 1.0, 0.55)
## Butin d'un porteur (Loot) : or d'un tas (au moins LOOT_MIN_GOLD, sinon
## LOOT_GOLD_PER_REWARD fois l'or du monstre), pierre et essence en Conquête.
const LOOT_MIN_GOLD := 15
const LOOT_GOLD_PER_REWARD := 3
const LOOT_STONE := 15
const LOOT_ESSENCE := 4
## Méta du moteur posée juste avant d'ouvrir un niveau en mode infini (voir open()) :
## le niveau la lit et l'efface à son lancement.
const ENDLESS_META := &"level_endless"
## Réglage (Progress) qui garde le dernier choix de tours (chemins des TowerData) : il est
## coché d'avance au lancement du niveau suivant.
const TOWER_CHOICE_SETTING := "tower_choice"
## Méta du moteur posée juste avant d'ouvrir le défi du jour (voir open_challenge()) :
## le jour du défi (« 2026-10-06 »), lu et effacé au lancement du niveau.
const CHALLENGE_META := &"level_challenge"
## Méta du moteur posée juste avant d'ouvrir un niveau de l'éditeur (voir open_custom()) :
## son dictionnaire (CustomLevel), lu et effacé quand la scène de niveau vide entre dans l'arbre.
const CUSTOM_META := &"level_custom"
const EMPTY_LEVEL := "res://scenes/levels/level.tscn"
const LEVEL_EDITOR := "res://scenes/ui/level_editor.tscn"

@export var level_name := "Niveau"
## Or et vies de départ, sans les bonus de l'arbre des améliorations (ajoutés au lancement).
@export var starting_gold := 150
@export var starting_lives := 20
@export var tower_types: Array[TowerData] = []
## Campagne dont fait partie le niveau : elle donne le niveau suivant.
@export var campaign: Campaign
## Lancer une vague avant d'avoir vidé la carte rapporte cette part de son bonus, en plus.
@export_range(0.0, 1.0) var early_call_bonus_ratio := 0.5
## Vitesses de jeu proposées dans le HUD. La première est celle du début de partie.
@export var game_speeds: Array[float] = [1.0, 2.0, 3.0]
## Intérêts : chaque fois que la carte est vidée, l'or gardé rapporte cette part en plus
## du bonus de vague, sans dépasser `interest_cap`.
@export_range(0.0, 0.5) var interest_rate := 0.05
@export var interest_cap := 25

@export_group("Conquête")
## Mode Conquête (voir Conquest) : les tours coûtent aussi de la pierre, minée par des
## ouvriers qui les bâtissent, des bâtiments s'ajoutent et les vagues partent seules.
## Ses niveaux ont leurs propres étoiles (ConquestLevels).
@export var conquest_mode := false
## Tutoriel (voir Tutorial) : des bulles guident le joueur pas à pas. Il se joue en Moyen,
## sans l'arbre des améliorations ni choix des tours, ne compte ni pour la progression ni
## pour les succès, et ouvre ensuite le premier niveau de la campagne.
@export var is_tutorial := false
## Filons d'essence de la carte (des cases bloquées, à miner ou à couvrir d'un Extracteur).
@export var essence_cells: Array[Vector2i] = []
@export var conquest_starting_stone := 40
@export var conquest_starting_workers := 3
## Pillards ajoutés aux vagues : le monstre, et combien dans chaque vague (dans l'ordre
## des vagues ; aucun au-delà de la liste). La difficulté change leur nombre.
@export var raider: EnemyData
@export var raiders_per_wave: Array[int] = []

var gold := 0:
	set(value):
		gold = value
		_refresh_hud()
var lives := 0:
	set(value):
		lives = maxi(value, 0)
		_refresh_hud()
var is_over := false
## Mise en pause par le joueur (la fin de partie met aussi l'arbre en pause, sans passer par là).
## Pendant la pause, le joueur peut construire, améliorer et vendre (le TowerPlacer et le HUD
## ne sont pas mis en pause), mais pas lancer de vague.
var is_paused := false
var game_speed := 1.0
## Pause choisie par le joueur avant d'ouvrir le menu Options.
var _paused_before_options := false
## Partie jouée toute seule derrière l'écran titre (TitleDemo), à régler avant l'ajout
## à l'arbre : pas de HUD ni de commandes, rien d'enregistré, et pas de pause à la fin.
var is_demo := false
## Mode infini : après les vagues du niveau, d'autres vagues, de plus en plus dures,
## arrivent sans fin. La partie se termine quand les vies tombent à 0, et chaque vague
## repoussée compte pour le record et les étoiles infinies du niveau.
var is_endless := false
## Difficulté de la partie (Difficulty) : celle choisie par le joueur, lue au lancement,
## sauf en mode infini et pour la partie de l'écran titre, toujours en Moyen.
var difficulty := Difficulty.DEFAULT
## Tours différentes qu'on peut prendre dans ce niveau (0 = pas de limite : partie de
## l'écran titre). Avec plus de tours disponibles, le joueur les choisit au lancement.
var tower_limit := 0
## Toutes les tours disponibles : celles du niveau, puis celles débloquées dans l'arbre.
## tower_types ne garde que celles choisies.
var available_tower_types: Array[TowerData] = []
## Le choix des tours est ouvert : pas de vague tant qu'il n'est pas validé.
var is_choosing_towers := false
## Défi du jour joué sur ce niveau (null sinon) : ses règles remplacent les tours du
## niveau, l'arbre des améliorations et la difficulté (Moyen), et la partie compte un score.
var challenge: DailyChallenge
## Défi du jour : points marqués jusqu'ici (voir DailyChallenge).
var score := 0
## Mutateurs actifs (règles du défi, voir Mutators) : seulement sur un niveau de la
## campagne déjà gagné, hors mode infini. Ils s'ajoutent à la difficulté, et la victoire
## rapporte des étoiles infinies.
var mutators: Array[int] = []
## Niveau fait dans l'éditeur (vide sinon, voir CustomLevel) : il ne compte ni pour la
## progression ni pour les succès, et la partie finie ramène à l'éditeur.
var custom_level: Dictionary = {}
## Statistiques de la partie, affichées sur l'écran de fin.
var stats := LevelStats.new()
## Succès débloqués pendant la partie (identifiants, voir Achievements).
var unlocked_achievements: Array[String] = []
## Pouvoirs actifs débloqués dans l'arbre des améliorations (aucun pour la partie de
## l'écran titre), et les secondes de recharge restantes de chacun (0 = prêt).
var powers: Array[Power] = []
var power_cooldowns: Array[float] = []
## Mode Conquête : ses ouvriers, sa pierre et ses rochers (null hors de ce mode).
var conquest: Conquest
## Bulles du tutoriel (null hors du tutoriel).
var tutorial: Tutorial
## Bonus des coffres gagnés pendant la partie : nombre d'exemplaires par identifiant
## (ChestBonus), dans l'ordre où ils sont tombés.
var chest_levels := {}

var _wave_bonus_paid := -1
## Ennemis tombés qui vont se relever (EnemyData.revive_count) : la vague n'est pas
## finie tant qu'il en reste.
var _pending_revives := 0
## Mode infini : record de vagues du niveau au lancement de la partie.
var _endless_record_before := 0
## Bonus de l'arbre des améliorations, lus au lancement : ils ne changent pas en cours de partie.
var _bonuses: Perk
## Monstres et élites détruits déjà ajoutés aux compteurs des succès.
var _counted_kills := 0
var _counted_elite_kills := 0
## Tirage des bonus des coffres (graine du niveau : une partie rejouée de la même façon
## donne les mêmes bonus).
var _chest_rng := RandomNumberGenerator.new()

@onready var map: GameMap = $Map
@onready var stains: Node2D = $Stains
@onready var enemies: Node2D = $Enemies
## Soldats des renforts.
@onready var allies: Node2D = $Allies
@onready var towers: Node2D = $Towers
@onready var projectiles: Node2D = $Projectiles
## Textes flottants (dégâts, or gagné), dessinés au-dessus des ennemis et des tirs.
@onready var effects: Node2D = $Effects
@onready var placer: TowerPlacer = $TowerPlacer
@onready var spawner: WaveSpawner = $WaveSpawner
@onready var hud: Hud = $HUD


## Ouvre un niveau, en mode infini ou non.
static func open(tree: SceneTree, path: String, endless := false) -> void:
	if endless:
		Engine.set_meta(ENDLESS_META, true)
	tree.change_scene_to_file(path)


## Ouvre le défi du jour sur son niveau.
static func open_challenge(tree: SceneTree, daily: DailyChallenge) -> void:
	Engine.set_meta(CHALLENGE_META, daily.date_key)
	tree.change_scene_to_file(daily.level_path)


## Ouvre un niveau de l'éditeur (dictionnaire de CustomLevel) dans la scène de niveau vide.
static func open_custom(tree: SceneTree, data: Dictionary) -> void:
	Engine.set_meta(CUSTOM_META, data.duplicate(true))
	tree.change_scene_to_file(EMPTY_LEVEL)


func _enter_tree() -> void:
	# La carte et les vagues d'un niveau de l'éditeur sont posées avant que la carte se
	# prépare (elle lit ses chemins dans son _ready, appelé avant celui du niveau).
	if Engine.has_meta(CUSTOM_META) and custom_level.is_empty() and not is_node_ready():
		custom_level = Engine.get_meta(CUSTOM_META)
		Engine.remove_meta(CUSTOM_META)
		CustomLevel.apply(self, custom_level)


## Les succès comptent dans les parties de la campagne, du mode infini, du défi et de la
## Conquête, mais pas dans la partie de l'écran titre ni dans les niveaux de l'éditeur.
func counts_achievements() -> bool:
	return not is_demo and custom_level.is_empty() and not is_tutorial


func _ready() -> void:
	if Engine.has_meta(ENDLESS_META):
		is_endless = Engine.get_meta(ENDLESS_META)
		Engine.remove_meta(ENDLESS_META)
	if Engine.has_meta(CHALLENGE_META):
		challenge = DailyChallenge.for_date(Engine.get_meta(CHALLENGE_META))
		Engine.remove_meta(CHALLENGE_META)
		is_endless = false
		# L'arbre des améliorations ne compte pas pendant le défi (voir _exit_tree()).
		Engine.set_meta(Perks.DISABLED_META, true)
	if is_tutorial:
		is_endless = false
		# Comme pendant le défi, l'arbre des améliorations ne compte pas (voir _exit_tree()).
		Engine.set_meta(Perks.DISABLED_META, true)
	spawner.endless = is_endless
	spawner.carriers = not is_tutorial
	_chest_rng.seed = hash(scene_file_path + "/coffres")
	if not is_endless and not is_demo and not challenge and not is_tutorial:
		difficulty = Difficulty.get_current()
		if custom_level.is_empty() and not conquest_mode and Mutators.applies_to(campaign, scene_file_path):
			mutators = Mutators.get_active()
	if challenge:
		spawner.apply_modifiers(challenge.get_health_multiplier(), challenge.get_count_multiplier(),
			challenge.get_speed_multiplier())
	elif not mutators.is_empty():
		spawner.apply_modifiers(Difficulty.HEALTH[difficulty] * DailyChallenge.health_multiplier_of(mutators),
			Difficulty.ENEMY_COUNT[difficulty] * DailyChallenge.count_multiplier_of(mutators),
			Difficulty.SPEED[difficulty] * DailyChallenge.speed_multiplier_of(mutators))
	elif difficulty != Difficulty.MOYEN:
		spawner.apply_difficulty(difficulty)
	# La carte prend les tuiles du biome de son monde, si elle n'en a pas.
	var world := campaign.world_index_of(scene_file_path) if campaign else -1
	if world >= 0 and map.tileset == null:
		map.tileset = campaign.worlds[world].tileset
	if is_endless:
		_endless_record_before = Progress.get_endless_waves(scene_file_path)
	placer.level = self
	if map.free_layout:
		map.layout_changed.connect(_reroute_enemies)
	if map.relief:
		_setup_relief()
	if conquest_mode and not is_demo:
		conquest = Conquest.new()
		conquest.name = "Conquest"
		add_child(conquest)
		move_child(conquest, towers.get_index() + 1)
		conquest.setup(self)
		spawner.loot_kinds = [Loot.Kind.GOLD, Loot.Kind.STONE, Loot.Kind.ESSENCE]
	# Les tours débloquées dans l'arbre des améliorations s'ajoutent à celles du niveau.
	var types := tower_types.duplicate()
	for data in Perks.get_unlocked_towers():
		if not types.has(data):
			types.append(data)
	if challenge:
		types = challenge.get_towers()
	available_tower_types = types
	tower_limit = 0 if is_demo or challenge or is_tutorial else Difficulty.TOWER_LIMITS[difficulty]
	is_choosing_towers = tower_limit > 0 and types.size() > tower_limit
	if is_choosing_towers:
		tower_types = []
	else:
		tower_types = types
	placer.selection_changed.connect(hud.set_selected_tower)
	placer.inspection_changed.connect(hud.show_tower_details)
	if conquest:
		# Avant la barre d'achat : elle laisse de la place au bouton des bâtiments.
		hud.setup_conquest(Conquest.WORKER_COST, Conquest.stone_cost, Conquest.upgrade_essence_cost)
		hud.recruit_requested.connect(conquest.recruit)
		hud.building_selected.connect(select_building)
		hud.demolish_requested.connect(conquest.sell_building)
		hud.building_details_closed.connect(placer.inspect_building.bind(null))
		placer.building_selection_changed.connect(hud.set_selected_building)
		placer.building_inspection_changed.connect(hud.show_building_details)
		hud.research_requested.connect(conquest.start_research)
		hud.workers_select_all.connect(conquest.toggle_all_workers)
		hud.workers_sent_home.connect(conquest.send_selected_home)
		hud.workers_released.connect(conquest.release_selected)
		hud.workers_deselected.connect(conquest.clear_selection)
		conquest.selection_changed.connect(func() -> void:
			hud.show_worker_selection(conquest.get_selected_workers().size()))
		conquest.changed.connect(_refresh_hud)
	hud.setup(get_title(), tower_types, game_speeds)
	if not custom_level.is_empty():
		hud.set_menu_button_text("Retour à l'éditeur")
	if is_choosing_towers:
		hud.show_tower_picker(types, tower_limit, get_default_tower_choice(), Difficulty.NAMES[difficulty])
		hud.towers_chosen.connect(choose_towers)
	hud.enemy_speed_multiplier = spawner.speed_multiplier
	if is_demo:
		hud.visible = false
		hud.process_mode = Node.PROCESS_MODE_DISABLED
		placer.process_mode = Node.PROCESS_MODE_DISABLED
	hud.pause_toggled.connect(func() -> void: set_paused(not is_paused))
	hud.game_speed_selected.connect(set_game_speed)
	hud.options_toggled.connect(_on_options_toggled)
	hud.tower_selected.connect(select_tower)
	hud.next_wave_requested.connect(start_next_wave)
	hud.upgrade_requested.connect(upgrade_tower)
	hud.sell_requested.connect(sell_tower)
	hud.tower_details_closed.connect(inspect_tower.bind(null))
	hud.restart_requested.connect(_on_restart_requested)
	hud.next_level_requested.connect(_on_next_level_requested)
	hud.menu_requested.connect(_on_menu_requested)
	hud.power_selected.connect(select_power)
	placer.power_selection_changed.connect(hud.set_selected_power)
	spawner.enemy_spawned.connect(_on_enemy_spawned)
	spawner.wave_started.connect(func(_index: int) -> void: _refresh_hud())
	spawner.wave_spawning_finished.connect(func(_index: int) -> void: _check_wave_cleared())
	# Les bonus de l'arbre des améliorations comptent comme des vies de départ : les
	# étoiles se calculent sur ce total.
	_bonuses = Perks.get_bonuses()
	starting_gold += _bonuses.starting_gold_bonus
	starting_lives += _bonuses.lives_bonus
	if not is_demo:
		for power in Perks.get_powers():
			powers.append(power)
	power_cooldowns.resize(powers.size())
	power_cooldowns.fill(0.0)
	hud.setup_powers(powers)
	hud.set_interest_rules(get_interest_rate(), get_interest_cap())
	if challenge:
		starting_gold = challenge.get_starting_gold(starting_gold)
		starting_lives = challenge.get_starting_lives(starting_lives)
		hud.show_challenge_rules(challenge.describe_rules())
	elif not mutators.is_empty():
		starting_gold = DailyChallenge.starting_gold_of(mutators, starting_gold)
		starting_lives = DailyChallenge.starting_lives_of(mutators, starting_lives)
		hud.show_mutator_rules(Mutators.describe(mutators), Mutators.stars_for(mutators),
			Progress.get_mutator_stars(scene_file_path), not is_choosing_towers)
	gold = starting_gold
	lives = starting_lives
	# La démo de l'écran titre garde sa vitesse ; une partie démarre à celle des options.
	if is_demo:
		set_game_speed(game_speeds[0] if not game_speeds.is_empty() else 1.0)
	else:
		set_game_speed(GameSettings.pick_start_speed(game_speeds))
	if is_tutorial and not is_demo:
		tutorial = Tutorial.new()
		add_child(tutorial)
		tutorial.setup(self)
	Sound.play_music()


## Vue de trois quarts : les tours, les monstres, les alliés et le décor sont triés en
## profondeur (ce qui est plus bas sur l'écran passe devant) ; les tirs, les effets et
## l'aperçu de pose restent par-dessus.
func _setup_relief() -> void:
	y_sort_enabled = true
	for container in [enemies, allies, towers]:
		container.y_sort_enabled = true
	projectiles.z_index = 2
	effects.z_index = 2
	placer.z_index = 3
	var decor := Node2D.new()
	decor.name = "Decor"
	decor.y_sort_enabled = true
	add_child(decor)
	move_child(decor, towers.get_index())
	map.populate_decor(decor)


## Titre du niveau dans la barre du haut, avec le mode ou la difficulté (traduit).
func get_title() -> String:
	if is_tutorial:
		return tr(level_name)
	if challenge:
		return tr("Défi du jour  ·  %s") % tr(level_name)
	if is_endless:
		return tr("%s  ·  Mode infini") % tr(level_name)
	if not mutators.is_empty():
		return "%s  ·  %s  ·  ✦ %d" % [tr(level_name), tr(Difficulty.NAMES[difficulty]), mutators.size()]
	return "%s  ·  %s" % [tr(level_name), tr(Difficulty.NAMES[difficulty])]


## Changement de langue (menu Options en jeu) : le titre est composé, le HUD refait le reste.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		hud.level_label.text = get_title()


func _exit_tree() -> void:
	# La vitesse est globale au moteur : on la remet à x1 en quittant le niveau.
	Engine.time_scale = 1.0
	if (challenge or is_tutorial) and Engine.has_meta(Perks.DISABLED_META):
		Engine.remove_meta(Perks.DISABLED_META)


## Niveau proposé après une victoire ("" = dernier niveau).
func get_next_level() -> String:
	if is_tutorial:
		return campaign.levels[0] if campaign and campaign.size() > 0 else ""
	if conquest_mode:
		return ConquestLevels.get_next(scene_file_path)
	if FreeLevels.has(scene_file_path):
		return FreeLevels.get_next(scene_file_path)
	return campaign.get_next(scene_file_path) if campaign and not challenge and custom_level.is_empty() else ""


func has_next_level() -> bool:
	return not get_next_level().is_empty()


## Nom du monde suivant si ce niveau est le dernier de son monde, "" sinon.
func get_next_world_name() -> String:
	if not campaign or not has_next_level():
		return ""
	var world := campaign.world_index_of(scene_file_path)
	var next_world := campaign.world_index_of(get_next_level())
	return campaign.worlds[next_world].display_name if next_world != world else ""


## Vagues repoussées jusqu'ici (toutes celles dont le bonus a été versé).
func get_waves_cleared() -> int:
	return _wave_bonus_paid + 1


## Mode infini : étoiles infinies méritées avec les vagues repoussées jusqu'ici.
func get_endless_stars() -> int:
	return Progress.endless_stars_for(get_waves_cleared() - spawner.get_wave_count())


## Étoiles méritées si la partie était gagnée maintenant.
func get_stars() -> int:
	return Progress.stars_for(lives, starting_lives)


# --- Tours ------------------------------------------------------------------

## Tours cochées d'avance dans le choix des tours : celles du dernier choix qui sont
## disponibles, complétées dans l'ordre (tours du niveau d'abord) jusqu'à la limite.
func get_default_tower_choice() -> Array[TowerData]:
	var last: PackedStringArray = Progress.get_setting(TOWER_CHOICE_SETTING, PackedStringArray())
	var result: Array[TowerData] = []
	for data in available_tower_types:
		if last.has(data.resource_path) and result.size() < tower_limit:
			result.append(data)
	for data in available_tower_types:
		if not result.has(data) and result.size() < tower_limit:
			result.append(data)
	return result


## Valide le choix des tours : elles seules vont dans la barre d'achat, et la partie
## peut commencer. Renvoie false si le choix n'est pas valable (vide, trop de tours, ou
## une tour non disponible).
func choose_towers(types: Array[TowerData]) -> bool:
	if not is_choosing_towers or types.is_empty() or types.size() > tower_limit \
			or types.any(func(data: TowerData) -> bool: return not available_tower_types.has(data)):
		return false
	is_choosing_towers = false
	tower_types = types.duplicate()
	if hud.tower_picker:
		hud.tower_picker.queue_free()
		hud.tower_picker = null
	hud.set_tower_types(tower_types)
	hud.show_rules_panel_later()
	if not is_demo:
		var paths := PackedStringArray()
		for data in tower_types:
			paths.append(data.resource_path)
		Progress.set_setting(TOWER_CHOICE_SETTING, paths)
	return true


func select_tower(data: TowerData) -> void:
	if is_over and data:
		return
	placer.select(data)


func can_place_tower(cell: Vector2i, data: TowerData) -> bool:
	return data != null and not is_over and map.is_cell_buildable(cell) and gold >= data.get_cost() \
		and (conquest == null or conquest.can_afford(data)) and not blocks_passage(cell)


## Niveau libre : une tour sur cette case fermerait le passage des monstres vers le QG
## (depuis un point d'apparition, ou depuis là où marche un monstre).
func blocks_passage(cell: Vector2i) -> bool:
	if not map.free_layout or not map.is_cell_buildable(cell):
		return false
	var walkers: Array[Vector2i] = []
	for node in enemies.get_children():
		var enemy := node as Enemy
		if enemy and enemy.is_alive and not enemy.data.flying:
			walkers.append(map.world_to_cell(enemy.get_route_position()))
	return not map.keeps_passage_open(cell, walkers)


## Niveau libre : le passage a changé, chaque monstre qui marche prend le nouveau plus
## court chemin, depuis là où il est.
func _reroute_enemies() -> void:
	for node in enemies.get_children():
		var enemy := node as Enemy
		if enemy and enemy.is_alive and not enemy.data.flying and enemy.is_node_ready():
			enemy.set_route(map.get_route_from(enemy.get_route_position()))


## Niveau libre : trajet que suit un monstre né d'un autre (divisé, appelé en renfort,
## relevé) ; null ailleurs, ou s'il ne se déplace pas comme lui (l'un vole, l'autre non).
func _route_for(parent: Enemy, data: EnemyData) -> Curve2D:
	return parent.get_route() if map.free_layout and data.flying == parent.data.flying else null


## Place une tour sur la case si c'est possible. Renvoie la tour, ou null.
func place_tower(cell: Vector2i, data: TowerData) -> Tower:
	if not can_place_tower(cell, data):
		return null
	var tower: Tower = data.scene.instantiate()
	tower.data = data
	tower.upgrades_locked = (challenge != null and not challenge.allows_upgrades()) \
		or not DailyChallenge.allows_upgrades_of(mutators)
	tower.projectile_container = projectiles
	towers.add_child(tower)
	tower.global_position = map.cell_to_world(cell)
	tower.cell = cell
	# Une Bobine éteinte par un Saboteur ne renforce plus ses voisines.
	tower.sabotage_changed.connect(func(_tower: Tower) -> void: refresh_boosts())
	refresh_tower_bonuses(tower)
	map.occupy(cell, tower)
	gold -= data.get_cost()
	stats.on_tower_placed(tower)
	Sound.play(&"build")
	if conquest:
		# En Conquête, la tour n'est qu'un chantier : les ouvriers vont la bâtir.
		conquest.start_site(tower)
	refresh_boosts()
	return tower


## Mode Conquête : un chantier vient d'être fini, la tour entre en jeu.
func on_tower_built(tower: Tower) -> void:
	Sound.play(&"upgrade")
	_show_floating_text(tr("Tour bâtie"), Color(0.6, 1.0, 0.65), tower.global_position + Vector2(0, -32), 14)
	refresh_boosts()
	if placer.inspected_tower == tower:
		hud.show_tower_details(tower)


func can_upgrade_tower(tower: Tower) -> bool:
	return is_instance_valid(tower) and not is_over and tower.can_upgrade() \
		and gold >= tower.get_upgrade_cost() and (conquest == null or conquest.can_afford_upgrade(tower))


## Améliore la tour si c'est possible et en déduit le prix. Renvoie true si elle a été améliorée.
func upgrade_tower(tower: Tower) -> bool:
	if not can_upgrade_tower(tower):
		return false
	var cost := tower.get_upgrade_cost()
	if conquest:
		conquest.pay_upgrade(tower)
	tower.upgrade()
	gold -= cost
	stats.on_tower_upgraded(tower, cost)
	Sound.play(&"upgrade")
	refresh_boosts()
	return true


## Vend la tour : elle quitte la carte et rend une partie de son prix.
## Renvoie l'or rendu (0 si la vente est impossible).
func sell_tower(tower: Tower) -> int:
	if not is_instance_valid(tower) or not tower.is_alive or is_over:
		return 0
	var value := tower.get_sell_value()
	if placer.inspected_tower == tower:
		inspect_tower(null)
	map.release(tower.cell)
	if conquest:
		conquest.refund(tower)
	stats.on_tower_sold(tower, value)
	_show_floating_text("+%d" % value, GOLD_TEXT_COLOR, tower.global_position, 16)
	tower.despawn()
	gold += value
	Sound.play(&"sell")
	refresh_boosts()
	return value


## Tours posées sur la carte (sans celles qui viennent d'être vendues).
func get_towers() -> Array[Tower]:
	var result: Array[Tower] = []
	for node in towers.get_children():
		var tower := node as Tower
		if tower and tower.is_alive:
			result.append(tower)
	return result


## Or rapporté par les intérêts si la carte était vidée maintenant.
func get_interest() -> int:
	return mini(floori(maxi(gold, 0) * get_interest_rate()), get_interest_cap())


## Part de l'or gardé rapportée par les intérêts, et leur plafond, coffres compris.
func get_interest_rate() -> float:
	return interest_rate + get_chest_bonus(ChestBonus.INTEREST) if interest_rate > 0.0 else 0.0


func get_interest_cap() -> int:
	return interest_cap + chest_levels.get(ChestBonus.INTEREST, 0) * ChestBonus.INTEREST_CAP_PER_LEVEL


# --- Pouvoirs ---------------------------------------------------------------

func get_power_cooldown(power: Power) -> float:
	var index := powers.find(power)
	return power_cooldowns[index] if index >= 0 else 0.0


func can_use_power(power: Power) -> bool:
	return power != null and powers.has(power) and not is_over and not is_paused \
		and not is_choosing_towers and get_power_cooldown(power) <= 0.0


## Bouton ou touche d'un pouvoir : un pouvoir qui se lance sur la carte attend le clic
## du joueur (le choisir à nouveau l'annule), le Gel part tout de suite.
func select_power(power: Power) -> void:
	if placer.selected_power == power or not can_use_power(power):
		placer.select_power(null)
	elif power.is_targeted():
		placer.select_power(power)
	else:
		use_power(power)


## Lance le pouvoir (sur le point `at` de la carte s'il se lance sur la carte) et le met
## en recharge. Renvoie true s'il a été lancé.
func use_power(power: Power, at := Vector2.ZERO) -> bool:
	if not can_use_power(power):
		return false
	match power.kind:
		Power.Kind.METEORS:
			var strike := MeteorStrike.new()
			strike.power = power
			effects.add_child(strike)
			strike.global_position = at
		Power.Kind.FREEZE:
			for node in get_tree().get_nodes_in_group(Enemy.GROUP):
				(node as Enemy).freeze(power.duration, power.vulnerability)
			var wave := FreezeWave.new()
			wave.area = hud.get_play_area()
			wave.color = power.color
			effects.add_child(wave)
			Sound.play(&"pulse_frost")
		Power.Kind.REINFORCEMENTS:
			# Les soldats se rangent en cercle sur le chemin, au plus près du point visé.
			var center := map.get_closest_path_point(at)
			for i in power.count:
				var soldier := Soldier.new()
				soldier.power = power
				allies.add_child(soldier)
				var spread := 0.0 if power.count == 1 else 16.0
				soldier.global_position = center + Vector2.from_angle(TAU * i / power.count - PI / 2.0) * spread
			Sound.play(&"build")
	power_cooldowns[powers.find(power)] = power.cooldown * (1.0 - get_chest_bonus(ChestBonus.POWERS))
	if placer.selected_power == power:
		placer.select_power(null)
	return true


## Soldats des renforts encore sur le terrain.
func get_soldiers() -> Array[Soldier]:
	var result: Array[Soldier] = []
	for node in allies.get_children():
		if node is Soldier and node.is_alive:
			result.append(node)
	return result


## Recalcule le bonus que chaque tour reçoit des Bobines à sa portée : celui de la plus
## forte (les Bobines ne s'additionnent pas). À appeler quand une tour est posée,
## améliorée ou vendue.
func refresh_boosts() -> void:
	var all := get_towers()
	var coils: Array[CoilTower] = []
	for tower in all:
		if tower is CoilTower:
			tower.boosted_towers.clear()
			if tower.is_built() and not tower.is_sabotaged():
				coils.append(tower)
	for tower in all:
		var best: CoilTower = null
		for coil in coils:
			if coil.can_boost(tower) and (best == null or coil.stats.boost_damage + coil.stats.boost_fire_rate
					> best.stats.boost_damage + best.stats.boost_fire_rate):
				best = coil
		if best:
			best.boosted_towers.append(tower)
			tower.set_boost(best.stats.boost_damage, best.stats.boost_fire_rate)
		else:
			tower.set_boost(0.0, 0.0)
	for coil in coils:
		coil.queue_redraw()


## Ouvre la fiche d'une tour posée (null = la fermer).
func inspect_tower(tower: Tower) -> void:
	placer.inspect(tower)


## Mode Conquête : choisit le bâtiment à poser (-1 = aucun).
func select_building(kind: int) -> void:
	if is_over and kind >= 0:
		return
	placer.select_building(kind)


# --- Pause et vitesse -------------------------------------------------------

func set_paused(value: bool) -> void:
	if is_over:
		return
	is_paused = value
	get_tree().paused = value
	hud.set_paused(value)
	# Le niveau ne se met plus à jour pendant la pause : on rafraîchit la vague tout de suite.
	_refresh_wave_ui()


## Le menu Options met la partie en pause ; à sa fermeture, elle reprend si elle tournait.
func _on_options_toggled(open: bool) -> void:
	if open:
		_paused_before_options = is_paused
		set_paused(true)
	elif not _paused_before_options:
		set_paused(false)


func set_game_speed(speed: float) -> void:
	if is_over:
		return
	game_speed = speed
	Engine.time_scale = speed
	hud.set_game_speed(speed)


# --- Vagues et ennemis ----------------------------------------------------

func can_start_next_wave() -> bool:
	return not is_over and not is_paused and not is_choosing_towers and not spawner.is_spawning \
		and spawner.has_next_wave()


func start_next_wave() -> void:
	if not can_start_next_wave():
		return
	var early_bonus := get_early_call_bonus()
	spawner.start_next_wave()
	hud.hide_challenge_rules()
	Sound.play(&"wave_start")
	if early_bonus > 0:
		gold += early_bonus
		stats.gold_earned += early_bonus
		stats.early_calls += 1
		if stats.early_calls >= Achievements.IMPATIENT_EARLY_CALLS:
			unlock_achievements(["impatient"])
		Sound.play(&"coins")
		var button_rect := hud.next_wave_button.get_global_rect()
		_show_floating_text("+%d" % early_bonus, GOLD_TEXT_COLOR,
			Vector2(button_rect.get_center().x, button_rect.end.y + 24.0), 18)


## Prime pour lancer la prochaine vague alors que des ennemis sont encore en jeu (0 sinon).
func get_early_call_bonus() -> int:
	if not can_start_next_wave() or _alive_enemy_count() == 0:
		return 0
	return roundi(get_wave_bonus(spawner.current_wave + 1) * early_call_bonus_ratio)


## Or versé quand la vague donnée est repoussée, bonus de l'arbre des améliorations compris.
func get_wave_bonus(index: int) -> int:
	return roundi(spawner.get_wave(index).bonus_gold * _bonuses.wave_bonus_multiplier
		* (1.0 + get_chest_bonus(ChestBonus.WAVE_GOLD)))


## Or rapporté par un ennemi détruit, bonus de l'arbre des améliorations, des coffres (et
## de l'Atelier en Conquête) compris.
func get_enemy_reward(data: EnemyData) -> int:
	return roundi(data.reward * _bonuses.reward_multiplier * (conquest.get_reward_multiplier() if conquest else 1.0)
		* (1.0 + get_chest_bonus(ChestBonus.BOUNTY)))


func _on_enemy_spawned(enemy: Enemy) -> void:
	enemy.damaged.connect(_on_enemy_damaged)
	enemy.died.connect(_on_enemy_died)
	enemy.reached_end.connect(_on_enemy_reached_end)
	enemy.healed.connect(_on_enemy_healed)
	enemy.summoned.connect(_on_enemy_summoned)
	# Niveau libre : un monstre qui suit un trajet d'avant le dernier changement du passage
	# (relevé après une tour posée) en reprend un à jour.
	if map.free_layout and not enemy.data.flying and not map.is_route_current(enemy.get_route()):
		enemy.set_route(map.get_route_from(enemy.get_route_position()))
	if enemy.data.is_boss:
		hud.track_boss(enemy)


func _on_enemy_damaged(enemy: Enemy, amount: float) -> void:
	stats.on_damage(enemy.damage_source_id, amount)
	# Petit décalage pour que les coups rapprochés ne se superposent pas.
	var offset := Vector2(randf_range(-8.0, 8.0), -enemy.data.radius - 12.0)
	_show_floating_text(str(roundi(amount)), DAMAGE_TEXT_COLOR, enemy.global_position + offset, 13)


func _on_enemy_healed(enemy: Enemy, amount: float) -> void:
	var offset := Vector2(randf_range(-8.0, 8.0), -enemy.data.radius - 12.0)
	_show_floating_text("+%d" % roundi(amount), HEAL_TEXT_COLOR, enemy.global_position + offset, 13)


func _on_enemy_died(enemy: Enemy) -> void:
	# Un porteur lâche son butin à sa première mort, même s'il va se relever.
	if enemy.carried >= 0:
		drop_loot(enemy.carried, enemy.global_position, enemy.data)
		enemy.carried = -1
	# Un ennemi qui va se relever ne rapporte rien cette fois : seulement à sa vraie mort.
	if enemy.can_revive():
		_start_revive(enemy)
		return
	var reward := get_enemy_reward(enemy.data)
	gold += reward
	stats.gold_earned += reward
	stats.on_kill(enemy.damage_source_id, enemy.data)
	if enemy.data.is_boss and counts_achievements():
		_announce_achievements(Achievements.on_boss_killed(enemy.data, get_towers().size()))
	if challenge:
		add_score(reward * DailyChallenge.POINTS_PER_GOLD)
	Sound.play(&"enemy_death", -3.0)
	_show_floating_text("+%d" % reward, GOLD_TEXT_COLOR, enemy.global_position, 16)
	var stain := GroundStain.new()
	stain.radius = enemy.data.radius
	stain.color = enemy.data.color
	stains.add_child(stain)
	stain.global_position = enemy.global_position
	_split(enemy)
	_check_wave_cleared()


## Fait apparaître les ennemis cachés dans un ennemi qui se divise, en file
## derrière lui sur son chemin.
func _split(enemy: Enemy) -> void:
	var data := enemy.data
	if data.split_into == null:
		return
	Sound.play(&"enemy_split")
	for i in data.split_count:
		spawner.spawn(data.split_into, enemy.path, maxf(enemy.progress - i * data.split_into.radius * 1.6, 0.0),
			enemy.health_multiplier, 1.0, -1, _route_for(enemy, data.split_into))


## Un ennemi tombé se relèvera sur place après son délai, avec une partie de sa vie.
func _start_revive(enemy: Enemy) -> void:
	_pending_revives += 1
	var effect := RiseEffect.new()
	effect.radius = enemy.data.radius
	effect.duration = enemy.data.revive_delay
	effect.risen.connect(_revive.bind(enemy.data, enemy.path, enemy.progress, enemy.health_multiplier,
		enemy.revives_left - 1, _route_for(enemy, enemy.data)))
	stains.add_child(effect)
	effect.global_position = enemy.global_position


func _revive(data: EnemyData, path: Path2D, at_progress: float, health_multiplier: float, revives: int,
		route: Curve2D) -> void:
	_pending_revives -= 1
	if is_over:
		return
	var enemy := spawner.spawn(data, path, at_progress, health_multiplier, data.revive_health_ratio, revives, route)
	Sound.play(&"enemy_split")
	_show_floating_text(tr("Se relève !"), Color(0.75, 0.55, 1.0), enemy.global_position + Vector2(0, -data.radius - 14.0), 14)


## Renforts appelés par un ennemi (un boss) : ils apparaissent en file derrière lui.
func _on_enemy_summoned(enemy: Enemy) -> void:
	var data := enemy.data
	for i in data.summon_count:
		spawner.spawn(data.summon_enemy, enemy.path,
			maxf(enemy.progress - data.radius - (i + 1) * data.summon_enemy.radius * 1.6, 0.0), enemy.health_multiplier,
			1.0, -1, _route_for(enemy, data.summon_enemy))


func _on_enemy_reached_end(enemy: Enemy) -> void:
	stats.lives_lost += mini(enemy.data.damage, lives)
	lives -= enemy.data.damage
	Sound.play(&"lives_lost")
	_show_lives_lost(enemy.data.damage, enemy.global_position)
	if lives <= 0:
		_end_game(false)
	else:
		_check_wave_cleared()


## Ennemis en jeu, ceux qui vont se relever compris.
func _alive_enemy_count() -> int:
	return get_tree().get_node_count_in_group(Enemy.GROUP) + _pending_revives


func _check_wave_cleared() -> void:
	if is_over or spawner.is_spawning or _alive_enemy_count() > 0:
		return
	# Intérêts sur l'or gardé, avant d'y ajouter les bonus : une fois par carte vidée.
	var interest := get_interest() if _wave_bonus_paid < spawner.current_wave else 0
	if interest > 0:
		gold += interest
		stats.gold_earned += interest
		_show_floating_text(tr("+%d intérêts") % interest, GOLD_TEXT_COLOR, hud.get_interest_anchor(), 16)
	# Si le joueur a lancé une vague avant d'avoir fini la précédente, tous les
	# bonus en attente sont versés quand la carte est vidée.
	while _wave_bonus_paid < spawner.current_wave:
		_wave_bonus_paid += 1
		gold += get_wave_bonus(_wave_bonus_paid)
		stats.gold_earned += get_wave_bonus(_wave_bonus_paid)
		if challenge:
			add_score(DailyChallenge.POINTS_PER_WAVE)
		# Infirmerie : rend des vies perdues, sans dépasser celles du départ.
		if lives < starting_lives:
			lives = mini(lives + _bonuses.lives_per_wave, starting_lives)
	if is_endless and not is_demo:
		Progress.record_endless(scene_file_path, get_waves_cleared(), get_endless_stars())
		if get_waves_cleared() >= Achievements.TIRELESS_WAVES:
			unlock_achievements(["infatigable"])
	_count_kills()
	if not spawner.has_next_wave():
		_end_game(true)
	elif conquest:
		conquest.on_wave_cleared()


func _end_game(victory: bool) -> void:
	if is_over:
		return
	is_over = true
	select_tower(null)
	placer.select_power(null)
	inspect_tower(null)
	if is_demo:
		game_over.emit(victory)
		return
	_count_kills()
	if conquest and counts_achievements():
		_announce_achievements(Achievements.add_counters({stone_mined = stats.stone_mined}))
	if challenge:
		if victory:
			add_score(lives * DailyChallenge.POINTS_PER_LIFE)
		var best_before := Progress.get_daily_score(challenge.date_key)
		var new_record := Progress.record_daily(challenge.date_key, score)
		if victory:
			Progress.record_daily_win(challenge.date_key)
		hud.show_challenge_end_screen(victory, score, maxi(best_before, score), new_record and best_before >= 0,
			Progress.get_daily_streak(challenge.date_key) if victory else 0)
	elif not custom_level.is_empty():
		hud.show_end_screen(victory, false, get_stars() if victory else 0)
	elif is_tutorial:
		hud.show_end_screen(victory, victory and has_next_level(), get_stars() if victory else 0)
	elif conquest and victory:
		var stars_won := get_stars()
		var new_record := Progress.record_victory(scene_file_path, stars_won, difficulty)
		_announce_achievements(Achievements.on_conquest_victory(stats))
		hud.show_end_screen(true, has_next_level(), stars_won, new_record)
	elif victory and not is_endless:
		var stars_won := get_stars()
		var new_record := Progress.record_victory(scene_file_path, stars_won, difficulty)
		_announce_achievements(Achievements.on_victory(stats, lives, gold, difficulty))
		hud.show_end_screen(true, has_next_level(), stars_won, new_record, get_next_world_name())
		if not mutators.is_empty():
			var before := Progress.get_mutator_stars(scene_file_path)
			Progress.record_mutators(scene_file_path, Mutators.stars_for(mutators))
			hud.show_mutator_result(Mutators.stars_for(mutators), before)
	elif is_endless:
		# Le record est enregistré à chaque vague : on le compare à celui d'avant la partie.
		hud.show_endless_end_screen(get_waves_cleared(), get_endless_stars(),
			get_waves_cleared() > _endless_record_before)
	else:
		hud.show_end_screen(false)
	hud.show_end_stats(stats, unlocked_achievements)
	is_paused = false
	Engine.time_scale = 1.0
	Sound.play(&"victory" if victory else &"defeat")
	game_over.emit(victory)
	get_tree().paused = true


# --- Butin et coffres --------------------------------------------------------

## Fait tomber le butin d'un porteur (Loot.Kind) là où il est mort.
func drop_loot(kind: int, at: Vector2, data: EnemyData = null) -> Loot:
	var loot := Loot.new()
	loot.kind = kind as Loot.Kind
	match kind:
		Loot.Kind.GOLD:
			loot.amount = maxi(LOOT_MIN_GOLD, LOOT_GOLD_PER_REWARD * get_enemy_reward(data) if data else 0)
		Loot.Kind.STONE:
			loot.amount = LOOT_STONE
		Loot.Kind.ESSENCE:
			loot.amount = LOOT_ESSENCE
	effects.add_child(loot)
	# Sur le chemin, un peu à côté du point de chute : deux butins ne se cachent pas.
	loot.global_position = at + Vector2(randf_range(-6.0, 6.0), randf_range(2.0, 8.0))
	Sound.play(&"coins", -8.0)
	return loot


## Butin au sol le plus proche d'un point de la carte, à moins de `radius` (null sinon).
func find_loot_at(at: Vector2, radius := Loot.PICK_RADIUS) -> Loot:
	var best: Loot = null
	var best_distance := radius
	for node in get_tree().get_nodes_in_group(Loot.GROUP):
		var loot := node as Loot
		if loot and not loot.is_queued_for_deletion():
			var distance := loot.global_position.distance_to(at)
			if distance <= best_distance:
				best = loot
				best_distance = distance
	return best


## Ramasse un butin : son or, sa pierre ou son essence, ou le bonus d'un coffre.
func collect_loot(loot: Loot) -> void:
	if not is_instance_valid(loot) or loot.is_queued_for_deletion() or is_over:
		return
	var at := loot.global_position + Vector2(0, -20)
	match loot.kind:
		Loot.Kind.GOLD:
			gold += loot.amount
			stats.gold_earned += loot.amount
			_show_floating_text("+%d" % loot.amount, GOLD_TEXT_COLOR, at, 18)
		Loot.Kind.STONE:
			conquest.stone += loot.amount
			conquest.changed.emit()
			_show_floating_text(tr("+%d pierre") % loot.amount, Conquest.STONE_COLOR, at, 16)
		Loot.Kind.ESSENCE:
			conquest.essence += loot.amount
			conquest.changed.emit()
			_show_floating_text(tr("+%d essence") % loot.amount, Conquest.ESSENCE_COLOR, at, 16)
		Loot.Kind.CHEST:
			open_chest(at)
	stats.loot_collected += 1
	Sound.play(&"coins")
	loot.queue_free()


## Ouvre un coffre : un bonus pour le reste du niveau, tiré parmi ceux qui peuvent encore
## tomber (de l'or s'ils sont tous au maximum). Renvoie son identifiant (&"" pour l'or).
func open_chest(at: Vector2) -> StringName:
	stats.chests_opened += 1
	if counts_achievements():
		_announce_achievements(Achievements.add_counters({chests_opened = 1}))
	var available := ChestBonus.get_available(chest_levels, not powers.is_empty(), interest_rate > 0.0, conquest != null)
	if available.is_empty():
		gold += ChestBonus.FALLBACK_GOLD
		stats.gold_earned += ChestBonus.FALLBACK_GOLD
		_show_floating_text("+%d" % ChestBonus.FALLBACK_GOLD, GOLD_TEXT_COLOR, at, 18)
		return &""
	var id := available[_chest_rng.randi() % available.size()]
	chest_levels[id] = chest_levels.get(id, 0) + 1
	var definition := ChestBonus.get_definition(id)
	match id:
		ChestBonus.DAMAGE, ChestBonus.RANGE, ChestBonus.FIRE_RATE:
			for tower in get_towers():
				refresh_tower_bonuses(tower)
		ChestBonus.INTEREST:
			hud.set_interest_rules(get_interest_rate(), get_interest_cap())
	_refresh_hud()
	_show_floating_text(tr(definition.name), definition.color, at, 18)
	hud.show_chest_bonus(definition, chest_levels[id])
	hud.update_chest_bonuses(chest_levels)
	return id


## Bonus total d'un bonus des coffres (0 s'il n'est pas tombé).
func get_chest_bonus(id: StringName) -> float:
	return ChestBonus.get_definition(id).per_level * chest_levels.get(id, 0)


## Bonus de la partie d'une tour (dégâts, portée, cadence) : ceux des coffres, et de
## l'Atelier en Conquête.
func refresh_tower_bonuses(tower: Tower) -> void:
	var damage := get_chest_bonus(ChestBonus.DAMAGE)
	var range_bonus := get_chest_bonus(ChestBonus.RANGE)
	var fire_rate := get_chest_bonus(ChestBonus.FIRE_RATE)
	if conquest:
		damage += conquest.get_research_bonus(Research.TOWER_DAMAGE)
		range_bonus += conquest.get_research_bonus(Research.TOWER_RANGE)
		fire_rate += conquest.get_research_bonus(Research.TOWER_FIRE_RATE)
	tower.set_research(damage, range_bonus, fire_rate)


# --- Succès ----------------------------------------------------------------

## Ajoute les monstres détruits depuis le dernier appel aux compteurs des succès.
func _count_kills() -> void:
	if not counts_achievements():
		return
	var kills := stats.kills - _counted_kills
	var elite_kills := stats.elite_kills - _counted_elite_kills
	_counted_kills = stats.kills
	_counted_elite_kills = stats.elite_kills
	_announce_achievements(Achievements.add_counters({kills = kills, elite_kills = elite_kills}))


## Débloque des succès (sauf dans la partie de l'écran titre) et annonce ceux qui
## ne l'étaient pas encore.
func unlock_achievements(ids: Array[String]) -> void:
	if counts_achievements():
		_announce_achievements(Achievements.unlock_all(ids))


## Annonce des succès qui viennent d'être débloqués : bandeau en jeu, et liste sur
## l'écran de fin.
func _announce_achievements(ids: Array[String]) -> void:
	for id in ids:
		unlocked_achievements.append(id)
		hud.show_achievement(Achievements.get_definition(id))


# --- Navigation -------------------------------------------------------------

func _on_restart_requested() -> void:
	get_tree().paused = false
	if is_endless:
		Engine.set_meta(ENDLESS_META, true)
	if challenge:
		Engine.set_meta(CHALLENGE_META, challenge.date_key)
	if not custom_level.is_empty():
		Engine.set_meta(CUSTOM_META, custom_level)
	get_tree().reload_current_scene()


func _on_next_level_requested() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(get_next_level())


func _on_menu_requested() -> void:
	get_tree().paused = false
	if conquest_mode:
		get_tree().change_scene_to_file(ConquestLevels.SELECT_SCREEN)
	elif FreeLevels.has(scene_file_path):
		get_tree().change_scene_to_file(FreeLevels.SELECT_SCREEN)
	else:
		get_tree().change_scene_to_file(TITLE_SCREEN if custom_level.is_empty() else LEVEL_EDITOR)


# --- Affichage --------------------------------------------------------------

## Défi du jour : ajoute des points au score, affiché en haut.
func add_score(points: int) -> void:
	score += points
	hud.set_score(score)


func _show_floating_text(text: String, color: Color, at: Vector2, font_size: int) -> void:
	var label := FloatingText.new()
	label.text = text
	label.color = color
	label.font_size = font_size
	label.position = effects.to_local(at)
	effects.add_child(label)


## Signale la perte de vies : effet sur le HUD et « -N » rouge là où l'ennemi est sorti.
func _show_lives_lost(amount: int, at: Vector2) -> void:
	hud.play_damage_effect(amount)
	# L'ennemi sort par le bord de l'écran : on ramène le texte dans la zone visible.
	var area := hud.get_play_area().grow(-24.0)
	var shown_at := at.clamp(area.position, area.end)
	_show_floating_text("-%d" % amount, LIVES_LOST_TEXT_COLOR, shown_at, 20)


func _refresh_hud() -> void:
	if not is_node_ready():
		return
	hud.update_stats(gold, lives, spawner.current_wave + 1, -1 if is_endless else spawner.get_wave_count(),
		get_interest() if interest_rate > 0.0 else -1)
	if conquest:
		hud.update_conquest(conquest)


func _process(delta: float) -> void:
	if not is_over and not is_choosing_towers:
		stats.duration += delta
	# Les pouvoirs se rechargent en temps de jeu (pas pendant la pause).
	if not is_over:
		for i in power_cooldowns.size():
			power_cooldowns[i] = maxf(power_cooldowns[i] - delta, 0.0)
	# Le bouton et l'aperçu de vague dépendent du spawner et des ennemis en jeu, qui évoluent en continu.
	_refresh_wave_ui()


func _refresh_wave_ui() -> void:
	hud.set_next_wave_available(can_start_next_wave())
	if not powers.is_empty():
		var usable: Array[bool] = []
		for power in powers:
			usable.append(can_use_power(power))
		hud.update_powers(power_cooldowns, usable)
	if not is_over:
		var next_index := spawner.current_wave + 1
		var next_wave: WaveData = spawner.get_wave(next_index) if spawner.has_next_wave() else null
		hud.show_next_wave(next_wave, get_early_call_bonus(), next_index + 1,
			get_wave_bonus(next_index) if next_wave else 0)
