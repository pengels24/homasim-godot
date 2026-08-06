extends MarginContainer

signal sig_tab_changed(tab: int)

var _selected_staff = null
var _current_tab = 0 # 0 = Team, 1 = Bewerber
var _map_grid: Node2D = null

var _active_rows: Array = []
var _update_timer: float = 0.0

@onready var tab_hbox: HBoxContainer = %TabHBox
@onready var list_container: VBoxContainer = %ListContainer
@onready var empty_label: Label = %EmptyLabel

@onready var detail_panel: Control = %DetailPanel
@onready var detail_name: Label = %DetailName
@onready var detail_role: Label = %DetailRole
@onready var detail_stats: VBoxContainer = %DetailStats
@onready var detail_costs: VBoxContainer = %DetailCosts
@onready var action_btn: Button = %ActionBtn
@onready var detail_image_lbl: Label = %DetailImageLbl
@onready var image_rect: Control = %ImageRect
@onready var pip_camera: PipCamera = %PipCamera
@onready var btn_goto: Button = %BtnGoto

var SB_BLUE = preload("res://assets/UI/menu_button_blue.tres")
var SB_BLUE_HOVER = preload("res://assets/UI/menu_button_blue_hover.tres")
var SB_BLUE_PRESSED = preload("res://assets/UI/menu_button_blue_pressed.tres")

var SB_DARK = preload("res://assets/UI/menu_button_darkblue.tres")
var SB_DARK_HOVER = preload("res://assets/UI/menu_button_darkblue_hover.tres")
var SB_DARK_DISABLED = preload("res://assets/UI/menu_button_darkblue_disabled.tres")

var SB_GREEN = preload("res://assets/UI/menu_button_green.tres")
var SB_GREEN_HOVER = preload("res://assets/UI/menu_button_green_hover.tres")
var SB_GREEN_PRESSED = preload("res://assets/UI/menu_button_green_pressed.tres")

var SB_RED = preload("res://assets/UI/menu_button_red.tres")
var SB_RED_HOVER = preload("res://assets/UI/menu_button_red_hover.tres")
var SB_RED_PRESSED = preload("res://assets/UI/menu_button_red_pressed.tres")

