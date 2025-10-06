extends Control

@onready var hbox = $Margin/HBoxContainer
@export var character_slot_scene: PackedScene
@export var num_slots := 4
var chosen : Array[String]
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
	if not SaveState.get_restarted():
		var first_picker: PanelContainer = $Margin/HBoxContainer.get_child(0)
		first_picker.get_focus()
	else:
		$Margin/StartButton.grab_focus()

func _on_start_pressed():
	chosen = []
	for slot in hbox.get_children():
		# get char_name
		var char_name = slot.characters[slot.char_idx][0]
		chosen.append(char_name)
	emit_signal("start_pressed")
	# теперь можно передать chosen в level_template

func get_chosen():
	return chosen

func load_chosen(_chosen : Array[String]):
	chosen = _chosen
	var cnt = 0
	for slot in hbox.get_children():
		if cnt < chosen.size():
			var char_name = _chosen[cnt]
			cnt += 1
			print (char_name)
			slot.set_character(char_name)


func _on_main_menu_button_pressed() -> void:
	SaveState.set_restarted(false)
	get_tree().root.get_node("LevelManager").show()
	get_tree().root.get_node("LevelManager").get_focus()
	get_tree().root.get_node("Level").queue_free()
