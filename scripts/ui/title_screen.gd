extends Control
## Écran titre : lance le premier niveau ou quitte le jeu.

const FIRST_LEVEL := "res://scenes/levels/level_01.tscn"

@onready var play_button: Button = %PlayButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(get_tree().quit)
	# Quitter n'a pas de sens dans un navigateur.
	quit_button.visible = not OS.has_feature("web")
	play_button.grab_focus()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(FIRST_LEVEL)
