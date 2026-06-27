extends MarginContainer
class_name ModalContentRoomList

@onready var room_list_container: VBoxContainer = %RoomListContainer
@onready var pip_camera: PipCamera = %PipCamera
@onready var detail_name_lbl: Label = %DetailNameLabel
@onready var detail_id_lbl: Label = %DetailIdLabel
@onready var detail_id_val: Label = %DetailIdValue
@onready var detail_guest_lbl: Label = %DetailGuestLabel
@onready var detail_guest_val: Label = %DetailGuestValue
@onready var detail_clean_lbl: Label = %DetailCleanLabel
@onready var detail_clean_val: Label = %DetailCleanValue
@onready var detail_maint_lbl: Label = %DetailMaintLabel
@onready var detail_maint_val: Label = %DetailMaintValue
@onready var btn_goto: Button = %BtnGoto

var _selected_room: Node2D = null
var _map_grid: Node2D = null
var _guest_manager: Node = null

var _btn_group: ButtonGroup
var _active_rows: Array[Dictionary] = []
var _update_timer: float = 0.0

func _ready() -> void:
	btn_goto.add_theme_stylebox_override("normal", load("res://assets/UI/menu_button_blue.tres"))
	btn_goto.add_theme_stylebox_override("hover", load("res://assets/UI/menu_button_blue_hover.tres"))
	btn_goto.add_theme_stylebox_override("pressed", load("res://assets/UI/menu_button_blue_pressed.tres"))
	
	var ingame = get_tree().get_root().get_node_or_null("Ingame")
	if ingame:
		_map_grid = ingame.get("map_grid")
		_guest_manager = ingame.get("_guest_mgr")
		
	btn_goto.pressed.connect(_on_goto_pressed)
	
	detail_id_lbl.text = GameState.T("room") + ":"
	detail_guest_lbl.text = GameState.T("guest") + ":"
	detail_clean_lbl.text = GameState.T("cleanliness") + ":"
	detail_maint_lbl.text = GameState.T("maintenance") + ":"
	
	_apply_translations()
	
	_btn_group = ButtonGroup.new()
	_populate_list()
	_clear_details()

func _apply_translations() -> void:
	btn_goto.text = GameState.T("ui.room_list.goto")
	
	var header_hbox = find_child("TableHeaderPanel", true, false).get_child(0).get_child(0)
	if header_hbox:
		var lbl_name = header_hbox.get_node_or_null("LblColName")
		if lbl_name: lbl_name.text = GameState.T("ui.room_list.col.name_type")
		var lbl_id = header_hbox.get_node_or_null("LblColId")
		if lbl_id: lbl_id.text = GameState.T("ui.room_list.col.room")
		var lbl_guest = header_hbox.get_node_or_null("LblColGuest")
		if lbl_guest: lbl_guest.text = GameState.T("ui.room_list.col.guest")
		var lbl_clean = header_hbox.get_node_or_null("LblColClean")
		if lbl_clean: lbl_clean.text = GameState.T("ui.room_list.col.clean")
		var lbl_maint = header_hbox.get_node_or_null("LblColMaint")
		if lbl_maint: lbl_maint.text = GameState.T("ui.room_list.col.condition")

func _populate_list() -> void:
	_active_rows.clear()
	for child in room_list_container.get_children():
		child.queue_free()
		
	if not _map_grid or not _map_grid.has_method("get_placed_rooms"):
		return
		
	var rooms = _map_grid.get_placed_rooms()
	for room in rooms:
		_create_list_item(room)

