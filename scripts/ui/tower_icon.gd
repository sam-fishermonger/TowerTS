class_name TowerIcon
extends Control
## Image d'un type de tour, comme sur la carte : socle et tourelle tournée vers le haut,
## ou un carré de sa couleur si le type de tour n'a pas d'image.

## Un TowerData. (Typé Resource : avec TowerData, charger ce script en premier, comme le
## fait l'arbre des améliorations, empêche Godot de libérer l'arbre et la campagne en
## quittant.)
var data: Resource:
	set(value):
		data = value
		queue_redraw()


func _draw() -> void:
	if data == null:
		return
	var center := size / 2.0
	# Le socle est réduit pour que la tourelle, qui déborde, tienne dans le contrôle.
	var base_side := minf(size.x, size.y) / Tower.TURRET_SCALE
	if data.turret_texture:
		Tower.draw_sprite(self, data, center, base_side)
	else:
		draw_rect(Rect2(center - Vector2.ONE * base_side / 2.0, Vector2.ONE * base_side), data.color.darkened(0.35))
		draw_circle(center, base_side * 0.3, data.color)
