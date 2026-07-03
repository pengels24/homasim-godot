extends PanelContainer
class_name RoomStatusIndicator

@onready var icon_clean: TextureRect = %IconClean
@onready var icon_repair: TextureRect = %IconRepair
@onready var icon_demolish: TextureRect = %IconDemolish
@onready var icon_unstaffed: TextureRect = %IconUnstaffed
@onready var progress_bar: ProgressBar = %Progress

func _ready() -> void:
	hide()
	progress_bar.hide()
	
	icon_clean.tooltip_text = "Reinigung angefordert"
	icon_clean.mouse_filter = Control.MOUSE_FILTER_PASS
	
	icon_repair.tooltip_text = "Wartung angefordert"
	icon_repair.mouse_filter = Control.MOUSE_FILTER_PASS
	
	icon_demolish.tooltip_text = "Zum Abriss markiert"
	icon_demolish.mouse_filter = Control.MOUSE_FILTER_PASS

	if icon_unstaffed:
		icon_unstaffed.tooltip_text = "Unterbesetzt"
		icon_unstaffed.mouse_filter = Control.MOUSE_FILTER_PASS

func set_status(needs_cleaning: bool, needs_repair: bool, pending_demolish: bool = false, staff_status: int = 0) -> void:
	if not is_node_ready():
		await ready

	if not needs_cleaning and not needs_repair and not pending_demolish and staff_status == 0:
		hide()
		return
		
	show()
	icon_clean.visible = needs_cleaning
	icon_repair.visible = needs_repair
	icon_demolish.visible = pending_demolish
	if icon_unstaffed:
		icon_unstaffed.visible = (staff_status > 0)
		if staff_status == 1:
			icon_unstaffed.modulate = Color(1.0, 0.5, 0.0)
			icon_unstaffed.tooltip_text = "Unterbesetzt"
		elif staff_status == 2:
			icon_unstaffed.modulate = Color(0.89, 0.1, 0.1)
			icon_unstaffed.tooltip_text = "Kein Personal"
	
	size = Vector2.ZERO

var _active_progress: Dictionary = {}

func set_progress(worker_id: String, value: float) -> void:
	## value: 0.0 (start) bis 1.0 (fertig)
	if not is_node_ready(): await ready
	show()
	
	_active_progress[worker_id] = value
	var max_val = 0.0
	for v in _active_progress.values():
		if v > max_val: max_val = v
		
	progress_bar.visible = true
	progress_bar.value = clampf(max_val * 100.0, 0.0, 100.0)
	size = Vector2.ZERO

func hide_progress(worker_id: String) -> void:
	if not is_node_ready(): await ready
	
	_active_progress.erase(worker_id)
	if _active_progress.is_empty():
		progress_bar.visible = false
		progress_bar.value = 0.0
	
	size = Vector2.ZERO
