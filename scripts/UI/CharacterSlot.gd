extends PanelContainer

@onready var sprite: AnimatedSprite2D = $Panel/Sprite2D

var char_idx: int = 0

var characters = [
	["Fire", "res://animation/fire_player.tres"],
	["Wind", "res://animation/wind_player.tres"],
	["Earth", "res://animation/earth_player.tres"],
]

func _ready():
	# Загружаем первого по умолчанию
	_on_character_selected(0)

func _on_character_selected(id: int):
	var anim_resource = load(characters[id][1])
	sprite.sprite_frames = anim_resource
	sprite.play("idle")
	
func set_character(name: String):
	for i in range(characters.size()):
		if characters[i][0] == name:
			char_idx = i
			_on_character_selected(char_idx)
			break

func _on_button_pressed() -> void:
	if not get_node("/root/Level/StartRoster").is_can_change():
		return
	char_idx = (char_idx + 1) % characters.size()
	_on_character_selected(char_idx)

func get_focus() -> void:
	$Button.grab_focus()
