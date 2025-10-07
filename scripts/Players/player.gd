# Player template. The exact playable characters are to be inherited from this script.

extends CharacterBody2D
class_name PlayerBase

signal moved_once
signal died
signal death_request(player: Node)

@export var hazards_map: TileMapLayer
@export var tiles_map: TileMapLayer
@export var tiles_map_2: TileMapLayer
@export var hazard_flag_name := "hazard"
@export var pushable_flag_name := "pushable"

@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

var explosion_scene : PackedScene
var explosion_type : Explosion.Type = Explosion.Type.FIRE

enum PlayerType {
	FIRE,
	WIND,
	EARTH,
	UNKNOWN,
}

# Get all tile layers for operations
func _get_tile_layers() -> Array[TileMapLayer]:
	var layers: Array[TileMapLayer] = []
	if tiles_map:
		layers.append(tiles_map)
	if tiles_map_2:
		layers.append(tiles_map_2)
	return layers

# Check if a cell has a specific flag in any layer
func _has_tile_with_flag(cell: Vector2i, flag_name: String, flag_value = true) -> bool:
	for layer in _get_tile_layers():
		if layer.get_cell_source_id(cell) == -1:
			continue
		var td: TileData = layer.get_cell_tile_data(cell)
		if td != null and td.get_custom_data(flag_name) == flag_value:
			return true
	return false

# Get the layer and tile data for a cell with a specific flag
func _get_tile_with_flag(cell: Vector2i, flag_name: String, flag_value = true) -> Dictionary:
	for layer in _get_tile_layers():
		if layer.get_cell_source_id(cell) == -1:
			continue
		var td: TileData = layer.get_cell_tile_data(cell)
		if td != null and td.get_custom_data(flag_name) == flag_value:
			return {"layer": layer, "tile_data": td}
	return {}

# Check if a collision is with any of our tile layers
func _is_collision_with_tile_layers(collision: KinematicCollision2D) -> TileMapLayer:
	var collider = collision.get_collider()
	for layer in _get_tile_layers():
		if collider == layer:
			return layer
	return null

func _ready() -> void:
	if tiles_map == null:
		var lvl := get_tree().current_scene
		tiles_map = lvl.find_child("Tiles", true, false) as TileMapLayer
	if tiles_map_2 == null:
		var lvl := get_tree().current_scene
		tiles_map_2 = lvl.find_child("Tiles 2", true, false) as TileMapLayer

	explosion_scene = preload("res://scenes/Explosion.tscn")

	add_to_group("liftable")
	add_to_group("player")

const TILE_SIZE := 200.0

var hp : int = 1

var dash_speed : float = 2000.0
var jump_height : float = 1.5 * TILE_SIZE
var double_jump_height : float = jump_height
var delay_between_jumps : float = 0.25
var time_since_last_jump : float = 0.0
var can_double_jump := true

# var speed : float = 3.0 * TILE_SIZE / sqrt(2 * jump_height / ProjectSettings.get_setting("physics/2d/default_gravity"))
var speed : float = TILE_SIZE * 4

var dash_duration : float = 0.15  # Продолжительность dash в секундах
var dash_time_left : float = 0.0
var is_dashing : bool = false
var can_dash := true
var is_on_the_wall := false  # Флаг состояния прилипания к стене
var wall_climb_direction := 0  # Направление стены (-1 слева, 1 справа)
var special_action_released := true
var special_action_released_delay := 0.2
var special_action_just_released_time_left := 0.0
var is_walking := false
var is_climbing := false

enum PlayerDirection {
	RIGHT,
	LEFT,
}

var player_direction : PlayerDirection = PlayerDirection.RIGHT

var _death_immunity_until_s: float = 0.0

var _emitted_move := false
var _dead: bool = false
var _frozen_on_death := false

# Переопределяемые наследниками флаги
var enabled_double_jumps := false
var enabled_dash := false
var enabled_wall_climb := false


func die() -> void:
	if _dead:
		return
	_dead = true
	_freeze_on_death(true)
	emit_signal("death_request", self)
	return

