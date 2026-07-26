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

# ── Konstanten (Snack-Automat) ────────────────────────────────────────────────
const VENDING_MACHINE_PRICE: int = 5
const VENDING_MACHINE_EXP: int = 3
const VENDING_MACHINE_SATURATION: int = 20

@onready var _vending_machine: Node2D = get_node_or_null("%VendingMachine") if get_node_or_null("%VendingMachine") else get_node_or_null("%VendingMashine")
@onready var _vending_target: Node2D = get_node_or_null("%VendingTargetPoint")


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
		"open_from": 0,
		"open_to": 0,
		"reception_open_from": 420,
		"reception_open_to": 1320,
	}


# ── Public API ────────────────────────────────────────────────────────────────

# =============================================================================
## ANG-218: Lobby ist immer 4×4 Tiles – base_size wird in der .tscn nicht gesetzt,
## daher hier als fester Override, damit Highlight und Hitbox korrekt sind.
func get_tile_size() -> Vector2i:
	return Vector2i(4, 4)


# =============================================================================
## ANG-211: Lobby ist Systemraum – keine Sauberkeits-/Wartungsabnahme,
## keine Service-Tickets. _on_hour_passed() des Elternraums wird nicht ausgeführt.
func _on_hour_passed(_hour: int) -> void:
	pass  # Systemraum: Werte bleiben konstant bei 100%

# =============================================================================
## ANG-211 Fix: Lobby braucht eigene Implementierungen, weil sie kein Standard-
## Tür-System hat (entrance_dir statt door_rotation/door_offset).
## get_target_tile() gibt den Tile VOR der Lobby-Mitte zurück (navigierbarer Korridor).
## get_room_entry_pos() gibt die Lobby-Mitte zurück (Arbeitsposition des Staff).
func get_target_tile(map_grid: Node) -> Vector2i:
	var tile = map_grid.world_to_tile(global_position)
	var gx = tile.x
	var gy = tile.y
	# Lobby 4×4 – Exit-Tile direkt vor dem Eingang (nachgewiesen navigierbar)
	match entrance_dir:
		"top":    return Vector2i(gx,     gy - 1)  # Korridor über Lobby
		"bottom": return Vector2i(gx,     gy + 4)  # Korridor unter Lobby
		"left":   return Vector2i(gx - 1, gy)      # Korridor links der Lobby
		"right":  return Vector2i(gx + 4, gy)      # Korridor rechts der Lobby
	return tile  # Fallback

func get_room_entry_pos(map_grid: Node) -> Vector2:
	var tile = map_grid.world_to_tile(global_position)
	var gx = tile.x
	var gy = tile.y
	# Arbeitsposition = 1 Tile innerhalb des Eingangs
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
	# Systemraum: Werte immer bei 100% halten, unabhängig vom Savegame
	cleanliness_level = 100
	maintenance_level = 100
	is_service_requested = false
	is_repair_requested = false


# =============================================================================
func _ready() -> void:
	super._ready()
	if not GameState.sig_hotel_level_changed.is_connected(_on_hotel_level_changed):
		GameState.sig_hotel_level_changed.connect(_on_hotel_level_changed)

func _on_hotel_level_changed(_new_level: int) -> void:
	_apply_visuals()


# =============================================================================
## VENDING MACHINE API
func get_vending_target(map_grid: Node) -> Vector2i:
	if not is_instance_valid(_vending_target):
		_vending_target = get_node_or_null("%VendingTargetPoint")
		
	if is_instance_valid(_vending_target):
		return map_grid.world_to_tile(_vending_target.global_position)
	return get_target_tile(map_grid)

func get_snack_eating_target_world() -> Vector2:
	# Essenspunkt ist oben mittig über den Tischen (lokal ca. x=32, y=8)
	return global_position + Vector2(32.0, 8.0)

func get_solid_tiles() -> Array[Vector2i]:
	var solid: Array[Vector2i] = []
	# Zentrum (Tische)
	solid.append(Vector2i(1, 1))
	solid.append(Vector2i(2, 1))
	solid.append(Vector2i(1, 2))
	solid.append(Vector2i(2, 2))
	
	# Ecken (Wände mit Pflanzen)
	solid.append(Vector2i(0, 0))
	solid.append(Vector2i(3, 0))
	solid.append(Vector2i(0, 3))
	solid.append(Vector2i(3, 3))
	return solid

func buy_snack(budget: int) -> bool:
	if budget >= VENDING_MACHINE_PRICE:
		GameState.add_money(VENDING_MACHINE_PRICE)
		GameState.add_exp(VENDING_MACHINE_EXP, "Snack-Automat")
		return true
	return false

# ── Visuals ───────────────────────────────────────────────────────────────────

# =============================================================================
func _apply_visuals() -> void:
	if not is_node_ready():
		return
		
	if not is_instance_valid(_vending_machine):
		_vending_machine = get_node_or_null("%VendingMachine")
	if is_instance_valid(_vending_machine):
		_vending_machine.visible = GameState.get_level() >= 2
		
	# Nur die passende Eingangs-Door-Layer anzeigen
	for child in _door_container.get_children():
		child.visible = (child.name.to_lower() == entrance_dir)
	# Nur die Eingangs-Wand einblenden – gegenüberliegende Innentür ist im Door-Layer
	_wall_top.visible    = (entrance_dir == "top")
	_wall_bottom.visible = (entrance_dir == "bottom")
	_wall_left.visible   = (entrance_dir == "left")
	_wall_right.visible  = (entrance_dir == "right")
