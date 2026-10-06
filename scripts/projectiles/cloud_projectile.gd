class_name CloudProjectile
extends Projectile
## Grenade qui éclate à l'impact : petits dégâts dans le rayon du nuage, puis un nuage
## (GasCloud) qui reste sur place et applique les effets de la tour (poison,
## ralentissement, soins bloqués) à tout ce qui le traverse.


func _impact(_hit: Enemy) -> void:
	for enemy in Enemy.get_alive_in_radius(get_tree(), global_position, stats.cloud_radius):
		_hit_enemy(enemy)
	var cloud := GasCloud.new()
	cloud.stats = stats
	get_parent().add_child(cloud)
	cloud.global_position = global_position
	Sound.play(&"explosion", -8.0)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, color.darkened(0.4))
	draw_circle(Vector2.ZERO, 3.0, color)
