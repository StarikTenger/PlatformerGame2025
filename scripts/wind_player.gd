extends "res://scripts/player.gd"

func _ready() -> void:
	super()
	jump_height = 400.0

func death_hint() -> String:
	return "This character will leave a tornado at the place of death"
