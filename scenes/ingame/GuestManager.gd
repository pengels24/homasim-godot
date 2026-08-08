extends Node
class_name GuestManager

signal parties_changed()
signal checkout_forgotten(count: int)
signal sig_party_checked_in(party: GuestParty, room: Node2D) # <--- NEU
signal sig_party_moving_to_checkout(party: GuestParty, room_id: String)
signal sig_party_checked_out_physically(party: GuestParty)
signal sig_guests_spawned(count)
signal sig_party_arrived(party: GuestParty)
signal sig_party_rejected(party: GuestParty)

# ── Konfiguration ─────────────────────────────────────────────────────────────
var _hotel:	Dictionary
var _map_grid: Node2D

# ── Listen ────────────────────────────────────────────────────────────────────
var _waiting:  Array = []   # Array[GuestParty]
var _active:   Array = []   # Array[GuestParty]
var _checkout: Array = []   # Array[GuestParty]
var _pending_dirty_rooms: Array[String] = [] # NEU: Räume, die auf das Unpause warten
var _daily_poi_visits: Dictionary = {}  # poi_room_id → visit_count (Reset jeden Morgen)


# --- Tages-Statistiken ---
var daily_checkin_parties: int = 0
var daily_checkin_heads: int = 0
var daily_checkout_parties: int = 0
var daily_checkout_heads: int = 0
var daily_rage_parties: int = 0
var daily_rage_heads: int = 0
var daily_timeout_parties: int = 0
var daily_timeout_heads: int = 0
var daily_reject_parties: int = 0
var daily_reject_heads: int = 0
var daily_declined_parties: int = 0
var daily_declined_heads: int = 0

# room_number → party_id; zeigt welches Zimmer belegt ist
var _room_assign: Dictionary = {}

# ── Zustand ───────────────────────────────────────────────────────────────────
var _next_party_id: int   = 1
var _next_member_id: int  = 1
var _daily_spawned_parties: int = 0
# todo - muss noch in settings
var _patience_rate: float = 0.05   # 5 % pro Spielstunde; über Settings anpassbar

# ── Setup ─────────────────────────────────────────────────────────────────────
var _room_definitions: Dictionary = {}


# =============================================================================
func configure(hotel: Dictionary, map_grid: Node2D) -> void:
	_hotel	= hotel
	_map_grid = map_grid
	# Sicherer Start: Dictionary bleibt leer, wenn keine Räume da sind.
	_room_definitions = {}

	GameState.sig_dev_spawn_guests.connect(func(count: int): spawn_guests(count))

	# NEU: Auf die Uhr hören!
	if not TimeManager.sig_midnight_struck.is_connected(process_midnight_penalties):
		TimeManager.sig_midnight_struck.connect(process_midnight_penalties)

	if not TimeManager.sig_morning_struck.is_connected(process_morning_routine):
		TimeManager.sig_morning_struck.connect(process_morning_routine)
		
	if not TimeManager.sig_speed_changed.is_connected(_on_speed_changed):
		TimeManager.sig_speed_changed.connect(_on_speed_changed)
		
	if TaskManager.has_signal("sig_room_cleaned"):
		if not TaskManager.sig_room_cleaned.is_connected(_on_room_cleaned):
			TaskManager.sig_room_cleaned.connect(_on_room_cleaned)



# =============================================================================
func set_patience_rate(rate: float) -> void:
	_patience_rate = rate


# ── Öffentliche Abfragen ──────────────────────────────────────────────────────


# =============================================================================
func get_waiting() -> Array:
	return _waiting


# =============================================================================
func get_active() -> Array:
	return _active


# =============================================================================
func get_checkout() -> Array:
	return _checkout

func get_guest(guest_id: String) -> GuestMember:
	for p: GuestParty in _waiting + _active + _checkout:
		for m: GuestMember in p.members:
			if m.id == guest_id:
				return m
	return null


# =============================================================================
func get_party(party_id: String) -> GuestParty:
	for p: GuestParty in _waiting + _active + _checkout:

		if p.id == party_id:
			return p

	return null


# =============================================================================
func get_free_rooms() -> Array:
	if not is_instance_valid(_map_grid):
		return []

	var all_rooms: Array = _map_grid.get_placed_rooms()
	var result: Array = []

	for room in all_rooms:
		var type_id: String = str(room.get("room_type_id"))
		
		# Neu: Wenn Zimmer zum Abriss markiert ist, darf es nicht belegt werden
		if room.get("is_pending_demolish"):
			continue

		# Falls wir die Def noch nicht im Cache haben, hier kurz holen (Lazy Loading)
		if not _room_definitions.has(type_id):

			if room.has_method("get_definition"):
				_room_definitions[type_id] = room.get_definition()

			else:
				continue

		var def = _room_definitions[type_id]

		if def.get("nightly_price", 0) <= 0:
			continue

		var rid := _room_key(room)

		if not _room_assign.has(rid):
			result.append(room)

	return result


