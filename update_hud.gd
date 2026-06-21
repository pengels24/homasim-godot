@tool
extends SceneTree

func _init() -> void:
	var path = "res://scenes/ingame/hud/HUDBottom.tscn"
	var packed_scene = load(path)
	var root = packed_scene.instantiate()
	var hbox = root.get_node("HBoxContainer")
	
	# 1. Create Tutorials Button (Panel0)
	var panel0 = Panel.new()
	panel0.name = "Panel0"
	panel0.custom_minimum_size = Vector2(60, 60)
	panel0.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel0.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var mc0 = MarginContainer.new()
	mc0.name = "MarginContainer"
	mc0.set_anchors_preset(Control.PRESET_FULL_RECT)
	mc0.add_theme_constant_override("margin_left", 10)
	mc0.add_theme_constant_override("margin_top", 10)
	mc0.add_theme_constant_override("margin_right", 10)
	mc0.add_theme_constant_override("margin_bottom", 10)
	
	var btn0 = Button.new()
	btn0.name = "Tutorials"
	btn0.text = "TUT"
	btn0.focus_mode = Control.FOCUS_NONE
	mc0.add_child(btn0)
	panel0.add_child(mc0)
	
	# 2. Create GuestList Button (Panel7)
	var panel7 = Panel.new()
	panel7.name = "Panel7"
	panel7.custom_minimum_size = Vector2(60, 60)
	panel7.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel7.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var mc7 = MarginContainer.new()
	mc7.name = "MarginContainer"
	mc7.set_anchors_preset(Control.PRESET_FULL_RECT)
	mc7.add_theme_constant_override("margin_left", 10)
	mc7.add_theme_constant_override("margin_top", 10)
	mc7.add_theme_constant_override("margin_right", 10)
	mc7.add_theme_constant_override("margin_bottom", 10)
	
	var btn7 = Button.new()
	btn7.name = "GuestList"
	btn7.text = "Gäste"
	btn7.focus_mode = Control.FOCUS_NONE
	mc7.add_child(btn7)
	panel7.add_child(mc7)
	
	# 3. Create RoomList Button (Panel8)
	var panel8 = Panel.new()
	panel8.name = "Panel8"
	panel8.custom_minimum_size = Vector2(60, 60)
	panel8.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel8.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var mc8 = MarginContainer.new()
	mc8.name = "MarginContainer"
	mc8.set_anchors_preset(Control.PRESET_FULL_RECT)
	mc8.add_theme_constant_override("margin_left", 10)
	mc8.add_theme_constant_override("margin_top", 10)
	mc8.add_theme_constant_override("margin_right", 10)
	mc8.add_theme_constant_override("margin_bottom", 10)
	
	var btn8 = Button.new()
	btn8.name = "RoomList"
	btn8.text = "Räume"
	btn8.focus_mode = Control.FOCUS_NONE
	mc8.add_child(btn8)
	panel8.add_child(mc8)
	
	# Set unique names explicitly
	btn0.unique_name_in_owner = true
	btn7.unique_name_in_owner = true
	btn8.unique_name_in_owner = true
	
	# Add to hbox
	hbox.add_child(panel0)
	hbox.move_child(panel0, 0) # move to start
	hbox.add_child(panel7)
	hbox.add_child(panel8)
	
	# Need to set owner for persistence in tscn
	panel0.owner = root
	mc0.owner = root
	btn0.owner = root
	
	panel7.owner = root
	mc7.owner = root
	btn7.owner = root
	
	panel8.owner = root
	mc8.owner = root
	btn8.owner = root
	
	var new_scene = PackedScene.new()
	new_scene.pack(root)
	ResourceSaver.save(new_scene, path)
	print("SUCCESS")
	quit()
