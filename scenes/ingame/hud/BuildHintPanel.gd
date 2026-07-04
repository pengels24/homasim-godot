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
	
	if label_r and label_r2:
		label_r.text = "[%s]" % _get_key_string("rotate_room")
		label_r2.text = GameState.T("settings.controls.build.rotate")
		
	if label_dot and label_dot2:
		label_dot.text = "[%s]" % _get_key_string("cycle_door")
		label_dot2.text = GameState.T("settings.controls.build.door")

func show_hints() -> void:
	visible = true
	anim_player.play("slide_in")

func hide_hints() -> void:
	anim_player.play("slide_out")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "slide_out":
		visible = false
