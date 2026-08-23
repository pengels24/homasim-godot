@tool
extends SceneTree

func _init():
	var astar = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, 80, 80)
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	
	# Mark the Bar room as solid (x=1 to 4, y=35 to 38)
	for y in range(35, 39):
		for x in range(1, 5):
			astar.set_point_solid(Vector2i(x, y), true)
			
	# Mark the exit of the room as non-solid (0, 35) and (0, 38) are in the corridor, so they are already non-solid.
	# Let's test the path
	var path = astar.get_id_path(Vector2i(0, 38), Vector2i(0, 35))
	print("Path from (0, 38) to (0, 35): ", path)
	quit()
