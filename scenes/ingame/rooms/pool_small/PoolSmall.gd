extends "res://scenes/ingame/rooms/Room.gd"

# =============================================================================
static func get_definition() -> Dictionary:
	var open_f = 480 # 08:00
	var open_t = 1200 # 20:00
	
	# Check for extended hours tech
	var tm = Engine.get_main_loop().root.get_node_or_null("TechtreeManager")
	if tm and tm.is_tech_unlocked("W1.5"): # Placeholder Tech ID für erweiterte Öffnungszeiten
		open_f = 360 # 06:00
		open_t = 1320 # 22:00

	return {
		"id": "pool_small",
		"build_cost": 5000,
		"exp_reward": 500,
		"prefix": "W",
		"label": "POOL",
		"name": "roomdef.name.long.pool_small",
		"category": "wellness",
		"icon": "res://assets/icons/angelus2010/Rooms/ang-pool-small.aseprite",
		"nightly_price": 0,
		"locked": false,
		"max_guests": 8,
		"in_build_menu": true,
		"req_level": 4,
		"req_tech": "W1.2",
		"max_beds": 0,
		"is_poi": true,
		"is_guest_poi": true,
		"visit_income": 20,
		"visit_exp": 15,
		"supply_cost_per_visit": 5,
		"adults_only": false,
		"required_role": "lifeguard",
		"allowed_roles": ["lifeguard"],
		"min_staff": 1,
		"max_staff": 1,
		"need_restoration": {"fun": 80, "energy": -10},
		"open_from": open_f,
		"open_to": open_t,
		"valid_door_slots": ["L2"],
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

func get_lifeguard_stand_pos() -> Vector2:
	# ChairSpecial-Node verwenden wenn vorhanden
	var chair = get_node_or_null("Interior/Furniture/Chairs/ChairSpecial")
	if is_instance_valid(chair):
		return chair.global_position
	return global_position + Vector2(24.0, 16.0)

func get_lifeguard_look_dir() -> float:
	var chair = get_node_or_null("Interior/Furniture/Chairs/ChairSpecial")
	if is_instance_valid(chair):
		return chair.global_rotation
	return PI / 2.0

func claim_lifeguard_chair(staff_id: String) -> bool:
	for s in _room_seats_staff_only:
		if s["occupied_by"] == "":
			s["occupied_by"] = staff_id
			return true
	return false

func leave_lifeguard_chair(staff_id: String) -> void:
	for s in _room_seats_staff_only:
		if s["occupied_by"] == staff_id:
			s["occupied_by"] = ""

func is_lifeguard_chair_free(staff_id: String = "") -> bool:
	for s in _room_seats_staff_only:
		if s["occupied_by"] == "" or (staff_id != "" and s["occupied_by"] == staff_id):
			return true
	return false

# =============================================================================

func claim_seat(guest_id: String) -> Vector2:
	for s in _room_seats:
		if s["occupied_by"] == guest_id:
			return s["node"].global_position
			
	var free_seats = []
	for s in _room_seats:
		if s["occupied_by"] == "":
			free_seats.append(s)
			
	if free_seats.size() > 0:
		var s = free_seats[randi() % free_seats.size()]
		s["occupied_by"] = guest_id
		return s["node"].global_position
		
	return Vector2.INF
func leave_seat(guest_id: String) -> void:
	for s in _room_seats:
		if s["occupied_by"] == guest_id:
			s["occupied_by"] = ""

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
			
			var status_text = "Schwimmt / Sonnt sich"
			details.append({
				"left": guest_name,
				"right": status_text,
				"color": Color("#06b6d4")
			})
			
	return details



func get_patrol_target() -> Vector2:
	var side = randi() % 4
	var rx = 0.0
	var ry = 0.0
	match side:
		0: # top
			rx = randf_range(8.0, 88.0)
			ry = randf_range(8.0, 20.0)
		1: # bottom
			rx = randf_range(8.0, 88.0)
			ry = randf_range(76.0, 88.0)
		2: # left
			rx = randf_range(8.0, 20.0)
			ry = randf_range(8.0, 88.0)
		3: # right
			rx = randf_range(76.0, 88.0)
			ry = randf_range(8.0, 88.0)

	return global_position + Vector2(rx, ry)
