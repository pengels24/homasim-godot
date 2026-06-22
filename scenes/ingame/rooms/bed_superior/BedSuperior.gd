extends "res://scenes/ingame/rooms/Room.gd"

static func get_definition() -> Dictionary:
	return {
		"name": "Superior-Zimmer",
		"category": "Zimmer",
		"size_x": 3,
		"size_y": 3,
		"icon": "res://assets/icons/HUDTop/house.svg",
		"build_cost": 15000,
		"nightly_price": 400,
		"req_level": 3,
		"req_tech": "Z1.3",
		"in_build_menu": true,
		"type": "room"
	}