# =============================================================================
## Prüft, ob ein bestimmtes Zimmer aktuell belegt ist, und gibt die GuestParty zurück
func get_party_in_room(room: Node2D) -> GuestParty:
	var rid := _room_key(room)

	if _room_assign.has(rid):
		var party_id: String = _room_assign[rid]
		return get_party(party_id)

	return null


# =============================================================================
## Eindeutiger Schlüssel für ein Zimmer: room_number wenn vergeben, sonst Positions-Key.
static func _room_key(room: Node2D) -> String:
	var rnum: String = str(room.get("room_number"))

	if rnum != "" and rnum != "null" and rnum != "0":
		return rnum

	return "%s_%d_%d" % [str(room.get("room_type_id")), int(room.get("x_pos")), int(room.get("y_pos"))]

func _get_room_node(room_id: String) -> Node2D:
	if not is_instance_valid(_map_grid):
		return null
	for room in _map_grid.get_placed_rooms():
		if _room_key(room) == room_id:
			return room
	return null

# =============================================================================
func _on_speed_changed(is_paused: bool, _speed: float) -> void:
	if not is_paused and _pending_dirty_rooms.size() > 0:
		for rid in _pending_dirty_rooms:
			var room = _get_room_node(rid)
			if room:
				room.set("cleanliness_level", 0)
				if GameState.selected_hotel.get("level", 1) >= GameState.UNLOCK_LEVELS.get("auto_staff", 100):
					room.set_service_requested(true)
					GameState.sig_room_needs_cleaning.emit(room)
				else:
					if room.has_method("_update_indicator"):
						room.call("_update_indicator")
		_pending_dirty_rooms.clear()


# =============================================================================
func _on_room_cleaned(room: Node2D) -> void:
	var room_key = _room_key(room)
	if _room_assign.has(room_key) and _room_assign[room_key] == "DIRTY":
		_room_assign.erase(room_key)
		parties_changed.emit()



# ── Spawn ─────────────────────────────────────────────────────────────────────

# =============================================================================
func on_hour_passed(_hour: int) -> void:
	_tick_patience()
	_tick_active_guests()

func _tick_active_guests() -> void:
	for party: GuestParty in _active:
		for member: GuestMember in party.members:
			member.saturation = max(0, member.saturation - 5)


# =============================================================================
func generate_daily_schedule(start_time: int) -> Array:
	if start_time <= 360:
		_daily_spawned_parties = 0
		
	var open_from := 420  # 07:00
	var open_to := 1320   # 22:00
	
	if is_instance_valid(_map_grid):
		for room in _map_grid.get_placed_rooms():
			if room.get("room_type_id") == "lobby" and room.has_method("get_definition"):
				var def: Dictionary = room.get_definition()
				open_from = def.get("reception_open_from", 420)
				open_to = def.get("reception_open_to", 1320)
				break
				
	# Keine Neuberechnungen (Spawns) mehr in den letzten 2 Stunden (120 Min) vor Schließung
	if start_time >= open_to - 120:
		return []
				
	var available_today := 0
	if is_instance_valid(_map_grid):
		for room in _map_grid.get_placed_rooms():
			if room.has_method("get_definition"):
				var def = room.get_definition()
				if def.get("nightly_price", 0) > 0 and not room.get("is_pending_demolish"):
					var rid := _room_key(room)
					var is_occupied_next_night = false
					
					if _room_assign.has(rid) and typeof(_room_assign[rid]) == TYPE_STRING and _room_assign[rid] != "DIRTY":
						var party = get_party(_room_assign[rid])
						if party and party.stay_days > 0:
							is_occupied_next_night = true
							
					if not is_occupied_next_night:
						available_today += 1
						
	var x: int = available_today
		
	var remaining_spawns = max(0, x - _daily_spawned_parties)
	
	# Wenn das Spiel mitten am Tag geladen wird, ist _daily_spawned_parties = 0.
	# Wir berechnen, wie viele Gäste bis zu diesem Zeitpunkt ungefähr gekommen WÄREN,
	# damit nicht alle Gäste des Tages in den verbleibenden Nachmittag gequetscht werden.
	if start_time > open_from:
		var day_duration = float(open_to - open_from)
		var elapsed = float(start_time - open_from)
		var proportion = clamp(elapsed / day_duration, 0.0, 1.0)
		var expected_guests = int(x * proportion)
		remaining_spawns = max(0, x - max(_daily_spawned_parties, expected_guests))
		
	var spawn_times := []
	
	if remaining_spawns > 0:
		var time_left = max(1, open_to - max(open_from, start_time))
		var block_duration = int(float(time_left) / float(remaining_spawns))
		
		# Für kleine Hotels (wenige Zimmer) die Wartezeit künstlich verkürzen, 
		# damit der Spieler am Anfang nicht 6 Stunden auf den ersten Gast wartet.
		block_duration = min(block_duration, 180) 
		
		var current_min = max(start_time + 15, open_from) # mind. 15 Min nach Start
		
		for i in range(remaining_spawns):
			if current_min >= open_to:
				break
				
			var current_max = min(open_to, current_min + block_duration)
			var time = randi_range(current_min, current_max)
			
			spawn_times.append(time)
			
			# Nächster Gast frühestens 15-45 Minuten nach diesem
			current_min = time + randi_range(15, 45)

	spawn_times.sort()
	# print("[GuestManager] generate_daily_schedule called with start_time=", start_time, " -> generated ", spawn_times.size(), " spawns: ", spawn_times)
	return spawn_times


