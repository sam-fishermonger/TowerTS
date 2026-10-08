class_name UiStyle
## Style « console tactique » de toute l'interface : fonds ardoise translucides, liserés cyan,
## angles vifs et boutons inclinés. Le thème global (resources/ui/theme.tres, regénéré par
## tools/generate_theme.gd) et les styles posés par le code viennent tous d'ici : pour changer
## l'allure du jeu, il suffit de modifier ce fichier puis de regénérer le thème.
##
## Les styles posés par le code gardent leur couleur d'accent (couleur de la tour, du monde,
## du pouvoir, de l'état), qui devient le liseré épais du panneau ou du bouton.

## Couleur d'accent par défaut : liserés, bouton enfoncé, barres de progression.
const ACCENT := Color(0.35, 0.85, 1.0)
## Fond des écrans de menu (derrière les panneaux).
const BACKGROUND := Color(0.03, 0.06, 0.09)
## Fond des panneaux.
const PANEL_COLOR := Color(0.04, 0.08, 0.11, 0.9)
## Fond des boutons au repos et survolés.
const BUTTON_COLOR := Color(0.08, 0.16, 0.22, 0.92)
const BUTTON_HOVER_COLOR := Color(0.1, 0.3, 0.4, 0.95)
const BUTTON_DISABLED_COLOR := Color(0.06, 0.09, 0.11, 0.85)
## Texte : courant, sur un bouton enfoncé, désactivé.
const TEXT_COLOR := Color(0.86, 0.95, 1.0)
const TEXT_PRESSED_COLOR := Color.WHITE
const TEXT_DISABLED_COLOR := Color(0.45, 0.55, 0.6)
## Contour du focus clavier.
const FOCUS_COLOR := Color(1.0, 0.75, 0.2)
## Inclinaison des boutons (décalage horizontal du haut par rapport au bas, en proportion de la hauteur).
const BUTTON_SKEW := 0.18
## Épaisseur du liseré d'accent, à gauche des boutons et sur un bord des panneaux.
const EDGE_WIDTH := 4

const TEXT_FONT: Font = preload("res://assets/fonts/police_interface.tres")
const TITLE_FONT: Font = preload("res://assets/fonts/police_titres.tres")


## Emplacement libre et interdit (aperçu de la tour à poser, rappel au tactile) : vert et
## rouge, ou bleu et orange en mode daltonien (voir is_colorblind).
const VALID_COLOR := Color(0.3, 1.0, 0.4)
const INVALID_COLOR := Color(1.0, 0.3, 0.3)
const COLORBLIND_VALID_COLOR := Color(0.3, 0.65, 1.0)
const COLORBLIND_INVALID_COLOR := Color(1.0, 0.6, 0.1)


## Méta du moteur : le mode daltonien choisi dans les Options (GameSettings la tient à
## jour). Les dessins la lisent ici, sans passer par la sauvegarde : les ressources des
## monstres (EnemyData) ne peuvent pas dépendre de Progress sans boucle de chargement.
const COLORBLIND_META := &"ui_colorblind"


static func is_colorblind() -> bool:
	return Engine.get_meta(COLORBLIND_META, false)


static func valid_color() -> Color:
	return COLORBLIND_VALID_COLOR if is_colorblind() else VALID_COLOR


static func invalid_color() -> Color:
	return COLORBLIND_INVALID_COLOR if is_colorblind() else INVALID_COLOR


## Panneau : fond ardoise, liseré fin, et un bord épais de la couleur d'accent
## (à gauche par défaut, SIDE_TOP pour les cartes).
static func panel(accent := Color(ACCENT, 0.6), margin := 14.0, edge := SIDE_LEFT,
		background := PANEL_COLOR) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = accent
	style.set_border_width_all(1)
	style.set_border_width(edge, EDGE_WIDTH)
	style.set_content_margin_all(margin)
	return style


## Styles d'un bouton, par état (normal, hover, pressed, hover_pressed, disabled, focus).
## L'accent (couleur de tour, de pouvoir...) colore le liseré et le fond du bouton enfoncé.
## Les cases à image (barre d'achat, pouvoirs) restent droites (slanted à false).
static func button_styles(accent := ACCENT, margin_left := 18.0, margin_right := 18.0,
		slanted := true) -> Dictionary:
	var normal := StyleBoxFlat.new()
	normal.bg_color = BUTTON_COLOR
	normal.border_color = Color(accent, 0.5)
	normal.set_border_width_all(1)
	normal.border_width_left = EDGE_WIDTH
	if slanted:
		normal.skew = Vector2(BUTTON_SKEW, 0)
	normal.content_margin_left = margin_left
	normal.content_margin_right = margin_right
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4
	normal.anti_aliasing = true
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = BUTTON_HOVER_COLOR
	hover.border_color = accent
	var pressed := normal.duplicate() as StyleBoxFlat
	# Fond teinté mais sombre : les textes colorés (tours, difficultés) restent lisibles.
	pressed.bg_color = accent.darkened(0.5)
	pressed.border_color = accent.lightened(0.4)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = BUTTON_DISABLED_COLOR
	disabled.border_color = Color(1, 1, 1, 0.12)
	var focus := normal.duplicate() as StyleBoxFlat
	focus.draw_center = false
	focus.border_color = FOCUS_COLOR
	focus.set_border_width_all(2)
	return {
		&"normal": normal, &"hover": hover, &"pressed": pressed, &"hover_pressed": pressed,
		&"disabled": disabled, &"focus": focus,
	}


