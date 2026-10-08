class_name Worker
extends Entity
## Ouvrier du mode Conquête : il mine la pierre des rochers ou l'essence des filons et la
## rapporte au dépôt le plus proche (le QG ou un Dépôt), ou bâtit les chantiers de tours
## et de bâtiments. C'est le mode Conquête (Conquest) qui lui donne ses ordres quand il
## n'a rien à faire. Il marche tout droit, quitte à traverser le chemin, mais attend au
## bord qu'aucun monstre au sol ne soit tout près pour s'y engager. Un monstre au sol qui
## le touche le blesse, et les Pillards viennent le frapper, sauf près du QG, où il est à
## l'abri et se soigne. Un ouvrier tombé perd ce qu'il portait.
## Le joueur peut aussi le choisir (clic, cadre ou bouton du HUD) et l'affecter à la main
## à une tâche (`order`) : il s'y tient, à plusieurs sur la même s'il le faut, puis
## revient aux ordres automatiques quand elle est finie.

enum State { IDLE, TO_ROCK, MINING, TO_DEPOT, TO_SITE, BUILDING }
## Tâche donnée à la main : aucune (ordres automatiques), miner un gisement jusqu'à ce
## qu'il soit vide, bâtir un chantier jusqu'au bout, ou rester à l'abri au QG.
enum Order { AUTO, MINE, BUILD, HOME }

## Vitesse de marche, en pixels par seconde.
const SPEED := 80.0
const MAX_HEALTH := 60.0
## Points de vie rendus par seconde au QG.
const HEAL_PER_SECOND := 15.0
## Pierre portée à chaque voyage…
const CARRY := 3
## … ou essence.
const ESSENCE_CARRY := 2
## Secondes pour remplir sa charge au rocher, ou au filon.
const MINE_TIME := 2.5
const ESSENCE_MINE_TIME := 4.0
## Distance au centre d'un rocher ou d'un chantier à laquelle l'ouvrier travaille.
const REACH := 38.0
## Places autour d'un chantier où l'on est plusieurs (angles, le premier devant).
const BUILD_PLACES: Array[float] = [PI / 2.0, PI / 4.0, PI * 0.75, 0.0, PI, -PI / 4.0, -PI * 0.75, -PI / 2.0]
## Distance au QG à laquelle il dépose sa charge, et en dessous de laquelle il est à l'abri.
const DEPOT_REACH := 36.0
const SAFE_RADIUS := 56.0
## Dégâts par seconde d'un monstre au sol qui touche l'ouvrier.
const CONTACT_DPS := 25.0
## Distance à un monstre au sol en dessous de laquelle il ne s'engage pas sur le chemin.
const CROSSING_MARGIN := 70.0
const BODY_RADIUS := 10.0
const COLOR := Color(1.0, 0.72, 0.25)
## Cercle sous un ouvrier choisi.
const SELECTED_COLOR := Color(0.45, 1.0, 0.55)
## Distance du point visé au corps de l'ouvrier en dessous de laquelle un clic le choisit.
const PICK_RADIUS := 18.0

## Émis quand l'ouvrier tombe (juste avant son retrait).
signal killed(worker: Worker)

var conquest: Conquest
var state := State.IDLE
## Gisement miné (TO_ROCK, MINING) : un rocher ou un filon.
var rock_cell := Vector2i.ZERO
## Chantier bâti (TO_SITE, BUILDING) : une tour (Tower) ou un bâtiment (Building),
## sans type commun qui ait is_built().
var site = null
## Pierre ou essence portée.
var cargo := 0
var cargo_kind := Conquest.Ore.STONE
var health := MAX_HEALTH
## Tâche donnée à la main (Order.AUTO : il suit les ordres du mode Conquête), et son
## gisement ou son chantier.
var order := Order.AUTO
var order_cell := Vector2i.ZERO
var order_site = null
## Place autour du chantier donné à la main (Worker.BUILD_PLACES, -1 : aucune).
var order_slot := -1
## Choisi par le joueur : un cercle vert sous ses pieds.
var selected := false:
	set(value):
		selected = value
		queue_redraw()

