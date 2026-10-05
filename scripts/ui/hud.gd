class_name Hud
extends CanvasLayer
## Interface du niveau : or, vies, vague, choix des tours et écran de fin.

## Émis quand le joueur choisit une tour à placer (null = aucune).
signal tower_selected(data: TowerData)
signal next_wave_requested
signal restart_requested
signal next_level_requested
signal menu_requested

var _tower_group := ButtonGroup.new()
var _gold := 0

@onready var level_label: Label = %LevelLabel
@onready var gold_label: Label = %GoldLabel
@onready var lives_label: Label = %LivesLabel
@onready var wave_label: Label = %WaveLabel
@onready var tower_buttons: HBoxContainer = %TowerButtons
@onready var next_wave_button: Button = %NextWaveButton
@onready var end_panel: PanelContainer = %EndPanel
@onready var end_title: Label = %EndTitle
@onready var end_message: Label = %EndMessage
@onready var next_level_button: Button = %NextLevelButton


func _ready() -> void:
	end_panel.visible = false
	_tower_group.allow_unpress = true
	next_wave_button.pressed.connect(next_wave_requested.emit)
	%RestartButton.pressed.connect(restart_requested.emit)
	%NextLevelButton.pressed.connect(next_level_requested.emit)
	%MenuButton.pressed.connect(menu_requested.emit)


func setup(level_name: String, tower_types: Array[TowerData]) -> void:
	level_label.text = level_name
	for data in tower_types:
		var button := Button.new()
		button.text = "%s  %d or" % [data.display_name, data.cost]
		button.tooltip_text = _describe_tower(data)
		button.toggle_mode = true
		button.button_group = _tower_group
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_color_override("font_color", data.color.lightened(0.3))
		button.set_meta("tower_data", data)
		button.pressed.connect(_on_tower_button_pressed)
		tower_buttons.add_child(button)


func update_stats(gold: int, lives: int, wave: int, wave_count: int) -> void:
	_gold = gold
	gold_label.text = "Or : %d" % gold
	lives_label.text = "Vies : %d" % lives
	wave_label.text = "Vague : %d / %d" % [wave, wave_count]
	_update_tower_buttons()


func set_selected_tower(data: TowerData) -> void:
	for button: Button in tower_buttons.get_children():
		button.set_pressed_no_signal(button.get_meta("tower_data") == data)
	_update_tower_buttons()


func set_next_wave_available(available: bool) -> void:
	next_wave_button.disabled = not available


func show_end_screen(victory: bool, can_continue := false) -> void:
	end_title.text = "Victoire !" if victory else "Défaite"
	end_message.text = "Toutes les vagues ont été repoussées." if victory \
		else "Les ennemis ont atteint votre base."
	next_level_button.visible = can_continue
	end_panel.visible = true
	if can_continue:
		next_level_button.grab_focus()
	else:
		%RestartButton.grab_focus()


func _update_tower_buttons() -> void:
	for button: Button in tower_buttons.get_children():
		var data: TowerData = button.get_meta("tower_data")
		button.disabled = data.cost > _gold and not button.button_pressed


func _on_tower_button_pressed() -> void:
	var pressed := _tower_group.get_pressed_button()
	tower_selected.emit(pressed.get_meta("tower_data") if pressed else null)


static func _describe_tower(data: TowerData) -> String:
	var lines := ["Dégâts : %d   Portée : %d   Cadence : %.1f tirs/s" \
		% [data.damage, data.attack_range, data.fire_rate]]
	if data.splash_radius > 0.0:
		lines.append("Explosion : rayon %d" % data.splash_radius)
	if data.slow_factor < 1.0:
		lines.append("Ralentit de %d %% pendant %.1f s" \
			% [roundi((1.0 - data.slow_factor) * 100.0), data.slow_duration])
	return "\n".join(lines)
