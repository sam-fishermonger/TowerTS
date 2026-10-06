class_name GroundStain
extends Node2D
## Tache laissée au sol par un ennemi détruit. Elle s'estompe lentement puis disparaît.

const DURATION := 20.0
const START_ALPHA := 0.45

var radius := 12.0
var color := Color.DARK_GREEN

var _age := 0.0
## Gouttes qui forment la tache : x, y = décalage, z = rayon.
var _blobs: Array[Vector3] = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	_blobs.append(Vector3(0, 0, radius))
	for i in 6:
		var offset := Vector2.from_angle(rng.randf() * TAU) * radius * rng.randf_range(0.6, 1.2)
		_blobs.append(Vector3(offset.x, offset.y, radius * rng.randf_range(0.2, 0.45)))
	rotation = rng.randf() * TAU


## La tache est dessinée une seule fois ; seule sa transparence change ensuite.
func _process(delta: float) -> void:
	_age += delta
	if _age >= DURATION:
		queue_free()
		return
	modulate.a = get_alpha() / START_ALPHA


func get_alpha() -> float:
	return START_ALPHA * (1.0 - clampf(_age / DURATION, 0.0, 1.0))


func _draw() -> void:
	var stain := Color(color.darkened(0.45), START_ALPHA)
	for blob in _blobs:
		draw_circle(Vector2(blob.x, blob.y), blob.z, stain)
