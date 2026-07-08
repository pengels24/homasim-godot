extends MarginContainer
class_name BuildHintPanel

@onready var anim_player = $AnimationPlayer

func _ready() -> void:
	visible = false
	modulate.a = 0.0
	_update_labels()

func _translate_key(key_str: String) -> String:
	var t_key = "key." + key_str.to_lower().replace(" ", "_")
	var translated = GameState.T(t_key)
	if translated == t_key:
		return key_str
	return translated

func _get_key_string(action: String) -> String:
	var events = InputMap.action_get_events(action)
	for ev in events:
		if ev is InputEventKey:
			return _translate_key(OS.get_keycode_string(ev.physical_keycode))
	return "?"

func _update_labels() -> void:
	var label_r = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/LabelR
	var label_r2 = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/LabelR2
	var label_dot = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/LabelDot
	var label_dot2 = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/LabelDot2
	var hbox_shift = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3
	var label_shift = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/LabelShift
	var label_shift2 = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/LabelShift2
	
	if label_r and label_r2:
		label_r.text = "[%s]" % _get_key_string("rotate_room")
		label_r2.text = GameState.T("settings.controls.build.rotate")
		
	if label_dot and label_dot2:
		label_dot.text = "[%s]" % _get_key_string("cycle_door")
		label_dot2.text = GameState.T("settings.controls.build.door")

	if hbox_shift and label_shift and label_shift2:
		label_shift.text = "[%s]" % _get_key_string("multi_build_modifier")
		label_shift2.text = GameState.T("settings.gameplay.multi_build.shift_hint")
		# Nur anzeigen, wenn Mehrfachbau "Mit Taste" eingestellt ist
		hbox_shift.visible = (SettingsManager.multi_build_mode == 2)

func show_hints() -> void:
	var vbox = $PanelContainer/MarginContainer/VBoxContainer
	for child in vbox.get_children():
		child.visible = true
	if vbox.has_node("CatLegend"):
		vbox.get_node("CatLegend").visible = false
	
	_update_labels()
	visible = true
	anim_player.play("slide_in")

func show_category_legend() -> void:
	var vbox = $PanelContainer/MarginContainer/VBoxContainer
	for child in vbox.get_children():
		child.visible = false
	
	if not vbox.has_node("CatLegend"):
		var legend_box = VBoxContainer.new()
		legend_box.name = "CatLegend"
		vbox.add_child(legend_box)
		
		var cats = [
			{"name": GameState.T("overlay.cat.zimmer", "Zimmer"), "color": Color(0.0, 0.5, 1.0)},
			{"name": GameState.T("overlay.cat.gastro", "Gastro"), "color": Color(1.0, 0.5, 0.0)},
			{"name": GameState.T("overlay.cat.infra", "Infrastruktur"), "color": Color(0.6, 0.4, 0.2)},
			{"name": GameState.T("overlay.cat.service", "Service"), "color": Color(0.5, 0.5, 0.5)}
		]
		for c in cats:
			var hb = HBoxContainer.new()
			hb.add_theme_constant_override("separation", 10)
			
			var cr = ColorRect.new()
			cr.custom_minimum_size = Vector2(24, 24)
			cr.color = c.color
			cr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hb.add_child(cr)
			
			var lbl = Label.new()
			lbl.text = c.name
			lbl.add_theme_font_size_override("font_size", 22)
			lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
			hb.add_child(lbl)
			
			legend_box.add_child(hb)
			
	var legend = vbox.get_node("CatLegend")
	legend.visible = true
	
	visible = true
	anim_player.play("slide_in")

func hide_hints() -> void:
	anim_player.play("slide_out")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "slide_out":
		visible = false
