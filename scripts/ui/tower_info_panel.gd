class_name TowerInfoPanel
extends PanelContainer
## Fiche détaillée d'une tour. Deux usages :
## - aperçu d'un type de tour (survol de la barre d'achat) : statistiques et prix ;
## - tour posée sur la carte : niveau, gains de la prochaine amélioration,
##   bouton Améliorer et bouton de fermeture.

signal upgrade_requested(tower: Tower)
signal close_requested

## Écart entre la fiche et ce qu'elle décrit, et marge avec les bords de l'écran.
const GAP := 8.0
## Haut de la zone de jeu, sous la barre du HUD.
const TOP_LIMIT := 72.0
const BONUS_COLOR := Color(0.55, 0.95, 0.55)
const MUTED_COLOR := Color(1, 1, 1, 0.6)
const PRICE_COLOR := Color(1, 0.85, 0.3)
const TOO_EXPENSIVE_COLOR := Color(1, 0.45, 0.45)

## Type de tour affiché.
var data: TowerData
## Tour posée affichée, ou null en mode aperçu.
var tower: Tower

var _gold := 0
## Zone de l'écran que la fiche décrit (bouton ou tour).
var _anchor_rect := Rect2()
## true : à côté de la zone (tour posée) ; false : en dessous (bouton).
var _beside := false

@onready var name_label: Label = %NameLabel
@onready var level_label: Label = %LevelLabel
@onready var close_button: Button = %CloseButton
@onready var description_label: Label = %DescriptionLabel
@onready var stats_grid: GridContainer = %StatsGrid
@onready var footer_label: Label = %FooterLabel
@onready var upgrade_button: Button = %UpgradeButton


func _ready() -> void:
	visible = false
	# Chaque fiche a son propre style, teinté selon la tour affichée.
	add_theme_stylebox_override("panel", get_theme_stylebox("panel").duplicate())
	close_button.pressed.connect(close_requested.emit)
	upgrade_button.pressed.connect(func() -> void: upgrade_requested.emit(tower))
	resized.connect(_reposition)


## Aperçu d'un type de tour, sous la zone donnée (le bouton de la barre d'achat).
func show_tower_type(tower_data: TowerData, gold: int, anchor_rect: Rect2) -> void:
	_set_tower(null)
	data = tower_data
	_gold = gold
	_anchor_rect = anchor_rect
	_beside = false
	_refresh()


## Fiche d'une tour posée, à côté d'elle.
func show_tower(placed: Tower, gold: int) -> void:
	_set_tower(placed)
	data = placed.data
	_gold = gold
	var size := Vector2(Tower.SIZE, Tower.SIZE)
	_anchor_rect = Rect2(placed.get_global_transform_with_canvas().origin - size / 2.0, size)
	_beside = true
	_refresh()


func close() -> void:
	_set_tower(null)
	visible = false


## Met à jour l'or disponible (prix et bouton Améliorer).
func set_gold(gold: int) -> void:
	if gold == _gold:
		return
	_gold = gold
	if visible:
		_refresh()


func _set_tower(new_tower: Tower) -> void:
	if is_instance_valid(tower) and tower.upgraded.is_connected(_on_tower_upgraded):
		tower.upgraded.disconnect(_on_tower_upgraded)
	tower = new_tower
	if tower:
		tower.upgraded.connect(_on_tower_upgraded)


func _on_tower_upgraded(_tower: Tower) -> void:
	_refresh()


# --- Contenu ------------------------------------------------------------------

