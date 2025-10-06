extends Control

@export var level_button_scene: PackedScene
@onready var grid: GridContainer = $VBoxContainer/GridContainer
var current_level: int = 0
var max_opened_level: int = 0
var parallax_time: float = 0.0  # Accumulated time for parallax animation
var parallax_velocity: Vector2 = Vector2.ZERO  # Current velocity for smooth movement
var parallax_position: Vector2 = Vector2.ZERO  # Current position

var level_scenes: Array[String] = [
	"res://levels/level_1.tscn",
	"res://levels/level_2.tscn",
	"res://levels/level_3.tscn",
	"res://levels/level_andrei.tscn",
]

var levels_by_id: Dictionary = {}

# Update the state of level buttons based on the current progress
func _update_level_buttons():
	for i in range(level_scenes.size()):
		var btn = grid.get_child(i)
		if btn:
			btn.is_opened = i <= max_opened_level

func _ready():
	print("Start")
	# Check if grid is properly loaded
	if not grid:
		print("ERROR: GridContainer not found!")
		grid = get_node("GridContainer")
		if not grid:
			print("ERROR: Could not find GridContainer node")
			return
	print("GridContainer found successfully")
	populate_levels()

func populate_levels():
	if not grid:
		print("ERROR: Cannot populate levels - GridContainer is null")
		return
	
	level_button_scene = preload("res://scenes/UI/LevelButton.tscn")
	for i in range(level_scenes.size()):
		var btn = level_button_scene.instantiate()
		btn.setup(i)
		btn.level_selected.connect(_on_level_selected)
		grid.add_child(btn)
	grid.get_child(0).grab_focus()

	_update_level_buttons()

	print("Populated ", level_scenes.size(), " level buttons")

func get_focus():
	grid.get_child(0).grab_focus()

func _launch_level(level_id: int):
	current_level = level_id
	print("Launching level ", level_id)
	var level_scene = level_scenes[level_id]
	
	get_tree().root.get_node("LevelManager").hide()

	get_tree().change_scene_to_file(level_scene)

	
func _on_level_selected(level_id: int):
	print("Loading level ", level_id)
	_launch_level(level_id)

func next_level():
	print("Current level - " + str(current_level))
	current_level = (current_level + 1) % level_scenes.size()
	max_opened_level = max(max_opened_level, current_level)
	_launch_level(current_level)

func open_all_levels():
	print("Opening all levels")
	max_opened_level = 100
	_update_level_buttons()

func _unhandled_input(event):
	# Handle open-all-levels action
	if Input.is_action_pressed("open-all-levels"):
		open_all_levels()

func _process(delta: float) -> void:
	# Accumulate time for smooth parallax animation
	parallax_time += delta
	
	# Add automatic parallax movement and cursor-based parallax
	var parallax_bg = $ParallaxBackground
	if parallax_bg:
		# Get screen center and mouse position
		var screen_size = get_viewport().get_visible_rect().size
		var screen_center = screen_size / 2
		var mouse_pos = get_global_mouse_position()
		
		# Calculate mouse offset from center (normalized to -1 to 1)
		var mouse_offset = (mouse_pos - screen_center) / screen_center
		mouse_offset = mouse_offset.clamp(Vector2(-1, -1), Vector2(1, 1))
		
		# Calculate target position based on automatic figure-8 and mouse input
		var speed = 0.6  # Speed multiplier for parallax movement
		var auto_target = Vector2(
			sin(parallax_time * 0.5 * speed) * 60,  # Horizontal movement
			sin(parallax_time * 1.0 * speed) * 20   # Vertical creates figure-8 when combined
		)
		var mouse_target = mouse_offset * 30  # Mouse influence on target position
		var target_position = auto_target + mouse_target
		
		# Apply smooth acceleration towards target position
		var position_diff = target_position - parallax_position
		var acceleration = position_diff * 3.0  # Acceleration strength
		
		# Apply acceleration to velocity with damping
		parallax_velocity += acceleration * delta
		parallax_velocity *= 0.85  # Damping factor for smooth deceleration  
		
		# Update position using velocity
		parallax_position += parallax_velocity * delta
		
		# Apply the smooth position to the parallax background
		parallax_bg.scroll_offset = parallax_position
		
		# Also apply to individual parallax layers for more visible effect
		var layer3 = parallax_bg.get_node_or_null("ParallaxLayer3")
		var layer4 = parallax_bg.get_node_or_null("ParallaxLayer4")
		
		if layer3:
			layer3.scroll_offset = parallax_position * 0.5
		if layer4:
			layer4.scroll_offset = parallax_position * 0.8