func _style_toggle_btn(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", SB_DARK)
	btn.add_theme_stylebox_override("hover", SB_DARK_HOVER)
	btn.add_theme_stylebox_override("pressed", SB_BLUE)
	btn.add_theme_stylebox_override("focus", SB_DARK)

func _style_action_btn(btn: Button, type: String) -> void:
	if type == "green":
		btn.add_theme_stylebox_override("normal", SB_GREEN)
		btn.add_theme_stylebox_override("hover", SB_GREEN_HOVER)
		btn.add_theme_stylebox_override("pressed", SB_GREEN_PRESSED)
		btn.add_theme_stylebox_override("focus", SB_GREEN)
	elif type == "red":
		btn.add_theme_stylebox_override("normal", SB_RED)
		btn.add_theme_stylebox_override("hover", SB_RED_HOVER)
		btn.add_theme_stylebox_override("pressed", SB_RED_PRESSED)
		btn.add_theme_stylebox_override("focus", SB_RED)
	elif type == "disabled":
		btn.add_theme_stylebox_override("disabled", SB_DARK_DISABLED)

func _ready() -> void:
	var ingame = get_tree().get_root().get_node_or_null("Ingame")
	if ingame:
		_map_grid = ingame.get("map_grid")

	btn_goto.add_theme_stylebox_override("normal", SB_BLUE)
	btn_goto.add_theme_stylebox_override("hover", SB_BLUE_HOVER)
	btn_goto.add_theme_stylebox_override("pressed", SB_BLUE_PRESSED)
	btn_goto.add_theme_stylebox_override("focus", SB_BLUE)
	btn_goto.pressed.connect(_on_goto_pressed)

	_build_tabs()
	action_btn.pressed.connect(_on_action_btn_pressed)
	
	if StaffManager:
		StaffManager.sig_staff_hired.connect(_on_staff_changed)
		StaffManager.sig_staff_fired.connect(_on_staff_changed)
		StaffManager.sig_assignments_changed.connect(_on_assignments_changed)
		
	_apply_translations()
	_refresh_list()

func _apply_translations() -> void:
	btn_goto.text = GameState.T("ui.staff.goto")
	
	var header_hbox = find_child("TableHeaderPanel", true, false).get_child(0).get_child(0)
	if header_hbox:
		var lbl_name = header_hbox.get_node_or_null("LblName")
		if lbl_name: lbl_name.text = GameState.T("ui.staff.col.name")
		var lbl_role = header_hbox.get_node_or_null("LblRole")
		if lbl_role: lbl_role.text = GameState.T("ui.staff.col.role")
		var lbl_age = header_hbox.get_node_or_null("LblAge")
		if lbl_age: lbl_age.text = GameState.T("ui.staff.col.age")
		var lbl_wage = header_hbox.get_node_or_null("LblWage")
		if lbl_wage: lbl_wage.text = GameState.T("ui.staff.col.wage")
		var lbl_morale = header_hbox.get_node_or_null("LblMorale")
		if lbl_morale: lbl_morale.text = GameState.T("ui.staff.col.morale")
		var lbl_status = header_hbox.get_node_or_null("LblStatus")
		if lbl_status: lbl_status.text = GameState.T("ui.staff.col.status")

func _build_tabs() -> void:
	for c in tab_hbox.get_children():
		c.queue_free()
		
	var tabs = [
		GameState.T("ui.staff.tab_team"),
		GameState.T("ui.staff.tab_applicants"),
		GameState.T("ui.staff.tab_assign")
	]
	for i in range(tabs.size()):
		var btn = Button.new()
		btn.text = tabs[i]
		btn.custom_minimum_size = Vector2(200, 50)
		btn.toggle_mode = true
		_style_toggle_btn(btn)
		var idx = i
		btn.pressed.connect(func(): _on_tab_changed(idx))
		btn.set_meta("tab_idx", i)
		tab_hbox.add_child(btn)
		
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_hbox.add_child(spacer)
	
	var refresh_btn = Button.new()
	refresh_btn.custom_minimum_size = Vector2(250, 50)
	refresh_btn.add_theme_stylebox_override("normal", SB_BLUE)
	refresh_btn.add_theme_stylebox_override("hover", SB_BLUE_HOVER)
	refresh_btn.add_theme_stylebox_override("pressed", SB_BLUE_PRESSED)
	refresh_btn.add_theme_stylebox_override("focus", SB_BLUE)
	refresh_btn.pressed.connect(_on_refresh_applicants_pressed)
	refresh_btn.set_meta("is_refresh_btn", true)
	tab_hbox.add_child(refresh_btn)
		
	_update_tab_buttons()

func _update_tab_buttons() -> void:
	for btn in tab_hbox.get_children():
		if btn.has_meta("tab_idx"):
			var idx = btn.get_meta("tab_idx")
			btn.button_pressed = (idx == _current_tab)
			if idx == 0:
				var max_cap = StaffManager.get_max_staff_capacity() if StaffManager.has_method("get_max_staff_capacity") else 10
				var hired_count = StaffManager.hired_staff.size() if StaffManager else 0
				btn.text = GameState.T("ui.staff.tab_team") + " (%d/%d)" % [hired_count, max_cap]
		elif btn.has_meta("is_refresh_btn"):
			btn.visible = (_current_tab == 1)
			var max_ref = StaffManager.MAX_DAILY_REFRESHES
			var cur_ref = StaffManager.get_daily_refreshes()
			btn.text = GameState.T("ui.staff.refresh_applicants") + " (%d/%d)" % [cur_ref, max_ref]
			btn.disabled = (cur_ref >= max_ref)
			
			if btn.disabled:
				btn.modulate = Color(1, 1, 1, 0.5)
			else:
				btn.modulate = Color.WHITE

func _on_refresh_applicants_pressed() -> void:
	if StaffManager.refresh_applicants():
		_update_tab_buttons()
		_refresh_list()

func _on_tab_changed(tab: int) -> void:
	_current_tab = tab
	_selected_staff = null
	_update_tab_buttons()
	_refresh_list()
	sig_tab_changed.emit(tab)

func _on_staff_changed(_dummy = null) -> void:
	_selected_staff = null
	_refresh_list()

func _on_assignments_changed() -> void:
	if _current_tab == 2:
		_refresh_list()

func _refresh_list() -> void:
	_active_rows.clear()
	for child in list_container.get_children():
		if child != empty_label:
			child.queue_free()
		
	var th = find_child("TableHeaderPanel", true, false)
	if th:
		th.visible = (_current_tab != 2)
		
	var lbl_status_header = get_node_or_null("%LblStatus")
	if lbl_status_header:
		lbl_status_header.visible = (_current_tab == 0)
		
	if detail_panel:
		detail_panel.visible = (_current_tab != 2)
		
	if _current_tab == 2:
		empty_label.visible = false
		_build_assignment_ui()
		return
		
	var items = []
	if _current_tab == 0:
		if StaffManager:
			items = StaffManager.get_state().get("hired", {}).values()
	else:
		if StaffManager:
			items = StaffManager.daily_applicants
			
	var sb_selected = StyleBoxFlat.new()
	sb_selected.bg_color = Color(0.5, 0.35, 0.05, 0.8) # Dunkles Gold
	sb_selected.set_corner_radius_all(4)
	
	var sb_hover = StyleBoxFlat.new()
	sb_hover.bg_color = Color(1, 1, 1, 0.1) # Leichtes Grau/Highlight
	sb_hover.set_corner_radius_all(4)
	
	var sb_empty = StyleBoxEmpty.new()
	
	if items.is_empty():
		empty_label.visible = true
		if _current_tab == 0:
			empty_label.text = GameState.T("ui.staff.no_team")
		else:
			empty_label.text = GameState.T("ui.staff.no_applicants")
	else:
		empty_label.visible = false
		var first_new_btn = null
		var btn_group = ButtonGroup.new()
		
		for item in items:
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(0, 44)
			btn.toggle_mode = true
			btn.button_group = btn_group
			
			# Setup initial styles
			btn.add_theme_stylebox_override("normal", sb_empty)
			btn.add_theme_stylebox_override("hover", sb_hover)
			btn.add_theme_stylebox_override("pressed", sb_selected)
			btn.add_theme_stylebox_override("focus", sb_empty)
			
			var hbox = HBoxContainer.new()
			hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
			
			var margin = MarginContainer.new()
			margin.set_anchors_preset(Control.PRESET_FULL_RECT)
			margin.add_theme_constant_override("margin_left", 16)
			margin.add_theme_constant_override("margin_right", 16)
			margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			var hbox_inner = HBoxContainer.new()
			hbox_inner.add_theme_constant_override("separation", 10)
			margin.add_child(hbox_inner)
			
			var list_font_color = Color("#CCCCCC")
			if _current_tab == 1 and not _get_available_poi_roles().has(item.get("role", "")):
				list_font_color = Color("#555555")
				btn.disabled = true
				btn.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
				btn.tooltip_text = GameState.T("ui.staff.role_not_needed", "POI noch nicht gebaut")

			# Name (Stretch 3.5)
			var lbl_name = Label.new()
			lbl_name.text = item.get("first_name", "") + " " + item.get("last_name", "")
			if _current_tab == 0 and item.get("training_state", "none") == "in_training":
				lbl_name.text += " [📖]"
				list_font_color = Color(1.0, 0.8, 0.2)
				btn.disabled = true
				btn.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
				btn.tooltip_text = GameState.T("ui.staff.assign.training_locked", "In Schulung (Gesperrt)")
			
			lbl_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl_name.size_flags_stretch_ratio = 3.5
			lbl_name.clip_text = true
			lbl_name.add_theme_color_override("font_color", list_font_color)
			
			# Rolle (Stretch 2.5)
			var lbl_role = Label.new()
			lbl_role.text = GameState.T("staff.role." + item.get("role", ""))
			lbl_role.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl_role.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl_role.size_flags_stretch_ratio = 2.5
			lbl_role.add_theme_color_override("font_color", list_font_color)
			
			# Alter (Stretch 1.0)
			var lbl_age = Label.new()
			lbl_age.text = str(item.get("age", 30))
			lbl_age.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl_age.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl_age.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl_age.size_flags_stretch_ratio = 1.0
			lbl_age.add_theme_color_override("font_color", list_font_color)
			
			# Gehalt (Stretch 1.5)
			var lbl_wage = Label.new()
			lbl_wage.text = "%d €" % int(item.get("daily_wage", 80))
			lbl_wage.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl_wage.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			lbl_wage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl_wage.size_flags_stretch_ratio = 1.5
			lbl_wage.add_theme_color_override("font_color", list_font_color)
			
			# Moral (Stretch 1.5)
			var lbl_morale = Label.new()
			lbl_morale.text = str(item.get("morale", 100)) + "%"
			lbl_morale.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl_morale.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			lbl_morale.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl_morale.size_flags_stretch_ratio = 1.5
			if item.get("morale", 100) < 50:
				lbl_morale.add_theme_color_override("font_color", Color("#b02e3b"))
			elif item.get("morale", 100) > 80:
				lbl_morale.add_theme_color_override("font_color", Color("#366e4d"))
			else:
				lbl_morale.add_theme_color_override("font_color", list_font_color)
			# Status (Stretch 2.0)
			var lbl_status = Label.new()
			lbl_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			lbl_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl_status.size_flags_stretch_ratio = 2.0
			
			if _current_tab == 0:
				var role = item.get("role", "")
				var assigned = StaffManager.room_assignments.get(item.get("id", ""), "")
				var is_roaming = (role == "housekeeping" or role == "maintenance")
				
				var t_state = item.get("training_state", "none")
				if t_state == "in_training":
					lbl_status.text = GameState.T("ui.staff.status.in_training", "In Schulung")
					lbl_status.add_theme_color_override("font_color", Color.CYAN)
				elif t_state == "scheduled":
					lbl_status.text = GameState.T("ui.staff.status.scheduled", "Schulung geplant")
					lbl_status.add_theme_color_override("font_color", Color.YELLOW)
				elif not is_roaming:
					if assigned == "":
						lbl_status.text = GameState.T("ui.staff.status.unassigned", "Ohne Aufgabe")
						lbl_status.add_theme_color_override("font_color", Color.GRAY)
					else:
						lbl_status.text = GameState.T("ui.staff.status.assigned", "Zugeordnet")
						lbl_status.add_theme_color_override("font_color", Color.GREEN)
				else:
					if item.get("busy", false):
						lbl_status.text = GameState.T("ui.staff.status.busy", "Im Einsatz")
						lbl_status.add_theme_color_override("font_color", Color.ORANGE)
					else:
						lbl_status.text = GameState.T("ui.staff.status.waiting", "Wartend")
						lbl_status.add_theme_color_override("font_color", Color.GRAY)
			else:
				lbl_status.visible = false
			
			hbox_inner.add_child(lbl_name)
			hbox_inner.add_child(lbl_role)
			hbox_inner.add_child(lbl_age)
			hbox_inner.add_child(lbl_wage)
			hbox_inner.add_child(lbl_morale)
			hbox_inner.add_child(lbl_status)
			
			btn.add_child(margin)
			btn.pressed.connect(func(): _select_item(item))
			btn.focus_entered.connect(func(): 
				btn.button_pressed = true
				_select_item(item)
			)
			list_container.add_child(btn)
			
			_active_rows.append({
				"item": item,
				"lbl_morale": lbl_morale
			})
			
			if first_new_btn == null:
				first_new_btn = btn
				
		if first_new_btn != null:
			first_new_btn.call_deferred("grab_focus")
			
	_update_details()

func _create_2col_row(label_text: String, value_text: String, parent: Node, is_big: bool = false) -> void:
	var hbox = HBoxContainer.new()
	
	var lbl_left = Label.new()
	lbl_left.text = label_text
	if is_big:
		lbl_left.theme_type_variation = &"HeaderMedium"
	else:
		lbl_left.theme_type_variation = &"DescLabel"
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var lbl_right = Label.new()
	lbl_right.text = value_text
	lbl_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if is_big:
		lbl_right.theme_type_variation = &"HeaderMedium"
	else:
		lbl_right.theme_type_variation = &"ValueLabel"
	
	hbox.add_child(lbl_left)
	hbox.add_child(spacer)
	hbox.add_child(lbl_right)
	parent.add_child(hbox)

func _create_progress_row(label_text: String, current_val: float, max_val: float, is_percent: bool, parent: Node) -> void:
	var hbox = HBoxContainer.new()
	
	var lbl_left = Label.new()
	lbl_left.text = label_text
	lbl_left.theme_type_variation = &"DescLabel"
	lbl_left.custom_minimum_size = Vector2(160, 0)
	
	var progress = ProgressBar.new()
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	progress.min_value = 0
	progress.max_value = max_val
	progress.value = current_val
	progress.custom_minimum_size = Vector2(0, 8)
	progress.show_percentage = false
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.1, 0.1, 0.1, 0.5)
	sb_bg.corner_radius_top_left = 4
	sb_bg.corner_radius_top_right = 4
	sb_bg.corner_radius_bottom_right = 4
	sb_bg.corner_radius_bottom_left = 4
	progress.add_theme_stylebox_override("background", sb_bg)
	
	var sb_fg = StyleBoxFlat.new()
	sb_fg.bg_color = Color("#EAB308")
	if is_percent and current_val < 50:
		sb_fg.bg_color = Color("#b02e3b")
	elif is_percent and current_val > 80:
		sb_fg.bg_color = Color("#366e4d")
	sb_fg.corner_radius_top_left = 4
	sb_fg.corner_radius_top_right = 4
	sb_fg.corner_radius_bottom_right = 4
	sb_fg.corner_radius_bottom_left = 4
	progress.add_theme_stylebox_override("fill", sb_fg)
	
	var lbl_right = Label.new()
	if is_percent:
		lbl_right.text = str(int(current_val)) + "%"
	else:
		lbl_right.text = str(int(current_val))
	lbl_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_right.theme_type_variation = &"ValueLabel"
	lbl_right.custom_minimum_size = Vector2(40, 0)
	
	hbox.add_child(lbl_left)
	hbox.add_child(progress)
	hbox.add_child(lbl_right)
	parent.add_child(hbox)

