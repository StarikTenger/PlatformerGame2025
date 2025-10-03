extends Camera2D

var player: Node2D = null
var SHAKE_TIME: float = 0.7

# === shake ===
@export var shake_strength: float = 10.0
@export var shake_duration: float = 0.2
var _shake_timer: float = 0.0
var _is_shaking: bool = false
var _runtime_shake_strength: float = 10.0

# === follow/hold ===
@export var follow_lerp: float = 10.0
var _follow_enabled: bool = true
var _is_holding: bool = false

var _original_offset: Vector2

func _ready():
	_original_offset = offset
	if player != null:
		global_position = player.global_position

func _physics_process(delta: float):
	# слежение за игроком, если не держим камеру и не шейкаем позицию
	if player and _follow_enabled and not _is_holding and not _is_shaking:
		global_position += (player.global_position - global_position) * follow_lerp * delta

	# обработка шейка (offset)
	if _is_shaking:
		_shake_timer -= delta
		if _shake_timer <= 0.0:
			_is_shaking = false
			offset = _original_offset
		else:
			var shake_offset := Vector2(
				randf_range(-_runtime_shake_strength, _runtime_shake_strength),
				randf_range(-_runtime_shake_strength, _runtime_shake_strength)
			)
			offset = _original_offset + shake_offset

# === Публичные методы ===

# запустить тряску (если duration/strength не заданы — берутся дефолты)
func shake(duration: float = -1.0, strength: float = -1.0) -> void:
	_is_shaking = true
	_shake_timer = duration if duration > 0.0 else shake_duration
	_runtime_shake_strength = strength if strength > 0.0 else shake_strength

# удержать камеру в точке pos на seconds сек; опционально трясти всё это время
func hold_at(pos: Vector2, seconds: float, do_shake: bool = false, shake_strength_override: float = -1.0) -> void:
	var prev_follow := _follow_enabled
	_follow_enabled = false
	_is_holding = true

	if do_shake:
		var prev_strength := shake_strength
		if shake_strength_override > 0.0:
			shake_strength = shake_strength_override
		shake(SHAKE_TIME)  # трясём всё время удержания
		await get_tree().create_timer(seconds).timeout
		shake_strength = prev_strength
	else:
		await get_tree().create_timer(seconds).timeout

	_is_holding = false
	_follow_enabled = prev_follow
