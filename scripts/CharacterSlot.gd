extends PanelContainer

@onready var selector: OptionButton = $VBoxContainer/OptionButton
@onready var sprite: AnimatedSprite2D = $VBoxContainer/Sprite2D

# Словарь персонажей: имя → путь к анимации
var characters = {
	"Fire": "res://animation/fire_player.tres",
	"Wind": "res://animation/wind_player.tres"
}

func _ready():
	# Заполняем OptionButton
	for char_name in characters.keys():
		selector.add_item(char_name)

	# Привязываем сигнал
	selector.item_selected.connect(_on_character_selected)

	# Загружаем первого по умолчанию
	_on_character_selected(0)
	var tex_size = sprite.sprite_frames.get_frame_texture("idle", 0).get_size()
	selector.custom_minimum_size.x = tex_size.x * sprite.scale.x

func _on_character_selected(index: int):
	var char_name = selector.get_item_text(index)
	var anim_resource = load(characters[char_name])
	sprite.sprite_frames = anim_resource
	sprite.play("idle")  # у тебя должна быть анимация "idle"
	
func set_character(name: String):
	var idx := -1
	for i in range(selector.item_count):
		if selector.get_item_text(i) == name:
			idx = i
			break
	if idx != -1:
		selector.select(idx)
		_on_character_selected(idx)
	else:
		push_warning("Character '%s' not found in OptionButton" % name)
