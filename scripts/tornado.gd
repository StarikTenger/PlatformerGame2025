extends Area2D

var lift_acceleration := 5000.0
var direction := Vector2.UP

func _physics_process(delta):
	for body in get_overlapping_bodies():
		if body.is_in_group("liftable"):
			body.velocity.y -= lift_acceleration * delta