func _select_item(item: Dictionary) -> void:
	var scroll_node = find_child("ScrollContainer", true, false)
	var scroll_v = 0
	if scroll_node:
		scroll_v = scroll_node.scroll_vertical
		
	_selected_staff = item
	_update_details()
	
	if scroll_node:
		# call_deferred or setting it directly might not be enough if layout takes a frame
		# A reliable way in Godot 4 is to set it deferred
		scroll_node.call_deferred("set", "scroll_vertical", scroll_v)
		# Just to be absolutely sure, also set it next frame
		get_tree().process_frame.connect(func(): if is_instance_valid(scroll_node): scroll_node.scroll_vertical = scroll_v, CONNECT_ONE_SHOT)

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
		
	_update_timer -= delta
	if _update_timer <= 0.0:
		_update_timer = 1.0
		_refresh_live_data()

func _refresh_live_data() -> void:
	var list_font_color = Color("#CCCCCC")
	for row in _active_rows:
		var item = row["item"]
		var lbl_morale = row["lbl_morale"]
		
		if not is_instance_valid(lbl_morale): continue
		
		var m = item.get("morale", 100)
		lbl_morale.text = "%d%%" % m
		if m < 50:
			lbl_morale.add_theme_color_override("font_color", Color("#b02e3b"))
		elif m > 80:
			lbl_morale.add_theme_color_override("font_color", Color("#366e4d"))
		else:
			lbl_morale.add_theme_color_override("font_color", list_font_color)
			
	# (Auskommentiert, da ständiges Löschen/Neubauen der Details den Layout-Container zucken lässt 
	# und den ScrollContainer der Liste zurücksetzt)
	# if _selected_staff != null:
	# 	_update_details()