# Уровень вызовет это, если в меню нажали «Применить смерть»
func apply_death_effect() -> void:
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	explosion.type = explosion_type
	get_parent().add_child(explosion)
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
	if Input.is_action_just_pressed("suicide"):
		die()
		return

	var moving_down := Input.is_action_pressed("move_down")
	if Input.is_action_pressed("special_action"):
		special_action_just_released_time_left = special_action_released_delay
		special_action_released = false
	else:
		special_action_just_released_time_left -= delta

	if special_action_just_released_time_left <= 0.0:
		special_action_released = true
		special_action_just_released_time_left = 0.0


	# Animation handling
	var anim_player = $Sprite2D
	if is_on_floor():
		if input_direction == 0:
			anim_player.play("idle")
			# Stop walking sound when not moving
			if is_walking:
				audio_player.stop()
				is_walking = false
		else:
			anim_player.play("walk")
			# Start walking sound only if not already playing
			if not is_walking:
				audio_player.stream = load("res://sounds/PLAYER_WALK_LOOP.mp3")
				audio_player.play()
				is_walking = true
			
			anim_player.flip_h = input_direction < 0
	elif not is_on_the_wall:
		if is_walking:
			is_walking = false
		if input_direction == 0:
			if velocity.y < 0:
				anim_player.play("jump_up")
			else:
				anim_player.play("fall")
		else:
			anim_player.play("jump_right")
			anim_player.flip_h = input_direction < 0
	else:
		# Wall climb animation
		# Направление определять по player_direction
		anim_player.play("climb")
		
		# Play sound only when first starting to climb
		if not is_climbing:
			audio_player.stream = load("res://sounds/EARTH_GUY_HEAVY.mp3")
			audio_player.volume_db = -10  # Lower volume (negative values reduce volume)
			audio_player.play()
			is_climbing = true
		
		if is_walking:
			is_walking = false
	var velocity_desired = input_direction * speed

	var friction_k = 0.2 if is_on_floor() else 0.05

	# Wall climb логика
	if enabled_wall_climb and not is_on_floor() and not is_on_the_wall and Input.is_action_pressed("special_action"):
		# Проверяем столкновения со стенами
		# var wall_left = is_on_wall() and input_direction < 0
		# var wall_right = is_on_wall() and input_direction > 0

		# Если хотим чтобы персонаж прилипал к стене без нахятия клавиши движения
		var wall_left = is_on_wall() and player_direction == PlayerDirection.LEFT
		var wall_right = is_on_wall() and player_direction == PlayerDirection.RIGHT

		if wall_left or wall_right:
			# Начинаем wall climb
			is_on_the_wall = true
			wall_climb_direction = -1 if wall_left else 1
			velocity.x = 0  # Останавливаем горизонтальное движение
			velocity.y = 0  # Останавливаем вертикальное движение (прилипаем к стене)


	# Применяем обычное движение только если не в состоянии wall climb
	if not is_on_the_wall:
		velocity.x = lerp(velocity.x, velocity_desired, friction_k)
	
	## hard movement
	#if input_direction != 0 and !is_on_floor():
		#velocity.x = velocity_desired
		
	# Dash в воздухе
	# Обновляем состояние dash
	if is_dashing:
		dash_time_left -= delta
		if dash_time_left <= 0:
			is_dashing = false
			if velocity_desired != 0:
				velocity.x = velocity_desired
			else:
				velocity.x /= 3  # плавное замедление после dash
		else:
			# Во время dash обнуляем вертикальную скорость
			velocity.y = 0
	
	# Инициируем новый dash (только в воздухе и только один раз до приземления)
	if enabled_dash and not is_dashing and not is_on_floor() and can_dash:
		if Input.is_action_just_pressed("special_action"):
			# TODO: анимация дэша

			# Dash sound
			audio_player.stream = load("res://sounds/FIRE_GUY_DASH.mp3")
			audio_player.play()

			var dash_direction = 0
			if player_direction == PlayerDirection.RIGHT:
				dash_direction = 1
			elif player_direction == PlayerDirection.LEFT:
				dash_direction = -1

			if dash_direction != 0:
				velocity.x = dash_direction * dash_speed
				is_dashing = true
				dash_time_left = dash_duration
				can_dash = false

	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	time_since_last_jump += delta
	
	if is_on_floor():
		can_double_jump = true	

	# Прыжки

	if is_on_floor():
		can_double_jump = true

	if Input.is_action_pressed("jump"):
		if is_on_floor(): 	# Прыжок с пола
			velocity.y = -sqrt(2 * gravity * jump_height)
			time_since_last_jump = 0.0
			if not _emitted_move:
				_emitted_move = true
				emit_signal("moved_once")
		
			# Play sound
			audio_player.stream = load("res://sounds/PLAYER_JUMP.mp3")
			audio_player.play()

		elif is_on_the_wall:  # Прыжок со стены
			velocity.y = -sqrt(2 * gravity * jump_height)
			# Добавляем небольшой импульс в сторону от стены
			velocity.x = -wall_climb_direction * speed * 0.6
			time_since_last_jump = 0.0
			is_on_the_wall = false  # Отключаем wall climb
			is_climbing = false  # Reset climbing state
			wall_climb_direction = 0

			# Play sound
			audio_player.volume_db = 0  # Restore volume
			audio_player.stream = load("res://sounds/EARTH_GUY_LIGHT.mp3")
			audio_player.play()
		
	if Input.is_action_just_pressed("jump"):
		print("Jump pressed: ", can_double_jump, " time_since_last_jump=", time_since_last_jump, " 	delay_between_jumps=", delay_between_jumps)
		if enabled_double_jumps and can_double_jump and time_since_last_jump >= delay_between_jumps: 	# Прыжок в воздухе
			# TODO: анимация двойного прыжка
			# Double jump sound
			audio_player.stream = load("res://sounds/WIND_GUY_DOUBLE_JUMP.mp3")
			audio_player.play()

			velocity.y = -sqrt(2 * gravity * jump_height)
			time_since_last_jump = 0.0
			can_double_jump = false

	# Обработка действия "движения вниз"
	if moving_down:
		# Отпустить стену если игрок на ней висит
		if is_on_the_wall:
			velocity.y = 0
			is_on_the_wall = false
			is_climbing = false  # Reset climbing state
			wall_climb_direction = 0

	# Отпускаем стену при отпускании клавиши dash
	if is_on_the_wall and special_action_released:
		velocity.y = 0
		is_on_the_wall = false
		is_climbing = false  # Reset climbing state
		wall_climb_direction = 0

	# Применяем гравитацию только если не в состоянии dash или wall climb
	if not is_dashing and not is_on_the_wall:
		velocity.y += gravity * delta
		# Ускоренное падение вниз при зажатии вниз
		if moving_down and not is_on_floor():
			velocity.y += gravity * delta

	# Определяем направление движения
	if velocity.x > 0:
		player_direction = PlayerDirection.RIGHT
	elif velocity.x < 0:
		player_direction = PlayerDirection.LEFT
	
	move_and_slide()
	
	# Восстанавливаем возможность dash при приземлении
	if is_on_floor():
		can_dash = true
		# На земле отключаем wall climb
		is_on_the_wall = false
		is_climbing = false  # Reset climbing state
		wall_climb_direction = 0
	
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		# Check if collision is with any of our tile layers
		var tile_layer = _is_collision_with_tile_layers(col)
		if tile_layer != null:
			var cell := _cell_at_collision(tile_layer, col)
			if cell != null:
				var td := tile_layer.get_cell_tile_data(cell)
				if td != null:
					if td.get_custom_data(hazard_flag_name) == true:
						die()
						return
					elif td.get_custom_data(pushable_flag_name) == true:
						_push_block(cell, col.get_normal(), tile_layer)
					
