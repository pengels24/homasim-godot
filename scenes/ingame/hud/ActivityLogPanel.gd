extends PanelContainer
class_name ActivityLogPanel

const ENTRY_SCENE = preload("res://scenes/ingame/hud/ActivityLogEntry.tscn")

@onready var anim = $AnimationPlayer
@onready var container = $MarginContainer/VBoxContainer/ScrollContainer/EntriesContainer
@onready var filter_label = $MarginContainer/VBoxContainer/Header/FilterLabel
@onready var scroll = $MarginContainer/VBoxContainer/ScrollContainer

var _is_open: bool = false
var _filters: Array[String] = ["ALLE"]
var _current_filter_idx: int = 0

func _ready() -> void:
	visible = false
	modulate = Color(1, 1, 1, 0)
	ActivityLog.entry_added.connect(_on_entry_added)

var _tween: Tween

func open() -> void:
	if _is_open: return
	_is_open = true
	visible = true
	
	_update_filters()
	_refresh_list()
	
	ActivityLog.mark_all_read()
	_animate_to(true)

func close() -> void:
	if not _is_open: return
	_is_open = false
	_animate_to(false)

func _animate_to(is_opening: bool) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
		
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Dynamische Berechnung der X-Position auf Basis der Skalierung
	var parent_width = get_viewport().get_visible_rect().size.x / get_tree().root.content_scale_factor
	var my_width = size.x if size.x > 10 else 390.0
	
	var visible_x = parent_width - my_width - 20
	var hidden_x = parent_width + 20
	
	var target_x = visible_x if is_opening else hidden_x
	var target_mod = Color(1, 1, 1, 1) if is_opening else Color(1, 1, 1, 0)
	
	# Wenn wir aus dem absoluten Off starten (z.B. 1950 bei kleinerer Auflösung), einmalig anshen
	if is_opening and not visible:
		position.x = hidden_x
		
	_tween.set_parallel(true)
	_tween.tween_property(self, "position:x", target_x, 0.3)
	_tween.tween_property(self, "modulate", target_mod, 0.3)
	
	if not is_opening:
		_tween.chain().tween_callback(func(): visible = false)

func _unhandled_input(event: InputEvent) -> void:
	if _is_open and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _update_filters() -> void:
	var unique_types := {}
	for e in ActivityLog.get_entries():
		var type: String = e.get("type", "INFO").to_upper()
		unique_types[type] = true
	
	_filters = ["ALLE"]
	for t in unique_types.keys():
		_filters.append(t)

func _refresh_list() -> void:
	# Clear existing
	for child in container.get_children():
		child.queue_free()
	
	var active_filter = _filters[_current_filter_idx]
	var trans_key = "activitylog.filter." + active_filter.to_lower()
	var translated = GameState.T(trans_key)
	filter_label.text = translated if translated != trans_key else active_filter.to_upper()
	
	var entries = ActivityLog.get_entries()
	for i in range(entries.size() - 1, -1, -1):
		var e = entries[i]
		var t = e.get("type", "INFO").to_upper()
		if active_filter == "ALLE" or t == active_filter:
			var inst = ENTRY_SCENE.instantiate() as ActivityLogEntry
			container.add_child(inst)
			inst.setup(e)

func _on_entry_added(_entry: Dictionary) -> void:
	if _is_open:
		_update_filters()
		_refresh_list()
		# Optionally scroll to top or bottom? We insert at top (iterating backwards)

func _on_btn_prev_pressed() -> void:
	_current_filter_idx -= 1
	if _current_filter_idx < 0:
		_current_filter_idx = _filters.size() - 1
	_refresh_list()

func _on_btn_next_pressed() -> void:
	_current_filter_idx += 1
	if _current_filter_idx >= _filters.size():
		_current_filter_idx = 0
	_refresh_list()

func _on_animation_player_animation_finished(anim_name: String) -> void:
	if anim_name == "slide_out":
		visible = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			accept_event()
