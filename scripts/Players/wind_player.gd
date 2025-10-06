extends PlayerBase
class_name WindPlayer

var tornado_scene : PackedScene

func _death_effect() -> void:
	# Spawn tornado at player's position
	var tornado = tornado_scene.instantiate()
	tornado.global_position = global_position
	get_parent().add_child(tornado)

func _ready() -> void:
	super()
	enabled_double_jumps = true
	jump_height = 1.7 * TILE_SIZE
	double_jump_height = jump_height
	
	tornado_scene = preload("res://scenes/Tornado.tscn")

func death_hint() -> String:
	return "This character will leave a tornado at the place of death"

func get_player_type() -> PlayerType:
	return PlayerType.WIND
