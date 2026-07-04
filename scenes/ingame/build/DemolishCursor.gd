extends Node2D
class_name DemolishCursor

signal sig_cancelled()

var _map_grid: Node2D
var _target_room: Node2D = null

func activate(map_grid: Node2D) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_map_grid = map_grid
	Input.set_custom_mouse_cursor(load("res://assets/icons/HUDBottom/hammer.svg"))
	
func _process(_delta: float) -> void:
	if not is_instance_valid(_map_grid):
		return
		
	var mouse_world = get_global_mouse_position()
	var room = _get_room_at_world_pos(mouse_world)
	
	if room != _target_room:
		if is_instance_valid(_target_room) and _target_room.has_method("set_highlight"):
			_target_room.set_highlight(false)
			
		_target_room = room
		
		if is_instance_valid(_target_room) and _target_room.has_method("set_highlight"):
			var is_occupied = _map_grid.guest_manager and _map_grid.guest_manager.get_party_in_room(_target_room) != null
			var is_pending = _target_room.get("is_pending_demolish")
			
			if is_pending:
				_target_room.set_highlight(true, Color(0.5, 0.5, 0.5, 0.8)) # Gray
			elif is_occupied:
				_target_room.set_highlight(true, Color(1.0, 0.0, 0.0, 0.9)) # Red
			else:
				_target_room.set_highlight(true, Color(0.0, 1.0, 0.0, 0.9)) # Green

func _get_room_at_world_pos(world_pos: Vector2) -> Node2D:
	for room in _map_grid.active_rooms:
		if not is_instance_valid(room): continue
		var local_pos = room.to_local(world_pos)
		var sz = room.get_tile_size()
		var rect = Rect2(0, 0, sz.x * 16, sz.y * 16)
		if rect.has_point(local_pos):
			return room
	return null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			_try_demolish()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				_rmb_pressed_pos = mb.position
			else:
				if mb.position.distance_to(_rmb_pressed_pos) < 5.0:
					_cancel()
			
	elif event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo and ke.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_cancel()

func _cancel() -> void:
	if is_instance_valid(_target_room) and _target_room.has_method("set_highlight"):
		_target_room.set_highlight(false)
	Input.set_custom_mouse_cursor(null)
	sig_cancelled.emit()
	queue_free()

func _try_demolish() -> void:
	if not is_instance_valid(_target_room):
		return
		
	var room = _target_room
	if room.get("room_type_id") == "lobby":
		if is_instance_valid(Toast):
			Toast.show(GameState.T("toast.room.lobby_no_demolish"))
		return
		
	if room.get("is_pending_demolish"):
		if is_instance_valid(Toast):
			Toast.show(GameState.T("toast.room.already_demolish"))
		return
		
	var is_occupied = _map_grid.guest_manager and _map_grid.guest_manager.get_party_in_room(room) != null
	
	var def = {}
	if room.has_method("get_definition"):
		def = room.get_definition()
	var room_name = GameState.T(def.get("name", "Zimmer"))
	var room_number = room.get("room_number")
	if room_number and str(room_number) != "":
		room_name += " " + str(room_number)
	var cost = def.get("build_cost", 0)
	var refund_multi = GameState.selected_hotel.get("refund_multiplier", 0.5) if GameState.selected_hotel else 0.5
	var refund = int(cost * refund_multi)
	
	var confirm_scene = load("res://scenes/shared/ConfirmModal.tscn")
	var confirm = confirm_scene.instantiate()
	var ui_root = _map_grid.get_parent().get_node("HUD")
	ui_root.add_child(confirm)
	
	if is_occupied:
		confirm.confirmed.connect(func():
			room.set("is_pending_demolish", true)
			if is_instance_valid(Toast): Toast.show(room_name + " für Abriss vorgemerkt.")
			confirm.queue_free()
		)
		confirm.cancelled.connect(func(): confirm.queue_free())
		confirm.ask("Abriss vormerken?", "%s ist aktuell belegt!\nFür automatischen Abriss nach Abreise der Gäste vormerken?" % room_name, "Vormerken")
	else:
		confirm.confirmed.connect(func():
			var refund_pos = room.global_position + Vector2(16, 16)
			if refund > 0:
				if FinanceManager: FinanceManager.add_transaction(refund, "construction", "tx.demolish|" + GameState.T(def.get("name", "Raum")))
				if EffectManager: EffectManager.spawn_money_text(refund, refund_pos)
				
			_map_grid.remove_room(room)
			
			if _target_room == room:
				_target_room = null
			confirm.queue_free()
		)
		confirm.cancelled.connect(func(): confirm.queue_free())
		confirm.ask("Zimmer abreißen?", "Möchtest du %s wirklich abreißen?\nDu erhältst %d € zurück." % [room_name, refund])
