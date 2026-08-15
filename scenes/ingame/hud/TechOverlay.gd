extends PanelContainer

@onready var lbl_stats = $MarginContainer/LabelStats

var _update_timer: float = 0.0
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	SettingsManager.sig_tech_info_toggled.connect(_on_tech_info_toggled)
	visible = SettingsManager.show_tech_info
	set_process(visible)

func _on_tech_info_toggled(show_tech: bool) -> void:
	visible = show_tech
	set_process(show_tech)
	if show_tech:
		_update_stats()

func _process(delta: float) -> void:
	_update_timer -= delta
	if _update_timer <= 0.0:
		_update_timer = 0.5
		_update_stats()

func _update_stats() -> void:
	var fps := Engine.get_frames_per_second()
	var mem_mb := OS.get_static_memory_usage() / 1024.0 / 1024.0
	var draws := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var objs := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var cpu_ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var phys_ms := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	
	var text = "FPS: %d\nRAM: %.1f MB\nDraw Calls: %d\nNodes: %d\nCPU: %.2f ms\nPhys: %.2f ms" % [fps, mem_mb, draws, objs, cpu_ms, phys_ms]
	lbl_stats.text = text

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_drag_offset = global_position - get_global_mouse_position()
				get_viewport().set_input_as_handled()
			else:
				_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		var new_pos = get_global_mouse_position() + _drag_offset
		var vp = get_viewport_rect().size
		new_pos.x = clamp(new_pos.x, 0, max(0, vp.x - size.x))
		new_pos.y = clamp(new_pos.y, 0, max(0, vp.y - size.y))
		global_position = new_pos
		get_viewport().set_input_as_handled()
