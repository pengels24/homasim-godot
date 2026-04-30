extends Node2D
## ANG-161 – Bau-Cursor. Lebt als Kind von MapGrid/WorldRoot wenn aktiv.
## Ghost bewegt sich innerhalb eigener Parzellen, rastet auf 16px-Tile-Raster.
## Weiß = Tile-Bereich frei, Rot = Überlappung. R=Tür-Wand, T=Tür-Position, Z=Raum-Flip. ESC = abbrechen.
## ANG-186 – Validierung über MapGrid.is_placement_valid() statt Einzelchecks.

signal room_placed(parcel_x: int, parcel_y: int, tile_x: int, tile_y: int, door_rotation: int, door_offset: int, room_flip: int, world_center: Vector2)
signal cancelled()

const ROOM_SCENES: Dictionary = {
	"bed_standard": preload("res://scenes/ingame/rooms/bed_standard/Bed_Standard.tscn"),
	"bed_double":   preload("res://scenes/ingame/rooms/bed_double/Bed_Double.tscn"),
}

const WALK_PX      := 48
const TILE_PX      := 16
const PARCEL_PX    := 256
const PARCEL_TILES := 16

var _map_grid:        Node2D
var _ghost:           Node2D
var _room_scene:      PackedScene
var _current_parcel:  Vector2i = Vector2i(0, 0)
var _tile_pos:        Vector2i = Vector2i(0, 0)
var _is_valid:        bool = false
var _door_rotation:   int = 0
var _door_offset:     int = 0
var _room_flip:       int = 0
var _snap_enabled:    bool = true
var _room_w:          int = 2
var _room_h:          int = 2


func activate(map_grid: Node2D, room_type_id: String) -> void:
	_map_grid     = map_grid
	_snap_enabled = GameState.snap_to_grid
	_room_scene   = ROOM_SCENES.get(room_type_id)
	if _room_scene == null:
		cancelled.emit()
		queue_free()
		return
	var mouse_parcel: Vector2i = _map_grid.world_to_grid(get_global_mouse_position())
	if _map_grid.is_parcel_owned(mouse_parcel.x, mouse_parcel.y):
		_current_parcel = mouse_parcel
	else:
		_current_parcel = _map_grid.get_first_owned_parcel()
	_spawn_ghost()


# ── Ghost ─────────────────────────────────────────────────────────────────────

func _spawn_ghost() -> void:
	if is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost         = _room_scene.instantiate()
	_ghost.z_index = 10
	add_child(_ghost)
	_ghost.configure({"door_rotation": _door_rotation, "door_offset": _door_offset, "room_flip": _room_flip})
	var sz: Vector2i = _ghost.get_tile_size()
	_room_w = sz.x
	_room_h = sz.y
	_update_modulate()


func _refresh_ghost() -> void:
	if not is_instance_valid(_ghost):
		return
	_ghost.configure({"door_rotation": _door_rotation, "door_offset": _door_offset, "room_flip": _room_flip})
	var sz: Vector2i = _ghost.get_tile_size()
	_room_w = sz.x
	_room_h = sz.y
	_is_valid = _map_grid.is_placement_valid(
		_current_parcel.x, _current_parcel.y,
		_tile_pos.x, _tile_pos.y,
		_room_w, _room_h, _door_rotation, _door_offset)
	_update_modulate()


func _update_modulate() -> void:
	if not is_instance_valid(_ghost):
		return
	_ghost.modulate = Color(0.35, 1.0, 0.45, 0.70) if _is_valid else Color(1.0, 0.35, 0.35, 0.65)


# ── Prozess – Ghost folgt Maus ────────────────────────────────────────────────

func _process(_delta: float) -> void:
	if not is_instance_valid(_ghost) or not is_instance_valid(_map_grid):
		return

	var mouse_local := (get_parent() as Node2D).to_local(get_global_mouse_position())
	var room_w_px := _room_w * TILE_PX
	var room_h_px := _room_h * TILE_PX

	var topleft: Vector2
	if _snap_enabled:
		topleft = Vector2(snappedf(mouse_local.x, float(TILE_PX)), snappedf(mouse_local.y, float(TILE_PX))) \
			- Vector2(room_w_px / 2.0, room_h_px / 2.0)
	else:
		topleft = mouse_local - Vector2(room_w_px / 2.0, room_h_px / 2.0)

	var cx := int((mouse_local.x - WALK_PX) / PARCEL_PX)
	var cy := int((mouse_local.y - WALK_PX) / PARCEL_PX)
	if _map_grid.is_parcel_owned(cx, cy):
		_current_parcel = Vector2i(cx, cy)

	var min_x := float(WALK_PX + _current_parcel.x * PARCEL_PX)
	var min_y := float(WALK_PX + _current_parcel.y * PARCEL_PX)
	_ghost.position = Vector2(
		clampf(topleft.x, min_x, min_x + float(PARCEL_PX - room_w_px)),
		clampf(topleft.y, min_y, min_y + float(PARCEL_PX - room_h_px))
	)

	var new_tile := Vector2i(
		int((_ghost.position.x - min_x) / TILE_PX),
		int((_ghost.position.y - min_y) / TILE_PX)
	)

	if new_tile != _tile_pos:
		_tile_pos = new_tile
		_is_valid = _map_grid.is_placement_valid(
			_current_parcel.x, _current_parcel.y,
			_tile_pos.x, _tile_pos.y,
			_room_w, _room_h, _door_rotation, _door_offset)
		_update_modulate()


# ── Input ─────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_try_place()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			get_viewport().set_input_as_handled()
			cancelled.emit()
			queue_free()
		return

	if event is InputEventKey:
		var ke := event as InputEventKey
		if not ke.pressed or ke.echo:
			return
		match ke.keycode:
			KEY_ESCAPE:
				get_viewport().set_input_as_handled()
				cancelled.emit()
				queue_free()
			KEY_R:
				_door_rotation = (_door_rotation + 1) % 4
				_refresh_ghost()
			KEY_T:
				_door_offset = 1 - _door_offset
				_refresh_ghost()
			KEY_Z:
				_room_flip = 1 - _room_flip
				_refresh_ghost()


func _try_place() -> void:
	var mouse_local := (get_parent() as Node2D).to_local(get_global_mouse_position())
	var min_x := float(WALK_PX + _current_parcel.x * PARCEL_PX)
	var min_y := float(WALK_PX + _current_parcel.y * PARCEL_PX)
	var room_w_px := _room_w * TILE_PX
	var room_h_px := _room_h * TILE_PX
	var snap_pos := Vector2(snappedf(mouse_local.x, float(TILE_PX)), snappedf(mouse_local.y, float(TILE_PX)))
	var sx := clampf(snap_pos.x - room_w_px / 2.0, min_x, min_x + float(PARCEL_PX - room_w_px))
	var sy := clampf(snap_pos.y - room_h_px / 2.0, min_y, min_y + float(PARCEL_PX - room_h_px))
	var place_tile := Vector2i(int((sx - min_x) / TILE_PX), int((sy - min_y) / TILE_PX))
	if _map_grid.is_placement_valid(
			_current_parcel.x, _current_parcel.y,
			place_tile.x, place_tile.y,
			_room_w, _room_h, _door_rotation, _door_offset):
		get_viewport().set_input_as_handled()
		var ghost_center := _ghost.global_position + Vector2(_room_w, _room_h) * float(TILE_PX) * 0.5
		room_placed.emit(_current_parcel.x, _current_parcel.y, place_tile.x, place_tile.y, _door_rotation, _door_offset, _room_flip, ghost_center)
		_spawn_ghost()
