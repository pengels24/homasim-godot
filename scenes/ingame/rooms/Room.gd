extends Node2D
## Basisklasse für alle Raumtypen. Lobby, SingleRoom etc. erben davon.

# ── Raum-Identität ────────────────────────────────────────────────────────────
var room_type_id: String = ""     # "lobby", "bed_standard", …
var room_level:   int    = 1
var room_number:  String = ""     # "101", "" bei Lobby

# ── Position im Stockwerk ─────────────────────────────────────────────────────
var x_pos: int = 0
var y_pos: int = 0
var floor_num: int = 1

# ── Zustand ───────────────────────────────────────────────────────────────────
var condition:  int = 100   # Verschleiß:  sinkt durch Nutzung, braucht Reparatur
var cleanliness: int = 100  # Sauberkeit:  sinkt täglich, braucht Personal

# ── Tür / Orientierung ────────────────────────────────────────────────────────
var door_rotation: int = 0   # Welche Wand   0–3  (R-Taste: im Uhrzeigersinn)
var door_offset:   int = 0   # Position auf Wand 0–1  (T-Taste)
var room_flip:     int = 0   # Orientierung  0=landscape 1=portrait  (Z-Taste)


# ── Definition (von Unterklassen überschreiben) ───────────────────────────────

## Gibt alle statischen Metadaten des Raumtyps zurück.
## Unterklassen überschreiben diese Funktion – kein zentrales Register nötig.
static func get_definition() -> Dictionary:
	return {
		"id":            "",
		"build_cost":    0,
		"xp_reward":     0,
		"prefix":        "Z",
		"label":         "?",
		"name":          "Unbekannter Raum",
		"category":      "",
		"icon":          "",
		"locked":        false,
		"in_build_menu": false,
	}


# ── Public API ────────────────────────────────────────────────────────────────

func configure(data: Dictionary) -> void:
	room_type_id  = data.get("room_type_id",  room_type_id)
	room_level    = data.get("room_level",    room_level)
	room_number   = data.get("room_number",   room_number)
	x_pos         = data.get("x_pos",         x_pos)
	y_pos         = data.get("y_pos",         y_pos)
	floor_num     = data.get("floor_num",     floor_num)
	condition     = data.get("condition",     condition)
	cleanliness   = data.get("cleanliness",   cleanliness)
	door_rotation = data.get("door_rotation", door_rotation)
	door_offset   = data.get("door_offset",   door_offset)
	room_flip     = data.get("room_flip",     room_flip)
	_apply_visuals()


func to_dict() -> Dictionary:
	return {
		"room_type_id":  room_type_id,
		"room_level":    room_level,
		"room_number":   room_number,
		"x_pos":         x_pos,
		"y_pos":         y_pos,
		"floor_num":     floor_num,
		"condition":     condition,
		"cleanliness":   cleanliness,
		"door_rotation": door_rotation,
		"door_offset":   door_offset,
		"room_flip":     room_flip,
	}


func rotate_door() -> void:
	door_rotation = (door_rotation + 1) % 4
	_apply_visuals()


func cycle_door_offset() -> void:
	door_offset = 1 - door_offset
	_apply_visuals()


func flip_room() -> void:
	room_flip = 1 - room_flip
	_apply_visuals()


func upgrade() -> void:
	room_level += 1
	_apply_visuals()


# ── Intern – von Unterklassen überschreiben ───────────────────────────────────

func get_tile_size() -> Vector2i:
	return Vector2i(2, 2)


func _apply_visuals() -> void:
	pass
