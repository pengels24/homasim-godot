extends CanvasLayer

# Referenzen
@onready var label_level: Label = %Level
@onready var hotel_stars: TextureProgressBar = %GourmetStars
@onready var label_money: Label = %Capital
@onready var label_guests_active: Label = %GuestsActive
@onready var label_guests_checkin: Label = %GuestsCheckIn
@onready var label_guests_checkout: Label = %GuestsCheckOut
@onready var bar_exp: ProgressBar = %EXP
@onready var label_exp_range: Label = %EXPRange
@onready var bar_rep: ProgressBar = %REP
@onready var label_rep_range: Label = %REPRange
@onready var label_day: Label = %Day
@onready var label_time: Label = %Time
@onready var label_next_event: Label = %NextEvent

# =============================================================================
func set_next_event(text: String) -> void:
	if label_next_event:
		label_next_event.text = text

@onready var btn_pause: Button = %Pause
@onready var btn_play: Button  = %Play
@onready var btn_ff: Button    = %Forward

# Steuerung der unteren UI-Rochade (Links / Mitte / Rechts)
@onready var lower_hbox: HBoxContainer = $BottomBarContainer
@onready var bottom_bar: Node = %HUDBottom

@onready var state_border: ReferenceRect = $StateBorder
@onready var pause_label: Label = $PauseLabel

@onready var activity_btn: Button = $ActivityLogContainer/MarginContainer/ActivityBtn
@onready var activity_badge: Panel = $ActivityLogContainer/Badge
@onready var activity_badge_label: Label = $ActivityLogContainer/Badge/Label
@onready var activity_panel: ActivityLogPanel = $ActivityLogPanel

var _is_building: bool = false
var _is_paused: bool = false


# =============================================================================
func _ready() -> void:
	GameState.sig_hotel_level_changed.connect(_on_hotel_level_changed)
	GameState.sig_hotel_stars_changed.connect(_on_hotel_stars_changed)
	GameState.sig_hotel_money_changed.connect(_on_hotel_money_changed)
	GameState.sig_hotel_guests_active_changed.connect(_on_hotel_guests_active_changed)
	GameState.sig_hotel_guests_checkin_changed.connect(_on_hotel_guests_checkin_changed)
	GameState.sig_hotel_guests_checkout_changed.connect(_on_hotel_guests_checkout_changed)
	GameState.sig_hotel_exp_changed.connect(_on_hotel_exp_changed)
	GameState.sig_hotel_rep_changed.connect(_on_hotel_rep_changed)
	GameState.sig_hotel_day_changed.connect(_on_hotel_day_changed)
	GameState.sig_hotel_time_changed.connect(_on_hotel_time_changed)
	GameState.sig_guest_clicked.connect(_on_guest_clicked)
	GameState.sig_staff_clicked.connect(_on_staff_clicked)

	TimeManager.sig_speed_changed.connect(_on_time_speed_changed)

	SettingsManager.sig_hud_side_changed.connect(func(): update_bottom_layout(SettingsManager.hud_side))
	update_bottom_layout(SettingsManager.hud_side)

	EffectManager.ui_money_node = %Capital
	EffectManager.ui_exp_node = %EXP
	EffectManager.ui_fp_node = bottom_bar.get_node("%TechTree")

	$BottomBarContainer/BuildMenu.sig_tool_selected.connect(_on_build_tool_selected)


	GameState.sig_hotel_level_up.connect(_on_hotel_level_up)
	%LevelUpModal.sig_rewards_claimed.connect(_on_level_up_rewards_claimed)

	# Techtree Signals
	TechtreeManager.sig_tech_unlocked.connect(_on_tech_unlocked)
	
	# Activity Log
	activity_btn.pressed.connect(_on_activity_btn_pressed)
	InputHandler.sig_hotkey_activity_log_requested.connect(_on_activity_btn_pressed)
	ActivityLog.entry_added.connect(_update_activity_badge)
	_update_activity_badge()

	# Initialen Pause-Status setzen (falls wir direkt pausiert ins Spiel starten)
	set_pause_visuals(TimeManager.is_paused())
	
	pause_label.text = GameState.T("hud.label.paused")
	
	btn_pause.tooltip_text = GameState.T("hud.top.right.tooltip.pause", _get_action_key_string("ui_pause"))
	btn_play.tooltip_text = GameState.T("hud.top.right.tooltip.play", _get_action_key_string("ui_play"))
	btn_ff.tooltip_text = GameState.T("hud.top.right.tooltip.forward", _get_action_key_string("ui_forward"))
	activity_btn.tooltip_text = GameState.T("hud.top.right.tooltip.activity_log", _get_action_key_string("ui_activity_log"))
	
	# FP-Anzeige verstecken (wird jetzt im Techtree geregelt)
	if has_node("TopBar/MarginContainer/HBoxContainer/FP"):
		get_node("TopBar/MarginContainer/HBoxContainer/FP").hide()

	# Custom Tooltip einhängen
	var tooltip_scene = preload("res://scenes/ingame/hud/CustomTooltip.tscn")
	var tooltip_instance = tooltip_scene.instantiate()
	add_child(tooltip_instance)

	# Room Context Menu einhängen
	var room_menu_scene = preload("res://scenes/ingame/hud/modals/RoomContextMenu.tscn")
	var room_menu_instance = room_menu_scene.instantiate()
	add_child(room_menu_instance)

