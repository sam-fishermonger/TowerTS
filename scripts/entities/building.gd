class_name Building
extends Entity
## Bâtiment du mode Conquête, posé comme une tour puis bâti par les ouvriers :
## - Dépôt : les ouvriers y déposent la pierre et l'essence, au lieu de rentrer au QG ;
## - Maison : des ouvriers de plus au maximum ;
## - Extracteur : posé sur un filon d'essence, il en tire sans ouvrier ;
## - Barricade : posée sur le chemin, elle arrête les monstres au sol qui la frappent ;
## - Caserne : elle produit des soldats qui retiennent les monstres sur le chemin ;
## - Atelier : il lance des améliorations pour la partie (Research), une à la fois.
## Les Pillards (EnemyData.raider) quittent le chemin pour les frapper ; un bâtiment
## détruit disparaît. C'est le mode Conquête (Conquest) qui les pose et les compte.

enum Kind { DEPOT, HOUSE, EXTRACTOR, BARRICADE, BARRACKS, WORKSHOP }

## Où se pose un bâtiment.
enum Placement { GROUND, VEIN, PATH }

## Fiche de chaque bâtiment, dans l'ordre de Kind : nom, description, prix (or, pierre,
## essence), vie, secondes de chantier pour un seul ouvrier, couleur et emplacement.
const DEFINITIONS: Array[Dictionary] = [
	{name = "Dépôt", gold = 50, stone = 30, essence = 0, health = 300.0, build_time = 8.0,
		color = Color(0.85, 0.65, 0.35), placement = Placement.GROUND,
		description = "Les ouvriers y déposent la pierre et l'essence au lieu de rentrer au QG : à poser près des gisements lointains."},
	{name = "Maison", gold = 40, stone = 30, essence = 0, health = 250.0, build_time = 6.0,
		color = Color(0.95, 0.55, 0.45), placement = Placement.GROUND,
		description = "Loge 2 ouvriers de plus."},
	{name = "Extracteur", gold = 60, stone = 40, essence = 0, health = 250.0, build_time = 8.0,
		color = Color(0.75, 0.45, 1.0), placement = Placement.VEIN,
		description = "Se pose sur un filon d'essence et en tire 1 toutes les 6 secondes, sans ouvrier et sans l'épuiser."},
	{name = "Barricade", gold = 15, stone = 25, essence = 0, health = 500.0, build_time = 4.0,
		color = Color(0.7, 0.5, 0.3), placement = Placement.PATH,
		description = "Se pose sur le chemin : les monstres au sol s'y arrêtent et doivent la casser pour passer. Les volants la survolent."},
	{name = "Caserne", gold = 90, stone = 40, essence = 4, health = 400.0, build_time = 10.0,
		color = Color(0.5, 0.75, 1.0), placement = Placement.GROUND,
		description = "Envoie 2 soldats sur le chemin le plus proche ; un soldat tombé est remplacé au bout de 12 secondes."},
	{name = "Atelier", gold = 80, stone = 50, essence = 0, health = 300.0, build_time = 10.0,
		color = Color(0.4, 0.88, 0.78), placement = Placement.GROUND,
		description = "Lance des améliorations pour la partie (ouvriers, tours et monde) contre de l'or, de la pierre et de l'essence, une à la fois."},
]

## Maison : ouvriers de plus au maximum.
const HOUSE_WORKERS := 2
## Extracteur : secondes entre deux essences.
const EXTRACT_INTERVAL := 6.0
## Barricade : dégâts par seconde que lui fait un monstre arrêté, par vie qu'il coûterait.
const BARRICADE_DAMAGE_PER_LIFE := 12.0
## Caserne : soldats sur le terrain au plus, secondes pour en remplacer un, et leurs
## statistiques (comme celles du pouvoir Renforts).
const BARRACKS_SOLDIERS := 2
const BARRACKS_RESPAWN := 12.0
const SOLDIER_HEALTH := 160.0
const SOLDIER_DAMAGE := 24.0
const SOLDIER_RADIUS := 40.0
## Taille du dessin, comme une tour.
const SIZE := 44.0

## Émis quand le bâtiment est détruit par les monstres (juste avant son retrait).
signal destroyed(building: Building)

var kind := Kind.DEPOT
var conquest: Conquest
## Case occupée.
var cell := Vector2i.ZERO
## Avancement du chantier, de 0 à 1 : il ne sert à rien avant d'être bâti.
var build_progress := 0.0
var health := 0.0
var max_health := 0.0

