extends PlayerBase
class_name EarthPlayer

var platform_scene : PackedScene

# Audio for creating platform
var earth_death_player := AudioStreamPlayer2D.new()

func _death_effect() -> void:
	# Play sound
	earth_death_player.stream = load("res://sounds/EARTH_GUY_DEATH.mp3")
	earth_death_player.position = global_position
	get_parent().add_child(earth_death_player)
	earth_death_player.play()
	
	# Spawn platform at player's position
	var platform = platform_scene.instantiate()
	platform.global_position = global_position
	get_parent().add_child(platform)

func _ready() -> void:
	super()
	enabled_wall_climb = true
	jump_height = 2.2 * TILE_SIZE
	speed = 600.0
	platform_scene = preload("res://scenes/Platform.tscn")

func death_hint() -> String:
	return "This character will leave a platform at the place of death"

func get_player_type() -> PlayerType:
	return PlayerType.EARTH
