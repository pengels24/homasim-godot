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
@onready var detail_wage: Label = %DetailWage
@onready var detail_stats: VBoxContainer = %DetailStats
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
			empty_label.text = "Du hast noch kein Personal eingestellt."
		else:
			empty_label.text = "Keine Bewerber heute."
	else:
		empty_label.visible = false
		for item in items:
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(0, 44)
			
			var hbox = HBoxContainer.new()
			hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
			hbox.add_theme_constant_override("margin_left", 10)
			hbox.add_theme_constant_override("margin_right", 10)
			
			var margin = MarginContainer.new()
			margin.set_anchors_preset(Control.PRESET_FULL_RECT)
			margin.add_theme_constant_override("margin_left", 10)
			margin.add_theme_constant_override("margin_right", 10)
			margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			var hbox_inner = HBoxContainer.new()
			margin.add_child(hbox_inner)
			
			var lbl_left = Label.new()
			lbl_left.text = item.get("first_name", "") + " " + item.get("last_name", "") + " (" + item.get("role", "") + ")"
			lbl_left.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			
			var spacer = Control.new()
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var lbl_right = Label.new()
			lbl_right.text = "Alter: %d  |  Gehalt: %d €  |  Moral: %d%%" % [item.get("age", 30), item.get("daily_wage", 80), item.get("morale", 100)]
			lbl_right.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl_right.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
			
			hbox_inner.add_child(lbl_left)
			hbox_inner.add_child(spacer)
			hbox_inner.add_child(lbl_right)
			
			btn.add_child(margin)
			btn.pressed.connect(func(): _select_item(item))
			list_container.add_child(btn)
			
	_update_details()

func _select_item(item: Dictionary) -> void:
	_selected_staff = item
	_update_details()

func _update_details() -> void:
	if _selected_staff == null:
		detail_name.text = ""
		detail_role.text = "Bitte wähle einen Mitarbeiter aus"
		detail_wage.text = ""
		action_btn.visible = false
		detail_image_lbl.text = ""
		
		for child in detail_stats.get_children():
			child.queue_free()
		return
		
	var s = _selected_staff
	detail_name.text = s.get("first_name", "") + " " + s.get("last_name", "") + " (" + str(s.get("age", 30)) + " J.)"
	detail_role.text = "Beruf: " + s.get("role", "")
	action_btn.visible = true
	
	if s.get("gender", "male") == "female":
		detail_image_lbl.text = "👩‍🔧"
	else:
		detail_image_lbl.text = "👨‍🔧"
	
	if _current_tab == 0:
		detail_wage.text = "Tagesgehalt: " + str(s.get("daily_wage", 0)) + " €"
		action_btn.text = "Kündigen"
		action_btn.add_theme_color_override("font_color", Color.RED)
	else:
		detail_wage.text = "Einstellungsgebühr: " + str(s.get("hire_cost", 0)) + " €\\nTagesgehalt: " + str(s.get("daily_wage", 0)) + " €"
		action_btn.text = "Einstellen"
		action_btn.add_theme_color_override("font_color", Color.GREEN)
		
	for child in detail_stats.get_children():
		child.queue_free()
		
	var skills = s.get("skills", {})
	for skill_name in skills.keys():
		var lbl = Label.new()
		lbl.text = str(skill_name) + ": " + str(skills[skill_name])
		detail_stats.add_child(lbl)
		
	if s.has("morale"):
		var lbl = Label.new()
		lbl.text = "Moral: " + str(s.get("morale", 100)) + "%"
		detail_stats.add_child(lbl)

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
theme_override_font_sizes/font_size = 28
text = "Name"
horizontal_alignment = 1

[node name="DetailRole" type="Label" parent="HBoxContainer/DetailPanel/MarginContainer/VBoxContainer"]
unique_name_in_owner = true
layout_mode = 2
theme_override_font_sizes/font_size = 18
theme_override_colors/font_color = Color(0.8, 0.8, 0.8, 1)
text = "Rolle"
horizontal_alignment = 1

[node name="HSeparator" type="HSeparator" parent="HBoxContainer/DetailPanel/MarginContainer/VBoxContainer"]
layout_mode = 2

[node name="DetailStats" type="VBoxContainer" parent="HBoxContainer/DetailPanel/MarginContainer/VBoxContainer"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3

[node name="HSeparator2" type="HSeparator" parent="HBoxContainer/DetailPanel/MarginContainer/VBoxContainer"]
layout_mode = 2

[node name="DetailWage" type="Label" parent="HBoxContainer/DetailPanel/MarginContainer/VBoxContainer"]
unique_name_in_owner = true
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "Gehalt: 0"
horizontal_alignment = 1

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
    
print("ModalContentStaff V2 generated!")
