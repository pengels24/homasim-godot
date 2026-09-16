extends Node
class_name GuestManager

signal parties_changed
signal sig_inspector_report_ready(stats: Dictionary)
signal checkout_forgotten(count: int)
signal sig_party_checked_in(party: GuestParty, room: Node2D) # <--- NEU
signal sig_party_event_arrived(party: GuestParty)
signal sig_party_moving_to_checkout(party: GuestParty, room_id: String)
signal sig_party_checked_out_physically(party: GuestParty)
@warning_ignore("unused_signal")
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
var recent_satisfaction: Array = [] # Die Satisfaction der letzten 30 Checkouts


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
	GameState.sig_dev_add_guest_budget.connect(_on_dev_add_guest_budget)

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
			
	if not TimeManager.sig_minute_passed.is_connected(_on_minute_passed):
		TimeManager.sig_minute_passed.connect(_on_minute_passed)

# =============================================================================
func _on_minute_passed(_total_game_minutes: int) -> void:
	var current_time = TimeManager.get_game_time()
	if current_time >= 420 and current_time % 5 == 0: # Erst ab 07:00 Uhr und alle 5 Ingame-Minuten prüfen
		if EventManager and EventManager.get("active_conferences") != null and EventManager.active_conferences.size() > 0:
			spawn_conference_guests(current_time)

	if current_time >= 720 and EventManager and EventManager.get("is_inspector_coming_today"):
		# Inspektor nur spawnen wenn kein anderes Event gleichzeitig läuft
		var conf_active: bool = EventManager.active_conferences.size() > 0
		var city_active: bool = EventManager.active_event != EventManager.EventType.NONE
		if not conf_active and not city_active:
			EventManager.is_inspector_coming_today = false
			spawn_inspector()
		# Wenn ein anderes Event läuft: Flag bleibt, Inspector kommt später nicht mehr.
		# Das ist gewollt - der Inspector-Tag wird verpasst (kein Nachholen).
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
func get_average_satisfaction() -> float:
	if recent_satisfaction.is_empty():
		return 100.0
	var sum := 0
	for val in recent_satisfaction:
		sum += val
	return float(sum) / float(recent_satisfaction.size())

# =============================================================================
func get_average_cleanliness() -> float:
	if not is_instance_valid(_map_grid):
		return 100.0
	var sum := 0
	var count := 0
	for room in _map_grid.get_placed_rooms():
		var clean = room.get("cleanliness_level")
		if clean != null:
			sum += int(clean)
			count += 1
	if count == 0:
		return 100.0
	return float(sum) / float(count)

