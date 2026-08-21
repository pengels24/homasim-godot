extends Node2D

@onready var map = $"../.."

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not map or map._occ.is_empty() or not map._show_debug_grid:
		return

	# Der fehlende Offset: Das Grid startet nicht bei 0,0!
	var offset_px = map.WALK_W * map.TILE_PX

	# 1. Raster zeichnen
	for gy in map._occ_h:
		for gx in map._occ_w:
			var tile_pos = Vector2i(gx, gy)
			var rect = Rect2(gx * map.TILE_PX + offset_px, gy * map.TILE_PX + offset_px, map.TILE_PX, map.TILE_PX)
			if map.astar.is_point_solid(tile_pos):
				draw_rect(rect, Color(1, 0, 0, 0.4), true) # ROT
			else:
				draw_rect(rect, Color(0, 1, 0, 0.1), true) # GRÜN

	# 2. Pfad als gelbe Linie zeichnen
	for path in map._debug_paths:
		if path.size() > 1:
			for i in range(path.size() - 1):
				var p1 = Vector2((path[i].x + map.WALK_W + 0.5) * map.TILE_PX, (path[i].y + map.WALK_W + 0.5) * map.TILE_PX)
				var p2 = Vector2((path[i+1].x + map.WALK_W + 0.5) * map.TILE_PX, (path[i+1].y + map.WALK_W + 0.5) * map.TILE_PX)
				draw_line(p1, p2, Color(1, 1, 0, 0.7), 2.0)
