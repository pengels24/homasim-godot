extends Node
class_name GuestManager
## ANG-162 – Spawn, Patience, Matching-Daten, Check-in/out.
## Wird via configure() aus Ingame.gd verdrahtet.

signal parties_changed()
signal checkout_forgotten(count: int)

# ── Konfiguration ─────────────────────────────────────────────────────────────
var _hotel:    Dictionary
var _clock:    IngameClock
var _map_grid: Node2D

# ── Listen ────────────────────────────────────────────────────────────────────
var _waiting:  Array = []   # Array[GuestParty]
var _active:   Array = []   # Array[GuestParty]
var _checkout: Array = []   # Array[GuestParty]

# room_number → party_id; zeigt welches Zimmer belegt ist
var _room_assign: Dictionary = {}

# ── Zustand ───────────────────────────────────────────────────────────────────
var _next_party_id: int   = 1
var _next_member_id: int  = 1
var _patience_rate: float = 0.05   # 5 % pro Spielstunde; über Settings anpassbar


# ── Setup ─────────────────────────────────────────────────────────────────────

var _room_definitions: Dictionary = {}

func configure(hotel: Dictionary, clock: IngameClock, map_grid: Node2D) -> void:
	_hotel    = hotel
	_clock    = clock
	_map_grid = map_grid
	# Sicherer Start: Dictionary bleibt leer, wenn keine Räume da sind.
	_room_definitions = {}


func set_patience_rate(rate: float) -> void:
	_patience_rate = rate


# ── Öffentliche Abfragen ──────────────────────────────────────────────────────

func get_waiting()  -> Array: return _waiting
func get_active()   -> Array: return _active
func get_checkout() -> Array: return _checkout


func get_party(party_id: String) -> GuestParty:
	for p: GuestParty in _waiting + _active + _checkout:
		if p.id == party_id:
			return p
	return null


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


## Eindeutiger Schlüssel für ein Zimmer: room_number wenn vergeben, sonst Positions-Key.
static func _room_key(room: Node2D) -> String:
	var rnum: String = str(room.get("room_number"))
	if rnum != "" and rnum != "null":
		return rnum
	return "%s_%d_%d" % [str(room.get("room_type_id")), int(room.get("x_pos")), int(room.get("y_pos"))]


# ── Spawn ─────────────────────────────────────────────────────────────────────

func on_hour_passed(_hour: int) -> void:
	_tick_patience()


## Spawnt eine neue Gästewelle; gibt die Anzahl der generierten Parteien zurück.
## Wird vom Ingame-Tagesplaner (DAILY_SCHEDULE) aufgerufen.
func spawn_guests() -> int:
	var count := randi_range(1, 3)
	for _i in count:
		var party := _generate_party()
		_waiting.append(party)
		ActivityLog.add(
			"guest_arrived",
			"Neuer Gast: %s (%s)" % [party.get_display_name(), party.get_type_name()],
			_hotel.get("day", 1),
			_clock.get_game_time(),
		)
	_clock.pause()
	parties_changed.emit()
	return count


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


func _generate_party() -> GuestParty:
	var type_id  := _weighted_random_type()
	var party_id := "P%04d" % _next_party_id
	_next_party_id += 1

	var party := GuestParty.new(party_id, type_id)
	var def: Dictionary = GuestDefinitions.ALL[type_id]
	party.stay_days    = randi_range(def["min_stay"], def["max_stay"])
	party.base_price   = randf_range(def["min_base_price"], def["max_base_price"])
	party.arrived_day  = _hotel.get("day", 1)
	party.arrived_time = _clock.get_game_time()

	match type_id:
		"couple":
			var last := NameDatabase.random_last()
			_add_member(party, NameDatabase.random_male(),   last, "primary")
			_add_member(party, NameDatabase.random_female(), last, "partner")
		"family":
			var last := NameDatabase.random_last()
			_add_member(party, NameDatabase.random_male(),   last, "primary")
			_add_member(party, NameDatabase.random_female(), last, "partner")
			var child_count := randi_range(1, 3)
			for _c in child_count:
				_add_member(party, NameDatabase.random_child(), last, "child")
		_:
			var last  := NameDatabase.random_last()
			var first := NameDatabase.random_male() if randf() > 0.5 else NameDatabase.random_female()
			_add_member(party, first, last, "primary")

	return party


func _add_member(party: GuestParty, first: String, last: String, role: String) -> void:
	var m := GuestMember.new(
		"M%04d" % _next_member_id,
		party.id,
		"%s %s" % [first, last],
		role,
	)
	_next_member_id += 1
	party.members.append(m)


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
		_waiting.erase(party)
		party.state = "gone"
		ActivityLog.add(
			"guest_left",
			"%s hat das Hotel verlassen (Geduld erschöpft)" % party.get_display_name(),
			_hotel.get("day", 1),
			_clock.get_game_time(),
		)

	if not left_ids.is_empty():
		parties_changed.emit()


