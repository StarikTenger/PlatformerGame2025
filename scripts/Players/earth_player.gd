extends PlayerBase
class_name EarthPlayer

var platform_scene : PackedScene

func _death_effect() -> void:
	# Spawn platform at player's position
	var platform = platform_scene.instantiate()
	platform.global_position = global_position
	get_parent().add_child(platform)

func _ready() -> void:
	super()
	jump_height = 210.0
	speed = 600.0
	delay_between_jumps = 0.7
	platform_scene = preload("res://scenes/Platform.tscn")

func death_hint() -> String:
	return "This character will leave a platform at the place of death"

func get_player_type() -> PlayerType:
	return PlayerType.EARTH
