extends TextureButton

signal level_selected(level_id: int)

var level_id: int
var level_scene: String

func setup(data: Dictionary):
	level_id = data["id"] 
	level_scene = data["level_scene"]

	if has_node("Label"):
		var lbl = $Label
		lbl.text = str(level_id)

func _pressed():
	emit_signal("level_selected", level_id)
	get_tree().change_scene_to_file(level_scene)