## Point où se rendre pour l'ordre en cours.
var _goal := Vector2.ZERO
var _timer := 0.0
## Secondes depuis le début du travail en cours, pour l'animation de l'outil.
var _work_time := 0.0
## Vue de trois quarts : sens du profil (1 vers la droite, -1 vers la gauche), distance
## parcourue (pour faire marcher les jambes) et s'il a bougé à la dernière image.
var _facing := 1.0
var _stride := 0.0
var _moving := false


func _ready() -> void:
	add_to_group(Conquest.RAID_TARGET_GROUP)


func _process(delta: float) -> void:
	_take_contact_damage(delta)
	if not is_alive:
		return
	var before := global_position
	match state:
		State.TO_ROCK:
			if not conquest.has_resource(rock_cell):
				_finish_order()
			elif _walk(delta):
				state = State.MINING
				_timer = (ESSENCE_MINE_TIME if conquest.resource_at(rock_cell) == Conquest.Ore.ESSENCE else MINE_TIME) \
					/ conquest.get_work_speed()
				_work_time = 0.0
		State.MINING:
			_work_time += delta
			if not conquest.has_resource(rock_cell):
				_finish_order()
			else:
				_timer -= delta
				if _timer <= 0.0:
					cargo_kind = conquest.resource_at(rock_cell)
					cargo += conquest.take_resource(rock_cell, maxi(conquest.get_carry(cargo_kind) - cargo, 0))
					go_deposit()
		State.TO_DEPOT:
			if _walk(delta):
				if cargo > 0:
					conquest.deposit(cargo, cargo_kind, global_position)
				cargo = 0
				state = State.IDLE
		State.TO_SITE:
			if not _site_needs_work():
				_finish_order()
			elif _walk(delta):
				state = State.BUILDING
				_work_time = 0.0
		State.BUILDING:
			_work_time += delta
			if not _site_needs_work():
				_finish_order()
			else:
				conquest.build(site, delta * conquest.get_work_speed())
	_update_pose(global_position - before)
	queue_redraw()


## Le joueur l'affecte à une tâche (Order.AUTO : le rend aux ordres automatiques), avec
## sa place autour d'un chantier. Il rapporte d'abord ce qu'il porte s'il va miner, pour
## ne pas mêler pierre et essence.
func assign(new_order: Order, cell := Vector2i.ZERO, target = null, slot := -1) -> void:
	order = new_order
	order_cell = cell
	order_site = target
	order_slot = slot
	match new_order:
		Order.MINE:
			if cargo > 0:
				go_deposit()
			else:
				go_mine(cell, conquest.level.map.cell_to_world(cell))
		Order.BUILD:
			go_build(target, slot)
		Order.HOME:
			go_deposit()
	queue_redraw()


## Ce sur quoi porte sa tâche donnée à la main (Vector2.INF : aucune).
func get_order_target() -> Vector2:
	match order:
		Order.MINE:
			return conquest.level.map.cell_to_world(order_cell)
		Order.BUILD:
			return order_site.global_position if is_instance_valid(order_site) else Vector2.INF
		Order.HOME:
			return conquest.depot_position
	return Vector2.INF


## Point du corps (pour le choisir d'un clic) : au-dessus du pied en vue de trois quarts.
func get_pick_point() -> Vector2:
	return global_position + (Vector2(0, -13) if Relief.enabled else Vector2.ZERO)


## Va miner le rocher de la case donnée : il se place au bord du rocher, de son côté.
func go_mine(cell: Vector2i, rock_center: Vector2) -> void:
	rock_cell = cell
	site = null
	state = State.TO_ROCK
	_goal = rock_center + _side_from(rock_center) * REACH


## Rapporte sa charge au dépôt le plus proche (ou rentre au QG, sans charge).
func go_deposit() -> void:
	site = null
	state = State.TO_DEPOT
	var depot := conquest.nearest_depot(global_position) if cargo > 0 else conquest.depot_position
	_goal = depot + _side_from(depot) * (DEPOT_REACH - 8.0)


## Va bâtir un chantier, tour ou bâtiment (il garde ce qu'il porte) : du côté d'où il
## vient, ou à la place `slot` autour du chantier quand ils y sont plusieurs (0 : devant,
## puis devant à droite, devant à gauche, à droite…).
func go_build(target: Node2D, slot := -1) -> void:
	site = target
	state = State.TO_SITE
	var side := _side_from(target.global_position) if slot < 0 else Vector2.from_angle(BUILD_PLACES[slot % BUILD_PLACES.size()])
	_goal = target.global_position + side * REACH