var _timer := 0.0
## Caserne : ses soldats encore sur le terrain.
var _soldiers: Array[Soldier] = []
## Caserne : stats des soldats, prises comme celles d'un pouvoir Renforts.
var _soldier_power: Power
## Atelier : amélioration en cours de recherche (&"" = aucune), le niveau qu'elle vise,
## et les secondes qui restent.
var research_id := &""
var research_level := 0
var research_left := 0.0


static func get_definition(building_kind: int) -> Dictionary:
	return DEFINITIONS[building_kind]


func _ready() -> void:
	max_health = get_definition(kind).health * conquest.get_building_health_multiplier()
	health = max_health
	add_to_group(Conquest.RAID_TARGET_GROUP)
	if kind == Kind.BARRACKS:
		_soldier_power = Power.new()
		_soldier_power.kind = Power.Kind.REINFORCEMENTS
		_soldier_power.health = SOLDIER_HEALTH
		_soldier_power.damage = SOLDIER_DAMAGE
		_soldier_power.radius = SOLDIER_RADIUS
		# Ils restent jusqu'à tomber.
		_soldier_power.duration = 1.0e9


func get_display_name() -> String:
	return get_definition(kind).name


func is_built() -> bool:
	return build_progress >= 1.0


## Fait avancer le chantier (part de la construction, 1 = toute). Renvoie true si le
## bâtiment vient d'être terminé.
func advance_construction(amount: float) -> bool:
	if is_built():
		return false
	build_progress = minf(build_progress + amount, 1.0)
	queue_redraw()
	if not is_built():
		return false
	_timer = conquest.get_extract_interval()
	if kind == Kind.BARRACKS:
		# Une caserne bâtie envoie tous ses soldats d'un coup, puis les remplace un à un.
		_timer = BARRACKS_RESPAWN
		for i in BARRACKS_SOLDIERS:
			_spawn_soldier()
	return true


## Un Pillard frappe le bâtiment (chantier compris).
func can_be_raided() -> bool:
	return is_alive


func take_damage(amount: float) -> void:
	if not is_alive or amount <= 0.0:
		return
	health -= amount
	queue_redraw()
	if health <= 0.0:
		destroyed.emit(self)
		despawn()


func _process(delta: float) -> void:
	if not is_built():
		return
	match kind:
		Kind.EXTRACTOR:
			_timer -= delta
			if _timer <= 0.0:
				_timer += conquest.get_extract_interval()
				conquest.add_essence(1, global_position + Vector2(0, -SIZE / 2.0 - 6.0))
		Kind.BARRICADE:
			_hold_enemies(delta)
		Kind.BARRACKS:
			_soldiers = _soldiers.filter(func(soldier: Soldier) -> bool: return is_instance_valid(soldier) and soldier.is_alive)
			if _soldiers.size() < BARRACKS_SOLDIERS:
				_timer -= delta
				if _timer <= 0.0:
					_timer = BARRACKS_RESPAWN
					_spawn_soldier()
		Kind.WORKSHOP:
			if research_id != &"":
				research_left -= delta
				if research_left <= 0.0:
					var finished := research_id
					research_id = &""
					conquest.complete_research(finished)


## Barricade : arrête les monstres au sol qui entrent sur sa case et encaisse leurs coups.
func _hold_enemies(delta: float) -> void:
	var map := conquest.level.map
	var damage := 0.0
	for node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy := node as Enemy
		if not enemy.is_alive or enemy.data.flying or enemy.is_raiding():
			continue
		if enemy.holder == self:
			damage += enemy.data.damage * BARRICADE_DAMAGE_PER_LIFE
		elif not enemy.is_held() and map.world_to_cell(enemy.global_position) == cell:
			enemy.holder = self
	if damage > 0.0:
		take_damage(damage * delta)


## Atelier : lance la recherche d'une amélioration (déjà payée) vers le niveau donné.
func start_research(id: StringName, at_level: int) -> void:
	research_id = id
	research_level = at_level
	research_left = Research.get_time(at_level)


## Atelier : part de la recherche en cours déjà faite, de 0 à 1.
func get_research_progress() -> float:
	if research_id == &"":
		return 0.0
	return 1.0 - research_left / Research.get_time(research_level)


## Fortifications : la vie (et le maximum) grandit d'autant que le bonus.
func scale_health(ratio: float) -> void:
	max_health *= ratio
	health *= ratio
	queue_redraw()


