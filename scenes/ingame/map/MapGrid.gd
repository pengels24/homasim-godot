extends Node2D
## Verantwortlichkeit: Spielfeld aufbauen, Parzellen-Sichtbarkeit steuern, Kamera-Input.
## ANG-186 – Occupancy Grid: globales Bool-Grid ersetzt per-Parzelle Rect2i-Array.

signal view_saved_changed(has_saved: bool)

# ── Nodes ─────────────────────────────────────────────────────────────────────
@onready var camera: Camera2D = $Camera2D

# ── Grid-Konfiguration ────────────────────────────────────────────────────────
@export var grid_cols:  int = 5
@export var grid_rows:  int = 5
@export var start_plot: Vector2i = Vector2i(1, 0)

const PARCEL_SZ := 16
const WALK_W    := 3
const TILE_PX   := 16
const SCALE     := 2.0

# Raum-Typ → Szenen-Pfad
const SCENE_PATHS: Dictionary = {
	"bed_standard": "res://scenes/ingame/rooms/bed_standard/Bed_Standard.tscn",
	"bed_double": "res://scenes/ingame/rooms/bed_double/Bed_Double.tscn",
	"hr_office": "res://scenes/ingame/rooms/hr_office/Hr_Office.tscn",
	"sc_office": "res://scenes/ingame/rooms/sc_office/Sc_Office.tscn",
	"bar": "res://scenes/ingame/rooms/bar/Bar.tscn",
}

# ── Kamera-Konfiguration ──────────────────────────────────────────────────────
const PAN_SPEED := 400.0
const ZOOM_MIN  := 0.5
const ZOOM_MAX  := 4.0
const ZOOM_STEP := 0.15

# ── State ─────────────────────────────────────────────────────────────────────
var _drag_active:    bool     = false
var _drag_origin:    Vector2  = Vector2.ZERO
var _cam_origin:     Vector2  = Vector2.ZERO
var _entry_plot:     Vector2i = Vector2i(1, 0)
var _saved_cam_pos:  Vector2  = Vector2.ZERO
var _saved_cam_zoom: float    = 1.0
var _has_saved_view: bool     = false

var _grid: Array = []

# ── Occupancy Grid ────────────────────────────────────────────────────────────
# Flaches PackedByteArray: 1 = belegt, 0 = frei.
# Adressierung: idx = gy * _occ_w + gx, wobei gx/gy globale Tile-Koordinaten sind.
# Globale Tile = parcel_x * PARCEL_SZ + local_tile_x (analog für y).
var _occ:   PackedByteArray
var _occ_w: int
var _occ_h: int


func _ready() -> void:
	# --- central input handler verdrahten ---
	InputHandler.sig_camera_save_view_requested.connect(save_current_view)
	InputHandler.sig_camera_restore_view_requested.connect(restore_saved_view)
	InputHandler.sig_camera_pan_requested.connect(_on_input_camera_pan)
	InputHandler.sig_camera_zoom_requested.connect(_on_input_camera_zoom)
	InputHandler.sig_camera_drag_started.connect(_on_input_drag_started)
	InputHandler.sig_camera_drag_moved.connect(_on_input_drag_moved)
	InputHandler.sig_camera_drag_ended.connect(_on_input_drag_ended)
	InputHandler.sig_kill_reset_pin_requested.connect(func():
		if _has_saved_view:
			_has_saved_view = false
			view_saved_changed.emit(false)
	)

	view_saved_changed.connect(func(has_saved: bool):
		InputHandler.is_view_saved = has_saved
	)

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

func get_placed_rooms() -> Array:
	var result: Array = []
	for row: Array in _grid:
		for parcel: Node2D in row:
			if not parcel.visible:
				continue
			for child: Node in parcel.get_children():
				if "room_type_id" in child:
					result.append(child)
	return result


