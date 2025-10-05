extends TextureButton

signal level_selected(level_id: int)

var level_id: int
var is_opened: bool = false

var tex: Texture2D = preload("res://resources/ui/buttons.png")

func setup(id: int, color: int = 0):
	level_id = id
	
	# Add texture depending on level 1-5 first line, 6-10 second line, etc.
	var cols: int = 15
	var rows: int = 10
	var row_offset: int = 7
	var levels_per_row: int = 5

	var cell_w: int = tex.get_width() / cols
	var cell_h: int = tex.get_height() / rows
	var x: int = id % levels_per_row
	var y: int = id / levels_per_row
	
	# Create an AtlasTexture for the specific region
	var color_offset: int = color
	var atlas_tex = AtlasTexture.new()
	atlas_tex.atlas = tex
	atlas_tex.region = Rect2((x + color_offset*levels_per_row) * cell_w,
							 (y + row_offset) * cell_h,
							  cell_w, cell_h)
	texture_normal = atlas_tex
	texture_pressed = atlas_tex
	
	color_offset = 1
	atlas_tex = AtlasTexture.new()
	atlas_tex.atlas = tex
	atlas_tex.region = Rect2((x + color_offset*levels_per_row) * cell_w,
							 (y + row_offset) * cell_h,
							  cell_w, cell_h)
	texture_hover = atlas_tex
	
	color_offset = 2
	atlas_tex = AtlasTexture.new()
	atlas_tex.atlas = tex
	atlas_tex.region = Rect2((x + color_offset*levels_per_row) * cell_w,
							 (y + row_offset) * cell_h,
							  cell_w, cell_h)
	texture_pressed = atlas_tex
	
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
	pass

	if not is_opened:
		setup(level_id, 0)
		modulate.a = 0.3
	else:
		setup(level_id, 0)
		modulate.a = 1.0
