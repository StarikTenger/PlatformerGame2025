# Player template. The exact playable characters are to be inherited from this script.

extends CharacterBody2D
class_name PlayerBase

signal moved_once
signal died
signal death_request(player: Node)

@export var hazards_map: TileMapLayer
@export var tiles_map: TileMapLayer
@export var hazard_flag_name := "hazard"
@export var pushable_flag_name := "pushable"

enum PlayerType {
	FIRE,
	WIND,
	EARTH,
	UNKNOWN,
}

func _ready() -> void:
	if tiles_map == null:
		var lvl := get_tree().current_scene
		tiles_map = lvl.find_child("Tiles", true, false) as TileMapLayer
	add_to_group("liftable")
	add_to_group("player")

var hp : int = 1
var speed : float = 800.0
var jump_height : float = 250.0
var delay_between_jumps : float = 0.4
var time_since_last_jump : float = 0.0
var _death_immunity_until_s: float = 0.0

var _emitted_move := false
var _dead: bool = false
var _frozen_on_death := false

func die() -> void:
	if _dead:
		return
	_dead = true
	_freeze_on_death(true)
	emit_signal("death_request", self)
	return

# Уровень вызовет это, если в меню нажали «Применить смерть»
func apply_death_effect() -> void:
	await _death_effect()                   # у наследников (огненный) тут ломаются тайлы

# Уровень вызовет это, когда надо реально умереть (после эффекта)
func finalize_death() -> void:
	emit_signal("died")
	queue_free()

# Уровень вызовет это, если в меню нажали «Не применять смерть»
func cancel_death() -> void:
	_dead = false
	_freeze_on_death(false)

func _freeze_on_death(f: bool) -> void:
	_frozen_on_death = f
	set_physics_process(not f)
	set_process(not f)

func _death_effect() -> void:
	await get_tree().process_frame

func death_hint() -> String:
	# дефолтный персонаж — без особого эффекта
	return "This character does not leave any effect after death"

func _physics_process(delta):
	if _frozen_on_death:
		return
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

	# Animation handling
	var anim_player = $Sprite2D
	if is_on_floor():
		if input_direction == 0:
			anim_player.play("idle")
		else:
			anim_player.play("walking")
			anim_player.flip_h = input_direction < 0
	else:
		if input_direction == 0:
			if velocity.y < 0:
				anim_player.play("jump_up")
			else:
				anim_player.play("fall")
		else:
			anim_player.play("jump_right")
			anim_player.flip_h = input_direction < 0

	var velocity_desired = input_direction * speed

	var friction_k = 0.2 if is_on_floor() else 0.05

	velocity.x = lerp(velocity.x, velocity_desired, friction_k)
	
	# hard movement
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
		# интересуют только столкновения с нужным TileMapLayer
		if tiles_map != null and col.get_collider() == tiles_map:
			var cell := _cell_at_collision(tiles_map, col)
			if cell != null:
				var td := tiles_map.get_cell_tile_data(cell)
				if td != null:
					if td.get_custom_data(hazard_flag_name) == true:
						die()
						return
					elif td.get_custom_data(pushable_flag_name) == true:
						_push_block(cell, col.get_normal())
					
func _cell_at_collision(layer: TileMapLayer, col: KinematicCollision2D) -> Vector2i:
	# берём точку чуть "внутрь" тайла (сдвигаемся на полпикселя по нормали)
	var world_p: Vector2 = col.get_position() - col.get_normal() * 0.5
	var local_p: Vector2 = layer.to_local(world_p)
	return layer.local_to_map(local_p)

func _push_block(cell: Vector2i, normal: Vector2) -> void:
	# вычисляем куда толкнуть
	var target_cell := cell + Vector2i(round(-normal.x), round(-normal.y))
	# проверяем что целевая пустая
	if tiles_map.get_cell_source_id(target_cell) == -1:
		var source_id := tiles_map.get_cell_source_id(cell)
		var atlas_coords := tiles_map.get_cell_atlas_coords(cell)
		# переносим тайл
		tiles_map.set_cell(target_cell, source_id, atlas_coords)
		tiles_map.set_cell(cell, -1)


func set_death_immunity(seconds: float = 0.5) -> void:
	_death_immunity_until_s = Time.get_unix_time_from_system() + seconds

func _can_die() -> bool:
	return Time.get_unix_time_from_system() >= _death_immunity_until_s

func get_player_type() -> PlayerType:
	return PlayerType.UNKNOWN
