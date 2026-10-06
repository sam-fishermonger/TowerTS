class_name TowerShop
extends HBoxContainer
## Barre d'achat : une case TowerShopButton par type de tour du niveau. Une seule
## case peut être enfoncée (la tour choisie pour être posée) ; les tours trop chères
## sont grisées, sauf celle déjà choisie.

## Émis quand le joueur choisit une tour à placer (null = aucune).
signal tower_selected(data: TowerData)
## Émis quand la souris entre sur une case (pour afficher la fiche de la tour).
signal tower_hovered(button: TowerShopButton)
signal hover_ended

## Largeur que la barre peut prendre sans pousser les boutons de droite : au-delà de
## quelques tours (tours débloquées dans l'arbre), les cases rétrécissent.
const MAX_WIDTH := 990.0
const MIN_SLOT_WIDTH := 70.0

var _group := ButtonGroup.new()
var _gold := 0


func _ready() -> void:
	_group.allow_unpress = true


func setup(tower_types: Array[TowerData]) -> void:
	var separation := get_theme_constant("separation")
	var slot_width := clampf(floorf(MAX_WIDTH / maxi(tower_types.size(), 1)) - separation,
		MIN_SLOT_WIDTH, TowerShopButton.SLOT_SIZE.x)
	for data in tower_types:
		var button := TowerShopButton.new(data)
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


## Enfonce la case de la tour donnée (null = aucune), sans émettre tower_selected.
func set_selected(data: TowerData) -> void:
	for button: TowerShopButton in get_children():
		button.set_pressed_no_signal(button.data == data)
	refresh()


## Remet à jour les prix (ils dépendent de l'arbre des améliorations) et les cases grisées.
func refresh() -> void:
	for button: TowerShopButton in get_children():
		var cost := button.data.get_cost()
		button.disabled = cost > _gold and not button.button_pressed
		button.set_price(cost, cost <= _gold)


func _on_button_pressed() -> void:
	var pressed := _group.get_pressed_button() as TowerShopButton
	tower_selected.emit(pressed.data if pressed else null)
