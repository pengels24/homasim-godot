extends "res://scenes/ingame/rooms/Room.gd"
## Bar – Kleine Bar (BA). 2×2 Tiles.
## door_rotation: 0=Links 1=Oben 2=Rechts 3=Unten  (R=Raum+Tür rotieren, .=nur Tür)
## door_offset:   0=erste Position  1=zweite Position auf Wand  (,=Wechsel)

static func get_definition() -> Dictionary:
	return {
		"id":            "bar",
		"build_cost":    1800,
		"exp_reward":     50,
		"prefix":        "B",
		"label":         "BA",
		"name":          "Bar",
		"category":      "gastro",
		"icon":          "res://assets/icons/wine.svg",
		"nightly_price": 0,
		"locked":        false,
		"in_build_menu": true,
	}


func _ready() -> void:
	room_type_id = "bar"


# PB: rechte Wand R1 (oben).
func get_valid_door_slots() -> Array[String]:
	return ["R1"]


# Interior-Transform je Tür-Wand: Raum rotiert um Mittelpunkt (16,16).
# pos + rot so berechnet dass (0,0) des Interior-Nodes um (16,16) gedreht wird.
const INTERIOR_TRANSFORMS: Dictionary = {
	0: {"pos": Vector2(0,  0),  "rot": 0.0},          # Links  – keine Rotation
	1: {"pos": Vector2(32, 0),  "rot": PI / 2.0},     # Oben   – 90° im UZS
	2: {"pos": Vector2(32, 32), "rot": PI},            # Rechts – 180°
	3: {"pos": Vector2(0,  32), "rot": -PI / 2.0},    # Unten  – 90° gegen UZS
}


func _apply_visuals() -> void:
	if not is_node_ready():
		return
	var dtfm := _calc_door_transform(door_rotation, door_offset)
	($Door as Node2D).position = dtfm["pos"]
	($Door as Node2D).rotation = dtfm["rot"]
	var icfg: Dictionary = INTERIOR_TRANSFORMS.get(room_rotation,	{"pos": Vector2.ZERO, "rot": 0.0})
	($Interior as Node2D).position = icfg["pos"]
	($Interior as Node2D).rotation = icfg["rot"]
