extends "res://scenes/ingame/rooms/Room.gd"

# =============================================================================
static func get_definition() -> Dictionary:
	var open_f = 480 # 08:00
	var open_t = 1200 # 20:00
	
	# Check for extended hours tech
	var tm = Engine.get_main_loop().root.get_node_or_null("TechtreeManager")
	if tm and tm.is_tech_unlocked("W1.4"): # Erweiterte Öffnungszeiten (Wellness-Paket)
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

# --- LEGACY STAFF METHODS (SMART ROOM API USED INSTEAD) ---
#func get_lifeguard_stand_pos() -> Vector2:
#	# ChairSpecial-Node verwenden wenn vorhanden
#	var chair = get_node_or_null("Interior/Furniture/Chairs/ChairSpecial")
#	if is_instance_valid(chair):
#		return chair.global_position
#	return global_position + Vector2(24.0, 16.0)
#
#func get_lifeguard_look_dir() -> float:
#	var chair = get_node_or_null("Interior/Furniture/Chairs/ChairSpecial")
#	if is_instance_valid(chair):
#		return chair.global_rotation
#	return PI / 2.0
#
#func claim_lifeguard_chair(staff_id: String) -> bool:
#	for s in _room_seats_staff_only:
#		if s["occupied_by"] == "":
#			s["occupied_by"] = staff_id
#			return true
#	return false
#
#func leave_lifeguard_chair(staff_id: String) -> void:
#	for s in _room_seats_staff_only:
#		if s["occupied_by"] == staff_id:
#			s["occupied_by"] = ""
#
#func is_lifeguard_chair_free(staff_id: String = "") -> bool:
#	for s in _room_seats_staff_only:
#		if s["occupied_by"] == "" or (staff_id != "" and s["occupied_by"] == staff_id):
#			return true
#	return false
#
# =============================================================================
# --- LEGACY GUEST METHODS ---
#func claim_seat(guest_id: String) -> Vector2:
#	for s in _room_seats:
#		if s["occupied_by"] == guest_id:
#			return s["node"].global_position
#			
#	var free_seats = []
#	for s in _room_seats:
#		if s["occupied_by"] == "":
#			free_seats.append(s)
#			
#	if free_seats.size() > 0:
#		var s = free_seats[randi() % free_seats.size()]
#		s["occupied_by"] = guest_id
#		return s["node"].global_position
#		
#	return Vector2.INF
#func leave_seat(guest_id: String) -> void:
#	for s in _room_seats:
#		if s["occupied_by"] == guest_id:
#			s["occupied_by"] = ""

# =============================================================================

# =============================================================================

# =============================================================================
# LIVE-MONITOR
# =============================================================================
func get_live_details() -> Array[Dictionary]:
	var details: Array[Dictionary] = []
	var now := TimeManager.get_game_time() if TimeManager else 0
	
	for actor in get_tree().get_nodes_in_group("guest_actors"):
		var valid_states = [3, 6, 7, 8, 9]
		if actor.get("current_state") in valid_states and actor.get("_current_poi_id") == "pool_small":
			var gm = actor.get("_guest_member")
			if gm:
				var guest_id: String = gm.id
				var time_left_mins: int = 0
				if _guest_session_end.has(guest_id):
					time_left_mins = max(0, _guest_session_end[guest_id] - now)
				
				var status_text: String
				var color := Color("#06b6d4")
				
				if time_left_mins <= 0:
					status_text = GameState.T("poi.status.leaving_soon")
				else:
					# Liege (bed) = "Entspannt", Wasser/Pool (seat) = "Badet"
					var on_lounger := false
					for b in _room_beds:
						if b["occupied_by"] == guest_id:
							on_lounger = true
							break
					
					if on_lounger:
						status_text = GameState.T("poi.pool.lounging")
						color = Color("#0891b2") # Liege etwas dunkler
					else:
						status_text = GameState.T("poi.pool.swimming")
						color = Color("#06b6d4") # Wasser-Blau
					status_text += " (%dm)" % time_left_mins

				
				details.append({
					"left": gm.name,
					"right": status_text,
					"color": color,
					"_sort": time_left_mins
				})
	
	# Aufsteigend: kleinste Zeit zuerst
	details.sort_custom(func(a, b): return a["_sort"] < b["_sort"])
	return details


