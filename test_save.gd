extends SceneTree

func _init():
	var cfg = ConfigFile.new()
	var err = cfg.load("C:/Users/angel/AppData/Roaming/Godot/app_userdata/HOMASIM/hotels/hotel_43.cfg")
	if err == OK:
		print("Loaded hotel_43.cfg successfully.")
		var plots = cfg.get_value("hotel", "plots", [])
		for p in plots:
			var rooms = p.get("rooms", [])
			for r in rooms:
				var traits = r.get("acquired_traits", "MISSING_KEY")
				if "conference" in r.get("room_type_id", "") or "superior" in r.get("room_type_id", ""):
					print("ROOM: ", r.get("room_type_id"), " traits: ", traits, " TYPEOF: ", typeof(traits))
	else:
		print("Failed to load hotel_43.cfg")
	
	quit()

