class_name DetailPopup
extends PanelContainer
## Fenêtre de détail, au survol : un texte (BBCode) placé à côté de ce qu'il décrit, sans
## sortir de l'écran (ou de la zone donnée). Elle ne prend pas la souris. Sert à la
## sélection des mondes (niveau survolé), à la prochaine vague et au monstre sous la
## souris en jeu.

## Où placer la fenêtre par rapport à ce qu'elle décrit.
enum Side { BESIDE, BELOW, ABOVE }

## Écart avec ce qu'elle décrit, et marge avec les bords.
const GAP := 10.0

## Zone où la fenêtre doit rester (vide = tout l'écran).
var bounds := Rect2()

var _label: RichTextLabel
var _style: StyleBoxFlat
var _anchor_rect := Rect2()
var _side := Side.BESIDE


func _init(width := 320.0) -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 10
	_style = UiStyle.panel(Color(0.5, 0.5, 0.5), 12.0, SIDE_LEFT, Color(0.03, 0.06, 0.09, 0.96))
	_style.shadow_color = Color(0, 0, 0, 0.45)
	_style.shadow_size = 8
	add_theme_stylebox_override(&"panel", _style)
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.custom_minimum_size.x = width
	_label.add_theme_font_size_override(&"normal_font_size", 14)
	_label.add_theme_font_size_override(&"bold_font_size", 15)
	add_child(_label)
	resized.connect(_reposition)


## Affiche le texte à côté de la zone de l'écran donnée, avec une bordure de la couleur
## donnée. Le texte n'est refait que s'il a changé.
func show_text(bbcode: String, anchor_rect: Rect2, border_color := Color(0.5, 0.5, 0.5),
		side := Side.BESIDE) -> void:
	_anchor_rect = anchor_rect
	_side = side
	_style.border_color = border_color
	if bbcode != _label.text:
		_label.text = bbcode
		reset_size()
		reset_size.call_deferred()
	visible = true
	_reposition()


func close() -> void:
	visible = false


## Texte affiché (sans BBCode), pour les tests.
func get_text() -> String:
	return _label.get_parsed_text()


func _reposition() -> void:
	if not visible or not is_inside_tree():
		return
	var area := bounds if bounds.has_area() else get_viewport_rect()
	var target: Vector2
	match _side:
		Side.BESIDE:
			target.x = _anchor_rect.end.x + GAP
			if target.x + size.x > area.end.x - GAP:
				target.x = _anchor_rect.position.x - GAP - size.x
			target.y = _anchor_rect.get_center().y - size.y / 2.0
		Side.BELOW:
			target.x = _anchor_rect.end.x - size.x
			target.y = _anchor_rect.end.y + GAP
		Side.ABOVE:
			target.x = _anchor_rect.get_center().x - size.x / 2.0
			target.y = _anchor_rect.position.y - GAP - size.y
	target.x = clampf(target.x, area.position.x + GAP, maxf(area.position.x + GAP, area.end.x - size.x - GAP))
	target.y = clampf(target.y, area.position.y + GAP, maxf(area.position.y + GAP, area.end.y - size.y - GAP))
	global_position = target
