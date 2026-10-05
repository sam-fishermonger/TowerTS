class_name TowerIcon
extends Control
## Image d'un type de tour, comme sur la carte : socle et tourelle tournée vers le haut,
## ou un carré de sa couleur si le type de tour n'a pas d'image.

var data: TowerData:
	set(value):
		data = value
		queue_redraw()


func _draw() -> void:
	if data == null:
		return
	var side := minf(size.x, size.y)
	var center := size / 2.0
	# Mêmes proportions que Tower._draw_body : la tourelle déborde un peu du socle.
	var base_side := side / 1.3
	var base_rect := Rect2(center - Vector2.ONE * base_side / 2.0, Vector2.ONE * base_side)
	if data.turret_texture == null:
		draw_rect(base_rect, data.color.darkened(0.35))
		draw_circle(center, base_side * 0.3, data.color)
		return
	draw_texture_rect(Tower.BASE_TEXTURE, base_rect, false)
	draw_set_transform(center, -PI / 2.0 if data.turret_rotates else 0.0)
	draw_texture_rect(data.turret_texture, Rect2(-Vector2.ONE * side / 2.0, Vector2.ONE * side), false)
	draw_set_transform(Vector2.ZERO)
