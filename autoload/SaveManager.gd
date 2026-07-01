extends Node

# ── Konstanten ────────────────────────────────────────────────────────────────
const PROFILES_PATH := "user://profiles.cfg"
const HOTELS_DIR    := "user://hotels/"
const SAVES_DIR     := "user://saves/"
const MAX_AUTOSAVES := 5
const MAX_HOTELS    := 10
const MANUAL_SLOTS  := 5

# ── State ─────────────────────────────────────────────────────────────────────
var _profiles:        Array = []
var _hotels:          Array = []
var _next_profile_id: int   = 1
var _next_hotel_id:   int   = 1
var _temp_thumbnail:  Image = null


# =============================================================================
func capture_thumbnail(viewport: Viewport) -> void:
	# Holt den aktuellen Viewport, skaliert ihn für das Dashboard runter und speichert ihn
	var img = viewport.get_texture().get_image()
	if img:
		img.resize(400, 225, Image.INTERPOLATE_BILINEAR)
		_temp_thumbnail = img

# ── Lifecycle ─────────────────────────────────────────────────────────────────

# =============================================================================
func _ready() -> void:
	# Das macht diesen Autoload immun gegen die Godot-Pause!
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_dirs()
	_load_profiles()
	_load_all_hotels()


# ── Profile ───────────────────────────────────────────────────────────────────

# =============================================================================
func get_profiles() -> Array:
	return _profiles


# =============================================================================
func create_profile(profile_name: String, appearance: Dictionary = {}) -> int:
	var new_id := _next_profile_id
	_next_profile_id += 1
	var profile := { "id": new_id, "name": profile_name }
	profile.merge(appearance)
	_profiles.append(profile)
	_save_profiles()
	return new_id


# =============================================================================
func get_profile(profile_id: int) -> Dictionary:
	for p in _profiles:
		if p["id"] == profile_id:
			return p
	return {}


# =============================================================================
func delete_profile(profile_id: int) -> void:
	_profiles = _profiles.filter(func(p: Dictionary) -> bool: return p["id"] != profile_id)
	var to_delete: Array = _hotels.filter(
		func(h: Dictionary) -> bool: return h["profile_id"] == profile_id)
	for h in to_delete:
		_delete_hotel_files(h["id"])
	_hotels = _hotels.filter(func(h: Dictionary) -> bool: return h["profile_id"] != profile_id)
	_save_profiles()


# ── Hotels ────────────────────────────────────────────────────────────────────

# =============================================================================
func get_hotels(profile_id: int) -> Array:
	return _hotels.filter(func(h: Dictionary) -> bool: return h["profile_id"] == profile_id)


# =============================================================================
func can_create_hotel(profile_id: int) -> bool:
	return get_hotels(profile_id).size() < MAX_HOTELS


# =============================================================================
func create_hotel(profile_id: int, hotel_name: String, cols: int = 5, rows: int = 5) -> int:
	var new_id := _next_hotel_id
	_next_hotel_id += 1
	var hotel := {
		"id": new_id,
		"profile_id": profile_id,
		"name": hotel_name,
		"grid_cols": cols,
		"grid_rows": rows,
		"day": 1,
		"money": 50000,
		"game_time": 360,
		"plots": _init_plots(cols, rows),
		"auto_count": 0,
		# neue felder ab v0.1.23gd
		"level": 1,
		"stars": 0,
		"guests_active": 0,
		"guests_checkin": 0,
		"guests_checkout": 0,
		"exp": 0,
		"exp_max": GameState.get_xp_needed_for_level(1),
		"rep_max": 1000,
		"fp": 0,
		"transactions": [],
		"unlocked_techs": [],
		"tutorial_step": 1,
	}
	_hotels.append(hotel)
	_save_profiles()
	_save_hotel(hotel)
	return new_id


# =============================================================================
func create_tutorial_hotel() -> int:
	delete_hotel(GameState.TUTORIAL_HOTEL_ID) # Lösche evtl. alten Stand
	var hotel := {
		"id": GameState.TUTORIAL_HOTEL_ID,
		"profile_id": -1,
		"name": "Tutorial Hotel",
		"grid_cols": 5,
		"grid_rows": 5,
		"day": 1,
		"money": 50000,
		"game_time": 360,
		"plots": _init_plots(5, 5),
		"auto_count": 0,
		"level": 1,
		"stars": 0,
		"guests_active": 0,
		"guests_checkin": 0,
		"guests_checkout": 0,
		"exp": 0,
		"exp_max": GameState.get_xp_needed_for_level(1),
		"rep": 500,
		"rep_max": 1000,
		"fp": 0,
		"guest_data": {},
		"transactions": [],
		"unlocked_techs": [],
		"techtree": {},
		"tutorials": [],
		"quests": {},
		"staff": {},
		"built_room_types": [],
		"tutorial_step": 1,
	}
	_hotels.append(hotel)
	_save_hotel(hotel)
	return GameState.TUTORIAL_HOTEL_ID


