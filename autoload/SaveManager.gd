extends Node
## ANG-184 – Save-System auf Einzeldateien umgestellt (ConfigFile + binäre Snapshots).
## Jedes Hotel = eigene .cfg, jeder Save-Slot = eigene .sav.
## API-Oberfläche identisch zu vorher.

# ── Konstanten ────────────────────────────────────────────────────────────────
const PROFILES_PATH := "user://profiles.cfg"
const HOTELS_DIR    := "user://hotels/"
const SAVES_DIR     := "user://saves/"
const MAX_AUTOSAVES := 10
const MAX_HOTELS    := 5
const MANUAL_SLOTS  := 3

# ── State ─────────────────────────────────────────────────────────────────────
var _profiles:        Array = []
var _hotels:          Array = []
var _next_profile_id: int   = 1
var _next_hotel_id:   int   = 1


# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_ensure_dirs()
	_load_profiles()
	_load_all_hotels()


# ── Profile ───────────────────────────────────────────────────────────────────

func get_profiles() -> Array:
	return _profiles


func create_profile(profile_name: String, appearance: Dictionary = {}) -> int:
	var new_id := _next_profile_id
	_next_profile_id += 1
	var profile := { "id": new_id, "name": profile_name }
	profile.merge(appearance)
	_profiles.append(profile)
	_save_profiles()
	return new_id


func get_profile(profile_id: int) -> Dictionary:
	for p in _profiles:
		if p["id"] == profile_id:
			return p
	return {}


func delete_profile(profile_id: int) -> void:
	_profiles = _profiles.filter(func(p: Dictionary) -> bool: return p["id"] != profile_id)
	var to_delete: Array = _hotels.filter(
		func(h: Dictionary) -> bool: return h["profile_id"] == profile_id)
	for h in to_delete:
		_delete_hotel_files(h["id"])
	_hotels = _hotels.filter(func(h: Dictionary) -> bool: return h["profile_id"] != profile_id)
	_save_profiles()


# ── Hotels ────────────────────────────────────────────────────────────────────

func get_hotels(profile_id: int) -> Array:
	return _hotels.filter(func(h: Dictionary) -> bool: return h["profile_id"] == profile_id)


func can_create_hotel(profile_id: int) -> bool:
	return get_hotels(profile_id).size() < MAX_HOTELS


func create_hotel(profile_id: int, hotel_name: String, cols: int = 5, rows: int = 5) -> int:
	var new_id := _next_hotel_id
	_next_hotel_id += 1
	var hotel := {
		"id":         new_id,
		"profile_id": profile_id,
		"name":       hotel_name,
		"grid_cols":  cols,
		"grid_rows":  rows,
		"day":        1,
		"money":      50000.0,
		"game_time":  360,
		"plots":      _init_plots(cols, rows),
		"auto_count": 0,
	}
	_hotels.append(hotel)
	_save_profiles()
	_save_hotel(hotel)
	return new_id


func get_hotel(hotel_id: int) -> Dictionary:
	for h in _hotels:
		if h["id"] == hotel_id:
			return h
	return {}


func update_hotel(hotel_id: int, fields: Dictionary) -> void:
	for h in _hotels:
		if h["id"] == hotel_id:
			for key in fields:
				h[key] = fields[key]
			_save_hotel(h)
			return


func delete_hotel(hotel_id: int) -> void:
	_hotels = _hotels.filter(func(h: Dictionary) -> bool: return h["id"] != hotel_id)
	_delete_hotel_files(hotel_id)


# ── Plots ─────────────────────────────────────────────────────────────────────

func get_plots(hotel_id: int) -> Array:
	return get_hotel(hotel_id).get("plots", [])


func get_built_plots(hotel_id: int) -> Array:
	return get_plots(hotel_id).filter(func(p: Dictionary) -> bool: return p["is_built"])


func set_plot_built(hotel_id: int, x: int, y: int, entrance_dir: String = "") -> void:
	var hotel := get_hotel(hotel_id)
	for p in hotel.get("plots", []):
		if p["x"] == x and p["y"] == y:
			p["is_built"]     = true
			p["entrance_dir"] = entrance_dir
			break
	_save_hotel(hotel)


# ── Räume ─────────────────────────────────────────────────────────────────────

func save_room_to_plot(hotel_id: int, parcel_x: int, parcel_y: int, room_dict: Dictionary) -> void:
	var hotel := get_hotel(hotel_id)
	for p in hotel.get("plots", []):
		if p["x"] == parcel_x and p["y"] == parcel_y:
			var rooms: Array = p.get("rooms", [])
			rooms.append(room_dict)
			p["rooms"] = rooms
			break
	_save_hotel(hotel)


# ── Save-Slots ────────────────────────────────────────────────────────────────

