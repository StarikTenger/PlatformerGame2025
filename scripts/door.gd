# res://scripts/Door.gd
class_name Door
extends StaticBody2D

@export var open_distance: float = 250.0       # на сколько пикселей поднять ворота
@export var open_duration: float = 0.25       # время анимации (сек)
@export var ease_up: bool = true              # плавное ускор/замедление
@export var disable_collision_on_open: bool = true  # сразу убрать коллизию при открытии

@onready var _coll: CollisionShape2D = $CollisionShape2Dц

var is_open: bool = false
var _opening: bool = false
var _closed_pos: Vector2

func _ready() -> void:
	_closed_pos = position

func open() -> void:
	if is_open or _opening:
		return
	_opening = true

	# если не хочешь, чтобы ворота «пихали» игрока при движении — сразу выключаем коллизию
	if disable_collision_on_open and _coll:
		_coll.disabled = true

	var target := _closed_pos + Vector2(0, -open_distance)
	var tw := create_tween()
	if ease_up:
		tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", target, open_duration)
	await tw.finished

	is_open = true
	_opening = false

# опционально — если когда-нибудь понадобится закрывать обратно:
func close() -> void:
	if not is_open:
		return
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "position", _closed_pos, open_duration)
	await tw.finished
	is_open = false
	if _coll:
		_coll.disabled = false