# =============================================================================
func get_hotel(hotel_id: int) -> Dictionary:
	for h in _hotels:
		if h["id"] == hotel_id:
			return h
	return {}


# =============================================================================
func update_hotel(hotel_id: int, fields: Dictionary) -> void:
	for h in _hotels:
		if h["id"] == hotel_id:
			for key in fields:
				h[key] = fields[key]
			_save_hotel(h)
			return


# =============================================================================
func delete_hotel(hotel_id: int) -> void:
	_hotels = _hotels.filter(func(h: Dictionary) -> bool: return h["id"] != hotel_id)
	_delete_hotel_files(hotel_id)


# ── Plots ─────────────────────────────────────────────────────────────────────

# =============================================================================
func get_plots(hotel_id: int) -> Array:
	return get_hotel(hotel_id).get("plots", [])


# =============================================================================
func get_built_plots(hotel_id: int) -> Array:
	return get_plots(hotel_id).filter(func(p: Dictionary) -> bool: return p["is_built"])


# =============================================================================
func set_plot_built(hotel_id: int, x: int, y: int, entrance_dir: String = "") -> void:
	var hotel := get_hotel(hotel_id)
	for p in hotel.get("plots", []):
		if p["x"] == x and p["y"] == y:
			p["is_built"]     = true
			p["entrance_dir"] = entrance_dir
			break
	_save_hotel(hotel)


# ── Räume ─────────────────────────────────────────────────────────────────────

# =============================================================================
func save_room_to_plot(hotel_id: int, parcel_x: int, parcel_y: int, room_dict: Dictionary) -> void:
	var hotel := get_hotel(hotel_id)
	for p in hotel.get("plots", []):
		if p["x"] == parcel_x and p["y"] == parcel_y:
			var rooms: Array = p.get("rooms", [])
			rooms.append(room_dict)
			p["rooms"] = rooms
			break
	_save_hotel(hotel)

# =============================================================================
func overwrite_rooms_in_plot(hotel_id: int, parcel_x: int, parcel_y: int, rooms_array: Array) -> void:
	var hotel := get_hotel(hotel_id)
	for p in hotel.get("plots", []):
		if p["x"] == parcel_x and p["y"] == parcel_y:
			p["rooms"] = rooms_array
			break
	_save_hotel(hotel)


# ── Save-Slots ────────────────────────────────────────────────────────────────

# =============================================================================
func get_save_slots(hotel_id: int) -> Dictionary:
	var hotel  := get_hotel(hotel_id)
	var result := _default_saves()
	var qs     := _read_snapshot(_save_path_quick(hotel_id))
	result["quick"] = qs if not qs.is_empty() else (null as Variant)
	for i in MANUAL_SLOTS:
		var ms := _read_snapshot(_save_path_manual(hotel_id, i))
		result["manual"][i] = ms if not ms.is_empty() else (null as Variant)
	var auto_count: int = hotel.get("auto_count", 0)
	result["auto"].resize(auto_count)
	for i in auto_count:
		result["auto"][i] = _read_snapshot(_save_path_auto(hotel_id, i))
	return result


# =============================================================================
func save_quick(hotel_id: int) -> void:
	var hotel := get_hotel(hotel_id)
	if hotel.is_empty():
		return
	_write_snapshot(_save_path_quick(hotel_id), _take_snapshot(hotel, "Quicksave"))


# =============================================================================
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


# =============================================================================
func save_manual(hotel_id: int, slot: int, save_name: String) -> void:
	if slot < 0 or slot >= MANUAL_SLOTS:
		return
	var hotel := get_hotel(hotel_id)
	if hotel.is_empty():
		return
	_write_snapshot(_save_path_manual(hotel_id, slot), _take_snapshot(hotel, save_name))


# =============================================================================
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


# =============================================================================
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


# =============================================================================
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


# =============================================================================
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

# =============================================================================
func _hotel_cfg_path(id: int) -> String:
	return HOTELS_DIR + "hotel_%d.cfg" % id


# =============================================================================
func _save_path_quick(id: int) -> String:
	return SAVES_DIR + "hotel_%d_quick.sav" % id


# =============================================================================
func _save_path_manual(id: int, n: int) -> String:
	return SAVES_DIR + "hotel_%d_manual_%d.sav" % [id, n]


# =============================================================================
func _save_path_auto(id: int, n: int) -> String:
	return SAVES_DIR + "hotel_%d_auto_%d.sav" % [id, n]


# ── Persistenz – Profile ──────────────────────────────────────────────────────

# =============================================================================
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


# =============================================================================
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

# =============================================================================
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


