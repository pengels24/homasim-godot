extends Node2D
class_name IngameBuild
## ANG-170 – BuildMenu + BuildCursor Koordination, BottomBar-Button-Handler.
## Erhält alle nötigen Node-Referenzen via configure(). Keine @onready.

const BUILD_PANEL_SCENE  := preload("res://scenes/ingame/build/BuildPanel.tscn")
const BUILD_PANEL_SCRIPT := preload("res://scenes/ingame/build/BuildPanel.gd")

const SCENE_PATHS: Dictionary = {
	"bed_standard": "res://scenes/ingame/rooms/bed_standard/Bed_Standard.tscn",
	"bed_double": "res://scenes/ingame/rooms/bed_double/Bed_Double.tscn",
	"hr_office": "res://scenes/ingame/rooms/hr_office/Hr_Office.tscn",
	"sc_office": "res://scenes/ingame/rooms/sc_office/Sc_Office.tscn",
	"bar": "res://scenes/ingame/rooms/bar/Bar.tscn",
}

signal room_built(room_type_id: String)

var _hotel:              Dictionary
var _map_grid:           Node2D
var _hud:                IngameHud
var _hud_canvas:         CanvasLayer

var _build_panel:  PanelContainer
var _build_cursor: Node2D
var _active_submenu:      PanelContainer
var _active_submenu_idx:  int = -1


func configure(hotel: Dictionary, map_grid: Node2D, hud: IngameHud, hud_canvas: CanvasLayer) -> void:
	_hotel      = hotel
	_map_grid   = map_grid
	_hud        = hud
	_hud_canvas = hud_canvas


# ── Public API ────────────────────────────────────────────────────────────────

func on_button_pressed(idx: int) -> void:
	if idx == 0:
		_toggle_build_panel()
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


## Schließt das oberste offene Layer (Cursor → Menü → Submenü).
## Gibt true zurück wenn etwas geschlossen wurde – Ingame nutzt das für ESC-Handling.
func close_all() -> bool:
	if is_instance_valid(_build_cursor):
		_build_cursor.queue_free()
		_build_cursor = null
		_hud.set_btn_active(-1)
		return true
	if is_instance_valid(_build_panel):
		_close_build_panel_animated()
		return true
	if _active_submenu != null:
		_active_submenu.queue_free()
		_active_submenu = null
		_hud.set_btn_active(-1)
		_active_submenu_idx = -1
		return true
	return false


# ── BuildPanel ────────────────────────────────────────────────────────────────

func _toggle_build_panel() -> void:
	if is_instance_valid(_build_panel):
		_close_build_panel_animated()
		return
	_hud.set_btn_active(0)
	_build_panel = BUILD_PANEL_SCENE.instantiate()
	_build_panel.room_selected.connect(_on_build_room_selected)
	_build_panel.tree_exited.connect(func() -> void:
		_build_panel = null
		_hud.set_btn_active(-1)
	)
	_hud_canvas.add_child(_build_panel)
	await get_tree().process_frame
	_position_build_panel()
	_animate_panel_in()


func _position_build_panel() -> void:
	if not is_instance_valid(_build_panel):
		return
	var bar_rect := _hud.get_bottom_bar_global_rect()
	_build_panel.position = Vector2(
		bar_rect.position.x,
		bar_rect.position.y - _build_panel.size.y - 6.0
	)


func _animate_panel_in() -> void:
	if not is_instance_valid(_build_panel):
		return
	var final_y := _build_panel.position.y
	_build_panel.position.y = final_y + _build_panel.size.y + 8.0
	_build_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tw := _build_panel.create_tween()
	tw.set_parallel(true)
	tw.tween_property(_build_panel, "position:y", final_y, 0.20) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_build_panel, "modulate:a", 1.0, 0.16) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)


func _close_build_panel_animated() -> void:
	if not is_instance_valid(_build_panel):
		return
	_hud.set_btn_active(-1)
	var panel := _build_panel
	_build_panel = null
	var target_y := panel.position.y + panel.size.y + 8.0
	var tw := panel.create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "position:y", target_y, 0.16) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(panel, "modulate:a", 0.0, 0.12) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_LINEAR)
	tw.set_parallel(false)
	tw.tween_callback(panel.queue_free)


func _on_build_room_selected(room_type_id: String) -> void:
	if is_instance_valid(_build_cursor):
		_build_cursor.queue_free()
	var cursor := Node2D.new()
	cursor.set_script(load("res://scenes/ingame/build/BuildCursor.gd"))
	_map_grid.get_world_root().add_child(cursor)
	cursor.room_placed.connect(func(px: int, py: int, tx: int, ty: int, dr: int, doff: int, rrot: int, wc: Vector2) -> void:
		_on_room_placed(room_type_id, px, py, tx, ty, dr, doff, rrot, wc)
	)
	cursor.cancelled.connect(_on_build_cursor_done)
	cursor.tree_exited.connect(func() -> void:
		if _build_cursor == cursor:
			_build_cursor = null
			_hud.show_context_bar(false)
	)
	_build_cursor = cursor
	cursor.activate(_map_grid, room_type_id)
	# Panel bleibt offen – Cursor läuft parallel


func _on_room_placed(room_type_id: String, px: int, py: int, tx: int, ty: int, dr: int, doff: int, rrot: int, world_center: Vector2) -> void:
	var path: String = SCENE_PATHS.get(room_type_id, "")
	if path == "":
		return

	var def:  Dictionary = BUILD_PANEL_SCRIPT.find_definition(room_type_id)
	var cost: int        = def.get("build_cost", 0)

	if float(cost) > _hotel.get("money", 0.0):
		Toast.show(GameState.T("toast.build.no_money"))
		return

	var room_number := _next_room_number(def)
	_map_grid.place_room(px, py, load(path), _hotel.get("id", -1), dr, doff, tx, ty, rrot, room_number)
	_apply_build_costs(def, cost, world_center)
	room_built.emit(room_type_id)


func _apply_build_costs(def: Dictionary, cost: int, world_center: Vector2) -> void:
	if cost > 0:
		_hotel["money"] = _hotel.get("money", 0.0) - float(cost)
		_hud.update_money(_hotel["money"])
		FloatingValues.spawn("-%d €" % cost, -1.0, world_center, _hud.get_stat_money_node(), Vector2(-48.0, 0.0))

	var xp: int = def.get("xp_reward", 0)
	if xp > 0:
		_hotel["xp"] = _hotel.get("xp", 0) + xp
		_hud.update_exp(_hotel["xp"])
		FloatingValues.spawn("+%d XP" % xp, 1.0, world_center, _hud.get_stat_exp_node(), Vector2(48.0, 0.0))


func _on_build_cursor_done() -> void:
	_build_cursor = null
	if is_instance_valid(_build_panel):
		_build_panel.clear_active_item()


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
