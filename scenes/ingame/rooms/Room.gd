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

var _guest_manager: Node

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
	
	if TimeManager and not TimeManager.sig_hour_passed.is_connected(_on_hour_passed):
		TimeManager.sig_hour_passed.connect(_on_hour_passed)
	if TimeManager and not TimeManager.sig_midnight_struck.is_connected(_on_midnight_struck):
		TimeManager.sig_midnight_struck.connect(_on_midnight_struck)
		
	if StaffManager and not StaffManager.sig_assignments_changed.is_connected(_update_indicator):
		StaffManager.sig_assignments_changed.connect(_update_indicator)

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
func get_room_entry_pos(map_grid: Node) -> Vector2:
	var exit_tile = get_target_tile(map_grid)
	var exit_pos = map_grid.tile_to_world(exit_tile)
	
	# Gehe vom Exit-Tile in den Raum hinein (je nach Tür-Ausrichtung)
	# 32 Pixel (2 Tiles) tief rein.
	var entry_offset := Vector2(0, 0)
	match door_rotation:
		0: entry_offset = Vector2(32, 0)   # Tür ist links -> wir gehen nach rechts rein
		1: entry_offset = Vector2(0, 32)   # Tür ist oben -> wir gehen nach unten rein
		2: entry_offset = Vector2(-32, 0)  # Tür ist rechts -> wir gehen nach links rein
		3: entry_offset = Vector2(0, -32)  # Tür ist unten -> wir gehen nach oben rein
		
	return exit_pos + entry_offset


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
	
	if data.get("is_new_build", false):
		if GameState.techtree.get("tech_wlan", false) or (TechtreeManager and TechtreeManager.is_unlocked("Z1.4")):
			acquired_traits.append("wlan")
		if GameState.techtree.get("tech_klima", false) or (TechtreeManager and TechtreeManager.is_unlocked("Z1.5")):
			acquired_traits.append("klima")
	else:
		acquired_traits = data.get("acquired_traits", [])

	_apply_visuals()
	_update_indicator()
	
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
		"acquired_traits": acquired_traits
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
func set_highlight(active: bool, custom_color: Color = Color(1.0, 0.8, 0.1, 0.9)) -> void:
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
			
		_highlight_rect.border_color = custom_color
		var bg_color = custom_color
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
	var sz := get_tile_size()
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
			var rnum = str(get("room_number"))
			var room_id = rnum if (rnum != "" and rnum != "null") else ("%s_%d_%d" % [str(get("room_type_id")), int(get("x_pos")), int(get("y_pos"))])
			
			var max_s = def.get("max_staff", def.get("min_staff", 1))
			var assigned_count = StaffManager.get_staff_for_room(room_id).size()
			if assigned_count == 0:
				staff_status = 2 # Kein Personal (Rot)
			elif assigned_count < max_s:
				staff_status = 1 # Unterbesetzt (Orange)

	var show_broom = is_service_requested or (cleanliness_level < 50)
	var show_wrench = is_repair_requested or (maintenance_level < 50)
	_status_indicator.set_status(show_broom, show_wrench, is_pending_demolish, staff_status, is_service_requested, is_repair_requested)
