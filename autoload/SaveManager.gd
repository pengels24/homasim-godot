extends Node
## Lokales Save-System via FileAccess (Godot Binary Format).
## Kein Login erforderlich. Zuständigkeit: Profiles, Hotels, Plots laden/speichern.

# ── Konstanten ────────────────────────────────────────────────────────────────
const SAVE_PATH := "user://homasim.sav"

# ── State ─────────────────────────────────────────────────────────────────────
var _data: Dictionary = {}


# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_load()


# ── Profile ───────────────────────────────────────────────────────────────────

func get_profiles() -> Array:
	return _data.get("profiles", [])


func create_profile(profile_name: String) -> int:
	var profiles: Array = get_profiles()
	var new_id: int     = _next_id(profiles)
	profiles.append({ "id": new_id, "name": profile_name })
	_data["profiles"] = profiles
	_save()
	return new_id


# ── Hotels ────────────────────────────────────────────────────────────────────

func get_hotels(profile_id: int) -> Array:
	return _data.get("hotels", []).filter(
		func(h: Dictionary) -> bool: return h["profile_id"] == profile_id
	)


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


# ── Plots ─────────────────────────────────────────────────────────────────────

func get_plots(hotel_id: int) -> Array:
	return get_hotel(hotel_id).get("plots", [])


func get_built_plots(hotel_id: int) -> Array:
	return get_plots(hotel_id).filter(
		func(p: Dictionary) -> bool: return p["is_built"]
	)


func delete_hotel(hotel_id: int) -> void:
	_data["hotels"] = _data.get("hotels", []).filter(
		func(h: Dictionary) -> bool: return h["id"] != hotel_id
	)
	_save()


func set_plot_built(hotel_id: int, x: int, y: int, entrance_dir: String = "") -> void:
	for p in get_plots(hotel_id):
		if p["x"] == x and p["y"] == y:
			p["is_built"]     = true
			p["entrance_dir"] = entrance_dir
			break
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
			})
	return plots


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
