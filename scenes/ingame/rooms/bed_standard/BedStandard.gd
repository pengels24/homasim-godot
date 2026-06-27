extends "res://scenes/ingame/rooms/Room.gd"

const FLOOR_BASE_SIZE := 28.0
const FLOOR_TEX_W := 256.0

# =============================================================================


# =============================================================================
static func get_definition() -> Dictionary:
	return {
		"id": "bed_standard",
		"build_cost": 2000,
		"exp_reward": 50,
		"prefix": "Z",
		"label": "EZ",
		"name": "roomdef.name.long.bed_standard",
		"category": "zimmer",
		"icon": "res://assets/icons/rooms/bed-single.svg",
		"nightly_price": 80,
		"locked": false,
		"in_build_menu": true,
		"req_level": 0,
		"req_tech": "",
		"max_beds": 1,
		"open_from": 0,
		"open_to": 0,
		"type": "room",
		"valid_door_slots": ["L1", "L2", "T1"],
		"cleanliness_level": 100,
		"maintenance_level": 100,
		"is_service_requested": false
	}


# =============================================================================
# Rotiert die Welt-Nachbar-Flags in den lokalen Raum des Interior-Nodes.
# Interior dreht sich um room_rotation * 90° CW → Flags entsprechend verschieben.
func set_floor_neighbors(top: bool, right: bool, bottom: bool, left: bool) -> void:
	var w: Array[bool] = [top, right, bottom, left]  # 0=T 1=R 2=B 3=L
	var l_top := w[(0 + room_rotation) % 4]
	var l_right := w[(1 + room_rotation) % 4]
	var l_bottom := w[(2 + room_rotation) % 4]
	var l_left := w[(3 + room_rotation) % 4]
	var ext_l := 1.0 if l_left else 0.0
	var ext_r := 1.0 if l_right else 0.0
	var ext_t := 1.0 if l_top else 0.0
	var ext_b := 1.0 if l_bottom else 0.0
	var floor_node := $Interior/Floor as Sprite2D
	floor_node.scale = Vector2((FLOOR_BASE_SIZE + ext_l + ext_r) / FLOOR_TEX_W,FLOOR_BASE_SIZE + ext_t + ext_b)
	floor_node.position = Vector2(16.0 + (ext_r - ext_l) * 0.5, 16.0 + (ext_b - ext_t) * 0.5)

