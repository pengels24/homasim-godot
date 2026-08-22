extends Node2D
## Basisklasse für alle Raumtypen. Lobby, SingleRoom etc. erben davon.

const TILE_PX := 16

@export var base_size := Vector2i(2, 2)

# Namensschema für Tür-Slots. Reihenfolge: 0=L 1=T 2=R 3=B.
# L: von unten nach oben  T: von links nach rechts
# R: von oben nach unten  B: von rechts nach links
# Max 5 Slots je Wand (für Räume bis 5 Tiles Wandlänge).
const DOOR_SLOTS: Array[Array] = [
	["L1", "L2", "L3", "L4", "L5"],
	["T1", "T2", "T3", "T4", "T5"],
	["R1", "R2", "R3", "R4", "R5"],
	["B1", "B2", "B3", "B4", "B5"],
]

# externe
# (GuestManager entfernt, wird vorerst nicht für Indikator genutzt)

# ── Raum-Identität ────────────────────────────────────────────────────────────
var room_type_id: String = ""     # "lobby", "bed_standard", …
var room_level:   int    = 1
var room_number:  String = ""     # "101", "" bei Lobby

# ── Position im Stockwerk ─────────────────────────────────────────────────────
var x_pos: int = 0
var y_pos: int = 0
var floor_num: int = 1

# ── Zustand ───────────────────────────────────────────────────────────────────
var cleanliness_level: int = 100
var maintenance_level: int = 100
var is_service_requested: bool = false
var is_built := false
var is_active := false

const SHOW_DEBUG_PATHS := true # Umschalter für das rote Wegnetz im Raum
var is_pending_demolish: bool = false:
	set(value):
		is_pending_demolish = value
		if is_inside_tree():
			_update_indicator()
var is_repair_requested: bool = false

# ── Tür / Orientierung ────────────────────────────────────────────────────────
var door_rotation: int = 0   # Welche Wand   0–3  (.-Taste: nur Tür wandert)
var door_offset:   int = 0   # Position auf Wand 0–1  (,-Taste)
var room_rotation: int = 0   # Gesamtrotation 0-3     (R-Taste: alles dreht)

var acquired_traits: Array = []
var custom_color: Color = Color.WHITE

# ── UI / Indikatoren ──────────────────────────────────────────────────────────
const INDICATOR_SCENE := preload("res://scenes/ingame/rooms/RoomStatusIndicator.tscn")
var _status_indicator: RoomStatusIndicator
var _overlay_rect: ColorRect

# =============================================================================
func set_overlay_color(color: Color) -> void:
	if not is_instance_valid(_overlay_rect):
		_overlay_rect = ColorRect.new()
		var sz = get_tile_size()
		_overlay_rect.size = Vector2(sz.x, sz.y) * TILE_PX
		_overlay_rect.position = Vector2.ZERO
		_overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_overlay_rect.z_index = 50 # Über dem Boden, unter UI (UI hat meist 100+)
		add_child(_overlay_rect)
		
	if color.a <= 0.0:
		_overlay_rect.visible = false
	else:
		_overlay_rect.visible = true
		_overlay_rect.color = color

# =============================================================================
# FURNITURE INTERACTION (Seats & Beds)
# =============================================================================
var _room_seats: Array[Dictionary] = []
var _room_beds: Array[Dictionary] = []
var _room_seats_staff_only: Array[Dictionary] = [] # z.B. Bademeisterhochsitz

func _find_furniture_recursive(node: Node) -> void:
	for child in node.get_children():
		# Generell alle UI-Eigenschaften von Möbeln (Blocker, Betten, Stühle) für die Maus ignorieren
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
		var n = child.name.to_lower()
		# Blocker überspringen (nicht als interaktive Möbelstücke zählen)
		if "navblocker" in n:
			_find_furniture_recursive(child)
			continue
			
		if "chairspecial" in n:
			# Nur für Staff (z.B. Bademeisterhochsitz) - Gäste dürfen hier nicht sitzen
			_room_seats_staff_only.append({"node": child, "occupied_by": ""})
		elif "chair" in n and n != "chairs":
			_room_seats.append({"node": child, "occupied_by": ""})
		elif "bed" in n and n != "beds":
			_room_beds.append({"node": child, "occupied_by": ""})
			
		_find_furniture_recursive(child)

func has_free_room_seat() -> bool:
	for s in _room_seats:
		if s["occupied_by"] == "": return true
	return false

func room_claim_seat(guest_id: String) -> Vector2:
	for s in _room_seats:
		if s["occupied_by"] == guest_id:
			return s["node"].global_position
	var free_seats = []
	for s in _room_seats:
		if s["occupied_by"] == "":
			free_seats.append(s)
	
	if free_seats.is_empty():
		return Vector2.INF
		
	free_seats.shuffle()
	var chosen = free_seats[0]
	chosen["occupied_by"] = guest_id
	return chosen["node"].global_position

func room_leave_seat(guest_id: String) -> void:
	for s in _room_seats:
		if s["occupied_by"] == guest_id:
			s["occupied_by"] = ""

