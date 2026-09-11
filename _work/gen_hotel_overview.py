import os

tscn = """[gd_scene load_steps=2 format=3 uid="uid://cxhoteloverview"]

[ext_resource type="Script" path="res://scenes/ingame/hud/modals/content/ModalContentHotelOverview.gd" id="1_script"]

[node name="ModalContentHotelOverview" type="MarginContainer"]
custom_minimum_size = Vector2(1000, 600)
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

[node name="Header" type="HBoxContainer" parent="VBox"]
layout_mode = 2

[node name="Title" type="Label" parent="VBox/Header"]
layout_mode = 2
theme_override_font_sizes/font_size = 32
text = "Hotel Status"

[node name="Grid" type="GridContainer" parent="VBox"]
layout_mode = 2
size_flags_vertical = 3
theme_override_constants/h_separation = 30
theme_override_constants/v_separation = 30
columns = 2

[node name="PanelStars" type="PanelContainer" parent="VBox/Grid"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_type_variation = &"InnerPanel"

[node name="M" type="MarginContainer" parent="VBox/Grid/PanelStars"]
layout_mode = 2
theme_override_constants/margin_left = 20
theme_override_constants/margin_top = 20
theme_override_constants/margin_right = 20
theme_override_constants/margin_bottom = 20

[node name="V" type="VBoxContainer" parent="VBox/Grid/PanelStars/M"]
layout_mode = 2

[node name="Label" type="Label" parent="VBox/Grid/PanelStars/M/V"]
layout_mode = 2
theme_override_colors/font_color = Color(0.917647, 0.701961, 0.0313726, 1)
theme_override_font_sizes/font_size = 24
text = "Sterne & Ruf"

[node name="HSeparator" type="HSeparator" parent="VBox/Grid/PanelStars/M/V"]
layout_mode = 2

[node name="ValStars" type="Label" parent="VBox/Grid/PanelStars/M/V"]
unique_name_in_owner = true
layout_mode = 2
theme_override_font_sizes/font_size = 20
text = "0 / 5 Sterne"

[node name="ValRep" type="Label" parent="VBox/Grid/PanelStars/M/V"]
unique_name_in_owner = true
layout_mode = 2
theme_override_font_sizes/font_size = 20
text = "0 Rufpunkte"

[node name="PanelFinances" type="PanelContainer" parent="VBox/Grid"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_type_variation = &"InnerPanel"

[node name="M" type="MarginContainer" parent="VBox/Grid/PanelFinances"]
layout_mode = 2
theme_override_constants/margin_left = 20
theme_override_constants/margin_top = 20
theme_override_constants/margin_right = 20
theme_override_constants/margin_bottom = 20

[node name="V" type="VBoxContainer" parent="VBox/Grid/PanelFinances/M"]
layout_mode = 2

[node name="Label" type="Label" parent="VBox/Grid/PanelFinances/M/V"]
layout_mode = 2
theme_override_colors/font_color = Color(0.917647, 0.701961, 0.0313726, 1)
theme_override_font_sizes/font_size = 24
text = "Finanzen"

[node name="HSeparator" type="HSeparator" parent="VBox/Grid/PanelFinances/M/V"]
layout_mode = 2

[node name="ValMoney" type="Label" parent="VBox/Grid/PanelFinances/M/V"]
unique_name_in_owner = true
layout_mode = 2
theme_override_font_sizes/font_size = 20
text = "0 €"

[node name="ValBalance" type="Label" parent="VBox/Grid/PanelFinances/M/V"]
unique_name_in_owner = true
layout_mode = 2
theme_override_font_sizes/font_size = 20
text = "Heute: +0 €"

[node name="PanelRooms" type="PanelContainer" parent="VBox/Grid"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_type_variation = &"InnerPanel"

[node name="M" type="MarginContainer" parent="VBox/Grid/PanelRooms"]
layout_mode = 2
theme_override_constants/margin_left = 20
theme_override_constants/margin_top = 20
theme_override_constants/margin_right = 20
theme_override_constants/margin_bottom = 20

[node name="V" type="VBoxContainer" parent="VBox/Grid/PanelRooms/M"]
layout_mode = 2

[node name="Label" type="Label" parent="VBox/Grid/PanelRooms/M/V"]
layout_mode = 2
theme_override_colors/font_color = Color(0.917647, 0.701961, 0.0313726, 1)
theme_override_font_sizes/font_size = 24
text = "Zimmer & Belegung"

[node name="HSeparator" type="HSeparator" parent="VBox/Grid/PanelRooms/M/V"]
layout_mode = 2

[node name="ValOccupancy" type="Label" parent="VBox/Grid/PanelRooms/M/V"]
unique_name_in_owner = true
layout_mode = 2
theme_override_font_sizes/font_size = 20
text = "Auslastung: 0%"

[node name="ValCleanliness" type="Label" parent="VBox/Grid/PanelRooms/M/V"]
unique_name_in_owner = true
layout_mode = 2
theme_override_font_sizes/font_size = 20
text = "Sauberkeit: 100%"

[node name="PanelGuests" type="PanelContainer" parent="VBox/Grid"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_type_variation = &"InnerPanel"

[node name="M" type="MarginContainer" parent="VBox/Grid/PanelGuests"]
layout_mode = 2
theme_override_constants/margin_left = 20
theme_override_constants/margin_top = 20
theme_override_constants/margin_right = 20
theme_override_constants/margin_bottom = 20

[node name="V" type="VBoxContainer" parent="VBox/Grid/PanelGuests/M"]
layout_mode = 2

[node name="Label" type="Label" parent="VBox/Grid/PanelGuests/M/V"]
layout_mode = 2
theme_override_colors/font_color = Color(0.917647, 0.701961, 0.0313726, 1)
theme_override_font_sizes/font_size = 24
text = "Gästezufriedenheit"

[node name="HSeparator" type="HSeparator" parent="VBox/Grid/PanelGuests/M/V"]
layout_mode = 2

[node name="ValSatisfaction" type="Label" parent="VBox/Grid/PanelGuests/M/V"]
unique_name_in_owner = true
layout_mode = 2
theme_override_font_sizes/font_size = 20
text = "Gesamt: 0%"
"""

