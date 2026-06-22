extends "res://scenes/ingame/rooms/Room.gd"

const FLOOR_BASE_SIZE := 44.0
const FLOOR_TEX_W := 256.0

static func get_definition() -> Dictionary:
	return {
		"id": "bed_family",
		"build_cost": 6000,
		"exp_reward": 150,
		"prefix": "Z",
		"label": "FZ",
		"name": "Familienzimmer",
		"category": "zimmer",
		"icon": "res://assets/icons/rooms/van.svg",
		"nightly_price": 200,
		"locked": false,
		"in_build_menu": true,
		"type": "room",
		"req_level": 3,
		"req_tech": "Z1.2",
		"max_beds": 5,
		"open_from": 0,
		"open_to": 0,
		"valid_door_slots": ["L3"],
		"cleanliness_level": 100,
		"maintenance_level": 100,
		"is_service_requested": false
	}

func set_floor_neighbors(top: bool, right: bool, bottom: bool, left: bool) -> void:
	var w: Array[bool] = [top, right, bottom, left]
	var l_top    := w[(0 + room_rotation) % 4]
	var l_right  := w[(1 + room_rotation) % 4]
	var l_bottom := w[(2 + room_rotation) % 4]
	var l_left   := w[(3 + room_rotation) % 4]
	var ext_l := 1.0 if l_left  else 0.0
	var ext_r := 1.0 if l_right else 0.0
	var ext_t := 1.0 if l_top   else 0.0
	var ext_b := 1.0 if l_bottom else 0.0

	var f := $Interior/Floor as Sprite2D
	if f:
		f.scale    = Vector2((FLOOR_BASE_SIZE + ext_l + ext_r) / FLOOR_TEX_W, FLOOR_BASE_SIZE + ext_t + ext_b)
		f.position = Vector2(24.0 + (ext_r - ext_l) * 0.5, 24.0 + (ext_b - ext_t) * 0.5)
