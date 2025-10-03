extends Node2D

const CHAR_SCENES := {
	"Wind": preload("res://scenes/wind_player.tscn"),
	"Fire": preload("res://scenes/fire_player.tscn"),
}

const SPAWN_NAME := "Spawn" # Marker2D
const CAMERA_SCENE := preload("res://scenes/Camera.tscn")
const DEATH_MENU_SCENE := preload("res://scenes/DeathMenu.tscn")
const CHARACTER_MENU_SCENE := preload("res://scenes/CharacterMenu.tscn")

var roster: Array[PackedScene] = []
var current_idx : int = 0
var current_player : Node = null

var can_switch := true
var moved_once := false
var spawn_pos: Vector2

var camera_node: Node = null # камера сцены, чтобы переназначать target
var death_menu: Control = null
var death_layer: CanvasLayer = null

var character_menu : Control = null
var character_layer: CanvasLayer = null

var _pending_player : Node = null
var _pending_scene_idx : int = -1

var _prev_mouse_mode: int = Input.get_mouse_mode()

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
		
	character_layer = CanvasLayer.new()
	character_layer.layer = 101
	character_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(character_layer)
	
	character_menu = CHARACTER_MENU_SCENE.instantiate()
	character_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	character_menu.visible = true
	character_layer.add_child(character_menu)
	
	character_menu.start_pressed.connect(_start_game)
	
	# инстансим меню один раз
	death_layer = CanvasLayer.new()
	death_layer.layer = 100
	death_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(death_layer)

	death_menu = DEATH_MENU_SCENE.instantiate()
	death_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	death_menu.visible = false
	death_layer.add_child(death_menu)
	# сигналы меню
	death_menu.apply_pressed.connect(_death_apply_pressed)
	death_menu.skip_pressed.connect(_death_skip_pressed)
	death_menu.restart_pressed.connect(_death_restart_pressed)

func _start_game():
	character_menu.visible = false
	# Стартовый пул и первый спавн
	for slot in character_menu.chosen:
		var scene: PackedScene = CHAR_SCENES[slot]
		roster.append(scene)
	current_idx = 0
	_spawn_and_bind(roster[current_idx])

	# Инициализируем гравитацию (можно держать в Project Settings)
	ProjectSettings.set_setting("physics/2d/default_gravity", 2000)

	# Initialize HUD layer
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 50  # Above gameplay but below death menu (layer 100)
	add_child(hud_layer)
	
	var HUD_scene := preload("res://scenes/HUD.tscn")
	hud = HUD_scene.instantiate()
	hud_layer.add_child(hud)
	
	# Connect HUD signals
	roster_updated.connect(hud._on_roster_updated)
	
	# Send initial roster data
	_update_hud_roster()

func _unhandled_input(event):
	# переключение персонажа по Shift до первого движения
	if can_switch and event.is_action_pressed("switch_char"):
		print("test11")
		_switch_next()
	if event.is_action_pressed("debug_menu"): # например, привяжи F1
		_show_death_menu(true)

func _switch_next():
	if roster.is_empty():
		return
	var next := (roster_idx + 1) % roster.size()
	_replace_current_with(next)

func _replace_current_with(next_idx: int):
	if current_player:
		current_player.queue_free()
		current_player = null
	roster_idx = next_idx
	_spawn_and_bind(roster[roster_idx])
	# Update HUD
	roster_updated.emit(char_deck, roster_idx)

func _spawn_and_bind(packed: PackedScene):
	var p := packed.instantiate()
	add_child(p)
	p.global_position = spawn_pos
	current_player = p
	camera_node.player = current_player

	# подписка на сигналы игрока
	if p.has_signal("moved_once"):
		p.connect("moved_once", Callable(self, "_on_player_moved_once"))
	if p.has_signal("death_request"):
		p.connect("death_request", Callable(self, "_on_player_death_request"), CONNECT_ONE_SHOT)
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
	can_switch = false # фиксируем выбор до смерти

func _on_player_death_request(player: Node):
	print("[death_request] from: ", player.name)
	_pending_player = player
	
	var allow_apply: bool = roster.size() > 1
	var hint: String
	if allow_apply:
		# спросим у конкретного класса игрока его подсказку
		if "death_hint" in player:
			hint = player.death_hint()
		else:
			hint = "This character will leave an effect upon death"
	else:
		hint = "The characters are over"
	
	death_menu.set_context(allow_apply, hint)
	_show_death_menu(true)

func _death_apply_pressed():
	# применить эффект → убрать перса из ростера → финализировать смерть → респавн следующего
	_show_death_menu(false)
	if _pending_player:
		await _pending_player.apply_death_effect()
		_pending_player.finalize_death()
		_pending_player = null
		_pending_scene_idx = -1

	# Move to the next character in the roster
	roster_idx += 1
	if roster_idx >= roster.size():
		_restart_level()
		return

	roster_idx = min(roster_idx, roster.size() - 1)
	_spawn_and_bind(roster[roster_idx])
	# Update HUD after roster change
	_update_hud_roster()

func _death_skip_pressed():
	# НЕ применять эффект и НЕ вычеркивать из ростера — респавним того же персонажа
	_show_death_menu(false)
	if _pending_player:
		# «отменим смерть» у инстанса на всякий случай (снимает freeze, если ты захочешь его вернуть)
		if "cancel_death" in _pending_player:
			_pending_player.cancel_death()
		_pending_player.queue_free()
		_pending_player = null
		_pending_scene_idx = -1

	# респавним того же типа (индекс не меняем)
	_spawn_and_bind(roster[roster_idx])

func _death_restart_pressed():
	_show_death_menu(false)
	_restart_level()

func _show_death_menu(show: bool):
	get_tree().paused = show
	death_menu.visible = show
	if show:
		_prev_mouse_mode = Input.get_mouse_mode()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		(death_menu as Node).call_deferred("open")
	else:
		Input.set_mouse_mode(_prev_mouse_mode)
		(death_menu as Node).call_deferred("close")
		
func _show_character_menu(show: bool):
	get_tree().paused = show
	death_menu.visible = show
	if show:
		_prev_mouse_mode = Input.get_mouse_mode()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		(death_menu as Node).call_deferred("open")
	else:
		Input.set_mouse_mode(_prev_mouse_mode)
		(death_menu as Node).call_deferred("close")

func _restart_level():
	var ml := Engine.get_main_loop()
	if ml is SceneTree:
		(ml as SceneTree).reload_current_scene()

func _on_player_died():
	pass

func _update_hud_roster():
	# Pass char_deck and current index to HUD
	roster_updated.emit(char_deck, roster_idx)
	print("Emitted roster_updated with deck size ", char_deck.size(), " and current index ", roster_idx)

func _get_char_type_from_scene(scene: PackedScene) -> CharType:
	# Determine character type from scene path
	var path = scene.resource_path
	if "fire_player" in path:
		return CharType.FIRE
	elif "wind_player" in path:
		return CharType.WIND
	elif "earth_player" in path:
		return CharType.EARTH
	elif "water_player" in path:
		return CharType.WATER
	else:
		return CharType.FIRE  # default fallback
