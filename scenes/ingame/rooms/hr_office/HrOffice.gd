extends "res://scenes/ingame/rooms/Room.gd"


# =============================================================================
static func get_definition() -> Dictionary:
	return {
		"id": "hr_office",
		"build_cost": 800,
		"exp_reward": 80,
		"prefix": "V",
		"label": "PB",
		"name": GameState.T("roomdef.name.long.hr_office", "Personalbüro"),
		"category": "management",
		"icon": "res://assets/icons/rooms/users.svg",
		"nightly_price": 0,
		"locked": false,
		"in_build_menu": true,
		"req_level": 2,
		"req_tech": "",
		"max_beds": 0,
		"open_from": 0,
		"open_to": 0,
		"valid_door_slots": ["L1", "T2"],
		"cleanliness_level": 100,
		"maintenance_level": 100,
		"is_service_requested": false
	}

