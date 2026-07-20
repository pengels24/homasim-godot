extends Control
class_name RoomContextMenu

@onready var panel = %MenuPanel
@onready var handle = %DragHandle
@onready var btn_close = %BtnClose
@onready var btn_details = %BtnDetails
@onready var btn_service = %BtnService
@onready var btn_demolish = %BtnDemolish

var _target_room: Node2D = null
var _dragging = false
var _drag_offset = Vector2.ZERO
var btn_repair: Button
var btn_wlan: Button
var btn_klima: Button

# =============================================================================
func _ready() -> void:
	# Fullscreen click out blocker
	gui_input.connect(_on_bg_input)
	
	# Drag logic
	handle.gui_input.connect(_on_handle_input)
	handle.mouse_default_cursor_shape = Control.CURSOR_DRAG
	
	# Translations
	handle.get_node("Label").text = GameState.T("room.action.title")
	btn_details.text = GameState.T("room.action.details")
	btn_service.text = GameState.T("room.action.service")
	btn_demolish.text = GameState.T("room.action.demolish_btn")
	
	# Buttons
	btn_close.pressed.connect(close)
	btn_details.pressed.connect(_on_details_pressed)
	btn_service.pressed.connect(_on_service_pressed)
	
	btn_repair = btn_service.duplicate()
	btn_repair.text = GameState.T("room.action.maintenance")
	btn_service.get_parent().add_child(btn_repair)
	btn_repair.pressed.connect(_on_repair_pressed)
	
	btn_wlan = btn_service.duplicate()
	btn_wlan.text = "WLAN (50$)"
	btn_service.get_parent().add_child(btn_wlan)
	btn_wlan.pressed.connect(_on_wlan_pressed)
	
	btn_klima = btn_service.duplicate()
	btn_klima.text = "Klima (150$)"
	btn_service.get_parent().add_child(btn_klima)
	btn_klima.pressed.connect(_on_klima_pressed)
	
	# Demolish button ans Ende verschieben
	btn_demolish.get_parent().move_child(btn_demolish, -1)
	btn_demolish.pressed.connect(_on_demolish_pressed)
	
	hide()
	GameState.sig_room_clicked.connect(open)

# =============================================================================
# ANG-212 Fix: Kein direktes Wert-Setzen mehr. Einfach Signal emittieren,
# TaskManager erstellt das Ticket, Staff laeuft wirklich hin.
func _on_service_pressed() -> void:
	if is_instance_valid(_target_room):
		if _target_room.get("is_service_requested"):
			Toast.show(GameState.T("toast.room.service_active"), "build")
		else:
			if GameState.selected_hotel.get("level", 1) < GameState.UNLOCK_LEVELS.get("staff", 2):
				Toast.show(GameState.T("toast.room.staff_locked"), "personal")
			else:
				_target_room.set("is_service_requested", true)
				if _target_room.has_method("_update_indicator"):
					_target_room.call("_update_indicator")
				GameState.sig_room_needs_cleaning.emit(_target_room)
				
				var has_hk = false
				if StaffManager:
					for s in StaffManager.hired_staff.values():
						if s.get("role", "") == "housekeeping":
							has_hk = true
							break
							
				if not has_hk:
					Toast.show(GameState.T("toast.room.service_no_staff"), "personal")
				else:
					Toast.show(GameState.T("toast.room.service_requested"), "build")
	close()

