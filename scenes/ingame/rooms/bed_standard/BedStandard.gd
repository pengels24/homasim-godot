extends "res://scenes/ingame/rooms/Room.gd"
## BedStandard – Standard-Einzelzimmer (EZ). 2×2 Tiles.
## door_rotation: 0=Links 1=Oben 2=Rechts 3=Unten  (R=Raum+Tür rotieren, .=nur Tür)
## door_offset:   0=erste Position  1=zweite Position auf Wand  (,=Wechsel)

static func get_definition() -> Dictionary:
	return {
		"id":            "bed_standard",
		"build_cost":    500,
		"exp_reward":     50,
		"prefix":        "Z",
		"label":         "EZ",
		"name":          "Einzelzimmer",
		"category":      "zimmer",
		"icon":          "res://assets/icons/bed-single.svg",
		"nightly_price": 60,
		"locked":        false,
		"in_build_menu": true,
	}


func _ready() -> void:
	room_type_id = "bed_standard"


# EZ: Tür nur auf der linken Wand, L1 (unten) und L2 (oben).
func get_valid_door_slots() -> Array[String]:
	return ["L1", "L2"]

# Interior-Transform je Tür-Wand: Raum rotiert um Mittelpunkt (16,16).
# pos + rot so berechnet dass (0,0) des Interior-Nodes um (16,16) gedreht wird.
const INTERIOR_TRANSFORMS: Dictionary = {
	0: {"pos": Vector2(0,  0),  "rot": 0.0},          # Links  – keine Rotation
	1: {"pos": Vector2(32, 0),  "rot": PI / 2.0},     # Oben   – 90° im UZS
	2: {"pos": Vector2(32, 32), "rot": PI},            # Rechts – 180°
	3: {"pos": Vector2(0,  32), "rot": -PI / 2.0},    # Unten  – 90° gegen UZS
}


const FLOOR_BASE_SIZE := 28.0
const FLOOR_TEX_W     := 256.0

# Rotiert die Welt-Nachbar-Flags in den lokalen Raum des Interior-Nodes.
# Interior dreht sich um room_rotation * 90° CW → Flags entsprechend verschieben.
func set_floor_neighbors(top: bool, right: bool, bottom: bool, left: bool) -> void:
	var w: Array[bool] = [top, right, bottom, left]  # 0=T 1=R 2=B 3=L
	var l_top    := w[(0 + room_rotation) % 4]
	var l_right  := w[(1 + room_rotation) % 4]
	var l_bottom := w[(2 + room_rotation) % 4]
	var l_left   := w[(3 + room_rotation) % 4]
	var ext_l := 1.0 if l_left   else 0.0
	var ext_r := 1.0 if l_right  else 0.0
	var ext_t := 1.0 if l_top    else 0.0
	var ext_b := 1.0 if l_bottom else 0.0
	var floor_node := $Interior/Floor as Sprite2D
	floor_node.scale    = Vector2((FLOOR_BASE_SIZE + ext_l + ext_r) / FLOOR_TEX_W,
								   FLOOR_BASE_SIZE + ext_t + ext_b)
	floor_node.position = Vector2(16.0 + (ext_r - ext_l) * 0.5,
								   16.0 + (ext_b - ext_t) * 0.5)


func _apply_visuals() -> void:
	if not is_node_ready():
		return
	var dtfm := _calc_door_transform(door_rotation, door_offset)
	($Door as Node2D).position = dtfm["pos"]
	($Door as Node2D).rotation = dtfm["rot"]
	var icfg: Dictionary = INTERIOR_TRANSFORMS.get(room_rotation,
		{"pos": Vector2.ZERO, "rot": 0.0})
	($Interior as Node2D).position = icfg["pos"]
	($Interior as Node2D).rotation = icfg["rot"]
