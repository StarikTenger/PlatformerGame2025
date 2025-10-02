extends Camera2D

var player: Node2D = null
var shake_strength: float = 10.0
var shake_duration: float = 0.2

var original_offset: Vector2
var shake_timer: float = 0.0
var is_shaking: bool = false

func _ready():
	original_offset = offset
	if player != null:
		position = player.position
		print("Camera following player at position: ", player.position)

func _physics_process(delta: float):
	if player != null and !is_shaking:
		position += (player.position - position) * 10 * delta
	
	# Handle camera shake
	if is_shaking:
		shake_timer -= delta
		if shake_timer <= 0.0:
			is_shaking = false
			offset = original_offset
		else:
			# Create screen shake effect
			var shake_offset = Vector2(
				randf_range(-shake_strength, shake_strength),
				randf_range(-shake_strength, shake_strength)
			)
			offset = original_offset + shake_offset

func shake():
	print("Camera shake triggered")
	is_shaking = true
	shake_timer = shake_duration