func build_map(built_plots: Array, entry_plot: Vector2i, enter_dir: String) -> void:
	RenderingServer.set_default_clear_color(Color("#292929"))
	_entry_plot = entry_plot
	_show_built_parcels(built_plots)
	_configure_walls()
	_occ_init()
	for plot in built_plots:
		_mark_parcel_walls(plot["x"], plot["y"])
	var start_p: Node2D = _grid[entry_plot.y][entry_plot.x]
	start_p.set_entrance(enter_dir)
	_mark_lobby_on_parcel(entry_plot.x, entry_plot.y)
	_restore_rooms(built_plots)
	center_on_entry(entry_plot)


func center_on_entry(entry_plot: Vector2i) -> void:
	var parcel: Node2D = _grid[entry_plot.y][entry_plot.x]
	var target := parcel.global_position + Vector2(PARCEL_SZ * TILE_PX, PARCEL_SZ * TILE_PX) * (SCALE / 2.0)
	camera.global_position = target
	camera.zoom = Vector2(1.0, 1.0)
	_set_camera_limits()


## Prüft ob Raum-Body + Tür-Exit-Tile vollständig frei sind.
## Ersetzt: is_tile_free + would_block_door + _door_is_blocked + _lobby_clearance_blocked.
func is_placement_valid(parcel_x: int, parcel_y: int, tile_x: int, tile_y: int,
		room_w: int, room_h: int, door_rot: int, door_off: int) -> bool:
	if tile_x < 0 or tile_y < 0 or tile_x + room_w > PARCEL_SZ or tile_y + room_h > PARCEL_SZ:
		return false
	var gx := parcel_x * PARCEL_SZ + tile_x
	var gy := parcel_y * PARCEL_SZ + tile_y
	if not _occ_free_for_room(gx, gy, room_w, room_h):
		return false
	var exit := _exit_global(parcel_x, parcel_y, tile_x, tile_y, room_w, room_h, door_rot, door_off)
	if not _occ_exit_free(exit.x, exit.y):
		return false
	if _exit_outside_parcel(parcel_x, parcel_y, exit, door_rot):
		return false
	return true


## Markiert Room-Body (Wert 1) + Exit-Tile (Wert 2) im Grid.
## Wert 2 = Exit: darf von anderen Exit-Tiles überlappt werden (Tür-zu-Tür OK).
func mark_placement(parcel_x: int, parcel_y: int, tile_x: int, tile_y: int,
		room_w: int, room_h: int, door_rot: int, door_off: int) -> void:
	var gx := parcel_x * PARCEL_SZ + tile_x
	var gy := parcel_y * PARCEL_SZ + tile_y
	_occ_mark(gx, gy, room_w, room_h)
	var exit := _exit_global(parcel_x, parcel_y, tile_x, tile_y, room_w, room_h, door_rot, door_off)
	_occ_mark_exit(exit.x, exit.y)


## Gibt Body + Exit-Tile wieder frei – Grundlage für Abrissmodus (ANG-188).
func unmark_placement(parcel_x: int, parcel_y: int, tile_x: int, tile_y: int,
		room_w: int, room_h: int, door_rot: int, door_off: int) -> void:
	var gx := parcel_x * PARCEL_SZ + tile_x
	var gy := parcel_y * PARCEL_SZ + tile_y
	_occ_clear(gx, gy, room_w, room_h)
	var exit := _exit_global(parcel_x, parcel_y, tile_x, tile_y, room_w, room_h, door_rot, door_off)
	_occ_clear(exit.x, exit.y, 1, 1)