func _update_details() -> void:
	for child in detail_stats.get_children():
		child.queue_free()
	for child in detail_costs.get_children():
		child.queue_free()
		
	if _selected_staff == null:
		detail_name.text = ""
		detail_role.text = GameState.T("ui.staff.select_prompt")
		action_btn.visible = false
		btn_goto.visible = false
		image_rect.visible = false
		pip_camera.visible = false
		pip_camera.set_target(null)
		return
		
	var s = _selected_staff
	detail_name.text = s.get("first_name", "") + " " + s.get("last_name", "")
	detail_role.text = GameState.T("ui.staff.job") + GameState.T("staff.role." + s.get("role", ""))
	action_btn.visible = true
	
	var job = s.get("role", "housekeeping")
	var gender = s.get("gender", "female")
	detail_image_lbl.text = ""
	
	var tex_rect = detail_image_lbl.get_node_or_null("AvatarRect")
	if not tex_rect:
		tex_rect = TextureRect.new()
		tex_rect.name = "AvatarRect"
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.custom_minimum_size = Vector2(128, 128)
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		detail_image_lbl.add_child(tex_rect)
		
	var texture_path = "res://assets/staff/staff_avatar_%s_%s.aseprite" % [gender, job]
	if ResourceLoader.exists(texture_path):
		tex_rect.texture = load(texture_path)
	else:
		tex_rect.texture = null
		if job == "maintenance":
			detail_image_lbl.text = "👩‍🔧" if gender == "female" else "👨‍🔧"
		elif job == "housekeeping":
			detail_image_lbl.text = "👩‍🍳" if gender == "female" else "👨‍🍳"
		else:
			detail_image_lbl.text = "👩‍💼" if gender == "female" else "👨‍💼"
	
	if _current_tab == 0:
		image_rect.visible = false
		pip_camera.visible = true
		btn_goto.visible = true
		var s_actor = _map_grid.get_node_or_null("StaffActor_" + str(s.get("id", ""))) if _map_grid else null
		pip_camera.set_target(s_actor)
		btn_goto.disabled = (s_actor == null)
		
		_create_2col_row(GameState.T("ui.staff.daily_wage"), "%d €" % int(s.get("daily_wage", 0)), detail_costs, false)
		action_btn.text = GameState.T("ui.staff.fire")
		action_btn.remove_theme_color_override("font_color")
		_style_action_btn(action_btn, "red")
		
		var t_state = s.get("training_state", "none")
		
		if t_state == "in_training":
			action_btn.disabled = true
			btn_goto.disabled = true
		else:
			action_btn.disabled = false
		
		var bonus_btn = Button.new()
		bonus_btn.custom_minimum_size = Vector2(0, 44)
		bonus_btn.text = GameState.T("ui.staff.pay_bonus", "Bonus zahlen (100 €)")
		bonus_btn.add_theme_stylebox_override("normal", SB_DARK)
		bonus_btn.add_theme_stylebox_override("hover", SB_DARK_HOVER)
		bonus_btn.add_theme_stylebox_override("pressed", SB_DARK_HOVER)
		bonus_btn.add_theme_stylebox_override("disabled", SB_DARK)
		bonus_btn.pressed.connect(func():
			if StaffManager and StaffManager.pay_bonus(s.get("id", "")):
				_refresh_live_data()
				_update_details() # Refresh the disabled state
		)
		if s.get("morale", 100) >= 100 or t_state != "none":
			bonus_btn.disabled = true
			bonus_btn.modulate = Color(1, 1, 1, 0.5)
		detail_costs.add_child(bonus_btn)
		
		# Training Button
		var train_btn = Button.new()
		train_btn.custom_minimum_size = Vector2(0, 44)
		var train_cost = 400
		train_btn.text = GameState.T("ui.staff.train_staff", "Schulen (%d €)") % train_cost
		train_btn.add_theme_stylebox_override("normal", SB_DARK)
		train_btn.add_theme_stylebox_override("hover", SB_DARK_HOVER)
		train_btn.add_theme_stylebox_override("pressed", SB_DARK_HOVER)
		train_btn.add_theme_stylebox_override("disabled", SB_DARK)
		train_btn.pressed.connect(func():
			_pending_action = 6
			_pending_train_cost = train_cost
			var staff_name = s.get("first_name", "") + " " + s.get("last_name", "")
			var modal = _get_confirm_modal()
			modal.ask(
				GameState.T("ui.staff.confirm.train.title", "Mitarbeiter schulen?"),
				GameState.T("ui.staff.confirm.train.desc", "Möchtest du [%s] für %d € auf Schulung schicken? Der Mitarbeiter fällt am Folgetag aus.") % [staff_name, train_cost],
				GameState.T("ui.staff.confirm.btn.train", "Schulen"),
				GameState.T("ui.staff.confirm.btn.cancel", "Abbrechen"),
				"",
				false
			)
		)
		
		if not TechtreeManager.is_tech_unlocked("M1.2"):
			train_btn.disabled = true
			train_btn.modulate = Color(1, 1, 1, 0.5)
			train_btn.tooltip_text = GameState.T("ui.staff.train_locked", "Benötigt Forschung M1.2 (Personalentwicklung)")
		elif s.get("skills", {}).get(job, 0) >= 10:
			train_btn.disabled = true
			train_btn.modulate = Color(1, 1, 1, 0.5)
			train_btn.tooltip_text = GameState.T("ui.staff.train_max", "Maximales Level erreicht")
		elif GameState.selected_hotel.get("money", 0) < train_cost:
			train_btn.disabled = true
			train_btn.modulate = Color(1, 1, 1, 0.5)
		elif t_state != "none":
			train_btn.disabled = true
			train_btn.modulate = Color(1, 1, 1, 0.5)
			if t_state == "in_training":
				train_btn.text = GameState.T("ui.staff.status.in_training", "In Schulung")
			elif t_state == "scheduled":
				train_btn.text = GameState.T("ui.staff.status.scheduled", "Schulung geplant")
		
		detail_costs.add_child(train_btn)
	else:
		image_rect.visible = true
		pip_camera.visible = false
		btn_goto.visible = false
		pip_camera.set_target(null)
		
		_create_2col_row(GameState.T("ui.staff.hire_cost"), "%d €" % int(s.get("hire_cost", 0)), detail_costs, false)
		_create_2col_row(GameState.T("ui.staff.daily_wage"), "%d €" % int(s.get("daily_wage", 0)), detail_costs, false)
		if _get_available_poi_roles().has(job):
			var max_cap = StaffManager.get_max_staff_capacity() if StaffManager.has_method("get_max_staff_capacity") else 10
			var cur_cap = StaffManager.hired_staff.size() if StaffManager else 0
			var is_training = (s.get("training_state", "none") != "none")
			if is_training:
				action_btn.text = GameState.T("ui.staff.assign.training_locked")
				action_btn.disabled = true
				action_btn.modulate = Color(1, 1, 1, 1.0)
				_style_action_btn(action_btn, "disabled")
			elif cur_cap >= max_cap:
				action_btn.text = GameState.T("toast.staff.limit_reached") % max_cap
				action_btn.disabled = true
				action_btn.modulate = Color(1, 1, 1, 1.0)
				_style_action_btn(action_btn, "disabled")
			else:
				action_btn.text = GameState.T("ui.staff.hire")
				action_btn.disabled = false
				action_btn.remove_theme_color_override("font_color")
				_style_action_btn(action_btn, "green")
				action_btn.tooltip_text = ""
		else:
			action_btn.text = "Kein Arbeitsplatz"
			action_btn.disabled = true
			action_btn.modulate = Color(1, 1, 1, 1.0)
			_style_action_btn(action_btn, "disabled")
			action_btn.tooltip_text = "Dieser Beruf benötigt einen entsprechenden Arbeitsplatz (POI), der noch nicht gebaut wurde."
		
	var age_str = str(s.get("age", 30)) + " " + GameState.T("ui.staff.years", "Jahre")
	_create_2col_row(GameState.T("ui.staff.age", "Alter"), age_str, detail_stats, false)
	
	if _current_tab == 0:
		var hired_day = s.get("hired_day", TimeManager.get_day())
		var tenure = max(0, TimeManager.get_day() - hired_day)
		var tenure_str = str(tenure) + " " + GameState.T("ui.staff.days", "Tag(e)")
		_create_2col_row(GameState.T("ui.staff.tenure", "Zugehörigkeit"), tenure_str, detail_stats, false)
		
	var skills = s.get("skills", {})
	for skill_name in skills.keys():
		var translated_skill = GameState.T("staff.skill." + skill_name)
		if translated_skill == "staff.skill." + skill_name:
			translated_skill = skill_name.capitalize().replace("_", " ")
		_create_progress_row(translated_skill, float(skills[skill_name]), 10.0, false, detail_stats)
		
	if s.has("morale"):
		_create_progress_row(GameState.T("ui.staff.morale"), float(s.get("morale", 100)), 100.0, true, detail_stats)

