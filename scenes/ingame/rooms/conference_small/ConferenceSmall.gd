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
			
			var status_text = GameState.T("poi.conference.attending")
			if seat["occupied_by"] == _speaker_id:
				status_text = GameState.T("poi.conference.speaking")
				
			details.append({
				"left": guest_name,
				"right": status_text,
				"color": Color("#8b5cf6") if seat["occupied_by"] != _speaker_id else Color("#f59e0b")
			})
			
	return details

# =============================================================================
# Smart Room & Speaker Logic
# =============================================================================
var _speaker_id: String = ""
var _speaker_time: int = 0

func _ready() -> void:
	super._ready()
	TimeManager.sig_minute_passed.connect(_on_minute_passed)

func _on_minute_passed(_total_game_minutes: int) -> void:
	if _speaker_id != "":
		_speaker_time += 1
		if _speaker_time >= 15:
			_swap_speaker()

func _swap_speaker() -> void:
	# Finde einen Zuhörer zum Tauschen
	var listener_id = ""
	for s in _room_seats:
		if s["node"].name != "ChairSpeaker" and s["occupied_by"] != "":
			listener_id = s["occupied_by"]
			break
			
	var old_speaker = _speaker_id
	_speaker_id = ""
	_speaker_time = 0
	
	release_interaction(old_speaker)
	if listener_id != "":
		release_interaction(listener_id)
	
	# Beide fordern sofort im nächsten _process vom GuestActor eine neue Interaction an.

func get_available_interactions(actor: Node2D) -> Array[Dictionary]:
	var interactions: Array[Dictionary] = []
	
	# Event-Modus prüfen
	var is_event_active = EventManager.active_conferences.has(get_instance_id())
	
	var party = null
	if actor.has_method("_get_my_party"):
		party = actor.call("_get_my_party")
			
	var is_my_event_guest = (party != null and party.get("event_poi_id", "") == str(get_instance_id()))
	var is_any_event_guest = (party != null and party.get("event_poi_id", "") != "")
	
	# MODUS A: Event läuft. NUR _meine_ Event-Gäste dürfen rein.
	if is_event_active and not is_my_event_guest:
		return interactions
		
	# MODUS B: Kein Event läuft. Event-Gäste dürfen NIE in reguläre Räume (außer Lobby/Bar/Rest)
	if not is_event_active and is_any_event_guest:
		return interactions
		
	# Normales Claiming (wie Room.gd)
	for i in range(_room_seats.size()):
		var s = _room_seats[i]
		if s["occupied_by"] == "":
			interactions.append({
				"id": "seat_" + str(i),
				"type": "sit",
				"target_pos": s["node"].global_position,
				"duration": randf_range(10.0, 20.0)
			})
			
	return interactions

func claim_interaction(actor_id: String, interaction_id: String) -> Dictionary:
	var res = super.claim_interaction(actor_id, interaction_id)
	if res.is_empty():
		return res
		
	if interaction_id.begins_with("seat_"):
		var idx = interaction_id.replace("seat_", "").to_int()
		var s = _room_seats[idx]
		if s["node"].name == "ChairSpeaker":
			_speaker_id = actor_id
			_speaker_time = 0
			
			# Blickrichtung auf Speakertable erzwingen
			var is_portrait := room_rotation % 2 == 1
			var root = get_node("Portrait/Interior") if is_portrait else get_node("Landscape/Interior")
			if root:
				var table = root.get_node_or_null("Speakertable")
				if table:
					res["look_at_pos"] = table.global_position
					
	return res

func release_interaction(actor_id: String) -> void:
	if _speaker_id == actor_id:
		_speaker_id = ""
		_speaker_time = 0
	super.release_interaction(actor_id)

