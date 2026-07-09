extends "res://scenes/ingame/rooms/Room.gd"

# =============================================================================
static func get_definition() -> Dictionary:
	return {
		"id": "bar",
		"build_cost": 1800,
		"exp_reward": 180,
		"prefix": "B",
		"label": "BA",
		"name": "roomdef.name.long.bar",
		"category": "gastro",
		"icon": "res://assets/icons/angelus2010/Rooms/ang-bar.aseprite",
		"nightly_price": 0,
		"locked": false,
		"in_build_menu": true,
		"req_level": 3,
		"req_tech": "G1.1",
		"max_beds": 0,
		"is_poi": true,
		"visit_income": 15,
		"supply_cost_per_visit": 5,
		"adults_only": true,
		"required_role": "bartender",
		"min_staff": 1,
		"max_staff": 2,
		"open_from": 720,
		"open_to": 1410,
		"valid_door_slots": ["R1"],
		"cleanliness_level": 100,
		"maintenance_level": 100,
		"is_service_requested": false
	}

