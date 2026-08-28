extends Node2D
## Verantwortlichkeit: Spielfeld aufbauen, Parzellen-Sichtbarkeit steuern, Kamera-Input.
## ANG-186 – Occupancy Grid: globales Bool-Grid ersetzt per-Parzelle Rect2i-Array.


# ── Nodes ─────────────────────────────────────────────────────────────────────
@onready var camera: Camera2D = $Camera2D
var guest_manager: GuestManager:
	set(value):
		guest_manager = value

# ── Grid-Konfiguration ────────────────────────────────────────────────────────
@export var grid_cols:  int = 5
@export var grid_rows:  int = 5
@export var start_plot: Vector2i = Vector2i(1, 0)

const PARCEL_SZ := 16
const WALK_W    := 3
const TILE_PX   := 16
const SCALE     := 2.0

# Raum-Typ → Szenen-Pfad wird jetzt dynamisch aus GameState.room_registry bezogen
# ── Kamera-Konfiguration ──────────────────────────────────────────────────────
var _pan_speed := 400.0
const ZOOM_MIN  := 0.5
const ZOOM_MAX  := 4.0
const ZOOM_STEP := 0.15

# ── State ─────────────────────────────────────────────────────────────────────
var _drag_active:    bool     = false
var _drag_origin:    Vector2  = Vector2.ZERO
var _cam_origin:     Vector2  = Vector2.ZERO
var _entry_plot:     Vector2i = Vector2i(1, 0)
@warning_ignore("unused_private_class_variable")
var _saved_cam_pos:  Vector2  = Vector2.ZERO
@warning_ignore("unused_private_class_variable")
var _saved_cam_zoom: float    = 1.0
var _has_saved_view: bool     = false

var _grid: Array = []
var active_rooms: Array = []

# ── Pathfinding ───────────────────────────────────────────────────────────────
var astar: AStarGrid2D = AStarGrid2D.new()

# ── Occupancy Grid ────────────────────────────────────────────────────────────
# Flaches PackedByteArray: 1 = belegt, 0 = frei.
# Adressierung: idx = gy * _occ_w + gx, wobei gx/gy globale Tile-Koordinaten sind.
# Globale Tile = parcel_x * PARCEL_SZ + local_tile_x (analog für y).
var _occ:   PackedByteArray
var _occ_w: int
var _occ_h: int

# ── Debugging ─────────────────────────────────────────────────────────────────
@warning_ignore("unused_private_class_variable")
var _show_debug_grid: bool = true
var _debug_paths: Dictionary = {}  # {id: {path, label}}
var _failed_paths: Array[Dictionary] = []

var is_miniature: bool = false

# =============================================================================
func _ready() -> void:
	add_to_group("map_grid")
	
	if not is_miniature:

		InputHandler.sig_camera_pan_requested.connect(_on_input_camera_pan)
		InputHandler.sig_camera_zoom_requested.connect(_on_input_camera_zoom)
		InputHandler.sig_camera_drag_started.connect(_on_input_drag_started)
		InputHandler.sig_camera_drag_moved.connect(_on_input_drag_moved)
		InputHandler.sig_camera_drag_ended.connect(_on_input_drag_ended)
		InputHandler.sig_camera_reset_requested.connect(func(): center_on_entry(_entry_plot))

		_pan_speed = SettingsManager.camera_pan_speed
		SettingsManager.sig_camera_pan_speed_changed.connect(func(speed): _pan_speed = speed)

	var p := $WorldRoot/ParcelsRoot
	_grid = [
		[p.get_node("P_0_0"), p.get_node("P_1_0"), p.get_node("P_2_0"), p.get_node("P_3_0"), p.get_node("P_4_0")],
		[p.get_node("P_0_1"), p.get_node("P_1_1"), p.get_node("P_2_1"), p.get_node("P_3_1"), p.get_node("P_4_1")],
		[p.get_node("P_0_2"), p.get_node("P_1_2"), p.get_node("P_2_2"), p.get_node("P_3_2"), p.get_node("P_4_2")],
		[p.get_node("P_0_3"), p.get_node("P_1_3"), p.get_node("P_2_3"), p.get_node("P_3_3"), p.get_node("P_4_3")],
		[p.get_node("P_0_4"), p.get_node("P_1_4"), p.get_node("P_2_4"), p.get_node("P_3_4"), p.get_node("P_4_4")],
	]

	for row: Array in _grid:
		for parcel: Node2D in row:
			parcel.visible = false


# ── Public API ────────────────────────────────────────────────────────────────

func setup_as_miniature(selected_x: int, selected_y: int) -> void:
	for row: Array in _grid:
		for parcel: Node2D in row:
			var px: int = parcel.name.get_slice("_", 1).to_int()
			var py: int = parcel.name.get_slice("_", 2).to_int()
			
			if px == selected_x and py == selected_y:
				parcel.visible = true
				parcel.modulate = Color(0.8, 0.8, 0.8) # Beton-Look für den Bauplatz
			else:
				parcel.visible = false
	
	if camera:
		var center_px = (5 * 16 * 16 + 2 * 3 * 16) * 2.0 / 2.0 # (cols*PARCEL_SZ*TILE_PX + 2*WALK_W*TILE_PX) * SCALE / 2
		camera.position = Vector2(center_px, center_px)
		camera.zoom = Vector2(0.14, 0.14)
		camera.make_current()

# =============================================================================
## Wandelt globale Kachel-Koordinaten (AStar) in Welt-Pixel für den Avatar um.
func tile_to_world(tile_coord: Vector2i) -> Vector2:
	# WALK_W addieren, damit der Gast exakt auf dem Grid der Parzellen landet
	var local_x := (tile_coord.x + WALK_W + 0.5) * TILE_PX
	var local_y := (tile_coord.y + WALK_W + 0.5) * TILE_PX

	return ($WorldRoot as Node2D).to_global(Vector2(local_x, local_y))