## Caserne : un soldat de plus, posté sur le chemin le plus proche.
func _spawn_soldier() -> void:
	var soldier := Soldier.new()
	soldier.power = _soldier_power
	conquest.level.allies.add_child(soldier)
	var post := conquest.level.map.get_closest_path_point(global_position)
	soldier.global_position = post + Vector2.from_angle(TAU * _soldiers.size() / BARRACKS_SOLDIERS) * 12.0
	_soldiers.append(soldier)


func _draw() -> void:
	var definition := get_definition(kind)
	if Relief.enabled:
		_draw_relief()
		return
	if not is_built():
		draw_icon(self, kind, Vector2.ZERO, SIZE, Color(1, 1, 1, 0.35))
		_draw_scaffolding()
	else:
		draw_icon(self, kind, Vector2.ZERO, SIZE)
	if health < max_health:
		var width := SIZE * 0.8
		var top_left := Vector2(-width / 2.0, SIZE / 2.0 - 2.0)
		draw_rect(Rect2(top_left, Vector2(width, 4)), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(top_left, Vector2(width * maxf(health, 0.0) / max_health, 4)), definition.color.lightened(0.3))


## Vue de trois quarts : le bâtiment debout sur sa case (ou son chantier, avec l'arc doré
## de l'avancement comme pour une tour), et sa barre de vie au-dessus du toit.
func _draw_relief() -> void:
	if not is_built():
		BuildingRelief.draw_site(self, kind, Vector2.ZERO)
		var radius := SIZE * 0.62
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(0, 0, 0, 0.45), 5.0)
		if build_progress > 0.0:
			draw_arc(Vector2.ZERO, radius, -PI / 2.0, -PI / 2.0 + TAU * build_progress, 40, Color(1.0, 0.82, 0.25), 4.0)
	else:
		BuildingRelief.draw(self, kind, Vector2.ZERO)
	if health < max_health:
		var width := SIZE * 0.8
		var top_left := Vector2(-width / 2.0, -BuildingRelief.top_height(kind) - 10.0)
		draw_rect(Rect2(top_left - Vector2.ONE, Vector2(width + 2.0, 6)), Relief.OUTLINE)
		draw_rect(Rect2(top_left, Vector2(width * maxf(health, 0.0) / max_health, 4)), get_definition(kind).color.lightened(0.3))


## Échafaudage et arc doré du chantier, comme pour une tour.
func _draw_scaffolding() -> void:
	var half := SIZE / 2.0
	var wood := Color(0.72, 0.52, 0.3)
	draw_rect(Rect2(-half, -half, SIZE, SIZE), wood, false, 2.0)
	draw_line(Vector2(-half, -half), Vector2(half, half), Color(wood, 0.7), 1.5)
	draw_line(Vector2(half, -half), Vector2(-half, half), Color(wood, 0.7), 1.5)
	var radius := SIZE * 0.62
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(0, 0, 0, 0.45), 5.0)
	if build_progress > 0.0:
		draw_arc(Vector2.ZERO, radius, -PI / 2.0, -PI / 2.0 + TAU * build_progress, 40, Color(1.0, 0.82, 0.25), 4.0)