# =============================================================================
func _load_hotel_file(filename: String) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(HOTELS_DIR + filename) != OK:
		return
	var id := int(filename.get_basename().trim_prefix("hotel_"))

	var loaded_level: int = cfg.get_value("hotel", "level", 1)
	var loaded_exp_max: int = cfg.get_value("hotel", "exp_max", 100)

	# Fallback für Altdaten: Wenn exp_max noch auf dem alten Standard von 100 steht,
	# überschreiben wir es mit der neuen Kurve passend zum geladenen Level.
	if loaded_exp_max == 100:
		loaded_exp_max = GameState.get_xp_needed_for_level(loaded_level)

	var h := {
		"id": id,
		"profile_id": cfg.get_value("hotel", "profile_id", 0),
		"name": cfg.get_value("hotel", "name", ""),
		"grid_cols": cfg.get_value("hotel", "grid_cols", 5),
		"grid_rows": cfg.get_value("hotel", "grid_rows", 5),
		"day": cfg.get_value("hotel", "day", 1),
		"money": cfg.get_value("hotel", "money", 50000),
		"game_time": cfg.get_value("hotel", "game_time", 360),
		"plots":  cfg.get_value("hotel", "plots", []),
		"auto_count": cfg.get_value("hotel", "auto_count", 0),
		"level": loaded_level,
		"stars": cfg.get_value("hotel", "stars", 0),
		"guests_active": cfg.get_value("hotel", "guests_active", 0),
		"guests_checkin": cfg.get_value("hotel", "guests_checkin", 0),
		"guests_checkout": cfg.get_value("hotel", "guests_checkout", 0),
		"exp": cfg.get_value("hotel", "exp", 0),
		"exp_max": loaded_exp_max,
		"rep": cfg.get_value("hotel", "rep", 500),
		"rep_max": cfg.get_value("hotel", "rep_max", 1000),
		"fp": cfg.get_value("hotel", "fp", 0),
		"guest_data": cfg.get_value("hotel", "guest_data", {}),
		"transactions": cfg.get_value("hotel", "transactions", []),
		"unlocked_techs": cfg.get_value("hotel", "unlocked_techs", []),
		"techtree": cfg.get_value("hotel", "techtree", {}),
		"tutorials": cfg.get_value("hotel", "tutorials", []),
		"quests": cfg.get_value("hotel", "quests", {}),
		"staff": cfg.get_value("hotel", "staff", {}),
		"built_room_types": cfg.get_value("hotel", "built_room_types", []),
		"tutorial_step": cfg.get_value("hotel", "tutorial_step", 1),
	}

	# Alle dynamischen Zimmer-Zähler aus der Config lesen und in 'h' einfügen
	if cfg.has_section("hotel"):
		for key in cfg.get_section_keys("hotel"):
			if key.begins_with("next_") and key.ends_with("_id"):
				h[key] = cfg.get_value("hotel", key)

	_hotels.append(h)


# =============================================================================
func _save_hotel(hotel: Dictionary) -> void:
	if hotel.is_empty():
		return
	var cfg := ConfigFile.new()
	var keys_to_save = [
		"profile_id", "name", "grid_cols", "grid_rows", "day", "money", "game_time", "plots", "auto_count", 
		"level", "stars", "guests_active", "guests_checkin", "guests_checkout", "exp", "exp_max", "rep", "rep_max", "fp", 
		"guest_data", "transactions", "unlocked_techs", "techtree", "tutorials", "quests", "staff", "built_room_types", "tutorial_step"
	]
	for key in keys_to_save:
		cfg.set_value("hotel", key, hotel.get(key))

	# NEU: Alle dynamischen Zimmer-Zähler ("next_z_id", etc.) mitspeichern
	for key in hotel:
		if key is String and key.begins_with("next_") and key.ends_with("_id"):
			cfg.set_value("hotel", key, hotel[key])

	cfg.save(_hotel_cfg_path(hotel["id"]))

	if _temp_thumbnail:
		var thumb_path := HOTELS_DIR + ("hotel_%d_thumb.png" % hotel["id"])
		_temp_thumbnail.save_png(thumb_path)
		_temp_thumbnail = null
# =============================================================================
func load_thumbnail(hotel_id: int) -> ImageTexture:
	var thumb_path := HOTELS_DIR + ("hotel_%d_thumb.png" % hotel_id)
	if FileAccess.file_exists(thumb_path):
		var img = Image.load_from_file(thumb_path)
		if img:
			return ImageTexture.create_from_image(img)
	return null


# =============================================================================
func _delete_hotel_files(hotel_id: int) -> void:
	var hdir := DirAccess.open(HOTELS_DIR)
	if hdir:
		var cfg_name := "hotel_%d.cfg" % hotel_id
		if hdir.file_exists(cfg_name):
			hdir.remove(cfg_name)
		var thumb_name := "hotel_%d_thumb.png" % hotel_id
		if hdir.file_exists(thumb_name):
			hdir.remove(thumb_name)
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

