extends "res://scenes/ingame/rooms/Room.gd"
## BedStandard – Standard-Einzelzimmer (EZ). 2×2 Tiles.
## door_rotation: 0=Links 1=Oben 2=Rechts 3=Unten  (R-Taste)
## door_offset:   0=erste Position  1=zweite Position  (T-Taste)
## room_flip:     nicht genutzt (2×2 ist symmetrisch)

static func get_definition() -> Dictionary:
	return {
		"id":            "bed_standard",
		"build_cost":    500,
		"xp_reward":     50,
		"prefix":        "Z",
		"label":         "EZ",
		"name":          "Einzelzimmer",
		"category":      "zimmer",
		"icon":          "res://assets/icons/bed-single.svg",
		"locked":        false,
		"in_build_menu": true,
	}


func _ready() -> void:
	room_type_id = "bed_standard"


# ── Visuals ───────────────────────────────────────────────────────────────────

func _apply_visuals() -> void:
	if not is_node_ready():
		return
	var target := _door_node_name()
	for child in $Door.get_children():
		child.visible = (child.name == target)


func _door_node_name() -> String:
	const NAMES: Array[Array] = [
		["LeftTop",    "LeftBottom"],
		["TopLeft",    "TopRight"],
		["RightTop",   "RightBottom"],
		["BottomLeft", "BottomRight"],
	]
	return NAMES[door_rotation][door_offset]
