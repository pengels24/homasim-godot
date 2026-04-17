extends Node2D
## ANG-153 – Map-Grid: Tile-Definitionen, Karte aufbauen, Kamera-Steuerung.
## Verantwortlichkeit: TileMap-Rendering + Kamera-Input. Keine HUD-Logik.

# ── Nodes ─────────────────────────────────────────────────────────────────────
@onready var floor_layer: TileMapLayer = $WorldRoot/FloorLayer
@onready var wall_layer:  TileMapLayer = $WorldRoot/WallLayer
@onready var camera:      Camera2D     = $Camera2D

# ── Tile Source-IDs ───────────────────────────────────────────────────────────
## Müssen mit der TileSet-Reihenfolge in MapGrid.tscn übereinstimmen.
const TILE_BASE  := 0  # ground_base.png
const TILE_WALK  := 1  # ground_walking.png
const TILE_FLOOR := 2  # ground_floor.png
const TILE_BRICK := 3  # ground_brick.png
const TILE_LOBBY := 4  # ground_lobby.png
const TILE_DOOR  := 5  # main_door.png

# ── Grid-Konfiguration ────────────────────────────────────────────────────────
const PARCELS   := 5    # 5×5 Parzellen
const PARCEL_SZ := 16   # 16×16 Tiles pro Parzelle
const WALK_W    := 3    # Gehweg-Breite außen (Tiles)
const TILE_PX   := 16   # Physische Tile-Größe in Px
const SCALE     := 2.0  # WorldRoot.scale → 32px/Tile sichtbar

# ── Kamera-Konfiguration ──────────────────────────────────────────────────────
const PAN_SPEED := 400.0
const ZOOM_MIN  := 0.5
const ZOOM_MAX  := 4.0
const ZOOM_STEP := 0.15

var _drag_active := false
var _drag_origin := Vector2.ZERO
var _cam_origin  := Vector2.ZERO


# ── Public API ────────────────────────────────────────────────────────────────

## Karte aufbauen. Wird von Ingame.gd nach _ready() aufgerufen.
## Basisraster (ground_base + ground_walking) ist statisch in MapGrid.tscn vorgebaut.
func build_map(entry_plot: Vector2i, owned_plots: Array, enter_dir: String) -> void:
	RenderingServer.set_default_clear_color(Color("#292929"))
	_fill_owned_plots(owned_plots)
	_place_lobby(entry_plot, enter_dir)


## Kamera auf Eingangs-Parzelle zentrieren + Limits setzen.
func center_on_entry(entry_plot: Vector2i) -> void:
	var center_tile := Vector2(
		(WALK_W + entry_plot.x * PARCEL_SZ + PARCEL_SZ / 2.0) * TILE_PX,
		(WALK_W + entry_plot.y * PARCEL_SZ + PARCEL_SZ / 2.0) * TILE_PX
	)
	camera.position = center_tile * SCALE
	camera.zoom     = Vector2(1.0, 1.0)
	_set_camera_limits()


# ── Map-Aufbau (privat) ───────────────────────────────────────────────────────

func _fill_owned_plots(owned: Array) -> void:
	for plot in owned:
		var px: int = int(plot[0])
		var py: int = int(plot[1])
		var ox := WALK_W + px * PARCEL_SZ
		var oy := WALK_W + py * PARCEL_SZ
		for ty in PARCEL_SZ:
			for tx in PARCEL_SZ:
				floor_layer.set_cell(Vector2i(ox + tx, oy + ty), TILE_FLOOR, Vector2i(0, 0))
				if _is_outer_wall(tx, ty, px, py, owned):
					wall_layer.set_cell(Vector2i(ox + tx, oy + ty), TILE_BRICK, Vector2i(0, 0))


func _is_outer_wall(tx: int, ty: int, px: int, py: int, owned: Array) -> bool:
	if tx == 0             and not _is_owned_plot(px - 1, py,     owned): return true
	if tx == PARCEL_SZ - 1 and not _is_owned_plot(px + 1, py,     owned): return true
	if ty == 0             and not _is_owned_plot(px,     py - 1, owned): return true
	if ty == PARCEL_SZ - 1 and not _is_owned_plot(px,     py + 1, owned): return true
	return false