# =============================================================================
func _write_snapshot(path: String, snap: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_var(snap)


# =============================================================================
func _read_snapshot(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var v = file.get_var()
	return v if v is Dictionary else {}


# ── Hilfsfunktionen ───────────────────────────────────────────────────────────

# =============================================================================
func _ensure_dirs() -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(HOTELS_DIR))
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(SAVES_DIR))


# =============================================================================
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


# =============================================================================
func _default_saves() -> Dictionary:
	return { "quick": null, "manual": _empty_manual(), "auto": [] }


# =============================================================================
func _empty_manual() -> Array:
	var arr: Array = []
	for _i in MANUAL_SLOTS:
		arr.append(null)
	return arr


# =============================================================================
func _take_snapshot(hotel: Dictionary, snap_name: String) -> Dictionary:
	var snap := {
		"name": snap_name,
		"timestamp": int(Time.get_unix_time_from_system()),
		"hotel_name": hotel.get("name", ""),
		"profile_id": hotel.get("profile_id", 0),
		"grid_cols": hotel.get("grid_cols", 5),
		"grid_rows": hotel.get("grid_rows", 5),
		"day": hotel.get("day", 1),
		"money": hotel.get("money", 0),
		"game_time": hotel.get("game_time", 360),
		"plots": hotel.get("plots", []).duplicate(true),
		"level": hotel.get("level", 1),
		"stars": hotel.get("stars", 0),
		"guests_active": hotel.get("guests_active", 0),
		"guests_checkin": hotel.get("guests_checkin", 0),
		"guests_checkout": hotel.get("guests_checkout", 0),
		"exp": hotel.get("exp", 0),
		"exp_max": hotel.get("exp_max", 100),
		"rep": hotel.get("rep", 500),
		"rep_max": hotel.get("rep_max", 1000),
		"fp": hotel.get("fp", 0),
		"guest_data": hotel.get("guest_data", {}).duplicate(true),
		"transactions": hotel.get("transactions", []).duplicate(true),
		"unlocked_techs": hotel.get("unlocked_techs", []).duplicate(true),
		"techtree": hotel.get("techtree", {}).duplicate(true),
		"tutorials": hotel.get("tutorials", []).duplicate(true),
		"quests": hotel.get("quests", {}).duplicate(true),
		"staff": hotel.get("staff", {}).duplicate(true),
		"built_room_types": hotel.get("built_room_types", []).duplicate(true),
		"tutorial_step": hotel.get("tutorial_step", 1),
	}

	# NEU: Zähler in den Snapshot kopieren
	for key in hotel:
		if key is String and key.begins_with("next_") and key.ends_with("_id"):
			snap[key] = hotel[key]

	return snap


# =============================================================================
func _apply_snapshot(hotel: Dictionary, snap: Dictionary) -> void:
	hotel["day"] = snap.get("day", 1)
	hotel["money"] = snap.get("money", 0)
	hotel["game_time"] = snap.get("game_time", 360)
	hotel["plots"] = snap.get("plots", []).duplicate(true)
	hotel["level"] = snap.get("level", 1)
	hotel["stars"] = snap.get("stars", 0)
	hotel["guests_active"] = snap.get("guests_active", 0)
	hotel["guests_checkin"] = snap.get("guests_checkin", 0)
	hotel["guests_checkout"] = snap.get("guests_checkout", 0)
	hotel["exp"] = snap.get("exp", 0)

	var snap_exp_max: int = snap.get("exp_max", 100)
	if snap_exp_max == 100:
		snap_exp_max = GameState.get_xp_needed_for_level(hotel["level"])
	hotel["exp_max"] = snap_exp_max

	hotel["rep"] = snap.get("rep", 500)
	hotel["rep_max"] = snap.get("rep_max", 1000)
	hotel["fp"] = snap.get("fp", 0)
	hotel["guest_data"] = snap.get("guest_data", {}).duplicate(true)
	hotel["transactions"] = snap.get("transactions", []).duplicate(true)
	hotel["unlocked_techs"] = snap.get("unlocked_techs", []).duplicate(true)
	hotel["techtree"] = snap.get("techtree", {}).duplicate(true)
	hotel["tutorials"] = snap.get("tutorials", []).duplicate(true)
	hotel["quests"] = snap.get("quests", {}).duplicate(true)
	hotel["staff"] = snap.get("staff", {}).duplicate(true)
	hotel["built_room_types"] = snap.get("built_room_types", []).duplicate(true)
	hotel["tutorial_step"] = snap.get("tutorial_step", 1)

	# Zähler aus dem Snapshot wiederherstellen
	for key in snap:
		if key is String and key.begins_with("next_") and key.ends_with("_id"):
			hotel[key] = snap[key]
