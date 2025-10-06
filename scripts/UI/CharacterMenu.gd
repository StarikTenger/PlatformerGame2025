extends Control

@onready var hbox = $Margin/HBoxContainer
@export var character_slot_scene: PackedScene
@export var num_slots := 4
var chosen : Array[String]
var current_level_number: int = 1
signal start_pressed

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

func _ready():
	process_mode =Node.PROCESS_MODE_ALWAYS
	
	# Get level number safely and handle title visibility
	current_level_number = _get_current_level_number()
	print("CharacterMenu: Detected level ", current_level_number)
	
	# If tutorial level, hide the title text
	if current_level_number <= 3:
		var title_node = get_node_or_null("Margin/Title")
		if title_node:
			# title_node.hide()
			title_node.text = "TUTORIAL " + str(current_level_number)
	
	# Создаем нужное количество слотов
	for i in range(num_slots):
		var slot = character_slot_scene.instantiate()
		hbox.add_child(slot)
	$Margin/StartButton.pressed.connect(_on_start_pressed)
	$Margin/MainMenuButton.pressed.connect(_on_main_menu_button_pressed)
	var max_height = 0
	for slot in hbox.get_children():
		var slot_tex = slot.sprite.sprite_frames.get_frame_texture("idle", 0)
		max_height = max(max_height, slot_tex.get_size().y * slot.sprite.scale.y)
	$Margin/Spacer.custom_minimum_size = Vector2(0, max_height)
	
	$Margin/StartButton.stretch_mode = 3
	$Margin/StartButton.texture_normal = get_atlas_texture(4, 0)
	$Margin/StartButton.texture_hover = get_atlas_texture(4, 1)
	$Margin/StartButton.texture_focused = get_atlas_texture(4, 1)
	$Margin/StartButton.texture_pressed = get_atlas_texture(4, 2)

	$Margin/MainMenuButton.stretch_mode = 3
	$Margin/MainMenuButton.texture_normal = get_atlas_texture(2, 0)
	$Margin/MainMenuButton.texture_hover = get_atlas_texture(2, 1)
	$Margin/MainMenuButton.texture_focused = get_atlas_texture(2, 1)
	$Margin/MainMenuButton.texture_pressed = get_atlas_texture(2, 2)
	
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

func _get_current_level_number() -> int:
	# Extract level number from current scene filename
	var scene_file = get_tree().current_scene.scene_file_path
	if "level_1" in scene_file:
		return 1
	elif "level_2" in scene_file:
		return 2
	elif "level_3" in scene_file:
		return 3
	elif "level_4" in scene_file:
		return 4
	elif "level_5" in scene_file:
		return 5
	return 1  # Default to level 1

func set_level_number(level_num: int):
	current_level_number = level_num
	print("CharacterMenu: Set to level ", level_num)
	
	# If tutorial level, hide the title text
	if current_level_number <= 2:
		var title_node = get_node_or_null("Margin/Title")
		if title_node:
			title_node.hide()

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
