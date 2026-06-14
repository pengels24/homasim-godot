extends PanelContainer
class_name RoomStatusIndicator

@onready var icon_clean: TextureRect = %IconClean
@onready var icon_repair: TextureRect = %IconRepair

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
