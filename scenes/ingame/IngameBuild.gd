extends Node2D
class_name IngameBuild

@warning_ignore("unused_signal")
signal sig_room_built(room_type_id: String)

var _hotel:              Dictionary
var _map_grid:           Node2D
var _hud:                Node
var _hud_canvas:         CanvasLayer
var _build_cursor:       Node2D


# =============================================================================
func configure(hotel: Dictionary, map_grid: Node2D, hud: Node, hud_canvas: Node) -> void:
	_hotel      = hotel
	_map_grid   = map_grid
	_hud        = hud
	_hud_canvas = hud_canvas

# ── Public API ────────────────────────────────────────────────────────────────


# =============================================================================
func close_all() -> void:
	if is_instance_valid(_build_cursor):
		_build_cursor.queue_free()
		_on_build_cursor_done()


# ── Neue Schnittstelle für das BuildMenu ──────────────────────────────────────

# =============================================================================
func start_building(room_scene: PackedScene) -> void:
	if is_instance_valid(_build_cursor):
		_build_cursor.queue_free()

	var cursor := Node2D.new()
	cursor.set_script(load("res://scenes/ingame/build/BuildCursor.gd"))
	_map_grid.get_world_root().add_child(cursor)

	cursor.sig_room_placed.connect(func(px: int, py: int, tx: int, ty: int, dr: int, doff: int, rrot: int, wc: Vector2) -> void:
		_on_room_placed(room_scene, px, py, tx, ty, dr, doff, rrot, wc)
	)
	cursor.sig_cancelled.connect(_on_build_cursor_done)

	cursor.tree_exited.connect(func() -> void:
		if _build_cursor == cursor:
			_build_cursor = null
	)

	_build_cursor = cursor
	cursor.activate(_map_grid, room_scene)

	if is_instance_valid(_hud_canvas) and _hud_canvas.has_method("set_build_mode_visuals"):
		_hud_canvas.set_build_mode_visuals(true)

# =============================================================================
func start_demolish() -> void:
	if is_instance_valid(_build_cursor):
		_build_cursor.queue_free()

	var cursor := Node2D.new()
	cursor.set_script(load("res://scenes/ingame/build/DemolishCursor.gd"))
	_map_grid.get_world_root().add_child(cursor)

	cursor.sig_cancelled.connect(_on_build_cursor_done)

	cursor.tree_exited.connect(func() -> void:
		if _build_cursor == cursor:
			_build_cursor = null
	)

	_build_cursor = cursor
	cursor.activate(_map_grid)

	if is_instance_valid(_hud_canvas) and _hud_canvas.has_method("set_build_mode_visuals"):
		_hud_canvas.set_build_mode_visuals(true)


# =============================================================================
func _on_tool_selected(action: String) -> void:
	if action == "demolish":
		start_demolish()


# =============================================================================
func _on_room_placed(room_scene: PackedScene, px: int, py: int, tx: int, ty: int, dr: int, doff: int, rrot: int, world_center: Vector2) -> void:
	# Definition temporär und sauber direkt aus der Szene auslesen
	var temp_room = room_scene.instantiate()
	var script: Script = temp_room.get_script()
	var def: Dictionary = {}
	if script and script.has_method("get_definition"):
		def = script.call("get_definition")
	temp_room.free()

	var cost: int = def.get("build_cost", 0)

	if float(cost) > _hotel.get("money", 0.0):
		Toast.show(GameState.T("toast.build.no_money"))
		return

	var room_number := _next_room_number(def)
	_map_grid.place_room(px, py, room_scene, _hotel.get("id", -1), dr, doff, tx, ty, rrot, room_number)
	_apply_build_costs(def, world_center)
	_apply_build_rewards(def, world_center)
	sig_room_built.emit(def.get("id", "unknown"))
	GameState.sig_room_built.emit(def.get("id", "unknown"))


# =============================================================================
func _apply_build_costs(def: Dictionary, world_center: Vector2) -> void:
	var cost: int = def.get("build_cost", 0)
	if cost > 0:
		# NEU: Über den FinanceManager routen
		var room_name: String = GameState.T(def.get("name", "Raum"))
		FinanceManager.add_transaction(-cost, "construction", "tx.build|" + room_name)

		EffectManager.spawn_money_text(-cost, world_center)


# =============================================================================
func _apply_build_rewards(def: Dictionary, world_center: Vector2) -> void:
	var xp: int = def.get("exp_reward", 0)
	var room_id: String = def.get("id", "")
	
	if xp > 0 and room_id != "":
		var built_types: Array = _hotel.get("built_room_types", [])
		if not built_types.has(room_id):
			built_types.append(room_id)
			_hotel["built_room_types"] = built_types
			GameState.add_exp(xp, "Bau: " + room_id + " (IngameBuild)")
			EffectManager.spawn_exp_text(xp, world_center)


# =============================================================================
func _on_build_cursor_done() -> void:
	_build_cursor = null

	if is_instance_valid(_hud_canvas) and _hud_canvas.has_method("set_build_mode_visuals"):
		_hud_canvas.set_build_mode_visuals(false)


# =============================================================================
func _next_room_number(def: Dictionary) -> String:
	var prefix: String = def.get("prefix", "")

	if prefix == "":
		return ""

	var key  := "next_%s_id" % prefix.to_lower()
	var next := _hotel.get(key, 1) as int
	_hotel[key] = next + 1
	return "%s%04d" % [prefix, next]
