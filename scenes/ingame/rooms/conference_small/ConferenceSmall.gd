extends "res://scenes/ingame/rooms/Room.gd"

# =============================================================================
static func get_definition() -> Dictionary:
	return {
		"id": "conference_small",
		"build_cost": 5000,
		"exp_reward": 500,
		"prefix": "P",
		"label": "KONF",
		"name": "roomdef.name.long.conference_small",
		"category": "business",
		"icon": "res://assets/icons/angelus2010/Rooms/ang-conference-small.aseprite",
		"nightly_price": 0,
		"locked": false,
		"max_guests": 12,
		"in_build_menu": true,
		"req_level": 5,
		"req_tech": "P1.2",
		"max_beds": 0,
		"is_poi": true,
		"is_guest_poi": true,
		"visit_income": 35, # Wird an Event-Tagen ignoriert
		"visit_exp": 30,
		"supply_cost_per_visit": 10,
		"adults_only": true,
		"required_role": "",
		"allowed_roles": [],
		"min_staff": 0,
		"max_staff": 0,
		"open_from": 480,  # 08:00
		"open_to": 1020,   # 17:00
		"valid_door_slots": ["L2"],
		"cleanliness_level": 100,
		"maintenance_level": 100,
		"is_service_requested": false,
		"allowed_guest_types": ["business", "digital_nomade", "luxus", "vip"]
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
					var actor_state = -1
					for a in get_tree().get_nodes_in_group("guest_actors"):
						if a.get("actor_id") == seat["occupied_by"]:
							actor_state = a.get("current_state")
							break
					if actor_state == 1: # State.WALKING
						continue
					guest_name = guest_node.get("_guest_member").name if guest_node.get("_guest_member") else "Gast"
			
			var status_text = "Nimmt teil"
			details.append({
				"left": guest_name,
				"right": status_text,
				"color": Color("#8b5cf6")
			})
			
	return details

# =============================================================================
# Speaker Logic
# =============================================================================
var current_speaker_id: String = ""

func claim_podium(guest_id: String) -> Vector2:
	if current_speaker_id == "":
		for s in _room_seats:
			if s["node"].name == "Chair12" and s["occupied_by"] == "":
				current_speaker_id = guest_id
				s["occupied_by"] = guest_id
				return s["node"].global_position
	return Vector2.INF

func leave_podium(guest_id: String) -> void:
	if current_speaker_id == guest_id:
		current_speaker_id = ""
		for s in _room_seats:
			if s["node"].name == "Chair12" and s["occupied_by"] == guest_id:
				s["occupied_by"] = ""

func claim_seat(guest_id: String) -> Vector2:
	# Only allow normal chairs 1-11
	for s in _room_seats:
		if s["occupied_by"] == "" and s["node"].name != "Chair12":
			s["occupied_by"] = guest_id
			return s["node"].global_position
	return Vector2.INF

func leave_seat(guest_id: String) -> void:
	for s in _room_seats:
		if s["occupied_by"] == guest_id and s["node"].name != "Chair12":
			s["occupied_by"] = ""