# =============================================================================
## Gibt ein Array von globalen Tile-Koordinaten (Vector2i) für die Bewegung zurück.
func get_path_between_tiles(start_tile: Vector2i, end_tile: Vector2i, debug_label: String = "") -> Array[Vector2i]:
	if not astar.is_in_boundsv(start_tile) or not astar.is_in_boundsv(end_tile):
		return []
		
	var start_was_solid = astar.is_point_solid(start_tile)
	var end_was_solid = astar.is_point_solid(end_tile)
	
	if start_was_solid:
		astar.set_point_solid(start_tile, false)
	if end_was_solid:
		astar.set_point_solid(end_tile, false)
		
	var path = astar.get_id_path(start_tile, end_tile)
	
	if start_was_solid:
		astar.set_point_solid(start_tile, true)
	if end_was_solid:
		astar.set_point_solid(end_tile, true)
		
	if path.is_empty():
		print("[MapGrid] Path failed: NO PATH FOUND by AStar. start: ", start_tile, " end: ", end_tile)
		_failed_paths.append({"start": start_tile, "end": end_tile})
		if _failed_paths.size() > 5:
			_failed_paths.pop_front()
		queue_redraw()
		print("--- ACTIVE ROOMS DUMP ---")
		for r in active_rooms:
			if is_instance_valid(r):
				var def = r.get_definition() if r.has_method("get_definition") else {}
				var r_name = def.get("id", "Unknown") if typeof(def) == TYPE_DICTIONARY else "Unknown"
				var r_pos = world_to_tile(r.global_position)
				print(" - ", r_name, " at tile ", r_pos)
		print("-------------------------")
	else:
		var lbl = debug_label if not debug_label.is_empty() else "?"
		print("[MapGrid] Path OK: ", lbl, " | ", start_tile, " -> ", end_tile, " len=", path.size())
		if debug_label != "":
			_debug_paths[debug_label] = {"path": path, "label": lbl}
		queue_redraw()
	return path

func clear_debug_path(debug_label: String) -> void:
	if _debug_paths.has(debug_label):
		_debug_paths.erase(debug_label)
		queue_redraw()


# =============================================================================
func get_placed_rooms() -> Array:
	var result: Array = []
	for row: Array in _grid:
		for parcel: Node2D in row:
			if not parcel.visible:
				continue
			for child: Node in parcel.get_children():
				if "room_type_id" in child:
					result.append(child)
	return result


# =============================================================================
func build_map(built_plots: Array, entry_plot: Vector2i, enter_dir: String) -> void:
	RenderingServer.set_default_clear_color(Color("#292929"))
	_entry_plot = entry_plot
	_show_built_parcels(built_plots)
	_configure_walls()
	_occ_init()
	for plot in built_plots:
		_mark_parcel_walls(plot["x"], plot["y"])
	var start_p: Node2D = _grid[entry_plot.y][entry_plot.x]
	start_p.set_entrance(enter_dir)
	_mark_parcel_walls(entry_plot.x, entry_plot.y)
	call_deferred("_mark_lobby_on_parcel", entry_plot.x, entry_plot.y)
	_restore_rooms(built_plots)
	center_on_entry(entry_plot)
	# Nochmal nach einem Frame: Migration kann Baustellen sofort fertigstellen,
	# daher Wände nach _process-Initialisierung neu konfigurieren
	call_deferred("_configure_walls")
	call_deferred("_update_all_floor_neighbors")


# =============================================================================
func center_on_entry(entry_plot: Vector2i) -> void:
	var parcel: Node2D = _grid[entry_plot.y][entry_plot.x]
	var target := parcel.global_position + Vector2(PARCEL_SZ * TILE_PX, PARCEL_SZ * TILE_PX) * (SCALE / 2.0)
	camera.global_position = target
	camera.zoom = Vector2(1.7, 1.7)
	_set_camera_limits()


# =============================================================================
func get_placement_error(parcel_x: int, parcel_y: int, tile_x: int, tile_y: int,
		room_w: int, room_h: int, door_rot: int, door_off: int) -> String:

	var gx := parcel_x * PARCEL_SZ + tile_x
	var gy := parcel_y * PARCEL_SZ + tile_y
	
	for dy in room_h:
		for dx in room_w:
			if gx + dx < 0 or gy + dy < 0:
				return "build.error.out_of_bounds"
			var px = floori((gx + dx) / float(PARCEL_SZ))
			var py = floori((gy + dy) / float(PARCEL_SZ))
			if not _is_built(px, py):
				return "build.error.out_of_bounds" # "Außerhalb der Parzelle"

	if not _occ_free_for_room(gx, gy, room_w, room_h):
		return "build.error.blocked" # "Bauplatz blockiert"

	var exit := _exit_global(parcel_x, parcel_y, tile_x, tile_y, room_w, room_h, door_rot, door_off)
	if not _occ_exit_free(exit.x, exit.y):
		return "build.error.door_blocked" # "Tür verdeckt / blockiert"
		
	if _exit_outside_parcel(parcel_x, parcel_y, exit, door_rot):
		return "build.error.door_out_of_bounds" # "Tür zeigt ins Nichts"

	# --- NEU: Reachability Check (Erreichbarkeits-Prüfung) ---
	# Wenn es noch keine Zimmer gibt, gibt es auch nichts einzusperren
	if active_rooms.is_empty():
		return ""

	# 1. SIMULATION: Raum auf dem Pathfinding-Grid blockieren
	# (Wir blockieren nur den Raumkörper, die Tür als Flur-Tile bleibt durchgängig!)
	var sim_coords: Array[Vector2i] = []
	for dy in room_h:
		for dx in room_w:
			var sim_x := gx + dx
			var sim_y := gy + dy
			if not astar.is_point_solid(Vector2i(sim_x, sim_y)):
				astar.set_point_solid(Vector2i(sim_x, sim_y), true)
				sim_coords.append(Vector2i(sim_x, sim_y))

	# Startpunkt (Lobby) berechnen
	var entry_parcel: Node2D = _grid[_entry_plot.y][_entry_plot.x]
	var clearance: Rect2i = entry_parcel.get_lobby_clearance_rect()
	# Wenn Lobby noch nicht initialisiert, Reachability-Check überspringen
	var error_msg := ""
	if not clearance.has_area():
		for sim_p in sim_coords:
			astar.set_point_solid(sim_p, false)
		return error_msg
	var start_x := (_entry_plot.x * PARCEL_SZ) + clearance.position.x + int(clearance.size.x / 2.0)
	var start_y := (_entry_plot.y * PARCEL_SZ) + clearance.position.y + int(clearance.size.y / 2.0)
	var lobby_tile := Vector2i(start_x, start_y)
	# Absicherung: Lobby-Tile muss begehbar sein
	if astar.is_point_solid(lobby_tile):
		for sim_p in sim_coords:
			astar.set_point_solid(sim_p, false)
		return error_msg


	# 2. PRÜFUNG: Teste alle aktiven Zimmer
	for room: Node2D in active_rooms:
		# Ignoriere Zimmer, die gerade abgerissen werden oder ungültig sind
		if not is_instance_valid(room):
			continue

		var r_sz: Vector2i = room.get_tile_size()
		var r_rot: int = room.get("door_rotation")
		var r_off: int = room.get("door_offset")
		var r_tx: int = int(room.position.x / TILE_PX)
		var r_ty: int = int(room.position.y / TILE_PX)
		var r_px: int = int(room.get_parent().name.split("_")[1])
		var r_py: int = int(room.get_parent().name.split("_")[2])

		var room_door_tile := _exit_global(r_px, r_py, r_tx, r_ty, r_sz.x, r_sz.y, r_rot, r_off)

		# Check 1: Findet das bestehende Zimmer noch einen Weg zur Lobby?
		var path := get_path_between_tiles(lobby_tile, room_door_tile)
		if path.is_empty():
			error_msg = "build.error.path_blocked" # "Blockiert Wege anderer Zimmer"
			break # Sobald ein Raum meckert, brechen wir ab

	# Check 2: Findet der GHOST selbst einen Weg? (Damit man keine Inseln baut)
	if error_msg == "":
		var ghost_path := get_path_between_tiles(lobby_tile, exit)
		if ghost_path.is_empty():
			error_msg = "build.error.no_connection" # "Keine Verbindung zum Wegenetz"

	# 3. AUFRÄUMEN: Simulation rückgängig machen
	for sim_p in sim_coords:
		astar.set_point_solid(sim_p, false)

	return error_msg


