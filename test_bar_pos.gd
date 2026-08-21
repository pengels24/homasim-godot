extends SceneTree

func _init():
	var bar_scene = load("res://scenes/ingame/rooms/bar/Bar.tscn").instantiate()
	var bartender_pos = bar_scene.get_bartender_stand_pos()
	var waiter_pos = bar_scene.get_waiter_stand_pos()
	var dir = bartender_pos.direction_to(waiter_pos)
	print("Bartender pos: ", bartender_pos)
	print("Waiter pos: ", waiter_pos)
	print("Direction: ", dir)
	print("Angle: ", dir.angle())
	print("Rotation: ", dir.angle() + PI / 2.0)
	quit()
