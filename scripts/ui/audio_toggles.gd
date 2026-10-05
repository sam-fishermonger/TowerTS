class_name AudioToggles
extends HBoxContainer
## Boutons « Musique » et « Sons » : chacun coupe ou remet sa partie du son. Utilisés
## sur l'écran titre et en jeu ; le choix est enregistré (voir Sound).

## Hauteur des boutons (plus petits dans la barre du jeu que sur l'écran titre).
@export var button_height := 36.0

@onready var music_button: Button = %MusicButton
@onready var sound_button: Button = %SoundButton


func _ready() -> void:
	for button in [music_button, sound_button]:
		button.custom_minimum_size.y = button_height
	music_button.toggled.connect(func(on: bool) -> void:
		Sound.set_music_enabled(on)
		refresh())
	sound_button.toggled.connect(func(on: bool) -> void:
		Sound.set_sound_enabled(on)
		refresh())
	refresh()


## Remet les boutons à jour d'après les réglages enregistrés.
func refresh() -> void:
	music_button.set_pressed_no_signal(Sound.is_music_enabled())
	sound_button.set_pressed_no_signal(Sound.is_sound_enabled())
	music_button.text = "Musique : %s" % ("oui" if music_button.button_pressed else "non")
	sound_button.text = "Sons : %s" % ("oui" if sound_button.button_pressed else "non")