# =============================================================================
func is_placement_valid(parcel_x: int, parcel_y: int, tile_x: int, tile_y: int,
		room_w: int, room_h: int, door_rot: int, door_off: int) -> bool:
	return get_placement_error(parcel_x, parcel_y, tile_x, tile_y, room_w, room_h, door_rot, door_off) == ""


# =============================================================================
## Markiert Room-Body (Wert 4) + Obstacles (Wert 1) + Exit-Tile (Wert 2) im Grid.
## Wert 2 = Exit: darf von anderen Exit-Tiles überlappt werden (Tür-zu-Tür OK).
func mark_placement(parcel_x: int, parcel_y: int, tile_x: int, tile_y: int,
		room_w: int, room_h: int, door_rot: int, door_off: int, _room: Node2D = null) -> void:
	var gx := parcel_x * PARCEL_SZ + tile_x
	var gy := parcel_y * PARCEL_SZ + tile_y
	
	# 1. Gesamte Fläche als begehbar markieren (Bauverbot-Zone)
	_occ_mark_clearance(gx, gy, room_w, room_h)
	
	# 1. Gesamte Fläche als Raum (Solid) markieren
	_occ_mark(gx, gy, room_w, room_h)
	
	# 2. Tür-Öffnung NICHT freistanzen, damit kein Durchlauf-Shortcut entsteht!
	# var door_border := _door_border_tile(gx, gy, room_w, room_h, door_rot, door_off)
	# _occ_mark_clearance(door_border.x, door_border.y, 1, 1)
	
	# 3. Exit-Tile direkt vor der Tür setzen (AStar begehbar, aber kein Bauplatz)
	var exit := _exit_global(parcel_x, parcel_y, tile_x, tile_y, room_w, room_h, door_rot, door_off)
	_occ_mark_exit(exit.x, exit.y)

# =============================================================================
## Berechnet welches Tile im Außenrand die Tür-Öffnung ist (innerhalb des Raumes).
func _door_border_tile(gx: int, gy: int, room_w: int, room_h: int, door_rot: int, door_off: int) -> Vector2i:
	match door_rot:
		0: return Vector2i(gx,                              gy + room_h - 1 - door_off) # Links
		1: return Vector2i(gx + door_off,                   gy)                          # Oben
		2: return Vector2i(gx + room_w - 1,                 gy + door_off)               # Rechts
		3: return Vector2i(gx + room_w - 1 - door_off,      gy + room_h - 1)             # Unten
	return Vector2i(gx, gy)


# =============================================================================
## Gibt Body + Exit-Tile wieder frei – Grundlage für Abrissmodus (ANG-188).
func unmark_placement(parcel_x: int, parcel_y: int, tile_x: int, tile_y: int,
		room_w: int, room_h: int, door_rot: int, door_off: int) -> void:
	var gx := parcel_x * PARCEL_SZ + tile_x
	var gy := parcel_y * PARCEL_SZ + tile_y
	_occ_clear(gx, gy, room_w, room_h)
	var exit := _exit_global(parcel_x, parcel_y, tile_x, tile_y, room_w, room_h, door_rot, door_off)
	_occ_clear(exit.x, exit.y, 1, 1)


# =============================================================================
func place_room(parcel_x: int, parcel_y: int, room_scene: PackedScene, hotel_id: int,
	door_rot: int, door_off: int, tile_x: int, tile_y: int, room_rot: int = 0,
	room_number: String = "") -> void:

	var parcel: Node2D = _grid[parcel_y][parcel_x]
	var is_new := not parcel.visible
	parcel.visible = true

	if is_new:
		_mark_parcel_walls(parcel_x, parcel_y)

	var room: Node2D = parcel.spawn_room(room_scene, door_rot, door_off, tile_x, tile_y, room_rot)
	room.room_number = room_number

	if room.has_method("configure"):
		room.configure({
			"guest_manager": guest_manager,
			"door_rotation": door_rot,
			"door_offset": door_off,
			"room_rotation": room_rot,
			"is_new_build": true
		})

	var sz: Vector2i = room.get_tile_size()
	mark_placement(parcel_x, parcel_y, tile_x, tile_y, sz.x, sz.y, door_rot, door_off, room)

	active_rooms.append(room)

	SaveManager.save_room_to_plot(hotel_id, parcel_x, parcel_y, room.to_dict())

	if is_new:
		SaveManager.set_plot_built(hotel_id, parcel_x, parcel_y)
		_configure_walls()
	_update_all_floor_neighbors()



# =============================================================================
func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local := ($WorldRoot as Node2D).to_local(world_pos)
	var gx := int((local.x - WALK_W * TILE_PX) / (PARCEL_SZ * TILE_PX))
	var gy := int((local.y - WALK_W * TILE_PX) / (PARCEL_SZ * TILE_PX))
	return Vector2i(gx, gy)

