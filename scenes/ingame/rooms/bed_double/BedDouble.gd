extends "res://scenes/ingame/rooms/Room.gd"
## BedDouble – Standard-Doppelzimmer (DZ). 3×2 Tiles (landscape) / 2×3 Tiles (portrait).
## room_rotation: 0=landscape  1=portrait  2=landscape 180°  3=portrait 180°  (R)
## door_rotation: 0=Links 1=Oben 2=Rechts 3=Unten  (.)
## door_offset:   0=erste Position 1=zweite Position  (,)

static func get_definition() -> Dictionary:
	return {
		"id":            "bed_double",
		"build_cost":    800,
		"exp_reward":     80,
		"prefix":        "Z",
		"label":         "DZ",
		"name":          "Doppelzimmer",
		"category":      "zimmer",
		"icon":          "res://assets/icons/bed-double.svg",
		"nightly_price": 120,
		"locked":        false,
		"in_build_menu": true,
	}


func _ready() -> void:
	room_type_id = "bed_double"


func get_tile_size() -> Vector2i:
	return Vector2i(2, 3) if room_rotation % 2 == 1 else Vector2i(3, 2)


# ── Visuals ───────────────────────────────────────────────────────────────────

# Landscape (3×2): Floor center (24,16), base 44×28px
# Portrait  (2×3): Floor center (16,24), base 28×44px
const LS_FLOOR_W := 44.0
const LS_FLOOR_H := 28.0
const PT_FLOOR_W := 28.0
const PT_FLOOR_H := 44.0
const FLOOR_TEX_W := 256.0

func set_floor_neighbors(top: bool, right: bool, bottom: bool, left: bool) -> void:
	var w: Array[bool] = [top, right, bottom, left]
	var l_top    := w[(0 + room_rotation) % 4]
	var l_right  := w[(1 + room_rotation) % 4]
	var l_bottom := w[(2 + room_rotation) % 4]
	var l_left   := w[(3 + room_rotation) % 4]
	var ext_l := 1.0 if l_left   else 0.0
	var ext_r := 1.0 if l_right  else 0.0
	var ext_t := 1.0 if l_top    else 0.0
	var ext_b := 1.0 if l_bottom else 0.0
	if room_rotation % 2 == 0:
		var f := $Landscape/Interior/Floor as Sprite2D
		f.scale    = Vector2((LS_FLOOR_W + ext_l + ext_r) / FLOOR_TEX_W, LS_FLOOR_H + ext_t + ext_b)
		f.position = Vector2(24.0 + (ext_r - ext_l) * 0.5, 16.0 + (ext_b - ext_t) * 0.5)
	else:
		var f := $Portrait/Interior/Floor as Sprite2D
		f.scale    = Vector2((PT_FLOOR_W + ext_l + ext_r) / FLOOR_TEX_W, PT_FLOOR_H + ext_t + ext_b)
		f.position = Vector2(16.0 + (ext_r - ext_l) * 0.5, 24.0 + (ext_b - ext_t) * 0.5)


# DZ: alle geometrisch passenden Slots sind gültig (leer = auto aus Raumgröße).
func get_valid_door_slots() -> Array[String]:
	return ["L1", "L2", "T1", "B2"]


func _apply_visuals() -> void:
	if not is_node_ready():
		return
	var is_portrait := room_rotation % 2 == 1
	$Landscape.visible = not is_portrait
	$Portrait.visible  = is_portrait

	if is_portrait:
		var interior := $Portrait/Interior as Node2D
		interior.position = Vector2(32, 48) if room_rotation == 3 else Vector2(0, 0)
		interior.rotation = PI if room_rotation == 3 else 0.0
	else:
		var interior := $Landscape/Interior as Node2D
		interior.position = Vector2(48, 32) if room_rotation == 2 else Vector2(0, 0)
		interior.rotation = PI if room_rotation == 2 else 0.0

	var dtfm := _calc_door_transform(door_rotation, door_offset)
	($Door as Node2D).position = dtfm["pos"]
	($Door as Node2D).rotation = dtfm["rot"]