func _is_owned_plot(px: int, py: int, owned: Array) -> bool:
	if px < 0 or px >= PARCELS or py < 0 or py >= PARCELS:
		return false
	for plot in owned:
		if int(plot[0]) == px and int(plot[1]) == py:
			return true
	return false


## Lobby 2×2 mittig an der Eingangsseite + Türöffnung platzieren.
func _place_lobby(entry: Vector2i, enter_dir: String) -> void:
	var ox  := WALK_W + entry.x * PARCEL_SZ
	var oy  := WALK_W + entry.y * PARCEL_SZ
	var mid := PARCEL_SZ / 2 - 1  # Tiles 7+8 = Mitte der 16er-Kante

	match enter_dir:
		"top":
			wall_layer.erase_cell(Vector2i(ox + mid,     oy))
			wall_layer.erase_cell(Vector2i(ox + mid + 1, oy))
			floor_layer.set_cell(Vector2i(ox + mid,     oy), TILE_DOOR, Vector2i(0, 0))
			floor_layer.set_cell(Vector2i(ox + mid + 1, oy), TILE_DOOR, Vector2i(0, 0))
			for ly in 2:
				for lx in 2:
					floor_layer.set_cell(Vector2i(ox + mid + lx, oy + 1 + ly), TILE_LOBBY, Vector2i(0, 0))
		"bottom":
			wall_layer.erase_cell(Vector2i(ox + mid,     oy + PARCEL_SZ - 1))
			wall_layer.erase_cell(Vector2i(ox + mid + 1, oy + PARCEL_SZ - 1))
			floor_layer.set_cell(Vector2i(ox + mid,     oy + PARCEL_SZ - 1), TILE_DOOR, Vector2i(0, 0))
			floor_layer.set_cell(Vector2i(ox + mid + 1, oy + PARCEL_SZ - 1), TILE_DOOR, Vector2i(0, 0))
			for ly in 2:
				for lx in 2:
					floor_layer.set_cell(Vector2i(ox + mid + lx, oy + PARCEL_SZ - 3 + ly), TILE_LOBBY, Vector2i(0, 0))
		"left":
			wall_layer.erase_cell(Vector2i(ox, oy + mid))
			wall_layer.erase_cell(Vector2i(ox, oy + mid + 1))
			floor_layer.set_cell(Vector2i(ox, oy + mid),     TILE_DOOR, Vector2i(0, 0))
			floor_layer.set_cell(Vector2i(ox, oy + mid + 1), TILE_DOOR, Vector2i(0, 0))
			for ly in 2:
				for lx in 2:
					floor_layer.set_cell(Vector2i(ox + 1 + lx, oy + mid + ly), TILE_LOBBY, Vector2i(0, 0))
		_:  # "right"
			wall_layer.erase_cell(Vector2i(ox + PARCEL_SZ - 1, oy + mid))
			wall_layer.erase_cell(Vector2i(ox + PARCEL_SZ - 1, oy + mid + 1))
			floor_layer.set_cell(Vector2i(ox + PARCEL_SZ - 1, oy + mid),     TILE_DOOR, Vector2i(0, 0))
			floor_layer.set_cell(Vector2i(ox + PARCEL_SZ - 1, oy + mid + 1), TILE_DOOR, Vector2i(0, 0))
			for ly in 2:
				for lx in 2:
					floor_layer.set_cell(Vector2i(ox + PARCEL_SZ - 3 + lx, oy + mid + ly), TILE_LOBBY, Vector2i(0, 0))


# ── Kamera ────────────────────────────────────────────────────────────────────

func _set_camera_limits() -> void:
	var map_px: float = (PARCELS * PARCEL_SZ + WALK_W * 2) * TILE_PX * SCALE
	var vp    := get_viewport_rect().size
	var pad_x := int(vp.x / 2.0)
	var pad_y := int(vp.y / 2.0)
	camera.limit_left   = -pad_x
	camera.limit_top    = -pad_y
	camera.limit_right  = int(map_px) + pad_x
	camera.limit_bottom = int(map_px) + pad_y


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
	if   Input.is_key_pressed(KEY_EQUAL)        or Input.is_key_pressed(KEY_KP_ADD):      zoom_dir =  1.0
	elif Input.is_key_pressed(KEY_MINUS)         or Input.is_key_pressed(KEY_KP_SUBTRACT): zoom_dir = -1.0
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
