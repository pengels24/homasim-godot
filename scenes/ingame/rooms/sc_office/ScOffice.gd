extends "res://scenes/ingame/rooms/Room.gd"


# =============================================================================
static func get_definition() -> Dictionary:
	return {
		"id": "sc_office",
		"build_cost": 1200,
		"exp_reward": 120,
		"prefix": "V",
		"label": "FB",
		"name": "roomdef.name.long.sc_office",
		"category": "management",
		"icon": "res://assets/icons/rooms/flask-conical.svg",
		"nightly_price": 0,
		"locked": false,
		"in_build_menu": true,
		"req_level": 3,
		"req_tech": "",
		"max_beds": 0,
		"open_from": 0,
		"open_to": 0,
		"valid_door_slots": ["T2", "B2"],
		"cleanliness_level": 100,
		"maintenance_level": 100,
		"is_service_requested": false
	}

