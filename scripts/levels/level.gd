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

var _wave_bonus_paid := -1
## Bonus de l'arbre des améliorations, lus au lancement : ils ne changent pas en cours de partie.
var _bonuses: Perk

@onready var map: GameMap = $Map
@onready var stains: Node2D = $Stains
@onready var enemies: Node2D = $Enemies
@onready var towers: Node2D = $Towers
@onready var projectiles: Node2D = $Projectiles
## Textes flottants (dégâts, or gagné), dessinés au-dessus des ennemis et des tirs.
@onready var effects: Node2D = $Effects
@onready var placer: TowerPlacer = $TowerPlacer
@onready var spawner: WaveSpawner = $WaveSpawner
@onready var hud: Hud = $HUD


func _ready() -> void:
	placer.level = self
	placer.selection_changed.connect(hud.set_selected_tower)
	placer.inspection_changed.connect(hud.show_tower_details)
	hud.setup(level_name, tower_types, game_speeds)
	hud.pause_toggled.connect(func() -> void: set_paused(not is_paused))
	hud.game_speed_selected.connect(set_game_speed)
	hud.tower_selected.connect(select_tower)
	hud.next_wave_requested.connect(start_next_wave)
	hud.upgrade_requested.connect(upgrade_tower)
	hud.sell_requested.connect(sell_tower)
	hud.tower_details_closed.connect(inspect_tower.bind(null))
	hud.restart_requested.connect(_on_restart_requested)
	hud.next_level_requested.connect(_on_next_level_requested)
	hud.menu_requested.connect(_on_menu_requested)
	spawner.enemy_spawned.connect(_on_enemy_spawned)
	spawner.wave_started.connect(func(_index: int) -> void: _refresh_hud())
	spawner.wave_spawning_finished.connect(func(_index: int) -> void: _check_wave_cleared())
	# Les bonus de l'arbre des améliorations comptent comme des vies de départ : les
	# étoiles se calculent sur ce total.
	_bonuses = Perks.get_bonuses()
	starting_gold += _bonuses.starting_gold_bonus
	starting_lives += _bonuses.lives_bonus
	gold = starting_gold
	lives = starting_lives
	set_game_speed(game_speeds[0] if not game_speeds.is_empty() else 1.0)
	Sound.play_music()


func _exit_tree() -> void:
	# La vitesse est globale au moteur : on la remet à x1 en quittant le niveau.
	Engine.time_scale = 1.0


## Niveau proposé après une victoire ("" = dernier niveau).
func get_next_level() -> String:
	return campaign.get_next(scene_file_path) if campaign else ""


func has_next_level() -> bool:
	return not get_next_level().is_empty()


## Nom du monde suivant si ce niveau est le dernier de son monde, "" sinon.
func get_next_world_name() -> String:
	if not campaign or not has_next_level():
		return ""
	var world := campaign.world_index_of(scene_file_path)
	var next_world := campaign.world_index_of(get_next_level())
	return campaign.worlds[next_world].display_name if next_world != world else ""


## Étoiles méritées si la partie était gagnée maintenant.
func get_stars() -> int:
	return Progress.stars_for(lives, starting_lives)


# --- Tours ------------------------------------------------------------------

func select_tower(data: TowerData) -> void:
	placer.select(data)


func can_place_tower(cell: Vector2i, data: TowerData) -> bool:
	return data != null and not is_over and map.is_cell_buildable(cell) and gold >= data.get_cost()


## Place une tour sur la case si c'est possible. Renvoie la tour, ou null.
func place_tower(cell: Vector2i, data: TowerData) -> Tower:
	if not can_place_tower(cell, data):
		return null
	var tower: Tower = data.scene.instantiate()
	tower.data = data
	tower.projectile_container = projectiles
	towers.add_child(tower)
	tower.global_position = map.cell_to_world(cell)
	tower.cell = cell
	map.occupy(cell, tower)
	gold -= data.get_cost()
	Sound.play(&"build")
	return tower


func can_upgrade_tower(tower: Tower) -> bool:
	return is_instance_valid(tower) and not is_over and tower.can_upgrade() \
		and gold >= tower.get_upgrade_cost()


## Améliore la tour si c'est possible et en déduit le prix. Renvoie true si elle a été améliorée.
func upgrade_tower(tower: Tower) -> bool:
	if not can_upgrade_tower(tower):
		return false
	gold -= tower.get_upgrade_cost()
	Sound.play(&"upgrade")
	return tower.upgrade()


## Vend la tour : elle quitte la carte et rend une partie de son prix.
## Renvoie l'or rendu (0 si la vente est impossible).
func sell_tower(tower: Tower) -> int:
	if not is_instance_valid(tower) or not tower.is_alive or is_over:
		return 0
	var value := tower.get_sell_value()
	if placer.inspected_tower == tower:
		inspect_tower(null)
	map.release(tower.cell)
	_show_floating_text("+%d" % value, GOLD_TEXT_COLOR, tower.global_position, 16)
	tower.despawn()
	gold += value
	Sound.play(&"sell")
	return value


