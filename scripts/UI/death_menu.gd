extends Control
signal apply_pressed
signal skip_pressed
signal restart_pressed

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
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
	
	get_viewport().size_changed.connect(_center_panel)
	visible = false
	_center_panel()

func open() -> void:
	visible = true
	await get_tree().process_frame
	_center_panel()
	$Center/Panel/Margin/VBox/BtnApply.grab_focus()

func close() -> void:
	visible = false

func _center_panel() -> void:
	var panel := $Center/Panel as Control
	# задать адекватный размер (если нулевой)
	if panel.custom_minimum_size == Vector2.ZERO:
		panel.custom_minimum_size = Vector2(420,220)
	# поставить по центру экрана
	var vp := get_viewport_rect().size
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)  # используем position/size
	panel.position = (vp - panel.size) * 0.5

func set_context(allow_apply: bool, hint: String) -> void:
	$Center/Panel/Margin/VBox/Title.text = hint
	$Center/Panel/Margin/VBox/BtnApply.disabled = not allow_apply