func has_free_room_bed() -> bool:
	for b in _room_beds:
		if b["occupied_by"] == "": return true
	return false

func room_claim_bed(guest_id: String) -> Vector2:
	for b in _room_beds:
		if b["occupied_by"] == guest_id:
			return b["node"].global_position
	var free_beds = []
	for b in _room_beds:
		if b["occupied_by"] == "":
			free_beds.append(b)
			
	if free_beds.is_empty():
		return Vector2.INF
		
	free_beds.shuffle()
	var chosen = free_beds[0]
	chosen["occupied_by"] = guest_id
	return chosen["node"].global_position

func room_leave_bed(guest_id: String) -> void:
	for b in _room_beds:
		if b["occupied_by"] == guest_id:
			b["occupied_by"] = ""

# =============================================================================
# --- SMART ROOM INTERFACE ---
# =============================================================================
func get_available_interactions(_actor: Node2D) -> Array[Dictionary]:
	var interactions: Array[Dictionary] = []
	for i in range(_room_beds.size()):
		var b = _room_beds[i]
		if b["occupied_by"] == "":
			interactions.append({
				"id": "bed_" + str(i),
				"type": "sleep",
				"target_pos": b["node"].global_position,
				"duration": randf_range(30.0, 60.0)
			})
	for i in range(_room_seats.size()):
		var s = _room_seats[i]
		if s["occupied_by"] == "":
			interactions.append({
				"id": "seat_" + str(i),
				"type": "sit",
				"target_pos": s["node"].global_position,
				"duration": randf_range(10.0, 20.0)
			})
	
	interactions.append({
		"id": "wander_center",
		"type": "wander",
		"target_pos": get_service_position(),
		"duration": randf_range(10.0, 20.0)
	})
	
	interactions.append({
		"id": "wander_random",
		"type": "wander",
		"target_pos": get_random_walkable_local_pos(),
		"duration": randf_range(5.0, 15.0)
	})
	return interactions

func claim_interaction(actor_id: String, interaction_id: String) -> Dictionary:
	if interaction_id.begins_with("bed_"):
		var idx = interaction_id.replace("bed_", "").to_int()
		if idx >= 0 and idx < _room_beds.size():
			var b = _room_beds[idx]
			if b["occupied_by"] == "":
				b["occupied_by"] = actor_id
				return {
					"target_pos": b["node"].global_position,
					"look_at_pos": get_service_position(),
					"duration": randf_range(30.0, 60.0)
				}
	elif interaction_id.begins_with("seat_"):
		var idx = interaction_id.replace("seat_", "").to_int()
		if idx >= 0 and idx < _room_seats.size():
			var s = _room_seats[idx]
			if s["occupied_by"] == "":
				s["occupied_by"] = actor_id
				var table = get_node_or_null("%Table")
				var look_pos = table.global_position if is_instance_valid(table) else get_service_position()
				return {
					"target_pos": s["node"].global_position,
					"look_at_pos": look_pos,
					"duration": randf_range(10.0, 20.0)
				}
	elif interaction_id == "wander_center":
		return {
			"target_pos": get_service_position(),
			"duration": randf_range(10.0, 20.0)
		}
	elif interaction_id == "wander_random":
		return {
			"target_pos": get_random_walkable_local_pos(),
			"duration": randf_range(5.0, 15.0)
		}
	return {}

func release_interaction(actor_id: String) -> void:
	for b in _room_beds:
		if b["occupied_by"] == actor_id:
			b["occupied_by"] = ""
	for s in _room_seats:
		if s["occupied_by"] == actor_id:
			s["occupied_by"] = ""

# ── Definition (von Unterklassen überschreiben) ───────────────────────────────


# =============================================================================
## Gibt alle statischen Metadaten des Raumtyps zurück.
## Unterklassen überschreiben diese Funktion – kein zentrales Register nötig.
static func get_definition() -> Dictionary:
	return {
		"id": "",
		"build_cost": 0,
		"exp_reward": 0,
		"prefix": "Z",
		"label": "?",
		"name": "Unbekannter Raum",
		"category": "",
		"icon": "",
		"nightly_price": 0,
		"locked": false,
		"in_build_menu": false,
		"req_level": 0,
		"req_tech": "",
		"max_beds": 0,
		"open_from": 0,
		"open_to": 0,
		"valid_door_slots": [],
	}


# =============================================================================
func _ready() -> void:
	var def := call("get_definition") as Dictionary
	room_type_id = def.get("id", "")
	
	_create_interaction_area()
	_build_local_nav()
	
	# Stelle sicher, dass ALLE Control-Nodes im Raum (NavBlocker, Betten, Stühle) 
	# keine Hover-Events abfangen - wichtig für Multi-Tile Räume!
	_apply_mouse_filter_recursive(self)
	
	_refresh_furniture()
	
	if TimeManager and not TimeManager.sig_hour_passed.is_connected(_on_hour_passed):
		TimeManager.sig_hour_passed.connect(_on_hour_passed)
	if TimeManager and not TimeManager.sig_midnight_struck.is_connected(_on_midnight_struck):
		TimeManager.sig_midnight_struck.connect(_on_midnight_struck)
		
	if StaffManager and not StaffManager.sig_assignments_changed.is_connected(_update_indicator):
		StaffManager.sig_assignments_changed.connect(_update_indicator)
		
	if SHOW_DEBUG_PATHS:
		_debug_node = Node2D.new()
		_debug_node.z_index = 100
		add_child(_debug_node)
		_debug_node.draw.connect(_on_debug_draw.bind(_debug_node))

