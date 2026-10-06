class_name ExplosiveProjectile
extends Projectile
## Obus qui explose à l'impact et touche tous les ennemis dans son rayon,
## même si la cible initiale a disparu entre-temps.

func _impact(_hit: Enemy) -> void:
	_hit_all_in_radius(stats.splash_radius)
	var explosion := Explosion.new()
	explosion.radius = stats.splash_radius
	explosion.color = color
	get_parent().add_child(explosion)
	explosion.global_position = global_position
	Sound.play(&"explosion")


func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, color.darkened(0.3))
	draw_circle(Vector2.ZERO, 3.0, color)
