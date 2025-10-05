extends Control

signal next_pressed
signal restart_pressed
signal menu_pressed

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

	$Center/Panel/Margin/VBox/BtnNext.pressed.connect(func(): emit_signal("next_pressed"))
	$Center/Panel/Margin/VBox/BtnRestart.pressed.connect(func(): emit_signal("restart_pressed"))
	$Center/Panel/Margin/VBox/BtnMenu.pressed.connect(func(): emit_signal("menu_pressed"))

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
	# задать адекватный размер (если нулевой)
	if panel.custom_minimum_size == Vector2.ZERO:
		panel.custom_minimum_size = Vector2(420,220)
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
