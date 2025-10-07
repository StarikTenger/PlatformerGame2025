# res://scripts/Projectile.gd
extends CharacterBody2D

@export var speed: float = 700.0
@export var direction: Vector2 = Vector2.RIGHT
@export var lifetime: float = 4.0
@export var destroy_on_any_collision: bool = true

var _age := 0.0

func _ready() -> void:
	direction = direction.normalized()
	explosion_scene = preload("res://scenes/Explosion.tscn")

var explosion_scene : PackedScene
var explosion_type : Explosion.Type = Explosion.Type.PROJECTILE

func _destroy() -> void:
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	explosion.type = explosion_type
	get_parent().add_child(explosion)
	queue_free()

func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		_destroy()
		return

	velocity = direction * speed
	var col := move_and_collide(velocity * delta)
	if col:
		var c := col.get_collider()
		# попали в игрока?
		if c and c.has_method("die"):
			c.die()
		# в остальном просто исчезаем (об стену/тайлмап и т.п.)
		if destroy_on_any_collision:
			_destroy()
