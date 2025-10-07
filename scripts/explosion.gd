extends Node2D
class_name Explosion

enum Type {
	FIRE,
	WIND,
	EARTH,
	PROJECTILE
}

var type : Type = Type.FIRE

func _ready():
	#scale = Vector2.ZERO
	print("Explosion at position: ", global_position)
	rotation = randf() * TAU

	$AnimatedSprite2D.connect("animation_finished", Callable(self, "queue_free"))
	
	match type:
		Type.FIRE:
			$AnimatedSprite2D.play("fire")
		Type.WIND:
			$AnimatedSprite2D.play("wind")
		Type.EARTH:
			$AnimatedSprite2D.play("earth")
		Type.PROJECTILE:
			scale = Vector2.ONE * 0.5
			$AnimatedSprite2D.play("projectile")
