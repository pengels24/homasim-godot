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
		"req_tech": "G1.1",
		"max_beds": 0,
		"is_poi": true,
		"open_from": 720,
		"open_to": 1410,
		"valid_door_slots": ["R1"],
		"cleanliness_level": 100,
		"maintenance_level": 100,
		"is_service_requested": false
	}