func _create_list_item(room: Node2D) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 44)
	btn.toggle_mode = true
	btn.button_group = _btn_group
	
	var sb_empty = StyleBoxEmpty.new()
	var sb_hover = StyleBoxFlat.new()
	sb_hover.bg_color = Color(1, 1, 1, 0.1)
	sb_hover.set_corner_radius_all(4)
	var sb_selected = StyleBoxFlat.new()
	sb_selected.bg_color = Color(0.5, 0.35, 0.05, 0.8)
	sb_selected.set_corner_radius_all(4)
	
	btn.add_theme_stylebox_override("normal", sb_empty)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_selected)
	btn.add_theme_stylebox_override("focus", sb_empty)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	margin.add_child(hbox)
	
	var font_color = Color("#CCCCCC")
	
	var r_num = room.get("room_number")
	var r_id = str(r_num) if r_num != null and str(r_num) != "" else "-"
	var r_def = room.get_definition() if room.has_method("get_definition") else {}
	var r_name = GameState.T(r_def.get("name", GameState.T("room")))
	
	# Name
	var lbl_name = Label.new()
	lbl_name.text = r_name
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_name.size_flags_stretch_ratio = 2.0
	lbl_name.add_theme_color_override("font_color", font_color)
	
	# ID
	var lbl_id = Label.new()
	lbl_id.text = r_id
	lbl_id.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_id.size_flags_stretch_ratio = 1.0
	lbl_id.add_theme_color_override("font_color", font_color)
	
	# Guest
	var guest_info = _get_guest_name_for_room(r_id)
	var lbl_guest = Label.new()
	lbl_guest.text = guest_info[0]
	if guest_info[1] != "":
		lbl_guest.tooltip_text = guest_info[1]
	lbl_guest.mouse_filter = Control.MOUSE_FILTER_PASS
	lbl_guest.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_guest.size_flags_stretch_ratio = 1.5
	lbl_guest.add_theme_color_override("font_color", font_color)
	
	# Cleanliness
	var clean = room.get("cleanliness_level") if "cleanliness_level" in room else 100
	var lbl_clean = Label.new()
	lbl_clean.text = "%d%%" % clean
	lbl_clean.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_clean.size_flags_stretch_ratio = 1.0
	_set_status_color(lbl_clean, clean)
	
	# Maintenance
	var maint = room.get("maintenance_level") if "maintenance_level" in room else 100
	var lbl_maint = Label.new()
	lbl_maint.text = "%d%%" % maint
	lbl_maint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_maint.size_flags_stretch_ratio = 1.0
	_set_status_color(lbl_maint, maint)
	
	hbox.add_child(lbl_name)
	hbox.add_child(lbl_id)
	hbox.add_child(lbl_guest)
	hbox.add_child(lbl_clean)
	hbox.add_child(lbl_maint)
	
	btn.add_child(margin)
	btn.pressed.connect(_on_room_selected.bind(room, btn))
	room_list_container.add_child(btn)
	
	_active_rows.append({
		"room": room,
		"lbl_guest": lbl_guest,
		"lbl_clean": lbl_clean,
		"lbl_maint": lbl_maint
	})

func _get_guest_name_for_room(room_id: String) -> Array:
	if not _guest_manager: return ["-", ""]
	# We only care about active parties
	for party in _guest_manager.get("_active"):
		if party.get("room_id") == room_id:
			var members = party.get("members")
			if members and members.size() > 0:
				var primary_name = ""
				var tooltip = ""
				for m in members:
					var m_name = m.get("name")
					if tooltip != "": tooltip += "\n"
					tooltip += m_name
					if m.has_method("is_primary") and m.is_primary() and primary_name == "":
						primary_name = m_name
				
				if primary_name == "":
					primary_name = members[0].get("name")
				
				if members.size() > 1:
					primary_name += " [+%d]" % (members.size() - 1)
					
				return [primary_name, tooltip]
	return ["-", ""]

func _set_status_color(lbl: Label, value: int) -> void:
	if value < 30:
		lbl.add_theme_color_override("font_color", Color.RED)
	elif value < 70:
		lbl.add_theme_color_override("font_color", Color.YELLOW)
	else:
		lbl.add_theme_color_override("font_color", Color("#CCCCCC"))

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
		
	_update_timer -= delta
	if _update_timer <= 0.0:
		_update_timer = 1.0
		_refresh_live_data()

