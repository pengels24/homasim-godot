extends MarginContainer
class_name ModalContentGuestList

@onready var guest_list_container: VBoxContainer = %GuestListContainer
@onready var pip_camera: PipCamera = %PipCamera
@onready var detail_name_lbl: Label = %DetailNameLabel
@onready var detail_room_lbl: Label = %DetailRoomLabel
@onready var detail_room_val: Label = %DetailRoomValue
@onready var detail_satisfaction_lbl: Label = %DetailSatisfactionLabel
@onready var detail_satisfaction_val: Label = %DetailSatisfactionValue
@onready var detail_status_lbl: Label = %DetailStatusLabel
@onready var detail_status_val: Label = %DetailStatusValue
@onready var detail_budget_lbl: Label = %DetailBudgetLabel
@onready var detail_budget_val: Label = %DetailBudgetValue
@onready var need_hunger: ProgressBar = %NeedHunger
@onready var need_thirst: ProgressBar = %NeedThirst
@onready var need_energy: ProgressBar = %NeedEnergy
@onready var need_fun: ProgressBar = %NeedFun
@onready var lbl_hunger: Label = %LblHunger
@onready var lbl_thirst: Label = %LblThirst
@onready var lbl_energy: Label = %LblEnergy
@onready var lbl_fun: Label = %LblFun
@onready var btn_goto: Button = %BtnGoto
@onready var btn_pip: Button = %BtnPip

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
	btn_goto.pressed.connect(_on_goto_pressed)
	btn_pip.pressed.connect(_on_pip_pressed)
	
	# Set static localized labels
	detail_room_lbl.text = GameState.T("room") + ":"
	detail_satisfaction_lbl.text = GameState.T("satisfaction") + ":"
	detail_budget_lbl.text = GameState.T("budget") + ":"
	detail_status_lbl.text = GameState.T("status") + ":"
	
	_apply_translations()
	
	_populate_list()
	_clear_details()

