extends TextureButton

signal level_selected(level_id: int)

var level_id: int

func setup(id: int):
	level_id = id

	if has_node("Label"):
		var lbl = $Label
		lbl.text = str(level_id + 1)

func _pressed():
	emit_signal("level_selected", level_id)
