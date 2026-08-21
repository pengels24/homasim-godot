extends SceneTree

func _init():
	var save_mgr = load("res://autoload/SaveManager.gd").new()
	var state = save_mgr.load_game_state(1)
	
	if state == null:
		print("No savegame found!")
		quit()
		return
		
	print("Plots:")
	for plot in state.get("plots", []):
		print("- plot x:", plot.get("x"), " y:", plot.get("y"), " built:", plot.get("is_built"))
		for room in plot.get("rooms", []):
			print("  - room: ", room.get("room_type_id"), " at ", room.get("x_pos"), ",", room.get("y_pos"), " rot:", room.get("room_rotation"), " door:", room.get("door_rotation"))
	
	quit()
