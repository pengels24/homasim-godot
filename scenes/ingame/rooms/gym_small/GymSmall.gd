extends "res://scenes/ingame/rooms/Room.gd"

# =============================================================================
static func get_definition() -> Dictionary:
	return {
		"id": "gym_small",
		"build_cost": 3800,
		"exp_reward": 380,
		"prefix": "W",
		"label": "GYM",
		"name": "roomdef.name.long.gym_small",
		"category": "wellness",
		"icon": "res://assets/icons/angelus2010/Rooms/ang-gym-small.aseprite",
		"nightly_price": 0,
		"locked": false,
		"in_build_menu": true,
		"req_level": 4,
		"req_tech": "W1.4",
		"max_beds": 0,
		"is_poi": true,
		"is_guest_poi": true,
		"visit_income": 25,
		"visit_exp": 10,
		"supply_cost_per_visit": 2,
		"adults_only": true,
		"required_role": "",
		"allowed_roles": [],
		"min_staff": 0,
		"max_staff": 0,
		"open_from": 360, # 06:00
		"open_to": 1320,  # 22:00
		"valid_door_slots": ["L3"],
		"cleanliness_level": 100,
		"maintenance_level": 100,
		"is_service_requested": false
	}

# =============================================================================
# Visuals (3x2 / 2x3)
# =============================================================================
const LS_FLOOR_W := 44.0
const LS_FLOOR_H := 28.0
const PT_FLOOR_W := 28.0
const PT_FLOOR_H := 44.0
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

	if room_rotation % 2 == 0:
		var f := $Landscape/Interior/Floor as Sprite2D
		if f:
			f.scale    = Vector2((LS_FLOOR_W + ext_l + ext_r) / FLOOR_TEX_W, LS_FLOOR_H + ext_t + ext_b)
			f.position = Vector2(24.0 + (ext_r - ext_l) * 0.5, 16.0 + (ext_b - ext_t) * 0.5)
	else:
		var f := $Portrait/Interior/Floor as Sprite2D
		if f:
			f.scale    = Vector2((PT_FLOOR_W + ext_l + ext_r) / FLOOR_TEX_W, PT_FLOOR_H + ext_t + ext_b)
			f.position = Vector2(16.0 + (ext_r - ext_l) * 0.5, 24.0 + (ext_b - ext_t) * 0.5)

func _apply_visuals() -> void:
	if not is_node_ready():
		return

	var is_portrait := room_rotation % 2 == 1
	var ls = get_node_or_null("Landscape")
	var pt = get_node_or_null("Portrait")
	
	if ls: ls.visible = not is_portrait
	if pt: pt.visible  = is_portrait

	if is_portrait and pt:
		var interior := pt.get_node_or_null("Interior") as Node2D
		if interior:
			interior.position = Vector2(32, 48) if room_rotation == 3 else Vector2(0, 0)
			interior.rotation = PI if room_rotation == 3 else 0.0
	elif ls:
		var interior := ls.get_node_or_null("Interior") as Node2D
		if interior:
			interior.position = Vector2(48, 32) if room_rotation == 2 else Vector2(0, 0)
			interior.rotation = PI if room_rotation == 2 else 0.0

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
			
			var status_text = "Trainiert"
			details.append({
				"label": guest_name,
				"value": status_text,
				"color": Color("#f43f5e")
			})
			
	return details

