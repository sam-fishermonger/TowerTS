class_name GameSettings
extends CanvasLayer
## Réglages du menu Options qui ne sont pas du son (voir Sound pour les volumes) :
## plein écran, vitesse de jeu par défaut et langue. Enregistrés avec la progression
## (section « settings »).
##
## Le nœud est chargé au démarrage (autoload « Settings ») : il remet le plein écran
## choisi, F11 (ou Alt + Entrée) bascule le plein écran partout, et il repère si le
## joueur se sert d'un écran tactile ou d'une souris (voir is_touch_mode). Sur un écran
## tactile tenu en hauteur, il invite à tourner l'appareil.
## Comme Sound, il s'utilise par ses fonctions statiques.

## Vitesses proposées comme vitesse par défaut (celles des niveaux).
const DEFAULT_SPEEDS: Array[float] = [1.0, 2.0, 3.0]
## Langues proposées, avec leur nom écrit dans la langue même. Le jeu est écrit en
## français : les autres langues traduisent ses textes (translations/<code>.po).
const LANGUAGES := {"fr": "Français", "en": "English"}
const DEFAULT_LANGUAGE := "fr"
## Méta du moteur : vrai quand le dernier geste du joueur était un toucher d'écran.
## (Pas de `static var`, voir Progress.)
const TOUCH_MODE_META := &"settings_touch_mode"
## Méta du moteur : bouton touché une première fois (voir confirm_touch).
const ARMED_BUTTON_META := &"settings_armed_button"

## Message « tournez l'appareil », par-dessus tout.
var _rotate_hint: Control


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	apply_language()
	# Le navigateur refuse le plein écran sans geste du joueur : sur le web, il ne se
	# demande que depuis le menu Options.
	if is_fullscreen_saved() and not OS.has_feature("web"):
		_apply_fullscreen(true)
	_build_rotate_hint()
	get_viewport().size_changed.connect(_refresh_rotate_hint)
	_refresh_rotate_hint()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		set_touch_mode(true)
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		# Une vraie souris (pas celle que Godot simule à partir des touchers).
		set_touch_mode(false)
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and (key.keycode == KEY_F11
			or (key.keycode == KEY_ENTER and key.alt_pressed)):
		set_fullscreen(not is_fullscreen())
		get_viewport().set_input_as_handled()


# --- Plein écran --------------------------------------------------------------

## Vrai si la fenêtre est en plein écran (ou, sans fenêtre, si c'est le choix enregistré).
static func is_fullscreen() -> bool:
	if not _has_window():
		return is_fullscreen_saved()
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


static func is_fullscreen_saved() -> bool:
	return Progress.get_setting("fullscreen", false)


static func set_fullscreen(enabled: bool) -> void:
	Progress.set_setting("fullscreen", enabled)
	_apply_fullscreen(enabled)


static func _apply_fullscreen(enabled: bool) -> void:
	if _has_window():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled
			else DisplayServer.WINDOW_MODE_WINDOWED)


static func _has_window() -> bool:
	return DisplayServer.get_name() != "headless"


# --- Vitesse par défaut -------------------------------------------------------

## Vitesse de jeu au lancement d'un niveau (x1, x2 ou x3).
static func get_default_speed() -> float:
	return Progress.get_setting("default_speed", 1.0)


static func set_default_speed(speed: float) -> void:
	Progress.set_setting("default_speed", speed)


## Vitesse de départ d'un niveau qui propose ces vitesses : la vitesse par défaut si
## le niveau l'a, sinon sa première.
static func pick_start_speed(speeds: Array[float]) -> float:
	if speeds.is_empty():
		return 1.0
	for speed in speeds:
		if is_equal_approx(speed, get_default_speed()):
			return speed
	return speeds[0]


# --- Langue ------------------------------------------------------------------

## Code de la langue choisie dans les Options (une clé de LANGUAGES).
static func get_language() -> String:
	var code: String = Progress.get_setting("language", DEFAULT_LANGUAGE)
	return code if LANGUAGES.has(code) else DEFAULT_LANGUAGE


## Change la langue tout de suite : les textes fixes se traduisent seuls, et chaque nœud
## reçoit NOTIFICATION_TRANSLATION_CHANGED pour recalculer ses textes composés.
static func set_language(code: String) -> void:
	Progress.set_setting("language", code)
	apply_language()


static func apply_language() -> void:
	if TranslationServer.get_locale() != get_language():
		TranslationServer.set_locale(get_language())


# --- Tactile ------------------------------------------------------------------

## Vrai quand le joueur se sert de l'écran tactile : on ne survole rien du doigt,
## alors une tour se pose en deux touchers (le premier montre l'aperçu) et les boutons
## qui ont une fenêtre de détail l'ouvrent au premier toucher (voir confirm_touch).
static func is_touch_mode() -> bool:
	return Engine.get_meta(TOUCH_MODE_META, false)


static func set_touch_mode(enabled: bool) -> void:
	if enabled != is_touch_mode():
		Engine.set_meta(TOUCH_MODE_META, enabled)
		Engine.set_meta(ARMED_BUTTON_META, 0)


## À appeler dans l'action d'un bouton qui montre sa fiche au survol (niveau, amélioration) :
## au tactile, le premier toucher ne fait qu'ouvrir la fiche et renvoie faux ; un second
## toucher sur le même bouton renvoie vrai. À la souris, renvoie toujours vrai.
static func confirm_touch(button: Control) -> bool:
	if not is_touch_mode():
		return true
	var id := button.get_instance_id()
	if Engine.get_meta(ARMED_BUTTON_META, 0) == id:
		Engine.set_meta(ARMED_BUTTON_META, 0)
		return true
	Engine.set_meta(ARMED_BUTTON_META, id)
	return false


func _build_rotate_hint() -> void:
	_rotate_hint = ColorRect.new()
	(_rotate_hint as ColorRect).color = Color(0.05, 0.07, 0.06, 0.94)
	_rotate_hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rotate_hint.mouse_filter = Control.MOUSE_FILTER_STOP
	var label := Label.new()
	label.text = "Tournez l'appareil\npour jouer à l'horizontale."
	label.add_theme_font_size_override(&"font_size", 56)
	label.add_theme_color_override(&"font_color", Color(0.95, 0.85, 0.45))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rotate_hint.add_child(label)
	add_child(_rotate_hint)


## Le jeu est fait pour un écran en largeur : tenu en hauteur, il serait minuscule.
func _refresh_rotate_hint() -> void:
	var window := DisplayServer.window_get_size() if _has_window() else Vector2i(16, 10)
	_rotate_hint.visible = DisplayServer.is_touchscreen_available() and window.y > window.x
