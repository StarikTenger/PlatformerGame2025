extends StaticBody2D

# Fade in parameters
var fade_duration := 1.0  # Duration of fade-in effect in seconds
var is_fading_in := true

const TILE_SIZE := 200

func _ready():
	# Start with fully transparent
	modulate.a = 0.0
	
	# Start fade-in animation
	_start_fade_in()
	
	global_position.x = floor(global_position.x / TILE_SIZE) * TILE_SIZE + TILE_SIZE / 2
	global_position.y = floor(global_position.y / TILE_SIZE) * TILE_SIZE + TILE_SIZE / 2
	

func _start_fade_in():
	# Create a tween for smooth fade-in
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	tween.tween_callback(_on_fade_in_complete)

func _on_fade_in_complete():
	is_fading_in = false
