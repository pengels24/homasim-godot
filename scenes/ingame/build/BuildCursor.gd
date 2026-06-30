extends Node2D

signal sig_room_placed(parcel_x: int, parcel_y: int, tile_x: int, tile_y: int, door_rotation: int, door_offset: int, room_rotation: int, world_center: Vector2)
signal sig_cancelled()

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
var _snap_enabled:    bool = true
var _room_w:          int = 2
var _room_h:          int = 2
var _valid_combos:    Array[Vector2i] = []
var _room_rotation:   int = 0
var _error_msg:       String = ""
var _tooltip_ui:      Node


# =============================================================================
# NEU: Wir verlangen nun direkt die PackedScene vom Menü!
func activate(map_grid: Node2D, room_scene: PackedScene) -> void:
	# ---> NEU: Zwingt das Bau-Skript, auch in der Pause komplett wach zu bleiben
	process_mode = Node.PROCESS_MODE_ALWAYS
	_map_grid     = map_grid
	_snap_enabled = GameState.snap_to_grid
	_room_scene   = room_scene

	if _room_scene == null:
		sig_cancelled.emit()
		queue_free()
		return

	var tooltip_scene = load("res://scenes/shared/BuildTooltip.tscn") as PackedScene
	if tooltip_scene:
		_tooltip_ui = tooltip_scene.instantiate()
		add_child(_tooltip_ui)

	var mouse_parcel: Vector2i = _map_grid.world_to_grid(get_global_mouse_position())
	if _map_grid.is_parcel_owned(mouse_parcel.x, mouse_parcel.y):
		_current_parcel = mouse_parcel
	else:
		_current_parcel = _map_grid.get_first_owned_parcel()
	_spawn_ghost()

# ── Ghost ─────────────────────────────────────────────────────────────────────


# =============================================================================
func _spawn_ghost() -> void:
	if is_instance_valid(_ghost):
		_ghost.queue_free()

	_ghost         = _room_scene.instantiate()
	_ghost.z_index = 10
	add_child(_ghost)
	_ghost.configure({"door_rotation": _door_rotation, "door_offset": _door_offset, "room_rotation": _room_rotation})
	var sz: Vector2i = _ghost.get_tile_size()
	_room_w = sz.x
	_room_h = sz.y
	_update_valid_combos()
	_snap_to_valid_combo()
	_ghost.configure({"door_rotation": _door_rotation, "door_offset": _door_offset})
	_update_modulate()


# =============================================================================
func _refresh_ghost() -> void:
	if not is_instance_valid(_ghost):
		return

	_ghost.configure({"door_rotation": _door_rotation, "door_offset": _door_offset, "room_rotation": _room_rotation})
	var sz: Vector2i = _ghost.get_tile_size()
	_room_w = sz.x
	_room_h = sz.y
	_update_valid_combos()
	_snap_to_valid_combo()
	_ghost.configure({"door_rotation": _door_rotation, "door_offset": _door_offset})
	_error_msg = _map_grid.get_placement_error(
		_current_parcel.x, _current_parcel.y,
		_tile_pos.x, _tile_pos.y,
		_room_w, _room_h, _door_rotation, _door_offset)
	_is_valid = (_error_msg == "")
	_update_modulate()


# =============================================================================
func _update_modulate() -> void:
	if not is_instance_valid(_ghost):
		return

	_ghost.modulate = Color(0.35, 1.0, 0.45, 0.70) if _is_valid else Color(1.0, 0.35, 0.35, 0.65)
	
	if is_instance_valid(_tooltip_ui):
		if _is_valid:
			_tooltip_ui.set_error("")
		else:
			_tooltip_ui.set_error(_error_msg)

# ── Prozess – Ghost folgt Maus ────────────────────────────────────────────────

# =============================================================================
func _process(_delta: float) -> void:
	if not is_instance_valid(_ghost) or not is_instance_valid(_map_grid):
		return

	var mouse_local := (get_parent() as Node2D).to_local(get_global_mouse_position())
	var room_w_px := _room_w * TILE_PX
	var room_h_px := _room_h * TILE_PX

	var topleft: Vector2
	if _snap_enabled:
		var raw := mouse_local - Vector2(room_w_px / 2.0, room_h_px / 2.0)
		topleft = Vector2(snappedf(raw.x, float(TILE_PX)), snappedf(raw.y, float(TILE_PX)))

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
		_error_msg = _map_grid.get_placement_error(
			_current_parcel.x, _current_parcel.y,
			_tile_pos.x, _tile_pos.y,
			_room_w, _room_h, _door_rotation, _door_offset)
		_is_valid = (_error_msg == "")
		_update_modulate()

