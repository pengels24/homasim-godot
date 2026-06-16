extends "res://scenes/ingame/rooms/Room.gd"

static func get_definition() -> Dictionary:
	return {
		"name": "Familienzimmer",
		"category": "Zimmer",
		"size_x": 3,
		"size_y": 3,
		"icon": "res://assets/icons/HUDTop/house.svg",
		"build_cost": 5000,
		"req_level": 5,
		"req_tech": "Z1.2",
		"in_build_menu": true,
		"type": "room"
	}
