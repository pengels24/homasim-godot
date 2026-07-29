extends Node2D

# ── Nodes ─────────────────────────────────────────────────────────────────────
@onready var wall_n: Node2D = $WallN
@onready var wall_s: Node2D = $WallS
@onready var wall_w: Node2D = $WallW
@onready var wall_e: Node2D = $WallE

# ── Konstanten ────────────────────────────────────────────────────────────────
const LOBBY_SCENE  := preload("res://scenes/ingame/rooms/lobby/Lobby.tscn")
const PARCEL_TILES := 16
const LOBBY_TILES  := 4
const TILE_PX      := 16

# ── Zustand ───────────────────────────────────────────────────────────────────
var is_built:     bool   = false
var has_entrance: bool   = false
var entrance_dir: String = ""


# ── Public API ────────────────────────────────────────────────────────────────

# =============================================================================
func configure(neighbors: Dictionary) -> void:
	wall_n.visible = not neighbors.get("top",    false)
	wall_s.visible = not neighbors.get("bottom", false)
	wall_w.visible = not neighbors.get("left",   false)
	wall_e.visible = not neighbors.get("right",  false)


# =============================================================================
func set_entrance(dir: String) -> void:
	has_entrance = true
	entrance_dir = dir
	_spawn_lobby()


# =============================================================================
func buy(hotel_id: int) -> void:
	is_built = true
	visible  = true
	SaveManager.set_plot_built(hotel_id, _grid_x(), _grid_y())


# =============================================================================
func spawn_room(room_scene: PackedScene, door_rot: int, door_off: int, tile_x: int, tile_y: int, room_rot: int = 0) -> Node2D:
	var room: Node2D = room_scene.instantiate()
	add_child(room)
	room.configure({"door_rotation": door_rot, "door_offset": door_off, "room_rotation": room_rot, "x_pos": tile_x, "y_pos": tile_y})
	room.position = Vector2(tile_x * TILE_PX, tile_y * TILE_PX)
	return room


# =============================================================================
func restore_room(room_data: Dictionary, room_scene: PackedScene) -> Node2D:
	var room: Node2D = room_scene.instantiate()
	add_child(room)
	room.configure(room_data)
	var tx: int = room_data.get("x_pos", 0)
	var ty: int = room_data.get("y_pos", 0)
	room.position = Vector2(tx * TILE_PX, ty * TILE_PX)
	return room


# =============================================================================
func get_lobby_tile_rect() -> Rect2i:
	if not has_entrance:
		return Rect2i()
	var lp := _lobby_position()
	return Rect2i(int(lp.x / TILE_PX), int(lp.y / TILE_PX), LOBBY_TILES, LOBBY_TILES)


# =============================================================================
func get_lobby() -> Node2D:
	for child in get_children():
		if child.get("room_type_id") == "lobby":
			return child
	return null

# ── Intern ────────────────────────────────────────────────────────────────────

# =============================================================================
func _spawn_lobby() -> void:
	var lobby: Node2D = LOBBY_SCENE.instantiate()
	add_child(lobby)
	lobby.position = _lobby_position()
	lobby.configure({ "entrance_dir": entrance_dir })


# =============================================================================
func _lobby_position() -> Vector2:
	var center_offset: int = int((PARCEL_TILES - LOBBY_TILES) / 2.0) * TILE_PX
	match entrance_dir:
		"top":    return Vector2(center_offset, 0)
		"bottom": return Vector2(center_offset, (PARCEL_TILES - LOBBY_TILES) * TILE_PX)
		"left":   return Vector2(0, center_offset)
		"right":  return Vector2((PARCEL_TILES - LOBBY_TILES) * TILE_PX, center_offset)
	return Vector2(center_offset, center_offset)


# =============================================================================
func _grid_x() -> int:
	return name.get_slice("_", 1).to_int()


# =============================================================================
func _grid_y() -> int:
	return name.get_slice("_", 2).to_int()
