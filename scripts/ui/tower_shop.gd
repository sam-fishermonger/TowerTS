class_name TowerShop
extends HBoxContainer
## Barre d'achat : une case TowerShopButton par type de tour du niveau. Une seule
## case peut être enfoncée (la tour choisie pour être posée) ; les tours trop chères
## sont grisées, sauf celle déjà choisie. Les touches 1 à 9 puis 0 choisissent les dix
## premières cases ; leur chiffre est affiché dans un coin de la case.

## Émis quand le joueur choisit une tour à placer (null = aucune).
signal tower_selected(data: TowerData)
## Émis quand la souris entre sur une case (pour afficher la fiche de la tour).
signal tower_hovered(button: TowerShopButton)
signal hover_ended

## Largeur que la barre peut prendre sans pousser les boutons de droite : au-delà de
## quelques tours (tours débloquées dans l'arbre), les cases rétrécissent.
const MAX_WIDTH := 990.0
const MIN_SLOT_WIDTH := 70.0
## Touches des cases, dans l'ordre (positions physiques, comme en QWERTY).
const SLOT_KEYS: Array[Key] = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0]
const SLOT_KEYPAD_KEYS: Array[Key] = [KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4, KEY_KP_5,
	KEY_KP_6, KEY_KP_7, KEY_KP_8, KEY_KP_9, KEY_KP_0]

## Largeur réellement disponible (moins en mode Conquête, où un bouton suit la barre).
var max_width := MAX_WIDTH

var _group := ButtonGroup.new()
var _gold := 0
## Barre verrouillée (fin de partie) : toutes les cases sont grisées.
var _locked := false
## Mode Conquête : pierre disponible, et pierre demandée par chaque type de tour
## (TowerData -> int ; vide hors de ce mode).
var stone_cost := Callable()
var _stone := 0


func _ready() -> void:
	_group.allow_unpress = true


func setup(tower_types: Array[TowerData]) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var separation := get_theme_constant("separation")
	var slot_width := clampf(floorf(max_width / maxi(tower_types.size(), 1)) - separation,
		MIN_SLOT_WIDTH, TowerShopButton.SLOT_SIZE.x)
	for i in tower_types.size():
		var button := TowerShopButton.new(tower_types[i])
		if i < SLOT_KEYS.size():
			button.hotkey = OS.get_keycode_string(SLOT_KEYS[i])
		button.custom_minimum_size.x = slot_width
		button.button_group = _group
		button.pressed.connect(_on_button_pressed)
		button.mouse_entered.connect(tower_hovered.emit.bind(button))
		button.mouse_exited.connect(hover_ended.emit)
		add_child(button)
	refresh()


func set_gold(gold: int) -> void:
	_gold = gold
	refresh()


func set_stone(stone: int) -> void:
	_stone = stone
	refresh()


## Enfonce la case de la tour donnée (null = aucune), sans émettre tower_selected.
func set_selected(data: TowerData) -> void:
	for button: TowerShopButton in get_children():
		button.set_pressed_no_signal(button.data == data)
	refresh()


## Grise toutes les cases pour de bon (fin de partie) : plus de choix ni de fiche au survol.
func lock() -> void:
	_locked = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for button: TowerShopButton in get_children():
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	refresh()


## Remet à jour les prix (ils dépendent de l'arbre des améliorations) et les cases grisées.
func refresh() -> void:
	for button: TowerShopButton in get_children():
		var cost := button.data.get_cost()
		var stone: int = stone_cost.call(button.data) if stone_cost.is_valid() else -1
		var affordable := cost <= _gold and stone <= _stone
		button.disabled = _locked or (not affordable and not button.button_pressed)
		button.set_price(cost, affordable, stone)


## Case choisie par une touche (rangée des chiffres ou pavé numérique), ou -1.
static func slot_for_key(physical_keycode: Key) -> int:
	var slot := SLOT_KEYS.find(physical_keycode)
	return slot if slot >= 0 else SLOT_KEYPAD_KEYS.find(physical_keycode)


## Choisit la tour de la case donnée, ou la repose si elle était déjà choisie (comme
## un clic sur la case). Sans effet sur une case grisée ou qui n'existe pas.
func toggle_slot(index: int) -> void:
	if index < 0 or index >= get_child_count():
		return
	var button := get_child(index) as TowerShopButton
	if not button.disabled:
		tower_selected.emit(null if button.button_pressed else button.data)


func _on_button_pressed() -> void:
	var pressed := _group.get_pressed_button() as TowerShopButton
	tower_selected.emit(pressed.data if pressed else null)


## Choisit la tour suivante (step = 1) ou précédente (-1) de la barre, en sautant les
## cases grisées (LB et RB à la manette). Sans tour choisie, part du bord de la barre.
func select_neighbour(step: int) -> void:
	var count := get_child_count()
	if count == 0:
		return
	var pressed := _group.get_pressed_button()
	var index := pressed.get_index() if pressed else (-1 if step > 0 else count)
	for i in count:
		index = posmod(index + step, count)
		var button := get_child(index) as TowerShopButton
		if not button.disabled and button != pressed:
			tower_selected.emit(button.data)
			return
