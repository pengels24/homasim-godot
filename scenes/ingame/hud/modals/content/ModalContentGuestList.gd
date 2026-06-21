extends MarginContainer
class_name ModalContentGuestList

@onready var guest_list_container: VBoxContainer = %GuestListContainer
@onready var pip_camera: PipCamera = %PipCamera
@onready var detail_name_lbl: Label = %DetailNameLabel
@onready var detail_room_lbl: Label = %DetailRoomLabel
@onready var detail_satisfaction_lbl: Label = %DetailSatisfactionLabel

var _selected_guest: GuestActor = null
var _guest_controller: GuestController = null
var _guest_manager: GuestManager = null

var _btn_group: ButtonGroup

var _active_rows: Array[Dictionary] = []
var _update_timer: float = 0.0

func _ready() -> void:
	var ingame = get_tree().get_root().get_node_or_null("Ingame")
	if ingame:
		_guest_controller = ingame.get("_guest_controller")
		_guest_manager = ingame.get("_guest_mgr")
		
	_btn_group = ButtonGroup.new()
	_populate_list()
	_clear_details()

func _populate_list() -> void:
	_active_rows.clear()
	for child in guest_list_container.get_children():
		child.queue_free()
		
	if not _guest_manager:
		return
		
	var all_parties = _guest_manager._active + _guest_manager._checkout + _guest_manager._waiting
	for party in all_parties:
		for member in party.members:
			_create_list_item(party, member)

func _create_list_item(party: GuestParty, member: GuestMember) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 44)
	btn.toggle_mode = true
	btn.button_group = _btn_group
	
	var sb_empty = StyleBoxEmpty.new()
	var sb_hover = StyleBoxFlat.new()
	sb_hover.bg_color = Color(1, 1, 1, 0.1)
	sb_hover.set_corner_radius_all(4)
	var sb_selected = StyleBoxFlat.new()
	sb_selected.bg_color = Color(0.5, 0.35, 0.05, 0.8)
	sb_selected.set_corner_radius_all(4)
	
	btn.add_theme_stylebox_override("normal", sb_empty)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_selected)
	btn.add_theme_stylebox_override("focus", sb_empty)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	margin.add_child(hbox)
	
	var font_color = Color("#CCCCCC")
	
	# Name
	var lbl_name = Label.new()
	lbl_name.text = member.name
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_name.size_flags_stretch_ratio = 2.5
	lbl_name.add_theme_color_override("font_color", font_color)
	
	# Room
	var lbl_room = Label.new()
	lbl_room.text = party.room_id if party.room_id else GameState.T("guest.state.waiting")
	lbl_room.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_room.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_room.size_flags_stretch_ratio = 1.5
	lbl_room.add_theme_color_override("font_color", font_color)
	
	# Gather live data from actor if spawned
	var actor = null
	if _guest_controller and _guest_controller._actors.has(member.id):
		actor = _guest_controller._actors[member.id]
		
	var goal_text = "---"
	var energy_val = 100.0
	
	if actor:
		# Guests don't have individual energy yet, keeping it at 100%
		var state = actor.get("current_state")
		if state == 2: # IN_ROOM
			var target_room = actor.get("_target_room")
			if is_instance_valid(target_room) and target_room.has_method("get_definition"):
				goal_text = target_room.get_definition().get("name", "Zimmer")
			else:
				goal_text = "Zimmer"
		elif state == 3: # IN_POI
			var poi_id = actor.get("_current_poi_id")
			goal_text = "Aktivität" if poi_id != "" else "POI"
		elif state == 4: # AWAITING_CHECKOUT
			goal_text = "Rezeption"
		elif state == 1: # WALKING
			if actor.get("_is_checkout_walk"):
				goal_text = "Zur Lobby"
			else:
				goal_text = "Unterwegs"
		elif state == 5: # LEAVING
			goal_text = "Abreise"
		else:
			goal_text = "-"
			
	# Goal
	var lbl_goal = Label.new()
	lbl_goal.text = goal_text
	lbl_goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_goal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_goal.size_flags_stretch_ratio = 2.0
	lbl_goal.add_theme_color_override("font_color", font_color)
	
	# Energy
	var lbl_energy = Label.new()
	lbl_energy.text = "%d%%" % int(energy_val)
	lbl_energy.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_energy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_energy.size_flags_stretch_ratio = 1.0
	if energy_val < 30:
		lbl_energy.add_theme_color_override("font_color", Color.RED)
	else:
		lbl_energy.add_theme_color_override("font_color", font_color)
		
	# Satisfaction
	var lbl_sat = Label.new()
	lbl_sat.text = "%d%%" % int(party.satisfaction)
	lbl_sat.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_sat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_sat.size_flags_stretch_ratio = 1.5
	if party.satisfaction < 30:
		lbl_sat.add_theme_color_override("font_color", Color.RED)
	elif party.satisfaction > 80:
		lbl_sat.add_theme_color_override("font_color", Color.GREEN)
	else:
		lbl_sat.add_theme_color_override("font_color", font_color)
		
	hbox.add_child(lbl_name)
	hbox.add_child(lbl_room)
	hbox.add_child(lbl_goal)
	hbox.add_child(lbl_energy)
	hbox.add_child(lbl_sat)
	
	btn.add_child(margin)
	btn.pressed.connect(_on_guest_selected.bind(party, member, btn))
	guest_list_container.add_child(btn)
	
	_active_rows.append({
		"party": party,
		"member": member,
		"lbl_goal": lbl_goal,
		"lbl_energy": lbl_energy,
		"lbl_sat": lbl_sat
	})

