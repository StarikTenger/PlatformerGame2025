extends Control

# Configuration parameters for deck display
const DECK_ITEM_SIZE = Vector2(90, 90)  # Size of each character deck item
const DECK_CONTAINER_POSITION = Vector2(20, 20)  # Position from top-left corner
const DECK_ITEM_SEPARATION = 20  # Distance between deck items in pixels
const DECK_BORDER_WIDTH = 3  # Width of the current character border
const DECK_BORDER_RADIUS = 5  # Corner radius for the border

const CharacterDeckItemScene = preload("res://scenes/UI/CharacterDeckItem.tscn")

var deck_items: Array[Control] = []
var deck_container: HBoxContainer

func _ready() -> void:
	print("HUD ready")
	process_mode = Node.PROCESS_MODE_ALWAYS  # Changed from WHEN_PAUSED to ALWAYS
	# растянуть рут на весь экран
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0

	visible = true
	
	# Create deck container in top-left corner
	deck_container = HBoxContainer.new()
	deck_container.position = DECK_CONTAINER_POSITION
	deck_container.add_theme_constant_override("separation", DECK_ITEM_SEPARATION)
	add_child(deck_container)
	
	var deck_panel = get_node_or_null("DeckPanel")
	if deck_panel:
		deck_panel.visible = false

	await get_tree().process_frame

func _on_deck_update(char_deck: Array, alive: Array[bool], current_index: int):
	print("HUD: Roster updated with ", char_deck.size(), " characters, current index: ", current_index)
	_clear_deck_items()
	_create_deck_items(char_deck, alive, current_index)

func _clear_deck_items():
	for item in deck_items:
		if is_instance_valid(item):
			item.queue_free()
	deck_items.clear()

func _create_deck_items(char_deck: Array, alive: Array[bool], current_index: int):
	print("Creating deck items...")
	print("Character deck: ", alive)

	for i in range(char_deck.size()):
		var char_type = char_deck[i]
		var deck_item = CharacterDeckItemScene.instantiate()
		
		# Set up the item
		deck_item.custom_minimum_size = DECK_ITEM_SIZE
		deck_item.size = DECK_ITEM_SIZE

		
		# Set animation and scale the sprite based on character type and state
		var animated_sprite = deck_item.get_node("AnimatedSprite2D") as AnimatedSprite2D
		
		# Scale the sprite to fit within the deck item size
		# The original sprite is quite large (1920x1080), so we need to scale it down significantly
		var sprite_scale = min(DECK_ITEM_SIZE.x / 1920.0, DECK_ITEM_SIZE.y / 1080.0)
		if  i != current_index:
			sprite_scale *= 1.2
		else:
			sprite_scale *= 1.5
		animated_sprite.scale = Vector2(sprite_scale, sprite_scale)
		

		# Center the sprite within the control
		animated_sprite.position = DECK_ITEM_SIZE * 0.5
		
		# Add border for current character
		if i == current_index:
			_add_current_border(deck_item)

		var is_dead = !alive[i]
		var animation_name = char_type
		if is_dead:
			animation_name += "_dead"
		if animated_sprite.sprite_frames.has_animation(animation_name):
			animated_sprite.animation = animation_name
			if i == current_index:
				animated_sprite.play()
			else:
				# freeze animation for non-current characters
				animated_sprite.frame = 0
				animated_sprite.stop()

		# Add the item to the container and track it
		deck_container.add_child(deck_item)
		deck_items.append(deck_item)

	# Adjust DeckPanel size and position to fit all deck items
	var deck_panel = get_node_or_null("DeckPanel")
	if deck_panel:
		var total_width = char_deck.size() * DECK_ITEM_SIZE.x + max(0, char_deck.size() - 1) * DECK_ITEM_SEPARATION
		deck_panel.size = Vector2(total_width, DECK_ITEM_SIZE.y)
		deck_panel.position = DECK_CONTAINER_POSITION
	deck_panel.visible = true


func _add_current_border(deck_item: Control):
	# Remove existing border first
	_remove_current_border(deck_item)
	
	# Create border panel
	var border = Panel.new()
	border.name = "CurrentBorder"
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Style the border
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color.TRANSPARENT
	style_box.border_color = Color.WHITE
	style_box.border_width_left = DECK_BORDER_WIDTH
	style_box.border_width_right = DECK_BORDER_WIDTH
	style_box.border_width_top = DECK_BORDER_WIDTH
	style_box.border_width_bottom = DECK_BORDER_WIDTH
	style_box.corner_radius_top_left = DECK_BORDER_RADIUS
	style_box.corner_radius_top_right = DECK_BORDER_RADIUS
	style_box.corner_radius_bottom_left = DECK_BORDER_RADIUS
	style_box.corner_radius_bottom_right = DECK_BORDER_RADIUS
	
	border.add_theme_stylebox_override("panel", style_box)
	deck_item.add_child(border)

func _remove_current_border(deck_item: Control):
	var existing_border = deck_item.get_node_or_null("CurrentBorder")
	if existing_border:
		existing_border.queue_free()
