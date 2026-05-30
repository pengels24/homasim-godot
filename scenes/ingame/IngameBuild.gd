extends Node2D
class_name IngameBuild
## ANG-170 – BuildMenu + BuildCursor Koordination, BottomBar-Button-Handler.
## Erhält alle nötigen Node-Referenzen via configure(). Keine @onready.

# 1. ALTE PFADE UND MENÜS SIND KOMPLETT GELÖSCHT!

signal room_built(room_type_id: String)

var _hotel:              Dictionary
var _map_grid:           Node2D
var _hud:                Node
var _hud_canvas:         CanvasLayer

var _build_cursor:       Node2D
var _active_submenu:     PanelContainer
var _active_submenu_idx: int = -1


func configure(hotel: Dictionary, map_grid: Node2D, hud: Node, hud_canvas: Node) -> void:
	_hotel      = hotel
	_map_grid   = map_grid
	_hud        = hud
	_hud_canvas = hud_canvas

# ── Public API ────────────────────────────────────────────────────────────────

func on_button_pressed(idx: int) -> void:
	if idx == 0:
		# Das Build-Menu wird jetzt vom InputHandler gesteuert! Wir tun hier nichts.
		return

	if _active_submenu != null:
		_active_submenu.queue_free()
		_active_submenu = null

	if _active_submenu_idx == idx:
		_hud.set_btn_active(-1)
		_active_submenu_idx = -1
		return

	_hud.set_btn_active(idx)
	_active_submenu_idx = idx
	_open_submenu(idx)


func close_all() -> bool:
	if is_instance_valid(_build_cursor):
		_build_cursor.queue_free()
		_build_cursor = null
		_hud.set_btn_active(-1)
		return true
	if _active_submenu != null:
		_active_submenu.queue_free()
		_active_submenu = null
		_hud.set_btn_active(-1)
		_active_submenu_idx = -1
		return true
	return false

# ── Neue Schnittstelle für das BuildMenu ──────────────────────────────────────

func start_building(room_scene: PackedScene) -> void:
	if is_instance_valid(_build_cursor):
		_build_cursor.queue_free()

	var cursor := Node2D.new()
	cursor.set_script(load("res://scenes/ingame/build/BuildCursor.gd"))
	_map_grid.get_world_root().add_child(cursor)

	cursor.room_placed.connect(func(px: int, py: int, tx: int, ty: int, dr: int, doff: int, rrot: int, wc: Vector2) -> void:
		_on_room_placed(room_scene, px, py, tx, ty, dr, doff, rrot, wc)
	)
	cursor.cancelled.connect(_on_build_cursor_done)

	cursor.tree_exited.connect(func() -> void:
		if _build_cursor == cursor:
			_build_cursor = null
			if _hud.has_method("show_context_bar"):
				_hud.show_context_bar(false)
	)

	_build_cursor = cursor
	cursor.activate(_map_grid, room_scene)


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
	# Hier übergeben wir nun direkt die Szene anstatt eines Dateipfads an das MapGrid!
	_map_grid.place_room(px, py, room_scene, _hotel.get("id", -1), dr, doff, tx, ty, rrot, room_number)
	_apply_build_costs(def, world_center)
	_apply_build_rewards(def, world_center)
	room_built.emit(def.get("id", "unknown"))


func _apply_build_costs(def: Dictionary, world_center: Vector2) -> void:
	var cost: int = def.get("build_cost", 0)
	if cost > 0:
		GameState.add_money(-cost)
		EffectManager.spawn_money_text(-cost, world_center)


func _apply_build_rewards(def: Dictionary, world_center: Vector2) -> void:
	var xp: int = def.get("exp_reward", 0)
	if xp > 0:
		GameState.add_exp(xp)
		EffectManager.spawn_exp_text(xp, world_center)


func _on_build_cursor_done() -> void:
	_build_cursor = null


func _next_room_number(def: Dictionary) -> String:
	var prefix: String = def.get("prefix", "")
	if prefix == "":
		return ""
	var key  := "next_%s_id" % prefix.to_lower()
	var next := _hotel.get(key, 1) as int
	_hotel[key] = next + 1
	return "%s%04d" % [prefix, next]

# ── Submenü (Platzhalter) ─────────────────────────────────────────────────────

func _open_submenu(_idx: int) -> void:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color                   = Color(0.04, 0.06, 0.10, 0.95)
	sb.corner_radius_top_left     = 10
	sb.corner_radius_top_right    = 10
	sb.corner_radius_bottom_left  = 10
	sb.corner_radius_bottom_right = 10
	sb.border_width_top           = 1
	sb.border_width_left          = 1
	sb.border_width_right         = 1
	sb.border_width_bottom        = 1
	sb.border_color               = Color(0.918, 0.702, 0.031, 0.30)
	sb.content_margin_left        = 16.0
	sb.content_margin_right       = 16.0
	sb.content_margin_top         = 12.0
	sb.content_margin_bottom      = 12.0
	panel.add_theme_stylebox_override("panel", sb)

	var lbl := Label.new()
	lbl.text = GameState.T("ingame.submenu.coming_soon")
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 1))
	panel.add_child(lbl)

	_hud_canvas.add_child(panel)
	panel.set_anchors_preset(Control.PRESET_CENTER)

	await get_tree().process_frame
	if not is_instance_valid(self) or not is_instance_valid(panel):
		return
	var vp := get_viewport().get_visible_rect().size
	panel.position = (vp - panel.size) * 0.5
	_active_submenu = panel
