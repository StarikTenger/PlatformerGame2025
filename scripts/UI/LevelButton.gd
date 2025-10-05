extends TextureButton

signal level_selected(level_id: int)

var level_id: int
var is_opened: bool = false

func setup(id: int):
	level_id = id

	if has_node("Label"):
		var lbl = $Label
		lbl.text = str(level_id + 1)

func _pressed():
	if is_opened:
		emit_signal("level_selected", level_id)


func _on_focus_entered() -> void:
	if is_opened:
		modulate = "#ffffffff"


func _on_ready() -> void:
	if is_opened:
		modulate = "#ffffff"


func _on_focus_exited() -> void:
	if is_opened:
		modulate = "#ffffff30"

func _process(delta: float) -> void:
	is_opened = LevelManager.max_opened_level >= level_id

	if not is_opened:
		modulate.a = 0.3
	else:
		modulate.a = 1.0