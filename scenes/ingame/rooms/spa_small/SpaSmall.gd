extends "res://scenes/ingame/rooms/Room.gd"

# =============================================================================
static func get_definition() -> Dictionary:
	return {
		"id": "spa_small",
		"build_cost": 4500,
		"exp_reward": 450,
		"prefix": "W",
		"label": "SPA",
		"name": "roomdef.name.long.spa_small",
		"category": "wellness",
		"icon": "res://assets/icons/angelus2010/Rooms/ang-spa-small.aseprite",
		"nightly_price": 0,
		"locked": false,
		"in_build_menu": true,
		"req_level": 4,
		"req_tech": "W1.3",
		"max_beds": 0,
		"is_poi": true,
		"is_guest_poi": true,
		"visit_income": 45,
		"visit_exp": 20,
		"supply_cost_per_visit": 8,
		"adults_only": true,
		"required_role": "wellness_counselor",
		"allowed_roles": ["wellness_counselor"],
		"min_staff": 1,
		"max_staff": 1,
		"open_from": 540, # 09:00
		"open_to": 1200,  # 20:00
		"valid_door_slots": ["L1", "L2", "L3", "R1", "R2", "R3", "T1", "T2", "T3", "B1", "B2", "B3"],
		"cleanliness_level": 100,
		"maintenance_level": 100,
		"is_service_requested": false
	}

# =============================================================================
# Visuals (3x3)
# =============================================================================
const FLOOR_W := 44.0
const FLOOR_H := 44.0
const FLOOR_TEX_W := 256.0

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
		f.scale    = Vector2((FLOOR_W + ext_l + ext_r) / FLOOR_TEX_W, FLOOR_H + ext_t + ext_b)
		f.position = Vector2(24.0 + (ext_r - ext_l) * 0.5, 24.0 + (ext_b - ext_t) * 0.5)

func _apply_visuals() -> void:
	if not is_node_ready():
		return
		
	var interior := $Interior as Node2D
	if interior:
		if room_rotation == 1:
			interior.position = Vector2(48, 0)
			interior.rotation = PI / 2.0
		elif room_rotation == 2:
			interior.position = Vector2(48, 48)
			interior.rotation = PI
		elif room_rotation == 3:
			interior.position = Vector2(0, 48)
			interior.rotation = -PI / 2.0
		else:
			interior.position = Vector2(0, 0)
			interior.rotation = 0.0
	
	super._apply_visuals()

# =============================================================================
# LIVE-MONITOR
# =============================================================================
func get_live_details() -> Array[Dictionary]:
	var details: Array[Dictionary] = []
	
	for seat in _room_seats:
		if seat["occupied_by"] != "":
			var guest_name = "Gast"
			var gm = get_tree().get_first_node_in_group("guest_manager")
			if gm:
				var guest_node = gm.get_guest(seat["occupied_by"])
				if guest_node:
					guest_name = guest_node.name
			
			var status_text = "Entspannt sich"
			details.append({
				"label": guest_name,
				"value": status_text,
				"color": Color("#3b82f6")
			})
			
	return details

