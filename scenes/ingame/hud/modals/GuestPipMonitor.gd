extends Control

@onready var handle = %DragHandle
@onready var btn_close = %BtnClose
@onready var label_title = %Label
@onready var pip_camera = %PipCamera
@onready var lbl_status = %LblStatus
@onready var lbl_sat = %LblSat
@onready var lbl_hunger: Label = %LblHunger
@onready var lbl_thirst: Label = %LblThirst
@onready var lbl_energy: Label = %LblEnergy
@onready var lbl_fun: Label = %LblFun
@onready var lbl_patience: Label = %LblPatience
@onready var need_hunger: ProgressBar = %NeedHunger
@onready var need_thirst: ProgressBar = %NeedThirst
@onready var need_energy: ProgressBar = %NeedEnergy
@onready var need_fun: ProgressBar = %NeedFun
@onready var need_patience: ProgressBar = %NeedPatience
@onready var panel = %MenuPanel

var _target_guest: GuestActor = null
var _dragging = false
var _drag_offset = Vector2()
var _group_siblings = {}
var _update_timer = 0.0

func _ready() -> void:
	handle.gui_input.connect(_on_handle_input)
	handle.mouse_default_cursor_shape = Control.CURSOR_DRAG
	btn_close.pressed.connect(close)
	label_title.add_theme_font_size_override("font_size", 18)
	
	size = panel.size
	
	_refresh_details()

func get_target_guest() -> Node2D:
	return _target_guest

func setup(guest: GuestActor) -> void:
	_target_guest = guest
	pip_camera.set_target(guest)
	
	var member = _target_guest.get("_guest_member")
	if member:
		label_title.text = "  ::: " + member.name
	else:
		label_title.text = "  ::: Gast"
		
	_refresh_details()
	
func _process(delta: float) -> void:
	if not is_instance_valid(_target_guest):
		close()
		return
		
	_update_timer += delta
	if _update_timer >= 0.5:
		_update_timer = 0.0
		_refresh_details()
		
func _refresh_details() -> void:
	if not is_instance_valid(_target_guest):
		return
		
	var member = _target_guest.get("_guest_member")
	if member:
		var sat = int(member.satisfaction) if "satisfaction" in member else 100
		var emoji = "🙂"
		if sat > 80: emoji = "😁"
		elif sat > 50: emoji = "🙂"
		elif sat > 25: emoji = "😐"
		else: emoji = "😠"
		lbl_sat.text = GameState.T("guest.tooltip.satisfaction") % [sat, emoji]
		
		var c = Color.GREEN
		if sat < 25: c = Color.RED
		elif sat < 50: c = Color.ORANGE
		elif sat < 80: c = Color.YELLOW
		lbl_sat.add_theme_color_override("font_color", c)
		
		var sat_hunger = int(member.saturation) if "saturation" in member else 100
		var sat_thirst = int(member.thirst) if "thirst" in member else 100
		var sat_energy = int(member.energy) if "energy" in member else 100
		var sat_fun = int(member.fun) if "fun" in member else 100
		
		# Calculate patience based on current wait state
		var patience_val = 100
		if _target_guest.current_state == GuestActor.State.WAITING_FOR_FOOD:
			var wait_limit = GuestActor.FOOD_WAIT_TIME_MINUTES * (float(TimeManager.SECONDS_PER_GAME_MINUTE) if TimeManager else 1.0)
			if TechtreeManager and TechtreeManager.is_tech_unlocked("M1.4"):
				wait_limit *= 1.2
			var ratio = _target_guest._waiting_for_food_timer / wait_limit
			patience_val = int(clamp(100 - (ratio * 100.0), 0, 100))
		elif _target_guest.current_state in [GuestActor.State.AWAITING_CHECKOUT, GuestActor.State.WAITING_IN_LINE]:
			var imp_limit = 120.0
			if TechtreeManager and TechtreeManager.is_tech_unlocked("M1.4"):
				imp_limit = 144.0
			# Zeige die Geduld relativ zu 5 Ticks (600 Ingame-Sekunden = 10 Ingame-Minuten), dann ist sie optisch leer
			# und ab dann ploppt das Wütend-Icon auf (da Satisfaction weiter sinkt)
			var max_visual_wait = imp_limit * 5.0 
			var timer_val = _target_guest.get("_total_wait_timer")
			if typeof(timer_val) == TYPE_NIL: timer_val = 0.0
			var ratio = timer_val / max_visual_wait
			patience_val = int(clamp(100 - (ratio * 100.0), 0, 100))
		
		if is_instance_valid(need_hunger): need_hunger.value = sat_hunger
		if is_instance_valid(need_thirst): need_thirst.value = sat_thirst
		if is_instance_valid(need_energy): need_energy.value = sat_energy
		if is_instance_valid(need_fun): need_fun.value = sat_fun
		if is_instance_valid(need_patience): need_patience.value = patience_val
		
		if is_instance_valid(lbl_hunger): lbl_hunger.text = GameState.T("need.hunger.short", "HU") + ": %d%%" % sat_hunger
		if is_instance_valid(lbl_thirst): lbl_thirst.text = GameState.T("need.thirst.short", "DU") + ": %d%%" % sat_thirst
		if is_instance_valid(lbl_energy): lbl_energy.text = GameState.T("need.energy.short", "EN") + ": %d%%" % sat_energy
		if is_instance_valid(lbl_fun): lbl_fun.text = GameState.T("need.fun.short", "SP") + ": %d%%" % sat_fun
		if is_instance_valid(lbl_patience): lbl_patience.text = "PA: %d%%" % patience_val
	else:
		lbl_sat.text = "Zufriedenheit: Unbekannt"
		
	# Status Text
	var state = _target_guest.current_state
	var t = GameState.T("guest.tooltip.target")
	if state == GuestActor.State.IN_ROOM:
		t += GameState.T("guest.tooltip.room")
	elif state == GuestActor.State.IN_POI:
		t += GameState.T("roomdef.name.long." + _target_guest._current_poi_id)
	elif state == GuestActor.State.WALKING:
		if _target_guest.get("_is_checkout_walk"):
			t += GameState.T("guest.tooltip.walking_reception")
		elif _target_guest._current_poi_id != "" and _target_guest._current_poi_id != "room":
			t += GameState.T("guest.tooltip.walking_poi") % GameState.T("roomdef.name.long." + _target_guest._current_poi_id)
		else:
			t += GameState.T("guest.tooltip.walking_room")
	elif state == GuestActor.State.AWAITING_CHECKOUT:
		t += GameState.T("guest.tooltip.reception")
	elif state == GuestActor.State.LEAVING:
		t += GameState.T("guest.tooltip.leaving")
	else:
		t += GameState.T("guest.tooltip.waiting")
		
	lbl_status.text = t
		