func is_building(target: Node2D) -> bool:
	return site == target and (state == State.TO_SITE or state == State.BUILDING)


func is_mining() -> bool:
	return state == State.TO_ROCK or state == State.MINING


func is_mining_essence() -> bool:
	return is_mining() and conquest.veins.has(rock_cell)


## Un Pillard peut le frapper : loin du QG.
func can_be_raided() -> bool:
	return is_alive and not conquest.is_safe(global_position)


## Coup d'un Pillard.
func take_damage(amount: float) -> void:
	if not is_alive or amount <= 0.0:
		return
	health -= amount
	if health <= 0.0:
		killed.emit(self)
		despawn()


## Direction de l'ouvrier vue depuis un point (vers le bas s'il est dessus).
func _side_from(center: Vector2) -> Vector2:
	var offset := global_position - center
	return offset.normalized() if offset.length() > 1.0 else Vector2.DOWN


## Avance vers le but. Renvoie true une fois arrivé.
func _walk(delta: float) -> bool:
	var offset := _goal - global_position
	var step := conquest.get_worker_speed() * delta
	var next := _goal if offset.length() <= step else global_position + offset.normalized() * step
	if not _is_safe_to_enter(next):
		return false
	global_position = next
	return next == _goal


## On peut avancer jusqu'à ce point : il n'est pas sur le chemin, l'ouvrier y est déjà,
## ou aucun monstre au sol n'est tout près.
func _is_safe_to_enter(point: Vector2) -> bool:
	var map := conquest.level.map
	if not map.is_cell_walked(map.world_to_cell(point)) or map.is_cell_walked(map.world_to_cell(global_position)):
		return true
	for node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy := node as Enemy
		if enemy.is_alive and not enemy.data.flying and enemy.global_position.distance_to(point) < CROSSING_MARGIN:
			return false
	return true


func _site_needs_work() -> bool:
	return is_instance_valid(site) and site.is_alive and not site.is_built()


## Ordre fini ou devenu impossible : il rapporte ce qu'il porte, sinon il attend un ordre.
## Une tâche donnée à la main finie (chantier bâti, gisement vidé) le rend aux ordres
## automatiques.
func _finish_order() -> void:
	site = null
	if order == Order.BUILD or (order == Order.MINE and not conquest.has_resource(order_cell)):
		order = Order.AUTO
		order_site = null
	if cargo > 0:
		go_deposit()
	else:
		state = State.IDLE


func _take_contact_damage(delta: float) -> void:
	if conquest.is_safe(global_position):
		if health < MAX_HEALTH:
			health = minf(health + HEAL_PER_SECOND * delta, MAX_HEALTH)
		return
	var touched := 0
	for node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy := node as Enemy
		if enemy.is_alive and not enemy.data.flying \
				and enemy.global_position.distance_to(global_position) < enemy.data.radius + BODY_RADIUS:
			touched += 1
	if touched > 0:
		take_damage(CONTACT_DPS * touched * delta)


func _draw() -> void:
	if selected:
		_draw_selection()
	if Relief.enabled:
		_draw_relief()
		return
	# Ombre, corps et casque.
	draw_circle(Vector2(0, 3), BODY_RADIUS, Color(0, 0, 0, 0.3))
	draw_circle(Vector2.ZERO, BODY_RADIUS, Color(0.35, 0.3, 0.25))
	draw_circle(Vector2(0, -2), BODY_RADIUS * 0.75, COLOR)
	draw_arc(Vector2(0, -2), BODY_RADIUS * 0.75, PI, TAU, 10, COLOR.darkened(0.4), 2.0)
	if cargo > 0 and cargo_kind == Conquest.Ore.ESSENCE:
		# L'essence portée : un cristal sur le dos.
		draw_colored_polygon(Conquest.crystal_points(Vector2(0, 6), 11.0), Conquest.ESSENCE_COLOR)
	elif cargo > 0:
		# La pierre portée, sur le dos.
		draw_rect(Rect2(Vector2(-5, 3), Vector2(10, 7)), Color(0.62, 0.62, 0.66))
		draw_rect(Rect2(Vector2(-5, 3), Vector2(10, 7)), Color(0.3, 0.3, 0.33), false, 1.0)
	if state == State.MINING or state == State.BUILDING:
		# Pioche ou marteau qui se balance vers le rocher ou le chantier.
		var toward := (_goal_target() - global_position).normalized()
		var swing := sin(_work_time * 12.0) * 0.7
		var tip := toward.rotated(swing) * 14.0
		draw_line(Vector2.ZERO, tip, Color(0.55, 0.4, 0.25), 2.5)
		draw_line(tip - tip.orthogonal().normalized() * 4.0, tip + tip.orthogonal().normalized() * 4.0,
			Color(0.75, 0.75, 0.8), 3.0)
	if health < MAX_HEALTH:
		var width := 18.0
		var top_left := Vector2(-width / 2.0, -BODY_RADIUS - 8.0)
		draw_rect(Rect2(top_left, Vector2(width, 3)), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(top_left, Vector2(width * health / MAX_HEALTH, 3)), Color(0.4, 1.0, 0.45))