var _pending_action: int = 0 # 0=none, 1=hire, 2=fire, 3=unassign, 4=assign_only, 5=hire_and_assign, 6=train
var _pending_train_cost: int = 0
var _pending_unassign_sid: String = ""
var _pending_assign_sid: String = ""
var _pending_assign_rid: String = ""
var _confirm_modal: Node = null
var _list_modal: Node = null

func _get_list_modal() -> Node:
	if not is_instance_valid(_list_modal):
		_list_modal = preload("res://scenes/shared/ListModal.tscn").instantiate()
		add_child(_list_modal)
	for conn in _list_modal.item_selected.get_connections():
		_list_modal.item_selected.disconnect(conn.callable)
	return _list_modal
func _get_confirm_modal() -> Node:
	if not is_instance_valid(_confirm_modal):
		_confirm_modal = preload("res://scenes/shared/ConfirmModal.tscn").instantiate()
		add_child(_confirm_modal)
		_confirm_modal.confirmed.connect(_on_confirm_accepted)
	return _confirm_modal

func _on_action_btn_pressed() -> void:
	if _selected_staff == null:
		return
		
	var s = _selected_staff
	var staff_name = s.get("first_name", "") + " " + s.get("last_name", "")
	var modal = _get_confirm_modal()
		
	if _current_tab == 0:
		_pending_action = 2
		modal.ask(
			GameState.T("ui.staff.confirm.fire.title"),
			GameState.T("ui.staff.confirm.fire.desc") % staff_name,
			GameState.T("ui.staff.confirm.btn.fire"),
			GameState.T("ui.staff.confirm.btn.cancel"),
			"",
			true # Destructive (Red button)
		)
	else:
		var role = s.get("role", "")
		if role != "housekeeping" and role != "maintenance":
			_show_hire_and_assign_popup(s)
			return
			
		_pending_action = 1
		modal.ask(
			GameState.T("ui.staff.confirm.hire.title"),
			GameState.T("ui.staff.confirm.hire.desc").replace("â¬", "€").replace("Ã¢â‚¬Â¬", "€") % [staff_name, s.get("hire_cost", 0)],
			GameState.T("ui.staff.confirm.btn.hire"),
			GameState.T("ui.staff.confirm.btn.cancel"),
			"",
			false # Green button
		)

