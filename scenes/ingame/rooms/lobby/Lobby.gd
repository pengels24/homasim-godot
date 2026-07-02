extends "res://scenes/ingame/rooms/Room.gd"
## Lobby – Eingangsbereich, 4×4 Tiles. Wird automatisch mit der Startparzelle platziert.
## Kein R/T/Z – Türrichtung kommt aus entrance_dir des Plots.
## Jede Door/*-Layer enthält Eingangstür + gegenüberliegende Innentüren als fertiges Paar.
## Wände zeigen sich nur auf der Eingangs-Achse (top/bottom → N+S-Wände, left/right → W+E-Wände).

# ── Nodes ─────────────────────────────────────────────────────────────────────
@onready var _door_container: Node2D      = $Door
@onready var _wall_top:       TileMapLayer = $Ground/Top
@onready var _wall_right:     TileMapLayer = $Ground/Right
@onready var _wall_left:      TileMapLayer = $Ground/Left
@onready var _wall_bottom:    TileMapLayer = $Ground/Bottom

# ── Zustand ───────────────────────────────────────────────────────────────────
var entrance_dir: String = "top"


# =============================================================================
static func get_definition() -> Dictionary:
	return {
		"id": "lobby",
		"build_cost": 0,
		"xp_reward": 0,
		"prefix": "R",
		"label": "Lobby",
		"name": "room.lobby.name",
		"category": "management",
		"icon": "",
		"nightly_price": 0,
		"locked": false,
		"in_build_menu": false,
		"req_level": 0,
		"req_tech": "",
		"max_beds": 0,
		"is_poi": true,
		"open_from": 420,
		"open_to": 1320,
	}


# ── Public API ────────────────────────────────────────────────────────────────

# =============================================================================
## ANG-218: Lobby ist immer 4×4 Tiles – base_size wird in der .tscn nicht gesetzt,
## daher hier als fester Override, damit Highlight, Hitbox und Pathfinding korrekt sind.
func get_tile_size() -> Vector2i:
	return Vector2i(4, 4)


# =============================================================================
## ANG-211 Fix: Lobby braucht eigene Implementierungen, weil sie kein Standard-
## Tür-System hat (entrance_dir statt door_rotation/door_offset).
## get_target_tile() gibt den Tile VOR der Lobby-Mitte zurück (navigierbarer Korridor).
## get_room_entry_pos() gibt die Lobby-Mitte zurück (Arbeitsposition des Staff).
func get_target_tile(map_grid: Node) -> Vector2i:
	var tile = map_grid.world_to_tile(global_position)
	var gx := tile.x
	var gy := tile.y
	# Lobby ist 4×4 – Eingang in Mitte der jeweiligen Wand (Offset 1-2 von 4)
	match entrance_dir:
		"top":    return Vector2i(gx + 1, gy - 1)      # Über der Mitte der Oberwand
		"bottom": return Vector2i(gx + 1, gy + 4)      # Unter der Mitte der Unterwand
		"left":   return Vector2i(gx - 1, gy + 1)      # Links der Mitte der Linkswand
		"right":  return Vector2i(gx + 4, gy + 1)      # Rechts der Mitte der Rechtswand
	return tile  # Fallback

func get_room_entry_pos(map_grid: Node) -> Vector2:
	var tile = map_grid.world_to_tile(global_position)
	var gx := tile.x
	var gy := tile.y
	# Arbeitsposition = 1 Tile innerhalb der Eingangsmitte (wo Staff reinläuft)
	match entrance_dir:
		"top":    return map_grid.tile_to_world(Vector2i(gx + 1, gy + 1))
		"bottom": return map_grid.tile_to_world(Vector2i(gx + 1, gy + 2))
		"left":   return map_grid.tile_to_world(Vector2i(gx + 1, gy + 1))
		"right":  return map_grid.tile_to_world(Vector2i(gx + 2, gy + 1))
	return map_grid.tile_to_world(Vector2i(gx + 2, gy + 2))  # Fallback: Lobby-Mitte


# =============================================================================
func configure(data: Dictionary) -> void:
	entrance_dir = data.get("entrance_dir", entrance_dir)
	super.configure(data)



# ── Visuals ───────────────────────────────────────────────────────────────────

# =============================================================================
func _apply_visuals() -> void:
	if not is_node_ready():
		return
	# Nur die passende Eingangs-Door-Layer anzeigen
	for child in _door_container.get_children():
		child.visible = (child.name.to_lower() == entrance_dir)
	# Nur die Eingangs-Wand einblenden – gegenüberliegende Innentür ist im Door-Layer
	_wall_top.visible    = (entrance_dir == "top")
	_wall_bottom.visible = (entrance_dir == "bottom")
	_wall_left.visible   = (entrance_dir == "left")
	_wall_right.visible  = (entrance_dir == "right")