# =============================================================================
func open(room: Node2D) -> void:
	if InputHandler.current_mode != InputHandler.InputMode.NORMAL:
		return
	# ANG-211: Lobby ist Systemraum – kein Aktionsmenü
	if room.get("room_type_id") == "lobby":
		return
		
	_target_room = room
	if _target_room.has_method("set_highlight"):
		_target_room.set_highlight(true)
		
	var is_pending = _target_room.get("is_pending_demolish")
	if is_pending == null:
		is_pending = false
	btn_service.disabled = is_pending
	if is_instance_valid(btn_repair):
		btn_repair.disabled = is_pending
		
	btn_wlan.visible = false
	btn_klima.visible = false
	if _target_room.has_method("has_trait"):
		var has_wlan = GameState.techtree.get("tech_wlan", false) or (TechtreeManager and TechtreeManager.is_unlocked("Z1.4"))
		if has_wlan and not _target_room.has_trait("wlan"):
			btn_wlan.visible = true
			btn_wlan.disabled = is_pending
			
		var has_klima = GameState.techtree.get("tech_klima", false) or (TechtreeManager and TechtreeManager.is_unlocked("Z1.5"))
		if has_klima and not _target_room.has_trait("klima"):
			btn_klima.visible = true
			btn_klima.disabled = is_pending
	
	var canvas_trans = room.get_global_transform_with_canvas()
	var pos_on_screen = canvas_trans.origin
	var sz = room.get_tile_size()
	var width_on_screen = sz.x * 16 * canvas_trans.get_scale().x
	
	# Start-Position: Links daneben
	var start_x = pos_on_screen.x - 220
	if start_x < 0:
		start_x = pos_on_screen.x + width_on_screen + 20
		
	var p_height = max(panel.size.y, 250.0)
	var final_y = pos_on_screen.y
	if final_y + p_height > size.y - 20:
		final_y = size.y - p_height - 20
		
	panel.position = Vector2(start_x, final_y)
	
	show()
	# Blockiere andere Inputs
	InputHandler.current_mode = InputHandler.InputMode.MODAL

# =============================================================================
func close() -> void:
	if is_instance_valid(_target_room) and _target_room.has_method("set_highlight"):
		_target_room.set_highlight(false)
		
	hide()
	if InputHandler.current_mode == InputHandler.InputMode.MODAL:
		InputHandler.current_mode = InputHandler.InputMode.NORMAL

# =============================================================================
func _on_details_pressed() -> void:
	if is_instance_valid(_target_room) and _target_room.has_method("get_live_details"):
		# Prüfen ob bereits ein Monitor für diesen Raum offen ist -> dann nach vorne bringen statt neu spawnen
		for existing in get_parent().get_children():
			if existing.has_method("get_target_room") and existing.get_target_room() == _target_room:
				existing.move_to_front()
				close()
				return
		
		var monitor_scene = load("res://scenes/ingame/hud/modals/RoomDetailsMonitor.tscn")
		var monitor = monitor_scene.instantiate()
		get_parent().add_child(monitor)
		
		# Mittig im Viewport platzieren, leicht versetzt damit mehrere Fenster nicht genau übereinander liegen
		var screen_size = get_viewport().get_visible_rect().size
		var spawn_x = screen_size.x * 0.5 - 150 + randf_range(-20, 20)
		var spawn_y = screen_size.y * 0.3 + randf_range(-20, 20)
		monitor.global_position = Vector2(spawn_x, spawn_y)
		monitor.setup(_target_room)
	else:
		if is_instance_valid(Toast):
			Toast.show(GameState.T("room.action.details") + ": " + GameState.T("room.action.coming_soon"), "info", false)
	close()

func _on_action(action_name: String) -> void:
	if is_instance_valid(Toast):
		Toast.show(action_name + ": " + GameState.T("room.action.coming_soon"), "info", false)
	close()

# =============================================================================
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_escape"):
		get_viewport().set_input_as_handled()
		close()

# =============================================================================
func _on_bg_input(event: InputEvent) -> void:
	# Klick außerhalb des Panels
	if event is InputEventMouseButton and event.pressed:
		close()

# =============================================================================
func _on_handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_offset = event.global_position - panel.global_position
		else:
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		panel.global_position = event.global_position - _drag_offset

# =============================================================================
# ANG-212 Fix: Kein direktes Wert-Setzen mehr fuer Wartung.
func _on_repair_pressed() -> void:
	if is_instance_valid(_target_room):
		if _target_room.get("is_repair_requested"):
			Toast.show(GameState.T("toast.room.repair_active"), "build")
		else:
			if GameState.selected_hotel.get("level", 1) < GameState.UNLOCK_LEVELS.get("staff", 2):
				Toast.show(GameState.T("toast.room.staff_locked"), "personal")
			else:
				_target_room.set("is_repair_requested", true)
				if _target_room.has_method("_update_indicator"):
					_target_room.call("_update_indicator")
				GameState.sig_room_needs_repair.emit(_target_room)
				
				var has_mt = false
				if StaffManager:
					for s in StaffManager.hired_staff.values():
						if s.get("role", "") == "maintenance":
							has_mt = true
							break
							
				if not has_mt:
					Toast.show(GameState.T("toast.room.repair_no_staff"), "personal")
				else:
					Toast.show(GameState.T("toast.room.repair_requested"), "build")
	close()