# =============================================================================
func _push_satisfaction(val: int) -> void:
	recent_satisfaction.append(val)
	if recent_satisfaction.size() > 30:
		recent_satisfaction.pop_front()


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
func spawn_conference_guests(current_time: int) -> void:
	if not is_instance_valid(_map_grid) or EventManager == null:
		return
		
	# Niemals vor 07:00 Uhr spawnen
	if current_time < 420:
		return
		
	var active_conferences = EventManager.active_conferences
	
	for room_id in active_conferences.keys():
		var event_cfg = active_conferences[room_id]
		var conf_rkey = str(room_id)
		
		var room = _get_room_node(conf_rkey)
		if not is_instance_valid(room):
			continue
			
		var max_g = min(event_cfg.get("max_participants", 12), room.call("get_definition").get("max_guests", 12))
		
		# Wieviele haben wir schon?
		var current_guests = 0
		for active_party in _active:
			if active_party.get("event_poi_id") == conf_rkey:
				current_guests += active_party.members.size()
				
		var needed = max_g - current_guests
		if needed <= 0:
			continue
			
		var spawn_now = min(4, needed) # Maximal 4 Gäste pro Welle (alle 5 Ingame-Minuten)
		var spawned_this_wave = 0
		
		while spawned_this_wave < spawn_now:
			var party = _generate_party("business")
			party.stay_days = 2
			party.total_stay_days = 0 
			
			party.room_id = "" 
			party.event_poi_id = conf_rkey 
			
			# Event-Farbe in die Party injecten, damit der GuestActor das Icon färben kann
			party.set("event_color", event_cfg.get("color", "#aaaaaa"))
			
			var def_b = GuestDefinitions.ALL.get("business", {})
			var budget_min: int = def_b.get("min_daily_budget", 10)
			var budget_max: int = def_b.get("max_daily_budget", 30)
			var poi_mult: float = def_b.get("poi_budget_multiplier", 1.0)
			var dynamic_poi_budget = _get_dynamic_poi_budget()
			for member: GuestMember in party.members:
				var b: int = randi_range(budget_min, budget_max) + int(dynamic_poi_budget * poi_mult)
				member.daily_budget   = b
				member.spending_budget = b
				# Tagungsgäste haben zu Beginn keinen Hunger, damit sie nicht sofort die POIs fluten
				member.saturation = randi_range(80, 100)
				
			party.daily_budget    = party.members.reduce(func(acc, m): return acc + m.daily_budget, 0)
			party.spending_budget = party.daily_budget
			
			_active.append(party)
			sig_party_event_arrived.emit(party)
			parties_changed.emit() # HUD-Gästezähler sofort aktualisieren
			
			daily_checkin_parties += 1
			daily_checkin_heads += party.members.size()
			spawned_this_wave += party.members.size()


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
		var party_crit_count = 0
		var party_happy_count = 0
		
		for member: GuestMember in party.members:
			member.saturation = max(0, member.saturation - 5)
			member.thirst = max(0, member.thirst - 8)
			member.energy = max(0, member.energy - 4)
			member.fun = max(0, member.fun - 6)
			
			if member.saturation < 20 or member.thirst < 20 or member.energy < 20 or member.fun < 20:
				party_crit_count += 1
			elif member.saturation > 70 and member.thirst > 70 and member.energy > 70 and member.fun > 70:
				party_happy_count += 1
				
		# Satisfaction anpassen basierend auf den aggregierten Bedürfnissen
		if party_crit_count > 0:
			# Für jedes Gruppenmitglied mit kritischem Bedürfnis -1 bis -2 Zufriedenheit
			party.modify_satisfaction(-1 * party_crit_count)
		elif party_happy_count == party.members.size():
			# Wenn ALLE Mitglieder im grünen Bereich sind, steigt die Zufriedenheit
			party.modify_satisfaction(1)


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
	if EventManager != null and EventManager.is_event_active():
		x = int(ceil(x * 1.5))
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
		party_count = randi_range(1, 3) # ANG-348: City-Events erzeugen 1-3 Buchungen gleichzeitig
		
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
func spawn_inspector() -> void:
	var party := _generate_party("inspector")
	party.is_inspector = true
	party.cover_type = "business" # Tarnung als Geschäftsreisender – nutzt Restaurant, passt zum Gourmet-Inspektor
	
	_waiting.append(party)
	sig_party_arrived.emit(party)
	
	parties_changed.emit()
	if SoundManager:
		SoundManager.play("reception_new_guests")


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
	
	if is_instance_valid(TutorialManager) and type_id != "inspector":
		TutorialManager.trigger("guest_" + type_id)

	var party := GuestParty.new(party_id, type_id)
	
	# Start-Zufriedenheit würfeln (Müde von der Anreise)
	party.satisfaction = randi_range(50, 80)
	if TechtreeManager and TechtreeManager.is_tech_unlocked("W1.1"):
		party.satisfaction += 5 # W1.1 Wellness-Körbchen Bonus (+5%)
		if party.satisfaction > 100: party.satisfaction = 100
		print("[Tech] W1.1 Wellness-Körbchen Bonus! Start-Zufriedenheit: ", party.satisfaction, "%")
		
	var def: Dictionary = GuestDefinitions.ALL[type_id]
	party.stay_days = randi_range(def["min_stay"], def["max_stay"])
	party.total_stay_days = party.stay_days
	party.base_price = randi_range(def["min_base_price"], def["max_base_price"])
	party.arrived_day = _hotel.get("day", 1)
	party.arrived_time = TimeManager.get_game_time()

	var party_speed = randf_range(-10.0, 10.0)
	
	match type_id:
		"couple":
			var last := NameDatabase.random_last()
			var m_first = NameDatabase.random_male()
			var f_first = NameDatabase.random_female()
			while f_first == m_first:
				f_first = NameDatabase.random_female()
				
			_add_member(party, m_first, last, "primary", "male", false, party_speed)
			_add_member(party, f_first, last, "partner", "female", false, party_speed)

		"family":
			var used_firsts: Array[String] = []
			var last := NameDatabase.random_last()
			
			var m_first = NameDatabase.random_male()
			used_firsts.append(m_first)
			_add_member(party, m_first,   last, "primary", "male", false, party_speed)
			
			var f_first = NameDatabase.random_female()
			while f_first in used_firsts:
				f_first = NameDatabase.random_female()
			used_firsts.append(f_first)
			_add_member(party, f_first, last, "partner", "female", false, party_speed)
			
			var child_count := randi_range(1, 3)

			for _c in child_count:
				var c_first = NameDatabase.random_child()
				while c_first in used_firsts:
					c_first = NameDatabase.random_child()
				used_firsts.append(c_first)
				
				var is_boy: bool = randf() > 0.5
				var child_gender: String = "male" if is_boy else "female"
				_add_member(party, c_first, last, "child", child_gender, true, party_speed)

		_:
			var last  := NameDatabase.random_last()
			var is_male: bool = randf() > 0.5
			var first := NameDatabase.random_male() if is_male else NameDatabase.random_female()
			var gender: String = "male" if is_male else "female"
			_add_member(party, first, last, "primary", gender, false, party_speed)

	return party