# =============================================================================
## Spawnt eine neue Gästewelle.
## Ist amount = -1 (Standard), wird genau 1 Gruppe generiert.
## Gibt die Anzahl der generierten KÖPFE (Gäste) zurück.
func spawn_guests(amount: int = -1) -> int:
	var party_count := amount if amount > 0 else 1
	
	if amount <= 0 and EventManager != null and EventManager.is_event_active():
		party_count = randi_range(2, 3)
		
	var total_heads := 0
	
	_daily_spawned_parties += party_count

	for _i in party_count:
		var party := _generate_party()
		_waiting.append(party)
		sig_party_arrived.emit(party)

		# Zählt die tatsächlichen Personen in der Gruppe
		total_heads += party.members.size()

		ActivityLog.add(
			"guest",
			GameState.T("log.guest.new_guest_details", party.get_display_name(), GameState.T(party.get_type_name())),
			_hotel.get("day", 1),
			TimeManager.get_game_time(),
		)

	TimeManager.trigger_auto_pause()
	parties_changed.emit()
	
	if SoundManager and total_heads > 0:
		SoundManager.play("reception_new_guests")

	return total_heads


# =============================================================================
func has_bookable_rooms() -> bool:
	if not is_instance_valid(_map_grid):
		return false

	for room in _map_grid.get_placed_rooms():
		# Wir nutzen hier den direkten Weg über den Raum selbst (statt BuildPanel)
		if room.has_method("get_definition"):
			var def := {}

			if room.has_method("get_definition"):
				def = room.get_definition()

			if def.get("nightly_price", 0) > 0:
				return true

	return false


# =============================================================================
func _generate_party(force_type_id: String = "") -> GuestParty:
	var type_id = force_type_id if force_type_id != "" else _weighted_random_type()
	var party_id := "P%04d" % _next_party_id
	_next_party_id += 1
	
	if is_instance_valid(TutorialManager):
		TutorialManager.trigger("guest_" + type_id)

	var party := GuestParty.new(party_id, type_id)
	
	# Start-Zufriedenheit würfeln (Müde von der Anreise)
	party.satisfaction = randi_range(50, 80)
	if TechtreeManager and TechtreeManager.is_tech_unlocked("W1.1"):
		party.satisfaction += 10 # W1.1 Wellness-Körbchen Bonus
		print("[Tech] W1.1 Wellness-Körbchen Bonus! Start-Zufriedenheit: ", party.satisfaction, "%")
		
	var def: Dictionary = GuestDefinitions.ALL[type_id]
	party.stay_days = randi_range(def["min_stay"], def["max_stay"])
	party.total_stay_days = party.stay_days
	party.base_price = randi_range(def["min_base_price"], def["max_base_price"])
	party.arrived_day = _hotel.get("day", 1)
	party.arrived_time = TimeManager.get_game_time()

	match type_id:
		"couple":
			var last := NameDatabase.random_last()
			var m_first = NameDatabase.random_male()
			var f_first = NameDatabase.random_female()
			while f_first == m_first:
				f_first = NameDatabase.random_female()
				
			_add_member(party, m_first, last, "primary", "male", false)
			_add_member(party, f_first, last, "partner", "female", false)

		"family":
			var used_firsts: Array[String] = []
			var last := NameDatabase.random_last()
			
			var m_first = NameDatabase.random_male()
			used_firsts.append(m_first)
			_add_member(party, m_first,   last, "primary", "male", false)
			
			var f_first = NameDatabase.random_female()
			while f_first in used_firsts:
				f_first = NameDatabase.random_female()
			used_firsts.append(f_first)
			_add_member(party, f_first, last, "partner", "female", false)
			
			var child_count := randi_range(1, 3)

			for _c in child_count:
				var c_first = NameDatabase.random_child()
				while c_first in used_firsts:
					c_first = NameDatabase.random_child()
				used_firsts.append(c_first)
				
				var is_boy: bool = randf() > 0.5
				var child_gender: String = "male" if is_boy else "female"
				_add_member(party, c_first, last, "child", child_gender, true)

		_:
			var last  := NameDatabase.random_last()
			var is_male: bool = randf() > 0.5
			var first := NameDatabase.random_male() if is_male else NameDatabase.random_female()
			var gender: String = "male" if is_male else "female"
			_add_member(party, first, last, "primary", gender, false)

	return party