## Ouvre la fiche d'une tour posée (null = la fermer).
func inspect_tower(tower: Tower) -> void:
	placer.inspect(tower)


# --- Pause et vitesse -------------------------------------------------------

func set_paused(value: bool) -> void:
	if is_over:
		return
	is_paused = value
	get_tree().paused = value
	hud.set_paused(value)
	# Le niveau ne se met plus à jour pendant la pause : on rafraîchit le bouton de vague tout de suite.
	hud.set_next_wave_available(can_start_next_wave())


func set_game_speed(speed: float) -> void:
	if is_over:
		return
	game_speed = speed
	Engine.time_scale = speed
	hud.set_game_speed(speed)


# --- Vagues et ennemis ----------------------------------------------------

func can_start_next_wave() -> bool:
	return not is_over and not is_paused and not spawner.is_spawning and spawner.has_next_wave()


func start_next_wave() -> void:
	if not can_start_next_wave():
		return
	var early_bonus := get_early_call_bonus()
	spawner.start_next_wave()
	Sound.play(&"wave_start")
	if early_bonus > 0:
		gold += early_bonus
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
	return roundi(spawner.waves[index].bonus_gold * _bonuses.wave_bonus_multiplier)


## Or rapporté par un ennemi détruit, bonus de l'arbre des améliorations compris.
func get_enemy_reward(data: EnemyData) -> int:
	return roundi(data.reward * _bonuses.reward_multiplier)


func _on_enemy_spawned(enemy: Enemy) -> void:
	enemy.damaged.connect(_on_enemy_damaged)
	enemy.died.connect(_on_enemy_died)
	enemy.reached_end.connect(_on_enemy_reached_end)
	enemy.healed.connect(_on_enemy_healed)


func _on_enemy_damaged(enemy: Enemy, amount: float) -> void:
	# Petit décalage pour que les coups rapprochés ne se superposent pas.
	var offset := Vector2(randf_range(-8.0, 8.0), -enemy.data.radius - 12.0)
	_show_floating_text(str(roundi(amount)), DAMAGE_TEXT_COLOR, enemy.global_position + offset, 13)


func _on_enemy_healed(enemy: Enemy, amount: float) -> void:
	var offset := Vector2(randf_range(-8.0, 8.0), -enemy.data.radius - 12.0)
	_show_floating_text("+%d" % roundi(amount), HEAL_TEXT_COLOR, enemy.global_position + offset, 13)


func _on_enemy_died(enemy: Enemy) -> void:
	var reward := get_enemy_reward(enemy.data)
	gold += reward
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
		spawner.spawn(data.split_into, enemy.path, maxf(enemy.progress - i * data.split_into.radius * 1.6, 0.0))


func _on_enemy_reached_end(enemy: Enemy) -> void:
	lives -= enemy.data.damage
	Sound.play(&"lives_lost")
	_show_lives_lost(enemy.data.damage, enemy.global_position)
	if lives <= 0:
		_end_game(false)
	else:
		_check_wave_cleared()


func _alive_enemy_count() -> int:
	return get_tree().get_nodes_in_group(Enemy.GROUP).size()


func _check_wave_cleared() -> void:
	if is_over or spawner.is_spawning or _alive_enemy_count() > 0:
		return
	# Si le joueur a lancé une vague avant d'avoir fini la précédente, tous les
	# bonus en attente sont versés quand la carte est vidée.
	while _wave_bonus_paid < spawner.current_wave:
		_wave_bonus_paid += 1
		gold += get_wave_bonus(_wave_bonus_paid)
		# Infirmerie : rend des vies perdues, sans dépasser celles du départ.
		if lives < starting_lives:
			lives = mini(lives + _bonuses.lives_per_wave, starting_lives)
	if not spawner.has_next_wave():
		_end_game(true)


func _end_game(victory: bool) -> void:
	if is_over:
		return
	is_over = true
	select_tower(null)
	inspect_tower(null)
	var stars := get_stars() if victory else 0
	var new_record := victory and Progress.record_victory(scene_file_path, stars)
	hud.show_end_screen(victory, victory and has_next_level(), stars, new_record,
		get_next_world_name() if victory else "")
	is_paused = false
	Engine.time_scale = 1.0
	Sound.play(&"victory" if victory else &"defeat")
	game_over.emit(victory)
	get_tree().paused = true


# --- Navigation -------------------------------------------------------------

func _on_restart_requested() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_next_level_requested() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(get_next_level())


func _on_menu_requested() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCREEN)


# --- Affichage --------------------------------------------------------------

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
	hud.update_stats(gold, lives, spawner.current_wave + 1, spawner.waves.size())


func _process(_delta: float) -> void:
	# Le bouton et l'aperçu de vague dépendent du spawner et des ennemis en jeu, qui évoluent en continu.
	hud.set_next_wave_available(can_start_next_wave())
	if not is_over:
		var next_wave: WaveData = spawner.waves[spawner.current_wave + 1] if spawner.has_next_wave() else null
		hud.show_next_wave(next_wave, get_early_call_bonus())
