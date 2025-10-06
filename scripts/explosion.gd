extends Node2D

func _ready():
	#scale = Vector2.ZERO
	print("Explosion at position: ", global_position)
	rotation = randf() * TAU

	$AnimatedSprite2D.connect("animation_finished", Callable(self, "queue_free"))
	$AnimatedSprite2D.play()