func _apply_mouse_filter_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_mouse_filter_recursive(child)

# =============================================================================
func can_build_path(_door_idx: int) -> bool:
	return false

func _get_obstacle_layers_recursive(node: Node, result: Array) -> void:
	for child in node.get_children():
		if child.has_method("get_used_cells"):
			if "bstacles" in child.name or "dont_walk" in child.name:
				result.append(child)
		_get_obstacle_layers_recursive(child, result)

# =============================================================================
## Liest alle TileMapLayer namens "Obstacles" aus und liefert die Koordinaten
## der bemalten Tiles (relativ zu dieser Room-Node).
## Nur sichtbare Layer werden berücksichtigt (wichtig für Landscape/Portrait-Räume).
func get_solid_tiles() -> Array[Vector2i]:
	var solid_tiles: Array[Vector2i] = []
	var all_obstacles = []
	_get_obstacle_layers_recursive(self, all_obstacles)
	
	for obstacles in all_obstacles:
		# Wenn Obstacles ein Kind von Landscape/Portrait ist, müssen wir schauen
		# ob dieses Elternteil sichtbar ist. Der Obstacles-Layer selbst darf
		# unsichtbar sein (damit man die roten Kästchen im Spiel nicht sieht).
		if obstacles.get_parent() != self and "visible" in obstacles.get_parent():
			if not obstacles.get_parent().visible:
				continue
		# Tile-Offset des Eltern-Nodes (z.B. Landscape oder Portrait) berücksichtigen
		var parent_offset := Vector2i.ZERO
		if obstacles.get_parent() != self:
			var p = obstacles.get_parent()
			parent_offset = Vector2i(
				int(p.position.x / TILE_PX),
				int(p.position.y / TILE_PX)
			)
		var obs_tile_size := Vector2i(TILE_PX, TILE_PX)
		if obstacles.tile_set:
			obs_tile_size = obstacles.tile_set.tile_size
			
		for t in obstacles.get_used_cells():
			var game_x := int(t.x * obs_tile_size.x / float(TILE_PX))
			var game_y := int(t.y * obs_tile_size.y / float(TILE_PX))
			var final_pos = Vector2i(game_x, game_y) + parent_offset
			if not solid_tiles.has(final_pos):
				solid_tiles.append(final_pos)
	return solid_tiles


# =============================================================================
## Liefert die MapGrid-Kachel (global), zu der Charaktere navigieren sollen.
## Das ist nun strikt das Exit-Tile VOR der Tür, um World-Pathfinding 
## von Room-Pathfinding sauber zu trennen.
func get_target_tile(map_grid: Node) -> Vector2i:
	var tile = map_grid.world_to_tile(global_position)
	var gx = tile.x
	var gy = tile.y
	var sz = get_tile_size()
	
	match door_rotation:
		0: return Vector2i(gx - 1,                    gy + sz.y - 1 - door_offset) # Links
		1: return Vector2i(gx + door_offset,          gy - 1)                      # Oben
		2: return Vector2i(gx + sz.x,                 gy + door_offset)            # Rechts
		3: return Vector2i(gx + sz.x - 1 - door_offset, gy + sz.y)                 # Unten
		
	return tile

# =============================================================================
## Berechnet die exakte Pixel-Koordinate ca. 32px (2 Tiles) im Raum drinnen.
func get_service_position() -> Vector2:
	# 1. Unique Name (Rückwärtskompatibilität)
	var marker = get_node_or_null("%ServicePoint")
	if marker:
		return marker.global_position

	# 2. Suche in allen Branches nach dem Marker (ohne %)
	var markers = find_children("ServicePoint", "Marker2D")
	if markers.is_empty():
		markers = find_children("ServicePoint", "Node2D")
		
	for m in markers:
		var is_marker_active = true
		var parent = m.get_parent()
		while parent != self and is_instance_valid(parent):
			if "visible" in parent and not parent.visible:
				is_marker_active = false
				break
			parent = parent.get_parent()
		if is_marker_active:
			return m.global_position
			
	# 3. Fallback auf Interior-Mitte
	var interior = get_node_or_null("Interior")
	if interior and interior.visible:
		return interior.global_position + Vector2(16, 16)
		
	# Fallback für asymmetrische Räume, falls Interior nicht existiert
	if has_node("Landscape") and get_node("Landscape").visible:
		var l_int = get_node_or_null("Landscape/Interior")
		if l_int: return l_int.global_position + Vector2(16, 16)
	if has_node("Portrait") and get_node("Portrait").visible:
		var p_int = get_node_or_null("Portrait/Interior")
		if p_int: return p_int.global_position + Vector2(16, 16)
		
	return global_position + Vector2(16, 16)