## Case à image (barre d'achat, pouvoirs) : droite, liseré de sa couleur ; choisie, elle
## garde un fond sombre teinté pour que son texte coloré reste lisible.
static func slot_styles(accent: Color, margin_left := 0.0, margin_right := 0.0) -> Dictionary:
	var styles := button_styles(accent, margin_left, margin_right, false)
	var pressed: StyleBoxFlat = styles[&"pressed"]
	pressed.bg_color = accent.darkened(0.6)
	pressed.border_color = accent.lightened(0.3)
	pressed.set_border_width_all(2)
	pressed.border_width_left = EDGE_WIDTH
	(styles[&"disabled"] as StyleBoxFlat).border_color = Color(accent, 0.2)
	return styles


## Pose des styles (par état) sur un bouton.
## Les styles sont posés d'un coup : le bouton ne se recalcule qu'une fois.
static func apply_styles(button: Button, styles: Dictionary) -> void:
	button.begin_bulk_theme_override()
	for state: StringName in styles:
		button.add_theme_stylebox_override(state, styles[state])
	button.end_bulk_theme_override()


## Pose les styles de button_styles() sur un bouton.
static func style_button(button: Button, accent := ACCENT, margin_left := 18.0, margin_right := 18.0,
		slanted := true) -> void:
	apply_styles(button, button_styles(accent, margin_left, margin_right, slanted))


## Barre de progression : fond sombre liseré, remplissage plein.
static func bar_background(accent := ACCENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.05, 0.07, 0.9)
	style.border_color = Color(accent, 0.4)
	style.set_border_width_all(1)
	return style


static func bar_fill(color := ACCENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	return style


## Variation de Label des titres d'écran : police des titres et ombre portée. Dans une
## scène, la mettre dans « Theme Type Variation » du Label.
const TITLE_VARIATION := &"TitreEcran"


static func style_title(label: Label) -> void:
	label.theme_type_variation = TITLE_VARIATION


## Thème global du jeu (voir tools/generate_theme.gd).
static func build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = TEXT_FONT
	theme.default_font_size = 18
	var bar := panel(Color(ACCENT, 0.45), 0.0, SIDE_TOP)
	bar.border_width_top = 2
	bar.border_color = Color(ACCENT, 0.7)
	var popup := panel(ACCENT, 10.0, SIDE_LEFT, Color(0.03, 0.06, 0.09, 0.96))
	theme.set_stylebox(&"panel", &"PanelContainer", bar)
	theme.set_stylebox(&"panel", &"Panel", bar)
	for type: StringName in [&"PopupPanel", &"TooltipPanel", &"AcceptDialog"]:
		theme.set_stylebox(&"panel", type, popup)
	theme.set_stylebox(&"embedded_border", &"Window", popup)
	theme.set_stylebox(&"embedded_unfocused_border", &"Window", popup)
	var styles := button_styles()
	for type: StringName in [&"Button", &"OptionButton", &"MenuButton"]:
		for state: StringName in styles:
			theme.set_stylebox(state, type, styles[state])
		theme.set_color(&"font_color", type, TEXT_COLOR)
		theme.set_color(&"font_hover_color", type, Color.WHITE)
		theme.set_color(&"font_focus_color", type, Color.WHITE)
		theme.set_color(&"font_pressed_color", type, TEXT_PRESSED_COLOR)
		theme.set_color(&"font_hover_pressed_color", type, TEXT_PRESSED_COLOR)
		theme.set_color(&"font_disabled_color", type, TEXT_DISABLED_COLOR)
	theme.set_color(&"font_color", &"Label", TEXT_COLOR)
	theme.set_type_variation(TITLE_VARIATION, &"Label")
	theme.set_font(&"font", TITLE_VARIATION, TITLE_FONT)
	theme.set_color(&"font_shadow_color", TITLE_VARIATION, Color(0, 0, 0, 0.6))
	theme.set_constant(&"shadow_offset_x", TITLE_VARIATION, 3)
	theme.set_constant(&"shadow_offset_y", TITLE_VARIATION, 3)
	theme.set_color(&"default_color", &"RichTextLabel", TEXT_COLOR)
	theme.set_stylebox(&"background", &"ProgressBar", bar_background())
	theme.set_stylebox(&"fill", &"ProgressBar", bar_fill())
	var slider := bar_background()
	slider.content_margin_top = 3
	slider.content_margin_bottom = 3
	theme.set_stylebox(&"slider", &"HSlider", slider)
	theme.set_stylebox(&"grabber_area", &"HSlider", bar_fill())
	theme.set_stylebox(&"grabber_area_highlight", &"HSlider", bar_fill(ACCENT.lightened(0.3)))
	return theme