func place_room(parcel_x: int, parcel_y: int, room_scene: PackedScene, hotel_id: int,
		door_rot: int, door_off: int, tile_x: int, tile_y: int, room_rot: int = 0,
		room_number: String = "") -> void:
	var parcel: Node2D = _grid[parcel_y][parcel_x]
	var is_new := not parcel.visible
	parcel.visible = true
	if is_new:
		_mark_parcel_walls(parcel_x, parcel_y)
	var room: Node2D = parcel.spawn_room(room_scene, door_rot, door_off, tile_x, tile_y, room_rot)
	room.room_number = room_number
	var sz: Vector2i = room.get_tile_size()
	mark_placement(parcel_x, parcel_y, tile_x, tile_y, sz.x, sz.y, door_rot, door_off)
	SaveManager.save_room_to_plot(hotel_id, parcel_x, parcel_y, room.to_dict())
	if is_new:
		SaveManager.set_plot_built(hotel_id, parcel_x, parcel_y)
		_configure_walls()
	_update_all_floor_neighbors()


func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local := ($WorldRoot as Node2D).to_local(world_pos)
	var gx := int((local.x - WALK_W * TILE_PX) / (PARCEL_SZ * TILE_PX))
	var gy := int((local.y - WALK_W * TILE_PX) / (PARCEL_SZ * TILE_PX))
	return Vector2i(gx, gy)


func is_buildable(x: int, y: int) -> bool:
	if x < 0 or x >= grid_cols or y < 0 or y >= grid_rows:
		return false
	return not _grid[y][x].visible


func is_parcel_owned(x: int, y: int) -> bool:
	if x < 0 or x >= grid_cols or y < 0 or y >= grid_rows:
		return false
	return _grid[y][x].visible


func get_first_owned_parcel() -> Vector2i:
	for y: int in grid_rows:
		for x: int in grid_cols:
			if _grid[y][x].visible:
				return Vector2i(x, y)
	return Vector2i(0, 0)


func get_world_root() -> Node2D:
	return $WorldRoot


# ── Intern – Grid-Aufbau ──────────────────────────────────────────────────────

func _show_built_parcels(built_plots: Array) -> void:
	for plot in built_plots:
		_grid[plot["y"]][plot["x"]].visible = true


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


func _restore_rooms(built_plots: Array) -> void:
	for plot in built_plots:
		var rooms: Array = plot.get("rooms", [])
		if rooms.is_empty():
			continue
		var parcel: Node2D = _grid[plot["y"]][plot["x"]]
		for room_data in rooms:
			var type_id: String = room_data.get("room_type_id", "")
			var path: String = SCENE_PATHS.get(type_id, "")
			if path.is_empty():
				continue
			var room: Node2D = parcel.restore_room(room_data, load(path) as PackedScene)
			var sz: Vector2i = room.get_tile_size()
			var tx: int = room_data.get("x_pos", 0)
			var ty: int = room_data.get("y_pos", 0)
			mark_placement(
				plot["x"], plot["y"], tx, ty,
				sz.x, sz.y,
				room_data.get("door_rotation", 0), room_data.get("door_offset", 0)
			)
	_update_all_floor_neighbors()


func _is_built(x: int, y: int) -> bool:
	if x < 0 or x >= grid_cols or y < 0 or y >= grid_rows:
		return false
	return _grid[y][x].visible


func _exit_outside_parcel(px: int, py: int, exit: Vector2i, door_rot: int) -> bool:
	match door_rot:
		0: return exit.x < px * PARCEL_SZ
		2: return exit.x >= (px + 1) * PARCEL_SZ
		1: return exit.y < py * PARCEL_SZ
		3: return exit.y >= (py + 1) * PARCEL_SZ
	return false


# ── Occupancy Grid – Kern ─────────────────────────────────────────────────────

func _occ_init() -> void:
	_occ_w = grid_cols * PARCEL_SZ
	_occ_h = grid_rows * PARCEL_SZ
	_occ   = PackedByteArray()
	_occ.resize(_occ_w * _occ_h)
	_occ.fill(0)


func _occ_mark(gx: int, gy: int, w: int, h: int) -> void:
	for dy in h:
		for dx in w:
			var idx := (gy + dy) * _occ_w + (gx + dx)
			if idx >= 0 and idx < _occ.size():
				_occ[idx] = 1


