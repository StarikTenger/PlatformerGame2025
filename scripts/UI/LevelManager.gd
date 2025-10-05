extends Control

@export var level_button_scene: PackedScene
@onready var grid: GridContainer = $GridContainer
var current_level: int = 0

var level_scenes: Array[String] = [
	"res://levels/level_template.tscn",
	"res://levels/level_0.tscn",
	"res://levels/level_1.tscn",
]

var levels_by_id: Dictionary = {}

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
	print("Populated ", level_scenes.size(), " level buttons")

func _launch_level(level_id: int):
	print("Launching level ", level_id)
	var level_scene = level_scenes[level_id]

	get_tree().change_scene_to_file(level_scene)

	
func _on_level_selected(level_id: int):
	current_level = level_id
	print("Loading level ", level_id)
	_launch_level(level_id)

func next_level():
	if current_level + 1 < level_scenes.size():
		current_level += 1
		print("Loading next level ", current_level)
		_launch_level(current_level)
	else:
		print("No more levels available.")
