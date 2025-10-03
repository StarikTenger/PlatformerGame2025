extends "res://scripts/Players/player.gd"

var platform_scene : PackedScene

func _death_effect() -> void:
	# Spawn platform at player's position
	var platform = platform_scene.instantiate()
	platform.global_position = global_position
	get_parent().add_child(platform)

func _ready() -> void:
	super()
	jump_height = 400.0
	
	platform_scene = preload("res://scenes/Platform.tscn")

func death_hint() -> String:
	return "This character will leave a platform at the place of death"
