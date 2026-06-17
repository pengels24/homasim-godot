import os

gd_script = """extends MarginContainer

var _selected_staff = null
var _current_tab = 0 # 0 = Team, 1 = Bewerber

@onready var tab_bar: TabBar = %TabBar
@onready var list_container: VBoxContainer = %ListContainer
@onready var empty_label: Label = %EmptyLabel

@onready var detail_panel: Control = %DetailPanel
@onready var detail_name: Label = %DetailName
@onready var detail_role: Label = %DetailRole
@onready var detail_stats: VBoxContainer = %DetailStats
@onready var detail_costs: VBoxContainer = %DetailCosts
@onready var action_btn: Button = %ActionBtn
@onready var detail_image_lbl: Label = %DetailImageLbl

func _ready() -> void:
	tab_bar.add_tab("Dein Team")
	tab_bar.add_tab("Bewerber")
	tab_bar.tab_changed.connect(_on_tab_changed)
	action_btn.pressed.connect(_on_action_btn_pressed)
	
	if StaffManager:
		StaffManager.sig_staff_hired.connect(_on_staff_changed)
		StaffManager.sig_staff_fired.connect(_on_staff_changed)
		
	_refresh_list()

func _on_tab_changed(tab: int) -> void:
	_current_tab = tab
	_selected_staff = null
	_refresh_list()

func _on_staff_changed(_dummy = null) -> void:
	_selected_staff = null
	_refresh_list()

func _refresh_list() -> void:
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
			
	if items.is_empty():
		empty_label.visible = true
		if _current_tab == 0:
			empty_label.text = GameState.T("ui.staff.no_team", "Du hast noch kein Personal eingestellt.")
		else:
			empty_label.text = GameState.T("ui.staff.no_applicants", "Keine Bewerber heute.")
	else:
		empty_label.visible = false
		var first_new_btn = null
		
		for item in items:
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(0, 44)
			
			var sb_empty = StyleBoxEmpty.new()
			var sb_focus = StyleBoxFlat.new()
			sb_focus.bg_color = Color(0.5, 0.35, 0.05, 0.8) # Dunkles Gold
			sb_focus.set_corner_radius_all(4)
			
			btn.add_theme_stylebox_override("normal", sb_empty)
			btn.add_theme_stylebox_override("hover", sb_focus)
			btn.add_theme_stylebox_override("pressed", sb_focus)
			btn.add_theme_stylebox_override("focus", sb_focus)
			
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
			lbl_wage.text = str(item.get("daily_wage", 80)) + " €"
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
			btn.focus_entered.connect(func(): _select_item(item))
			btn.mouse_entered.connect(func(): btn.grab_focus())
			list_container.add_child(btn)
			
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
		lbl_left.add_theme_font_size_override("font_size", 22)
	else:
		lbl_left.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var lbl_right = Label.new()
	lbl_right.text = value_text
	lbl_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if is_big:
		lbl_right.add_theme_font_size_override("font_size", 22)
		lbl_right.add_theme_color_override("font_color", Color(0.9, 0.7, 0.1))
	else:
		lbl_right.add_theme_font_size_override("font_size", 18)
	
	hbox.add_child(lbl_left)
	hbox.add_child(spacer)
	hbox.add_child(lbl_right)
	parent.add_child(hbox)

func _select_item(item: Dictionary) -> void:
	_selected_staff = item
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
		detail_image_lbl.text = ""
		return
		
	var s = _selected_staff
	detail_name.text = s.get("first_name", "") + " " + s.get("last_name", "") + " (" + str(s.get("age", 30)) + " J.)"
	detail_role.text = GameState.T("ui.staff.job", "Beruf: ") + GameState.T("staff.role." + s.get("role", ""))
	action_btn.visible = true
	
	var is_female = s.get("gender", "male") == "female"
	var role = s.get("role", "")
	
	if role == "maintenance":
		detail_image_lbl.text = "👩‍🔧" if is_female else "👨‍🔧"
	elif role == "housekeeping":
		detail_image_lbl.text = "👩‍🍳" if is_female else "👨‍🍳"
	else:
		detail_image_lbl.text = "👩‍💼" if is_female else "👨‍💼"
	
	if _current_tab == 0:
		_create_2col_row(GameState.T("ui.staff.daily_wage", "Tagesgehalt"), str(s.get("daily_wage", 0)) + " €", detail_costs, true)
		action_btn.text = GameState.T("ui.staff.fire", "Kündigen")
		action_btn.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	else:
		_create_2col_row(GameState.T("ui.staff.hire_cost", "Einstellungsgebühr"), str(s.get("hire_cost", 0)) + " €", detail_costs, true)
		_create_2col_row(GameState.T("ui.staff.daily_wage", "Tagesgehalt"), str(s.get("daily_wage", 0)) + " €", detail_costs, true)
		action_btn.text = GameState.T("ui.staff.hire", "Einstellen")
		action_btn.add_theme_color_override("font_color", Color(0.4, 1, 0.4))
		
	var skills = s.get("skills", {})
	for skill_name in skills.keys():
		var translated_skill = GameState.T("staff.skill." + skill_name)
		if translated_skill == "staff.skill." + skill_name:
			translated_skill = skill_name.capitalize().replace("_", " ")
		_create_2col_row(translated_skill, str(skills[skill_name]), detail_stats, false)
		
	if s.has("morale"):
		_create_2col_row(GameState.T("ui.staff.morale", "Moral"), str(s.get("morale", 100)) + "%", detail_stats, false)

func _on_action_btn_pressed() -> void:
	if _selected_staff == null:
		return
		
	if _current_tab == 0:
		if StaffManager:
			StaffManager.fire_staff(_selected_staff["id"])
	else:
		if StaffManager:
			StaffManager.hire_staff(_selected_staff["id"])
"""