# =============================================================================
func _add_member(party: GuestParty, first: String, last: String, role: String, gender: String, is_child: bool) -> void:
	var m := GuestMember.new(
		"M%04d" % _next_member_id,
		party.id,
		"%s %s" % [first, last],
		role,
		gender,
		is_child
	)
	_next_member_id += 1
	party.members.append(m)


# =============================================================================
func _weighted_random_type() -> String:
	var pool := []
	var level: int = GameState.selected_hotel.get("level", 1)
	
	# Säule B: Level-Kopplung
	if level >= 1:
		pool.append("single")
		pool.append("couple")
	if level >= 3:
		pool.append("budget")
		pool.append("business")
	if level >= 5:
		pool.append("digital_nomad")
		pool.append("event")
		
	# Säule A: Harte Raum-Kopplung
	var has_family := false
	var has_superior := false
	
	if is_instance_valid(_map_grid):
		for room in _map_grid.get_placed_rooms():
			var r_id = room.get("room_type_id")
			if r_id == "bed_family": has_family = true
			if r_id == "bed_superior": has_superior = true
			
	if has_family:
		pool.append("family")
	if has_superior:
		pool.append("luxury")
		if GameState.has_techtree_unlocked("P1.3"):
			pool.append("vip")
		
	if pool.is_empty():
		pool.append("single")

	var total := 0
	var chances = {}
	
	for key: String in pool:
		if GuestDefinitions.ALL.has(key):
			var chance = int(GuestDefinitions.ALL[key]["spawn_chance"])
			
			if EventManager != null and EventManager.is_event_active():
				var ev = EventManager.get_active_event()
				if ev == EventManager.EventType.TRADE_FAIR and key == "business":
					chance = int(chance * 2.0)
				elif ev == EventManager.EventType.CONCERT and key == "event":
					chance = int(chance * 2.0)
				elif ev == EventManager.EventType.HOLIDAY and key == "family":
					chance = int(chance * 2.0)
					
			chances[key] = chance
			total += chance

	if total <= 0:
		return "single"

	var roll := randi() % total
	var acc  := 0

	for key: String in pool:
		if chances.has(key):
			acc += chances[key]
			if roll < acc:
				return key

	return pool[0]


# ── Patience ──────────────────────────────────────────────────────────────────

# =============================================================================
func _tick_patience() -> void:
	var left_ids: Array = []
	var current_time = TimeManager.get_game_time()

	for party: GuestParty in _waiting:
		# 11 Ingame-Stunden (660 Minuten) Geduld als Basis
		var wait_limit = 660
		if TechtreeManager and TechtreeManager.is_tech_unlocked("M1.4"):
			wait_limit = 792 # +20% Wartezeit (660 * 1.2)
			
		if current_time - party.arrived_time >= wait_limit:
			left_ids.append(party.id)

	for pid: String in left_ids:
		var party := get_party(pid)

		if party == null:
			continue

		# NEU: Statistik füttern
		daily_timeout_parties += 1
		daily_timeout_heads += party.members.size()
		
		# Harte Strafe -20 Ruf
		GameState.add_rep(-20)
		Toast.show(GameState.T("toast.guest.left_angry").replace("###", party.get_display_name()), "guest", false)

		_waiting.erase(party)
		party.state = "gone"
		sig_party_rejected.emit(party)
		ActivityLog.add(
			"guest_left",
			GameState.T("log.guest.left_angry", party.get_display_name()),
			_hotel.get("day", 1),
			TimeManager.get_game_time(),
		)

	if not left_ids.is_empty():
		parties_changed.emit()




# ── Check-in ──────────────────────────────────────────────────────────────────

# =============================================================================
## Gibt den Match-Typ zurück: "perfect" | "ask_price" | "ask_requirements" | "disabled"
func get_match_type(party: GuestParty, room: Node2D) -> String:
	var def:   Dictionary = party.get_type_def()
	var rtype: String = str(room.get("room_type_id"))
	var type_ok:  bool = rtype in def.get("allowed_rooms",   [])
	var preferred: bool = rtype in def.get("preferred_rooms", [])

	var reqs = def.get("requirements", [])
	var reqs_met: bool = _check_requirements(room, reqs)

	if not type_ok:
		return "disabled"

	if preferred and reqs_met:
		return "perfect"

	if not type_ok and not reqs_met:
		return "disabled"

	# Mindestens ein Problem: falscher Typ (allowed aber nicht preferred) ODER fehlende Reqs
	if not preferred and not reqs_met:
		return "disabled"   # beides fehlt

	return "ask_price" if not preferred else "ask_requirements"


