extends Control
signal apply_pressed
signal skip_pressed
signal restart_pressed

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
	
	# подключение кнопок
	$Center/Panel/Margin/VBox/BtnApply.pressed.connect(func(): emit_signal("apply_pressed"))
	$Center/Panel/Margin/VBox/BtnSkip.pressed.connect(func(): emit_signal("skip_pressed"))
	$Center/Panel/Margin/VBox/BtnRestart.pressed.connect(func(): emit_signal("restart_pressed"))
	
	# Textures and alignment
	var apply_btn = $Center/Panel/Margin/VBox/BtnApply
	apply_btn.stretch_mode = 3
	apply_btn.texture_normal = get_atlas_texture(3, 0)
	apply_btn.texture_hover = get_atlas_texture(3, 1)
	apply_btn.texture_focused = get_atlas_texture(3, 1)
	apply_btn.texture_pressed = get_atlas_texture(3, 2)
	apply_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var skip_btn = $Center/Panel/Margin/VBox/BtnSkip
	skip_btn.stretch_mode = 3
	skip_btn.texture_normal = get_atlas_texture(1, 0)
	skip_btn.texture_hover = get_atlas_texture(1, 1)
	skip_btn.texture_focused = get_atlas_texture(1, 1)
	skip_btn.texture_pressed = get_atlas_texture(1, 2)
	skip_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var restart_btn = $Center/Panel/Margin/VBox/BtnRestart
	restart_btn.stretch_mode = 3
	restart_btn.texture_normal = get_atlas_texture(2, 0)
	restart_btn.texture_hover = get_atlas_texture(2, 1)
	restart_btn.texture_focused = get_atlas_texture(2, 1)
	restart_btn.texture_pressed = get_atlas_texture(2, 2)
	restart_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	# Fix MarginContainer sizing - it should fill the Panel
	var margin = $Center/Panel/Margin
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	get_viewport().size_changed.connect(_center_panel)
	visible = false
	_center_panel()

func _unhandled_input(event: InputEvent) -> void:
	if visible and Input.is_action_just_pressed("esc_menu"):
		get_tree().root.set_input_as_handled()
		print("Death menu: Escape pressed, closing menu")
		close_menu()
		# emit_signal("apply_pressed")


func open() -> void:
	visible = true
	_prev_mouse_mode = Input.get_mouse_mode()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	await get_tree().process_frame
	_center_panel()
	var vbox = $Center/Panel/Margin/VBox as Control
	var apply_btn = vbox.get_node_or_null("BtnApply")
	var skip_btn = vbox.get_node_or_null("BtnSkip")
	if apply_btn and apply_btn.visible and not apply_btn.disabled:
		apply_btn.grab_focus()
	elif skip_btn:
		skip_btn.grab_focus()

func close_menu() -> void:
	# Закрывает меню И снимает паузу
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(_prev_mouse_mode)

func _center_panel() -> void:
	var panel := $Center/Panel as Control
	# задать адекватный размер (если нулевой)
	if panel.custom_minimum_size == Vector2.ZERO:
		panel.custom_minimum_size = Vector2(420,220)
	# поставить по центру экрана
	var vp := get_viewport_rect().size
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)  # используем position/size
	panel.position = (vp - panel.size) * 0.5

func set_context(allow_resume: bool, hint: String) -> void:
	$Center/Panel/Margin/VBox/Title.text = hint
	var vbox = $Center/Panel/Margin/VBox as Control
	var btn = vbox.get_node_or_null("BtnApply")
	if btn:
		btn.disabled = not allow_resume
		# properly toggle visibility
		btn.visible = allow_resume
		# if made visible and menu is already open, focus it
		if allow_resume and visible:
			btn.grab_focus()

func _on_btn_apply_pressed() -> void:
	close_menu()
	emit_signal("apply_pressed")

func _on_btn_skip_pressed() -> void:
	close_menu()
	emit_signal("skip_pressed")

func _on_btn_restart_pressed() -> void:
	close_menu()
	emit_signal("restart_pressed")
