extends ParallaxBackground

func _ready() -> void:
	var level_overview = get_parent().get_node("LevelOverview")
	if level_overview != null:
		# offset = level_overview.position
		print("ParallaxBackground offset set to ", offset)
	
func _process(delta: float) -> void:
	var window_size: Vector2 = get_parent().get_viewport_rect().size
	var zoom_factor = window_size.y / 720.0
	scale = Vector2.ONE * zoom_factor

	# var level_overview = get_parent().get_node("LevelOverview")
	# if level_overview != null:
	# 	offset = level_overview.position / zoom_factor
