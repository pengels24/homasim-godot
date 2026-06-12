extends "res://scenes/ingame/rooms/Room.gd"

# =============================================================================
static func get_definition() -> Dictionary:
	return {
		"id": "bar",
		"build_cost": 1800,
		"exp_reward": 180,
		"prefix": "B",
		"label": "BA",
		"name": "Bar",
		"category": "gastro",
		"icon": "res://assets/icons/rooms/wine.svg",
		"nightly_price": 0,
		"locked": false,
		"in_build_menu": true,
		"req_level": 5,
		"req_tech": "",
		"max_beds": 0,
		"open_from": 0,
		"open_to": 0,
		"valid_door_slots": ["R1"]
	}
