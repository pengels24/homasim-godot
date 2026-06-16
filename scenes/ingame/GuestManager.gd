extends Node
class_name GuestManager

signal parties_changed()
signal checkout_forgotten(count: int)
signal sig_party_checked_in(party: GuestParty, room: Node2D) # <--- NEU
signal sig_party_moving_to_checkout(party: GuestParty, room_id: String)
signal sig_party_checked_out_physically(party: GuestParty)

# ── Konfiguration ─────────────────────────────────────────────────────────────
var _hotel:    Dictionary
var _map_grid: Node2D

# ── Listen ────────────────────────────────────────────────────────────────────
var _waiting:  Array = []   # Array[GuestParty]
var _active:   Array = []   # Array[GuestParty]
var _checkout: Array = []   # Array[GuestParty]

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
# todo - muss noch in settings
var _patience_rate: float = 0.05   # 5 % pro Spielstunde; über Settings anpassbar

# ── Setup ─────────────────────────────────────────────────────────────────────
var _room_definitions: Dictionary = {}


# =============================================================================
func configure(hotel: Dictionary, map_grid: Node2D) -> void:
	_hotel    = hotel
	_map_grid = map_grid
	# Sicherer Start: Dictionary bleibt leer, wenn keine Räume da sind.
	_room_definitions = {}

	GameState.sig_dev_spawn_guests.connect(func(count: int): spawn_guests(count))

	# NEU: Auf die Uhr hören!
	if not TimeManager.sig_midnight_struck.is_connected(process_midnight_penalties):
		TimeManager.sig_midnight_struck.connect(process_midnight_penalties)

	if not TimeManager.sig_morning_struck.is_connected(process_morning_routine):
		TimeManager.sig_morning_struck.connect(process_morning_routine)


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

	if rnum != "" and rnum != "null":
		return rnum

	return "%s_%d_%d" % [str(room.get("room_type_id")), int(room.get("x_pos")), int(room.get("y_pos"))]


# ── Spawn ─────────────────────────────────────────────────────────────────────

# =============================================================================
func on_hour_passed(_hour: int) -> void:
	_tick_patience()


# =============================================================================
## Spawnt eine neue Gästewelle.
## Ist amount = -1 (Standard), wird eine zufällige Anzahl (1-3) generiert.
## Gibt die Anzahl der generierten KÖPFE (Gäste) zurück.
func spawn_guests(amount: int = -1) -> int:
	# Wenn kein bestimmter Wert übergeben wird, nimm Zufall
	var party_count := amount if amount > 0 else randi_range(1, 3)
	var total_heads := 0

	for _i in party_count:
		var party := _generate_party()
		_waiting.append(party)

		# Zählt die tatsächlichen Personen in der Gruppe
		total_heads += party.members.size()

		ActivityLog.add(
			"guest_arrived",
			"Neuer Gast: %s (%s)" % [party.get_display_name(), party.get_type_name()],
			_hotel.get("day", 1),
			TimeManager.get_game_time(),
		)

	TimeManager.pause()
	parties_changed.emit()

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
func _generate_party() -> GuestParty:
	var type_id  := _weighted_random_type()
	var party_id := "P%04d" % _next_party_id
	_next_party_id += 1

	var party := GuestParty.new(party_id, type_id)
	var def: Dictionary = GuestDefinitions.ALL[type_id]
	party.stay_days = randi_range(def["min_stay"], def["max_stay"])
	party.total_stay_days = party.stay_days
	party.base_price = randi_range(def["min_base_price"], def["max_base_price"])
	party.arrived_day = _hotel.get("day", 1)
	party.arrived_time = TimeManager.get_game_time()

	match type_id:
		"couple":
			var last := NameDatabase.random_last()
			_add_member(party, NameDatabase.random_male(),   last, "primary", "male", false)
			_add_member(party, NameDatabase.random_female(), last, "partner", "female", false)

		"family":
			var last := NameDatabase.random_last()
			_add_member(party, NameDatabase.random_male(),   last, "primary", "male", false)
			_add_member(party, NameDatabase.random_female(), last, "partner", "female", false)
			var child_count := randi_range(1, 3)

			for _c in child_count:
				var is_boy: bool = randf() > 0.5
				var child_gender: String = "male" if is_boy else "female"
				_add_member(party, NameDatabase.random_child(), last, "child", child_gender, true)

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
	var total := 0

	for key: String in GuestDefinitions.ALL:
		total += int(GuestDefinitions.ALL[key]["spawn_chance"])

	var roll := randi() % total
	var acc  := 0

	for key: String in GuestDefinitions.ALL:
		acc += int(GuestDefinitions.ALL[key]["spawn_chance"])

		if roll < acc:
			return key

	return "single"


# ── Patience ──────────────────────────────────────────────────────────────────