func _on_guest_selected(party: GuestParty, member: GuestMember, btn: Button) -> void:
	if not _guest_controller:
		return
		
	var guest_id = member.id
	if _guest_controller._actors.has(guest_id):
		_selected_guest = _guest_controller._actors[guest_id]
		pip_camera.set_target(_selected_guest)
		
		detail_name_lbl.text = member.name
		detail_room_lbl.text = "%s: %s" % [GameState.T("room"), (party.room_id if party.room_id else GameState.T("none"))]
		detail_satisfaction_lbl.text = "%s: %d%%" % [GameState.T("satisfaction"), party.satisfaction]
	else:
		_clear_details()

func _clear_details() -> void:
	_selected_guest = null
	pip_camera.set_target(null)
	detail_name_lbl.text = GameState.T("ui.guest_list.please_select", "Bitte wählen...")
	detail_room_lbl.text = ""
	detail_satisfaction_lbl.text = ""

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
		
	_update_timer -= delta
	if _update_timer <= 0.0:
		_update_timer = 1.0 # Update every second
		_refresh_live_data()

func _refresh_live_data() -> void:
	if not _guest_controller: return
	
	for row in _active_rows:
		var member = row.member
		var party = row.party
		var actor = null
		if _guest_controller._actors.has(member.id):
			actor = _guest_controller._actors[member.id]
			
		var goal_text = "---"
		var energy_val = 100.0
		
		if actor:
			var state = actor.get("current_state")
			if state == 2: # IN_ROOM
				var target_room = actor.get("_target_room")
				if is_instance_valid(target_room) and target_room.has_method("get_definition"):
					goal_text = target_room.get_definition().get("name", "Zimmer")
				else:
					goal_text = "Zimmer"
			elif state == 3: # IN_POI
				var poi_id = actor.get("_current_poi_id")
				goal_text = "Aktivität" if poi_id != "" else "POI"
			elif state == 4: # AWAITING_CHECKOUT
				goal_text = "Rezeption"
			elif state == 1: # WALKING
				if actor.get("_is_checkout_walk"):
					goal_text = "Zur Lobby"
				else:
					goal_text = "Unterwegs"
			elif state == 5: # LEAVING
				goal_text = "Abreise"
			else:
				goal_text = "-"
				
		row.lbl_goal.text = goal_text
		row.lbl_energy.text = "%d%%" % int(energy_val)
		if energy_val < 30:
			row.lbl_energy.add_theme_color_override("font_color", Color.RED)
		else:
			row.lbl_energy.add_theme_color_override("font_color", Color("#CCCCCC"))
			
		row.lbl_sat.text = "%d%%" % int(party.satisfaction)
		if party.satisfaction < 30:
			row.lbl_sat.add_theme_color_override("font_color", Color.RED)
		elif party.satisfaction > 80:
			row.lbl_sat.add_theme_color_override("font_color", Color.GREEN)
		else:
			row.lbl_sat.add_theme_color_override("font_color", Color("#CCCCCC"))
			
		if _selected_guest and member.id == (_selected_guest.get("id") if "id" in _selected_guest else ""):
			detail_satisfaction_lbl.text = "%s: %d%%" % [GameState.T("satisfaction"), party.satisfaction]