## Dessin d'un bâtiment vu de dessus, centré sur `center`, dans un carré de côté `size`
## (carte à plat, barre d'achat, lexique ; la vue de trois quarts dessine BuildingRelief).
static func draw_icon(canvas: CanvasItem, building_kind: int, center: Vector2, size: float,
		modulate := Color.WHITE) -> void:
	var color: Color = get_definition(building_kind).color * modulate
	var dark := Color(color.darkened(0.55), color.a)
	var half := size / 2.0
	match building_kind:
		Kind.DEPOT:
			# Hangar : toit en pente, porte, et une caisse devant.
			var body := Rect2(center + Vector2(-half * 0.8, -half * 0.25), Vector2(size * 0.8, size * 0.62))
			canvas.draw_rect(body, color.darkened(0.15))
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(-half * 0.92, -half * 0.2),
				center + Vector2(0, -half * 0.8), center + Vector2(half * 0.92, -half * 0.2)]), color.lightened(0.15))
			canvas.draw_rect(Rect2(center + Vector2(-half * 0.25, half * 0.05), Vector2(size * 0.25, size * 0.32)), dark)
			canvas.draw_rect(body, dark, false, 1.5)
		Kind.HOUSE:
			var body := Rect2(center + Vector2(-half * 0.6, -half * 0.15), Vector2(size * 0.6, size * 0.55))
			canvas.draw_rect(body, Color(0.9, 0.85, 0.75, modulate.a))
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(-half * 0.8, -half * 0.1),
				center + Vector2(0, -half * 0.85), center + Vector2(half * 0.8, -half * 0.1)]), color)
			canvas.draw_rect(Rect2(center + Vector2(-half * 0.12, half * 0.12), Vector2(size * 0.14, size * 0.28)), dark)
			canvas.draw_rect(Rect2(center + Vector2(half * 0.22, half * 0.0), Vector2(size * 0.14, size * 0.12)),
				Color(1.0, 0.85, 0.4, modulate.a))
			canvas.draw_rect(body, dark, false, 1.5)
		Kind.EXTRACTOR:
			# Foreuse : un socle, un mât et un cristal d'essence qui brille.
			canvas.draw_rect(Rect2(center + Vector2(-half * 0.7, half * 0.25), Vector2(size * 0.7, size * 0.3)), Color(0.4, 0.4, 0.45, modulate.a))
			canvas.draw_line(center + Vector2(-half * 0.45, half * 0.25), center + Vector2(0, -half * 0.75), Color(0.6, 0.6, 0.65, modulate.a), 3.0)
			canvas.draw_line(center + Vector2(half * 0.45, half * 0.25), center + Vector2(0, -half * 0.75), Color(0.6, 0.6, 0.65, modulate.a), 3.0)
			canvas.draw_colored_polygon(Conquest.crystal_points(center + Vector2(0, -half * 0.05), size * 0.28), color)
		Kind.BARRICADE:
			# Pieux croisés.
			for i in 3:
				var x := (i - 1) * half * 0.55
				canvas.draw_line(center + Vector2(x - half * 0.3, half * 0.6), center + Vector2(x + half * 0.3, -half * 0.6), color, 5.0)
				canvas.draw_line(center + Vector2(x + half * 0.3, half * 0.6), center + Vector2(x - half * 0.3, -half * 0.6), color.darkened(0.2), 5.0)
			canvas.draw_line(center + Vector2(-half * 0.85, half * 0.1), center + Vector2(half * 0.85, half * 0.1), dark, 3.0)
		Kind.BARRACKS:
			# Tente et bannière.
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(-half * 0.8, half * 0.5),
				center + Vector2(0, -half * 0.55), center + Vector2(half * 0.8, half * 0.5)]), color.darkened(0.2))
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(-half * 0.2, half * 0.5),
				center + Vector2(0, -half * 0.05), center + Vector2(half * 0.2, half * 0.5)]), dark)
			canvas.draw_line(center + Vector2(0, -half * 0.55), center + Vector2(0, -half * 0.95), Color(0.8, 0.8, 0.8, modulate.a), 2.0)
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -half * 0.95),
				center + Vector2(half * 0.45, -half * 0.82), center + Vector2(0, -half * 0.68)]), Color(1.0, 0.35, 0.3, modulate.a))
		Kind.WORKSHOP:
			# Établi : un toit plat, une enclume devant et une roue dentée.
			var body := Rect2(center + Vector2(-half * 0.75, -half * 0.3), Vector2(size * 0.75, size * 0.6))
			canvas.draw_rect(body, color.darkened(0.2))
			canvas.draw_rect(Rect2(center + Vector2(-half * 0.88, -half * 0.5), Vector2(size * 0.88, size * 0.2)), color.lightened(0.1))
			canvas.draw_rect(body, dark, false, 1.5)
			_draw_gear(canvas, center + Vector2(half * 0.05, half * 0.02), half * 0.36, Color(0.85, 0.85, 0.9, modulate.a), dark)
			canvas.draw_rect(Rect2(center + Vector2(-half * 0.6, half * 0.4), Vector2(size * 0.24, size * 0.1)), Color(0.35, 0.35, 0.4, modulate.a))


## Roue dentée (dessin de l'Atelier).
static func _draw_gear(canvas: CanvasItem, center: Vector2, radius: float, color: Color, outline: Color) -> void:
	var points := PackedVector2Array()
	for i in 16:
		var angle := TAU * i / 16.0
		points.append(center + Vector2.from_angle(angle) * (radius if i % 2 == 0 else radius * 0.72))
	canvas.draw_colored_polygon(points, color)
	points.append(points[0])
	canvas.draw_polyline(points, outline, 1.2)
	canvas.draw_circle(center, radius * 0.3, outline)
