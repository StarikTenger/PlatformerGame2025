extends Area2D

var passed: bool = false
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

signal exit_passed()

# func _ready():
# 	# Create audio player for exit sound
# 	audio_player = AudioStreamPlayer2D.new()
# 	add_child(audio_player)

func _physics_process(delta):
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			if passed:
				return
			passed = true
			print("Exit triggered by player")
			
			# Play exit sound
			audio_player.stream = load("res://sounds/FLOURISH.mp3")
			audio_player.play()
			
			get_parent().camera_node.set_target_state(global_position, 2, 1, 0)
			await get_tree().create_timer(1.0).timeout
			get_parent()._show_win_menu(true)