gd = """extends MarginContainer

@onready var val_stars: Label = %ValStars
@onready var val_rep: Label = %ValRep
@onready var val_money: Label = %ValMoney
@onready var val_balance: Label = %ValBalance
@onready var val_occupancy: Label = %ValOccupancy
@onready var val_cleanliness: Label = %ValCleanliness
@onready var val_satisfaction: Label = %ValSatisfaction

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if not visible: return
	_update_stats()

func _update_stats() -> void:
	# Sterne & Ruf
	var stars = GameState.selected_hotel.get("stars", 0)
	var rep = GameState.selected_hotel.get("rep", 0)
	var rep_max = GameState.selected_hotel.get("rep_max", 100)
	val_stars.text = "%d / 5 Sterne" % stars
	val_rep.text = "%d / %d Rufpunkte" % [rep, rep_max]
	
	# Finanzen
	var money = GameState.selected_hotel.get("money", 0)
	val_money.text = "%d €" % money
	
	var balance = 0
	if FinanceManager:
		var record = FinanceManager.get_daily_record(TimeManager.current_day)
		balance = record["income"] - record["expense"]
		var prefix = "+" if balance >= 0 else ""
		val_balance.text = "Heute: %s%d €" % [prefix, balance]
	
	# Auslastung & Sauberkeit
	var total_beds = 0
	var used_beds = 0
	var total_cleanliness = 0.0
	var clean_rooms = 0
	
	if GameState.room_registry:
		for room_id in GameState.room_registry:
			var room_data = GameState.room_registry[room_id].get("def", {})
			var cat_id = room_data.get("category_id", "")
			if cat_id.begins_with("guest_"):
				var beds = room_data.get("bed_count", 0)
				total_beds += beds
				if room_data.get("is_occupied", false):
					used_beds += beds
				
				total_cleanliness += room_data.get("cleanliness", 100.0)
				clean_rooms += 1
				
	if total_beds > 0:
		val_occupancy.text = "Auslastung: %d%% (%d/%d Betten)" % [round((float(used_beds)/float(total_beds))*100.0), used_beds, total_beds]
	else:
		val_occupancy.text = "Auslastung: 0% (0 Betten)"
		
	if clean_rooms > 0:
		val_cleanliness.text = "Ø Sauberkeit: %d%%" % round(total_cleanliness / float(clean_rooms))
	else:
		val_cleanliness.text = "Ø Sauberkeit: 100%"
		
	# Gästezufriedenheit
	var total_sat = 0.0
	var parties = 0
	if get_tree().root.has_node("Ingame/Managers/GuestManager"):
		var guest_mgr = get_tree().root.get_node("Ingame/Managers/GuestManager")
		parties = guest_mgr.guest_parties.size()
		for party in guest_mgr.guest_parties:
			total_sat += party.satisfaction
			
	if parties > 0:
		val_satisfaction.text = "Ø Zufriedenheit: %d%% (%d Gruppen)" % [round(total_sat / float(parties)), parties]
	else:
		val_satisfaction.text = "Ø Zufriedenheit: Keine Gäste"
"""

with open("d:/game-dev/homasim-godot/scenes/ingame/hud/modals/content/ModalContentHotelOverview.tscn", "w", encoding="utf-8") as f:
    f.write(tscn)

with open("d:/game-dev/homasim-godot/scenes/ingame/hud/modals/content/ModalContentHotelOverview.gd", "w", encoding="utf-8") as f:
    f.write(gd)
