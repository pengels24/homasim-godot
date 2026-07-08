extends PanelContainer
class_name ActivityLogEntry

@onready var lbl_category = $MarginContainer/VBoxContainer/HBoxContainer/Category
@onready var lbl_time = $MarginContainer/VBoxContainer/HBoxContainer/Time
@onready var lbl_message = $MarginContainer/VBoxContainer/Message

func setup(entry: Dictionary) -> void:
	var cat: String = entry.get("type", "info").to_upper()
	var trans_key = "activitylog.filter." + cat.to_lower()
	var translated = GameState.T(trans_key)
	lbl_category.text = translated if translated != trans_key else cat.to_upper()
	
	var t: int = entry.get("game_time", 0)
	var h = int(t / 60.0)
	var m = t % 60
	lbl_time.text = "%02d:%02d" % [h, m]
	
	var raw_msg: String = entry.get("message", "")
	if "|" in raw_msg:
		var parts: PackedStringArray = raw_msg.split("|")
		var msg_translated := GameState.T(parts[0])
		if parts.size() == 2:
			lbl_message.text = msg_translated % parts[1]
		elif parts.size() >= 3:
			lbl_message.text = msg_translated % [parts[1], parts[2]]
		else:
			lbl_message.text = msg_translated
	else:
		lbl_message.text = GameState.T(raw_msg)
	# Color border based on category
	var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
	match cat:
		"WARNING", "ERROR":
			style.border_color = Color("#b02e3b") # Red
		"BUILD", "CONSTRUCTION":
			style.border_color = Color("#3d4891") # Blue
		"STAFF", "PERSONAL", "WAGES":
			style.border_color = Color("#c79b38") # Gold
		"GUEST":
			style.border_color = Color("#366e4d") # Green
		_:
			style.border_color = Color("#666666") # Medium visible gray
	
	add_theme_stylebox_override("panel", style)
