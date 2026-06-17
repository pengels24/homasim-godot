import os

gd_script = """extends MarginContainer

var _selected_staff = null
var _current_tab = 0 # 0 = Team, 1 = Bewerber

@onready var tab_bar: TabBar = %TabBar
@onready var list_container: VBoxContainer = %ListContainer
@onready var detail_panel: Control = %DetailPanel
@onready var empty_label: Label = %EmptyLabel

@onready var detail_name: Label = %DetailName
@onready var detail_role: Label = %DetailRole
@onready var detail_wage: Label = %DetailWage
@onready var detail_stats: VBoxContainer = %DetailStats
@onready var action_btn: Button = %ActionBtn
@onready var detail_image: TextureRect = %DetailImage

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
			btn.text = item.get("first_name", "") + " " + item.get("last_name", "") + " (" + item.get("role", "") + ")"
			btn.custom_minimum_size = Vector2(0, 40)
			btn.pressed.connect(func(): _select_item(item))
			list_container.add_child(btn)
			
	_update_details()

func _select_item(item: Dictionary) -> void:
	_selected_staff = item
	_update_details()

func _update_details() -> void:
	if _selected_staff == null:
		detail_panel.visible = false
		return
		
	detail_panel.visible = true
	var s = _selected_staff
	detail_name.text = s.get("first_name", "") + " " + s.get("last_name", "")
	detail_role.text = "Beruf: " + s.get("role", "")
	
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

tscn_data = """[gd_scene load_steps=2 format=3 uid="uid://cxstaffmodal"]

[ext_resource type="Script" path="res://scenes/ingame/hud/modals/content/ModalContentStaff.gd" id="1_script"]

[node name="ModalContentStaff" type="MarginContainer"]
custom_minimum_size = Vector2(800, 500)
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
size_flags_stretch_ratio = 1.2

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

[node name="MarginContainer" type="MarginContainer" parent="HBoxContainer/DetailPanel"]
layout_mode = 2
theme_override_constants/margin_left = 20
theme_override_constants/margin_top = 20
theme_override_constants/margin_right = 20
theme_override_constants/margin_bottom = 20

[node name="VBoxContainer" type="VBoxContainer" parent="HBoxContainer/DetailPanel/MarginContainer"]
layout_mode = 2
theme_override_constants/separation = 15

[node name="DetailImage" type="TextureRect" parent="HBoxContainer/DetailPanel/MarginContainer/VBoxContainer"]
unique_name_in_owner = true
custom_minimum_size = Vector2(100, 100)
layout_mode = 2
expand_mode = 1
stretch_mode = 5

[node name="DetailName" type="Label" parent="HBoxContainer/DetailPanel/MarginContainer/VBoxContainer"]
unique_name_in_owner = true
layout_mode = 2
theme_override_font_sizes/font_size = 24
text = "Name"
horizontal_alignment = 1

[node name="DetailRole" type="Label" parent="HBoxContainer/DetailPanel/MarginContainer/VBoxContainer"]
unique_name_in_owner = true
layout_mode = 2
text = "Rolle"
horizontal_alignment = 1

[node name="HSeparator" type="HSeparator" parent="HBoxContainer/DetailPanel/MarginContainer/VBoxContainer"]
layout_mode = 2

[node name="ScrollStats" type="ScrollContainer" parent="HBoxContainer/DetailPanel/MarginContainer/VBoxContainer"]
layout_mode = 2
size_flags_vertical = 3

[node name="DetailStats" type="VBoxContainer" parent="HBoxContainer/DetailPanel/MarginContainer/VBoxContainer/ScrollStats"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3

[node name="HSeparator2" type="HSeparator" parent="HBoxContainer/DetailPanel/MarginContainer/VBoxContainer"]
layout_mode = 2

[node name="DetailWage" type="Label" parent="HBoxContainer/DetailPanel/MarginContainer/VBoxContainer"]
unique_name_in_owner = true
layout_mode = 2
text = "Gehalt: 0"
horizontal_alignment = 1

[node name="ActionBtn" type="Button" parent="HBoxContainer/DetailPanel/MarginContainer/VBoxContainer"]
unique_name_in_owner = true
custom_minimum_size = Vector2(0, 50)
layout_mode = 2
text = "Aktion"
"""

path_dir = r"d:\game-dev\homasim-godot\scenes\ingame\hud\modals\content"
os.makedirs(path_dir, exist_ok=True)

with open(os.path.join(path_dir, "ModalContentStaff.gd"), "w", encoding="utf-8") as f:
    f.write(gd_script)
    
with open(os.path.join(path_dir, "ModalContentStaff.tscn"), "w", encoding="utf-8") as f:
    f.write(tscn_data)
    
print("ModalContentStaff generated!")
