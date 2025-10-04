extends Control

@export var level_button_scene: PackedScene
@onready var grid = $GridContainer

var levels = [
	{"id": 1, "level_scene": "res://levels/level_template.tscn"},
	{"id": 2, "level_scene": "res://levels/level_0.tscn"},
	{"id": 3, "level_scene": "res://levels/level_template.tscn"},
]

func _ready():
	print("Start")
	populate_levels()

func populate_levels():
	for level_data in levels:
		var btn = level_button_scene.instantiate()
		btn.setup(level_data)
		btn.level_selected.connect(_on_level_selected)
		grid.add_child(btn)

func _on_level_selected(level_id: int):
	print("Loading level ", level_id)
	# здесь: смена сцены на сам уровень
	# get_tree().change_scene_to_file("res://levels/level_%d.tscn" % level_id)