func _on_unassign_requested(sid: String) -> void:
	_pending_unassign_sid = sid
	_pending_action = 3
	var staff_data = StaffManager.hired_staff.get(sid, {})
	var staff_name = staff_data.get("first_name", "") + " " + staff_data.get("last_name", "")
	var modal = _get_confirm_modal()
	modal.ask(
		GameState.T("ui.staff.confirm.unassign.title"),
		GameState.T("ui.staff.confirm.unassign.desc") % staff_name,
		GameState.T("ui.staff.confirm.btn.unassign"),
		GameState.T("ui.staff.confirm.btn.cancel"),
		"",
		true # Destructive (Red button)
	)

func _on_confirm_accepted() -> void:
	if _pending_action == 3:
		if StaffManager:
			StaffManager.unassign_from_room(_pending_unassign_sid)
			_pending_unassign_sid = ""
			_refresh_list()
		_pending_action = 0
		return
		
	if _selected_staff == null:
		return
		
	if _pending_action == 2:
		if StaffManager:
			StaffManager.fire_staff(_selected_staff["id"])
	elif _pending_action == 1:
		if StaffManager:
			StaffManager.hire_staff(_selected_staff["id"])
	elif _pending_action == 4:
		if StaffManager:
			StaffManager.assign_to_room(_pending_assign_sid, _pending_assign_rid)
			_refresh_list()
	elif _pending_action == 5:
		if StaffManager:
			if StaffManager.hire_staff(_pending_assign_sid):
				StaffManager.assign_to_room(_pending_assign_sid, _pending_assign_rid)
				_refresh_list()
	elif _pending_action == 6:
		if StaffManager:
			if StaffManager.train_staff(_selected_staff["id"], _pending_train_cost):
				_refresh_live_data()
				_update_details()
				_refresh_list()
			
	_pending_action = 0

