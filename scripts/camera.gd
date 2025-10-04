extends Camera2D
class_name MainCamera

var player: PlayerBase = null
var SHAKE_TIME: float = 0.7

# === shake ===
@export var shake_strength: float = 10.0
@export var shake_duration: float = 0.2
var _shake_timer: float = 0.0
var _is_shaking: bool = false
var _runtime_shake_strength: float = 10.0

# === follow/hold ===
@export var follow_lerp: float = 10.0


class CameraState:
	func _init(position_: Vector2 = Vector2.ZERO, zoom_: float = 0.0) -> void:
		position = position_
		zoom = zoom_
	
	var position: Vector2 = Vector2.ZERO
	var zoom: float = 0.0

# Positioning logic
#######################################################
#
#      |--- x -----|------- y --------|
#      |           |                  |
# -----*-----------*------------------*--------
#      ^           ^                  ^
#     Follow      Effective        Target.state
#
# Effective = Target.state * y + Follow * x
# x + y = 1
# x = target_lerp
#######################################################


@export var follow_zoom: float = 1.0

var _follow_state: CameraState = null
var _target_state: TargetState = null

var _original_offset: Vector2 = Vector2.ZERO


class TargetState:
	func _init(
			target_state_: CameraState,
			zoom_in_duration_: float,
			return_back_zoom_duration_: float,
			shake_enabled_: bool = false):
		target_state = target_state_
		zoom_in_duration = zoom_in_duration_
		return_back_zoom_duration = return_back_zoom_duration_
		shake_enabled = shake_enabled_
		_returning_back = false
		_timer = 0.0
		_phase = 0.0

	var target_state: CameraState = null
	var zoom_in_duration: float = 0.0
	var return_back_zoom_duration: float = 0.0
	var duration: float = 0.0
	var shake_enabled: bool = false

	var _returning_back: bool = false
	var _timer: float = 0.0
	var _phase: float = 0.0

	func process(delta: float) -> bool:
		# return true when finished
		_timer += delta

		if _returning_back:
			_phase = 1 - _timer / return_back_zoom_duration
			if _timer >= return_back_zoom_duration:
				return true
		else:
			_phase = min(1, _timer / zoom_in_duration)
		return false

	func return_back() -> void:
		var _progress: float = min(_timer / zoom_in_duration, 1.0)
		_timer = (1 - _progress) * return_back_zoom_duration
		_returning_back = true

	func get_effective_state(follow_state: CameraState) -> CameraState:
		var pos: Vector2 = target_state.position * _phase + follow_state.position * (1 - _phase)
		var zoom: float = target_state.zoom * _phase + follow_state.zoom * (1 - _phase)
		return CameraState.new(pos, zoom)

func _ready():
	_original_offset = offset
	if player != null:
		_follow_state = CameraState.new(player.global_position, follow_zoom)

func bind_player(player_: PlayerBase) -> void:
	player = player_
	_follow_state = CameraState.new(player.global_position, follow_zoom)

func unbind_player() -> void:
	player = null
	# remember last followed state for smooth transition
	# _follow_state = null

func _physics_process(delta: float):
	# слежение за игроком, если не держим камеру и не шейкаем позицию
	if player and _follow_state:
		_follow_state.position += (player.global_position - _follow_state.position) * follow_lerp * delta

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
	
	_positioning(delta)

func _positioning(delta: float):
	if _follow_state == null:
		return

	if _target_state != null:
		if _target_state.process(delta):
			_target_state = null

	if _target_state != null:
		var effective_state: CameraState = _target_state.get_effective_state(_follow_state)
		global_position = effective_state.position
		zoom = Vector2.ONE * effective_state.zoom
	else:
		global_position = _follow_state.position
		zoom = Vector2.ONE * _follow_state.zoom


# === Публичные методы ===

# запустить тряску (если duration/strength не заданы — берутся дефолты)
func shake(duration: float = -1.0, strength: float = -1.0) -> void:
	_is_shaking = true
	_shake_timer = duration if duration > 0.0 else shake_duration
	_runtime_shake_strength = strength if strength > 0.0 else shake_strength

func set_target_state(pos: Vector2, zoom_: float, zoom_in_duration: float = 1, return_back_zoom_duration: float = 1) -> void:
	print("SET_TARGET_STATE: ", pos, zoom_, zoom_in_duration, return_back_zoom_duration)
	_target_state = TargetState.new(CameraState.new(pos, zoom_), zoom_in_duration, return_back_zoom_duration)

func reset_target_state() -> void:
	print("RESET_TARGET_STATE")
	if _target_state != null:
		_target_state.return_back()

func hard_reset_target_state() -> void:
	print("HARD_RESET_TARGET_STATE")
	_target_state = null
