extends Node2D
## ANG-161 – Bau-Cursor. Lebt als Kind von MapGrid/WorldRoot wenn aktiv.
## Ghost bewegt sich innerhalb eigener Parzellen, rastet auf 16px-Tile-Raster.
## Weiß = Tile-Bereich frei, Rot = Überlappung. R/T = Tür drehen/flippen. ESC = abbrechen.

signal room_placed(parcel_x: int, parcel_y: int, tile_x: int, tile_y: int, door_rotation: int, door_offset: int)
signal cancelled()

const ROOM_SCENES: Dictionary = {
	"bed_standard": preload("res://scenes/ingame/rooms/bed_standard/Bed_Standard.tscn"),
}

# Koordinaten-Konstanten – spiegeln MapGrid-Werte wider
const WALK_PX      := 48    # WALK_W(3) × TILE_PX(16)
const TILE_PX      := 16
const PARCEL_PX    := 256   # PARCEL_SZ(16) × TILE_PX(16)
const PARCEL_TILES := PARCEL_PX / TILE_PX  # = 16
const ROOM_TILE_PX := 32    # 2 Tiles × 16px – Raum-Ausdehnung in Pixeln (visual)
const ROOM_TILES   := 2     # Tile-Seitenlänge des Raums
const ROOM_HALF    := ROOM_TILE_PX / 2   # = 16 – halbe Raumbreite für Zentrierung unter Maus

var _map_grid:        Node2D
var _ghost:           Node2D
var _room_scene:      PackedScene
var _current_parcel:  Vector2i = Vector2i(0, 0)   # aktive (owned) Parzelle
var _tile_pos:        Vector2i = Vector2i(0, 0)   # Tile-Position innerhalb der Parzelle
var _is_valid:        bool = false
var _door_rotation:   int = 0
var _door_offset:     int = 0
var _snap_enabled:    bool = true


func activate(map_grid: Node2D, room_type_id: String) -> void:
	_map_grid     = map_grid
	_snap_enabled = GameState.snap_to_grid
	_room_scene   = ROOM_SCENES.get(room_type_id)
	if _room_scene == null:
		cancelled.emit()
		queue_free()
		return
	# Startparzelle: unter der Maus wenn owned, sonst erste owned Parzelle
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
	_ghost.configure({"door_rotation": _door_rotation, "door_offset": _door_offset})
	_update_modulate()


func _refresh_ghost() -> void:
	if not is_instance_valid(_ghost):
		return
	_ghost.configure({"door_rotation": _door_rotation, "door_offset": _door_offset})
	_is_valid = _map_grid.is_tile_free(
		_current_parcel.x, _current_parcel.y, _tile_pos.x, _tile_pos.y, ROOM_TILES, ROOM_TILES) \
		and not _door_is_blocked(_tile_pos.x, _tile_pos.y) \
		and not _lobby_clearance_blocked(_tile_pos.x, _tile_pos.y)
	_update_modulate()


func _update_modulate() -> void:
	if not is_instance_valid(_ghost):
		return
	# Weiß = gültig, Rot = ungültig (Überlappung oder außerhalb)
	_ghost.modulate = Color(0.95, 0.95, 0.95, 0.65) if _is_valid else Color(1.0, 0.35, 0.35, 0.65)


# ── Prozess – Ghost folgt Maus, bleibt in owned Parzellen ────────────────────

