extends Node2D

var player_scene: PackedScene = preload("res://scenes/Player.tscn")

func _ready():
	if player_scene == null:
		print("Error: Player scene not found!")
		return

	var player = player_scene.instantiate()
	add_child(player)
	player.global_position = Vector2(100, 100) # Set initial position as needed

	# Instantiate and set up the camera
	var camera_scene: PackedScene = preload("res://scenes/Camera.tscn")
	if camera_scene:
		var camera = camera_scene.instantiate()
		camera.player = player
		add_child(camera)
		


	# Init gravity
	ProjectSettings.set_setting("physics/2d/default_gravity", 2000)
