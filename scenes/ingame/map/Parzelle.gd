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
var build_ui_panel: Control
var _ui_canvas: CanvasLayer  # Screen-Space → nie verwaschen, nie blockierend
const PARZELLE_BUILD_UI = preload("res://scenes/ingame/map/ParzelleBuildUI.tscn")

func _ready() -> void:
	if has_node("Ground"):
		$Ground.z_index = -1
		
	# Panel-Updates müssen auch im Pause-Modus laufen
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Panel auf CanvasLayer → Screen-Space, kein Blur, kein Mouse-Blocking
	_ui_canvas = CanvasLayer.new()
	_ui_canvas.layer = 10
	add_child(_ui_canvas)
	
	build_ui_panel = PARZELLE_BUILD_UI.instantiate()
	build_ui_panel.visible = false
	_ui_canvas.add_child(build_ui_panel)
	
var _in_buy_mode: bool = false
func set_buy_mode(active: bool) -> void:
	_in_buy_mode = active

var _was_constructing: bool = false  # für queue_redraw() Trigger


func _process(_delta: float) -> void:
	if is_constructing:
		# Progressbar IMMER anzeigen während des Baus (auch im Buy-Modus)
		if not build_ui_panel.visible:
			build_ui_panel.visible = true
		
		# Screen-Space Zentrierung
		var center_local := Vector2(PARCEL_TILES * TILE_PX, PARCEL_TILES * TILE_PX) / 2.0
		var screen_pos := get_global_transform_with_canvas() * center_local
		build_ui_panel.position = screen_pos - build_ui_panel.size / 2.0
		
		var current_time = TimeManager.get_absolute_time()
		if current_time >= construction_end_time:
			buy(GameState.active_hotel_id)
			var map = get_parent().get_parent()
			# Occupancy-Grid für die neue Parzelle freischalten (sonst: alle Tiles SOLID)
			if map.has_method("_mark_parcel_walls"):
				var gx := int(name.get_slice("_", 1))
				var gy := int(name.get_slice("_", 2))
				map._mark_parcel_walls(gx, gy)
			if map.has_method("_configure_walls"):
				map._configure_walls()
			if map.has_method("_update_all_floor_neighbors"):
				map._update_all_floor_neighbors()
			queue_redraw()  # Overlay entfernen
		else:
			var start_time = construction_end_time - 1440
			var progress = clampf(float(current_time - start_time) / 1440.0, 0.0, 1.0)
			var remaining = int(construction_end_time - current_time)
			build_ui_panel.update_progress(progress, remaining)
			queue_redraw()  # Overlay aktuell halten
	else:
		if _was_constructing:
			_was_constructing = false
			queue_redraw()

# =============================================================================
# Bau-Overlay: Gelb-schwarze Schraffur während is_constructing
func _draw() -> void:
	if not is_constructing:
		return
	
	var size := Vector2(PARCEL_TILES * TILE_PX, PARCEL_TILES * TILE_PX)
	
	# Halbtransparentes dunkles Basisräume
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.1, 0.1, 0.45))
	
	# Diagonale gelb-schwarze Warnstreifen
	var stripe_w: int = 8
	var stripe_gap: int = 8
	var total: int = int(size.x + size.y)
	var sx: int = int(size.x)
	var sy: int = int(size.y)
	var i: int = 0
	while i < total:
		var x1: int = clampi(i - sy, 0, sx)
		var y1: int = clampi(sy - i, 0, sy)
		var x2: int = clampi(i, 0, sx)
		var y2: int = 0
		if x2 > x1:
			draw_line(Vector2(x1, y1), Vector2(x2, y2), Color(0.95, 0.75, 0.05, 0.5), float(stripe_w))
		i += stripe_w + stripe_gap



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
	# build_ui_panel.visible wird in _process automatisch gesetzt
	var _gx = int(name.split("_")[1])
	var _gy = int(name.split("_")[2])
	SaveManager.set_plot_constructing(hotel_id, _gx, _gy, end_time)


# =============================================================================
func buy(hotel_id: int) -> void:
	is_built = true
	visible  = true
	is_constructing = false
	if build_ui_panel: build_ui_panel.visible = false  # _process ist off, manuell
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
## Alias – MapGrid ruft diese Variante beim Platzierungscheck auf
func get_lobby_clearance_rect() -> Rect2i:
	return get_lobby_tile_rect()


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