func close() -> void:
	pip_camera.set_target(null) # Cleanup signal connections
	queue_free()

func _on_handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				move_to_front()
				_dragging = true
				_drag_offset = get_global_mouse_position() - global_position
				_group_siblings.clear()
				if Input.is_key_pressed(KEY_SHIFT):
					_collect_group_siblings()
			else:
				_dragging = false
				_group_siblings.clear()
	elif event is InputEventMouseMotion and _dragging:
		var new_pos = get_global_mouse_position() - _drag_offset
		if _group_siblings.is_empty():
			global_position = _clamp_to_screen(_apply_snapping(new_pos))
		else:
			# Gruppe verschieben: kein Snapping damit sich die Gruppe nicht selbst bekämpft
			var delta = _clamp_to_screen(new_pos) - global_position
			global_position += delta
			for sibling in _group_siblings:
				if is_instance_valid(sibling):
					sibling.global_position = _clamp_to_screen(sibling.global_position + delta)

func _collect_group_siblings() -> void:
	for sibling in get_parent().get_children():
		if sibling == self or not sibling.name.ends_with("Monitor"):
			continue
		if not is_instance_valid(sibling):
			continue
		if _is_touching(sibling):
			_group_siblings[sibling] = sibling.global_position - global_position

func _is_touching(sibling: Node) -> bool:
	var s_panel = sibling.get_node_or_null("%MenuPanel")
	if not s_panel: return false
	var my_r = Rect2(global_position, size)
	var s_r  = Rect2(sibling.global_position, s_panel.size)
	return my_r.grow(SNAP_DIST * 1.5).intersects(s_r)

func _clamp_to_screen(pos: Vector2) -> Vector2:
	var screen = get_viewport().get_visible_rect().size
	const HANDLE_H := 32.0
	var clamped_x = clamp(pos.x, 0.0, screen.x - size.x)
	var clamped_y = clamp(pos.y, 0.0, screen.y - HANDLE_H)
	return Vector2(clamped_x, clamped_y)

const SNAP_DIST := 15.0

func _apply_snapping(new_pos: Vector2) -> Vector2:
	var my_size = size
	var my_left   = new_pos.x
	var my_right  = new_pos.x + my_size.x
	var my_top    = new_pos.y
	var my_bottom = new_pos.y + my_size.y
	
	var snap_x: float = new_pos.x
	var snap_y: float = new_pos.y
	var best_dx := INF
	var best_dy := INF
	
	for sibling in get_parent().get_children():
		if sibling == self or not sibling.name.ends_with("Monitor"):
			continue
		if not is_instance_valid(sibling):
			continue
		
		var s_panel = sibling.get_node_or_null("%MenuPanel")
		if not s_panel:
			continue
		
		var s_pos  = sibling.global_position
		var s_size = s_panel.size
		var s_left   = s_pos.x
		var s_right  = s_pos.x + s_size.x
		var s_top    = s_pos.y
		var s_bottom = s_pos.y + s_size.y
		
		var dx = abs(my_right - s_left)
		if dx < SNAP_DIST and dx < best_dx:
			best_dx = dx
			snap_x = s_left - my_size.x
		dx = abs(my_left - s_right)
		if dx < SNAP_DIST and dx < best_dx:
			best_dx = dx
			snap_x = s_right
		dx = abs(my_left - s_left)
		if dx < SNAP_DIST and dx < best_dx:
			best_dx = dx
			snap_x = s_left
		dx = abs(my_right - s_right)
		if dx < SNAP_DIST and dx < best_dx:
			best_dx = dx
			snap_x = s_right - my_size.x
			
		var dy = abs(my_bottom - s_top)
		if dy < SNAP_DIST and dy < best_dy:
			best_dy = dy
			snap_y = s_top - my_size.y
		dy = abs(my_top - s_bottom)
		if dy < SNAP_DIST and dy < best_dy:
			best_dy = dy
			snap_y = s_bottom
		dy = abs(my_top - s_top)
		if dy < SNAP_DIST and dy < best_dy:
			best_dy = dy
			snap_y = s_top
		dy = abs(my_bottom - s_bottom)
		if dy < SNAP_DIST and dy < best_dy:
			best_dy = dy
			snap_y = s_bottom - my_size.y
			
	return Vector2(snap_x, snap_y)
