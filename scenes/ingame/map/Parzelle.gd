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
var is_constructing: bool = false
var construction_end_time: float = 0.0
var has_entrance: bool   = false
var entrance_dir: String = ""

# ── UI ────────────────────────────────────────────────────────────────────────
var build_overlay: ColorRect
var build_ui_panel: Control
const PARZELLE_BUILD_UI = preload("res://scenes/ingame/map/ParzelleBuildUI.tscn")

func _ready() -> void:
	build_overlay = ColorRect.new()
	build_overlay.color = Color(0, 0, 0, 0.6)
	build_overlay.size = Vector2(PARCEL_TILES * TILE_PX, PARCEL_TILES * TILE_PX)
	build_overlay.visible = false
	add_child(build_overlay)
	
	build_ui_panel = PARZELLE_BUILD_UI.instantiate()
	
	var center = CenterContainer.new()
	center.size = build_overlay.size
	center.pivot_offset = center.size / 2.0
	center.scale = Vector2(3.0, 3.0)
	center.add_child(build_ui_panel)
	
	build_overlay.add_child(center)
	
var _in_buy_mode: bool = false
func set_buy_mode(active: bool) -> void:
	_in_buy_mode = active
	if is_constructing:
		build_overlay.visible = not _in_buy_mode



func _process(_delta: float) -> void:
	if is_constructing:
		var current_time = TimeManager.get_game_time()
		if current_time >= construction_end_time:
			buy(GameState.active_hotel_id)
			var map = get_parent().get_parent()
			if map.has_method("_configure_walls"):
				map._configure_walls()
			if map.has_method("_update_all_floor_neighbors"):
				map._update_all_floor_neighbors()
		else:
			var start_time = construction_end_time - 1440
			var progress = clampf(float(current_time - start_time) / 1440.0, 0.0, 1.0)
			
			var remaining = int(construction_end_time - current_time)
			build_ui_panel.update_progress(progress, remaining)


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
func start_construction(hotel_id: int, end_time: float) -> void:
	is_constructing = true
	construction_end_time = end_time
	visible = true
	build_overlay.visible = not _in_buy_mode
	var map = get_parent().get_parent()
	var _gx = int(name.split("_")[1])
	var _gy = int(name.split("_")[2])
	SaveManager.set_plot_constructing(hotel_id, _gx, _gy, end_time)

# =============================================================================
func buy(hotel_id: int) -> void:
	is_built = true
	visible  = true
	is_constructing = false
	if build_overlay: build_overlay.visible = false
	var _gx = int(name.split("_")[1])
	var _gy = int(name.split("_")[2])
	SaveManager.set_plot_built(hotel_id, _gx, _gy)


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
