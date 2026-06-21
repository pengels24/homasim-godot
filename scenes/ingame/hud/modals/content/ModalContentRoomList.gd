extends MarginContainer
class_name ModalContentRoomList

@onready var room_list_container: VBoxContainer = %RoomListContainer
@onready var detail_name_lbl: Label = %DetailNameLabel
@onready var detail_status_lbl: Label = %DetailStatusLabel
@onready var detail_clean_lbl: Label = %DetailCleanLabel
@onready var detail_maint_lbl: Label = %DetailMaintLabel
@onready var btn_goto: Button = %BtnGoto

var _selected_room: Node2D = null
var _map_grid: Node2D = null
var _guest_manager: Node = null

var _btn_group: ButtonGroup
var _active_rows: Array[Dictionary] = []
var _update_timer: float = 0.0

func _ready() -> void:
	var ingame = get_tree().get_root().get_node_or_null("Ingame")
	if ingame:
		_map_grid = ingame.get("map_grid")
		_guest_manager = ingame.get("_guest_mgr")
		
	btn_goto.pressed.connect(_on_goto_pressed)
	
	_btn_group = ButtonGroup.new()
	_populate_list()
	_clear_details()

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
	
	var r_id = room.get("id") if "id" in room else "Unbekannt"
	var r_def = room.get_definition() if room.has_method("get_definition") else {}
	var r_name = r_def.get("name", GameState.T("room", "Raum"))
	
	# Name
	var lbl_name = Label.new()
	lbl_name.text = r_name
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_name.size_flags_stretch_ratio = 2.0
	lbl_name.add_theme_color_override("font_color", font_color)
	
	# ID
	var lbl_id = Label.new()
	lbl_id.text = r_id
	lbl_id.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_id.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_id.size_flags_stretch_ratio = 1.0
	lbl_id.add_theme_color_override("font_color", font_color)
	
	# Guest
	var guest_name = _get_guest_name_for_room(r_id)
	var lbl_guest = Label.new()
	lbl_guest.text = guest_name
	lbl_guest.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_guest.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_guest.size_flags_stretch_ratio = 2.0
	lbl_guest.add_theme_color_override("font_color", font_color)
	
	# Cleanliness
	var clean = room.get("cleanliness_level") if "cleanliness_level" in room else 100
	var lbl_clean = Label.new()
	lbl_clean.text = "%d%%" % clean
	lbl_clean.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_clean.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_clean.size_flags_stretch_ratio = 1.0
	_set_status_color(lbl_clean, clean)
	
	# Maintenance
	var maint = room.get("maintenance_level") if "maintenance_level" in room else 100
	var lbl_maint = Label.new()
	lbl_maint.text = "%d%%" % maint
	lbl_maint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
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

func _get_guest_name_for_room(room_id: String) -> String:
	if not _guest_manager: return "-"
	# We only care about active parties
	for party in _guest_manager.get("_active"):
		if party.get("room_id") == room_id:
			var members = party.get("members")
			if members and members.size() > 0:
				for m in members:
					if m.has_method("is_primary") and m.is_primary():
						return m.get("name")
				return members[0].get("name")
	return "-"

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
		
		var r_id = room.get("id") if "id" in room else "Unbekannt"
		row.lbl_guest.text = _get_guest_name_for_room(r_id)
		
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
		var is_service = _selected_room.get("is_service_requested") if "is_service_requested" in _selected_room else false
		
		detail_clean_lbl.text = "%s: %d%%" % [GameState.T("cleanliness", "Sauberkeit"), clean]
		detail_maint_lbl.text = "%s: %d%%" % [GameState.T("maintenance", "Zustand"), maint]
		
		if is_service:
			detail_status_lbl.text = "%s: %s" % [GameState.T("status", "Status"), GameState.T("service_needed", "Service benötigt")]
			detail_status_lbl.add_theme_color_override("font_color", Color.YELLOW)
		else:
			detail_status_lbl.text = "%s: OK" % GameState.T("status", "Status")
			detail_status_lbl.add_theme_color_override("font_color", Color.GREEN)

func _on_room_selected(room: Node2D, btn: Button) -> void:
	_selected_room = room
	
	var r_id = room.get("id") if "id" in room else GameState.T("unknown", "Unbekannt")
	var r_def = room.get_definition() if room.has_method("get_definition") else {}
	var r_name = r_def.get("name", GameState.T("room", "Raum"))
	
	detail_name_lbl.text = "%s (%s)" % [r_name, r_id]
	
	btn_goto.disabled = false
	_refresh_live_data()

func _clear_details() -> void:
	_selected_room = null
	detail_name_lbl.text = GameState.T("please_select", "Bitte wählen...")
	detail_status_lbl.text = ""
	detail_clean_lbl.text = ""
	detail_maint_lbl.text = ""
	btn_goto.disabled = true

func _on_goto_pressed() -> void:
	if not is_instance_valid(_selected_room):
		return
		
	var cam = _map_grid.get_node_or_null("Camera2D") if _map_grid else get_viewport().get_camera_2d()
	if cam:
		var target_pos = _selected_room.global_position
		if _selected_room.has_method("get_tile_size"):
			var size = _selected_room.get_tile_size()
			target_pos += Vector2(size.x, size.y) * 16.0 * 0.5 * _selected_room.global_scale
			
		var tween = get_tree().create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_parallel(true)
		tween.tween_property(cam, "global_position", target_pos, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(cam, "zoom", Vector2(4, 4), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	var modal = find_parent("StandardModal")
	if modal and modal.has_method("close"):
		modal.close()
