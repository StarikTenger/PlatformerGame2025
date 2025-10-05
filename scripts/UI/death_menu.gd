extends Control
signal apply_pressed
signal skip_pressed
signal restart_pressed

var _prev_mouse_mode: int = Input.get_mouse_mode()

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
	$Center/Panel/Margin/VBox/BtnApply.grab_focus()

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

func set_context(allow_apply: bool, hint: String) -> void:
	$Center/Panel/Margin/VBox/Title.text = hint
	$Center/Panel/Margin/VBox/BtnApply.disabled = not allow_apply

func _on_btn_apply_pressed() -> void:
	close_menu()
	emit_signal("apply_pressed")

func _on_btn_skip_pressed() -> void:
	close_menu()
	emit_signal("skip_pressed")

func _on_btn_restart_pressed() -> void:
	close_menu()
	emit_signal("restart_pressed")
