# res://scripts/Projectile.gd
extends CharacterBody2D

@export var speed: float = 700.0
@export var direction: Vector2 = Vector2.RIGHT
@export var lifetime: float = 4.0
@export var destroy_on_any_collision: bool = true

var _age := 0.0

func _ready() -> void:
	direction = direction.normalized()

func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
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
			queue_free()