## Ouvrier choisi : un cercle vert à ses pieds et, s'il a une tâche donnée à la main, un
## trait pointillé jusqu'à elle.
func _draw_selection() -> void:
	var target := get_order_target()
	if target != Vector2.INF and target.distance_to(global_position) > REACH + 4.0:
		draw_dashed_line(Vector2.ZERO, to_local(target), Color(SELECTED_COLOR, 0.55), 1.5, 6.0)
	if Relief.enabled:
		var ring := Relief.ellipse(Vector2(0, 1), 12.0, 12.0 * Relief.GROUND_SQUASH, 0.0, TAU, 24)
		draw_polyline(ring, Color(0, 0, 0, 0.45), 4.0, true)
		draw_polyline(ring, SELECTED_COLOR, 2.0, true)
	else:
		draw_arc(Vector2.ZERO, BODY_RADIUS + 4.0, 0.0, TAU, 24, Color(0, 0, 0, 0.45), 4.0)
		draw_arc(Vector2.ZERO, BODY_RADIUS + 4.0, 0.0, TAU, 24, SELECTED_COLOR, 2.0)


## Vue de trois quarts : il se tourne vers où il marche, ou vers son ouvrage.
func _update_pose(moved: Vector2) -> void:
	_moving = moved.length() > 0.01
	_stride += moved.length()
	if absf(moved.x) > 0.01:
		_facing = signf(moved.x)
	elif state == State.MINING or state == State.BUILDING:
		var toward := _goal_target().x - global_position.x
		if absf(toward) > 1.0:
			_facing = signf(toward)


