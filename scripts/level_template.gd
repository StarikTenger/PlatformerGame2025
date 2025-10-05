extends Node2D

const CHAR_SCENES := {
	"Wind": preload("res://scenes/Players/wind_player.tscn"),
	"Fire": preload("res://scenes/Players/fire_player.tscn"),
	"Earth": preload("res://scenes/Players/earth_player.tscn"),
}

const SPAWN_NAME := "Spawn"               # Marker2D
const CAMERA_SCENE := preload("res://scenes/Camera.tscn")
const DEATH_MENU_SCENE := preload("res://scenes/UI/DeathMenu.tscn")
const WIN_MENU_SCENE := preload("res://scenes/UI/WinMenu.tscn")
const CHARACTER_MENU_SCENE := preload("res://scenes/UI/CharacterMenu.tscn")
const HUD_SCENE := preload("res://scenes/UI/HUD.tscn")

var character_deck: Array[String] = []
var character_deck_alive : Array[bool] = []
var character_deck_idx : int = 0
var current_player : Node = null
var player_alive : bool = false

# Signal for HUD communication
signal deck_update(char_deck: Array[String], alive: Array[bool], idx: int)


var can_switch := true
var moved_once := false
var spawn_pos : Vector2

var camera_node : MainCamera = null   # камера сцены, чтобы переназначать target
var death_menu : Control = null
var death_layer: CanvasLayer = null

var hud : Control = null
var hud_layer: CanvasLayer = null

var win_menu : Control = null
var win_layer: CanvasLayer = null

var character_menu : Control = null
var character_layer: CanvasLayer = null

var _pending_player : PlayerBase = null
var _pending_scene_idx : int = -1

var _prev_mouse_mode: int = Input.get_mouse_mode()

######################################################
# level overview

var level_overview_position: Vector2 = Vector2.ZERO
var level_overview_zoom: float = 0

func _ready():
	var start_roster = $StartRoster
	
	if start_roster and not SaveState.get_restarted():
		SaveState.save_chosen(start_roster.get_roster())
	
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
		
	#### Instantiate Character Menu ####

	character_layer = CanvasLayer.new()
	character_layer.layer = 101
	character_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(character_layer)
	
	character_menu = CHARACTER_MENU_SCENE.instantiate()
	character_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	character_menu.visible = true
	character_layer.add_child(character_menu)
	
	character_menu.start_pressed.connect(_start_game)
	character_menu.load_chosen(SaveState.get_chosen())

	#### Instantiate Death Menu (no longer in use!) ####

	death_layer = CanvasLayer.new()
	death_layer.layer = 100
	death_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(death_layer)

	death_menu = DEATH_MENU_SCENE.instantiate()
	death_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	death_menu.visible = false
	death_layer.add_child(death_menu)

	# signals
	death_menu.apply_pressed.connect(_continue_from_death_menu)
	death_menu.skip_pressed.connect(_death_restart_pressed)
	death_menu.restart_pressed.connect(_death_main_menu_pressed)

	##### Instantiate Win Menu ####

	win_layer = CanvasLayer.new()
	win_layer.layer = 102
	win_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(win_layer)

	win_menu = WIN_MENU_SCENE.instantiate()
	win_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	win_menu.visible = false
	win_layer.add_child(win_menu)

	win_menu.next_pressed.connect(_next_level)
	win_menu.restart_pressed.connect(_win_restart_pressed)
	win_menu.menu_pressed.connect(_win_menu_pressed)

	##### Instantiate HUD overlay ####
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 50
	hud_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud_layer)

	hud = HUD_SCENE.instantiate()
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	hud.visible = true
	hud_layer.add_child(hud)

	deck_update.connect(hud._on_deck_update)

	
	


	var level_overview_position_node: Variant = get_node_or_null("LevelOverview")
	if level_overview_position_node != null:
		if level_overview_position_node is LevelOverviewNode:
			level_overview_position = level_overview_position_node.global_position
			level_overview_zoom = level_overview_position_node.zoom


func _start_game():
	var chosen : Array[String]
	SaveState.save_chosen(character_menu.get_chosen())
	character_menu.visible = false
	# Стартовый пул и первый спавн
	character_deck.clear()
	character_deck_alive.clear()
	for slot in character_menu.chosen:
		character_deck.append(slot)
		character_deck_alive.append(true)
	character_deck_idx = 0
	_spawn_and_bind(character_deck[character_deck_idx])

	# Инициализируем гравитацию (можно держать в Project Settings)
	ProjectSettings.set_setting("physics/2d/default_gravity", 2000)

	deck_update.emit(character_deck, character_deck_alive, character_deck_idx)

func _unhandled_input(event):
	# переключение персонажа по Shift до первого движения
	if can_switch and event.is_action_pressed("switch_char"):
		print("test11")
		_switch_next()
	if not character_menu.visible and not get_tree().paused and Input.is_action_just_pressed("esc_menu"):
		print("Pause menu requested")
		death_menu.set_context(true, "Game on pause")
		_show_death_menu(true)
	if event.is_action_pressed("level_overview"):
		if level_overview_zoom != 0 and player_alive:
			camera_node.set_target_state(level_overview_position, level_overview_zoom, 0.3, 0.3)
	elif event.is_action_released("level_overview"):
		if player_alive:
			camera_node.reset_target_state()

