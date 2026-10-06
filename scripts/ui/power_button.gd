class_name PowerButton
extends Button
## Bouton d'un pouvoir actif, en haut de l'écran : son image, son nom et sa touche.
## Pendant la recharge, il se grise, se remplit de gauche à droite et montre les
## secondes restantes. Il reste enfoncé tant que le pouvoir est visé sur la carte.

const ICON_SIZE := 26.0

var power: Power
## Touche du pouvoir, telle qu'elle est écrite sur le clavier du joueur.
var key_text := ""
var cooldown_left := 0.0


func setup(value: Power, key: String) -> void:
	power = value
	key_text = key
	text = power.display_name
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(118, 44)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_theme_font_size_override("font_size", 14)
	_refresh_tooltip()
	# Même cadre que les cases de la barre d'achat, à la couleur du pouvoir.
	UiStyle.apply_styles(self, UiStyle.slot_styles(power.color, ICON_SIZE + 12.0, 10.0))
	add_theme_color_override("font_color", power.color.lightened(0.35))
	add_theme_color_override("font_hover_color", power.color.lightened(0.5))
	add_theme_color_override("font_pressed_color", Color.WHITE)
	add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.45))


## Bulle d'aide : nom, touche, description et statistiques du pouvoir (refaite au changement de langue).
func _refresh_tooltip() -> void:
	tooltip_text = tr("%s (touche %s)") % [tr(power.display_name), key_text] + "\n%s\n%s" % [tr(power.description),
		"\n".join(power.get_stats_lines())]


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and power:
		_refresh_tooltip()


## Recharge restante et pouvoir utilisable maintenant (sinon le bouton est grisé).
func set_state(cooldown: float, usable: bool) -> void:
	disabled = not usable
	var label := power.display_name if cooldown <= 0.0 else "%d s" % ceili(cooldown)
	if label != text:
		text = label
	if not is_equal_approx(cooldown, cooldown_left):
		cooldown_left = cooldown
		queue_redraw()


func _draw() -> void:
	var ready := cooldown_left <= 0.0
	PowerIcon.draw_icon(self, power, Rect2(Vector2(7.0, (size.y - ICON_SIZE) / 2.0), Vector2.ONE * ICON_SIZE),
		1.0 if ready else 0.45)
	if not ready and power.cooldown > 0.0:
		# Ce qui est déjà rechargé se remplit de la couleur du pouvoir.
		var ratio := 1.0 - clampf(cooldown_left / power.cooldown, 0.0, 1.0)
		draw_rect(Rect2(Vector2(2, size.y - 5.0), Vector2((size.x - 4.0) * ratio, 3.0)), Color(power.color, 0.8))
	var font := get_theme_default_font()
	draw_string(font, Vector2(size.x - 13.0, 14.0), key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
		Color(1, 1, 1, 0.55))
