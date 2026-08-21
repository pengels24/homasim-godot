extends SceneTree

func _init():
	var bar = load("res://scenes/ingame/rooms/bar/Bar.tscn").instantiate()
	# wir rufen _build_local_nav manuell auf
	bar._build_local_nav()
	var astar = bar._local_astar
	print("AStar Punkte in Spalte X=6:")
	var cells_x = 32 / 4 # 8
	var cells_y = 32 / 4 # 8
	var has_6 = false
	for y in cells_y:
		for x in cells_x:
			var id = y * cells_x + x
			if astar.has_point(id):
				var p = astar.get_point_position(id)
				if p.x == 6:
					print("Point ", id, " at ", p)
					has_6 = true
	if not has_6:
		print("Keine Punkte bei X=6 gefunden!")
	quit()
