class_name BossBar
extends PanelContainer
## Barre de vie d'un boss, en haut de la carte, tant qu'il est en jeu : son nom, sa vie
## et son bouclier. S'il y a plusieurs boss, elle suit le premier encore en jeu.

const WIDTH := 420.0
const BAR_HEIGHT := 12.0
const HEALTH_COLOR := Color(0.9, 0.25, 0.22)
const SHIELD_COLOR := Color(0.4, 0.85, 1.0)

## Boss suivis, dans l'ordre d'apparition.
var _bosses: Array[Enemy] = []
var _name_label: Label
var _bars: Control


func _init() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.05, 0.05, 0.88)
	style.border_color = EnemyData.BOSS_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 6
	style.content_margin_bottom = 8
	add_theme_stylebox_override(&"panel", style)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", 4)
	add_child(column)
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_color_override(&"font_color", EnemyData.BOSS_COLOR.lightened(0.3))
	_name_label.add_theme_font_size_override(&"font_size", 16)
	column.add_child(_name_label)
	_bars = Control.new()
	_bars.custom_minimum_size = Vector2(WIDTH, BAR_HEIGHT)
	_bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bars.draw.connect(_draw_bars)
	column.add_child(_bars)


## Suit un boss qui vient d'apparaître.
func track(enemy: Enemy) -> void:
	_bosses.append(enemy)
	_refresh()


## Boss affiché, ou null.
func get_boss() -> Enemy:
	return _bosses[0] if not _bosses.is_empty() else null


func _process(_delta: float) -> void:
	if not _bosses.is_empty():
		_refresh()


func _refresh() -> void:
	_bosses = _bosses.filter(func(e: Enemy) -> bool: return is_instance_valid(e) and e.is_alive)
	visible = not _bosses.is_empty()
	if not visible:
		return
	var boss := _bosses[0]
	var others := _bosses.size() - 1
	_name_label.text = boss.data.display_name + ("  (+%d)" % others if others > 0 else "")
	_bars.queue_redraw()


func _draw_bars() -> void:
	var boss := get_boss()
	if not boss or not boss.is_node_ready():
		return
	var health := boss.health
	var rect := Rect2(Vector2.ZERO, _bars.size)
	_bars.draw_rect(rect, Color(0.15, 0.1, 0.1))
	_bars.draw_rect(Rect2(rect.position, Vector2(rect.size.x * health.health / health.max_health, rect.size.y)),
		HEALTH_COLOR)
	if health.max_shield > 0.0:
		var shield_height := rect.size.y * 0.4
		_bars.draw_rect(Rect2(rect.position, Vector2(rect.size.x * health.shield / health.max_shield, shield_height)),
			SHIELD_COLOR)
	_bars.draw_rect(rect, Color(1, 1, 1, 0.5), false, 1.0)
	var text := "%d / %d" % [ceili(health.health), roundi(health.max_health)]
	var font := get_theme_default_font()
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
	_bars.draw_string(font, Vector2((rect.size.x - text_size.x) / 2.0, rect.size.y - 1.5), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
