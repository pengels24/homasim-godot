extends "res://scenes/ingame/rooms/Room.gd"
## BedDouble – Standard-Doppelzimmer (DZ). 2×4 Tiles (landscape) / 4×2 Tiles (portrait).
## door_rotation: 0=Links 1=Oben 2=Rechts 3=Unten  (R-Taste)
## door_offset:   0=erste Position 1=zweite Position  (T-Taste)
## room_flip:     0=landscape 1=portrait  (Z-Taste)

func _ready() -> void:
	room_type_id = "bed_double"


func get_tile_size() -> Vector2i:
	return Vector2i(2, 4) if room_flip == 1 else Vector2i(4, 2)


# ── Visuals ───────────────────────────────────────────────────────────────────

func _apply_visuals() -> void:
	if not is_node_ready():
		return
	$Landscape.visible = (room_flip == 0)
	$Portrait.visible  = (room_flip == 1)
	var door_root := $Portrait/Door if room_flip == 1 else $Landscape/Door
	var target := _door_node_name()
	for child in door_root.get_children():
		child.visible = (child.name == target)


func _door_node_name() -> String:
	const NAMES: Array[Array] = [
		["LeftTop",    "LeftBottom"],
		["TopLeft",    "TopRight"],
		["RightTop",   "RightBottom"],
		["BottomLeft", "BottomRight"],
	]
	return NAMES[door_rotation][door_offset]
