extends Node
## ANG-175 – Lokales Save-System via FileAccess (Godot Binary Format).
## Kein Login erforderlich. Zuständigkeit: Profiles, Hotels, Plots, Räume, Save-Slots.

# ── Konstanten ────────────────────────────────────────────────────────────────
const SAVE_PATH      := "user://homasim.sav"
const MAX_AUTOSAVES  := 10
const MAX_HOTELS     := 5
const MANUAL_SLOTS   := 3

# ── State ─────────────────────────────────────────────────────────────────────
var _data: Dictionary = {}


# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_load()


# ── Profile ───────────────────────────────────────────────────────────────────

func get_profiles() -> Array:
	return _data.get("profiles", [])


func create_profile(profile_name: String, appearance: Dictionary = {}) -> int:
	var profiles: Array = get_profiles()
	var new_id: int     = _next_id(profiles)
	var profile         := { "id": new_id, "name": profile_name }
	profile.merge(appearance)
	profiles.append(profile)
	_data["profiles"] = profiles
	_save()
	return new_id


func get_profile(profile_id: int) -> Dictionary:
	for p in _data.get("profiles", []):
		if p["id"] == profile_id:
			return p
	return {}


func delete_profile(profile_id: int) -> void:
	_data["profiles"] = _data.get("profiles", []).filter(
		func(p: Dictionary) -> bool: return p["id"] != profile_id
	)
	_data["hotels"] = _data.get("hotels", []).filter(
		func(h: Dictionary) -> bool: return h["profile_id"] != profile_id
	)
	_save()


# ── Hotels ────────────────────────────────────────────────────────────────────

func get_hotels(profile_id: int) -> Array:
	return _data.get("hotels", []).filter(
		func(h: Dictionary) -> bool: return h["profile_id"] == profile_id
	)


func can_create_hotel(profile_id: int) -> bool:
	return get_hotels(profile_id).size() < MAX_HOTELS


func create_hotel(profile_id: int, hotel_name: String, cols: int = 5, rows: int = 5) -> int:
	var hotels: Array = _data.get("hotels", [])
	var new_id: int   = _next_id(hotels)
	hotels.append({
		"id":         new_id,
		"profile_id": profile_id,
		"name":       hotel_name,
		"grid_cols":  cols,
		"grid_rows":  rows,
		"day":        1,
		"money":      50000.0,
		"game_time":  360,
		"plots":      _init_plots(cols, rows),
		"saves":      _default_saves(),
	})
	_data["hotels"] = hotels
	_save()
	return new_id


func get_hotel(hotel_id: int) -> Dictionary:
	for h in _data.get("hotels", []):
		if h["id"] == hotel_id:
			return h
	return {}


func update_hotel(hotel_id: int, fields: Dictionary) -> void:
	for h in _data.get("hotels", []):
		if h["id"] == hotel_id:
			for key in fields:
				h[key] = fields[key]
			break
	_save()


func delete_hotel(hotel_id: int) -> void:
	_data["hotels"] = _data.get("hotels", []).filter(
		func(h: Dictionary) -> bool: return h["id"] != hotel_id
	)
	_save()


# ── Plots ─────────────────────────────────────────────────────────────────────

func get_plots(hotel_id: int) -> Array:
	return get_hotel(hotel_id).get("plots", [])


func get_built_plots(hotel_id: int) -> Array:
	return get_plots(hotel_id).filter(
		func(p: Dictionary) -> bool: return p["is_built"]
	)


func set_plot_built(hotel_id: int, x: int, y: int, entrance_dir: String = "") -> void:
	for p in get_plots(hotel_id):
		if p["x"] == x and p["y"] == y:
			p["is_built"]     = true
			p["entrance_dir"] = entrance_dir
			break
	_save()


# ── Räume ─────────────────────────────────────────────────────────────────────

func save_room_to_plot(hotel_id: int, parcel_x: int, parcel_y: int, room_dict: Dictionary) -> void:
	for p in get_plots(hotel_id):
		if p["x"] == parcel_x and p["y"] == parcel_y:
			var rooms: Array = p.get("rooms", [])
			rooms.append(room_dict)
			p["rooms"] = rooms
			break
	_save()


# ── Save-Slots ────────────────────────────────────────────────────────────────

func get_save_slots(hotel_id: int) -> Dictionary:
	var hotel := get_hotel(hotel_id)
	if hotel.is_empty():
		return _default_saves()
	return hotel.get("saves", _default_saves())


## Quicksave – Snapshot des aktuellen Spielstands.
func save_quick(hotel_id: int) -> void:
	var hotel := get_hotel(hotel_id)
	if hotel.is_empty():
		return
	var saves: Dictionary = hotel.get("saves", _default_saves())
	saves["quick"] = _take_snapshot(hotel, "Quicksave")
	hotel["saves"] = saves
	_save()


## Quickload – stellt den letzten Quicksave wieder her.
## Gibt true zurück wenn ein Quicksave vorhanden war.
func load_quick(hotel_id: int) -> bool:
	var hotel := get_hotel(hotel_id)
	if hotel.is_empty():
		return false
	var saves: Dictionary = hotel.get("saves", _default_saves())
	var snap = saves.get("quick", null)
	if snap == null:
		return false
	_apply_snapshot(hotel, snap)
	_save()
	return true