func _occ_mark_exit(gx: int, gy: int) -> void:
	if gx < 0 or gy < 0 or gx >= _occ_w or gy >= _occ_h:
		return
	var idx := gy * _occ_w + gx
	if _occ[idx] == 0:
		_occ[idx] = 2


func _occ_mark_wall(gx: int, gy: int, w: int, h: int) -> void:
	for dy in h:
		for dx in w:
			var idx := (gy + dy) * _occ_w + (gx + dx)
			if idx >= 0 and idx < _occ.size():
				_occ[idx] = 3


func _occ_clear(gx: int, gy: int, w: int, h: int) -> void:
	for dy in h:
		for dx in w:
			var idx := (gy + dy) * _occ_w + (gx + dx)
			if idx >= 0 and idx < _occ.size() and _occ[idx] != 3:
				_occ[idx] = 0


# Raum-Body darf auf freie (0) und Wand-Tiles (3) platziert werden; Body (1) und Exit (2) blockieren.
func _occ_free_for_room(gx: int, gy: int, w: int, h: int) -> bool:
	for dy in h:
		for dx in w:
			var ngx := gx + dx
			var ngy := gy + dy
			if ngx < 0 or ngy < 0 or ngx >= _occ_w or ngy >= _occ_h:
				return false
			var v := _occ[ngy * _occ_w + ngx]
			if v == 1 or v == 2:
				return false
	return true


# Exit-Tile darf auf Exit (2) landen – Tür-zu-Tür OK.
# Body (1) und Wand (3) blockieren den Exit.
func _occ_exit_free(gx: int, gy: int) -> bool:
	if gx < 0 or gy < 0 or gx >= _occ_w or gy >= _occ_h:
		return false
	var v := _occ[gy * _occ_w + gx]
	return v == 0 or v == 2 or v == 3


func _occ_has_room_body(gx: int, gy: int, w: int, h: int) -> bool:
	for dy in h:
		for dx in w:
			var ngx := gx + dx
			var ngy := gy + dy
			if ngx < 0 or ngy < 0 or ngx >= _occ_w or ngy >= _occ_h:
				continue
			if _occ[ngy * _occ_w + ngx] == 1:
				return true
	return false


func _update_all_floor_neighbors() -> void:
	for py in grid_rows:
		for px in grid_cols:
			var parcel: Node2D = _grid[py][px]
			if not parcel.visible:
				continue
			for child: Node2D in parcel.get_children():
				if not child.has_method("get_tile_size"):
					continue
				var sz: Vector2i  = child.get_tile_size()
				var gx: int = px * PARCEL_SZ + int(child.position.x / TILE_PX)
				var gy: int = py * PARCEL_SZ + int(child.position.y / TILE_PX)
				child.set_floor_neighbors(
					_occ_has_room_body(gx,        gy - 1,   sz.x, 1),
					_occ_has_room_body(gx + sz.x, gy,       1,    sz.y),
					_occ_has_room_body(gx,        gy + sz.y, sz.x, 1),
					_occ_has_room_body(gx - 1,    gy,       1,    sz.y)
				)


func _mark_parcel_walls(parcel_x: int, parcel_y: int) -> void:
	var gx := parcel_x * PARCEL_SZ
	var gy := parcel_y * PARCEL_SZ
	_occ_mark_wall(gx,                gy,                PARCEL_SZ, 1)
	_occ_mark_wall(gx,                gy + PARCEL_SZ - 1, PARCEL_SZ, 1)
	_occ_mark_wall(gx,                gy,                1, PARCEL_SZ)
	_occ_mark_wall(gx + PARCEL_SZ - 1, gy,               1, PARCEL_SZ)


