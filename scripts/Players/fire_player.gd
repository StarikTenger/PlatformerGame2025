extends PlayerBase
class_name FirePlayer

@export var explosion_radius: int = 4
var explosion_radius_px = explosion_radius * 100.0
const DESTRUCT_FLAG := "destruct_fire"

# Audio for explosion
var explosion_player := AudioStreamPlayer2D.new()

var tiles_layer: TileMapLayer



func _ready() -> void:
	super()
	enabled_dash = true

	# ищем Tiles в сцене уровня
	var lvl = get_tree().current_scene
	tiles_layer = lvl.find_child("Tiles", true, false) as TileMapLayer
	explosion_scene = preload("res://scenes/Explosion.tscn")

var explosion_scene : PackedScene
func _spawn_explosion(pos: Vector2) -> void:

	# Play sound
	explosion_player.stream = load("res://sounds/FIRE_GUY_DEATH.mp3")
	explosion_player.position = pos
	get_parent().add_child(explosion_player)
	explosion_player.play()

	var explosion = explosion_scene.instantiate()
	explosion.global_position = pos
	get_parent().add_child(explosion)

func _death_effect() -> void:
	_spawn_explosion(global_position)

	# Shake camera
	var cam = get_parent().camera_node
	if cam:
		cam.shake()

	if tiles_layer:
		_erase_destructibles_around(global_position, explosion_radius_px)
	await get_tree().process_frame

func death_hint() -> String:
	return "This character will explode magma blocks around him"

func _erase_destructibles_around(world_pos: Vector2, radius_px: float) -> void:
	var local_center: Vector2 = tiles_layer.to_local(world_pos)
	var cell_center: Vector2i = tiles_layer.local_to_map(local_center)

	var tile_size: Vector2 = tiles_layer.tile_set.tile_size
	var rx: int = int(ceil(radius_px / tile_size.x))
	var ry: int = int(ceil(radius_px / tile_size.y))

	var visited := {}
	var queue := []

	# Collect all cells within the radius
	for cy in range(cell_center.y - ry, cell_center.y + ry + 1):
		for cx in range(cell_center.x - rx, cell_center.x + rx + 1):
			var cell: Vector2i = Vector2i(cx, cy)
			if tiles_layer.get_cell_source_id(cell) == -1:
				continue
			var wc: Vector2 = tiles_layer.to_global(tiles_layer.map_to_local(cell) + tile_size * 0.5)
			if wc.distance_to(world_pos) > radius_px:
				continue
			var td: TileData = tiles_layer.get_cell_tile_data(cell)
			if td != null and td.get_custom_data(DESTRUCT_FLAG) == true:
				queue.append(cell)
				visited[cell] = true

	# BFS to explode all reachable destructible tiles
	while queue.size() > 0:
		var current: Vector2i = queue.pop_front()
		var wc: Vector2 = tiles_layer.to_global(tiles_layer.map_to_local(current) + tile_size * 0.5)
		tiles_layer.erase_cell(current)
		_spawn_explosion(wc)

		# Check 4 neighbors
		for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var neighbor = current + dir
			if visited.has(neighbor):
				continue
			if tiles_layer.get_cell_source_id(neighbor) == -1:
				continue
			var n_td: TileData = tiles_layer.get_cell_tile_data(neighbor)
			if n_td != null and n_td.get_custom_data(DESTRUCT_FLAG) == true:
				queue.append(neighbor)
				visited[neighbor] = true

func get_player_type() -> PlayerType:
	return PlayerType.FIRE
