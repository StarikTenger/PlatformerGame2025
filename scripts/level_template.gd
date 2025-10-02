extends Node2D

const CHAR_SCENES := [
	preload("res://scenes/wind_player.tscn"),
	preload("res://scenes/fire_player.tscn"),
]

const SPAWN_NAME := "Spawn"               # Marker2D
const CAMERA_SCENE := preload("res://scenes/Camera.tscn")

var roster : Array = []
var current_idx : int = 0
var current_player : Node = null

var can_switch := true
var moved_once := false
var spawn_pos : Vector2

var camera_node : Node = null   # камера сцены, чтобы переназначать target

func _ready():
	# Инициализация Spawn
	var spawn := get_node_or_null(SPAWN_NAME)
	if spawn == null:
		# создадим, чтобы не падать
		spawn = Marker2D.new()
		spawn.name = SPAWN_NAME
		add_child(spawn)
		spawn.position = Vector2.ZERO
		push_warning("Spawn не найден, создан автоматически в (0,0)")
	spawn_pos = (spawn as Marker2D).global_position

	# Камера (одна на весь уровень)
	if CAMERA_SCENE:
		camera_node = CAMERA_SCENE.instantiate()
		add_child(camera_node)

	# Стартовый пул и первый спавн
	roster = CHAR_SCENES.duplicate() as Array[PackedScene]
	current_idx = 0
	_spawn_and_bind(roster[current_idx])

	# Инициализируем гравитацию (можно держать в Project Settings)
	ProjectSettings.set_setting("physics/2d/default_gravity", 2000)

func _unhandled_input(event):
	# переключение персонажа по Shift до первого движения
	if can_switch and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SHIFT:
			print("test11")
			_switch_next()

func _switch_next():
	if roster.is_empty():
		return
	var next := (current_idx + 1) % roster.size()
	_replace_current_with(next)

func _replace_current_with(next_idx: int):
	if current_player:
		current_player.queue_free()
		current_player = null
	current_idx = next_idx
	_spawn_and_bind(roster[current_idx])

func _spawn_and_bind(packed: PackedScene):
	var p := packed.instantiate()
	add_child(p)
	p.global_position = spawn_pos
	current_player = p
	camera_node.player = current_player

	# подписка на сигналы игрока
	if p.has_signal("moved_once"):
		p.connect("moved_once", Callable(self, "_on_player_moved_once"))
	if p.has_signal("died"):
		p.connect("died", Callable(self, "_on_player_died"))

	# привязываем камеру к текущему игроку (если у камеры есть поле player)
	if camera_node and "player" in camera_node:
		camera_node.player = current_player

	# новый заход — снова можно выбирать, пока не двинулся
	can_switch = true
	moved_once = false

func _on_player_moved_once():
	if moved_once: return
	moved_once = true
	can_switch = false  # фиксируем выбор до смерти

func _on_player_died():
	print(roster)
	# потратить текущего
	if roster.size() > 0:
		roster.remove_at(current_idx)

	if current_player:
		current_player.queue_free()
		current_player = null

	if roster.is_empty():
		print("lost")
		# все умерли — полный рестарт уровня
		var ml := Engine.get_main_loop()
		if ml is SceneTree:
			(ml as SceneTree).reload_current_scene()
		return

	# остались живые — респавн на старте и снова можно выбирать
	current_idx = (current_idx + 1) % roster.size()
	_spawn_and_bind(roster[current_idx])
