extends Control
## Écran titre : lance le premier niveau, permet de choisir un niveau, ou quitte le jeu.

const LEVELS: Array[String] = [
	"res://scenes/levels/level_01.tscn",
	"res://scenes/levels/level_02.tscn",
]

@onready var play_button: Button = %PlayButton
@onready var level_buttons: HBoxContainer = %LevelButtons
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	play_button.pressed.connect(open_level.bind(LEVELS[0]))
	for i in LEVELS.size():
		var button := Button.new()
		button.text = "Niveau %d" % (i + 1)
		button.custom_minimum_size = Vector2(124, 40)
		button.pressed.connect(open_level.bind(LEVELS[i]))
		level_buttons.add_child(button)
	quit_button.pressed.connect(get_tree().quit)
	# Quitter n'a pas de sens dans un navigateur.
	quit_button.visible = not OS.has_feature("web")
	play_button.grab_focus()


func open_level(path: String) -> void:
	get_tree().change_scene_to_file(path)