## Liefert die globale Koordinate, an der die Raumtür auf der Innenseite liegt.
func get_door_world_inside(map_grid: Node, _is_leaving_hotel: bool = false) -> Vector2:
	if has_method("get_room_entry_pos"):
		return call("get_room_entry_pos", map_grid)
	return global_position

## Liefert die globale Koordinate, die direkt außerhalb des Raumes liegt.
func get_door_world_outside(map_grid: Node, _is_leaving_hotel: bool = false) -> Vector2:
	if has_method("get_target_tile"):
		var exit_tile = call("get_target_tile", map_grid)
		return map_grid.tile_to_world(exit_tile)
	return global_position

func get_room_entry_pos(map_grid: Node) -> Vector2:
	var exit_tile = get_target_tile(map_grid)
	var exit_pos = map_grid.tile_to_world(exit_tile)
	
	# Gehe vom Exit-Tile in den Raum hinein (24 Pixel = 1.5 Tiles)
	var entry_offset := Vector2(0, 0)
	var rx = 0.0
	var ry = 0.0
	match door_rotation:
		0: 
			entry_offset = Vector2(22, 0)
			rx = randf_range(0.0, 6.0)
			ry = randf_range(-2.0, 2.0)
		1: 
			entry_offset = Vector2(0, 22)
			rx = randf_range(-2.0, 2.0)
			ry = randf_range(0.0, 6.0)
		2: 
			entry_offset = Vector2(-22, 0)
			rx = randf_range(-6.0, 0.0)
			ry = randf_range(-2.0, 2.0)
		3: 
			entry_offset = Vector2(0, -22)
			rx = randf_range(-2.0, 2.0)
			ry = randf_range(-6.0, 0.0)
		
		
	return exit_pos + entry_offset + Vector2(rx, ry)


# =============================================================================
func _on_hour_passed(_hour: int) -> void:
	if TimeManager.is_paused():
		return
		
	# Alte stündliche Degradation entfernt, läuft nun über degrade_condition_from_visits

func _on_midnight_struck(_day: int) -> void:
		
	var main = get_tree().root.get_node_or_null("Ingame")
	if not main: return
	
	var guest_manager = main.get_node_or_null("GuestManager")
	if not guest_manager: return
		
	var party = guest_manager.get_party_in_room(self)
	if party and party.members.size() > 0:
		var occupants_size = party.members.size()
		add_dirt_from_visits(occupants_size)
		degrade_condition_from_visits(occupants_size)

func add_dirt_from_visits(visits: int) -> void:
	var dirt_factor: int = GameState.selected_hotel.get("dirt_factor", 2)
	var base_drop = visits * 8
	var rand_drop = randi_range(0, visits * dirt_factor)
	
	cleanliness_level = clampi(cleanliness_level - (base_drop + rand_drop), 0, 100)
	
	if cleanliness_level < 50 and not is_service_requested:
		if GameState.selected_hotel.get("level", 1) >= GameState.UNLOCK_LEVELS.get("auto_staff", 100):
			is_service_requested = true
			GameState.sig_room_needs_cleaning.emit(self)
		_update_indicator()

func degrade_condition_from_visits(visits: int) -> void:
	var maint_factor: int = GameState.selected_hotel.get("maintenance_factor", 2)
	
	# Würfel w10(<= faktor)
	if randi_range(1, 10) <= maint_factor:
		var drop = randi_range(1, visits * maint_factor)
		maintenance_level = clampi(maintenance_level - drop, 0, 100)
		
		if maintenance_level < 50 and not is_repair_requested:
			if GameState.selected_hotel.get("level", 1) >= GameState.UNLOCK_LEVELS.get("auto_staff", 100):
				is_repair_requested = true
				GameState.sig_room_needs_repair.emit(self)
			_update_indicator()

# ── Public API ────────────────────────────────────────────────────────────────


