# Player template. The exact playable characters are to be inherited from this script.

extends CharacterBody2D

@export var hazards_map: TileMapLayer

func _ready() -> void:
	hazards_map = get_parent().get_node("Hazards")

var hp : int = 1
var speed : float = 800.0
var jump_height : float = 250.0
var delay_between_jumps : float = 0.4
var time_since_last_jump : float = 0.0

func _physics_process(delta):
	var input_direction = 0
	if Input.is_action_pressed("move_right"):
		input_direction += 1
	if Input.is_action_pressed("move_left"):
		input_direction -= 1

	var velocity_desired = input_direction * speed

	var friction_k = 0.2 if is_on_floor() else 0.05

	velocity.x = lerp(velocity.x, velocity_desired, friction_k)

	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	time_since_last_jump += delta

	if Input.is_action_pressed("jump") and is_on_floor() and time_since_last_jump >= delay_between_jumps:
		velocity.y = -sqrt(2 * gravity * jump_height)
		time_since_last_jump = 0.0

	velocity.y += gravity * delta
	move_and_slide()
	
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		if col.get_collider() == hazards_map:
			die()

func die():
	print(get_parent())
	get_tree().reload_current_scene()