func is_deck_empty() -> bool:
	for alive in character_deck_alive:
		if alive:
			return false
	return true

func characters_on_deck() -> int:
	var count := 0
	for alive in character_deck_alive:
		if alive:
			count += 1
	return count

func _switch_next():
	if is_deck_empty():
		return
	var next := character_deck_idx
	for i in range(character_deck.size()):
		next = (next + 1) % character_deck.size()
		if character_deck_alive[next]:
			break	
	_replace_current_with(next)

	deck_update.emit(character_deck, character_deck_alive, character_deck_idx)

func _replace_current_with(next_idx: int):
	if current_player:
		current_player.queue_free()
		current_player = null
	character_deck_idx = next_idx
	_spawn_and_bind(character_deck[character_deck_idx])

func _spawn_and_bind(char_type: String):
	var packed : PackedScene = CHAR_SCENES[char_type]
	var p := packed.instantiate()
	add_child(p)
	p.global_position = spawn_pos
	current_player = p
	camera_node.bind_player(current_player)
	camera_node.reset_target_state()
	player_alive = true
	
	# подписка на сигналы игрока
	if p.has_signal("moved_once"):
		p.connect("moved_once", Callable(self, "_on_player_moved_once"))
	if p.has_signal("death_request"):
		p.connect("death_request", Callable(self, "_on_player_death_request"), CONNECT_ONE_SHOT)
	if p.has_signal("died"):
		p.connect("died", Callable(self, "_on_player_died"))

	# новый заход — снова можно выбирать, пока не двинулся
	can_switch = true
	moved_once = false

func _on_player_moved_once():
	if moved_once: return
	moved_once = true
	can_switch = false  # фиксируем выбор до смерти

func _on_player_death_request(player: PlayerBase):
	print("[death_request] from: ", player.name)
	_pending_player = player
	_pending_scene_idx = character_deck_idx
	
	var allow_apply: bool = characters_on_deck() > 1
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

	player_alive = false
	if camera_node:
		camera_node.hard_reset_target_state()
		camera_node.unbind_player()

	#_show_death_menu(true)
	_death_apply_pressed()


func _death_apply_pressed():
	
	# применить эффект → убрать перса из ростера → финализировать смерть → респавн следующего
	_show_death_menu(false)
	if _pending_player:
		var death_pos: Vector2 = _pending_player.global_position
		
		await _pending_player.apply_death_effect()
		_pending_player.finalize_death()
		character_deck_alive[_pending_scene_idx] = false
		
		print("CAMERA NODE: ", camera_node)
		if camera_node:
			# если скрипт огненного — включаем тряску
			# camera_node.hard_reset_target_state()
			camera_node.set_target_state(death_pos, 1, 0.7, 0.7)
			if _pending_player.get_player_type() == PlayerBase.PlayerType.FIRE:
				camera_node.shake(1)
			await get_tree().create_timer(1.5).timeout

		_pending_player = null
		_pending_scene_idx = -1

	if is_deck_empty():
		#_restart_level()
		_show_death_menu(true)
		return

	_switch_next()
	print("Apply death", character_deck_alive)

func _continue_from_death_menu():
	_show_death_menu(false)

func _death_skip_pressed():
	# НЕ применять эффект и НЕ вычеркивать из ростера — респавним того же персонажа
	_show_death_menu(false)
	if _pending_player:
		# «отменим смерть» у инстанса на всякий случай (снимает freeze, если ты захочешь его вернуть)
		_pending_player.cancel_death()
		_pending_player.queue_free()
		_pending_player = null
		_pending_scene_idx = -1

	# респавним того же типа (индекс не меняем)
	_spawn_and_bind(character_deck[character_deck_idx])

func _death_restart_pressed():
	_show_death_menu(false)
	_restart_level()

func _death_main_menu_pressed():
	SaveState.set_restarted(false)
	_show_death_menu(false)
	get_tree().change_scene_to_file("res://scenes/UI/LevelManager.tscn")

func _win_restart_pressed():
	_show_win_menu(false)
	_restart_level()

func _win_menu_pressed():
	_show_win_menu(false)
	get_tree().change_scene_to_file("res://scenes/UI/LevelManager.tscn")

func _show_death_menu(show: bool):
	if show:
		death_menu.open()
	else:
		death_menu.close_menu()

func _show_win_menu(show: bool):
	if show:
		win_menu.open()
	else:
		win_menu.close_menu()

func _next_level():
	_show_win_menu(false)
	LevelManager.next_level()

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
	SaveState.set_restarted(true)
	var ml := Engine.get_main_loop()
	if ml is SceneTree:
		(ml as SceneTree).reload_current_scene()
