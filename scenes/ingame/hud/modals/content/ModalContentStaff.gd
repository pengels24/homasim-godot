extends MarginContainer

var _selected_staff = null
var _current_tab = 0 # 0 = Team, 1 = Bewerber
var _map_grid: Node2D = null

var _active_rows: Array[Dictionary] = []
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
		
	_refresh_list()

func _build_tabs() -> void:
	for c in tab_hbox.get_children():
		c.queue_free()
		
	var tabs = ["Dein Team", "Bewerber"]
	for i in range(tabs.size()):
		var btn = Button.new()
		btn.text = tabs[i]
		btn.custom_minimum_size = Vector2(200, 50)
		btn.toggle_mode = true
		_style_toggle_btn(btn)
		btn.pressed.connect(func(): _on_tab_changed(i))
		btn.set_meta("tab_idx", i)
		tab_hbox.add_child(btn)
		
	_update_tab_buttons()

func _update_tab_buttons() -> void:
	for btn in tab_hbox.get_children():
		btn.button_pressed = (btn.get_meta("tab_idx") == _current_tab)

func _on_tab_changed(tab: int) -> void:
	_current_tab = tab
	_selected_staff = null
	_update_tab_buttons()
	_refresh_list()

func _on_staff_changed(_dummy = null) -> void:
	_selected_staff = null
	_refresh_list()

func _refresh_list() -> void:
	_active_rows.clear()
	for child in list_container.get_children():
		if child != empty_label:
			child.queue_free()
		
	var items = []
	if _current_tab == 0:
		if StaffManager:
			items = StaffManager.get_state().values()
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
			empty_label.text = GameState.T("ui.staff.no_team", "Du hast noch kein Personal eingestellt.")
		else:
			empty_label.text = GameState.T("ui.staff.no_applicants", "Keine Bewerber heute.")
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
			
			# Name (Stretch 3.5)
			var lbl_name = Label.new()
			lbl_name.text = item.get("first_name", "") + " " + item.get("last_name", "")
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
				lbl_morale.add_theme_color_override("font_color", Color.RED)
			elif item.get("morale", 100) > 80:
				lbl_morale.add_theme_color_override("font_color", Color.GREEN)
			else:
				lbl_morale.add_theme_color_override("font_color", list_font_color)
			
			hbox_inner.add_child(lbl_name)
			hbox_inner.add_child(lbl_role)
			hbox_inner.add_child(lbl_age)
			hbox_inner.add_child(lbl_wage)
			hbox_inner.add_child(lbl_morale)
			
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

func _select_item(item: Dictionary) -> void:
	_selected_staff = item
	_update_details()

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
			lbl_morale.add_theme_color_override("font_color", Color.RED)
		elif m > 80:
			lbl_morale.add_theme_color_override("font_color", Color.GREEN)
		else:
			lbl_morale.add_theme_color_override("font_color", list_font_color)
			
	if _selected_staff != null:
		# Minimal update of detail panel if needed. We update it by recreating to keep it simple, 
		# since F4 doesn't have complex focus state inside detail_stats.
		_update_details()

func _update_details() -> void:
	for child in detail_stats.get_children():
		child.queue_free()
	for child in detail_costs.get_children():
		child.queue_free()
		
	if _selected_staff == null:
		detail_name.text = ""
		detail_role.text = GameState.T("ui.staff.select_prompt", "Bitte wähle einen Mitarbeiter aus")
		action_btn.visible = false
		btn_goto.visible = false
		image_rect.visible = false
		pip_camera.visible = false
		pip_camera.set_target(null)
		return
		
	var s = _selected_staff
	detail_name.text = s.get("first_name", "") + " " + s.get("last_name", "") + " (" + str(s.get("age", 30)) + " J.)"
	detail_role.text = GameState.T("ui.staff.job", "Beruf: ") + GameState.T("staff.role." + s.get("role", ""))
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
		
		_create_2col_row(GameState.T("ui.staff.daily_wage", "Tagesgehalt"), "%d €" % int(s.get("daily_wage", 0)), detail_costs, false)
		action_btn.text = GameState.T("ui.staff.fire", "Kündigen")
		action_btn.remove_theme_color_override("font_color")
		_style_action_btn(action_btn, "red")
	else:
		image_rect.visible = true
		pip_camera.visible = false
		btn_goto.visible = false
		pip_camera.set_target(null)
		
		_create_2col_row(GameState.T("ui.staff.hire_cost", "Einstellungsgebühr"), "%d €" % int(s.get("hire_cost", 0)), detail_costs, false)
		_create_2col_row(GameState.T("ui.staff.daily_wage", "Tagesgehalt"), "%d €" % int(s.get("daily_wage", 0)), detail_costs, false)
		action_btn.text = GameState.T("ui.staff.hire", "Einstellen")
		action_btn.remove_theme_color_override("font_color")
		_style_action_btn(action_btn, "green")
		
	var skills = s.get("skills", {})
	for skill_name in skills.keys():
		var translated_skill = GameState.T("staff.skill." + skill_name)
		if translated_skill == "staff.skill." + skill_name:
			translated_skill = skill_name.capitalize().replace("_", " ")
		_create_2col_row(translated_skill, str(skills[skill_name]), detail_stats, false)
		
	if s.has("morale"):
		_create_2col_row(GameState.T("ui.staff.morale", "Moral"), str(s.get("morale", 100)) + "%", detail_stats, false)

var _pending_action: int = 0 # 0=none, 1=hire, 2=fire
var _confirm_modal: Node = null

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
			"Kündigung",
			"Möchtest du " + staff_name + " wirklich kündigen?",
			"Kündigen",
			"Abbrechen",
			"",
			true # Destructive (Red button)
		)
	else:
		_pending_action = 1
		modal.ask(
			"Arbeitsvertrag",
			"Möchtest du " + staff_name + " für " + str(s.get("hire_cost", 0)) + " € einstellen?",
			"Einstellen",
			"Abbrechen",
			"",
			false # Green button
		)

func _on_confirm_accepted() -> void:
	if _selected_staff == null:
		return
		
	if _pending_action == 2:
		if StaffManager:
			StaffManager.fire_staff(_selected_staff["id"])
	elif _pending_action == 1:
		if StaffManager:
			StaffManager.hire_staff(_selected_staff["id"])
			
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
