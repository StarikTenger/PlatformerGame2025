extends Control
class_name CharacterDeckItem

@export var character_type: level_template.CharType
@export var is_current: bool = false
@export var item_index: int = 0

@onready var background: Panel = $Background
@onready var icon: TextureRect = $Icon
@onready var border: Panel = $Border

# Character type colors and icons
const TYPE_COLORS = {
	level_template.CharType.FIRE: Color.RED,
	level_template.CharType.WIND: Color.CYAN,
	level_template.CharType.EARTH: Color.BROWN,
	level_template.CharType.WATER: Color.BLUE
}

const TYPE_NAMES = {
	level_template.CharType.FIRE: "F",
	level_template.CharType.WIND: "W", 
	level_template.CharType.EARTH: "E",
	level_template.CharType.WATER: "A"
}

func _ready():
	# Set up the item appearance
	_setup_appearance()

func _setup_appearance():
	if not background or not border:
		return
		
	# Set background color based on character type
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = TYPE_COLORS.get(character_type, Color.GRAY)
	style_bg.corner_radius_top_left = 4
	style_bg.corner_radius_top_right = 4
	style_bg.corner_radius_bottom_left = 4
	style_bg.corner_radius_bottom_right = 4
	background.add_theme_stylebox_override("panel", style_bg)
	
	# Set border for current character
	var style_border = StyleBoxFlat.new()
	if is_current:
		style_border.bg_color = Color.TRANSPARENT
		style_border.border_color = Color.WHITE
		style_border.border_width_left = 3
		style_border.border_width_right = 3
		style_border.border_width_top = 3
		style_border.border_width_bottom = 3
	else:
		style_border.bg_color = Color.TRANSPARENT
		style_border.border_color = Color.TRANSPARENT
	
	style_border.corner_radius_top_left = 4
	style_border.corner_radius_top_right = 4
	style_border.corner_radius_bottom_left = 4
	style_border.corner_radius_bottom_right = 4
	border.add_theme_stylebox_override("panel", style_border)
	
	# Set icon text (simple letter representation)
	if icon and icon is Label:
		(icon as Label).text = TYPE_NAMES.get(character_type, "?")
		(icon as Label).add_theme_color_override("font_color", Color.WHITE)

func update_current_status(current: bool):
	is_current = current
	_setup_appearance()

func set_character_data(type: level_template.CharType, index: int, current: bool):
	character_type = type
	item_index = index
	is_current = current
	if is_inside_tree():
		_setup_appearance()