func _process(_delta: float) -> void:
	if not is_instance_valid(_ghost) or not is_instance_valid(_map_grid):
		return

	var mouse_local := (get_parent() as Node2D).to_local(get_global_mouse_position())

	# Ghost-Top-Left = Maus minus halbe Raumgröße → Ghost zentriert unter Maus
	var topleft: Vector2
	if _snap_enabled:
		topleft = Vector2(snappedf(mouse_local.x, float(TILE_PX)), snappedf(mouse_local.y, float(TILE_PX))) - Vector2(ROOM_HALF, ROOM_HALF)
	else:
		topleft = mouse_local - Vector2(ROOM_HALF, ROOM_HALF)

	# Parzel-Erkennung auf Mausposition (nicht Top-Left) – wechselt beim Grenzübertritt
	var cx := int((mouse_local.x - WALK_PX) / PARCEL_PX)
	var cy := int((mouse_local.y - WALK_PX) / PARCEL_PX)
	if _map_grid.is_parcel_owned(cx, cy):
		_current_parcel = Vector2i(cx, cy)

	# Ghost auf aktive Parzelle einschränken
	var min_x := float(WALK_PX + _current_parcel.x * PARCEL_PX)
	var min_y := float(WALK_PX + _current_parcel.y * PARCEL_PX)
	_ghost.position = Vector2(
		clampf(topleft.x, min_x, min_x + float(PARCEL_PX - ROOM_TILE_PX)),
		clampf(topleft.y, min_y, min_y + float(PARCEL_PX - ROOM_TILE_PX))
	)

	# Tile-Position innerhalb der Parzelle
	var new_tile := Vector2i(
		int((_ghost.position.x - min_x) / TILE_PX),
		int((_ghost.position.y - min_y) / TILE_PX)
	)

	# Validität nur neu berechnen wenn Tile sich geändert hat
	if new_tile != _tile_pos:
		_tile_pos = new_tile
		_is_valid = _map_grid.is_tile_free(
			_current_parcel.x, _current_parcel.y, _tile_pos.x, _tile_pos.y, ROOM_TILES, ROOM_TILES) \
			and not _door_is_blocked(_tile_pos.x, _tile_pos.y) \
			and not _lobby_clearance_blocked(_tile_pos.x, _tile_pos.y)
		_update_modulate()


# ── Input – _input für Vorrang vor MapGrid-Kamera (_unhandled_input) ─────────

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_try_place()
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


func _try_place() -> void:
	# Beim Platzieren immer auf Tile-Raster snappen – unabhängig von snap_enabled
	var mouse_local := (get_parent() as Node2D).to_local(get_global_mouse_position())
	var min_x := float(WALK_PX + _current_parcel.x * PARCEL_PX)
	var min_y := float(WALK_PX + _current_parcel.y * PARCEL_PX)
	var snap_pos := Vector2(snappedf(mouse_local.x, float(TILE_PX)), snappedf(mouse_local.y, float(TILE_PX)))
	var sx := clampf(snap_pos.x - float(ROOM_HALF), min_x, min_x + float(PARCEL_PX - ROOM_TILE_PX))
	var sy := clampf(snap_pos.y - float(ROOM_HALF), min_y, min_y + float(PARCEL_PX - ROOM_TILE_PX))
	var place_tile := Vector2i(int((sx - min_x) / TILE_PX), int((sy - min_y) / TILE_PX))
	if _map_grid.is_tile_free(_current_parcel.x, _current_parcel.y, place_tile.x, place_tile.y, ROOM_TILES, ROOM_TILES) \
			and not _door_is_blocked(place_tile.x, place_tile.y) \
			and not _lobby_clearance_blocked(place_tile.x, place_tile.y):
		get_viewport().set_input_as_handled()
		room_placed.emit(_current_parcel.x, _current_parcel.y, place_tile.x, place_tile.y, _door_rotation, _door_offset)
		queue_free()


# ── Hilfsfunktionen ───────────────────────────────────────────────────────────

func _door_is_blocked(tile_x: int, tile_y: int) -> bool:
	# Außenwand-Schnellcheck + Belegtheits-Check der Tiles direkt vor der Tür
	match _door_rotation:
		0:  # Tür links
			if tile_x <= 1: return true
			return not _map_grid.is_tile_free(_current_parcel.x, _current_parcel.y,
				tile_x - 1, tile_y, 1, ROOM_TILES)
		1:  # Tür oben
			if tile_y <= 1: return true
			return not _map_grid.is_tile_free(_current_parcel.x, _current_parcel.y,
				tile_x, tile_y - 1, ROOM_TILES, 1)
		2:  # Tür rechts
			if tile_x + ROOM_TILES >= PARCEL_TILES - 1: return true
			return not _map_grid.is_tile_free(_current_parcel.x, _current_parcel.y,
				tile_x + ROOM_TILES, tile_y, 1, ROOM_TILES)
		3:  # Tür unten
			if tile_y + ROOM_TILES >= PARCEL_TILES - 1: return true
			return not _map_grid.is_tile_free(_current_parcel.x, _current_parcel.y,
				tile_x, tile_y + ROOM_TILES, ROOM_TILES, 1)
	return false


func _lobby_clearance_blocked(tile_x: int, tile_y: int) -> bool:
	var clearance: Rect2i = _map_grid.get_lobby_clearance_rect(_current_parcel.x, _current_parcel.y)
	return clearance.has_area() and Rect2i(tile_x, tile_y, ROOM_TILES, ROOM_TILES).intersects(clearance)
