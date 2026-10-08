class_name Loot
extends Node2D
## Butin lâché par un monstre porteur (Enemy.Carrier) : un tas d'or, de la pierre ou de
## l'essence (mode Conquête), ou un coffre. Il reste au sol quelques secondes : un clic
## ou un toucher dessus le ramasse (Level.collect_loot()), sinon il clignote puis disparaît.

## Émis quand le butin disparaît sans avoir été ramassé.
signal expired(loot: Loot)

enum Kind { GOLD, STONE, ESSENCE, CHEST }

const GROUP := "loot"
## Secondes au sol (temps réel, sans la pause) avant de disparaître, dont les dernières
## à clignoter.
const LIFETIME := 12.0
const BLINK_TIME := 3.0
## Distance à laquelle un clic (ou un toucher) le ramasse, en pixels.
const PICK_RADIUS := 22.0
const TOUCH_PICK_RADIUS := 34.0
const GOLD_COLOR := Color(1.0, 0.82, 0.25)
const STONE_COLOR := Color(0.72, 0.74, 0.8)
const ESSENCE_COLOR := Color(0.78, 0.5, 1.0)
const WOOD_COLOR := Color(0.55, 0.33, 0.16)
## Échelle du dessin au sol (celui porté par un monstre est plus petit).
const SIZE := 1.35

var kind := Kind.GOLD
## Or, pierre ou essence donnés (rien pour un coffre : son bonus est tiré à l'ouverture).
var amount := 0
## Survolé par la souris : il est cerclé de blanc.
var highlighted := false:
	set(value):
		if value != highlighted:
			highlighted = value
			queue_redraw()

var _age := 0.0
var _body := Node2D.new()


func _ready() -> void:
	add_to_group(GROUP)
	_body.draw.connect(_draw_body)
	add_child(_body)
	# Il tombe du monstre en rebondissant, puis flotte doucement.
	_body.position = Vector2(0, -18)
	scale = Vector2(0.4, 0.4)
	var fall := create_tween().set_parallel()
	fall.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	fall.tween_property(_body, "position:y", 0.0, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	fall.chain().tween_callback(_float)


func _float() -> void:
	var bob := create_tween().set_loops()
	bob.tween_property(_body, "position:y", -3.0, 0.6).set_trans(Tween.TRANS_SINE)
	bob.tween_property(_body, "position:y", 0.0, 0.6).set_trans(Tween.TRANS_SINE)


func _process(delta: float) -> void:
	# Temps réel : il dure autant en x3 qu'en x1 (le jeu en pause, lui, l'arrête).
	_age += delta / maxf(Engine.time_scale, 0.01)
	if _age >= LIFETIME:
		expired.emit(self)
		queue_free()
	elif _age >= LIFETIME - BLINK_TIME:
		modulate.a = 0.35 if fmod(_age, 0.3) < 0.12 else 1.0


## Secondes avant qu'il disparaisse.
func get_time_left() -> float:
	return LIFETIME - _age


func is_chest() -> bool:
	return kind == Kind.CHEST


func _draw() -> void:
	var size := (15.0 if is_chest() else 12.0) * SIZE
	Relief.draw_shadow(self, Vector2(0, 2), size, size * 0.45)
	if highlighted:
		draw_polyline(Relief.ellipse(Vector2(0, 2), size + 6.0, (size + 6.0) * 0.5), Color(1, 1, 1, 0.85), 2.0, true)
	if is_chest():
		draw_colored_polygon(Relief.ellipse(Vector2(0, 2), size + 4.0, (size + 4.0) * 0.5), Color(ChestBonus.COLOR, 0.35))


func _draw_body() -> void:
	draw_item(_body, kind, Vector2.ZERO, SIZE)


## Dessine un butin posé sur `foot` (bas de l'objet), à l'échelle donnée : sert aussi
## à la marque portée par un monstre (Enemy).
static func draw_item(canvas: CanvasItem, item: int, foot: Vector2, size: float) -> void:
	var outline := Relief.OUTLINE
	match item:
		Kind.CHEST:
			var w := 13.0 * size
			var h := 9.0 * size
			var box := Rect2(foot + Vector2(-w, -h * 1.6), Vector2(w * 2.0, h * 1.6))
			canvas.draw_rect(box, WOOD_COLOR)
			# Couvercle bombé, plus clair.
			var lid := Relief.ellipse(Vector2(foot.x, box.position.y), w, h * 0.8, PI, TAU, 14)
			canvas.draw_colored_polygon(lid, WOOD_COLOR.lightened(0.2))
			canvas.draw_polyline(lid, outline, 1.5, true)
			canvas.draw_rect(box, outline, false, 1.5)
			# Ferrures sombres et serrure dorée.
			for x in [-w * 0.6, w * 0.6]:
				canvas.draw_line(Vector2(foot.x + x, box.position.y - h * 0.62), Vector2(foot.x + x, box.end.y), WOOD_COLOR.darkened(0.5), 2.5 * size)
			canvas.draw_line(Vector2(box.position.x, box.position.y), Vector2(box.end.x, box.position.y), outline, 1.5)
			canvas.draw_rect(Rect2(foot + Vector2(-3.0, -h * 1.75) * size, Vector2(6.0, 6.0) * size), GOLD_COLOR)
			canvas.draw_rect(Rect2(foot + Vector2(-3.0, -h * 1.75) * size, Vector2(6.0, 6.0) * size), outline, false, 1.0)
		Kind.GOLD:
			# Trois pièces empilées en quinconce.
			for offset in [Vector2(-5, 0), Vector2(5, 0), Vector2(0, -5)]:
				var center: Vector2 = foot + (offset - Vector2(0, 4)) * size
				canvas.draw_colored_polygon(Relief.ellipse(center + Vector2(0, 1.5) * size, 6.0 * size, 3.5 * size, 0.0, TAU, 14), GOLD_COLOR.darkened(0.35))
				var face := Relief.ellipse(center, 6.0 * size, 3.5 * size, 0.0, TAU, 14)
				canvas.draw_colored_polygon(face, GOLD_COLOR)
				canvas.draw_polyline(face, outline, 1.2, true)
			canvas.draw_circle(foot + Vector2(-1.5, -10.5) * size, 1.4 * size, Color(1, 1, 0.9))
		Kind.STONE:
			var rock := PackedVector2Array()
			for point in [Vector2(-9, 0), Vector2(-8, -7), Vector2(-2, -12), Vector2(6, -10), Vector2(9, -3), Vector2(7, 0)]:
				rock.append(foot + point * size)
			canvas.draw_colored_polygon(rock, STONE_COLOR)
			canvas.draw_colored_polygon(PackedVector2Array([rock[2], rock[3], rock[4], foot + Vector2(1, -5) * size]), STONE_COLOR.lightened(0.25))
			rock.append(rock[0])
			canvas.draw_polyline(rock, outline, 1.5, true)
		Kind.ESSENCE:
			var crystal := PackedVector2Array()
			for point in [Vector2(0, 0), Vector2(-6, -8), Vector2(0, -17), Vector2(6, -8)]:
				crystal.append(foot + point * size)
			canvas.draw_colored_polygon(crystal, ESSENCE_COLOR)
			canvas.draw_colored_polygon(PackedVector2Array([crystal[1], crystal[2], crystal[0]]), ESSENCE_COLOR.lightened(0.3))
			crystal.append(crystal[0])
			canvas.draw_polyline(crystal, outline, 1.5, true)
