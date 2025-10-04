extends Area2D

signal exit_passed()

func _physics_process(delta):
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			print("Exit triggered by player")
			LevelManager.next_level()
