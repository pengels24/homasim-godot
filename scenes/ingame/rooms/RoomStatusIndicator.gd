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
	
	icon_clean.tooltip_text = GameState.T("ui.room.cleaning_requested", "Reinigung angefordert")
	icon_clean.mouse_filter = Control.MOUSE_FILTER_PASS
	
	icon_repair.tooltip_text = GameState.T("ui.room.maintenance_requested", "Wartung angefordert")
	icon_repair.mouse_filter = Control.MOUSE_FILTER_PASS
	
	icon_demolish.tooltip_text = GameState.T("ui.room.pending_demolish", "Zum Abriss markiert")
	icon_demolish.mouse_filter = Control.MOUSE_FILTER_PASS

	if icon_unstaffed:
		icon_unstaffed.tooltip_text = GameState.T("ui.room.understaffed_tooltip", "Unterbesetzt")
		icon_unstaffed.mouse_filter = Control.MOUSE_FILTER_PASS
		if not icon_unstaffed.gui_input.is_connected(_on_icon_unstaffed_gui_input):
			icon_unstaffed.gui_input.connect(_on_icon_unstaffed_gui_input)
		
	_set_visibility_layer_recursive(self, 2)

func _set_visibility_layer_recursive(node: Node, layer: int) -> void:
	if node is CanvasItem:
		node.visibility_layer = layer
	for child in node.get_children():
		_set_visibility_layer_recursive(child, layer)

func set_status(needs_cleaning: bool, needs_repair: bool, pending_demolish: bool = false, staff_status: int = 0, cleaning_requested: bool = false, repair_requested: bool = false, is_critical_clean: bool = false, is_critical_repair: bool = false) -> void:
	if not is_node_ready():
		await ready

	if _forced_clean_workers.size() > 0:
		needs_cleaning = true
		cleaning_requested = true

	icon_clean.visible = needs_cleaning
	icon_repair.visible = needs_repair
	icon_demolish.visible = pending_demolish
	if icon_unstaffed:
		icon_unstaffed.visible = (staff_status > 0)

	if not needs_cleaning and not needs_repair and not pending_demolish and staff_status == 0:
		# Wenn wir KEINEN Progress-Bar haben, können wir uns verstecken
		if _active_progress.is_empty():
			hide()
		return
		
	show()
	
	if cleaning_requested:
		icon_clean.modulate = Color("2d863e") # Gruen, analog zum Tooltip-Progress
		icon_clean.tooltip_text = GameState.T("ui.room.cleaning_requested", "Reinigung angefordert")
	elif is_critical_clean:
		icon_clean.modulate = Color(0.89, 0.1, 0.1) # Rot (Kritisch)
		icon_clean.tooltip_text = GameState.T("ui.room.cleaning_critical", "Reinigung dringend nötig")
	else:
		icon_clean.modulate = Color("e3ae08") # Gold/Gelb (Aufgabe offen)
		icon_clean.tooltip_text = GameState.T("ui.room.cleaning_required", "Reinigung erforderlich")
		
	if repair_requested:
		icon_repair.modulate = Color("2d863e") # Gruen
		icon_repair.tooltip_text = GameState.T("ui.room.maintenance_requested", "Wartung angefordert")
	elif is_critical_repair:
		icon_repair.modulate = Color(0.89, 0.1, 0.1) # Rot (Kritisch)
		icon_repair.tooltip_text = GameState.T("ui.room.maintenance_critical", "Wartung dringend nötig")
	else:
		icon_repair.modulate = Color("e3ae08") # Gold/Gelb
		icon_repair.tooltip_text = GameState.T("ui.room.maintenance_required", "Wartung erforderlich")

	if icon_unstaffed and staff_status > 0:
		if staff_status == 1:
			icon_unstaffed.modulate = Color(1.0, 0.5, 0.0)
			icon_unstaffed.tooltip_text = GameState.T("ui.room.understaffed_tooltip", "Unterbesetzt")
			icon_unstaffed.mouse_default_cursor_shape = Control.CURSOR_ARROW
		elif staff_status == 2:
			icon_unstaffed.modulate = Color(0.89, 0.1, 0.1)
			icon_unstaffed.tooltip_text = GameState.T("ui.room.unstaffed_tooltip", "Kein Personal (Klick für Zuweisung)")
			icon_unstaffed.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	size = Vector2.ZERO

func _on_icon_unstaffed_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if icon_unstaffed.modulate.is_equal_approx(Color(0.89, 0.1, 0.1)):
			if InputHandler.current_mode == InputHandler.InputMode.NORMAL:
				get_viewport().set_input_as_handled()
				var ingame = get_tree().current_scene
				if is_instance_valid(ingame) and ingame.name == "Ingame":
					var ui_mgr = ingame.get("_ui_mgr")
					if is_instance_valid(ui_mgr) and ui_mgr.has_method("open_staff"):
						ui_mgr.open_staff(2)

var _active_progress: Dictionary = {}
var _forced_clean_workers: Array[String] = []

func set_progress(worker_id: String, value: float, force_clean: bool = false) -> void:
	## value: 0.0 (start) bis 1.0 (fertig)
	if not is_node_ready(): await ready
	show()
	
	if force_clean and not worker_id in _forced_clean_workers:
		_forced_clean_workers.append(worker_id)
		
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
	_forced_clean_workers.erase(worker_id)
	if _active_progress.is_empty():
		progress_bar.visible = false
		progress_bar.value = 0.0
		
		var has_icons = icon_clean.visible or icon_repair.visible or icon_demolish.visible or (icon_unstaffed and icon_unstaffed.visible)
		if not has_icons:
			hide()
	
	size = Vector2.ZERO
