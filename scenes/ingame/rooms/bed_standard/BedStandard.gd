extends "res://scenes/ingame/rooms/Room.gd"
## BedStandard – Standard-Einzelzimmer (EZ). 4×4 Tiles.
## door_rotation: 0=Links 1=Oben 2=Rechts 3=Unten  (T-Taste)
## door_offset:   0=erste Position  1=zweite Position  (Z-Taste)

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
