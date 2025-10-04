extends AnimatedSprite2D
class_name Eye

var state_timer: float = 0.0

func _ready() -> void:
	play("idle")
	state_timer = 0

func _process(delta: float) -> void:
	if state_timer <= delta:
		state_timer = randf_range(5, 10)
		match randi_range(0, 2):
			0:
				play("blink")
			1:
				play("look_down")
			2:
				play("look_right")
	else:
		state_timer -= delta

func _on_animation_finished() -> void:
	play("idle")
