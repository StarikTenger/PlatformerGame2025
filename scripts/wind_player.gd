extends "res://scripts/player.gd"

var tornado_scene : PackedScene

func _death_effect() -> void:
	# Spawn tornado at player's position
	var tornado = tornado_scene.instantiate()
	tornado.global_position = global_position
	get_parent().add_child(tornado)

func _ready() -> void:
	super()
	jump_height = 400.0

func death_hint() -> String:
	return "This character will leave a tornado at the place of death"

	tornado_scene = preload("res://scenes/Tornado.tscn")