# =============================================================================
func configure(data: Dictionary) -> void:

	room_type_id  = data.get("room_type_id",  room_type_id)
	room_level    = data.get("room_level",    room_level)
	room_number   = data.get("room_number",   room_number)
	x_pos         = data.get("x_pos",         x_pos)
	y_pos         = data.get("y_pos",         y_pos)
	floor_num     = data.get("floor_num",     floor_num)
	maintenance_level = data.get("maintenance_level", data.get("condition", maintenance_level))
	cleanliness_level = data.get("cleanliness_level", data.get("cleanliness", cleanliness_level))
	is_service_requested = data.get("is_service_requested", is_service_requested)
	is_repair_requested = data.get("is_repair_requested", is_repair_requested)
	is_pending_demolish = data.get("is_pending_demolish", is_pending_demolish)
	door_rotation = data.get("door_rotation", door_rotation)
	door_offset   = data.get("door_offset",   door_offset)
	room_rotation = data.get("room_rotation", room_rotation)
	if data.has("custom_color"):
		var col_str = data.get("custom_color", "ffffff")
		if typeof(col_str) == TYPE_STRING and col_str != "":
			custom_color = Color(col_str)

	if data.get("is_new_build", false):
		if TechtreeManager and TechtreeManager.is_tech_unlocked("Z1.4"):
			acquired_traits.append("wlan")
		if TechtreeManager and TechtreeManager.is_tech_unlocked("Z1.5"):
			acquired_traits.append("klima")
	elif data.has("acquired_traits"):
		# Only reset traits when the data dict actually carries them.
		# A second configure({guest_manager:...}) must NOT wipe already-loaded traits.
		acquired_traits = []
		var loaded_traits = data.get("acquired_traits", [])
		if typeof(loaded_traits) == TYPE_STRING:
			if loaded_traits.begins_with("["):
				var p = JSON.parse_string(loaded_traits)
				if typeof(p) == TYPE_ARRAY:
					for t in p:
						var st = str(t).strip_edges().replace('"', '')
						if st != "": acquired_traits.append(st)
			elif loaded_traits != "":
				for t in loaded_traits.split(","):
					var st = str(t).strip_edges().replace('"', '')
					if st != "": acquired_traits.append(st)



	_apply_visuals()
	_update_indicator()
	
	# Neu aufbauen falls sich Rotation geändert hat
	_build_local_nav()
	if SHOW_DEBUG_PATHS and _debug_node:
		_debug_node.queue_redraw()
	
	# Nach dem Laden: Offene Tickets wiederherstellen!
	if is_service_requested:
		# call_deferred stellt sicher, dass der Node im Baum ist und TaskManager bereit
		GameState.sig_room_needs_cleaning.emit.call_deferred(self)
	if is_repair_requested:
		GameState.sig_room_needs_repair.emit.call_deferred(self)


# =============================================================================
func to_dict() -> Dictionary:
	return {
		"room_type_id": room_type_id,
		"room_level": room_level,
		"room_number": room_number,
		"x_pos": x_pos,
		"y_pos": y_pos,
		"floor_num": floor_num,
		"maintenance_level": maintenance_level,
		"cleanliness_level": cleanliness_level,
		"is_service_requested": is_service_requested,
		"is_repair_requested": is_repair_requested,
		"is_pending_demolish": is_pending_demolish,
		"door_rotation": door_rotation,
		"door_offset": door_offset,
		"room_rotation": room_rotation,
		"custom_color": custom_color.to_html(false),
		"acquired_traits": ",".join(acquired_traits)
	}


# =============================================================================
func has_trait(trait_id: String) -> bool:
	if trait_id in acquired_traits:
		return true
	var def = call("get_definition")
	var base_traits = def.get("traits", [])
	return trait_id in base_traits

# =============================================================================
func rotate_door() -> void:
	door_rotation = (door_rotation + 1) % 4
	_apply_visuals()


# =============================================================================
func cycle_door_offset() -> void:
	door_offset = 1 - door_offset
	_apply_visuals()


# =============================================================================
func upgrade() -> void:
	room_level += 1
	_apply_visuals()

# =============================================================================
func set_service_requested(requested: bool) -> void:
	is_service_requested = requested
	_update_indicator()

var _highlight_rect: ReferenceRect

# =============================================================================
func set_highlight(active: bool, highlight_color: Color = Color(1.0, 0.8, 0.1, 0.9)) -> void:
	if active:
		if not is_instance_valid(_highlight_rect):
			_highlight_rect = ReferenceRect.new()
			_highlight_rect.editor_only = false
			_highlight_rect.border_width = 3.0
			_highlight_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			var bg = ColorRect.new()
			bg.name = "HighlightBG"
			bg.set_anchors_preset(Control.PRESET_FULL_RECT)
			bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_highlight_rect.add_child(bg)
			
			var sz = get_tile_size()
			_highlight_rect.size = Vector2(sz.x * TILE_PX, sz.y * TILE_PX)
			_highlight_rect.z_index = 50
			
			add_child(_highlight_rect)
			
		_highlight_rect.border_color = highlight_color
		var bg_color = highlight_color
		bg_color.a = 0.2
		var bg_node = _highlight_rect.get_node_or_null("HighlightBG")
		if bg_node:
			bg_node.color = bg_color
			
		_highlight_rect.show()
	else:
		if is_instance_valid(_highlight_rect):
			_highlight_rect.hide()


var _interaction_collision: CollisionShape2D

# =============================================================================
func _create_interaction_area() -> void:
	var area = Area2D.new()
	area.process_mode = Node.PROCESS_MODE_ALWAYS # Fix: Allows Area2D to regain mouse focus after UI closes while paused
	_interaction_collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	var sz = get_tile_size()
	shape.size = Vector2(sz.x * TILE_PX, sz.y * TILE_PX)
	
	_interaction_collision.position = shape.size / 2.0
	_interaction_collision.shape = shape
	
	area.add_child(_interaction_collision)
	add_child(area)
	
	area.mouse_entered.connect(func(): GameState.sig_room_hovered.emit(self, true))
	area.mouse_exited.connect(func(): GameState.sig_room_hovered.emit(self, false))
	area.input_event.connect(_on_interaction_area_input)