func _mark_lobby_on_parcel(parcel_x: int, parcel_y: int) -> void:
	var parcel: Node2D = _grid[parcel_y][parcel_x]
	var gx := parcel_x * PARCEL_SZ
	var gy := parcel_y * PARCEL_SZ
	var lobby_rect: Rect2i = parcel.get_lobby_tile_rect()
	if lobby_rect.has_area():
		_occ_mark(gx + lobby_rect.position.x, gy + lobby_rect.position.y,
			lobby_rect.size.x, lobby_rect.size.y)
	var clearance: Rect2i = parcel.get_lobby_clearance_rect()
	if clearance.has_area():
		_occ_mark(gx + clearance.position.x, gy + clearance.position.y,
			clearance.size.x, clearance.size.y)


func _exit_global(parcel_x: int, parcel_y: int, tile_x: int, tile_y: int,
		room_w: int, room_h: int, door_rot: int, door_off: int) -> Vector2i:
	var gx := parcel_x * PARCEL_SZ + tile_x
	var gy := parcel_y * PARCEL_SZ + tile_y
	match door_rot:
		0: return Vector2i(gx - 1,                      gy + door_off * (room_h - 1))
		1: return Vector2i(gx + door_off * (room_w - 1), gy - 1)
		2: return Vector2i(gx + room_w,                  gy + door_off * (room_h - 1))
		3: return Vector2i(gx + door_off * (room_w - 1), gy + room_h)
	return Vector2i(-1, -1)


# ── Kamera ────────────────────────────────────────────────────────────────────

# =============================================================================
func _set_camera_limits() -> void:
	var map_px: float = (grid_cols * PARCEL_SZ + WALK_W * 2) * TILE_PX * SCALE
	var vp    := get_viewport_rect().size
	camera.limit_left   = -int(vp.x / 2.0)
	camera.limit_top    = -int(vp.y / 2.0)
	camera.limit_right  = int(map_px) + int(vp.x / 2.0)
	camera.limit_bottom = int(map_px) + int(vp.y / 2.0)


# =============================================================================
func _apply_zoom(delta: float) -> void:
	_clear_saved_view()
	var new_zoom: float = clampf(camera.zoom.x + delta, ZOOM_MIN, ZOOM_MAX)
	camera.zoom = Vector2(new_zoom, new_zoom)


# =============================================================================
func _clear_saved_view() -> void:
	if not _has_saved_view:
		return
	_has_saved_view = false
	view_saved_changed.emit(false)


# ── Signale vom InputHandler ausführen ────────────────────────────────────────

# =============================================================================
func _on_input_camera_pan(dir_delta: Vector2) -> void:
	camera.position += dir_delta * PAN_SPEED / camera.zoom.x


# =============================================================================
func _on_input_camera_zoom(step: float) -> void:
	# Wenn der Wert extrem klein ist, kommt er aus der _process (Tastatur-Delta)
	if abs(step) < 0.5:
		# Tastatur-Zoom drosseln, indem wir es verkleinern
		_apply_zoom(step * 0.2)
	else:
		# Mausrad-Impuls (1.0 / -1.0) sanfter machen: wir nutzen 50% des normalen Steps
		_apply_zoom(step * (ZOOM_STEP * 0.5))


# =============================================================================
func _on_input_drag_started(mouse_pos: Vector2) -> void:
	_drag_active = true
	_drag_origin = mouse_pos
	_cam_origin = camera.position
	Input.set_default_cursor_shape(Input.CURSOR_DRAG)


# =============================================================================
func _on_input_drag_moved(mouse_pos: Vector2) -> void:
	if _drag_active:
		camera.position = _cam_origin - (mouse_pos - _drag_origin) / camera.zoom


# =============================================================================
# =============================================================================
func _on_input_drag_ended() -> void:
	_drag_active = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


# =============================================================================
func save_current_view() -> void:
	_saved_cam_pos = camera.global_position
	_saved_cam_zoom = camera.zoom.x
	center_on_entry(_entry_plot)
	view_saved_changed.emit(true)


# =============================================================================
func restore_saved_view() -> void:
	camera.global_position = _saved_cam_pos
	camera.zoom = Vector2(_saved_cam_zoom, _saved_cam_zoom)
	view_saved_changed.emit(false)
