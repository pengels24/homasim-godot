extends PanelContainer
class_name RoomStatusIndicator

@onready var icon_clean: TextureRect = %IconClean
@onready var icon_repair: TextureRect = %IconRepair
@onready var progress_bar: ProgressBar = %Progress

func _ready() -> void:
	hide()

func set_status(needs_cleaning: bool, needs_repair: bool) -> void:
	if not is_node_ready():
		await ready

	if not needs_cleaning and not needs_repair:
		hide()
		return
		
	show()
	icon_clean.visible = needs_cleaning
	icon_repair.visible = needs_repair

func set_progress(value: float) -> void:
	## value: 0.0 (start) bis 1.0 (fertig)
	if not is_node_ready(): await ready
	show()
	progress_bar.visible = true
	progress_bar.value = clampf(value * 100.0, 0.0, 100.0)

func hide_progress() -> void:
	if not is_node_ready(): await ready
	progress_bar.visible = false
	progress_bar.value = 0.0