func _apply_translations() -> void:
	btn_goto.text = GameState.T("ui.guest_list.goto")
	btn_pip.text = "Beobachten (PIP)"
	
	var header_hbox = find_child("TableHeaderPanel", true, false).get_child(0).get_child(0)
	if header_hbox:
		var lbl_name = header_hbox.get_node_or_null("LblName")
		if lbl_name: lbl_name.text = GameState.T("ui.guest_list.col.name")
		var lbl_room = header_hbox.get_node_or_null("LblRoom")
		if lbl_room: lbl_room.text = GameState.T("ui.guest_list.col.room")
		var lbl_budget = header_hbox.get_node_or_null("LblBudget")
		if lbl_budget: lbl_budget.text = GameState.T("ui.guest_list.col.budget")
		var lbl_goal = header_hbox.get_node_or_null("LblGoal")
		if lbl_goal: lbl_goal.text = GameState.T("ui.guest_list.col.status")
		var lbl_energy = header_hbox.get_node_or_null("LblEnergy")
		if lbl_energy: lbl_energy.text = GameState.T("ui.guest_list.col.energy")
		var lbl_sat = header_hbox.get_node_or_null("LblSatisfaction")
		if lbl_sat:
			lbl_sat.text = GameState.T("ui.guest_list.col.satisfaction")
			lbl_sat.tooltip_text = GameState.T("ui.guest_list.tooltip.satisfaction")

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
	
	# Icon (NEW)
	var tex_icon = TextureRect.new()
	var def = party.get_type_def()
	var icon_path = def.get("icon", "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		tex_icon.texture = load(icon_path)
	tex_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_icon.custom_minimum_size = Vector2(24, 24)
	tex_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var icon_margin = MarginContainer.new()
	icon_margin.add_theme_constant_override("margin_right", 8)
	icon_margin.add_child(tex_icon)
	hbox.add_child(icon_margin)
	
	# Name
	var lbl_name = Label.new()
	lbl_name.text = member.name
	lbl_name.clip_text = true
	lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_name.size_flags_stretch_ratio = 2.0
	lbl_name.add_theme_color_override("font_color", font_color)
	
	# Raum
	var lbl_room = Label.new()
	if party.room_id == "" and party.event_poi_id != "":
		lbl_room.text = "Tagesgast"
	elif party.room_id != "":
		lbl_room.text = party.room_id
	else:
		lbl_room.text = GameState.T("guest.state.waiting")
	lbl_room.clip_text = true
	lbl_room.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl_room.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_room.size_flags_stretch_ratio = 1.0
	lbl_room.add_theme_color_override("font_color", font_color)
	
	# Budget (individuell pro Member) – rechtsbündig (Wert)
	var lbl_budget = Label.new()
	if member.daily_budget > 0:
		lbl_budget.text = "%d %s" % [member.spending_budget, GameState.T("currency.symbol")]
	else:
		lbl_budget.text = "---"
	lbl_budget.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_budget.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_budget.size_flags_stretch_ratio = 1.0
	lbl_budget.add_theme_color_override("font_color", font_color)
	
	# Gather live data from actor if spawned
	var actor: GuestActor = null
	if _guest_controller and _guest_controller._actors.has(member.id):
		actor = _guest_controller._actors[member.id]
	
	var goal_text := "---"
	if actor:
		goal_text = actor.get_status_text()

	# Status – linksbündig (Text), mit Clip + Ellipsis + Tooltip
	var lbl_goal = Label.new()
	lbl_goal.text = goal_text
	lbl_goal.tooltip_text = goal_text
	lbl_goal.clip_text = true
	lbl_goal.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lbl_goal.mouse_filter = Control.MOUSE_FILTER_PASS
	lbl_goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl_goal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_goal.size_flags_stretch_ratio = 2.0
	lbl_goal.add_theme_color_override("font_color", font_color)
	
	# Sättigung – rechtsbündig (Wert)
	var energy_val: int = member.saturation if "saturation" in member else 100
	var row_lbl_energy = Label.new()
	row_lbl_energy.text = "%d%%" % energy_val
	row_lbl_energy.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row_lbl_energy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_lbl_energy.size_flags_stretch_ratio = 1.0
	if energy_val < 30:
		row_lbl_energy.add_theme_color_override("font_color", Color("#b02e3b"))
	else:
		row_lbl_energy.add_theme_color_override("font_color", font_color)
		
	# Zufriedenheit – rechtsbündig (Wert)
	var sat: int = party.satisfaction
	var lbl_sat = Label.new()
	lbl_sat.text = "%d%%" % sat
	lbl_sat.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_sat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_sat.size_flags_stretch_ratio = 1.0
	if sat < 50:
		lbl_sat.add_theme_color_override("font_color", Color("#b02e3b"))
	elif sat > 80:
		lbl_sat.add_theme_color_override("font_color", Color("#366e4d"))
	else:
		lbl_sat.add_theme_color_override("font_color", font_color)

		
	hbox.add_child(lbl_name)
	hbox.add_child(lbl_room)
	hbox.add_child(lbl_budget)
	hbox.add_child(lbl_goal)
	hbox.add_child(row_lbl_energy)
	hbox.add_child(lbl_sat)
	
	btn.add_child(margin)
	btn.pressed.connect(_on_guest_selected.bind(party, member, btn))
	guest_list_container.add_child(btn)
	
	_active_rows.append({
		"party": party,
		"member": member,
		"lbl_budget": lbl_budget,
		"lbl_goal": lbl_goal,
		"lbl_energy": row_lbl_energy,
		"lbl_sat": lbl_sat
	})

func _on_guest_selected(party: GuestParty, member: GuestMember, _btn: Button) -> void:
	if not _guest_controller:
		return
		
	var guest_id = member.id
	if _guest_controller._actors.has(guest_id):
		_selected_guest = _guest_controller._actors[guest_id]
		pip_camera.set_target(_selected_guest)
		btn_goto.disabled = false
		btn_goto.add_theme_stylebox_override("normal", load("res://assets/UI/menu_button_blue.tres"))
		btn_goto.add_theme_stylebox_override("hover", load("res://assets/UI/menu_button_blue_hover.tres"))
		btn_goto.add_theme_stylebox_override("pressed", load("res://assets/UI/menu_button_blue_pressed.tres"))
		
		btn_pip.disabled = false
		btn_pip.add_theme_stylebox_override("normal", load("res://assets/UI/menu_button_blue.tres"))
		btn_pip.add_theme_stylebox_override("hover", load("res://assets/UI/menu_button_blue_hover.tres"))
		btn_pip.add_theme_stylebox_override("pressed", load("res://assets/UI/menu_button_blue_pressed.tres"))
		
		detail_name_lbl.text = member.name
		if party.room_id == "" and party.event_poi_id != "":
			detail_room_val.text = "Tagesgast"
			detail_room_val.add_theme_color_override("font_color", Color("#8ab4f8"))
		elif party.room_id != "":
			detail_room_val.text = party.room_id
			detail_room_val.remove_theme_color_override("font_color")
		else:
			detail_room_val.text = GameState.T("none")
			detail_room_val.remove_theme_color_override("font_color")
		detail_satisfaction_val.text = "%d%%" % party.satisfaction
		if member.daily_budget > 0:
			detail_budget_val.text = "%d / %d %s" % [member.spending_budget, member.daily_budget, GameState.T("currency.symbol")]
			detail_budget_val.remove_theme_color_override("font_color")
		else:
			detail_budget_val.text = "---"
			detail_budget_val.remove_theme_color_override("font_color")
		
		detail_status_val.text = _selected_guest.get_status_text()

		
		_update_need_bar(need_hunger, lbl_hunger, GameState.T("need.hunger"), member.saturation)
		_update_need_bar(need_thirst, lbl_thirst, GameState.T("need.thirst"), member.thirst)
		_update_need_bar(need_energy, lbl_energy, GameState.T("need.energy"), member.energy)
		_update_need_bar(need_fun, lbl_fun, GameState.T("need.fun"), member.fun)
	else:
		_clear_details()

func _update_need_bar(bar: ProgressBar, lbl: Label, prefix: String, val: int) -> void:
	if not is_instance_valid(bar): return
	bar.value = val
	if is_instance_valid(lbl):
		lbl.text = "%s: %d%%" % [prefix, val]

func _clear_details() -> void:
	_selected_guest = null
	pip_camera.set_target(null)
	btn_goto.disabled = true
	btn_goto.add_theme_stylebox_override("disabled", load("res://assets/UI/menu_button_darkblue_disabled.tres"))
	btn_pip.disabled = true
	btn_pip.add_theme_stylebox_override("disabled", load("res://assets/UI/menu_button_darkblue_disabled.tres"))
	
	detail_name_lbl.text = GameState.T("ui.guest_list.please_select")
	detail_room_val.text = "---"
	detail_satisfaction_val.text = "---"
	detail_budget_val.text = "---"
	detail_status_val.text = "---"
	
	need_hunger.value = 0
	need_thirst.value = 0
	need_energy.value = 0
	need_fun.value = 0
	if is_instance_valid(lbl_hunger): lbl_hunger.text = "%s: 0%%" % GameState.T("need.hunger.short")
	if is_instance_valid(lbl_thirst): lbl_thirst.text = "%s: 0%%" % GameState.T("need.thirst.short")
	if is_instance_valid(lbl_energy): lbl_energy.text = "%s: 0%%" % GameState.T("need.energy.short")
	if is_instance_valid(lbl_fun):    lbl_fun.text    = "%s: 0%%" % GameState.T("need.fun.short")

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
			
		var goal_text_short := "---"
		var energy_val: int = member.saturation if "saturation" in member else 100
		var sat: int = party.satisfaction
		if actor:
			goal_text_short = actor.get_status_text()

		row.lbl_goal.text = goal_text_short
		row.lbl_goal.tooltip_text = goal_text_short
		row.lbl_energy.text = "%d%%" % energy_val
		if energy_val < 30:
			row.lbl_energy.add_theme_color_override("font_color", Color("#b02e3b"))
		else:
			row.lbl_energy.add_theme_color_override("font_color", Color("#CCCCCC"))
			
		if member.daily_budget > 0:
			row.lbl_budget.text = "%d %s" % [member.spending_budget, GameState.T("currency.symbol")]
		else:
			row.lbl_budget.text = "---"
			
		row.lbl_sat.text = "%d%%" % sat
		if sat < 50:
			row.lbl_sat.add_theme_color_override("font_color", Color("#b02e3b"))
		elif sat > 80:
			row.lbl_sat.add_theme_color_override("font_color", Color("#366e4d"))
		else:
			row.lbl_sat.add_theme_color_override("font_color", Color("#CCCCCC"))
			
		if _selected_guest and actor and _selected_guest == actor:
			detail_satisfaction_val.text = "%d%%" % sat
			detail_status_val.text = goal_text_short

			if member.daily_budget > 0:
				detail_budget_val.text = "%d / %d %s" % [member.spending_budget, member.daily_budget, GameState.T("currency.symbol")]
			_update_need_bar(need_hunger, lbl_hunger, GameState.T("need.hunger"), member.saturation)
			_update_need_bar(need_thirst, lbl_thirst, GameState.T("need.thirst"), member.thirst)
			_update_need_bar(need_energy, lbl_energy, GameState.T("need.energy"), member.energy)
			_update_need_bar(need_fun, lbl_fun, GameState.T("need.fun"), member.fun)

func _on_pip_pressed() -> void:
	if not is_instance_valid(_selected_guest):
		return
	GameState.sig_guest_clicked.emit(_selected_guest)
	
	# Close the Modal automatically
	var modal = self
	while modal != null and not modal.has_method("close"):
		modal = modal.get_parent()
	if modal and modal.has_method("close"):
		modal.close()

func _on_goto_pressed() -> void:
	if not is_instance_valid(_selected_guest):
		return
		
	var ingame = get_tree().get_root().get_node_or_null("Ingame")
	var map_grid = ingame.get("map_grid") if ingame else null
	var cam = map_grid.get_node_or_null("Camera2D") if map_grid else get_viewport().get_camera_2d()
	
	if cam:
		var target_pos = _selected_guest.global_position
			
		var tween = get_tree().create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_parallel(true)
		tween.tween_property(cam, "global_position", target_pos, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(cam, "zoom", Vector2(4, 4), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	var modal = find_parent("StandardModal")
	if modal and modal.has_method("close"):
		modal.close()
