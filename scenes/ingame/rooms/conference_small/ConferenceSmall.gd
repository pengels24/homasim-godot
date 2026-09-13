extends "res://scenes/ingame/rooms/Room.gd"

# =============================================================================
static func get_definition() -> Dictionary:
	return {
		"id": "conference_small",
		"build_cost": 5000,
		"exp_reward": 500,
		"prefix": "C",
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
		"open_from": 465,  # 07:45 – 15 Min. Vorpuffer damit TG den Raum betreten können
		"open_to": 1020,   # 17:00
		"valid_door_slots": ["L2"],
		"cleanliness_level": 100,
		"maintenance_level": 100,
		"is_service_requested": false,
		"allowed_guest_types": ["business", "nomad", "luxury", "vip"]
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
	var shown_ids: Array[String] = []
	
	# 1. Belegte Sitzplätze anzeigen
	for seat in _room_seats:
		if seat["occupied_by"] != "":
			var guest_name = "Gast"
			var is_walking = false
			
			for a in get_tree().get_nodes_in_group("guest_actors"):
				var mem = a.get("_guest_member")
				if mem and mem.id == seat["occupied_by"]:
					guest_name = mem.name + " (TG)"
					if a.get("current_state") == 1: # State.WALKING
						is_walking = true
					break
			
			if is_walking:
				continue
			
			shown_ids.append(seat["occupied_by"])
			var status_text = GameState.T("poi.conference.attending")
			if seat["occupied_by"] == _speaker_id:
				status_text = GameState.T("poi.conference.speaking")
				
			details.append({
				"left": guest_name,
				"right": status_text,
				"color": Color("#8b5cf6") if seat["occupied_by"] != _speaker_id else Color("#f59e0b")
			})
	
	# 2. Wuselnde Gäste anzeigen (vor Event-Start, noch kein Sitz)
	var gm = get_tree().current_scene.find_child("GuestManager", true, false)
	var rkey = gm._room_key(self) if is_instance_valid(gm) else ""
	for a in get_tree().get_nodes_in_group("guest_actors"):
		var mem = a.get("_guest_member")
		if not mem:
			continue
		if mem.id in shown_ids:
			continue
		var party = a.call("_get_my_party") if a.has_method("_get_my_party") else null
		if not is_instance_valid(party) or party.get("event_poi_id") != rkey:
			continue
		# Ist der Gast im IN_POI State in diesem Raum?
		if a.get("current_state") == 3 and a.get("_current_poi_id") == "conference_small": # State.IN_POI = 3
			details.append({
				"left": mem.name + " (TG)",
				"right": GameState.T("poi.conference.waiting"),
				"color": Color("#6b7280")
			})
	
	return details

# =============================================================================
# Smart Room & Speaker Logic
# =============================================================================
const TIME_SESSION_START    := 480   # 08:00
const TIME_BREAK_START      := 720   # 12:00
const TIME_BREAK_END        := 795   # 13:15  Gäste kommen zurück → wander_pm
const TIME_SESSION_PM_START := 810   # 13:30  Session PM beginnt
const TIME_END              := 1020  # 17:00

var _speaker_id: String = ""
var _designated_speaker_id: String = ""
var _speaker_time: int = 0
var _phase: String = "idle"  # idle / wander / session / break / wander_pm / session_pm / end

func _ready() -> void:
	super._ready()
	TimeManager.sig_minute_passed.connect(_on_minute_passed)
	# Phase nach Reload korrekt initialisieren (sig_minute_passed liefert keine vergangenen Events)
	_init_phase_from_time.call_deferred()

func _init_phase_from_time() -> void:
	if _phase != "idle":
		return
	var t := TimeManager.get_game_time() if TimeManager else 0
	if t < TIME_SESSION_START:
		_phase = "wander"
	elif t < TIME_BREAK_START:
		_phase = "session"
	elif t < TIME_BREAK_END:
		_phase = "break"
	elif t < TIME_SESSION_PM_START:
		_phase = "wander_pm"
	elif t < TIME_END:
		_phase = "session_pm"
	else:
		_phase = "end"

func _on_minute_passed(total_game_minutes: int) -> void:
	# Phasen-Übergänge ZUERST (damit Speaker-Check korrekte Phase sieht)
	match total_game_minutes:
		TIME_SESSION_START:
			if _phase == "wander" or _phase == "idle":
				_phase = "session"
		TIME_BREAK_START:
			if _phase == "session":
				_start_break()
		TIME_BREAK_END:
			if _phase == "break":
				_end_break()
		TIME_SESSION_PM_START:
			if _phase == "wander_pm":
				_phase = "session_pm"
				_speaker_time = 0  # Frischer Start nach Pause
		TIME_END:
			if _phase == "session_pm" or _phase == "wander_pm":
				_broadcast_to_event_guests("end_conference_day")
				_phase = "end"

	# Speaker-Swap DANACH (Phase ist jetzt aktuell)
	if _speaker_id != "" and (_phase == "session" or _phase == "session_pm"):
		_speaker_time += 1
		if _speaker_time >= 15:
			_swap_speaker()

func _swap_speaker() -> void:
	# var t = TimeManager.get_game_time() if TimeManager else -1
	# print("[TGCHANGE] SWAP_SPEAKER called | %02d:%02d | current_speaker=%s | speaker_time=%d" % [t/60, t%60, _speaker_id, _speaker_time])
	# Wähle einen ZUFÄLLIGEN Zuhörer als neuen Speaker
	var possible_listeners = []
	for s in _room_seats:
		if s["node"].name != "ChairSpeaker" and s["occupied_by"] != "":
			possible_listeners.append(s["occupied_by"])
			
	if possible_listeners.is_empty():
		_speaker_time = 0
		return
		
	var new_speaker_id: String = possible_listeners.pick_random()
	var old_speaker_id: String = _speaker_id
	
	if new_speaker_id == old_speaker_id:
		_speaker_time = 0
		return

	# Finde die Platz-Daten
	var speaker_seat_idx := -1
	var listener_seat_idx := -1
	for i in range(_room_seats.size()):
		if _room_seats[i]["node"].name == "ChairSpeaker":
			speaker_seat_idx = i
		if _room_seats[i]["occupied_by"] == new_speaker_id:
			listener_seat_idx = i
			
	if speaker_seat_idx == -1 or listener_seat_idx == -1:
		_speaker_time = 0
		return
		
	# Finde die GuestActor-Nodes
	var old_speaker_actor: Node = null
	var new_speaker_actor: Node = null
	for node in get_tree().get_nodes_in_group("guest_actors"):
		var mem = node.get("_guest_member")
		if mem:
			if mem.id == old_speaker_id:
				old_speaker_actor = node
			elif mem.id == new_speaker_id:
				new_speaker_actor = node
				
	if not is_instance_valid(old_speaker_actor) or not is_instance_valid(new_speaker_actor):
		_speaker_time = 0
		return

	# -- ATOMARER TAUSCH --
	# 1. Plätze im Seatmap direkt tauschen (kein release/claim Umweg)
	_room_seats[speaker_seat_idx]["occupied_by"] = new_speaker_id
	_room_seats[listener_seat_idx]["occupied_by"] = old_speaker_id
	
	# 2. Speaker-Status aktualisieren
	_speaker_id = new_speaker_id
	_designated_speaker_id = new_speaker_id
	_speaker_time = 0
	
	# 3. Beide Gäste direkt zu ihren neuen Plätzen schicken (über _execute_poi_move)
	var speaker_target_pos: Vector2 = _room_seats[speaker_seat_idx]["node"].global_position
	var listener_target_pos: Vector2 = _room_seats[listener_seat_idx]["node"].global_position
	
	# Timer VOR _execute_poi_move setzen! Verhindert Race-Condition:
	# Wenn der alte _action_timer genau in diesem Frame auf <= 0 lief,
	# würde _process_waiting() zwischen swap und Timer-Reset feuern und
	# release/claim_interaction auslösen (was EXP generiert).
	new_speaker_actor.set("_action_timer", 999.0 * 60.0)
	old_speaker_actor.set("_action_timer", 999.0 * 60.0)
	
	# var t2 = TimeManager.get_game_time() if TimeManager else -1
	# print("[TGCHANGE] SWAP_DONE | %02d:%02d | new_speaker=%s | old_speaker=%s | timers set to 999*60" % [t2/60, t2%60, new_speaker_id, old_speaker_id])
	
	if new_speaker_actor.has_method("_execute_poi_move"):
		new_speaker_actor.call("_execute_poi_move", speaker_target_pos, self)
	
	if old_speaker_actor.has_method("_execute_poi_move"):
		old_speaker_actor.call("_execute_poi_move", listener_target_pos, self)

func get_available_interactions(actor: Node2D) -> Array[Dictionary]:
	var interactions: Array[Dictionary] = []
	
	# Event-Modus prüfen
	var gm = get_tree().current_scene.find_child("GuestManager", true, false)
	var rkey = gm._room_key(self) if is_instance_valid(gm) else ""
	var is_event_active = EventManager.active_conferences.has(rkey)
	
	var party = null
	if actor.has_method("_get_my_party"):
		party = actor.call("_get_my_party")

	var is_my_event_guest = (party != null and party.get("event_poi_id") == rkey)
	var is_any_event_guest = (party != null and party.get("event_poi_id") != "")
	
	# MODUS A: Event läuft. NUR _meine_ Event-Gäste dürfen rein.
	if is_event_active and not is_my_event_guest:
		return interactions
		
	# MODUS B: Kein Event läuft. Event-Gäste dürfen NIE in reguläre Räume (außer Lobby/Bar/Rest)
	if not is_event_active and is_any_event_guest:
		return interactions

	# VORPUFFER-MODUS:
	# Morgens 07:45-08:00 UND nachmittags 13:50-14:00: Gäste wuseln im Raum
	var current_game_time = TimeManager.get_game_time() if TimeManager else 480
	var is_wander_window := (current_game_time < TIME_SESSION_START) or \
						   (current_game_time >= TIME_BREAK_END and current_game_time < TIME_SESSION_PM_START)
	if is_my_event_guest and is_wander_window:
		var wander_pos = get_random_walkable_local_pos() # gibt bereits World-Koordinaten zurück!
		if wander_pos != Vector2.INF:
			interactions.append({
				"id": "wander_pre",
				"type": "wander",
				"target_pos": wander_pos,
				"duration": randf_range(4.0, 8.0)  # 4-8 Ingame-Min: kurz zusammenstehen, dann weiterschlurfen
			})
		return interactions
	
	# Normales Claiming (wie Room.gd)
	var actor_id = actor.get("_guest_member").id if actor.has_method("_get_my_party") else ""
	for i in range(_room_seats.size()):
		var s = _room_seats[i]
		# Frei ODER aktuell vom selben Gast besetzt (damit er seinen Platz "behalten" kann)
		if s["occupied_by"] == "" or s["occupied_by"] == actor_id:
			if s["node"].name == "ChairSpeaker":
				# Wenn es einen ausgewählten nächsten Speaker gibt, darf nur er hier sitzen
				if _designated_speaker_id != "" and actor_id != _designated_speaker_id:
					continue
			else:
				# Der designierte Speaker DARF NICHT auf einen Zuhörerplatz
				if _designated_speaker_id != "" and actor_id == _designated_speaker_id:
					continue
					
			interactions.append({
				"id": "seat_" + str(i),
				"type": "sit",
				"target_pos": s["node"].global_position,
				"duration": 999.0
			})
			
	return interactions

func claim_interaction(actor_id: String, interaction_id: String) -> Dictionary:
	# Wander-Interaktion vor Event-Start: kein Sitz belegen, nur Position
	if interaction_id == "wander_pre":
		var wander_pos = get_random_walkable_local_pos() # gibt bereits World-Koordinaten zurück!
		if wander_pos != Vector2.INF:
			return {"target_pos": wander_pos, "duration": randf_range(4.0, 8.0)}  # 4-8 Ingame-Min
		return {}
	
	var res = super.claim_interaction(actor_id, interaction_id)
	if res.is_empty():
		return res
	
	if interaction_id.begins_with("seat_"):
		var idx = interaction_id.replace("seat_", "").to_int()
		var s = _room_seats[idx]
		# Konferenz-Sitze: Gaeste bleiben bis Swap oder Session-Ende (kein 10-20 Min Zucken)
		res["duration"] = 999.0
		if s["node"].name == "ChairSpeaker":
			_speaker_id = actor_id
			_designated_speaker_id = actor_id
			_speaker_time = 0
			# Phase sicherstellen falls noch idle (Reload-Fallback)
			if _phase == "idle":
				_init_phase_from_time()
		
		# Blickrichtung fuer ALLE Sitze: immer zum Speakertable
		var is_portrait := room_rotation % 2 == 1
		var root = get_node_or_null("Portrait/Interior") if is_portrait else get_node_or_null("Landscape/Interior")
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

# =============================================================================
func get_room_entry_pos(_map_grid: Node) -> Vector2:
	var door = get_node_or_null("Door")
	if is_instance_valid(door):
		return door.global_position
		
	return global_position + Vector2(16, 16)

# =============================================================================
# Konferenz-Phasen: Pause & Ende
# =============================================================================

func _start_break() -> void:
	_phase = "break"
	# Speaker-State zurücksetzen – nach Pause frischer Start
	_speaker_id = ""
	_speaker_time = 0
	_designated_speaker_id = ""
	# Alle Sitze freigeben (die GuestActor-Methode macht den Rest)
	for s in _room_seats:
		s["occupied_by"] = ""
	print("[CONF] _start_break | 12:00 | alle Sitze frei, TG werden rausgeschickt")
	_broadcast_to_event_guests("go_conference_break")

func _end_break() -> void:
	_phase = "wander_pm"
	print("[CONF] _end_break | 13:50 | TG kehren zurück (wander_pm bis 14:00)")
	_broadcast_to_event_guests("return_from_conference_break")

func _end_conference() -> void:
	_phase = "end"
	# Alle restlichen Sitze freigeben
	for s in _room_seats:
		s["occupied_by"] = ""
	_speaker_id = ""
	_designated_speaker_id = ""
	print("[CONF] _end_conference | 17:00 | Konferenz beendet")
	# active_conferences Eintrag entfernen (GuestManager direkt via Gruppe, nicht find_child)
	var gm_nodes = get_tree().get_nodes_in_group("guest_manager")
	if gm_nodes.size() > 0:
		var rkey = gm_nodes[0]._room_key(self)
		EventManager.active_conferences.erase(rkey)
		print("[CONF] active_conferences bereinigt: ", rkey)
	_broadcast_to_event_guests("end_conference_day")

## Ruft eine Methode auf allen TG-Akteuren auf, die zu diesem Raum gehören.
func _broadcast_to_event_guests(method: String) -> void:
	var gm_nodes = get_tree().get_nodes_in_group("guest_manager")
	if gm_nodes.size() == 0:
		push_warning("[CONF] _broadcast_to_event_guests: GuestManager nicht gefunden!")
		return
	var rkey = gm_nodes[0]._room_key(self)
	for actor in get_tree().get_nodes_in_group("guest_actors"):
		if not is_instance_valid(actor):
			continue
		var party = actor.call("_get_my_party") if actor.has_method("_get_my_party") else null
		if is_instance_valid(party) and party.event_poi_id == rkey:
			if actor.has_method(method):
				actor.call(method)
