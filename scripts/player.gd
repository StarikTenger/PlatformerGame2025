# Player template. The exact playable characters are to be inherited from this script.

extends CharacterBody2D

var hp : int = 1
var speed : float = 800.0
var jump_height : float = 250.0
var delay_between_jumps : float = 0.4
var time_since_last_jump : float = 0.0

func _physics_process(delta):
	var input_direction = 0
	if Input.is_action_pressed("ui_right"):
		input_direction += 1
	if Input.is_action_pressed("ui_left"):
		input_direction -= 1

	var velocity_desired = input_direction * speed

	var friction_k = 0.2 if is_on_floor() else 0.05

	velocity.x = lerp(velocity.x, velocity_desired, friction_k)

	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	time_since_last_jump += delta

	if Input.is_action_pressed("ui_up") and is_on_floor() and time_since_last_jump >= delay_between_jumps:
		velocity.y = -sqrt(2 * gravity * jump_height)
		time_since_last_jump = 0.0

	velocity.y += gravity * delta
	move_and_slide()
