class_name Worker
extends Entity
## Ouvrier du mode Conquête : il mine la pierre des rochers ou l'essence des filons et la
## rapporte au dépôt le plus proche (le QG ou un Dépôt), ou bâtit les chantiers de tours
## et de bâtiments. C'est le mode Conquête (Conquest) qui lui donne ses ordres quand il
## n'a rien à faire. Il marche tout droit, quitte à traverser le chemin, mais attend au
## bord qu'aucun monstre au sol ne soit tout près pour s'y engager. Un monstre au sol qui
## le touche le blesse, et les Pillards viennent le frapper, sauf près du QG, où il est à
## l'abri et se soigne. Un ouvrier tombé perd ce qu'il portait.

enum State { IDLE, TO_ROCK, MINING, TO_DEPOT, TO_SITE, BUILDING }

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
## Distance au QG à laquelle il dépose sa charge, et en dessous de laquelle il est à l'abri.
const DEPOT_REACH := 36.0
const SAFE_RADIUS := 56.0
## Dégâts par seconde d'un monstre au sol qui touche l'ouvrier.
const CONTACT_DPS := 25.0
## Distance à un monstre au sol en dessous de laquelle il ne s'engage pas sur le chemin.
const CROSSING_MARGIN := 70.0
const BODY_RADIUS := 10.0
const COLOR := Color(1.0, 0.72, 0.25)

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

## Point où se rendre pour l'ordre en cours.
var _goal := Vector2.ZERO
var _timer := 0.0
## Secondes depuis le début du travail en cours, pour l'animation de l'outil.
var _work_time := 0.0


func _ready() -> void:
	add_to_group(Conquest.RAID_TARGET_GROUP)


func _process(delta: float) -> void:
	_take_contact_damage(delta)
	if not is_alive:
		return
	match state:
		State.TO_ROCK:
			if not conquest.has_resource(rock_cell):
				_finish_order()
			elif _walk(delta):
				state = State.MINING
				_timer = ESSENCE_MINE_TIME if conquest.resource_at(rock_cell) == Conquest.Ore.ESSENCE else MINE_TIME
				_work_time = 0.0
		State.MINING:
			_work_time += delta
			if not conquest.has_resource(rock_cell):
				_finish_order()
			else:
				_timer -= delta
				if _timer <= 0.0:
					cargo_kind = conquest.resource_at(rock_cell)
					var carry := ESSENCE_CARRY if cargo_kind == Conquest.Ore.ESSENCE else CARRY
					cargo += conquest.take_resource(rock_cell, carry - cargo)
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
				conquest.build(site, delta)
	queue_redraw()


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


## Va bâtir un chantier, tour ou bâtiment (il garde ce qu'il porte).
func go_build(target: Node2D) -> void:
	site = target
	state = State.TO_SITE
	_goal = target.global_position + _side_from(target.global_position) * REACH


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
	var step := SPEED * delta
	var next := _goal if offset.length() <= step else global_position + offset.normalized() * step
	if not _is_safe_to_enter(next):
		return false
	global_position = next
	return next == _goal


## On peut avancer jusqu'à ce point : il n'est pas sur le chemin, l'ouvrier y est déjà,
## ou aucun monstre au sol n'est tout près.
func _is_safe_to_enter(point: Vector2) -> bool:
	var map := conquest.level.map
	if not map.is_cell_on_path(map.world_to_cell(point)) or map.is_cell_on_path(map.world_to_cell(global_position)):
		return true
	for node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy := node as Enemy
		if enemy.is_alive and not enemy.data.flying and enemy.global_position.distance_to(point) < CROSSING_MARGIN:
			return false
	return true


func _site_needs_work() -> bool:
	return is_instance_valid(site) and site.is_alive and not site.is_built()


## Ordre fini ou devenu impossible : il rapporte ce qu'il porte, sinon il attend un ordre.
func _finish_order() -> void:
	site = null
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


## Ce sur quoi l'ouvrier travaille : le rocher ou le chantier.
func _goal_target() -> Vector2:
	if state == State.BUILDING and is_instance_valid(site):
		return site.global_position
	return conquest.level.map.cell_to_world(rock_cell)