# =============================================================================
func roll_ask(party: GuestParty, room: Node2D) -> Dictionary:
	var def: Dictionary = party.get_type_def()
	var preferred: bool = str(room.get("room_type_id")) in def.get("preferred_rooms", [])

	var target_chance := 0.6 if not preferred else 0.7
	var roll := randf()
	var accepted := roll <= target_chance

	# Wir geben ein Dictionary zurück, um die Werte im Toast anzeigen zu können
	return {
		"accepted": accepted,
		"roll_val": int(roll * 100),
		"target_val": int(target_chance * 100)
	}


# =============================================================================
func do_checkin(party: GuestParty, room: Node2D) -> void:
	var rid	   := _room_key(room)
	party.room_id  = rid
	party.state	= "active"
	_waiting.erase(party)
	_active.append(party)
	_room_assign[rid] = party.id

	# NEU: Statistik füttern
	daily_checkin_parties += 1
	daily_checkin_heads += party.members.size()

	# Budget beim Check-in: jeder Member bekommt sein eigenes Tagesbudget
	var def = GuestDefinitions.ALL.get(party.type, {})
	
	# === Traits checken und Zufriedenheit abziehen ===
	var reqs = def.get("requirements", [])
	var missing_count = 0
	for req in reqs:
		if not room.has_method("has_trait") or not room.has_trait(req):
			missing_count += 1
	if missing_count > 0:
		party.modify_satisfaction(-20 * missing_count)
	
	var budget_min: int = def.get("min_daily_budget", 10)
	var budget_max: int = def.get("max_daily_budget", 30)
	for member: GuestMember in party.members:
		var b: int = randi_range(budget_min, budget_max)
		if member.is_child:
			b = int(b * randf_range(0.2, 0.4)) # Kinder: 20–40% des Erwachsenen-Budgets
		member.daily_budget	= b
		member.spending_budget = b
	# Party-Budget als Summe (für Anzeige/Savegame-Kompatibilität)
	party.daily_budget	= party.members.reduce(func(acc, m): return acc + m.daily_budget, 0)
	party.spending_budget = party.daily_budget

	ActivityLog.add(
		"guest",
		GameState.T("log.guest.check_in", party.get_display_name(), str(room.get("room_number"))),
		_hotel.get("day", 1),
		TimeManager.get_game_time(),
	)
	sig_party_checked_in.emit(party, room) # <--- NEU: Ruf an die Welt
	parties_changed.emit()


# =============================================================================
func reject_party(party: GuestParty) -> void:
	party.state = "gone"
	sig_party_rejected.emit(party)
	_waiting.erase(party)

	# NEU: Statistik füttern
	daily_reject_parties += 1
	daily_reject_heads += party.members.size()

	ActivityLog.add(
		"guest",
		GameState.T("log.guest.rejected", party.get_display_name()),
		_hotel.get("day", 1),
		TimeManager.get_game_time(),
	)
	parties_changed.emit()


# =============================================================================
func clear_waiting_guests_with_penalty() -> void:
	if _waiting.is_empty():
		return

	var total_penalty := 0
	var kicked_count := _waiting.size()

	# Alle wartenden Gäste durchgehen und Strafe sammeln
	for party: GuestParty in _waiting:
		var penalty: int = 20 # ANG-255: Harte Strafe pauschal -20
		total_penalty += penalty
		party.state = "gone"
		sig_party_rejected.emit(party)

		ActivityLog.add(
			"guest",
			GameState.T("log.guest.left_angry_closed", party.get_display_name()),
			_hotel.get("day", 1),
			TimeManager.get_game_time()
		)

	# Liste leeren und UI benachrichtigen
	_waiting.clear()
	parties_changed.emit()

	# Ruf abziehen und Toast für den Spieler anzeigen
	if total_penalty > 0:
		GameState.add_rep(-total_penalty)
		Toast.show("%d Gästegruppen wütend abgereist! (-%d Ruf)" % [kicked_count, total_penalty], "guest", false)

# ── Checkout ──────────────────────────────────────────────────────────────────

# =============================================================================
func do_checkout(party: GuestParty) -> float:
	var payout := _calculate_payout(party)
	_finalize_checkout(party, int(payout), false)
	
	var exp_gain = GameState.calc_checkout_exp(party)
	if exp_gain > 0:
		var final_exp = int(exp_gain * (party.satisfaction / 100.0))
		GameState.add_exp(final_exp, "Checkout (GuestManager)")
		
	if party.satisfaction < 30:
		GameState.add_rep(-15)
	elif party.satisfaction >= 80:
		GameState.add_rep(5)

	return payout