# =============================================================================
func _tick_patience() -> void:
	var left_ids: Array = []

	for party: GuestParty in _waiting:
		party.patience -= _patience_rate

		if party.patience <= 0.45:
			left_ids.append(party.id)

	for pid: String in left_ids:
		var party := get_party(pid)

		if party == null:
			continue

		# NEU: Statistik füttern
		daily_timeout_parties += 1
		daily_timeout_heads += party.members.size()

		_waiting.erase(party)
		party.state = "gone"
		ActivityLog.add(
			"guest_left",
			"%s hat das Hotel verlassen (Geduld erschöpft)" % party.get_display_name(),
			_hotel.get("day", 1),
			# _clock.get_game_time(),
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

	# todo MÄNGEL-SYSTEM PAUSIERT: Wir setzen reqs_met hart auf true,
	# bis das Ausstattungs-Feature fertig ist.
	# var reqs_met: bool = _check_requirements(room, def.get("requirements", []))
	var reqs_met: bool = true

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
	var rid       := _room_key(room)
	party.room_id  = rid
	party.state    = "active"
	_waiting.erase(party)
	_active.append(party)
	_room_assign[rid] = party.id

	# NEU: Statistik füttern
	daily_checkin_parties += 1
	daily_checkin_heads += party.members.size()

	ActivityLog.add(
		"check_in",
		"Check-in: %s → %s" % [party.get_display_name(), str(room.get("room_number"))],
		_hotel.get("day", 1),
		TimeManager.get_game_time(),
	)
	sig_party_checked_in.emit(party, room) # <--- NEU: Ruf an die Welt
	parties_changed.emit()


# =============================================================================
func reject_party(party: GuestParty) -> void:
	party.state = "gone"
	_waiting.erase(party)

	# NEU: Statistik füttern
	daily_reject_parties += 1
	daily_reject_heads += party.members.size()

	ActivityLog.add(
		"guest_rejected",
		"%s wurde abgelehnt" % party.get_display_name(),
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
		var penalty: int = GameState.calc_reject_rep_penalty(party)
		total_penalty += penalty
		party.state = "gone"

		ActivityLog.add(
			"guest_rejected",
			"%s ist wütend abgereist (Rezeption geschlossen)" % party.get_display_name(),
			_hotel.get("day", 1),
			TimeManager.get_game_time()
		)

	# Liste leeren und UI benachrichtigen
	_waiting.clear()
	parties_changed.emit()

	# Ruf abziehen und Toast für den Spieler anzeigen
	if total_penalty > 0:
		GameState.add_rep(-total_penalty)
		Toast.show("%d Gästegruppen wütend abgereist! (-%d Ruf)" % [kicked_count, total_penalty])

# ── Checkout ──────────────────────────────────────────────────────────────────

# =============================================================================
func do_checkout(party: GuestParty) -> float:
	var payout := _calculate_payout(party)
	_finalize_checkout(party, int(payout), false)

	return payout


# =============================================================================
func _finalize_checkout(party: GuestParty, payout: int, auto: bool) -> void:
	_checkout.erase(party)
	
	# TODO(Cleaning): Wenn wir das Personal-System (Housekeeping) haben, darf das Zimmer 
	# hier NICHT sofort wieder freigegeben werden. Es muss den Status "needs_cleaning"
	# erhalten. Erst wenn die Reinigungskraft fertig ist, darf es aus _room_assign gelöscht 
	# (oder als "clean" markiert) und wieder buchbar werden!
	_room_assign.erase(party.room_id)
	
	party.state = "gone"
	
	if not auto:
		sig_party_checked_out_physically.emit(party)

	var msg := ""
	var log_type := "check_out"

	# NEU: Unterscheidung für den Wut-Checkout inkl. getrennter Statistik
	if auto and payout == 0:
		msg = "Wut-Checkout: %s ist wütend abgereist (0 €)" % party.get_display_name()
		log_type = "rage_quit"

		daily_rage_parties += 1
		daily_rage_heads += party.members.size()
	else:
		msg = "Check-out: %s (%d €)" % [party.get_display_name(), payout]
		if auto:
			msg += " [Auto-Checkout]"
			log_type = "check_out_auto"

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
		var desc := "Checkout: " + party.get_display_name()
		FinanceManager.add_transaction(payout, category, desc)

	parties_changed.emit()


# =============================================================================
func _calculate_payout(party: GuestParty) -> float:
	return party.base_price * float(party.total_stay_days) * (party.satisfaction / 100.0)


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
		"waiting":        w,
		"active":         a,
		"checkout":       c,
		"room_assign":    _room_assign.duplicate(),
		"next_party_id":  _next_party_id,
		"next_member_id": _next_member_id,
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
	_room_assign    = d.get("room_assign",    {})
	_next_party_id  = d.get("next_party_id",  1)
	_next_member_id = d.get("next_member_id", 1)
	parties_changed.emit()


# ── Hilfsmethoden ─────────────────────────────────────────────────────────────

# =============================================================================
func _check_requirements(_room: Node2D, reqs: Array) -> bool:
	if reqs.is_empty():
		return true

	# Räume haben noch kein Requirements-System – für jetzt immer false wenn Reqs vorhanden
	# wird erweitert wenn Room-Ausstattung implementiert ist
	return false


# =============================================================================
## Wird um 23:59 Uhr aufgerufen (VOR dem Tagesabschluss-Modal)
func process_midnight_penalties(day: int) -> void:
	# 1. Wartende Gäste an der Eingangstür verjagen
	for party: GuestParty in _waiting:
		party.state = "gone"
		ActivityLog.add(
			"guest_left",
			"%s hat das Hotel verlassen (Tagesende)" % party.get_display_name(),
			day,
			TimeManager.get_game_time(),
		)
	_waiting.clear()

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
			Toast.show("%d Gäste sind wütend abgereist! (0 €)" % forgotten_count)

	parties_changed.emit()


# =============================================================================
## Wird um 06:00 Uhr aufgerufen (Wenn der neue Tag physisch beginnt)
func process_morning_routine() -> void:
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

	var moving: Array = []

	# Aktive Gäste: stay_days verringern
	for party: GuestParty in _active:
		party.stay_days -= 1

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
	_waiting.erase(party)

	# NEU: Statistik für gescheiterte Verhandlungen
	daily_declined_parties += 1
	daily_declined_heads += party.members.size()

	ActivityLog.add(
		"guest_declined",
		"%s hat das Angebot abgelehnt und ist abgereist" % party.get_display_name(),
		_hotel.get("day", 1),
		TimeManager.get_game_time()
	)

	parties_changed.emit()