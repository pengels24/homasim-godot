extends Node2D
## Verantwortlichkeit: Spielfeld aufbauen, Parzellen-Sichtbarkeit steuern, Kamera-Input.

# ── Nodes ─────────────────────────────────────────────────────────────────────
@onready var camera: Camera2D = $Camera2D

# ── Grid-Konfiguration ────────────────────────────────────────────────────────
@export var grid_cols:  int = 5
@export var grid_rows:  int = 5
@export var start_plot: Vector2i = Vector2i(1, 0)

const PARCEL_SZ := 16   # Tiles pro Parzelle
const WALK_W    := 3    # Gehweg-Breite außen
const TILE_PX   := 16   # Physische Tile-Größe in Px
const SCALE     := 2.0  # WorldRoot.scale

# ── Kamera-Konfiguration ──────────────────────────────────────────────────────
const PAN_SPEED := 400.0
const ZOOM_MIN  := 0.5
const ZOOM_MAX  := 4.0
const ZOOM_STEP := 0.15

# ── State ─────────────────────────────────────────────────────────────────────
var _drag_active: bool    = false
var _drag_origin: Vector2 = Vector2.ZERO
var _cam_origin:  Vector2 = Vector2.ZERO

# ── Statisches Grid – direkte Referenzen auf alle 25 Parzellen-Instanzen ──────
# _grid[y][x] – in _ready() fest verdrahtet, immer verfügbar.
var _grid: Array = []


func _ready() -> void:
	var p := $WorldRoot/ParcelsRoot
	_grid = [
		[p.get_node("P_0_0"), p.get_node("P_1_0"), p.get_node("P_2_0"), p.get_node("P_3_0"), p.get_node("P_4_0")],
		[p.get_node("P_0_1"), p.get_node("P_1_1"), p.get_node("P_2_1"), p.get_node("P_3_1"), p.get_node("P_4_1")],
		[p.get_node("P_0_2"), p.get_node("P_1_2"), p.get_node("P_2_2"), p.get_node("P_3_2"), p.get_node("P_4_2")],
		[p.get_node("P_0_3"), p.get_node("P_1_3"), p.get_node("P_2_3"), p.get_node("P_3_3"), p.get_node("P_4_3")],
		[p.get_node("P_0_4"), p.get_node("P_1_4"), p.get_node("P_2_4"), p.get_node("P_3_4"), p.get_node("P_4_4")],
	]
	for row: Array in _grid:
		for parcel: Node2D in row:
			parcel.visible = false


# ── Public API ────────────────────────────────────────────────────────────────

func build_map(built_plots: Array, entry_plot: Vector2i, enter_dir: String) -> void:
	RenderingServer.set_default_clear_color(Color("#292929"))
	_show_built_parcels(built_plots)
	_configure_walls()
	var start_p: Node2D = _grid[entry_plot.y][entry_plot.x]
	start_p.set_entrance(enter_dir)
	center_on_entry(entry_plot)


func center_on_entry(entry_plot: Vector2i) -> void:
	var parcel: Node2D = _grid[entry_plot.y][entry_plot.x]
	var target := parcel.global_position + Vector2(PARCEL_SZ * TILE_PX, PARCEL_SZ * TILE_PX) * (SCALE / 2.0)
	camera.global_position = target
	camera.zoom = Vector2(1.0, 1.0)
	_set_camera_limits()


func _show_built_parcels(built_plots: Array) -> void:
	for plot in built_plots:
		var x: int = plot["x"]
		var y: int = plot["y"]
		_grid[y][x].visible = true


func _configure_walls() -> void:
	for y in grid_rows:
		for x in grid_cols:
			var parzelle: Node2D = _grid[y][x]
			if not parzelle.visible:
				continue
			parzelle.configure({
				"top":    _is_built(x, y - 1),
				"bottom": _is_built(x, y + 1),
				"left":   _is_built(x - 1, y),
				"right":  _is_built(x + 1, y),
			})


func _is_built(x: int, y: int) -> bool:
	if x < 0 or x >= grid_cols or y < 0 or y >= grid_rows:
		return false
	return _grid[y][x].visible