# =============================================================================
func _finalize_checkout(party: GuestParty, payout: int, auto: bool) -> void:
	_checkout.erase(party)
	
	party.state = "gone"
	
	var is_demolish_pending = false
	var room = _get_room_node(party.room_id)
	if room and room.get("is_pending_demolish"):
		is_demolish_pending = true
		if _room_assign.has(party.room_id):
			_room_assign.erase(party.room_id)
	else:
		# Raum wird schmutzig und blockiert
		_room_assign[party.room_id] = "DIRTY"
		
		if TimeManager.is_paused:
			_pending_dirty_rooms.append(party.room_id)
		else:
			if room:
				room.set("cleanliness_level", 0)
				if GameState.selected_hotel.get("level", 1) >= GameState.UNLOCK_LEVELS.get("auto_staff", 100):
					room.set_service_requested(true)
					GameState.sig_room_needs_cleaning.emit(room)
				else:
					if room.has_method("_update_indicator"):
						room.call("_update_indicator")
	
	if not auto:
		sig_party_checked_out_physically.emit(party)
		
	# Update quests
	if QuestManager.has_method("on_guest_checkout"):
		QuestManager.on_guest_checkout(party.type)

	var msg := ""
	var log_type := "guest"

	# NEU: Unterscheidung für den Wut-Checkout inkl. getrennter Statistik
	if auto and payout == 0:
		msg = GameState.T("log.guest.rage_checkout", party.get_display_name())
		log_type = "rage_quit"

		daily_rage_parties += 1
		daily_rage_heads += party.members.size()
	else:
		msg = GameState.T("log.guest.check_out", party.get_display_name(), str(payout))
		if auto:
			msg += GameState.T("log.guest.auto_checkout")

		daily_checkout_parties += 1
		daily_checkout_heads += party.members.size()

	ActivityLog.add(
		log_type,
		msg,
		_hotel.get("day", 1),
		TimeManager.get_game_time()
	)

	if payout > 0:
		var category := "room"
		var desc := "tx.checkout|" + party.get_display_name()
		FinanceManager.add_transaction(payout, category, desc, false)

	parties_changed.emit()
	
	if is_demolish_pending:
		demolish_pending_rooms(false)


# =============================================================================
func _calculate_payout(party: GuestParty) -> float:
	return calculate_payout(party)

## Öffentliche Variante – wird auch von GuestCard zur Anzeige genutzt.
func calculate_payout(party: GuestParty) -> float:
	var nightly_price: float = float(party.base_price) # Fallback
	var room = _get_room_node(party.room_id)
	if room and room.has_method("get_definition"):
		var def = room.get_definition()
		if def.has("nightly_price") and def.get("nightly_price") > 0:
			nightly_price = float(def.get("nightly_price"))
			
	var base_payout = nightly_price * float(party.total_stay_days)
	
	if party.satisfaction < 40:
		base_payout *= 0.8
	elif party.satisfaction >= 90:
		base_payout *= 1.15
		
	return base_payout

# ── Serialisierung ────────────────────────────────────────────────────────────

# =============================================================================
func to_save_dict() -> Dictionary:
	var w: Array = []
	var a: Array = []
	var c: Array = []
	for p: GuestParty in _waiting:  w.append(p.to_dict())
	for p: GuestParty in _active:   a.append(p.to_dict())
	for p: GuestParty in _checkout: c.append(p.to_dict())
	return {
		"waiting":		w,
		"active":		 a,
		"checkout":	   c,
		"room_assign":	_room_assign.duplicate(),
		"next_party_id":  _next_party_id,
		"next_member_id": _next_member_id,
		
		# Stats
		"daily_checkin_parties": daily_checkin_parties,
		"daily_checkin_heads": daily_checkin_heads,
		"daily_checkout_parties": daily_checkout_parties,
		"daily_checkout_heads": daily_checkout_heads,
		"daily_rage_parties": daily_rage_parties,
		"daily_rage_heads": daily_rage_heads,
		"daily_timeout_parties": daily_timeout_parties,
		"daily_timeout_heads": daily_timeout_heads,
		"daily_reject_parties": daily_reject_parties,
		"daily_reject_heads": daily_reject_heads,
		"daily_declined_parties": daily_declined_parties,
		"daily_declined_heads": daily_declined_heads,
	}


# =============================================================================
func load_from_dict(d: Dictionary) -> void:
	_waiting.clear()
	_active.clear()
	_checkout.clear()
	_room_assign.clear()
	for pd: Dictionary in d.get("waiting",  []): _waiting.append(GuestParty.from_dict(pd))
	for pd: Dictionary in d.get("active",   []): _active.append(GuestParty.from_dict(pd))
	for pd: Dictionary in d.get("checkout", []): _checkout.append(GuestParty.from_dict(pd))
	_room_assign	= d.get("room_assign",	{})
	_next_party_id  = d.get("next_party_id",  1)
	_next_member_id = d.get("next_member_id", 1)
	
	daily_checkin_parties = d.get("daily_checkin_parties", 0)
	daily_checkin_heads = d.get("daily_checkin_heads", 0)
	daily_checkout_parties = d.get("daily_checkout_parties", 0)
	daily_checkout_heads = d.get("daily_checkout_heads", 0)
	daily_rage_parties = d.get("daily_rage_parties", 0)
	daily_rage_heads = d.get("daily_rage_heads", 0)
	daily_timeout_parties = d.get("daily_timeout_parties", 0)
	daily_timeout_heads = d.get("daily_timeout_heads", 0)
	daily_reject_parties = d.get("daily_reject_parties", 0)
	daily_reject_heads = d.get("daily_reject_heads", 0)
	daily_declined_parties = d.get("daily_declined_parties", 0)
	daily_declined_heads = d.get("daily_declined_heads", 0)
	
	parties_changed.emit()


