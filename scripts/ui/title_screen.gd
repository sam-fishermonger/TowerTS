extends Control
## Écran titre : reprend la campagne, ouvre l'arbre des améliorations, permet de choisir
## un niveau débloqué, ou quitte le jeu.

const PERK_TREE_SCREEN := "res://scenes/ui/perk_tree_screen.tscn"

const CAMPAIGN: Campaign = preload("res://resources/campaign.tres")

@onready var play_button: Button = %PlayButton
@onready var perks_button: Button = %PerksButton
@onready var level_buttons: HBoxContainer = %LevelButtons
@onready var quit_button: Button = %QuitButton
@onready var reset_button: Button = %ResetButton
@onready var reset_dialog: ConfirmationDialog = %ResetDialog
@onready var music_button: Button = %MusicButton
@onready var sound_button: Button = %SoundButton


func _ready() -> void:
	play_button.pressed.connect(func() -> void: open_level(Progress.get_next_to_play(CAMPAIGN)))
	perks_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(PERK_TREE_SCREEN))
	quit_button.pressed.connect(get_tree().quit)
	# Quitter n'a pas de sens dans un navigateur.
	quit_button.visible = not OS.has_feature("web")
	reset_button.pressed.connect(reset_dialog.popup_centered)
	reset_dialog.confirmed.connect(_on_reset_confirmed)
	music_button.toggled.connect(func(on: bool) -> void:
		Sound.set_music_enabled(on)
		_refresh_audio_buttons())
	sound_button.toggled.connect(func(on: bool) -> void:
		Sound.set_sound_enabled(on)
		_refresh_audio_buttons())
	_refresh_audio_buttons()
	_build_level_buttons()
	Sound.play_music()
	play_button.grab_focus()


func open_level(path: String) -> void:
	get_tree().change_scene_to_file(path)


## Un bouton par niveau de la campagne : ses étoiles, ou « Verrouillé ».
func _build_level_buttons() -> void:
	for child in level_buttons.get_children():
		level_buttons.remove_child(child)
		child.queue_free()
	var any_won := false
	for i in CAMPAIGN.size():
		var path := CAMPAIGN.levels[i]
		var stars := Progress.get_stars(path)
		any_won = any_won or stars > 0
		var button := Button.new()
		button.custom_minimum_size = Vector2(124, 64)
		button.disabled = not Progress.is_unlocked(CAMPAIGN, i)
		button.text = "Niveau %d\n%s" % [i + 1, "Verrouillé" if button.disabled else Progress.star_text(stars)]
		button.pressed.connect(open_level.bind(path))
		level_buttons.add_child(button)
	play_button.text = "Continuer" if any_won else "Jouer"
	# Les étoiles non dépensées sont signalées sur le bouton de l'arbre.
	var available := Perks.get_available_stars()
	perks_button.text = "Améliorations  ·  ★ %d" % available if available > 0 else "Améliorations"
	reset_button.visible = any_won


func _refresh_audio_buttons() -> void:
	music_button.set_pressed_no_signal(Sound.is_music_enabled())
	sound_button.set_pressed_no_signal(Sound.is_sound_enabled())
	music_button.text = "Musique : %s" % ("oui" if music_button.button_pressed else "non")
	sound_button.text = "Sons : %s" % ("oui" if sound_button.button_pressed else "non")


func _on_reset_confirmed() -> void:
	Progress.reset_campaign()
	_build_level_buttons()
	play_button.grab_focus()