func _refresh_live_data() -> void:
	for row in _active_rows:
		var room = row.room
		if not is_instance_valid(room): continue
		
		var r_num = room.get("room_number")
		var r_id = str(r_num) if r_num != null and str(r_num) != "" else "-"
		var guest_info = _get_guest_name_for_room(r_id)
		row.lbl_guest.text = guest_info[0]
		if guest_info[1] != "":
			row.lbl_guest.tooltip_text = guest_info[1]
		else:
			row.lbl_guest.tooltip_text = ""
		
		var clean = room.get("cleanliness_level") if "cleanliness_level" in room else 100
		row.lbl_clean.text = "%d%%" % clean
		_set_status_color(row.lbl_clean, clean)
		
		var maint = room.get("maintenance_level") if "maintenance_level" in room else 100
		row.lbl_maint.text = "%d%%" % maint
		_set_status_color(row.lbl_maint, maint)
		
	# Update Detail panel
	if is_instance_valid(_selected_room):
		var clean = _selected_room.get("cleanliness_level") if "cleanliness_level" in _selected_room else 100
		var maint = _selected_room.get("maintenance_level") if "maintenance_level" in _selected_room else 100
		
		detail_clean_val.text = "%d%%" % clean
		detail_maint_val.text = "%d%%" % maint
		
		var r_num = _selected_room.get("room_number")
		var r_id = str(r_num) if r_num != null and str(r_num) != "" else "-"
		var guest_info = _get_guest_name_for_room(r_id)
		detail_guest_val.text = guest_info[0]
		detail_guest_val.mouse_filter = Control.MOUSE_FILTER_PASS
		if guest_info[1] != "":
			detail_guest_val.tooltip_text = guest_info[1]
		else:
			detail_guest_val.tooltip_text = ""

func _on_room_selected(room: Node2D, btn: Button) -> void:
	_selected_room = room
	pip_camera.set_target(room)
	
	btn_goto.add_theme_stylebox_override("normal", load("res://assets/UI/menu_button_blue.tres"))
	btn_goto.add_theme_stylebox_override("hover", load("res://assets/UI/menu_button_blue_hover.tres"))
	btn_goto.add_theme_stylebox_override("pressed", load("res://assets/UI/menu_button_blue_pressed.tres"))
	
	var r_num = room.get("room_number")
	var r_id = str(r_num) if r_num != null and str(r_num) != "" else "-"
	var r_def = room.get_definition() if room.has_method("get_definition") else {}
	var r_name = GameState.T(r_def.get("name", GameState.T("room")))
	
	detail_name_lbl.text = r_name
	detail_id_val.text = r_id
	
	btn_goto.disabled = false
	_refresh_live_data()

func _clear_details() -> void:
	_selected_room = null
	pip_camera.set_target(null)
	detail_name_lbl.text = GameState.T("ui.room_list.please_select")
	detail_id_val.text = "---"
	detail_guest_val.text = "---"
	detail_clean_val.text = "---"
	detail_maint_val.text = "---"
	btn_goto.disabled = true
	btn_goto.add_theme_stylebox_override("disabled", load("res://assets/UI/menu_button_darkblue_disabled.tres"))

func _on_goto_pressed() -> void:
	if not is_instance_valid(_selected_room):
		return
		
	var cam = _map_grid.get_node_or_null("Camera2D") if _map_grid else get_viewport().get_camera_2d()
	if cam:
		var target_pos = _selected_room.global_position
		if _selected_room.has_method("get_tile_size"):
			var tile_size = _selected_room.get_tile_size()
			target_pos += Vector2(tile_size.x, tile_size.y) * 16.0 * 0.5 * _selected_room.global_scale
			
		var tween = get_tree().create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_parallel(true)
		tween.tween_property(cam, "global_position", target_pos, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(cam, "zoom", Vector2(4, 4), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	var modal = find_parent("StandardModal")
	if modal and modal.has_method("close"):
		modal.close()
