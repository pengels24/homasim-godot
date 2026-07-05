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
	var h = t / 60
	var m = t % 60
	lbl_time.text = "%02d:%02d" % [h, m]
	
	lbl_message.text = GameState.T(entry.get("message", ""))
	
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
