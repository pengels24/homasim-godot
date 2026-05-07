extends Node2D
## Basisklasse für alle Raumtypen. Lobby, SingleRoom etc. erben davon.

const TILE_PX := 16

# Namensschema für Tür-Slots. Reihenfolge: 0=L 1=T 2=R 3=B.
# L: von unten nach oben  T: von links nach rechts
# R: von oben nach unten  B: von rechts nach links
# Max 5 Slots je Wand (für Räume bis 5 Tiles Wandlänge).
const DOOR_SLOTS: Array[Array] = [
	["L1", "L2", "L3", "L4", "L5"],
	["T1", "T2", "T3", "T4", "T5"],
	["R1", "R2", "R3", "R4", "R5"],
	["B1", "B2", "B3", "B4", "B5"],
]

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
var door_rotation: int = 0   # Welche Wand   0–3  (.-Taste: nur Tür wandert)
var door_offset:   int = 0   # Position auf Wand 0–1  (,-Taste)
var room_rotation: int = 0   # Interior-Rotation 0–3  (R-Taste: ganzer Raum dreht)


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
	room_rotation = data.get("room_rotation", room_rotation)
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
		"room_rotation": room_rotation,
	}


func rotate_door() -> void:
	door_rotation = (door_rotation + 1) % 4
	_apply_visuals()


func cycle_door_offset() -> void:
	door_offset = 1 - door_offset
	_apply_visuals()



func upgrade() -> void:
	room_level += 1
	_apply_visuals()


# ── Intern – von Unterklassen überschreiben ───────────────────────────────────

func get_tile_size() -> Vector2i:
	return Vector2i(2, 2)


## Welche benannten Slots darf dieser Raum nutzen? Leer = alle geometrisch passenden.
func get_valid_door_slots() -> Array[String]:
	return []


## Berechnet alle gültigen (door_rotation, door_offset)-Kombos aus Raumgröße + Slot-Deklaration.
## door_rotation = Wand (0=L 1=T 2=R 3=B), door_offset = 0-basierter Slot-Index.
func get_valid_door_combos() -> Array[Vector2i]:
	var sz       := get_tile_size()
	var wall_len := [sz.y, sz.x, sz.y, sz.x]  # L/R = Höhe, T/B = Breite
	var named    := get_valid_door_slots()
	var result: Array[Vector2i] = []
	for rot: int in range(4):
		var slots: Array = DOOR_SLOTS[rot]
		var n := mini(wall_len[rot], 5)
		for off: int in range(n):
			if named.is_empty() or slots[off] in named:
				result.append(Vector2i(rot, off))
	return result


## Berechnet Position + Rotation des Tür-Sprites für einen Slot.
## L/B zählen von der Ecke (L1=unten, B1=rechts) – daher invertierte along-Formel.
func _calc_door_transform(rot: int, off: int) -> Dictionary:
	var sz    := get_tile_size()
	var w_px  := sz.x * TILE_PX
	var h_px  := sz.y * TILE_PX
	var along: float
	match rot:
		0:  # L – von unten nach oben
			along = (sz.y - 1 - off) * TILE_PX + TILE_PX / 2.0
			return {"pos": Vector2(1, along),       "rot": PI}
		1:  # T – von links nach rechts
			along = off * TILE_PX + TILE_PX / 2.0
			return {"pos": Vector2(along, 1),       "rot": -PI / 2.0}
		2:  # R – von oben nach unten
			along = off * TILE_PX + TILE_PX / 2.0
			return {"pos": Vector2(w_px - 1, along), "rot": 0.0}
		3:  # B – von rechts nach links
			along = (sz.x - 1 - off) * TILE_PX + TILE_PX / 2.0
			return {"pos": Vector2(along, h_px - 1), "rot": PI / 2.0}
	return {"pos": Vector2.ZERO, "rot": 0.0}


func set_floor_neighbors(_top: bool, _right: bool, _bottom: bool, _left: bool) -> void:
	pass


func _apply_visuals() -> void:
	pass