# =============================================================================
func _on_interaction_area_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if InputHandler.current_mode == InputHandler.InputMode.NORMAL:
			# Prüfen, ob wir versehentlich einen Gast oder Staff anklicken (die liegen optisch drüber)
			var space = get_world_2d().direct_space_state
			var query = PhysicsPointQueryParameters2D.new()
			query.position = get_global_mouse_position()
			query.collide_with_areas = true
			var hits = space.intersect_point(query)
			for hit in hits:
				var parent = hit.collider.get_parent()
				if parent and (parent.is_in_group("guest_actors") or parent.is_in_group("staff_actors")):
					return # Ignorieren, der Gast/Staff fängt den Klick selbst!
					
			get_viewport().set_input_as_handled()
			GameState.sig_room_clicked.emit(self)


# ── Intern – von Unterklassen überschreiben ───────────────────────────────────

# =============================================================================
func get_tile_size() -> Vector2i:
	# Bei 90° (1) und 270° (3) tauschen Breite und Höhe die Plätze!
	if room_rotation == 1 or room_rotation == 3:
		return Vector2i(base_size.y, base_size.x)

	return base_size


# =============================================================================
## Holt sich die erlaubten Türen nun direkt aus den Daten!
func get_valid_door_slots() -> Array[String]:
	var def: Dictionary = call("get_definition")
	var result: Array[String] = []
	result.assign(def.get("valid_door_slots", []))
	return result


# =============================================================================
## Berechnet alle gültigen (door_rotation, door_offset)-Kombos aus Raumgröße + Slot-Deklaration.
## door_rotation = Wand (0=L 1=T 2=R 3=B), door_offset = 0-basierter Slot-Index.
func get_valid_door_combos() -> Array[Vector2i]:
	var sz := base_size
	var wall_len := [sz.y, sz.x, sz.y, sz.x]  # L/R = Höhe, T/B = Breite
	var named := get_valid_door_slots()
	var result: Array[Vector2i] = []
	for rot: int in range(4):
		var slots: Array = DOOR_SLOTS[rot]
		var n := mini(wall_len[rot], 5)
		for off: int in range(n):
			if named.is_empty() or slots[off] in named:
																																	result.append(Vector2i(rot, off))
	return result


# =============================================================================
## Berechnet Position + Rotation des Tür-Sprites für einen Slot.
## L/B zählen von der Ecke (L1=unten, B1=rechts) – daher invertierte along-Formel.
func _calc_door_transform(rot: int, off: int) -> Dictionary:
	var sz := get_tile_size()
	var w_px := sz.x * TILE_PX
	var h_px := sz.y * TILE_PX
	var along: float
	match rot:
		0: # L – von unten nach oben
			along = (sz.y - 1 - off) * TILE_PX + TILE_PX / 2.0
			return {"pos": Vector2(1, along),       "rot": PI}
		1: # T – von links nach rechts
			along = off * TILE_PX + TILE_PX / 2.0
			return {"pos": Vector2(along, 1),       "rot": -PI / 2.0}
		2: # R – von oben nach unten
			along = off * TILE_PX + TILE_PX / 2.0
			return {"pos": Vector2(w_px - 1, along), "rot": 0.0}
		3: # B – von rechts nach links
			along = (sz.x - 1 - off) * TILE_PX + TILE_PX / 2.0
			return {"pos": Vector2(along, h_px - 1), "rot": PI / 2.0}
	return {"pos": Vector2.ZERO, "rot": 0.0}


# =============================================================================
func set_floor_neighbors(_top: bool, _right: bool, _bottom: bool, _left: bool) -> void:
	pass


# =============================================================================
func _apply_visuals() -> void:
	if not is_node_ready():
		return

	# 1. Tür-Positionierung (für alle Räume gleich)
	# Wir prüfen mit get_node_or_null, damit es keinen Crash gibt,
	# falls ein Spezial-Raum mal keinen "Door" Node haben sollte.
	var door := get_node_or_null("Door") as Node2D
	if door:
		var dtfm := _calc_door_transform(door_rotation, door_offset)
		door.position = dtfm["pos"]
		door.rotation = dtfm["rot"]

	# 2. Interior-Rotation (für alle Standard-Räume)
	var interior := get_node_or_null("Interior") as Node2D
	if interior:
		var icfg := _get_interior_transform(room_rotation)
		interior.position = icfg["pos"]
		interior.rotation = icfg["rot"]

	# 3. Hitbox (Area2D) anpassen
	if is_instance_valid(_interaction_collision):
		var sz = get_tile_size()
		var rect = _interaction_collision.shape as RectangleShape2D
		if rect:
			rect.size = Vector2(sz.x * TILE_PX, sz.y * TILE_PX)
			_interaction_collision.position = rect.size / 2.0
			
	# 4. NavGrid aktualisieren, da Blocker nun rotiert sein könnten
	_build_local_nav()
	_refresh_furniture()

