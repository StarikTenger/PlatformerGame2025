extends Control

signal next_pressed
signal restart_pressed
signal menu_pressed

var _prev_mouse_mode: int = Input.get_mouse_mode()
var tex: Texture2D = preload("res://resources/ui/buttons.png")

func get_atlas_texture(line: int, color=0):
	# Add texture depending on level 1-5 first line, 6-10 second line, etc.
	var colors: int = 3
	var rows: int = 10
	var row_offset: int = 0
	var color_offset: int = color
	var cell_w: int = tex.get_width() / colors
	var cell_h: int = tex.get_height() / rows
	var y: int = line
	
	# Create an AtlasTexture for the specific region
	var atlas_tex = AtlasTexture.new()
	atlas_tex.atlas = tex
	atlas_tex.region = Rect2(color_offset * cell_w,
							 (y + row_offset) * cell_h,
							  cell_w, cell_h)
	return atlas_tex


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	set_process_unhandled_input(true)
	# растянуть рут на весь экран
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	
	mouse_filter = Control.MOUSE_FILTER_STOP

	$Center/Panel/Margin/VBox/BtnNext.pressed.connect(func(): emit_signal("next_pressed"))
	$Center/Panel/Margin/VBox/BtnRestart.pressed.connect(func(): emit_signal("restart_pressed"))
	$Center/Panel/Margin/VBox/BtnMenu.pressed.connect(func(): emit_signal("menu_pressed"))

	# Textures and alignment
	var apply_btn = $Center/Panel/Margin/VBox/BtnNext
	apply_btn.stretch_mode = 3
	apply_btn.texture_normal = get_atlas_texture(0, 0)
	apply_btn.texture_hover = get_atlas_texture(0, 1)
	apply_btn.texture_pressed = get_atlas_texture(0, 2)
	apply_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var skip_btn = $Center/Panel/Margin/VBox/BtnRestart
	skip_btn.stretch_mode = 3
	skip_btn.texture_normal = get_atlas_texture(1, 0)
	skip_btn.texture_hover = get_atlas_texture(1, 1)
	skip_btn.texture_pressed = get_atlas_texture(1, 2)
	skip_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var restart_btn = $Center/Panel/Margin/VBox/BtnMenu
	restart_btn.stretch_mode = 3
	restart_btn.texture_normal = get_atlas_texture(2, 0)
	restart_btn.texture_hover = get_atlas_texture(2, 1)
	restart_btn.texture_pressed = get_atlas_texture(2, 2)
	restart_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	# Fix MarginContainer sizing - let it size itself and add reasonable margins
	var margin = $Center/Panel/Margin
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Add smaller margins so content fits better
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)


	get_viewport().size_changed.connect(_center_panel)
	visible = false
	_center_panel()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("esc_menu"):
		pass

func open() -> void:
	visible = true
	_prev_mouse_mode = Input.get_mouse_mode()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	await get_tree().process_frame
	_center_panel()
	$Center/Panel/Margin/VBox/BtnNext.grab_focus()

func close_menu() -> void:
	# Закрывает меню И снимает паузу
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(_prev_mouse_mode)

func _center_panel() -> void:
	var panel := $Center/Panel as Control
	# задать адекватный размер (если нулевой) - make it taller for WinMenu
	#if panel.custom_minimum_size == Vector2.ZERO:
	panel.custom_minimum_size = Vector2(420, 320)  # Increased height from 220 to 280
	# поставить по центру экрана
	var vp := get_viewport_rect().size
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)  # используем position/size
	panel.position = (vp - panel.size) * 0.5

# func _on_btn_next_pressed() -> void:
# 	emit_signal("next_pressed")
# 	close_menu()

# func _on_btn_restart_pressed() -> void:
# 	emit_signal("restart_pressed")
# 	close_menu()

# func _on_btn_main_menu_pressed() -> void:
# 	emit_signal("menu_pressed")
# 	close_menu()