# ── Hilfsmethoden ─────────────────────────────────────────────────────────────

# =============================================================================
func _check_requirements(room: Node2D, reqs: Array) -> bool:
	if reqs.is_empty():
		return true

	for req in reqs:
		if not room.has_method("has_trait") or not room.has_trait(req):
			return false
	return true


# =============================================================================
## Wird um 23:59 Uhr aufgerufen (VOR dem Tagesabschluss-Modal)
func process_midnight_penalties(day: int) -> void:
	# 1. Wartende Gäste an der Eingangstür verjagen
	for party: GuestParty in _waiting:
		party.state = "gone"
		sig_party_rejected.emit(party)
		ActivityLog.add(
			"guest_left",
			GameState.T("log.guest.left_end_of_day", party.get_display_name()),
			day,
			TimeManager.get_game_time(),
		)
	_waiting.clear()

	# NEU: Tagesgäste (Konferenz) verlassen das Hotel
	var day_guests = []
	for party: GuestParty in _active:
		if party.total_stay_days == 0:
			day_guests.append(party)
			
	for party in day_guests:
		party.state = "gone"
		_active.erase(party)
		sig_party_checked_out_physically.emit(party)
		ActivityLog.add(
			"guest_left",
			GameState.T("Tagesgäste sind abgereist", party.get_display_name()),
			day,
			TimeManager.get_game_time(),
		)

	# 1.5 Tägliche Zufriedenheitsstrafe für fehlende Requirements in belegten Zimmern
	for party: GuestParty in _active:
		var room = _get_room_node(party.room_id)
		if is_instance_valid(room):
			var def = party.get_type_def()
			var reqs = def.get("requirements", [])
			var missing_count = 0
			for req in reqs:
				if not room.has_method("has_trait") or not room.has_trait(req):
					missing_count += 1
			if missing_count > 0:
				party.modify_satisfaction(-10 * missing_count)
				
	# 2. Wut-Checkout für ignorierte Gäste am Tresen
	# Strafen passieren erst ab Tag 2, da an Tag 1 noch niemand abreisen kann.
	if day > 1:
		var forgotten_count := _checkout.size()
		var to_rage_quit: Array = _checkout.duplicate() # Kopie, da wir die originale Liste gleich bearbeiten

		for party: GuestParty in to_rage_quit:
			# Saftige Ruf-Strafe (Passe den Wert gerne an)
			GameState.add_rep(-20)
			# Checkout mit 0 Euro Zahlung erzwingen
			_finalize_checkout(party, 0, true)

		if forgotten_count > 0:
			checkout_forgotten.emit(forgotten_count)

	# 3. Warenverbrauch der POIs abrechnen
	_process_poi_supply_costs()

	parties_changed.emit()


# =============================================================================
## Wird aufgerufen wenn ein Gast einen POI betritt – zählt Besuche für Warenverbrauch.
func on_poi_visited(room_id: String) -> void:
	_daily_poi_visits[room_id] = _daily_poi_visits.get(room_id, 0) + 1


# =============================================================================
## Rechnet am Tagesende den Warenverbrauch aller besuchten POIs ab.
func _process_poi_supply_costs() -> void:
	for room_id in _daily_poi_visits:
		var visits: int = _daily_poi_visits[room_id]
		var room = _get_room_node(room_id)
		if not is_instance_valid(room):
			continue
		var supply_cost: int = room.get_definition().get("supply_cost_per_visit", 0)
		var total: int = visits * supply_cost
		if total > 0:
			FinanceManager.add_transaction(
				-total, "betrieb",
				"tx.supply|" + GameState.T(room.get_definition().get("name", room_id)) + "|" + str(visits)
			)
		
		# Verschmutzung basierend auf Besuchen erhöhen
		if room.has_method("add_dirt_from_visits"):
			room.add_dirt_from_visits(visits)
		if room.has_method("degrade_condition_from_visits"):
			room.degrade_condition_from_visits(visits)
			
	_daily_poi_visits.clear()


# =============================================================================
func demolish_pending_rooms(silent: bool = false) -> void:
	if is_instance_valid(_map_grid) and _map_grid.has_method("demolish_marked_rooms"):
		_map_grid.demolish_marked_rooms(silent)


