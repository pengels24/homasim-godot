extends PanelContainer

@onready var lbl_stats = $MarginContainer/LabelStats

var _update_timer: float = 0.0

func _ready() -> void:
	SettingsManager.sig_tech_info_toggled.connect(_on_tech_info_toggled)
	visible = SettingsManager.show_tech_info
	set_process(visible)

func _on_tech_info_toggled(is_visible: bool) -> void:
	visible = is_visible
	set_process(is_visible)
	if is_visible:
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
