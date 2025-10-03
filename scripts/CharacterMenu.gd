extends Control

@onready var hbox = $Margin/HBoxContainer
@export var character_slot_scene: PackedScene
@export var num_slots := 4
var chosen := []
signal start_pressed

func _ready():
	process_mode =Node.PROCESS_MODE_ALWAYS
	# Создаем нужное количество слотов
	for i in range(num_slots):
		var slot = character_slot_scene.instantiate()
		hbox.add_child(slot)
	$Margin/StartButton.pressed.connect(_on_start_pressed)
	var max_height = 0
	for slot in hbox.get_children():
		var tex = slot.sprite.sprite_frames.get_frame_texture("idle", 0)
		max_height = max(max_height, tex.get_size().y * slot.sprite.scale.y)
	$Margin/Spacer.custom_minimum_size = Vector2(0, max_height)
	print(max_height)

func _on_start_pressed():
	print("start pressed")
	for slot in hbox.get_children():
		var char_name = slot.selector.get_item_text(slot.selector.selected)
		chosen.append(char_name)
	print("Выбранные персонажи:", chosen)
	emit_signal("start_pressed")
	# теперь можно передать chosen в level_template