# =============================================================================
func _add_member(party: GuestParty, first: String, last: String, role: String, gender: String, is_child: bool, speed: float = -999.0) -> void:
	var m := GuestMember.new(
		"M%04d" % _next_member_id,
		party.id,
		"%s %s" % [first, last],
		role,
		gender,
		is_child,
		"", # hair
		"", # shirt
		speed
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
		if TechtreeManager and TechtreeManager.is_tech_unlocked("P1.3"):
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
	var poi_mult: float = def.get("poi_budget_multiplier", 1.0)
	var dynamic_poi_budget = _get_dynamic_poi_budget()
	
	for member: GuestMember in party.members:
		var b: int = randi_range(budget_min, budget_max) + int(dynamic_poi_budget * poi_mult)
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
## TG-Gäste (kein Zimmer, Tagung beendet) sauber aus _active entfernen und
## den normalen physischen Checkout-Flow triggern.
func checkout_event_party(party: GuestParty) -> void:
	_push_satisfaction(party.satisfaction)
	_active.erase(party)
	party.state = "gone"
	sig_party_checked_out_physically.emit(party)

# =============================================================================
func do_checkout(party: GuestParty) -> float:
	var payout := _calculate_payout(party)
	_finalize_checkout(party, int(payout), false)
	
	if party.type == "inspector":
		evaluate_gourmet_stars(party)
	else:
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
func evaluate_gourmet_stars(party: GuestParty) -> void:
	GameState.selected_hotel["last_inspector_day"] = _hotel.get("day", 1)
	
	var current_stars = GameState.selected_hotel.get("stars", 0)
	var next_level = str(current_stars + 1)
	
	var path := "res://config/gourmet_stars.json"
	if not FileAccess.file_exists(path):
		return
		
	var f := FileAccess.open(path, FileAccess.READ)
	var config = JSON.parse_string(f.get_as_text())
	if config == null or not config.has(next_level):
		Toast.show(GameState.T("event.gourmet.max_stars"), "event")
		return
		
	var req = config[next_level]
	var inspector_sat = party.satisfaction
	var avg_sat = get_average_satisfaction()
	var avg_clean = get_average_cleanliness()
	var rep = GameState.selected_hotel.get("rep", 0)
	var rooms = 0
	if is_instance_valid(_map_grid):
		rooms = _map_grid.get_placed_rooms().size()
		
	var success = true
	if inspector_sat < req.get("min_inspector_satisfaction", 0): success = false
	if avg_sat < req.get("min_avg_satisfaction", 0): success = false
	if avg_clean < req.get("min_cleanliness", 0): success = false
	if rep < req.get("min_rep", 0): success = false
	if rooms < req.get("min_rooms", 0): success = false
	
	var stats = {
		"inspector_sat": inspector_sat,
		"req_inspector_sat": req.get("min_inspector_satisfaction", 0),
		"avg_sat": avg_sat,
		"req_avg_sat": req.get("min_avg_satisfaction", 0),
		"avg_clean": avg_clean,
		"req_clean": req.get("min_cleanliness", 0),
		"rep": rep,
		"req_rep": req.get("min_rep", 0),
		"rooms": rooms,
		"req_rooms": req.get("min_rooms", 0),
		"result": "none",
		"stars_before": current_stars,
		"stars_after": current_stars,
		"inspector_name": party.get_display_name(),  # Pruefername fuer Signatur im Bericht
		"visited_rooms": party.visited_rooms
	}
	
	if success:
		GameState.selected_hotel["stars"] = current_stars + 1
		GameState.add_exp(200, GameState.T("event.gourmet.gained_toast"))
		GameState.sig_hotel_stars_changed.emit(GameState.selected_hotel["stars"])
		
		stats["result"] = "up"
		stats["stars_after"] = current_stars + 1
		
		if current_stars == 0:
			GameState.selected_hotel["exp_frozen"] = true
			# We emit sig_demo_completed after the inspector report is closed!
			# But we'll let UIManager handle that or emit it later. 
			# For now, just setting exp_frozen is fine.
	else:
		# Check auf Verlust
		if current_stars > 0:
			var curr_req = config.get(str(current_stars))
			if curr_req != null:
				var loss = false
				if inspector_sat < curr_req.get("min_inspector_satisfaction", 0) - 20: loss = true
				if avg_sat < curr_req.get("min_avg_satisfaction", 0) - 20: loss = true
				if avg_clean < curr_req.get("min_cleanliness", 0) - 20: loss = true
				if loss:
					GameState.selected_hotel["stars"] -= 1
					GameState.sig_hotel_stars_changed.emit(GameState.selected_hotel["stars"])
					stats["result"] = "down"
					stats["stars_after"] = current_stars - 1

	if is_instance_valid(TutorialManager):
		TutorialManager.trigger("guest_inspector")
		
	sig_inspector_report_ready.emit(stats)


# =============================================================================
func _finalize_checkout(party: GuestParty, payout: int, auto: bool) -> void:
	_push_satisfaction(party.satisfaction)
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
		"recent_satisfaction": recent_satisfaction.duplicate(),
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
	recent_satisfaction = d.get("recent_satisfaction", [])
	
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
	
	# === Gäste werden über Nacht hungrig, durstig und erholen sich ===
	for party: GuestParty in _active:
		for member: GuestMember in party.members:
			var night_hunger = randi_range(15, 40)
			member.saturation = max(0, member.saturation - night_hunger)
			member.thirst = max(0, member.thirst - night_hunger)
			member.fun = max(0, member.fun - 20)
			# Energie wird über Nacht komplett wiederhergestellt
			member.energy = 100

	var moving: Array = []
	
	var dynamic_poi_budget = _get_dynamic_poi_budget()

	# Aktive Gäste: stay_days verringern (TG-Gäste ausschließen – kein Zimmer, kein Countdown)
	for party: GuestParty in _active:
		if party.total_stay_days == 0:
			continue  # TG-Gast: kein stay_days Countdown, Checkout läuft über checkout_event_party()
		party.stay_days -= 1
		
		var def = GuestDefinitions.ALL.get(party.type, {})
		var budget_min: int = def.get("min_daily_budget", 10)
		var budget_max: int = def.get("max_daily_budget", 30)
		var poi_mult: float = def.get("poi_budget_multiplier", 1.0)
		var poi_addition: int = int(dynamic_poi_budget * poi_mult)
		
		party.daily_budget = 0
		
		# Neues Taschengeld für jeden Member individuell anpassen (falls neue POIs gebaut wurden)
		for member: GuestMember in party.members:
			var new_b: int = randi_range(budget_min, budget_max) + poi_addition
			if member.is_child:
				new_b = int(new_b * randf_range(0.2, 0.4))
			
			# Damit es nicht sinkt (falls was abgerissen wurde), nehmen wir das Maximum
			member.daily_budget = max(member.daily_budget, new_b)
			member.spending_budget = member.daily_budget
			party.daily_budget += member.daily_budget
			
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

# =============================================================================
func _on_dev_add_guest_budget(amount: int) -> void:
	for party in _active:
		party.spending_budget += amount
		for member in party.members:
			member.spending_budget += amount
			# Falls daily_budget noch 0 ist (z.B. Tagesgäste vor dem Budget-Fix),
			# wird es ebenfalls gesetzt damit der Tooltip es anzeigen kann
			if member.daily_budget == 0:
				member.daily_budget = amount
	parties_changed.emit()

# =============================================================================
func _get_dynamic_poi_budget() -> int:
	if not is_instance_valid(_map_grid):
		return 0
		
	var total_cost: int = 0
	var seen_poi_types = {}
	
	for room in _map_grid.get_placed_rooms():
		if room.has_method("get_definition"):
			var def = room.get_definition()
			if def.get("is_poi") == true:
				var r_id = def.get("id", "")
				
				if r_id == "" or seen_poi_types.has(r_id):
					continue
					
				seen_poi_types[r_id] = true
				
				if r_id == "restaurant_small":
					total_cost += 25
				elif r_id == "lobby":
					total_cost += 5
				else:
					total_cost += def.get("visit_income", 0)
					
	return total_cost
