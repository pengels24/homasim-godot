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
		"is_guest_poi": false,
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
	# Für Gäste IM Hotel ist das Ziel-Tile VOR der Innentür der Lobby, nicht auf der Straße!
	match entrance_dir:
		"top":    return Vector2i(gx + 1, gy + 4) # Innentür unten
		"bottom": return Vector2i(gx + 1, gy - 1) # Innentür oben
		"left":   return Vector2i(gx + 4, gy + 1) # Innentür rechts
		"right":  return Vector2i(gx - 1, gy + 1) # Innentür links
	return tile

func get_street_tile(map_grid: Node) -> Vector2i:
	var tile = map_grid.world_to_tile(global_position)
	var gx = tile.x
	var gy = tile.y
	# Für abreisende Gäste ist das Ziel-Tile auf der Straße
	match entrance_dir:
		"top":    return Vector2i(gx + 1, gy - 1) # Straße oben
		"bottom": return Vector2i(gx + 1, gy + 4) # Straße unten
		"left":   return Vector2i(gx - 1, gy + 1) # Straße links
		"right":  return Vector2i(gx + 4, gy + 1) # Straße rechts
	return tile

func get_room_entry_pos(map_grid: Node) -> Vector2:
	var tile = map_grid.world_to_tile(global_position)
	var gx = tile.x
	var gy = tile.y
	# The wait area for guests checking out is inside the inner doors.
	match entrance_dir:
		"top":    return map_grid.tile_to_world(Vector2i(gx + 1, gy + 3)) # Inner doors at bottom
		"bottom": return map_grid.tile_to_world(Vector2i(gx + 1, gy + 0)) # Inner doors at top
		"left":   return map_grid.tile_to_world(Vector2i(gx + 3, gy + 1)) # Inner doors at right
		"right":  return map_grid.tile_to_world(Vector2i(gx + 0, gy + 1)) # Inner doors at left
	return map_grid.tile_to_world(Vector2i(gx + 3, gy + 1))


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
func _on_hotel_level_changed(_new_level: int) -> void:
	_apply_visuals()

# =============================================================================
var _room_receptions: Array[Node] = []
var _room_snack_points: Array[Node] = []

func _find_special_nodes(node: Node) -> void:
	for child in node.get_children():
		var n = child.name.to_lower()
		if "navblocker" in n:
			_find_special_nodes(child)
			continue
		if "reception" in n:
			_room_receptions.append(child)
		elif "snackpoint" in n:
			_room_snack_points.append(child)
		_find_special_nodes(child)

func _ready() -> void:
	super._ready()
	_find_special_nodes(self)
	if not GameState.sig_hotel_level_changed.is_connected(_on_hotel_level_changed):
		GameState.sig_hotel_level_changed.connect(_on_hotel_level_changed)

# =============================================================================
func get_checkout_wait_pos() -> Vector2:
	if _room_receptions.is_empty():
		return global_position + Vector2(32.0, 32.0) # Fallback center
	
	# Zufälligen Reception-Point wählen
	var r = _room_receptions[randi() % _room_receptions.size()]
	return r.global_position



# =============================================================================
## VENDING MACHINE API
## VENDING MACHINE API
func get_vending_target_world() -> Vector2:
	if not is_instance_valid(_vending_target):
		_vending_target = get_node_or_null("%VendingTargetPoint")
		
	if is_instance_valid(_vending_target):
		return _vending_target.global_position
	return global_position + Vector2(32.0, 32.0) # Fallback

func get_snack_eating_target_world() -> Vector2:
	if _room_snack_points.is_empty():
		return global_position + Vector2(32.0, 8.0) # Fallback
	var sp = _room_snack_points[randi() % _room_snack_points.size()]
	return sp.global_position

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

# =============================================================================
func get_live_details() -> Array[Dictionary]:
	var details: Array[Dictionary] = []
	
	if Engine.is_editor_hint(): return details
	
	var gm = get_tree().get_first_node_in_group("guest_manager")
	if not gm: return details
	
	# Zeige Gäste an, die sich gerade in der Lobby befinden (z.B. am Automaten oder beim Checkout)
	for guest_actor in get_tree().get_nodes_in_group("guest_actors"):
		if guest_actor._current_poi_id == "lobby" or guest_actor.current_state == 8: # 8 = AWAITING_CHECKOUT
			var guest_name = guest_actor.get_node("NameLabel").text if guest_actor.has_node("NameLabel") else "Gast"
			var status = "Wartet..."
			if guest_actor.current_state == 8: # AWAITING_CHECKOUT
				status = GameState.T("poi.lobby.checking_out")
			elif guest_actor.current_state == 4: # IN_POI
				status = GameState.T("poi.lobby.vending")
				
			details.append({
				"name": guest_name,
				"status": status,
				"icon": "res://assets/UI/icons/icon_guest.png"
			})
			
	return details
