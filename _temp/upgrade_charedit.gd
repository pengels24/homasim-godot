@tool
extends EditorScript

func _run():
	var scene_path = "res://scenes/character/CharacterEdit.tscn"
	var packed_scene = load(scene_path)
	var root = packed_scene.instantiate()
	
	# Load styles
	var modal_panel = load("res://assets/UI/modal_panel_glow.tres")
	var red_n = load("res://assets/UI/menu_button_red.tres")
	var red_h = load("res://assets/UI/menu_button_red_hover.tres")
	var red_p = load("res://assets/UI/menu_button_red_pressed.tres")
	var blue_n = load("res://assets/UI/menu_button_darkblue.tres")
	var blue_h = load("res://assets/UI/menu_button_darkblue_hover.tres")
	var blue_p = load("res://assets/UI/menu_button_darkblue_pressed.tres")
	var gold_n = load("res://assets/UI/menu_button_golden.tres")
	var gold_h = load("res://assets/UI/menu_button_golden_hover.tres")
	var gold_p = load("res://assets/UI/menu_button_golden_pressed.tres")
	var green_n = load("res://assets/UI/menu_button_green.tres")
	var green_h = load("res://assets/UI/menu_button_green_hover.tres")
	var green_p = load("res://assets/UI/menu_button_green_pressed.tres")
	
	var card = root.get_node("Center/Card")
	card.add_theme_stylebox_override("panel", modal_panel)
	card.custom_minimum_size = Vector2(900, 0) # Slightly wider for breathing room
	
	var vbox = root.get_node("Center/Card/VBox")
	
	# 1. Add MarginContainer between Card and VBox
	var margin = MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	
	card.remove_child(vbox)
	card.add_child(margin)
	margin.owner = root
	margin.add_child(vbox)
	
	# 2. Fix Header
	var title = vbox.get_node("Title")
	vbox.remove_child(title)
	
	var header = HBoxContainer.new()
	header.name = "Header"
	vbox.add_child(header)
	vbox.move_child(header, 0)
	header.owner = root
	
	header.add_child(title)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_color_override("font_color", Color("e3ae08"))
	title.add_theme_color_override("font_shadow_color", Color(0,0,0,0.6))
	title.add_theme_font_size_override("font_size", 32)
	
	var btn_back = root.get_node("Center/Card/Margin/VBox/BtnBack")
	vbox.remove_child(btn_back)
	header.add_child(btn_back)
	btn_back.text = ""
	btn_back.icon = load("res://assets/images/icons/x.svg") # Fallback to standard Godot if missing, wait: we have x.svg?
	# Let's just use text "X" if icon fails
	btn_back.text = "X"
	btn_back.custom_minimum_size = Vector2(40, 40)
	btn_back.add_theme_stylebox_override("normal", red_n)
	btn_back.add_theme_stylebox_override("hover", red_h)
	btn_back.add_theme_stylebox_override("pressed", red_p)
	btn_back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	# 3. Add HSeparator
	var sep = HSeparator.new()
	sep.name = "HSeparator"
	var sep_style = StyleBoxLine.new()
	sep_style.color = Color("e3ae08")
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)
	vbox.move_child(sep, 1)
	sep.owner = root
	
	# 4. Style Option Buttons
	var options = root.get_node("Center/Card/Margin/VBox/HBox/Options")
	for row in [options.get_node("GenderRow"), options.get_node("SkinRow"), options.get_node("HairRow"), options.get_node("OutfitRow")]:
		for btn in row.get_children():
			if btn is Button:
				btn.add_theme_stylebox_override("normal", blue_n)
				btn.add_theme_stylebox_override("hover", blue_h)
				btn.add_theme_stylebox_override("pressed", gold_n)
				btn.add_theme_font_size_override("font_size", 14)
				btn.add_theme_color_override("font_color", Color.WHITE)
				btn.add_theme_color_override("font_hover_color", Color.WHITE)
				btn.add_theme_color_override("font_pressed_color", Color("000000"))
				btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	# 5. Style Save Button
	var btn_save = root.get_node("Center/Card/Margin/VBox/BtnSave")
	btn_save.add_theme_stylebox_override("normal", green_n)
	btn_save.add_theme_stylebox_override("hover", green_h)
	btn_save.add_theme_stylebox_override("pressed", green_p)
	btn_save.add_theme_color_override("font_color", Color.WHITE)
	btn_save.add_theme_color_override("font_hover_color", Color.WHITE)
	btn_save.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	# Save scene
	var p = PackedScene.new()
	p.pack(root)
	ResourceSaver.save(p, scene_path)
	print("Scene updated successfully.")