# =============================================================================
func world_to_tile(world_pos: Vector2) -> Vector2i:
	var local := ($WorldRoot as Node2D).to_local(world_pos)
	var tx := int((local.x - WALK_W * TILE_PX) / TILE_PX)
	var ty := int((local.y - WALK_W * TILE_PX) / TILE_PX)
	return Vector2i(tx, ty)

# =============================================================================
func is_buildable(x: int, y: int) -> bool:
	if x < 0 or x >= grid_cols or y < 0 or y >= grid_rows:
		return false
	return not _grid[y][x].visible


# =============================================================================
func is_parcel_owned(x: int, y: int) -> bool:
	if x < 0 or x >= grid_cols or y < 0 or y >= grid_rows:
		return false
	return _grid[y][x].visible


# =============================================================================
func get_first_owned_parcel() -> Vector2i:
	for y: int in grid_rows:
		for x: int in grid_cols:
			if _grid[y][x].visible:
				return Vector2i(x, y)
	return Vector2i(0, 0)


# =============================================================================
func get_world_root() -> Node2D:
	return $WorldRoot


# ── Intern – Grid-Aufbau ──────────────────────────────────────────────────────

# =============================================================================
func _show_built_parcels(built_plots: Array) -> void:
	for plot in built_plots:
		var p = _grid[plot["y"]][plot["x"]]
		p.visible = true
		if plot.get("is_constructing", false):
			p.is_constructing = true
			var saved_end: float = plot.get("construction_end_time", 0.0)
			# Migration: Alte Baustellen-Saves nutzen tagesrelative Minuten (<= 2880).
			# Neue Saves nutzen absoluten Wert (Tag × 1440 + Minute, also >> 2880 ab Tag 3+).
			# Wenn der gespeicherte Wert suspekt klein ist, sofort fertigstellen.
			var current_abs := TimeManager.get_absolute_time()
			if saved_end < current_abs - 1440:
				# Offensichtlich alter oder abgelaufener Wert → sofort fertig
				p.construction_end_time = current_abs - 1
			else:
				p.construction_end_time = saved_end
			# build_ui_panel.visible wird in Parzelle._process automatisch gesetzt
		else:
			p.is_built = true


# =============================================================================
func _configure_walls() -> void:
	for y in grid_rows:
		for x in grid_cols:
			var parzelle: Node2D = _grid[y][x]
			if not parzelle.visible:
				continue
			parzelle.configure({
				"top":    _is_visible(x, y - 1),
				"bottom": _is_visible(x, y + 1),
				"left":   _is_visible(x - 1, y),
				"right":  _is_visible(x + 1, y),
			})


# =============================================================================
func _restore_rooms(built_plots: Array) -> void:
	for plot in built_plots:
		var rooms: Array = plot.get("rooms", [])
		if rooms.is_empty():
			continue
		var parcel: Node2D = _grid[plot["y"]][plot["x"]]
		for room_data in rooms:
			var type_id: String = room_data.get("room_type_id", "")
			if type_id == "lobby":
				continue
			var room_def = GameState.room_registry.get(type_id, {})
			var path: String = room_def.get("scene_path", "")
			if path.is_empty():
				continue

			room_data["guest_manager"] = guest_manager

			var room: Node2D = parcel.restore_room(room_data, load(path) as PackedScene)
			var sz: Vector2i = room.get_tile_size()
			var tx: int = room_data.get("x_pos", 0)
			var ty: int = room_data.get("y_pos", 0)
			mark_placement(
				plot["x"], plot["y"], tx, ty,
				sz.x, sz.y,
				room_data.get("door_rotation", 0), room_data.get("door_offset", 0),
				room
			)
			active_rooms.append(room)

	_update_all_floor_neighbors()
	
	# Finale Garantie: Alle Exit-Tiles (occ==2) MÜSSEN non-solid sein.
	# Diese Schleife läuft einmalig nach dem Laden aller Räume und stellt sicher,
	# dass keine Tür durch die Reihenfolge der Raum-Initialisierung solid geworden ist.
	if astar:
		for gy in _occ_h:
			for gx in _occ_w:
				if _occ[gy * _occ_w + gx] == 2:
					astar.set_point_solid(Vector2i(gx, gy), false)


# =============================================================================
func _is_built(x: int, y: int) -> bool:
	if x < 0 or x >= grid_cols or y < 0 or y >= grid_rows:
		return false
	return _grid[y][x].is_built


# =============================================================================
## Nur für Wanddarstellung: zählt auch Baustellen als 'vorhanden'
func _is_visible(x: int, y: int) -> bool:
	if x < 0 or x >= grid_cols or y < 0 or y >= grid_rows:
		return false
	var p = _grid[y][x]
	return p.is_built or p.is_constructing

func _process(_delta: float) -> void:
	if _show_debug_grid:
		queue_redraw()

