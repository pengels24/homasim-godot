extends Node2D

# ── Nodes ─────────────────────────────────────────────────────────────────────
@onready var wall_n: Node2D = $WallN
@onready var wall_s: Node2D = $WallS
@onready var wall_w: Node2D = $WallW
@onready var wall_e: Node2D = $WallE

# ── Konstanten ────────────────────────────────────────────────────────────────
const LOBBY_SCENE := preload("res://scenes/ingame/rooms/lobby/Lobby.tscn")

# ── Zustand ───────────────────────────────────────────────────────────────────
var is_built:     bool   = false
var has_entrance: bool   = false
var entrance_dir: String = ""


# ── Public API ────────────────────────────────────────────────────────────────

func configure(neighbors: Dictionary) -> void:
	wall_n.visible = not neighbors.get("top",    false)
	wall_s.visible = not neighbors.get("bottom", false)
	wall_w.visible = not neighbors.get("left",   false)
	wall_e.visible = not neighbors.get("right",  false)


func set_entrance(dir: String) -> void:
	has_entrance = true
	entrance_dir = dir
	_spawn_lobby()


func buy(hotel_id: int) -> void:
	is_built = true
	visible  = true
	# grid_pos wird von MapGrid gesetzt bevor buy() möglich ist
	SaveManager.set_plot_built(hotel_id, _grid_x(), _grid_y())


# ── Intern ────────────────────────────────────────────────────────────────────

const PARCEL_TILES := 16
const LOBBY_TILES  := 4
const TILE_PX      := 16

func _spawn_lobby() -> void:
	var lobby: Node2D = LOBBY_SCENE.instantiate()
	add_child(lobby)
	lobby.position = _lobby_position()
	lobby.configure({ "entrance_dir": entrance_dir })


func _lobby_position() -> Vector2:
	var center_offset: int = (PARCEL_TILES - LOBBY_TILES) / 2 * TILE_PX  # 96px
	var inset: int = TILE_PX  # 1 Tile Abstand zur Parzellen-Außenmauer
	match entrance_dir:
		"top":    return Vector2(center_offset, inset)
		"bottom": return Vector2(center_offset, (PARCEL_TILES - LOBBY_TILES - 1) * TILE_PX)
		"left":   return Vector2(inset, center_offset)
		"right":  return Vector2((PARCEL_TILES - LOBBY_TILES - 1) * TILE_PX, center_offset)
	return Vector2(center_offset, center_offset)


func _grid_x() -> int:
	# Name ist "P_x_y" – x aus dem Namen lesen
	return name.get_slice("_", 1).to_int()


func _grid_y() -> int:
	return name.get_slice("_", 2).to_int()