# ── Check-in ──────────────────────────────────────────────────────────────────

## Gibt den Match-Typ zurück: "perfect" | "ask_price" | "ask_requirements" | "disabled"
func get_match_type(party: GuestParty, room: Node2D) -> String:
	var def:   Dictionary = party.get_type_def()
	var rtype: String = str(room.get("room_type_id"))

	var type_ok:  bool = rtype in def.get("allowed_rooms",   [])
	var preferred: bool = rtype in def.get("preferred_rooms", [])
	var reqs_met: bool = _check_requirements(room, def.get("requirements", []))

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


func roll_ask(party: GuestParty, room: Node2D) -> bool:
	var def: Dictionary = party.get_type_def()
	var preferred: bool = str(room.get("room_type_id")) in def.get("preferred_rooms", [])
	# Aufpreis: 60 %, fehlende Ausstattung: 70 %
	var chance := 0.6 if not preferred else 0.7
	return randf() <= chance


func do_checkin(party: GuestParty, room: Node2D) -> void:
	var rid       := _room_key(room)
	party.room_id  = rid
	party.state    = "active"
	_waiting.erase(party)
	_active.append(party)
	_room_assign[rid] = party.id
	ActivityLog.add(
		"check_in",
		"Check-in: %s → %s" % [party.get_display_name(), str(room.get("room_number"))],
		_hotel.get("day", 1),
		_clock.get_game_time(),
	)
	parties_changed.emit()


func reject_party(party: GuestParty) -> void:
	party.state = "gone"
	_waiting.erase(party)
	ActivityLog.add(
		"guest_rejected",
		"%s wurde abgelehnt" % party.get_display_name(),
		_hotel.get("day", 1),
		_clock.get_game_time(),
	)
	parties_changed.emit()


# ── Checkout ──────────────────────────────────────────────────────────────────

func do_checkout(party: GuestParty) -> float:
	var payout := _calculate_payout(party)
	_finalize_checkout(party, payout, false)
	return payout


func _finalize_checkout(party: GuestParty, payout: float, auto: bool) -> void:
	_checkout.erase(party)
	_room_assign.erase(party.room_id)
	party.state = "gone"
	var msg := "Check-out: %s (%s €)" % [party.get_display_name(), "%.0f" % payout]
	if auto:
		msg += " [Auto-Checkout]"
	ActivityLog.add(
		"check_out" if not auto else "check_out_auto",
		msg,
		_hotel.get("day", 1),
		_clock.get_game_time(),
	)
	if payout > 0.0:
		_hotel["money"] = _hotel.get("money", 0.0) + payout
	parties_changed.emit()


func _calculate_payout(party: GuestParty) -> float:
	return party.base_price * float(party.stay_days) * party.satisfaction


# ── Tagesende ─────────────────────────────────────────────────────────────────

func on_day_ended(new_day: int) -> void:
	# 1. Alle wartenden Gäste verlassen das Hotel
	for party: GuestParty in _waiting:
		party.state = "gone"
		ActivityLog.add(
			"guest_left",
			"%s hat das Hotel verlassen (Tagesende)" % party.get_display_name(),
			new_day - 1,
			_clock.get_game_time(),
		)
	_waiting.clear()

	# 2. Vergessene Checkouts verarbeiten
	var forgotten_count := _checkout.size()
	var to_auto: Array  = []
	for party: GuestParty in _checkout:
		party.checkout_days += 1
		if party.checkout_days >= 2:
			to_auto.append(party)
		else:
			# Erste Vergessen-Strafe: Zufriedenheit -20 %, Preis -10–50 %
			party.satisfaction = maxf(0.0, party.satisfaction - 0.2)
			party.base_price  *= randf_range(0.5, 0.9)

	for party: GuestParty in to_auto:
		_finalize_checkout(party, 0.0, true)

	if forgotten_count > 0:
		checkout_forgotten.emit(forgotten_count)

	# 3. Aktive Gäste: stay_days verringern, fällige in Checkout verschieben
	var moving: Array = []
	for party: GuestParty in _active:
		party.stay_days -= 1
		if party.stay_days <= 0:
			moving.append(party)

	for party: GuestParty in moving:
		_active.erase(party)
		party.state = "checkout"
		_checkout.append(party)

	parties_changed.emit()


# ── Serialisierung ────────────────────────────────────────────────────────────

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

func _check_requirements(_room: Node2D, reqs: Array) -> bool:
	if reqs.is_empty():
		return true
	# Räume haben noch kein Requirements-System – für jetzt immer false wenn Reqs vorhanden
	# wird erweitert wenn Room-Ausstattung implementiert ist
	return false