# Session-Tracking: Wann soll der Gast den Pool verlassen?
var _guest_session_end: Dictionary = {}   # guest_id -> Ingame-Zeit Sessionende
var _guest_cooldown_end: Dictionary = {}  # guest_id -> Ingame-Zeit Cooldown-Ende

func is_guest_allowed(actor: Node2D) -> bool:
	# Cooldown-Check: nach Session-Ende darf Gast 60 Min nicht mehr rein
	var gm = actor.get("_guest_member")
	var guest_id: String = gm.id if gm else ""
	var now := TimeManager.get_game_time() if TimeManager else 0
	if _guest_cooldown_end.has(guest_id) and now < _guest_cooldown_end[guest_id]:
		return false
	return true

func get_available_interactions(actor: Node2D) -> Array[Dictionary]:
	var gm = actor.get("_guest_member")
	var guest_id: String = gm.id if gm else ""
	var now := TimeManager.get_game_time() if TimeManager else 0
	# Session abgelaufen? Leeres Array, Session bleibt bis release_interaction kommt
	if _guest_session_end.has(guest_id) and now >= _guest_session_end[guest_id]:
		return []
	
	var interactions = super.get_available_interactions(actor)
	# Kein Wandern im Pool
	interactions = interactions.filter(func(i): return i.type != "wander")
	# Erzwungene Chair <-> Bed Alternation
	if _last_interaction_for_guest.has(guest_id):
		var last_type: String = _last_interaction_for_guest[guest_id].get("type", "")
		var want_type: String = "sleep" if last_type == "sit" else "sit"
		var alternated = interactions.filter(func(i): return i.type == want_type)
		if not alternated.is_empty():
			return alternated
	return interactions

func claim_interaction(actor_id: String, interaction_id: String) -> Dictionary:
	# Bademeister-Hochsitz: Blickrichtung zum Pool (ServicePoint) statt Stuhl-Rotation
	if interaction_id.begins_with("staff_seat_"):
		var seat_result := super.claim_interaction(actor_id, interaction_id)
		if seat_result.has("target_pos"):
			var pool_center: Vector2
			var chair4 := get_node_or_null("Interior/Furniture/Chairs/Chair4")
			if is_instance_valid(chair4):
				pool_center = chair4.global_position
			else:
				pool_center = get_service_position() # Fallback
			var chair_pos: Vector2 = seat_result["target_pos"]
			var dir: Vector2 = (pool_center - chair_pos).normalized()
			seat_result["look_at_dir"] = dir.angle() + PI / 2.0
		return seat_result

	# Gäste: Beim ersten Claim Gesamtaufenthalt festlegen (60-180 Min, begrenzt auf Schliessung)
	if not _guest_session_end.has(actor_id):
		var stay_dur := randf_range(60.0, 180.0)
		var def = get_definition()
		if def.has("open_to"):
			var open_to: int = def.get("open_to")
			if open_to < 1440:
				var now_t := TimeManager.get_game_time() if TimeManager else 0
				var time_left := open_to - now_t
				if time_left > 0:
					stay_dur = min(stay_dur, float(time_left))
				else:
					stay_dur = 1.0
		var now := TimeManager.get_game_time() if TimeManager else 0
		_guest_session_end[actor_id] = now + int(stay_dur)

	# Spot-Wechsel-Timer: 5-12 Min fuer mehr Lebendigkeit
	var spot_dur := randf_range(5.0, 12.0)
	var result := super.claim_interaction(actor_id, interaction_id)
	if result.has("target_pos"):
		result["duration"] = spot_dur
	return result



func release_interaction(actor_id: String) -> void:
	if _guest_session_end.has(actor_id):
		var now := TimeManager.get_game_time() if TimeManager else 0
		if now >= _guest_session_end[actor_id]:
			# Session abgelaufen: Cooldown setzen und Session loeschen
			_guest_cooldown_end[actor_id] = now + 60
			_guest_session_end.erase(actor_id)
		# else: Spot-Wechsel - Session BEHALTEN damit claim_interaction keine neue erstellt
	super.release_interaction(actor_id)

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
