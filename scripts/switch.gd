# res://scripts/Switch.gd
extends Area2D

@export var door: Door            # просто перетащи узел Door в это поле в инспекторе
@export var off_texture: Texture2D
@export var on_texture: Texture2D
@export var one_shot: bool = true # если true — повторное касание игнорим

var _triggered: bool = false

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_apply_look()

func _on_body_entered(body: Node) -> void:
	if _triggered and one_shot:
		return
	if not _is_player(body):
		return

	_triggered = true
	_apply_look()
	if door:
		door.open()

func _is_player(body: Node) -> bool:
	# самый простой способ — помести своих персонажей в группу "player"
	# (в Player._ready(): add_to_group("player"))
	return body.is_in_group("player")

func _apply_look() -> void:
	if _sprite:
		_sprite.texture = (on_texture if _triggered else off_texture)
