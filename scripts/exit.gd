extends Area2D

var passed: bool = false

signal exit_passed()

func _physics_process(delta):
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			if passed:
				return
			passed = true
			print("Exit triggered by player")
			get_parent().camera_node.set_target_state(global_position, 2, 1, 0)
			await get_tree().create_timer(1.0).timeout
			get_parent()._show_win_menu(true)
