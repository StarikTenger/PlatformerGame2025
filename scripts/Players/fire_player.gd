extends "res://scripts/Players/player.gd"

@export var explosion_radius: int = 4
var explosion_radius_px = explosion_radius * 100.0
const DESTRUCT_FLAG := "destruct_fire"

var tiles_layer: TileMapLayer



func _ready() -> void:
	super()
	# ищем Tiles в сцене уровня
	var lvl = get_tree().current_scene
	tiles_layer = lvl.find_child("Tiles", true, false) as TileMapLayer
	explosion_scene = preload("res://scenes/Explosion.tscn")

var explosion_scene : PackedScene
func _spawn_explosion(pos: Vector2) -> void:
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

	for cy in range(cell_center.y - ry, cell_center.y + ry + 1):
		for cx in range(cell_center.x - rx, cell_center.x + rx + 1):
			var cell: Vector2i = Vector2i(cx, cy)
			if tiles_layer.get_cell_source_id(cell) == -1:
				continue

			# центр клетки → мировые координаты
			var wc: Vector2 = tiles_layer.to_global(tiles_layer.map_to_local(cell) + tile_size * 0.5)
			if wc.distance_to(world_pos) > radius_px:
				continue

			var td: TileData = tiles_layer.get_cell_tile_data(cell)
			if td != null and td.get_custom_data(DESTRUCT_FLAG) == true:
				tiles_layer.erase_cell(cell)
				_spawn_explosion(wc)
