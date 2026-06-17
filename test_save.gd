@tool
extends SceneTree

func _init():
	var dir = DirAccess.open("user://saves")
	for file_name in dir.get_files():
		if file_name.begins_with("hotel_23_") and file_name.ends_with(".sav"):
			var file = FileAccess.open("user://saves/" + file_name, FileAccess.READ)
			var snap = file.get_var()
			if snap and snap.has("plots"):
				var plots = snap.get("plots", [])
				var total_rooms = 0
				var out_str = ""
				for p in plots:
					var rooms = p.get("rooms", [])
					if rooms.size() > 0:
						total_rooms += rooms.size()
						out_str += "P(" + str(p["x"]) + "," + str(p["y"]) + ")=" + str(rooms.size()) + " "
				print(file_name, " -> Total Rooms: ", total_rooms, " | ", out_str)
	quit()