func _cell_at_collision(layer: TileMapLayer, col: KinematicCollision2D) -> Vector2i:
	# берём точку чуть "внутрь" тайла (сдвигаемся на полпикселя по нормали)
	var world_p: Vector2 = col.get_position() - col.get_normal() * 0.5
	var local_p: Vector2 = layer.to_local(world_p)
	return layer.local_to_map(local_p)

func _push_block(cell: Vector2i, normal: Vector2, layer: TileMapLayer = null) -> void:
	# Use provided layer or default to tiles_map
	var target_layer = layer if layer != null else tiles_map
	if target_layer == null:
		return
		
	# вычисляем куда толкнуть
	var target_cell := cell + Vector2i(round(-normal.x), round(-normal.y))
	# проверяем что целевая пустая (проверяем во всех слоях)
	var target_occupied = false
	for check_layer in _get_tile_layers():
		if check_layer.get_cell_source_id(target_cell) != -1:
			target_occupied = true
			break
			
	if not target_occupied:
		var source_id := target_layer.get_cell_source_id(cell)
		var atlas_coords := target_layer.get_cell_atlas_coords(cell)
		# переносим тайл
		target_layer.set_cell(target_cell, source_id, atlas_coords)
		target_layer.set_cell(cell, -1)


func set_death_immunity(seconds: float = 0.5) -> void:
	_death_immunity_until_s = Time.get_unix_time_from_system() + seconds

func _can_die() -> bool:
	return Time.get_unix_time_from_system() >= _death_immunity_until_s

func get_player_type() -> PlayerType:
	return PlayerType.UNKNOWN