func _refresh() -> void:
	var placed := tower != null
	# En aperçu, la fiche ne doit pas intercepter la souris.
	mouse_filter = Control.MOUSE_FILTER_STOP if placed else Control.MOUSE_FILTER_IGNORE
	var style := get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		style.border_color = data.color
	name_label.text = data.display_name
	name_label.add_theme_color_override("font_color", data.color.lightened(0.3))
	close_button.visible = placed
	description_label.text = data.description
	description_label.visible = not data.description.is_empty()

	var level := tower.level if placed else 1
	var stats := tower.stats if placed else data.get_stats_at_level(1)
	var next: TowerData = null
	if placed and tower.can_upgrade():
		next = data.get_stats_at_level(level + 1)
	_fill_stats(stats, next)

	if placed:
		level_label.text = "Niv. %d / %d" % [level, data.get_max_level()]
		level_label.visible = true
		footer_label.visible = false
		upgrade_button.visible = true
		_refresh_upgrade_button()
	else:
		level_label.visible = false
		var footer := "Prix : %d or" % data.cost
		if data.upgrades.size() > 0:
			footer += "   ·   %d amélioration%s" % [data.upgrades.size(), "s" if data.upgrades.size() > 1 else ""]
		footer_label.text = footer
		footer_label.add_theme_color_override("font_color",
			PRICE_COLOR if _gold >= data.cost else TOO_EXPENSIVE_COLOR)
		footer_label.visible = true
		upgrade_button.visible = false

	visible = true
	# La taille dépend du contenu : on la recalcule (aussi à l'image suivante, une fois
	# la mise en page des nouvelles lignes faite), puis on replace la fiche.
	reset_size()
	reset_size.call_deferred()
	_reposition()


func _refresh_upgrade_button() -> void:
	if not tower.can_upgrade():
		upgrade_button.text = "Niveau maximal"
		upgrade_button.disabled = true
		return
	var cost := tower.get_upgrade_cost()
	upgrade_button.text = "Améliorer  ·  %d or" % cost
	upgrade_button.disabled = _gold < cost


## Une ligne par statistique : nom, valeur actuelle et, si fourni, la valeur au niveau suivant.
func _fill_stats(stats: TowerData, next: TowerData) -> void:
	for child in stats_grid.get_children():
		stats_grid.remove_child(child)
		child.queue_free()
	_add_stat("Dégâts", _format(stats.damage), _format(next.damage) if next else "")
	_add_stat("Cadence", "%s tirs/s" % _format(stats.fire_rate, 2),
		"%s tirs/s" % _format(next.fire_rate, 2) if next else "")
	_add_stat("Dégâts/s", _format(stats.get_dps()), _format(next.get_dps()) if next else "")
	_add_stat("Portée", _format(stats.attack_range), _format(next.attack_range) if next else "")
	if stats.splash_radius > 0.0:
		_add_stat("Explosion", _format(stats.splash_radius), _format(next.splash_radius) if next else "")
	if stats.slow_factor < 1.0:
		_add_stat("Ralentit", "-%d %%" % roundi((1.0 - stats.slow_factor) * 100.0),
			"-%d %%" % roundi((1.0 - next.slow_factor) * 100.0) if next else "")
		_add_stat("Pendant", "%s s" % _format(stats.slow_duration),
			"%s s" % _format(next.slow_duration) if next else "")


func _add_stat(stat_name: String, value: String, next_value: String) -> void:
	var name_cell := Label.new()
	name_cell.text = stat_name
	name_cell.add_theme_color_override("font_color", MUTED_COLOR)
	stats_grid.add_child(name_cell)
	var value_cell := Label.new()
	value_cell.text = value
	value_cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_grid.add_child(value_cell)
	# Seuls les gains apparaissent : une valeur inchangée laisse la case vide.
	var next_cell := Label.new()
	next_cell.text = "→ %s" % next_value if not next_value.is_empty() and next_value != value else ""
	next_cell.add_theme_color_override("font_color", BONUS_COLOR)
	stats_grid.add_child(next_cell)


## Nombre arrondi, sans décimales inutiles : 25, 1.5, 0.75.
static func _format(value: float, decimals := 1) -> String:
	var text := String.num(value, decimals)
	return text.rstrip("0").trim_suffix(".") if text.contains(".") else text


# --- Position -----------------------------------------------------------------

func _reposition() -> void:
	if not visible or not is_inside_tree():
		return
	var screen := get_viewport_rect().size
	var target: Vector2
	if _beside:
		# À droite de la tour, ou à gauche s'il n'y a pas la place.
		target.x = _anchor_rect.end.x + GAP
		if target.x + size.x > screen.x - GAP:
			target.x = _anchor_rect.position.x - GAP - size.x
		target.y = _anchor_rect.get_center().y - size.y / 2.0
	else:
		target.x = _anchor_rect.get_center().x - size.x / 2.0
		target.y = _anchor_rect.end.y + GAP
	target.x = clampf(target.x, GAP, maxf(GAP, screen.x - size.x - GAP))
	target.y = clampf(target.y, TOP_LIMIT, maxf(TOP_LIMIT, screen.y - size.y - GAP))
	position = target