func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local := ($WorldRoot as Node2D).to_local(world_pos)
	var gx := int((local.x - WALK_W * TILE_PX) / (PARCEL_SZ * TILE_PX))
	var gy := int((local.y - WALK_W * TILE_PX) / (PARCEL_SZ * TILE_PX))
	return Vector2i(gx, gy)


func is_buildable(x: int, y: int) -> bool:
	if x < 0 or x >= grid_cols or y < 0 or y >= grid_rows:
		return false
	return not _grid[y][x].visible


func place_room(parcel_x: int, parcel_y: int, room_scene: PackedScene, hotel_id: int,
		door_rot: int, door_off: int, tile_x: int, tile_y: int) -> void:
	var parcel: Node2D = _grid[parcel_y][parcel_x]
	var is_new := not parcel.visible
	parcel.visible = true
	parcel.spawn_room(room_scene, door_rot, door_off, tile_x, tile_y)
	if is_new:
		SaveManager.set_plot_built(hotel_id, parcel_x, parcel_y)
		_configure_walls()


func is_parcel_owned(x: int, y: int) -> bool:
	if x < 0 or x >= grid_cols or y < 0 or y >= grid_rows:
		return false
	return _grid[y][x].visible


func is_tile_free(parcel_x: int, parcel_y: int, tile_x: int, tile_y: int, w: int, h: int) -> bool:
	if not is_parcel_owned(parcel_x, parcel_y):
		return false
	return _grid[parcel_y][parcel_x].is_area_free(tile_x, tile_y, w, h)


func get_first_owned_parcel() -> Vector2i:
	for y: int in grid_rows:
		for x: int in grid_cols:
			if _grid[y][x].visible:
				return Vector2i(x, y)
	return Vector2i(0, 0)


func get_world_root() -> Node2D:
	return $WorldRoot


# ── Kamera ────────────────────────────────────────────────────────────────────

func _set_camera_limits() -> void:
	var map_px: float = (grid_cols * PARCEL_SZ + WALK_W * 2) * TILE_PX * SCALE
	var vp    := get_viewport_rect().size
	camera.limit_left   = -int(vp.x / 2.0)
	camera.limit_top    = -int(vp.y / 2.0)
	camera.limit_right  = int(map_px) + int(vp.x / 2.0)
	camera.limit_bottom = int(map_px) + int(vp.y / 2.0)


func _process(delta: float) -> void:
	_handle_wasd_pan(delta)
	_handle_keyboard_zoom(delta)


func _handle_wasd_pan(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_D): dir.x += 1.0
	if Input.is_key_pressed(KEY_A): dir.x -= 1.0
	if Input.is_key_pressed(KEY_S): dir.y += 1.0
	if Input.is_key_pressed(KEY_W): dir.y -= 1.0
	if dir != Vector2.ZERO:
		camera.position += dir.normalized() * PAN_SPEED * delta / camera.zoom.x


func _handle_keyboard_zoom(delta: float) -> void:
	if Input.is_key_pressed(KEY_KP_MULTIPLY):
		camera.zoom = Vector2(1.0, 1.0)
		return
	var zoom_dir := 0.0
	if   Input.is_key_pressed(KEY_EQUAL)   or Input.is_key_pressed(KEY_KP_ADD):      zoom_dir =  1.0
	elif Input.is_key_pressed(KEY_MINUS)   or Input.is_key_pressed(KEY_KP_SUBTRACT): zoom_dir = -1.0
	if zoom_dir != 0.0:
		_apply_zoom(zoom_dir * ZOOM_STEP * delta * 10.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion and _drag_active:
		var mm := event as InputEventMouseMotion
		camera.position = _cam_origin - (mm.position - _drag_origin) / camera.zoom


func _handle_mouse_button(mb: InputEventMouseButton) -> void:
	match mb.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			if mb.pressed: _apply_zoom(ZOOM_STEP)
		MOUSE_BUTTON_WHEEL_DOWN:
			if mb.pressed: _apply_zoom(-ZOOM_STEP)
		MOUSE_BUTTON_RIGHT:
			_drag_active = mb.pressed
			if _drag_active:
				_drag_origin = mb.position
				_cam_origin  = camera.position


func _apply_zoom(delta: float) -> void:
	var new_zoom: float = clampf(camera.zoom.x + delta, ZOOM_MIN, ZOOM_MAX)
	camera.zoom = Vector2(new_zoom, new_zoom)
