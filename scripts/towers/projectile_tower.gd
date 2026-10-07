class_name ProjectileTower
extends Tower
## Tour à canon orientable qui tire le projectile défini dans ses données
## (balle à tête chercheuse, obus explosif...).


func _attack(enemy: Enemy) -> void:
	var projectile: Projectile = data.projectile_scene.instantiate()
	projectile.setup(enemy, stats)
	_get_container().add_child(projectile)
	projectile.global_position = global_position + Vector2.from_angle(_aim_angle) * SIZE * 0.5
	# Vue de trois quarts : le tir part du haut de la tour (il reste au sol pour le jeu).
	projectile.lift = -get_muzzle_offset().y


func _draw_shape() -> void:
	draw_circle(Vector2.ZERO, SIZE * 0.32, data.color)
	draw_line(Vector2.ZERO, Vector2.from_angle(_aim_angle) * SIZE * 0.55, data.color.lightened(0.3), 7.0)