# =============================================================================
func _on_tech_unlocked(tech_id: String) -> void:
	if tech_id == "M1.1" and is_instance_valid(bottom_bar) and bottom_bar.has_method("set_browser_locked"):
		bottom_bar.set_browser_locked(false)


# =============================================================================
func _on_activity_btn_pressed() -> void:
	if activity_panel.visible and activity_panel._is_open:
		activity_panel.close()
	else:
		activity_panel.open()
		_update_activity_badge()


# =============================================================================
func _update_activity_badge(_entry = null) -> void:
	var c = ActivityLog.get_unread_count()
	if c > 0:
		activity_badge.visible = true
		activity_badge_label.text = str(c)
	else:
		activity_badge.visible = false


# =============================================================================
func _on_guest_clicked(guest: Node2D) -> void:
	# Wenn es schon einen laufenden Tooltip gibt, löschen wir ihn am besten
	for child in get_children():
		if child.name == "GuestFollowTooltip" or child.has_method("_update_target_text"):
			child.queue_free()
			
	var tooltip_scene = load("res://scenes/ingame/hud/GuestFollowTooltip.tscn")
	var t = tooltip_scene.instantiate()
	add_child(t)
	t.setup(guest)


# =============================================================================
func _on_staff_clicked(staff: Node2D) -> void:
	for child in get_children():
		if child.name == "StaffFollowTooltip" or child.name == "GuestFollowTooltip" or child.has_method("_update_target_text"):
			child.queue_free()
			
	var tooltip_scene = load("res://scenes/ingame/hud/StaffFollowTooltip.tscn")
	var t = tooltip_scene.instantiate()
	add_child(t)
	t.setup(staff)


# =============================================================================
func _on_hotel_level_changed(new_level: int) -> void:
	label_level.text = str(new_level)
	if is_instance_valid(bottom_bar):
		if bottom_bar.has_method("set_staff_locked"):
			bottom_bar.set_staff_locked(new_level < GameState.UNLOCK_LEVELS.staff)
		if bottom_bar.has_method("set_techtree_locked"):
			bottom_bar.set_techtree_locked(new_level < GameState.UNLOCK_LEVELS.techtree)
		
		await get_tree().process_frame
		if is_instance_valid(bottom_bar) and bottom_bar.has_method("set_browser_locked"):
			bottom_bar.set_browser_locked(not TechtreeManager.is_tech_unlocked("M1.1"))


# =============================================================================
func _on_hotel_money_changed(new_money: int) -> void:
	label_money.text = GameState.format_money(new_money)
	# Rot wenn Schulden, Standard-Weiß wenn positiv
	if new_money < 0:
		label_money.add_theme_color_override("font_color", Color("dc2626")) # Rot
	else:
		label_money.remove_theme_color_override("font_color") # Zurück zur Standard-Farbe


# =============================================================================
func _on_hotel_stars_changed(stars: int) -> void:
	hotel_stars.value = stars


# =============================================================================
func _on_hotel_guests_active_changed(guests_active: int) -> void:
	label_guests_active.text = str(guests_active)


# =============================================================================
func _on_hotel_guests_checkin_changed(guests_checkin: int) -> void:
	label_guests_checkin.text = str(guests_checkin)


# =============================================================================
func _on_hotel_guests_checkout_changed(guests_checkout: int) -> void:
	label_guests_checkout.text = str(guests_checkout)