func _draw() -> void:
	if not _show_debug_grid: return
	# _draw() laeuft im lokalen Koordinatenraum des MapGrid-Nodes.
	# tile_to_world() liefert globale Koord. (via $WorldRoot.to_global).
	# to_local(tile_to_world(tile)) = korrekte lokale Zeichenposition.
	var p0 := to_local(tile_to_world(Vector2i(0, 0)))
	var p1 := to_local(tile_to_world(Vector2i(1, 0)))
	var tile_w := p1.x - p0.x
	var tile_h := tile_w
	# Solid tiles (ROT)
	for y in astar.region.size.y:
		for x in astar.region.size.x:
			if astar.is_point_solid(Vector2i(x, y)):
				var c := to_local(tile_to_world(Vector2i(x, y)))
				draw_rect(Rect2(c.x - tile_w * 0.5, c.y - tile_h * 0.5, tile_w, tile_h), Color(1.0, 0.0, 0.0, 0.5))
	# Exit tiles occ==2 (BLAU=ok, ORANGE=solid Fehler!)
	if _occ.size() > 0:
		for gy in _occ_h:
			for gx in _occ_w:
				if _occ[gy * _occ_w + gx] == 2:
					var is_solid = astar.is_point_solid(Vector2i(gx, gy))
					var color = Color(1.0, 0.5, 0.0, 0.85) if is_solid else Color(0.0, 0.2, 0.9, 0.85)
					var c := to_local(tile_to_world(Vector2i(gx, gy)))
					draw_rect(Rect2(c.x - tile_w * 0.5, c.y - tile_h * 0.5, tile_w, tile_h), color)
					draw_line(Vector2(c.x - 4, c.y), Vector2(c.x + 4, c.y), Color.WHITE, 1.5)
					draw_line(Vector2(c.x, c.y - 4), Vector2(c.x, c.y + 4), Color.WHITE, 1.5)
	# Debug paths (gelb) - Grüner Kreis = Start, Roter Kreis = Ziel, Label am Start
	for key in _debug_paths:
		var entry = _debug_paths[key]
		var path = entry["path"]
		var lbl  = entry["label"]
		if path.size() > 1:
			var points := PackedVector2Array()
			for tile in path:
				points.append(to_local(tile_to_world(tile)))
			draw_polyline(points, Color.YELLOW, 2.0)
			draw_circle(points[0], 6.0, Color.GREEN)
			draw_circle(points[points.size() - 1], 6.0, Color.RED)
			draw_string(ThemeDB.fallback_font, points[0] + Vector2(6, -6), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	# Failed paths (magenta)
	for fp in _failed_paths:
		var st_pos := to_local(tile_to_world(fp["start"]))
		var et_pos := to_local(tile_to_world(fp["end"]))
		draw_line(st_pos, et_pos, Color(1.0, 0.0, 1.0, 0.8), 6.0)
		draw_circle(st_pos, 10.0, Color(1.0, 0.0, 1.0, 0.8))
		draw_circle(et_pos, 10.0, Color(1.0, 0.0, 1.0, 0.8))

# =============================================================================
func _exit_outside_parcel(_px: int, _py: int, exit: Vector2i, _door_rot: int) -> bool:
	if exit.x < 0 or exit.y < 0:
		return true
	var exit_px = floori(exit.x / float(PARCEL_SZ))
	var exit_py = floori(exit.y / float(PARCEL_SZ))
	return not _is_built(exit_px, exit_py)


# =============================================================================
## Gibt den occ-Wert eines Tiles zurück. 1 = solid, 4 = begehbar, 0 = Flur/leer.
func get_occ_value(tile: Vector2i) -> int:
	var idx := tile.y * _occ_w + tile.x
	if idx < 0 or idx >= _occ.size():
		return -1
	return _occ[idx]


# =============================================================================
## Findet das nächste begehbare Tile in der Nähe von 'tile'.
## Gibt das Original zurück falls es bereits begehbar ist.
func find_nearest_walkable(tile: Vector2i, search_radius: int = 5) -> Vector2i:
	if get_occ_value(tile) != 1:
		return tile
	for r in range(1, search_radius + 1):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if abs(dx) != r and abs(dy) != r:
					continue
				var candidate := tile + Vector2i(dx, dy)
				var val := get_occ_value(candidate)
				if val == 4 or val == 0:
					return candidate
	return tile


# ── Occupancy Grid – Kern ─────────────────────────────────────────────────────

# =============================================================================
func _occ_init() -> void:
	_occ_w = grid_cols * PARCEL_SZ
	_occ_h = grid_rows * PARCEL_SZ
	_occ   = PackedByteArray()
	_occ.resize(_occ_w * _occ_h)
	_occ.fill(3) # <--- ÄNDERUNG: Alles ist Wiese (blockiert)
	_setup_astar()


# =============================================================================
func _occ_mark(gx: int, gy: int, w: int, h: int) -> void:
	for dy in h:
		for dx in w:
			var idx := (gy + dy) * _occ_w + (gx + dx)
			if idx >= 0 and idx < _occ.size():
				if _occ[idx] != 2: # Tuer-Exit nicht ueberschreiben!
					_occ[idx] = 1
					_sync_astar_cell(gx + dx, gy + dy)


# =============================================================================
func _occ_mark_exit(gx: int, gy: int) -> void:
	if gx < 0 or gy < 0 or gx >= _occ_w or gy >= _occ_h:
		return
	var idx := gy * _occ_w + gx
	_occ[idx] = 2
	_sync_astar_cell(gx, gy)
	
	# GANZ WICHTIG: Türen DÜRFEN NIEMALS solid sein, selbst wenn _sync_astar_cell 
	# durch Clearance-Zonen oder Parzellen-Wände verwirrt wird!
	if astar:
		astar.set_point_solid(Vector2i(gx, gy), false)


# =============================================================================
func _occ_mark_wall(gx: int, gy: int, w: int, h: int) -> void:
	for dy in h:
		for dx in w:
			var idx := (gy + dy) * _occ_w + (gx + dx)
			if idx >= 0 and idx < _occ.size():
				var existing = _occ[idx]
				if existing != 1 and existing != 2:
					_occ[idx] = 3
					_sync_astar_cell(gx + dx, gy + dy)


# =============================================================================
func _occ_clear(gx: int, gy: int, w: int, h: int) -> void:
	for dy in h:
		for dx in w:
			var idx := (gy + dy) * _occ_w + (gx + dx)
			if idx >= 0 and idx < _occ.size(): # <--- ÄNDERUNG: Die != 3 Prüfung ist weg!
				_occ[idx] = 0
				_sync_astar_cell(gx + dx, gy + dy)


# =============================================================================
func _occ_free_for_room(gx: int, gy: int, w: int, h: int) -> bool:
	for dy in h:
		for dx in w:
			var ngx := gx + dx
			var ngy := gy + dy
			if ngx < 0 or ngy < 0 or ngx >= _occ_w or ngy >= _occ_h:
				return false
			var v := _occ[ngy * _occ_w + ngx]
			if v == 1 or v == 2 or v == 4: # <--- NEU: 4 (Clearance) blockiert Raumkörper!
				return false
	return true


# =============================================================================
# Exit-Tile darf auf Exit (2) landen – Tür-zu-Tür OK.
# Body (1) und Wand (3) blockieren den Exit.
func _occ_exit_free(gx: int, gy: int) -> bool:
	if gx < 0 or gy < 0 or gx >= _occ_w or gy >= _occ_h:
		return false
	var v := _occ[gy * _occ_w + gx]
	return v == 0 or v == 2 or v == 3


# =============================================================================
func _occ_has_room_body(gx: int, gy: int, w: int, h: int) -> bool:
	for dy in h:
		for dx in w:
			var ngx := gx + dx
			var ngy := gy + dy
			if ngx < 0 or ngy < 0 or ngx >= _occ_w or ngy >= _occ_h:
				continue
			if _occ[ngy * _occ_w + ngx] == 1:
				return true
	return false


# =============================================================================
func _occ_mark_clearance(gx: int, gy: int, w: int, h: int) -> void:
	for dy in h:
		for dx in w:
			var idx := (gy + dy) * _occ_w + (gx + dx)
			if idx >= 0 and idx < _occ.size():
				if _occ[idx] != 2:
					_occ[idx] = 4 # 4 = Freizuhaltende Zone (Begehbar, aber Bauverbot)
					_sync_astar_cell(gx + dx, gy + dy)


# =============================================================================
func remove_room(room: Node2D) -> void:
	if not active_rooms.has(room):
		return
		
	var sz: Vector2i = room.get_tile_size()
	var door_rot: int = room.get("door_rotation")
	var door_off: int = room.get("door_offset")
	var tile_x: int = int(room.position.x / TILE_PX)
	var tile_y: int = int(room.position.y / TILE_PX)
	var parcel_name = room.get_parent().name
	var px: int = int(parcel_name.split("_")[1])
	var py: int = int(parcel_name.split("_")[2])
	
	unmark_placement(px, py, tile_x, tile_y, sz.x, sz.y, door_rot, door_off)
	
	active_rooms.erase(room)
	if room.has_method("get_definition"):
		var def = room.get_definition()
		var unique_id = ""
		var gm = null
		if is_inside_tree():
			gm = get_tree().get_first_node_in_group("guest_manager")
		if is_instance_valid(gm) and gm.has_method("_room_key"):
			unique_id = gm._room_key(room)
		if def and def.has("id"):
			GameState.sig_room_demolished.emit(def["id"], unique_id)
	room.queue_free()
	
	_update_all_floor_neighbors()
	save_all_rooms_to_db(GameState.active_hotel_id)


# =============================================================================
func demolish_marked_rooms(silent: bool = false) -> void:
	var to_remove = []
	for room in active_rooms:
		if is_instance_valid(room) and room.get("is_pending_demolish"):
			# Nur abreißen, wenn der Raum aktuell leer ist (nicht von Gästen belegt)
			if guest_manager and guest_manager.get_party_in_room(room) == null:
				to_remove.append(room)
				
	for room in to_remove:
		var def = {}
		if room.has_method("get_definition"):
			def = room.get_definition()
		var cost = def.get("build_cost", 0)
		var refund = int(cost * 0.5)
		
		# Feedback
		var refund_pos = room.global_position + Vector2(16, 16)
		if refund > 0:
			FinanceManager.add_transaction(refund, "construction", "tx.auto_demolish|" + GameState.T(def.get("name", "Raum")))
			if not silent:
				EffectManager.spawn_money_text(refund, refund_pos)
			
		remove_room(room)


# =============================================================================
func save_all_rooms_to_db(hotel_id: int) -> void:
	for row_idx in range(_grid.size()):
		var row = _grid[row_idx]
		for col_idx in range(row.size()):
			var parcel: Node2D = row[col_idx]
			if not parcel.visible: continue
			
			var parcel_rooms: Array = []
			for child: Node in parcel.get_children():
				if child.has_method("to_dict") and child.get("room_type_id") != "lobby":
					parcel_rooms.append(child.call("to_dict"))
					
			SaveManager.overwrite_rooms_in_plot(hotel_id, col_idx, row_idx, parcel_rooms)


# =============================================================================
func _update_all_floor_neighbors() -> void:
	for py in grid_rows:
		for px in grid_cols:
			var parcel: Node2D = _grid[py][px]
			if not parcel.visible:
				continue
			for child: Node in parcel.get_children():
				if not child.has_method("get_tile_size"):
					continue
				var sz: Vector2i  = child.get_tile_size()
				var gx: int = px * PARCEL_SZ + int(child.position.x / TILE_PX)
				var gy: int = py * PARCEL_SZ + int(child.position.y / TILE_PX)
				child.set_floor_neighbors(
					_occ_has_room_body(gx,        gy - 1,   sz.x, 1),
					_occ_has_room_body(gx + sz.x, gy,       1,    sz.y),
					_occ_has_room_body(gx,        gy + sz.y, sz.x, 1),
					_occ_has_room_body(gx - 1,    gy,       1,    sz.y)
				)


# =============================================================================
func _mark_parcel_walls(parcel_x: int, parcel_y: int) -> void:
	var gx := parcel_x * PARCEL_SZ
	var gy := parcel_y * PARCEL_SZ
	# Wir baggern die komplette 16x16 Parzelle aus und machen sie zu Flur (0)
	_occ_clear(gx, gy, PARCEL_SZ, PARCEL_SZ)


# =============================================================================
func _mark_lobby_on_parcel(parcel_x: int, parcel_y: int) -> void:
	var parcel: Node2D = _grid[parcel_y][parcel_x]
	var gx := parcel_x * PARCEL_SZ
	var gy := parcel_y * PARCEL_SZ

	var lobby_rect: Rect2i = parcel.get_lobby_tile_rect()
	if lobby_rect.has_area():
		var lobby = parcel.get_lobby()
		if is_instance_valid(lobby):
			if not active_rooms.has(lobby):
				active_rooms.append(lobby)
			
			# Grundfläche der Lobby als Raum-Körper markieren (wie normale Räume)
			_occ_mark(gx + lobby_rect.position.x, gy + lobby_rect.position.y,
				lobby_rect.size.x, lobby_rect.size.y)
				
			# Tür-Exit markieren, falls die Lobby ein Target-Tile hat
			if lobby.has_method("get_target_tile"):
				var exit = lobby.get_target_tile(self)
				_occ_mark_exit(exit.x, exit.y)


# =============================================================================
func _exit_global(parcel_x: int, parcel_y: int, tile_x: int, tile_y: int,
	room_w: int, room_h: int, door_rot: int, door_off: int) -> Vector2i:
	var gx := parcel_x * PARCEL_SZ + tile_x
	var gy := parcel_y * PARCEL_SZ + tile_y

	match door_rot:
		0: return Vector2i(gx - 1,                      gy + (room_h - 1 - door_off)) # L: von unten nach oben
		1: return Vector2i(gx + door_off,               gy - 1)                       # T: von links nach rechts
		2: return Vector2i(gx + room_w,                 gy + door_off)                # R: von oben nach unten
		3: return Vector2i(gx + (room_w - 1 - door_off), gy + room_h)                 # B: von rechts nach links

	return Vector2i(-1, -1)


# ── Kamera ────────────────────────────────────────────────────────────────────

# =============================================================================
func _set_camera_limits() -> void:
	var map_px: float = (grid_cols * PARCEL_SZ + WALK_W * 2) * TILE_PX * SCALE
	var vp    := get_viewport_rect().size
	camera.limit_left   = -int(vp.x / 2.0)
	camera.limit_top    = -int(vp.y / 2.0)
	camera.limit_right  = int(map_px) + int(vp.x / 2.0)
	camera.limit_bottom = int(map_px) + int(vp.y / 2.0)


# =============================================================================
func _apply_zoom(delta: float) -> void:
	_clear_saved_view()
	var old_zoom = camera.zoom.x
	var new_zoom: float = clampf(old_zoom + delta, ZOOM_MIN, ZOOM_MAX)
	if old_zoom == new_zoom:
		return
		
	var mouse_screen_pos = get_viewport().get_mouse_position()
	var vp_size = get_viewport_rect().size
	var mouse_offset_screen = mouse_screen_pos - (vp_size / 2.0)
	
	camera.zoom = Vector2(new_zoom, new_zoom)
	
	# Kamera verschieben, damit der Punkt unter der Maus fixiert bleibt
	camera.global_position += mouse_offset_screen * (1.0 / old_zoom - 1.0 / new_zoom)


# =============================================================================
func _clear_saved_view() -> void:
	if not _has_saved_view:
		return
	_has_saved_view = false


# ── Signale vom InputHandler ausführen ────────────────────────────────────────

# =============================================================================
func _on_input_camera_pan(dir_delta: Vector2) -> void:
	if is_instance_valid(_buy_overlay_root):
		return
	camera.position += dir_delta * _pan_speed / camera.zoom.x


# =============================================================================
func _on_input_camera_zoom(step: float) -> void:
	if is_instance_valid(_buy_overlay_root):
		return
	# Wenn der Wert extrem klein ist, kommt er aus der _process (Tastatur-Delta)
	if abs(step) < 0.5:
		# Tastatur-Zoom drosseln, indem wir es verkleinern
		_apply_zoom(step * 0.2)
	else:
		# Mausrad-Impuls (1.0 / -1.0) mit einstellbarer Empfindlichkeit (ANG-223)
		_apply_zoom(step * (ZOOM_STEP * SettingsManager.scroll_zoom_sensitivity))


# =============================================================================
func _on_input_drag_started(mouse_pos: Vector2) -> void:
	if is_instance_valid(_buy_overlay_root):
		return
	_drag_active = true
	_drag_origin = mouse_pos
	_cam_origin = camera.position
	Input.set_default_cursor_shape(Input.CURSOR_DRAG)


# =============================================================================
func _on_input_drag_moved(mouse_pos: Vector2) -> void:
	if _drag_active:
		camera.position = _cam_origin - (mouse_pos - _drag_origin) / camera.zoom


# =============================================================================
func _on_input_drag_ended() -> void:
	_drag_active = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


# =============================================================================



# pathfinding


# =============================================================================
func _setup_astar() -> void:
	astar.region = Rect2i(0, 0, _occ_w, _occ_h)
	astar.cell_size = Vector2i(1, 1)
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()

	# Initiale Synchronisation aller Tiles
	for gy in _occ_h:
		for gx in _occ_w:
			_sync_astar_cell(gx, gy)


# =============================================================================
func _sync_astar_cell(gx: int, gy: int) -> void:
	if gx < 0 or gy < 0 or gx >= _occ_w or gy >= _occ_h:
		return
	var val = _occ[gy * _occ_w + gx]
	# 2 = Exit-Tile (Tür) → NIEMALS solid, egal was danach noch aufgerufen wird!
	if val == 2:
		if astar:
			astar.set_point_solid(Vector2i(gx, gy), false)
		return
	# 1 = Room Body, 3 = Wall → Diese blockieren den Weg!
	var is_solid: bool = (val == 1 or val == 3)
	astar.set_point_solid(Vector2i(gx, gy), is_solid)


# =============================================================================
func get_lobby_spawn_pos_world() -> Vector2:
	var entry_parcel: Node2D = _grid[_entry_plot.y][_entry_plot.x]
	var clearance: Rect2i = entry_parcel.get_lobby_clearance_rect()
	var start_x := (_entry_plot.x * PARCEL_SZ) + clearance.position.x + int(clearance.size.x / 2.0)
	var start_y := (_entry_plot.y * PARCEL_SZ) + clearance.position.y + int(clearance.size.y / 2.0)
	return tile_to_world(Vector2i(start_x, start_y))

# =============================================================================
func get_target_tile(room: Node2D) -> Vector2i:
	if room.has_method("get_target_tile"):
		return room.get_target_tile(self)
	if room.has_method("get_rect"):
		var rct = room.get_rect()
		return world_to_tile(room.to_global(rct.position + rct.size * 0.5))
	if room.has_method("get_tile_size"):
		var sz = room.get_tile_size() * 16.0
		return world_to_tile(room.global_position + Vector2(sz.x, sz.y) * 0.5)
	return world_to_tile(room.global_position)


# ── Plot Buy Mode ────────────────────────────────────────────────────────────

var _buy_overlay_root: Node2D

func enter_buy_mode() -> void:
	if is_instance_valid(_buy_overlay_root):
		_buy_overlay_root.queue_free()
	_buy_overlay_root = Node2D.new()
	_buy_overlay_root.process_mode = Node.PROCESS_MODE_ALWAYS
	$WorldRoot.add_child(_buy_overlay_root)
	
	# Zoom out further to show entire map (including behind UI)
	camera.zoom = Vector2(0.33, 0.33)
	var map_center = Vector2((grid_cols * PARCEL_SZ * TILE_PX) / 2.0, (grid_rows * PARCEL_SZ * TILE_PX) / 2.0)
	camera.global_position = map_center * SCALE
	
	var active_plots = SaveManager.get_active_plots(GameState.active_hotel_id)
	var built_count = active_plots.size()
	var plot_price = int(4000 * (1 << (built_count - 1)) if built_count > 0 else 4000)
	
	var current_level = GameState.get_level()
	var max_plots = 1 + max(0, floori((current_level - 2) / 2.0))
	
	for y in grid_rows:
		for x in grid_cols:
			var p = _grid[y][x]
			p.set_buy_mode(true)
			
			if p.is_built:
				continue
				
			var overlay = ColorRect.new()
			overlay.size = Vector2(PARCEL_SZ * TILE_PX, PARCEL_SZ * TILE_PX)
			overlay.position = p.position
			
			if p.is_constructing:
				overlay.color = Color(0.15, 0.4, 0.15, 0.5) # Darker green transparent
				var lbl = Label.new()
				lbl.theme = load("res://assets/ui/default_theme.tres")
				lbl.add_theme_font_size_override("font_size", 34)
				lbl.text = TranslationServer.translate("plot.under_construction")
				lbl.size = overlay.size
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				overlay.add_child(lbl)
				_buy_overlay_root.add_child(overlay)
				continue
				
			var is_adjacent = false
			if x > 0 and (_grid[y][x-1].is_built or _grid[y][x-1].is_constructing): is_adjacent = true
			if x < grid_cols-1 and (_grid[y][x+1].is_built or _grid[y][x+1].is_constructing): is_adjacent = true
			if y > 0 and (_grid[y-1][x].is_built or _grid[y-1][x].is_constructing): is_adjacent = true
			if y < grid_rows-1 and (_grid[y+1][x].is_built or _grid[y+1][x].is_constructing): is_adjacent = true
			
			if is_adjacent:
				if built_count >= max_plots:
					overlay.color = Color(1.0, 0.0, 0.0, 0.15) # Red transparent
					var lbl = Label.new()
					lbl.theme = load("res://assets/ui/default_theme.tres")
					lbl.add_theme_font_size_override("font_size", 34)
					
					var required_level = 2 + built_count * 2
					if required_level <= 10:
						lbl.text = GameState.T("plot.locked_level", "Level %d benötigt") % required_level
					else:
						lbl.text = GameState.T("plot.max_reached", "Max. Parzellen")
						
					lbl.size = overlay.size
					lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
					overlay.add_child(lbl)
				else:
					overlay.color = Color(1.0, 0.64, 0.0, 0.15) # Orange transparent
					var btn = Button.new()
					btn.theme = load("res://assets/ui/default_theme.tres")
					btn.text = GameState.T("plot.buy", "Kaufen") + "\n%s €" % GameState.format_money(plot_price)
					btn.add_theme_font_size_override("font_size", 34)
					btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
					btn.size = Vector2(180, 80)
					btn.position = (overlay.size - btn.size) / 2.0
					btn.pressed.connect(func(): _on_plot_buy_clicked(x, y, plot_price))
					
					var normal_style = load("res://assets/ui/menu_button_blue.tres")
					if normal_style:
						btn.add_theme_stylebox_override("normal", normal_style)
						btn.add_theme_stylebox_override("hover", load("res://assets/ui/menu_button_blue_hover.tres"))
						btn.add_theme_stylebox_override("pressed", load("res://assets/ui/menu_button_blue_pressed.tres"))
					
					overlay.add_child(btn)
			else:
				overlay.color = Color(1.0, 0.0, 0.0, 0.08) # Red transparent
				var lbl = Label.new()
				lbl.theme = load("res://assets/ui/default_theme.tres")
				lbl.add_theme_font_size_override("font_size", 34)
				lbl.text = GameState.T("plot.not_available", "Nicht verfügbar")
				lbl.size = overlay.size
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				overlay.add_child(lbl)
				
			_buy_overlay_root.add_child(overlay)


func exit_buy_mode() -> void:
	if is_instance_valid(_buy_overlay_root):
		_buy_overlay_root.queue_free()
	_buy_overlay_root = null  # Sofort nullen → Zoom ist im gleichen Frame wieder aktiv
		
	for y in grid_rows:
		for x in grid_cols:
			if is_instance_valid(_grid[y][x]):
				_grid[y][x].set_buy_mode(false)
				
	if _entry_plot != Vector2i(-1, -1):
		center_on_entry(_entry_plot)


func _on_plot_buy_clicked(x: int, y: int, price: int) -> void:
	if int(GameState.selected_hotel.get("money", 0)) < price:
		if is_instance_valid(Toast): Toast.show(GameState.T("ui.toast.not_enough_money", "Nicht genug Geld!"), "money", false)
		return
		
	var confirm_scene = load("res://scenes/shared/ConfirmModal.tscn")
	var confirm = confirm_scene.instantiate()
	var ui_root = get_parent().get_node_or_null("HUD")
	if not ui_root:
		ui_root = self
	ui_root.add_child(confirm)
	
	confirm.confirmed.connect(func():
		if FinanceManager:
			FinanceManager.add_transaction(-price, "building", "tx.plot_buy|" + str(x) + "," + str(y))
		else:
			GameState.add_money(-price)
			
		var center_px = (PARCEL_SZ * TILE_PX) / 2.0
		var spawn_pos = Vector2(x * PARCEL_SZ * TILE_PX + center_px, y * PARCEL_SZ * TILE_PX + center_px) * SCALE
		if EffectManager:
			EffectManager.spawn_money_text(-price, spawn_pos)
			
		var p = _grid[y][x]
		p.start_construction(GameState.active_hotel_id, TimeManager.get_absolute_time() + 1440)
		
		if is_instance_valid(Toast): Toast.show(GameState.T("ui.toast.plot_bought", "Parzelle gekauft! Bau beginnt."), "build")
		
		# Refresh overlay
		exit_buy_mode()
		enter_buy_mode()
		
		confirm.queue_free()
	)
	
	confirm.cancelled.connect(func(): confirm.queue_free())
	confirm.ask(GameState.T("ui.confirm.plot_buy_title", "Parzelle kaufen?"), GameState.T("ui.confirm.plot_buy_desc", "Möchtest du diese Parzelle für %s € kaufen?") % GameState.format_money(price), GameState.T("plot.buy", "Kaufen"))


# =============================================================================
func get_room_exit_tile(room: Node2D) -> Vector2i:
	var sz: Vector2i = room.get_tile_size()
	var door_rot: int = room.get("door_rotation")
	var door_off: int = room.get("door_offset")
	var tile_x: int = int(room.position.x / TILE_PX)
	var tile_y: int = int(room.position.y / TILE_PX)
	var px: int = int(room.get_parent().name.split("_")[1])
	var py: int = int(room.get_parent().name.split("_")[2])
	return _exit_global(px, py, tile_x, tile_y, sz.x, sz.y, door_rot, door_off)
