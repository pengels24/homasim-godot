extends PanelContainer
class_name RoomStatusIndicator

@onready var icon_clean: TextureRect = %IconClean
@onready var icon_repair: TextureRect = %IconRepair
@onready var icon_demolish: TextureRect = %IconDemolish
@onready var progress_bar: ProgressBar = %Progress

func _ready() -> void:
	hide()
	progress_bar.hide()

func set_status(needs_cleaning: bool, needs_repair: bool, pending_demolish: bool = false) -> void:
	if not is_node_ready():
		await ready

	if not needs_cleaning and not needs_repair and not pending_demolish:
		hide()
		return
		
	show()
	icon_clean.visible = needs_cleaning
	icon_repair.visible = needs_repair
	icon_demolish.visible = pending_demolish
	
	size = Vector2.ZERO

func set_progress(value: float) -> void:
	## value: 0.0 (start) bis 1.0 (fertig)
	if not is_node_ready(): await ready
	show()
	progress_bar.visible = true
	progress_bar.value = clampf(value * 100.0, 0.0, 100.0)
	size = Vector2.ZERO

func hide_progress() -> void:
	if not is_node_ready(): await ready
	progress_bar.visible = false
	progress_bar.value = 0.0
	size = Vector2.ZERO