# =============================================================================
## Wird um 06:00 Uhr aufgerufen (Wenn der neue Tag physisch beginnt)
func process_morning_routine() -> void:
	# Perfekter Tag EXP Bonus (vor dem Reset auswerten)
	var total_checkins_checkouts = daily_checkin_parties + daily_checkout_parties
	if total_checkins_checkouts > 0:
		var bad_events = daily_rage_parties + daily_timeout_parties + daily_declined_parties + daily_reject_parties
		if bad_events == 0:
			GameState.add_exp(100)
			ActivityLog.add(
				"guest", 
				GameState.T("log.guest.perfect_day"), 
				GameState.selected_hotel.get("day", 1), 
				TimeManager.get_game_time()
			)

	# Tages-Statistiken auf null setzen
	daily_checkin_parties = 0
	daily_checkin_heads = 0
	daily_checkout_parties = 0
	daily_checkout_heads = 0
	daily_rage_parties = 0
	daily_rage_heads = 0
	daily_timeout_parties = 0
	daily_timeout_heads = 0
	daily_reject_parties = 0
	daily_reject_heads = 0
	daily_declined_parties = 0
	daily_declined_heads = 0
	
	# === Gäste werden über Nacht hungrig ===
	for party: GuestParty in _active:
		for member: GuestMember in party.members:
			var night_hunger = randi_range(15, 40)
			member.saturation = max(0, member.saturation - night_hunger)

	# NEU: Tagesgäste für Konferenz spawnen
	if EventManager and EventManager.is_event_active() and EventManager.active_event == EventManager.EventType.CONFERENCE:
		var conf_room = null
		if is_instance_valid(_map_grid):
			for room in _map_grid.active_rooms:
				if is_instance_valid(room) and room.has_method("get_definition"):
					if room.get_definition().get("id") == "conference_small":
						conf_room = room
						break
		if conf_room:
			# Generiere 6-12 Tagesgäste für die Konferenz (entspricht der Anzahl an Stühlen/Pult)
			var amount = randi_range(6, 12)
			var total_event_income = 0
			
			for i in range(amount):
				var party = _generate_party("business")
				party.stay_days = 2 # Künstlich hoch, damit sie morgens nicht direkt auschecken
				party.total_stay_days = 0 # Markierung als Tagesgast
				
				# Room ID generieren wie in GuestController erwartet (z.B. "conference_small_10_5")
				var rx = int(conf_room.get("x_pos"))
				var ry = int(conf_room.get("y_pos"))
				var conf_rkey = "%s_%d_%d" % ["conference_small", rx, ry]
				party.room_id = conf_rkey
				
				_active.append(party)
				
				# Signal emitten, damit der GuestController die Actors an der Lobby spawnt!
				# Wir verwenden sig_party_checked_in, um den Actor-Spawn zu triggern,
				# übergeben als room den conf_room.
				sig_party_checked_in.emit(party, conf_room)
				
				# Statistik
				daily_checkin_parties += 1
				daily_checkin_heads += party.members.size()
				
				# Event-Pauschale berechnen (z.B. 150 pro Kopf)
				total_event_income += 150 * party.members.size()
				
			if total_event_income > 0:
				if FinanceManager:
					FinanceManager.add_transaction(total_event_income, "room", "tx.event_income|Konferenz")
				else:
					GameState.add_money(total_event_income)
				
				if EffectManager:
					EffectManager.spawn_money_text(total_event_income, conf_room.global_position + Vector2(0, -64))

	var moving: Array = []

	# Aktive Gäste: stay_days verringern
	for party: GuestParty in _active:
		party.stay_days -= 1
		# Neues Taschengeld für jeden Member individuell
		for member: GuestMember in party.members:
			member.spending_budget = member.daily_budget
		party.spending_budget = party.daily_budget  # Party-Summe auch zurücksetzen

		if party.stay_days <= 0:
			moving.append(party)

	# Gäste mit abgelaufener Zeit ans Pult (in den Checkout) schicken
	for party: GuestParty in moving:
		_active.erase(party)
		party.state = "checkout"
		_checkout.append(party)
		sig_party_moving_to_checkout.emit(party, party.room_id)

	parties_changed.emit()


# =============================================================================
## Wird vom UI aufgerufen, wenn ein Gast einen Aufpreis/Deal ablehnt
func guest_declined_offer(party: GuestParty) -> void:
	party.state = "gone"
	sig_party_rejected.emit(party)
	_waiting.erase(party)

	# NEU: Statistik für gescheiterte Verhandlungen
	daily_declined_parties += 1
	daily_declined_heads += party.members.size()

	ActivityLog.add(
		"guest_declined",
		GameState.T("log.guest.declined_offer", party.get_display_name()),
		_hotel.get("day", 1),
		TimeManager.get_game_time()
	)

	parties_changed.emit()