## Manueller Save – 3 Slots (0-2), mit benutzerdefiniertem Namen.
func save_manual(hotel_id: int, slot: int, save_name: String) -> void:
	if slot < 0 or slot >= MANUAL_SLOTS:
		return
	var hotel := get_hotel(hotel_id)
	if hotel.is_empty():
		return
	var saves: Dictionary = hotel.get("saves", _default_saves())
	var manual: Array = saves.get("manual", _empty_manual())
	while manual.size() < MANUAL_SLOTS:
		manual.append(null)
	manual[slot] = _take_snapshot(hotel, save_name)
	saves["manual"] = manual
	hotel["saves"] = saves
	_save()


## Manueller Load. Gibt true zurück wenn der Slot gefüllt war.
func load_manual(hotel_id: int, slot: int) -> bool:
	if slot < 0 or slot >= MANUAL_SLOTS:
		return false
	var hotel := get_hotel(hotel_id)
	if hotel.is_empty():
		return false
	var saves: Dictionary = hotel.get("saves", _default_saves())
	var manual: Array = saves.get("manual", _empty_manual())
	if slot >= manual.size():
		return false
	var snap = manual[slot]
	if snap == null:
		return false
	_apply_snapshot(hotel, snap)
	_save()
	return true


## Autosave – rotierend, maximal MAX_AUTOSAVES Einträge.
func save_auto(hotel_id: int) -> void:
	var hotel := get_hotel(hotel_id)
	if hotel.is_empty():
		return
	var saves: Dictionary = hotel.get("saves", _default_saves())
	var auto_list: Array = saves.get("auto", [])
	auto_list.push_front(_take_snapshot(hotel, "Autosave"))
	if auto_list.size() > MAX_AUTOSAVES:
		auto_list.resize(MAX_AUTOSAVES)
	saves["auto"] = auto_list
	hotel["saves"] = saves
	_save()


## Autosave laden (Index 0 = neuester).
func load_auto(hotel_id: int, index: int) -> bool:
	var hotel := get_hotel(hotel_id)
	if hotel.is_empty():
		return false
	var saves: Dictionary = hotel.get("saves", _default_saves())
	var auto_list: Array = saves.get("auto", [])
	if index < 0 or index >= auto_list.size():
		return false
	_apply_snapshot(hotel, auto_list[index])
	_save()
	return true


## Einzelnen Save-Slot löschen.
## slot_type: "quick" | "manual" | "auto"
func delete_save(hotel_id: int, slot_type: String, slot_idx: int = 0) -> void:
	var hotel := get_hotel(hotel_id)
	if hotel.is_empty():
		return
	var saves: Dictionary = hotel.get("saves", _default_saves())
	match slot_type:
		"quick":
			saves["quick"] = null
		"manual":
			var manual: Array = saves.get("manual", _empty_manual())
			if slot_idx < manual.size():
				manual[slot_idx] = null
			saves["manual"] = manual
		"auto":
			var auto_list: Array = saves.get("auto", [])
			if slot_idx < auto_list.size():
				auto_list.remove_at(slot_idx)
			saves["auto"] = auto_list
	hotel["saves"] = saves
	_save()


# ── Privat ────────────────────────────────────────────────────────────────────

func _init_plots(cols: int, rows: int) -> Array:
	var plots: Array = []
	for row in rows:
		for col in cols:
			plots.append({
				"x":            col,
				"y":            row,
				"is_built":     false,
				"entrance_dir": "",
				"rooms":        [],
			})
	return plots


func _default_saves() -> Dictionary:
	return { "quick": null, "manual": _empty_manual(), "auto": [] }


func _empty_manual() -> Array:
	var arr: Array = []
	for _i in MANUAL_SLOTS:
		arr.append(null)
	return arr


## Tiefe Kopie des aktuellen Hotel-Zustands als Snapshot.
func _take_snapshot(hotel: Dictionary, snap_name: String) -> Dictionary:
	return {
		"name":      snap_name,
		"timestamp": int(Time.get_unix_time_from_system()),
		"day":       hotel.get("day",       1),
		"money":     hotel.get("money",     0.0),
		"game_time": hotel.get("game_time", 360),
		"plots":     hotel.get("plots",     []).duplicate(true),
	}


## Snapshot auf das Hotel anwenden (stellt Spielstand wieder her).
func _apply_snapshot(hotel: Dictionary, snap: Dictionary) -> void:
	hotel["day"]       = snap.get("day",       1)
	hotel["money"]     = snap.get("money",     0.0)
	hotel["game_time"] = snap.get("game_time", 360)
	hotel["plots"]     = snap.get("plots",     []).duplicate(true)


func _next_id(list: Array) -> int:
	var max_id: int = 0
	for item in list:
		if item.get("id", 0) > max_id:
			max_id = item["id"]
	return max_id + 1


func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(_data)


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_data = { "profiles": [], "hotels": [] }
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	_data = file.get_var()