tscn_data = """[gd_scene load_steps=3 format=3 uid="uid://cxstaffmodal"]

[ext_resource type="Script" path="res://scenes/ingame/hud/modals/content/ModalContentStaff.gd" id="1_script"]

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_Detail"]
bg_color = Color(0.12, 0.12, 0.14, 1)
corner_radius_top_left = 8
corner_radius_top_right = 8
corner_radius_bottom_right = 8
corner_radius_bottom_left = 8

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_Header"]
bg_color = Color(0.2, 0.2, 0.22, 1)
corner_radius_top_left = 4
corner_radius_top_right = 4
corner_radius_bottom_right = 4
corner_radius_bottom_left = 4

[node name="ModalContentStaff" type="MarginContainer"]
custom_minimum_size = Vector2(1100, 600)
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/margin_left = 20
theme_override_constants/margin_top = 20
theme_override_constants/margin_right = 20
theme_override_constants/margin_bottom = 20
script = ExtResource("1_script")

[node name="HBoxContainer" type="HBoxContainer" parent="."]
layout_mode = 2
theme_override_constants/separation = 40

[node name="LeftCol" type="VBoxContainer" parent="HBoxContainer"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_stretch_ratio = 1.6

[node name="TabBar" type="TabBar" parent="HBoxContainer/LeftCol"]
unique_name_in_owner = true
layout_mode = 2

[node name="TableHeaderPanel" type="PanelContainer" parent="HBoxContainer/LeftCol"]
layout_mode = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_Header")

[node name="MarginContainer" type="MarginContainer" parent="HBoxContainer/LeftCol/TableHeaderPanel"]
layout_mode = 2
theme_override_constants/margin_left = 16
theme_override_constants/margin_right = 16
theme_override_constants/margin_top = 8
theme_override_constants/margin_bottom = 8

[node name="HBoxContainer" type="HBoxContainer" parent="HBoxContainer/LeftCol/TableHeaderPanel/MarginContainer"]
layout_mode = 2
theme_override_constants/separation = 10

[node name="LblName" type="Label" parent="HBoxContainer/LeftCol/TableHeaderPanel/MarginContainer/HBoxContainer"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_stretch_ratio = 3.5
theme_override_colors/font_color = Color(0.9, 0.7, 0.1, 1)
text = "Name"

[node name="LblRole" type="Label" parent="HBoxContainer/LeftCol/TableHeaderPanel/MarginContainer/HBoxContainer"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_stretch_ratio = 2.5
theme_override_colors/font_color = Color(0.9, 0.7, 0.1, 1)
text = "Beruf"

[node name="LblAge" type="Label" parent="HBoxContainer/LeftCol/TableHeaderPanel/MarginContainer/HBoxContainer"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_stretch_ratio = 1.0
theme_override_colors/font_color = Color(0.9, 0.7, 0.1, 1)
text = "Alter"
horizontal_alignment = 1

[node name="LblWage" type="Label" parent="HBoxContainer/LeftCol/TableHeaderPanel/MarginContainer/HBoxContainer"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_stretch_ratio = 1.5
theme_override_colors/font_color = Color(0.9, 0.7, 0.1, 1)
text = "Gehalt"
horizontal_alignment = 2

[node name="LblMorale" type="Label" parent="HBoxContainer/LeftCol/TableHeaderPanel/MarginContainer/HBoxContainer"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_stretch_ratio = 1.5
theme_override_colors/font_color = Color(0.9, 0.7, 0.1, 1)
text = "Moral"
horizontal_alignment = 2

[node name="ScrollContainer" type="ScrollContainer" parent="HBoxContainer/LeftCol"]
layout_mode = 2
size_flags_vertical = 3

[node name="ListContainer" type="VBoxContainer" parent="HBoxContainer/LeftCol/ScrollContainer"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3

[node name="EmptyLabel" type="Label" parent="HBoxContainer/LeftCol/ScrollContainer/ListContainer"]
unique_name_in_owner = true
layout_mode = 2
text = "Keine Daten."
horizontal_alignment = 1

[node name="DetailPanel" type="PanelContainer" parent="HBoxContainer"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
theme_override_styles/panel = SubResource("StyleBoxFlat_Detail")

[node name="MarginContainer" type="MarginContainer" parent="HBoxContainer/DetailPanel"]
layout_mode = 2
theme_override_constants/margin_left = 24
theme_override_constants/margin_top = 24
theme_override_constants/margin_right = 24
theme_override_constants/margin_bottom = 24

[node name="VBoxContainer" type="VBoxContainer" parent="HBoxContainer/DetailPanel/MarginContainer"]
layout_mode = 2
theme_override_constants/separation = 20

[node name="ImageRect" type="ColorRect" parent="HBoxContainer/DetailPanel/MarginContainer/VBoxContainer"]
custom_minimum_size = Vector2(120, 120)
layout_mode = 2
size_flags_horizontal = 4
color = Color(0.2, 0.2, 0.22, 1)

[node name="DetailImageLbl" type="Label" parent="HBoxContainer/DetailPanel/MarginContainer/VBoxContainer/ImageRect"]
unique_name_in_owner = true
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_font_sizes/font_size = 72
horizontal_alignment = 1
vertical_alignment = 1

[node name="DetailName" type="Label" parent="HBoxContainer/DetailPanel/MarginContainer/VBoxContainer"]
unique_name_in_owner = true
layout_mode = 2
theme_override_colors/font_color = Color(0.9, 0.7, 0.1, 1)
theme_override_font_sizes/font_size = 28
text = "Name"
horizontal_alignment = 1

[node name="DetailRole" type="Label" parent="HBoxContainer/DetailPanel/MarginContainer/VBoxContainer"]
unique_name_in_owner = true
layout_mode = 2
theme_override_font_sizes/font_size = 22
theme_override_colors/font_color = Color(0.8, 0.8, 0.8, 1)
text = "Rolle"
horizontal_alignment = 1

[node name="HSeparator" type="HSeparator" parent="HBoxContainer/DetailPanel/MarginContainer/VBoxContainer"]
layout_mode = 2

[node name="DetailStats" type="VBoxContainer" parent="HBoxContainer/DetailPanel/MarginContainer/VBoxContainer"]
unique_name_in_owner = true
layout_mode = 2
theme_override_constants/separation = 6

[node name="HSeparator2" type="HSeparator" parent="HBoxContainer/DetailPanel/MarginContainer/VBoxContainer"]
layout_mode = 2

[node name="DetailCosts" type="VBoxContainer" parent="HBoxContainer/DetailPanel/MarginContainer/VBoxContainer"]
unique_name_in_owner = true
layout_mode = 2
theme_override_constants/separation = 8

[node name="Spacer" type="Control" parent="HBoxContainer/DetailPanel/MarginContainer/VBoxContainer"]
layout_mode = 2
size_flags_vertical = 3

[node name="ActionBtn" type="Button" parent="HBoxContainer/DetailPanel/MarginContainer/VBoxContainer"]
unique_name_in_owner = true
custom_minimum_size = Vector2(200, 60)
layout_mode = 2
size_flags_horizontal = 4
theme_override_font_sizes/font_size = 20
text = "Aktion"
"""

path_dir = r"d:\game-dev\homasim-godot\scenes\ingame\hud\modals\content"
os.makedirs(path_dir, exist_ok=True)

with open(os.path.join(path_dir, "ModalContentStaff.gd"), "w", encoding="utf-8") as f:
    f.write(gd_script)
    
with open(os.path.join(path_dir, "ModalContentStaff.tscn"), "w", encoding="utf-8") as f:
    f.write(tscn_data)
    
print("ModalContentStaff V4 generated!")