func get_save_slots(hotel_id: int) -> Dictionary:
	var hotel  := get_hotel(hotel_id)
	var result := _default_saves()
	var qs     := _read_snapshot(_save_path_quick(hotel_id))
	result["quick"] = qs if not qs.is_empty() else null
	for i in MANUAL_SLOTS:
		var ms := _read_snapshot(_save_path_manual(hotel_id, i))
		result["manual"][i] = ms if not ms.is_empty() else null
	var auto_count: int = hotel.get("auto_count", 0)
	result["auto"].resize(auto_count)
	for i in auto_count:
		result["auto"][i] = _read_snapshot(_save_path_auto(hotel_id, i))
	return result


func save_quick(hotel_id: int) -> void:
	var hotel := get_hotel(hotel_id)
	if hotel.is_empty():
		return
	_write_snapshot(_save_path_quick(hotel_id), _take_snapshot(hotel, "Quicksave"))


func load_quick(hotel_id: int) -> bool:
	var hotel := get_hotel(hotel_id)
	if hotel.is_empty():
		return false
	var snap := _read_snapshot(_save_path_quick(hotel_id))
	if snap.is_empty():
		return false
	_apply_snapshot(hotel, snap)
	_save_hotel(hotel)
	return true


func save_manual(hotel_id: int, slot: int, save_name: String) -> void:
	if slot < 0 or slot >= MANUAL_SLOTS:
		return
	var hotel := get_hotel(hotel_id)
	if hotel.is_empty():
		return
	_write_snapshot(_save_path_manual(hotel_id, slot), _take_snapshot(hotel, save_name))


func load_manual(hotel_id: int, slot: int) -> bool:
	if slot < 0 or slot >= MANUAL_SLOTS:
		return false
	var hotel := get_hotel(hotel_id)
	if hotel.is_empty():
		return false
	var snap := _read_snapshot(_save_path_manual(hotel_id, slot))
	if snap.is_empty():
		return false
	_apply_snapshot(hotel, snap)
	_save_hotel(hotel)
	return true


func save_auto(hotel_id: int) -> void:
	var hotel := get_hotel(hotel_id)
	if hotel.is_empty():
		return
	var count: int = hotel.get("auto_count", 0)
	var dir := DirAccess.open(SAVES_DIR)
	if dir:
		var shift_to := mini(count, MAX_AUTOSAVES - 1)
		for i in range(shift_to, 0, -1):
			var src := "hotel_%d_auto_%d.sav" % [hotel_id, i - 1]
			var dst := "hotel_%d_auto_%d.sav" % [hotel_id, i]
			if dir.file_exists(src):
				dir.rename(src, dst)
	_write_snapshot(_save_path_auto(hotel_id, 0), _take_snapshot(hotel, "Autosave"))
	hotel["auto_count"] = mini(count + 1, MAX_AUTOSAVES)
	_save_hotel(hotel)


func load_auto(hotel_id: int, index: int) -> bool:
	var hotel := get_hotel(hotel_id)
	if hotel.is_empty():
		return false
	var auto_count: int = hotel.get("auto_count", 0)
	if index < 0 or index >= auto_count:
		return false
	var snap := _read_snapshot(_save_path_auto(hotel_id, index))
	if snap.is_empty():
		return false
	_apply_snapshot(hotel, snap)
	_save_hotel(hotel)
	return true


func delete_save(hotel_id: int, slot_type: String, slot_idx: int = 0) -> void:
	var dir := DirAccess.open(SAVES_DIR)
	if not dir:
		return
	match slot_type:
		"quick":
			var f := "hotel_%d_quick.sav" % hotel_id
			if dir.file_exists(f):
				dir.remove(f)
		"manual":
			var f := "hotel_%d_manual_%d.sav" % [hotel_id, slot_idx]
			if dir.file_exists(f):
				dir.remove(f)
		"auto":
			var hotel     := get_hotel(hotel_id)
			var count: int = hotel.get("auto_count", 0)
			var f := "hotel_%d_auto_%d.sav" % [hotel_id, slot_idx]
			if dir.file_exists(f):
				dir.remove(f)
			for i in range(slot_idx, count - 1):
				var src := "hotel_%d_auto_%d.sav" % [hotel_id, i + 1]
				var dst := "hotel_%d_auto_%d.sav" % [hotel_id, i]
				if dir.file_exists(src):
					dir.rename(src, dst)
			hotel["auto_count"] = maxi(0, count - 1)
			_save_hotel(hotel)


# ── Pfad-Helfer ───────────────────────────────────────────────────────────────

func _hotel_cfg_path(id: int) -> String:
	return HOTELS_DIR + "hotel_%d.cfg" % id

func _save_path_quick(id: int) -> String:
	return SAVES_DIR + "hotel_%d_quick.sav" % id

func _save_path_manual(id: int, n: int) -> String:
	return SAVES_DIR + "hotel_%d_manual_%d.sav" % [id, n]

