import os

tscn = """[gd_scene load_steps=2 format=3 uid="uid://cxyzinsprep"]

[ext_resource type="Script" path="res://scenes/ingame/hud/modals/content/ModalContentInspectorReport.gd" id="1_script"]

[node name="ModalContentInspectorReport" type="MarginContainer"]
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

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode = 2
theme_override_constants/separation = 20

[node name="Title" type="Label" parent="VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 28
text = "Ergebnisse der Prüfung"
horizontal_alignment = 1

[node name="ResultLabel" type="RichTextLabel" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
bbcode_enabled = true
text = "[center]Auswertung...[/center]"
fit_content = true

[node name="Grid" type="GridContainer" parent="VBox"]
layout_mode = 2
size_flags_vertical = 3
theme_override_constants/h_separation = 20
theme_override_constants/v_separation = 10
columns = 3

[node name="H1" type="Label" parent="VBox/Grid"]
layout_mode = 2
theme_override_colors/font_color = Color(0.917647, 0.701961, 0.0313726, 1)
text = "Kriterium"

[node name="H2" type="Label" parent="VBox/Grid"]
layout_mode = 2
theme_override_colors/font_color = Color(0.917647, 0.701961, 0.0313726, 1)
text = "Erreicht"

[node name="H3" type="Label" parent="VBox/Grid"]
layout_mode = 2
theme_override_colors/font_color = Color(0.917647, 0.701961, 0.0313726, 1)
text = "Gefordert"

[node name="LblSat" type="Label" parent="VBox/Grid"]
layout_mode = 2
text = "Inspektor-Zufriedenheit"

[node name="ValSat" type="Label" parent="VBox/Grid"]
unique_name_in_owner = true
layout_mode = 2
text = "0%"

[node name="ReqSat" type="Label" parent="VBox/Grid"]
unique_name_in_owner = true
layout_mode = 2
text = "0%"

[node name="LblAvgSat" type="Label" parent="VBox/Grid"]
layout_mode = 2
text = "Ø Gästezufriedenheit"

[node name="ValAvgSat" type="Label" parent="VBox/Grid"]
unique_name_in_owner = true
layout_mode = 2
text = "0%"

[node name="ReqAvgSat" type="Label" parent="VBox/Grid"]
unique_name_in_owner = true
layout_mode = 2
text = "0%"

[node name="LblClean" type="Label" parent="VBox/Grid"]
layout_mode = 2
text = "Ø Sauberkeit"

[node name="ValClean" type="Label" parent="VBox/Grid"]
unique_name_in_owner = true
layout_mode = 2
text = "0%"

[node name="ReqClean" type="Label" parent="VBox/Grid"]
unique_name_in_owner = true
layout_mode = 2
text = "0%"

[node name="LblRep" type="Label" parent="VBox/Grid"]
layout_mode = 2
text = "Rufpunkte"

[node name="ValRep" type="Label" parent="VBox/Grid"]
unique_name_in_owner = true
layout_mode = 2
text = "0"

[node name="ReqRep" type="Label" parent="VBox/Grid"]
unique_name_in_owner = true
layout_mode = 2
text = "0"

[node name="LblRooms" type="Label" parent="VBox/Grid"]
layout_mode = 2
text = "Zimmer (Gesamt)"

[node name="ValRooms" type="Label" parent="VBox/Grid"]
unique_name_in_owner = true
layout_mode = 2
text = "0"

[node name="ReqRooms" type="Label" parent="VBox/Grid"]
unique_name_in_owner = true
layout_mode = 2
text = "0"

[node name="Space" type="Control" parent="VBox"]
layout_mode = 2
size_flags_vertical = 3

[node name="BtnClose" type="Button" parent="VBox"]
unique_name_in_owner = true
custom_minimum_size = Vector2(200, 50)
layout_mode = 2
size_flags_horizontal = 4
text = "Bericht schließen"
"""

gd = """extends MarginContainer

signal sig_close_requested

@onready var result_label: RichTextLabel = %ResultLabel

@onready var val_sat: Label = %ValSat
@onready var req_sat: Label = %ReqSat
@onready var val_avg_sat: Label = %ValAvgSat
@onready var req_avg_sat: Label = %ReqAvgSat
@onready var val_clean: Label = %ValClean
@onready var req_clean: Label = %ReqClean
@onready var val_rep: Label = %ValRep
@onready var req_rep: Label = %ReqRep
@onready var val_rooms: Label = %ValRooms
@onready var req_rooms: Label = %ReqRooms
@onready var btn_close: Button = %BtnClose

func _ready() -> void:
	btn_close.pressed.connect(func(): sig_close_requested.emit())

func setup(stats: Dictionary) -> void:
	val_sat.text = str(stats.inspector_sat) + "%"
	req_sat.text = str(stats.req_inspector_sat) + "%"
	if stats.inspector_sat < stats.req_inspector_sat: val_sat.add_theme_color_override("font_color", Color.RED)
	
	val_avg_sat.text = str(stats.avg_sat) + "%"
	req_avg_sat.text = str(stats.req_avg_sat) + "%"
	if stats.avg_sat < stats.req_avg_sat: val_avg_sat.add_theme_color_override("font_color", Color.RED)
	
	val_clean.text = str(stats.avg_clean) + "%"
	req_clean.text = str(stats.req_clean) + "%"
	if stats.avg_clean < stats.req_clean: val_clean.add_theme_color_override("font_color", Color.RED)
	
	val_rep.text = str(stats.rep)
	req_rep.text = str(stats.req_rep)
	if stats.rep < stats.req_rep: val_rep.add_theme_color_override("font_color", Color.RED)
	
	val_rooms.text = str(stats.rooms)
	req_rooms.text = str(stats.req_rooms)
	if stats.rooms < stats.req_rooms: val_rooms.add_theme_color_override("font_color", Color.RED)
	
	if stats.result == "up":
		result_label.text = "[center][color=green]Prüfung erfolgreich![/color] Die Anforderungen für den nächsten Stern wurden erfüllt.[/center]"
	elif stats.result == "down":
		result_label.text = "[center][color=red]Prüfung nicht bestanden![/color] Aufgrund gravierender Mängel wurde ein Stern aberkannt.[/center]"
	else:
		result_label.text = "[center][color=yellow]Prüfung nicht bestanden.[/color] Aktueller Stern konnte gehalten werden.[/center]"
"""

with open("d:/game-dev/homasim-godot/scenes/ingame/hud/modals/content/ModalContentInspectorReport.tscn", "w", encoding="utf-8") as f:
    f.write(tscn)

with open("d:/game-dev/homasim-godot/scenes/ingame/hud/modals/content/ModalContentInspectorReport.gd", "w", encoding="utf-8") as f:
    f.write(gd)
