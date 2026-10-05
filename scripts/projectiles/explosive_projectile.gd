class_name ExplosiveProjectile
extends Projectile
## Obus qui explose à l'impact et touche tous les ennemis dans son rayon,
## même si la cible initiale a disparu entre-temps.

var splash_radius := 50.0


func setup(new_target: Enemy, data: TowerData) -> void:
	super(new_target, data)
	splash_radius = data.splash_radius


func _impact(_hit: Enemy) -> void:
	for enemy in Enemy.get_alive_in_radius(get_tree(), global_position, splash_radius):
		_hit_enemy(enemy)
	var explosion := Explosion.new()
	explosion.radius = splash_radius
	explosion.color = color
	get_parent().add_child(explosion)
	explosion.global_position = global_position
	Sound.play(&"explosion")


func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, color.darkened(0.3))
	draw_circle(Vector2.ZERO, 3.0, color)