func _save_path_auto(id: int, n: int) -> String:
	return SAVES_DIR + "hotel_%d_auto_%d.sav" % [id, n]


# ── Persistenz – Profile ──────────────────────────────────────────────────────

func _load_profiles() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PROFILES_PATH) != OK:
		return
	_next_profile_id = cfg.get_value("meta", "next_profile_id", 1)
	_next_hotel_id   = cfg.get_value("meta", "next_hotel_id",   1)
	_profiles.clear()
	for section in cfg.get_sections():
		if section == "meta":
			continue
		var id:         int        = int(section.trim_prefix("profile_"))
		var name_val:   String     = cfg.get_value(section, "name", "")
		var appearance: Dictionary = cfg.get_value(section, "appearance", {})
		var profile: Dictionary    = { "id": id, "name": name_val }
		profile.merge(appearance)
		_profiles.append(profile)


func _save_profiles() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "next_profile_id", _next_profile_id)
	cfg.set_value("meta", "next_hotel_id",   _next_hotel_id)
	for p in _profiles:
		var section := "profile_%d" % p["id"]
		cfg.set_value(section, "name", p.get("name", ""))
		var appearance := {}
		for key in p:
			if key != "id" and key != "name":
				appearance[key] = p[key]
		cfg.set_value(section, "appearance", appearance)
	cfg.save(PROFILES_PATH)


# ── Persistenz – Hotels ───────────────────────────────────────────────────────

func _load_all_hotels() -> void:
	var dir := DirAccess.open(HOTELS_DIR)
	if not dir:
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".cfg"):
			_load_hotel_file(fname)
		fname = dir.get_next()


func _load_hotel_file(filename: String) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(HOTELS_DIR + filename) != OK:
		return
	var id := int(filename.get_basename().trim_prefix("hotel_"))
	_hotels.append({
		"id":         id,
		"profile_id": cfg.get_value("hotel", "profile_id", 0),
		"name":       cfg.get_value("hotel", "name",       ""),
		"grid_cols":  cfg.get_value("hotel", "grid_cols",  5),
		"grid_rows":  cfg.get_value("hotel", "grid_rows",  5),
		"day":        cfg.get_value("hotel", "day",        1),
		"money":      cfg.get_value("hotel", "money",      50000.0),
		"game_time":  cfg.get_value("hotel", "game_time",  360),
		"plots":      cfg.get_value("hotel", "plots",      []),
		"auto_count": cfg.get_value("hotel", "auto_count", 0),
	})


func _save_hotel(hotel: Dictionary) -> void:
	if hotel.is_empty():
		return
	var cfg := ConfigFile.new()
	for key in ["profile_id", "name", "grid_cols", "grid_rows", "day", "money", "game_time", "plots", "auto_count"]:
		cfg.set_value("hotel", key, hotel.get(key))
	cfg.save(_hotel_cfg_path(hotel["id"]))


func _delete_hotel_files(hotel_id: int) -> void:
	var hdir := DirAccess.open(HOTELS_DIR)
	if hdir:
		var cfg_name := "hotel_%d.cfg" % hotel_id
		if hdir.file_exists(cfg_name):
			hdir.remove(cfg_name)
	var sdir := DirAccess.open(SAVES_DIR)
	if not sdir:
		return
	var prefix := "hotel_%d_" % hotel_id
	sdir.list_dir_begin()
	var f := sdir.get_next()
	while f != "":
		if f.begins_with(prefix):
			sdir.remove(f)
		f = sdir.get_next()


# ── Persistenz – Snapshots ────────────────────────────────────────────────────

func _write_snapshot(path: String, snap: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_var(snap)


func _read_snapshot(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var v = file.get_var()
	return v if v is Dictionary else {}


# ── Hilfsfunktionen ───────────────────────────────────────────────────────────

func _ensure_dirs() -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(HOTELS_DIR))
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(SAVES_DIR))


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


func _take_snapshot(hotel: Dictionary, snap_name: String) -> Dictionary:
	return {
		"name":       snap_name,
		"timestamp":  int(Time.get_unix_time_from_system()),
		"hotel_name": hotel.get("name",       ""),
		"profile_id": hotel.get("profile_id", 0),
		"grid_cols":  hotel.get("grid_cols",  5),
		"grid_rows":  hotel.get("grid_rows",  5),
		"day":        hotel.get("day",        1),
		"money":      hotel.get("money",      0.0),
		"game_time":  hotel.get("game_time",  360),
		"plots":      hotel.get("plots",      []).duplicate(true),
	}


func _apply_snapshot(hotel: Dictionary, snap: Dictionary) -> void:
	hotel["day"]       = snap.get("day",       1)
	hotel["money"]     = snap.get("money",     0.0)
	hotel["game_time"] = snap.get("game_time", 360)
	hotel["plots"]     = snap.get("plots",     []).duplicate(true)
