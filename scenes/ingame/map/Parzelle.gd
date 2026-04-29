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
const ROOM_TILES   := 2   # alle Räume sind aktuell 2×2 Tiles (16px × 2 = 32px)

# ── Zustand ───────────────────────────────────────────────────────────────────
var is_built:     bool   = false
var has_entrance: bool   = false
var entrance_dir: String = ""

var _occupied:      Array[Rect2i] = []   # belegte Tile-Bereiche innerhalb der Parzelle
var _walls_marked:  bool         = false  # Randtiles einmalig belegen


# ── Public API ────────────────────────────────────────────────────────────────

func configure(neighbors: Dictionary) -> void:
	wall_n.visible = not neighbors.get("top",    false)
	wall_s.visible = not neighbors.get("bottom", false)
	wall_w.visible = not neighbors.get("left",   false)
	wall_e.visible = not neighbors.get("right",  false)


func set_entrance(dir: String) -> void:
	has_entrance = true
	entrance_dir = dir
	_ensure_walls_marked()
	_spawn_lobby()


func buy(hotel_id: int) -> void:
	is_built = true
	visible  = true
	SaveManager.set_plot_built(hotel_id, _grid_x(), _grid_y())


func spawn_room(room_scene: PackedScene, door_rot: int, door_off: int, tile_x: int, tile_y: int, rflip: int = 0) -> Node2D:
	_ensure_walls_marked()
	var room: Node2D = room_scene.instantiate()
	add_child(room)
	room.configure({"door_rotation": door_rot, "door_offset": door_off, "room_flip": rflip, "x_pos": tile_x, "y_pos": tile_y})
	room.position = Vector2(tile_x * TILE_PX, tile_y * TILE_PX)
	var sz: Vector2i = room.get_tile_size()
	mark_occupied(tile_x, tile_y, sz.x, sz.y)
	return room


## Gespeicherten Raum aus Save-Daten wiederherstellen (kein save_room_to_plot nötig).
func restore_room(room_data: Dictionary, room_scene: PackedScene) -> void:
	_ensure_walls_marked()
	var room: Node2D = room_scene.instantiate()
	add_child(room)
	room.configure(room_data)
	var tx: int = room_data.get("x_pos", 0)
	var ty: int = room_data.get("y_pos", 0)
	room.position = Vector2(tx * TILE_PX, ty * TILE_PX)
	var sz: Vector2i = room.get_tile_size()
	mark_occupied(tx, ty, sz.x, sz.y)


## 1-Tile-Streifen direkt vor der Lobby-Innentür – darf nicht verbaut werden.
func get_lobby_clearance_rect() -> Rect2i:
	if not has_entrance:
		return Rect2i()
	var lp := _lobby_position()
	var lx: int = int(lp.x / TILE_PX)
	var ly: int = int(lp.y / TILE_PX)
	match entrance_dir:
		"top":    return Rect2i(lx, ly + LOBBY_TILES, LOBBY_TILES, 1)
		"bottom": return Rect2i(lx, ly - 1,           LOBBY_TILES, 1)
		"left":   return Rect2i(lx + LOBBY_TILES, ly,  1, LOBBY_TILES)
		"right":  return Rect2i(lx - 1, ly,            1, LOBBY_TILES)
	return Rect2i()


## Gibt true zurück wenn das Rect ein Türexit-Tile eines bereits platzierten Raums blockiert.
func would_block_any_door(test_rect: Rect2i) -> bool:
	for child in get_children():
		if not child.has_method("get_tile_size"):
			continue
		var exit := _door_exit_tile(child)
		if exit.x >= 0 and test_rect.has_point(exit):
			return true
	return false


func _door_exit_tile(room: Node2D) -> Vector2i:
	var rx: int = room.x_pos
	var ry: int = room.y_pos
	var sz: Vector2i = room.get_tile_size()
	# door_offset * (dim - 1): 0 → erste Position, 1 → letzte Position der Wand.
	# Funktioniert für alle Raumgrößen (2×2, 4×2, 2×4 …).
	match room.door_rotation:
		0: return Vector2i(rx - 1,                              ry + room.door_offset * (sz.y - 1))
		1: return Vector2i(rx + room.door_offset * (sz.x - 1), ry - 1)
		2: return Vector2i(rx + sz.x,                           ry + room.door_offset * (sz.y - 1))
		3: return Vector2i(rx + room.door_offset * (sz.x - 1), ry + sz.y)
	return Vector2i(-1, -1)


## Prüft ob der Tile-Bereich (tile_x, tile_y, w×h) vollständig frei ist.
func is_area_free(tile_x: int, tile_y: int, w: int, h: int) -> bool:
	var test := Rect2i(tile_x, tile_y, w, h)
	for r: Rect2i in _occupied:
		if r.intersects(test):
			return false
	return true


func mark_occupied(tile_x: int, tile_y: int, w: int, h: int) -> void:
	_occupied.append(Rect2i(tile_x, tile_y, w, h))


# ── Intern ────────────────────────────────────────────────────────────────────

func _spawn_lobby() -> void:
	var lobby: Node2D = LOBBY_SCENE.instantiate()
	add_child(lobby)
	lobby.position = _lobby_position()
	lobby.configure({ "entrance_dir": entrance_dir })
	# Lobby-Tiles als belegt markieren
	var lp := _lobby_position()
	mark_occupied(int(lp.x / TILE_PX), int(lp.y / TILE_PX), LOBBY_TILES, LOBBY_TILES)


func _lobby_position() -> Vector2:
	var center_offset: int = int((PARCEL_TILES - LOBBY_TILES) / 2.0) * TILE_PX  # 96px
	var inset: int = TILE_PX  # 1 Tile Abstand zur Parzellen-Außenmauer
	match entrance_dir:
		"top":    return Vector2(center_offset, inset)
		"bottom": return Vector2(center_offset, (PARCEL_TILES - LOBBY_TILES - 1) * TILE_PX)
		"left":   return Vector2(inset, center_offset)
		"right":  return Vector2((PARCEL_TILES - LOBBY_TILES - 1) * TILE_PX, center_offset)
	return Vector2(center_offset, center_offset)


func _ensure_walls_marked() -> void:
	if _walls_marked:
		return
	_walls_marked = true
	mark_occupied(0,                  0,  PARCEL_TILES, 1)  # oben
	mark_occupied(0,  PARCEL_TILES - 1,  PARCEL_TILES, 1)  # unten
	mark_occupied(0,                  0,  1, PARCEL_TILES)  # links
	mark_occupied(PARCEL_TILES - 1,   0,  1, PARCEL_TILES)  # rechts


func _grid_x() -> int:
	return name.get_slice("_", 1).to_int()


func _grid_y() -> int:
	return name.get_slice("_", 2).to_int()