func _on_goto_pressed() -> void:
	if not _selected_staff or _current_tab != 0: return
	var s_actor = _map_grid.get_node_or_null("StaffActor_" + str(_selected_staff.get("id", ""))) if _map_grid else null
	if is_instance_valid(s_actor):
		var cam = _map_grid.get_node_or_null("Camera2D") if _map_grid else get_viewport().get_camera_2d()
		if cam:
			var target_pos = s_actor.global_position
			var tween = get_tree().create_tween()
			tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tween.set_parallel(true)
			tween.tween_property(cam, "global_position", target_pos, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(cam, "zoom", Vector2(4, 4), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		var modal = find_parent("StandardModal")
		if modal and modal.has_method("close"):
			modal.close()


# =============================================================================
# TAB 3 – ZUWEISUNG
# =============================================================================

func _build_assignment_ui() -> void:
	var vbox = VBoxContainer.new()
	vbox.name = "AssignmentVBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 16)
	list_container.add_child(vbox)
	
	var info_lbl = Label.new()
	info_lbl.text = "\n" + GameState.T("ui.staff.auto_assign_desc", "Das Personal sucht sich selbstständig freie Arbeitsplätze (z.B. sucht ein Barkeeper automatisch nach einer Bar).\nKlicke bei einem Raum auf 'Freistellen', um einen Mitarbeiter von diesem Raum zu lösen. Er sucht sich dann automatisch einen neuen, unbesetzten Arbeitsplatz.")
	info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_lbl.add_theme_color_override("font_color", Color("#AAAAAA"))
	vbox.add_child(info_lbl)
	
	var sep_top = HSeparator.new()
	vbox.add_child(sep_top)
	
	var panel = PanelContainer.new()
	panel.theme_type_variation = "InnerPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(inner_vbox)

	var header = Label.new()
	header.text = GameState.T("ui.staff.assign_poi", "POI-Räume")
	header.theme_type_variation = "HeaderMedium"
	inner_vbox.add_child(header)

	var sep_inner = HSeparator.new()
	inner_vbox.add_child(sep_inner)

	# POI-Räume aus MapGrid holen
	var poi_rooms: Array = []
	if is_instance_valid(_map_grid) and _map_grid.has_method("get_placed_rooms"):
		for room in _map_grid.get_placed_rooms():
			if not is_instance_valid(room): continue
			var def = room.call("get_definition")
			if def.get("is_poi", false) and def.get("in_build_menu", true):
				poi_rooms.append(room)

	if poi_rooms.is_empty():
		var no_poi_lbl = Label.new()
		no_poi_lbl.text = GameState.T("ui.staff.no_pois", "Keine POI-Räume gebaut.")
		no_poi_lbl.add_theme_color_override("font_color", Color("#888888"))
		inner_vbox.add_child(no_poi_lbl)
	else:
		const CARD_ROOM = preload("res://scenes/ingame/hud/modals/content/cards/CardAssignRoom.tscn")
		for room in poi_rooms:
			var def = room.call("get_definition")
			var room_id = GuestManager._room_key(room)
			var min_s: int = def.get("min_staff", 1)
			var max_s: int = def.get("max_staff", 1)
			
			var label_text: String = GameState.T(def.get("name", ""))
			if label_text == "" or label_text == def.get("name", ""):
				label_text = def.get("label", "Raum")
			var prefix: String = def.get("prefix", "")
			var r_num: String = room.room_number if "room_number" in room else "????"
			var display_id: String = prefix + r_num if prefix != "" and not r_num.begins_with(prefix) else r_num
			var formatted_name = label_text + " [" + display_id + "]"
			
			var assigned: Array = StaffManager.get_staff_for_room(room_id)
			var req_role = def.get("required_role", "")
			if req_role != "":
				assigned.sort_custom(func(a, b):
					var a_main = (a.get("role", "") == req_role)
					var b_main = (b.get("role", "") == req_role)
					if a_main and not b_main: return true
					if not a_main and b_main: return false
					return false
				)

			var card = CARD_ROOM.instantiate()
			inner_vbox.add_child(card)
			card.populate(formatted_name, room_id, min_s, max_s, assigned, def)
			card.sig_unassign_staff.connect(_on_unassign_requested)
			card.sig_empty_slot_clicked.connect(_on_empty_slot_clicked)

func _on_empty_slot_clicked(room_id: String, allowed_roles: Array) -> void:
	var unassigned_candidates = []
	if StaffManager:
		for staff_id in StaffManager.hired_staff:
			if not StaffManager.room_assignments.has(staff_id):
				var r = StaffManager.hired_staff[staff_id].get("role", "")
				if allowed_roles.has(r):
					unassigned_candidates.append(StaffManager.hired_staff[staff_id])
					
	var modal = _get_list_modal()
	if unassigned_candidates.is_empty():
		modal.ask_list("Personal Zuweisen", "Kein passendes Personal verfügbar.", [])
	else:
		var items = []
		for c in unassigned_candidates:
			var txt = "%s %s (%s)" % [c.get("first_name", ""), c.get("last_name", ""), GameState.T("staff.role." + c.get("role", ""))]
			items.append({"id": c.get("id", ""), "text": txt, "data": c})
			
		modal.ask_list("Personal Zuweisen", "Wähle einen Mitarbeiter aus, der diesem Raum zugewiesen werden soll:", items)
		modal.item_selected.connect(func(s_id: String):
			if StaffManager:
				StaffManager.assign_to_room(s_id, room_id)
				_refresh_list()
		)

func _show_hire_and_assign_popup(staff: Dictionary) -> void:
	var role = staff.get("role", "")
	var valid_rooms = []
	if is_instance_valid(_map_grid) and _map_grid.has_method("get_placed_rooms"):
		for room in _map_grid.get_placed_rooms():
			if not is_instance_valid(room): continue
			if not room.has_method("get_definition"): continue
			var def = room.call("get_definition")
			if not def.get("is_poi", false): continue
			
			var req = def.get("required_role", "")
			var allowed = def.get("allowed_roles", [req] if req != "" else [])
			if not allowed.has(role): continue
			
			var room_id = GuestManager._room_key(room)
			var assigned = StaffManager.get_staff_for_room(room_id).size()
			if assigned < def.get("max_staff", 1):
				var prefix = def.get("prefix", "")
				var rnum = room.room_number if "room_number" in room else "????"
				var display_id = prefix + rnum if prefix != "" and not rnum.begins_with(prefix) else rnum
				var rname = GameState.T(def.get("name", ""))
				valid_rooms.append({"id": room_id, "text": "%s [%s]" % [rname, display_id]})
				
	var modal = _get_list_modal()
	if valid_rooms.is_empty():
		modal.ask_list("Arbeitsplatz Wählen", "Kein Raum mit freiem Slot für diesen Beruf vorhanden.", [])
	else:
		modal.ask_list("Arbeitsplatz Wählen", "Wähle den Raum, in dem %s %s arbeiten soll:" % [staff.get("first_name", ""), staff.get("last_name", "")], valid_rooms)
		modal.item_selected.connect(func(r_id: String):
			var staff_name = staff.get("first_name", "") + " " + staff.get("last_name", "")
			var c_modal = _get_confirm_modal()
			_pending_action = 5
			_pending_assign_sid = staff.get("id", "")
			_pending_assign_rid = r_id
			
			c_modal.ask(
				GameState.T("ui.staff.confirm.hire.title"),
				GameState.T("ui.staff.confirm.hire.desc").replace("â¬", "€").replace("Ã¢â‚¬Â¬", "€") % [staff_name, staff.get("hire_cost", 0)],
				GameState.T("ui.staff.confirm.btn.hire", "Einstellen"),
				GameState.T("ui.staff.confirm.btn.cancel", "Abbrechen"),
				"",
				false
			)
		)

func _get_available_poi_roles() -> Array:
	var roles = ["housekeeping", "maintenance"] # Immer erlaubt
	if not is_instance_valid(_map_grid):
		return roles
	var poi_rooms = []
	if _map_grid.has_method("get_placed_rooms"):
		var rooms = _map_grid.get_placed_rooms()
		for r in rooms:
			if r.get("room_type_id") != "corridor":
				poi_rooms.append(r)
	for room in poi_rooms:
		if room.has_method("get_definition"):
			var def = room.call("get_definition")
			var r_role = def.get("required_role", "")
			var allowed = def.get("allowed_roles", [r_role] if r_role != "" else [])
			for role in allowed:
				if role != "" and not roles.has(role):
					roles.append(role)
	return roles

