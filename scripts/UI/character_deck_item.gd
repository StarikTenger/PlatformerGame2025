extends Control

@onready var animation_sprite: AnimatedSprite2D = $AnimatedSprite2D

var max_width = 0
var max_height = 0
var default_scale: Vector2 = Vector2.ONE * 2.5

func _ready():
	# Find the largest frame size among all animations
	for anim in animation_sprite.sprite_frames.get_animation_names():
		var frame_count = animation_sprite.sprite_frames.get_frame_count(anim)
		for i in range(frame_count):
			var tex = animation_sprite.sprite_frames.get_frame_texture(anim, i)
			if tex:
				max_width = max(max_width, tex.get_width())
				max_height = max(max_height, tex.get_height())

	print("Max frame size: ", max_width, "x", max_height)

	default_scale = animation_sprite.scale
	
func _physics_process(delta):
	# Detect the current animation and scale it to fit max sizes
	var current_anim = animation_sprite.animation
	var current_frame = animation_sprite.frame
	var current_tex = animation_sprite.sprite_frames.get_frame_texture(current_anim, current_frame)
	if current_tex and max_width > 0 and max_height > 0:
		var scale_x = float(max_width) / current_tex.get_width()
		var scale_y = float(max_height) / current_tex.get_height()
		var scale_factor = min(scale_x, scale_y)
		animation_sprite.scale = default_scale * scale_factor
		# animation_sprite.position = Vector2((max_width - current_tex.get_width() * scale_factor) / 2, (max_height - current_tex.get_height() * scale_factor) / 2)
