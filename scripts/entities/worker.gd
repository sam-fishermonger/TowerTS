class_name Worker
extends Entity
## Ouvrier du mode Conquête : il mine la pierre des rochers et la rapporte au QG, ou
## bâtit les chantiers de tours. C'est le mode Conquête (Conquest) qui lui donne ses
## ordres quand il n'a rien à faire. Il marche tout droit, quitte à traverser le chemin :
## un monstre au sol qui le touche le blesse, sauf près du QG, où il est à l'abri. Un
## ouvrier tombé perd la pierre qu'il portait.

enum State { IDLE, TO_ROCK, MINING, TO_DEPOT, TO_SITE, BUILDING }

## Vitesse de marche, en pixels par seconde.
const SPEED := 80.0
const MAX_HEALTH := 40.0
## Pierre portée à chaque voyage.
const CARRY := 3
## Secondes pour remplir sa charge au rocher.
const MINE_TIME := 2.5
## Distance au centre d'un rocher ou d'un chantier à laquelle l'ouvrier travaille.
const REACH := 38.0
## Distance au QG à laquelle il dépose sa charge, et en dessous de laquelle il est à l'abri.
const DEPOT_REACH := 36.0
const SAFE_RADIUS := 56.0
## Dégâts par seconde d'un monstre au sol qui touche l'ouvrier.
const CONTACT_DPS := 30.0
const BODY_RADIUS := 10.0
const COLOR := Color(1.0, 0.72, 0.25)

## Émis quand l'ouvrier tombe (juste avant son retrait).
signal killed(worker: Worker)

var conquest: Conquest
var state := State.IDLE
## Rocher miné (TO_ROCK, MINING).
var rock_cell := Vector2i.ZERO
## Chantier bâti (TO_SITE, BUILDING).
var site: Tower
## Pierre portée.
var cargo := 0
var health := MAX_HEALTH

## Point où se rendre pour l'ordre en cours.
var _goal := Vector2.ZERO
var _timer := 0.0
## Secondes depuis le début du travail en cours, pour l'animation de l'outil.
var _work_time := 0.0


func _process(delta: float) -> void:
	_take_contact_damage(delta)
	if not is_alive:
		return
	match state:
		State.TO_ROCK:
			if not conquest.has_stone(rock_cell):
				_finish_order()
			elif _walk(delta):
				state = State.MINING
				_timer = MINE_TIME
				_work_time = 0.0
		State.MINING:
			_work_time += delta
			if not conquest.has_stone(rock_cell):
				_finish_order()
			else:
				_timer -= delta
				if _timer <= 0.0:
					cargo += conquest.take_stone(rock_cell, CARRY - cargo)
					go_deposit()
		State.TO_DEPOT:
			if _walk(delta):
				if cargo > 0:
					conquest.deposit(cargo)
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


## Rapporte sa charge au QG (ou y rentre, sans charge).
func go_deposit() -> void:
	site = null
	state = State.TO_DEPOT
	_goal = conquest.depot_position + _side_from(conquest.depot_position) * (DEPOT_REACH - 8.0)


## Va bâtir un chantier (il garde la pierre qu'il porte).
func go_build(tower: Tower) -> void:
	site = tower
	state = State.TO_SITE
	_goal = tower.global_position + _side_from(tower.global_position) * REACH


func is_building(tower: Tower) -> bool:
	return site == tower and (state == State.TO_SITE or state == State.BUILDING)


func is_mining() -> bool:
	return state == State.TO_ROCK or state == State.MINING


## Direction de l'ouvrier vue depuis un point (vers le bas s'il est dessus).
func _side_from(center: Vector2) -> Vector2:
	var offset := global_position - center
	return offset.normalized() if offset.length() > 1.0 else Vector2.DOWN


## Avance vers le but. Renvoie true une fois arrivé.
func _walk(delta: float) -> bool:
	var offset := _goal - global_position
	var step := SPEED * delta
	if offset.length() <= step:
		global_position = _goal
		return true
	global_position += offset.normalized() * step
	return false


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
	if global_position.distance_to(conquest.depot_position) < SAFE_RADIUS:
		return
	var touched := 0
	for node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy := node as Enemy
		if enemy.is_alive and not enemy.data.flying \
				and enemy.global_position.distance_to(global_position) < enemy.data.radius + BODY_RADIUS:
			touched += 1
	if touched == 0:
		return
	health -= CONTACT_DPS * touched * delta
	if health <= 0.0:
		killed.emit(self)
		despawn()


func _draw() -> void:
	# Ombre, corps et casque.
	draw_circle(Vector2(0, 3), BODY_RADIUS, Color(0, 0, 0, 0.3))
	draw_circle(Vector2.ZERO, BODY_RADIUS, Color(0.35, 0.3, 0.25))
	draw_circle(Vector2(0, -2), BODY_RADIUS * 0.75, COLOR)
	draw_arc(Vector2(0, -2), BODY_RADIUS * 0.75, PI, TAU, 10, COLOR.darkened(0.4), 2.0)
	if cargo > 0:
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