# =============================================================================
func _refresh_furniture() -> void:
	_room_seats.clear()
	_room_beds.clear()
	_room_seats_staff_only.clear()
	
	var interior = get_node_or_null("Interior")
	if interior:
		_find_furniture_recursive(interior)
	elif has_node("Landscape") and has_node("Portrait"):
		if room_rotation % 2 == 1:
			var interior_portrait = get_node_or_null("Portrait/Interior")
			if interior_portrait:
				_find_furniture_recursive(interior_portrait)
		else:
			var interior_landscape = get_node_or_null("Landscape/Interior")
			if interior_landscape:
				_find_furniture_recursive(interior_landscape)


# =============================================================================
# Berechnet den Dreh- und Verschiebe-Punkt dynamisch anhand der Raumgröße!
func _get_interior_transform(rot: int) -> Dictionary:
	var sz := get_tile_size()
	var w_px := sz.x * TILE_PX
	var h_px := sz.y * TILE_PX

	match rot:
		0: return {"pos": Vector2.ZERO, "rot": 0.0}
		1: return {"pos": Vector2(w_px, 0), "rot": PI / 2.0}
		2: return {"pos": Vector2(w_px, h_px), "rot": PI}
		3: return {"pos": Vector2(0, h_px), "rot": -PI / 2.0}

	return {"pos": Vector2.ZERO, "rot": 0.0}


# =============================================================================
func _update_indicator() -> void:
	# 1. LAZY INSTANTIATION: Wenn es den Indikator noch nicht gibt, bauen wir ihn JETZT.
	if not is_instance_valid(_status_indicator):
		_status_indicator = INDICATOR_SCENE.instantiate()
		add_child(_status_indicator)

		# 1. POSITION: Ab in die obere linke Ecke (z.B. 4 Pixel vom Rand)
		_status_indicator.position = Vector2(0, 0)
		_status_indicator.scale = Vector2(0.3, 0.3) # Werte ggf. anpassen (z.B. 0.3, 0.3)
		_status_indicator.z_index = 100
		_status_indicator.z_as_relative = false


	# 2. HOLEN DER DATEN:
	var def: Dictionary = call("get_definition")
	if def.get("max_beds", 0) == 0 and not def.get("is_poi", false):
		_status_indicator.visible = false
		return

	_status_indicator.visible = true

	var staff_status = 0
	if def.get("is_poi", false) and def.get("required_role", "") != "":
		if StaffManager:
			var room_id = GuestManager._room_key(self)
			
			var max_s = def.get("max_staff", def.get("min_staff", 1))
			var assigned_count = StaffManager.get_staff_for_room(room_id).size()
			
			if not StaffManager.is_poi_staffed(def, room_id):
				staff_status = 2 # Kein Personal / Wichtige Rolle fehlt (Rot)
			elif assigned_count < max_s:
				staff_status = 1 # Unterbesetzt (Orange)

	var show_broom = is_service_requested or (cleanliness_level < 50)
	var show_wrench = is_repair_requested or (maintenance_level < 50)
	var is_critical_clean = (cleanliness_level == 0)
	var is_critical_repair = (maintenance_level == 0)
	_status_indicator.set_status(show_broom, show_wrench, is_pending_demolish, staff_status, is_service_requested, is_repair_requested, is_critical_clean, is_critical_repair)


# ── Lokale Navigation (Raum-intern) ──────────────────────────────────────────

var _local_astar: AStar2D
var _debug_node: Node2D = null
const LOCAL_NAV_CELL_SIZE := 4.0

func _find_nav_blockers_recursive(node: Node, result: Array) -> void:
	if "visible" in node and not node.visible:
		return
	for child in node.get_children():
		if "NavBlocker" in child.name or child.is_in_group("nav_blocker"):
			if child is Control or child is ReferenceRect or child is ColorRect:
				result.append(child)
		_find_nav_blockers_recursive(child, result)

func _find_nav_weights_recursive(node: Node, result: Array) -> void:
	if "visible" in node and not node.visible:
		return
	for child in node.get_children():
		if "NavWeight" in child.name or child.is_in_group("nav_weight"):
			if child is Control or child is ReferenceRect or child is ColorRect:
				result.append(child)
		_find_nav_weights_recursive(child, result)

func _is_node_visible(node: Node) -> bool:
	var current = node
	while current and current != self:
		if "visible" in current and not current.visible:
			return false
		current = current.get_parent()
	return true