# =============================================================================
func _on_hotel_exp_changed(exp_curr: int, exp_max: int) -> void:
	bar_exp.max_value = exp_max
	bar_exp.value = exp_curr
	
	if GameState.selected_hotel.get("level", 1) >= 10:
		label_exp_range.text = "MAX LEVEL"
	else:
		label_exp_range.text = "%d / %d" % [exp_curr, exp_max]


# =============================================================================
func _on_hotel_rep_changed(rep_curr: int, rep_max: int) -> void:
	bar_rep.max_value = rep_max
	bar_rep.value = rep_curr
	label_rep_range.text = "%d / %d" % [rep_curr, rep_max]
	var rep_color: Color

	if rep_curr < 250:
		rep_color = label_guests_checkout.get_theme_color("font_color")
		# Animation starten, falls sie nicht schon läuft
		if not %AnimateREPPulse.is_playing():
			%AnimateREPPulse.play("pulse")

	elif rep_curr <= 750:
		rep_color = label_guests_checkin.get_theme_color("font_color")
		# Wieder im Normalbereich: Animation stoppen
		if %AnimateREPPulse.is_playing():
			%AnimateREPPulse.stop()

	else:
		rep_color = label_guests_active.get_theme_color("font_color")
		# Im Top-Bereich: Sicherstellen, dass die Animation steht
		if %AnimateREPPulse.is_playing():
			%AnimateREPPulse.stop()

	var stylebox_fill = bar_rep.get_theme_stylebox("fill").duplicate()
	stylebox_fill.bg_color = rep_color
	bar_rep.add_theme_stylebox_override("fill", stylebox_fill)


# =============================================================================
func _on_hotel_day_changed(day_number: int) -> void:
	label_day.text = str(day_number)


# =============================================================================
func _on_hotel_time_changed(time_string: String) -> void:
	label_time.text = time_string


# =============================================================================
func _on_hotel_level_up(new_level: int) -> void:
	var reward_money := 1000 * new_level
	var reward_fp    := 100  * new_level
	var unlock_text  := ""

	match new_level:
		GameState.UNLOCK_LEVELS.staff:
			unlock_text  = GameState.T("levelup.unlock.hr_hint")
			reward_money = 1500
			reward_fp    = 250
		GameState.UNLOCK_LEVELS.techtree:
			unlock_text  = GameState.T("modal.techtree.title")
			reward_money = 2500
			reward_fp    = 500
		4:
			unlock_text  = GameState.T("levelup.unlock.l4_gastro")
			reward_money = 4000
			reward_fp    = 600
		5:
			unlock_text  = GameState.T("levelup.unlock.l5_staff_room")
			reward_money = 5000
			reward_fp    = 750
		6:
			unlock_text  = GameState.T("levelup.unlock.l6_guest_needs")
			reward_money = 6000
			reward_fp    = 900
		7:
			unlock_text  = GameState.T("levelup.unlock.l7_gourmet_kitchen")
			reward_money = 7000
			reward_fp    = 1100
		8:
			unlock_text  = GameState.T("levelup.unlock.l8_wellness")
			reward_money = 8000
			reward_fp    = 1300
		9:
			unlock_text  = GameState.T("levelup.unlock.l9_stars")
			reward_money = 10000
			reward_fp    = 1500
		10:
			unlock_text  = GameState.T("levelup.unlock.l10_tier2")
			reward_money = 15000
			reward_fp    = 2000

	%LevelUpModal.setup(new_level, reward_money, reward_fp, unlock_text)
	%LevelUpModal.open()



# =============================================================================
func _on_level_up_rewards_claimed(money: int, fp: int) -> void:
	await get_tree().create_timer(0.3).timeout

	var camera = get_viewport().get_camera_2d()
	var spawn_pos = Vector2.ZERO
	if camera:
		spawn_pos = camera.get_screen_center_position()

	if money > 0:
		# NEU: Über den FinanceManager routen
		FinanceManager.add_transaction(money, "reward", "tx.level_up_bonus")

		EffectManager.spawn_money_text(money, spawn_pos)

	if fp > 0:
		GameState.add_fp(fp)
		EffectManager.spawn_fp_text(fp, spawn_pos)