# =============================================================================
func _on_demolish_pressed() -> void:
	if not is_instance_valid(_target_room):
		close()
		return
		
	var room = _target_room
	if room.get("room_type_id") == "lobby":
		if is_instance_valid(Toast): Toast.show(GameState.T("toast.room.lobby_no_demolish"), "build", false)
		close()
		return
		
	if room.get("is_pending_demolish"):
		if is_instance_valid(Toast): Toast.show(GameState.T("toast.room.already_demolish"), "build", false)
		close()
		return
		
	var map_grid = room.get_parent().get_parent().get_parent().get_parent()
	if not map_grid or not map_grid.has_method("remove_room"):
		close()
		return
		
	var is_occupied = map_grid.guest_manager and map_grid.guest_manager.get_party_in_room(room) != null
	
	var def = {}
	if room.has_method("get_definition"):
		def = room.get_definition()
	var room_name = GameState.T(def.get("name", "Zimmer"))
	var room_number = room.get("room_number")
	if room_number and str(room_number) != "":
		room_name += " " + str(room_number)
	var cost = def.get("build_cost", 0)
	var refund = int(cost * 0.5)
	
	var confirm_scene = load("res://scenes/shared/ConfirmModal.tscn")
	var confirm = confirm_scene.instantiate()
	var ui_root = map_grid.get_parent().get_node("HUD")
	ui_root.add_child(confirm)
	
	if is_occupied:
		confirm.confirmed.connect(func():
			room.set("is_pending_demolish", true)
			if is_instance_valid(Toast): Toast.show(GameState.T("room.action.demolish_queued_toast") % room_name, "build")
			confirm.queue_free()
		)
		confirm.cancelled.connect(func(): confirm.queue_free())
		confirm.ask(GameState.T("room.action.demolish_queue_title"), GameState.T("room.action.demolish_queue_desc") % room_name, GameState.T("room.action.demolish_queue_btn"))
	else:
		confirm.confirmed.connect(func():
			var refund_pos = room.global_position + Vector2(16, 16)
			if refund > 0:
				if FinanceManager: FinanceManager.add_transaction(refund, "construction", "tx.demolish|" + GameState.T(def.get("name", "Raum")))
				if EffectManager: EffectManager.spawn_money_text(refund, refund_pos)
				
			map_grid.remove_room(room)
			confirm.queue_free()
		)
		confirm.cancelled.connect(func(): confirm.queue_free())
		confirm.ask(GameState.T("room.action.demolish_title"), GameState.T("room.action.demolish_desc") % [room_name, refund])
		
	close()

# =============================================================================
func _on_wlan_pressed() -> void:
	if not is_instance_valid(_target_room): return
	var cost = 50
	if GameState.selected_hotel.get("money", 0) < cost:
		if is_instance_valid(Toast): Toast.show(GameState.T("toast.build.no_money"), "build", false)
		close()
		return
		
	if FinanceManager: FinanceManager.add_transaction(-cost, "construction", "WLAN Upgrade")
	_target_room.acquired_traits.append("wlan")
	if is_instance_valid(Toast): Toast.show("WLAN installiert!", "build")
	close()

# =============================================================================
func _on_klima_pressed() -> void:
	if not is_instance_valid(_target_room): return
	var cost = 150
	if GameState.selected_hotel.get("money", 0) < cost:
		if is_instance_valid(Toast): Toast.show(GameState.T("toast.build.no_money"), "build", false)
		close()
		return
		
	if FinanceManager: FinanceManager.add_transaction(-cost, "construction", "Klima Upgrade")
	_target_room.acquired_traits.append("klima")
	if is_instance_valid(Toast): Toast.show("Klimaanlage installiert!", "build")
	close()
