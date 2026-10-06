extends Control
## Écran titre : reprend la campagne, ouvre la sélection des mondes et des niveaux,
## ouvre l'arbre des améliorations, ou quitte le jeu.

const PERK_TREE_SCREEN := "res://scenes/ui/perk_tree_screen.tscn"
const WORLD_SELECT_SCREEN := "res://scenes/ui/world_select_screen.tscn"

const CAMPAIGN: Campaign = preload("res://resources/campaign.tres")

@onready var play_button: Button = %PlayButton
@onready var perks_button: Button = %PerksButton
@onready var worlds_button: Button = %WorldsButton
@onready var quit_button: Button = %QuitButton
@onready var reset_button: Button = %ResetButton
@onready var reset_dialog: ConfirmationDialog = %ResetDialog


func _ready() -> void:
	play_button.pressed.connect(func() -> void: open_level(Progress.get_next_to_play(CAMPAIGN)))
	worlds_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(WORLD_SELECT_SCREEN))
	perks_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(PERK_TREE_SCREEN))
	quit_button.pressed.connect(get_tree().quit)
	# Quitter n'a pas de sens dans un navigateur.
	quit_button.visible = not OS.has_feature("web")
	reset_button.pressed.connect(reset_dialog.popup_centered)
	reset_dialog.confirmed.connect(_on_reset_confirmed)
	_refresh()
	Sound.play_music()
	play_button.grab_focus()


func open_level(path: String) -> void:
	get_tree().change_scene_to_file(path)


## Boutons qui dépendent de la progression : Jouer ou Continuer, étoiles gagnées et
## à dépenser, effacement.
func _refresh() -> void:
	var earned := Perks.get_earned_stars()
	var any_won := earned > 0
	play_button.text = "Continuer" if any_won else "Jouer"
	worlds_button.text = "Mondes  ·  ★ %d / %d" % [earned, CAMPAIGN.size() * 3] if any_won else "Mondes"
	# Les étoiles non dépensées sont signalées sur le bouton de l'arbre.
	var available := Perks.get_available_stars()
	perks_button.text = "Améliorations  ·  ★ %d" % available if available > 0 else "Améliorations"
	reset_button.visible = any_won


func _on_reset_confirmed() -> void:
	Progress.reset_campaign()
	_refresh()
	play_button.grab_focus()
