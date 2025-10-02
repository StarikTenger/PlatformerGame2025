# Player template. The exact playable characters are to be inherited from this script.

extends CharacterBody2D

signal moved_once
signal died

@export var hazards_map: TileMapLayer

func _ready() -> void:
	hazards_map = get_parent().get_node("Hazards")
	add_to_group("liftable")

var hp : int = 1
var speed : float = 800.0
var jump_height : float = 250.0
var delay_between_jumps : float = 0.4
var time_since_last_jump : float = 0.0
var _death_immunity_until_s: float = 0.0

var _emitted_move := false
var _dead: bool = false

func die() -> void:
	if _dead:
		return
	_dead = true
	await _death_effect()
	if not _can_die():
		return
	emit_signal("died")
	queue_free()

func _death_effect() -> void:
	await get_tree().process_frame

func _physics_process(delta):
	var input_direction = 0
	if Input.is_action_pressed("move_right"):
		input_direction += 1
		if not _emitted_move:
			_emitted_move = true
			emit_signal("moved_once")
	if Input.is_action_pressed("move_left"):
		input_direction -= 1
		if not _emitted_move:
			_emitted_move = true
			emit_signal("moved_once")
	if Input.is_action_just_pressed("ctrl"):
		die()
		return

	var velocity_desired = input_direction * speed

	var friction_k = 0.2 if is_on_floor() else 0.05

	velocity.x = lerp(velocity.x, velocity_desired, friction_k)
	if input_direction != 0 and !is_on_floor():
		velocity.x = velocity_desired

	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	time_since_last_jump += delta

	if Input.is_action_pressed("jump") and is_on_floor() and time_since_last_jump >= delay_between_jumps:
		velocity.y = -sqrt(2 * gravity * jump_height)
		time_since_last_jump = 0.0
		if not _emitted_move:
			_emitted_move = true
			emit_signal("moved_once")

	velocity.y += gravity * delta
	move_and_slide()
	
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		if col.get_collider() == hazards_map:
			die()
			return

func set_death_immunity(seconds: float = 0.5) -> void:
	_death_immunity_until_s = Time.get_unix_time_from_system() + seconds

func _can_die() -> bool:
	return Time.get_unix_time_from_system() >= _death_immunity_until_s
