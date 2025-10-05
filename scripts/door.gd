# res://scripts/Door.gd
class_name Door
extends StaticBody2D

var is_open: bool = false

func open() -> void:
	if is_open:
		return
		
	$CollisionShape2D.set_deferred("disabled", true)

	var anim: AnimatedSprite2D = $AnimatedSprite2D
	anim.play("open")


	is_open = true