func _build_local_nav() -> void:
	var blockers = []
	_find_nav_blockers_recursive(self, blockers)
	var weights = []
	_find_nav_weights_recursive(self, weights)
	var solid_tiles = get_solid_tiles()
	
	if blockers.is_empty() and solid_tiles.is_empty():
		return # Keine lokale Navigation nötig für leere Räume
		
	_local_astar = AStar2D.new()
	var sz = get_tile_size() * float(TILE_PX)
	var cells_x = int(sz.x / LOCAL_NAV_CELL_SIZE)
	var cells_y = int(sz.y / LOCAL_NAV_CELL_SIZE)
	
	# Punkte generieren
	for y in cells_y:
		for x in cells_x:
			var id = y * cells_x + x
			# Mittig in der 4x4 Zelle
			var p = Vector2(x * LOCAL_NAV_CELL_SIZE + LOCAL_NAV_CELL_SIZE / 2.0, y * LOCAL_NAV_CELL_SIZE + LOCAL_NAV_CELL_SIZE / 2.0)
			
			var is_blocked = false
			
			# 1. Prüfe Wände (TileMapLayer)
			var tile_pos := Vector2i(int(p.x / TILE_PX), int(p.y / TILE_PX))
			if solid_tiles.has(tile_pos):
				is_blocked = true
				
			# 2. Prüfe NavBlocker (Möbel)
			if not is_blocked:
				var p_global = to_global(p)
				for b in blockers:
					if b is Control or b is ReferenceRect or b is ColorRect:
						if not _is_node_visible(b): continue
						var p_local = b.get_global_transform().affine_inverse() * p_global
						if Rect2(Vector2.ZERO, b.size).has_point(p_local):
							is_blocked = true
							break
					
			if not is_blocked:
				_local_astar.add_point(id, p)
				
				# 3. Prüfe NavWeight (Wasser etc)
				var is_weighted = false
				var p_global = to_global(p)
				for w in weights:
					if w is Control or w is ReferenceRect or w is ColorRect:
						if not _is_node_visible(w): continue
						var p_local = w.get_global_transform().affine_inverse() * p_global
						if Rect2(Vector2.ZERO, w.size).has_point(p_local):
							is_weighted = true
							break
				if is_weighted:
					_local_astar.set_point_weight_scale(id, 50.0)
				
	# Punkte verbinden (orthogonal & diagonal)
	for y in cells_y:
		for x in cells_x:
			var id = y * cells_x + x
			if not _local_astar.has_point(id):
				continue
				
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					if dx == 0 and dy == 0: continue
					var nx = x + dx
					var ny = y + dy
					if nx >= 0 and nx < cells_x and ny >= 0 and ny < cells_y:
						var nid = ny * cells_x + nx
						if _local_astar.has_point(nid):
							if not _local_astar.are_points_connected(id, nid):
								_local_astar.connect_points(id, nid, true)
	queue_redraw()

func get_local_path(start_world: Vector2, end_world: Vector2, actor_id: String = "Unknown") -> Array[Vector2]:
	if _local_astar == null:
		return [start_world, end_world]
		
	var start_local = to_local(start_world)
	var end_local = to_local(end_world)
	
	var start_id = _local_astar.get_closest_point(start_local)
	var end_id = _local_astar.get_closest_point(end_local)
	
	if start_id == -1 or end_id == -1:
		return [start_world, end_world]
		
	var path_local = _local_astar.get_point_path(start_id, end_id)
	var path_world: Array[Vector2] = []
	for p in path_local:
		path_world.append(to_global(p))
		
	if path_world.size() > 0:
		path_world.insert(0, start_world)
		path_world.append(end_world)
	else:
		if start_id != end_id:
			print("[AStar Bug] Actor: ", actor_id, " in Room: ", name, " | NO PATH FOUND between start_id: ", start_id, " and end_id: ", end_id, " | start_local: ", start_local, " end_local: ", end_local)
		return [start_world, end_world]
		
	return path_world

func get_random_walkable_local_pos() -> Vector2:
	if _local_astar == null or _local_astar.get_point_count() == 0:
		return Vector2.INF
	var ids = _local_astar.get_point_ids()
	if ids.is_empty():
		return Vector2.INF
	var random_id = ids[randi() % ids.size()]
	return to_global(_local_astar.get_point_position(random_id))

func _on_debug_draw(canvas: Node2D) -> void:
	if SHOW_DEBUG_PATHS:
		var blockers = []
		_find_nav_blockers_recursive(self, blockers)
		for b in blockers:
			if b is Control or b is ReferenceRect or b is ColorRect:
				if not _is_node_visible(b): continue
				var b_trans = get_global_transform().affine_inverse() * b.get_global_transform()
				var p1 = b_trans * Vector2(0, 0)
				var p2 = b_trans * Vector2(b.size.x, 0)
				var p3 = b_trans * b.size
				var p4 = b_trans * Vector2(0, b.size.y)
				canvas.draw_polygon(PackedVector2Array([p1, p2, p3, p4]), PackedColorArray([Color(1, 0, 0, 0.5), Color(1, 0, 0, 0.5), Color(1, 0, 0, 0.5), Color(1, 0, 0, 0.5)]))
				
		if _local_astar != null:
			# Punkte und Verbindungen zeichnen (Grün für offene Wege)
			for id in _local_astar.get_point_ids():
				var p1 = _local_astar.get_point_position(id)
				canvas.draw_circle(p1, 1.0, Color(0, 1, 0, 0.8))
				for cid in _local_astar.get_point_connections(id):
					var p2 = _local_astar.get_point_position(cid)
					canvas.draw_line(p1, p2, Color(0, 1, 0, 0.4), 0.5)