# ── Input ─────────────────────────────────────────────────────────────────────

# =============================================================================
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_try_place()

		elif mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			get_viewport().set_input_as_handled()
			sig_cancelled.emit()
			queue_free()
		return

	if event is InputEventKey:
		var ke := event as InputEventKey
		if not ke.pressed or ke.echo:
			return

		match ke.keycode:
			KEY_ESCAPE:
				get_viewport().set_input_as_handled()
				sig_cancelled.emit()
				queue_free()

			KEY_PERIOD:
				_advance_door_combo()
				_refresh_ghost()

			KEY_COMMA:
				pass  # reserviert

			KEY_R:
				_advance_room_rotation()
				_refresh_ghost()

			KEY_F:
				pass  # reserviert

# ── Kombo-Navigation ──────────────────────────────────────────────────────────

# =============================================================================
# Übersetzt die raumrelativen door-Combos in Weltkoordinaten (+ room_rotation-Offset).
# Damit bleibt .-Taste immer auf der aktuellen Wand, egal wie oft R gedrückt wurde.
func _update_valid_combos() -> void:
	if not is_instance_valid(_ghost):
		return

	var raw: Array[Vector2i] = _ghost.get_valid_door_combos()
	_valid_combos.clear()
	for c: Vector2i in raw:
		_valid_combos.append(Vector2i((c.x + _room_rotation) % 4, c.y))


# =============================================================================
func _snap_to_valid_combo() -> void:
	if _valid_combos.is_empty():
		return

	var current := Vector2i(_door_rotation, _door_offset)
	if current not in _valid_combos:
		_door_rotation = _valid_combos[0].x
		_door_offset   = _valid_combos[0].y


# =============================================================================
func _advance_room_rotation() -> void:
	_room_rotation = (_room_rotation + 1) % 4
	_door_rotation = (_door_rotation + 1) % 4


# =============================================================================
func _advance_door_combo() -> void:
	if _valid_combos.is_empty():
		return

	var current := Vector2i(_door_rotation, _door_offset)
	var idx := _valid_combos.find(current)
	var next := _valid_combos[(idx + 1) % _valid_combos.size()]
	_door_rotation = next.x
	_door_offset   = next.y


# =============================================================================
func _try_place() -> void:
	var mouse_local := (get_parent() as Node2D).to_local(get_global_mouse_position())
	var min_x := float(WALK_PX + _current_parcel.x * PARCEL_PX)
	var min_y := float(WALK_PX + _current_parcel.y * PARCEL_PX)
	if mouse_local.x < min_x or mouse_local.x > min_x + PARCEL_PX or \
			mouse_local.y < min_y or mouse_local.y > min_y + PARCEL_PX:
		return

	var room_w_px := _room_w * TILE_PX
	var room_h_px := _room_h * TILE_PX
	var sx := clampf(snappedf(mouse_local.x - room_w_px / 2.0, float(TILE_PX)), min_x, min_x + float(PARCEL_PX - room_w_px))
	var sy := clampf(snappedf(mouse_local.y - room_h_px / 2.0, float(TILE_PX)), min_y, min_y + float(PARCEL_PX - room_h_px))
	var place_tile := Vector2i(int((sx - min_x) / TILE_PX), int((sy - min_y) / TILE_PX))
	if _map_grid.is_placement_valid(
			_current_parcel.x, _current_parcel.y,
			place_tile.x, place_tile.y,
			_room_w, _room_h, _door_rotation, _door_offset):
		get_viewport().set_input_as_handled()
		var ghost_center := _ghost.global_position + Vector2(_room_w, _room_h) * float(TILE_PX) * 0.5
		sig_room_placed.emit(_current_parcel.x, _current_parcel.y, place_tile.x, place_tile.y, _door_rotation, _door_offset, _room_rotation, ghost_center)
		_spawn_ghost()
