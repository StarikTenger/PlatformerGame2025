# res://scripts/Dispenser.gd
extends Node2D

@export var projectile_scene: PackedScene
@export var interval: float = 1.2
@export var start_delay: float = 0.0
@export var active: bool = true

@export var direction: Vector2 = Vector2.LEFT
@export var projectile_speed: float = 700.0
@export var projectile_lifetime: float = 4.0

@export var aim_at_player: bool = false  # если true — целимся в текущего игрока

@onready var _spawn: Marker2D = $Spawn
@onready var _timer: Timer = $Timer

func _ready() -> void:
	_timer.one_shot = false
	_timer.wait_time = max(0.01, interval)
	_timer.timeout.connect(_fire)

	if active:
		if start_delay > 0.0:
			await get_tree().create_timer(start_delay).timeout
		_timer.start()

func _fire() -> void:
	# Animation
	var anim: AnimatedSprite2D = $AnimatedSprite2D
	anim.play("fire")

	# Wait to the end of animation
	await anim.animation_finished

	if projectile_scene == null:
		push_error("Dispenser: projectile_scene not set")
		return

	var p := projectile_scene.instantiate()
	# где спавним
	p.global_position = _spawn.global_position

	# направление
	var dir := direction
	if aim_at_player:
		var player := _find_player()
		if player:
			dir = (player.global_position - _spawn.global_position).normalized()

	# прокидываем параметры в снаряд, если у него они есть
	if "direction" in p: p.direction = dir
	if "speed"     in p: p.speed = projectile_speed
	if "lifetime"  in p: p.lifetime = projectile_lifetime

	# добавляем в ту же сцену, что и диспенсер
	get_parent().add_child(p)


func _find_player() -> Node2D:
	# запасной — берём первого CharacterBody2D в сцене с методом die()
	for n in get_tree().current_scene.get_children():
		if n is PlayerBase:
			return n
	return null