# =============================================================================
func _set_inner_alignment(node: Node, alignment: BoxContainer.AlignmentMode) -> void:
	if not node:
		return

	var hbox = node.get_node_or_null("HBoxContainer")
	if hbox:
		hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		hbox.offset_left = 0
		hbox.offset_top = 0
		hbox.offset_right = 0
		hbox.offset_bottom = 0
		hbox.alignment = alignment


# =============================================================================
func update_bottom_layout(position_setting: String) -> void:
	if not is_inside_tree():
		await ready

	if not bottom_bar:
		return

	match position_setting.to_lower():
		"left":
			lower_hbox.move_child($BottomBarContainer/BuildMenu, 0)
			_set_inner_alignment($BottomBarContainer/BuildMenu, BoxContainer.ALIGNMENT_BEGIN)

		"right":
			lower_hbox.move_child($BottomBarContainer/BuildMenu, 2)
			_set_inner_alignment($BottomBarContainer/BuildMenu, BoxContainer.ALIGNMENT_END)

		"center", _:
			lower_hbox.move_child($BottomBarContainer/BuildMenu, 1)
			_set_inner_alignment($BottomBarContainer/BuildMenu, BoxContainer.ALIGNMENT_CENTER)




# =============================================================================
func set_reception_locked(is_locked: bool) -> void:
	bottom_bar.set_reception_locked(is_locked)


# =============================================================================
func set_reception_alert(has_waiting_guests: bool) -> void:
	bottom_bar.set_reception_alert(has_waiting_guests)


# =============================================================================
func _on_time_speed_changed(is_paused: bool, speed: float) -> void:
	if is_paused:
		btn_pause.set_pressed_no_signal(true)
		btn_play.set_pressed_no_signal(false)
		btn_ff.set_pressed_no_signal(false)

	elif speed > 1.0:
		btn_ff.set_pressed_no_signal(true)
		btn_pause.set_pressed_no_signal(false)
		btn_play.set_pressed_no_signal(false)

	else:
		btn_play.set_pressed_no_signal(true)
		btn_pause.set_pressed_no_signal(false)
		btn_ff.set_pressed_no_signal(false)


# =============================================================================
func update_state_visuals() -> void:
	if not is_instance_valid(state_border) or not is_instance_valid(pause_label):
		return

	if _is_building:
		state_border.border_color = Color(0.9, 0.7, 0.0) # Gold/Yellow
		state_border.visible = true
	elif _is_paused:
		state_border.border_color = Color.WHITE
		state_border.visible = true
	else:
		state_border.visible = false

	pause_label.visible = _is_paused


# =============================================================================
func set_pause_visuals(p_paused: bool) -> void:
	_is_paused = p_paused
	update_state_visuals()


# =============================================================================
func set_build_mode_visuals(p_building: bool) -> void:
	_is_building = p_building
	update_state_visuals()
	var hint = find_child("BuildHintPanel", true, false)
	if hint:
		if p_building:
			var build_menu = $BottomBarContainer/BuildMenu
			if build_menu and build_menu._current_category == "demolish":
				hint.hide_hints()
			else:
				hint.show_hints()
		else:
			if _active_overlay in ["category", "occupancy"]:
				hint.show_overlay_legend(_active_overlay)
			else:
				hint.hide_hints()

var _active_overlay: String = ""

func set_overlay_legend_visuals(type: String) -> void:
	_active_overlay = type
	var hint = find_child("BuildHintPanel", true, false)
	if hint:
		if _is_building:
			pass # Build hints have priority
		elif _active_overlay in ["category", "occupancy"]:
			hint.show_overlay_legend(_active_overlay)
		else:
			hint.hide_hints()

# =============================================================================
func _on_build_tool_selected(action_id: String) -> void:
	var hint = find_child("BuildHintPanel", true, false)
	if hint and _is_building:
		if action_id == "demolish":
			hint.hide_hints()
		else:
			hint.show_hints()
func _get_action_key_string(action_name: String) -> String:
	var events = InputMap.action_get_events(action_name)
	if events.size() > 0:
		var event = events[0]
		if event is InputEventKey:
			var code = event.get_physical_keycode_with_modifiers() if event.physical_keycode != 0 else event.get_keycode_with_modifiers()
			var txt = OS.get_keycode_string(code)
			var t_key = "key." + txt.to_lower().replace(" ", "_")
			var translated = GameState.T(t_key)
			if translated != t_key:
				txt = translated
			return "(" + txt + ")"
	return ""