## Vue de trois quarts : un petit ouvrier de profil, au-dessus de son pied, avec son
## casque jaune, sa charge sur le dos et sa pioche (son marteau sur un chantier).
func _draw_relief() -> void:
	Relief.draw_shadow(self, Vector2(1, 0), 9.0, 3.5, 0.32)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_facing, 1.0))
	var outline := Relief.OUTLINE
	var cloth := Color(0.55, 0.36, 0.2)
	var skin := Color(0.96, 0.76, 0.58)
	# Jambes qui marchent : celle du fond d'abord, plus sombre.
	var step := sin(_stride * 0.3) * 4.0 if _moving else 0.0
	var hip := Vector2(0, -8)
	for leg in [-1.0, 1.0]:
		var foot := Vector2(-step * leg + leg * 0.5, 0)
		var color := Color(0.3, 0.28, 0.35).darkened(0.35 if leg < 0.0 else 0.0)
		draw_line(hip, foot, outline, 4.5, true)
		draw_line(hip, foot, color, 2.5, true)
		draw_line(foot + Vector2(-1, 0), foot + Vector2(2.5, 0), outline, 3.0, true)
	# En marchant, l'outil repose sur l'épaule, derrière lui.
	var working := state == State.MINING or state == State.BUILDING
	if not working:
		_draw_tool()
	# Charge sur le dos : un sac de pierres, ou un cristal d'essence.
	if cargo > 0 and cargo_kind == Conquest.Ore.ESSENCE:
		BuildingRelief.draw_crystal(self, Vector2(-6, -8), 15.0, 7.0, Conquest.ESSENCE_COLOR, Color.WHITE, -0.15)
	elif cargo > 0:
		draw_circle(Vector2(-6, -14), 5.5, outline, true, -1.0, true)
		draw_circle(Vector2(-6, -14), 4.2, Color(0.7, 0.62, 0.45), true, -1.0, true)
		draw_circle(Vector2(-7, -18), 2.6, Conquest.STONE_COLOR, true, -1.0, true)
	# Corps : une tunique, cernée.
	var body := Relief.ellipse(Vector2(0, -12.5), 4.8, 6.0, 0.0, TAU, 16)
	draw_colored_polygon(Relief.ellipse(Vector2(0, -12.5), 6.3, 7.5, 0.0, TAU, 16), outline)
	draw_colored_polygon(body, cloth)
	draw_colored_polygon(Relief.ellipse(Vector2(-1.5, -14.5), 2.2, 2.6, 0.0, TAU, 10), cloth.lightened(0.25))
	draw_line(Vector2(-4.5, -9), Vector2(4.5, -9), Color(0.3, 0.2, 0.12), 1.5)
	# Tête et casque, visière vers l'avant.
	var head := Vector2(1, -21)
	draw_circle(head, 5.0, outline, true, -1.0, true)
	draw_circle(head, 3.8, skin, true, -1.0, true)
	draw_circle(head + Vector2(2.0, 0.3), 0.9, outline, true, -1.0, true)
	var helmet := Relief.ellipse(head + Vector2(0, -0.8), 4.8, 4.6, PI, TAU, 10)
	helmet.append(head + Vector2(6.5, -0.3))
	draw_colored_polygon(helmet, COLOR)
	draw_colored_polygon(Relief.ellipse(head + Vector2(-1.5, -3.2), 1.8, 1.1, 0.0, TAU, 8), COLOR.lightened(0.45))
	helmet.append(helmet[0])
	draw_polyline(helmet, outline, 1.5, true)
	if working:
		_draw_tool()
	draw_set_transform(Vector2.ZERO)
	if health < MAX_HEALTH:
		var width := 18.0
		var top_left := Vector2(-width / 2.0, -36.0)
		draw_rect(Rect2(top_left - Vector2.ONE, Vector2(width + 2.0, 5)), outline)
		draw_rect(Rect2(top_left, Vector2(width * health / MAX_HEALTH, 3)), Color(0.4, 1.0, 0.45))


## Pioche (ou marteau) au bout du bras : elle s'abat au travail, et repose sur l'épaule
## en marchant.
func _draw_tool() -> void:
	var outline := Relief.OUTLINE
	var shoulder := Vector2(0.5, -15)
	var working := state == State.MINING or state == State.BUILDING
	# Angle du manche : levé derrière la tête, puis abattu vers l'avant.
	var angle := -2.4
	if working:
		angle = lerpf(-2.3, 0.5, pow(0.5 + 0.5 * sin(_work_time * 11.0), 2.0))
	var hand := shoulder + Vector2.from_angle(angle * 0.5 + 0.6) * 5.0
	draw_line(shoulder, hand, outline, 4.0, true)
	draw_line(shoulder, hand, Color(0.96, 0.76, 0.58), 2.2, true)
	var direction := Vector2.from_angle(angle)
	var tip := hand + direction * 11.0
	draw_line(hand - direction * 3.0, tip, outline, 3.5, true)
	draw_line(hand - direction * 3.0, tip, Color(0.6, 0.42, 0.25), 2.0, true)
	var across := direction.orthogonal()
	var metal := Color(0.78, 0.8, 0.85)
	if state == State.BUILDING:
		var block := PackedVector2Array([tip - across * 3.5 - direction * 1.5, tip + across * 3.5 - direction * 1.5,
			tip + across * 3.5 + direction * 2.5, tip - across * 3.5 + direction * 2.5])
		draw_colored_polygon(block, metal.darkened(0.2))
		block.append(block[0])
		draw_polyline(block, outline, 1.5, true)
	else:
		var pick := PackedVector2Array([tip + across * 6.0 - direction * 2.5, tip + across * 1.5 + direction * 1.5,
			tip - across * 1.5 + direction * 1.5, tip - across * 6.0 - direction * 2.5])
		draw_polyline(pick, outline, 3.5, true)
		draw_polyline(pick, metal, 1.8, true)


## Ce sur quoi l'ouvrier travaille : le rocher ou le chantier.
func _goal_target() -> Vector2:
	if state == State.BUILDING and is_instance_valid(site):
		return site.global_position
	return conquest.level.map.cell_to_world(rock_cell)
