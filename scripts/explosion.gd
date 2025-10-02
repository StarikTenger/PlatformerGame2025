extends Node2D

@export var grow_time: float = 0.2
@export var max_scale: float = 2.0

var _timer := 0.0
var _original_scale := Vector2.ONE


func _ready():
	_original_scale = scale
	scale = Vector2.ZERO
	print("Explosion at position: ", global_position)

func _process(delta):
	_timer += delta
	if _timer < grow_time:
		var t = _timer / grow_time
		scale = _original_scale.lerp(_original_scale * max_scale, t)
	else:
		queue_free()
