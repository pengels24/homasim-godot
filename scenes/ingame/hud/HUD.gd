extends CanvasLayer

# Referenzen
@onready var label_name: Label = %Hotelname
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

@onready var btn_pause: Button = %Pause
@onready var btn_play: Button  = %Play
@onready var btn_ff: Button    = %Forward

# Steuerung der unteren UI-Rochade (Links / Mitte / Rechts)
@onready var lower_hbox: HBoxContainer = $BottomBarContainer
@onready var reset_view: Node = %HUDResetView
@onready var bottom_bar: Node = %HUDBottom
@onready var music_ctrl: Node = %HUDMusicControl

@onready var state_border: ReferenceRect = $StateBorder
@onready var pause_label: Label = $PauseLabel

var _is_building: bool = false
var _is_paused: bool = false


# =============================================================================
func _ready() -> void:
	GameState.sig_hotel_name_changed.connect(_on_hotel_name_changed)
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

	TimeManager.sig_speed_changed.connect(_on_time_speed_changed)

	SettingsManager.sig_hud_side_changed.connect(func(): update_bottom_layout(SettingsManager.hud_side))
	update_bottom_layout(SettingsManager.hud_side)

	EffectManager.ui_money_node = %Capital
	EffectManager.ui_exp_node = %EXP
	EffectManager.ui_fp_node = bottom_bar.get_node("%TechTree")

	GameState.sig_hotel_level_up.connect(_on_hotel_level_up)
	%LevelUpModal.sig_rewards_claimed.connect(_on_level_up_rewards_claimed)

	# Initialen Pause-Status setzen (falls wir direkt pausiert ins Spiel starten)
	set_pause_visuals(TimeManager.is_paused())
	
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
func _on_hotel_name_changed(new_name: String) -> void:
	label_name.text = new_name


# =============================================================================
func _on_hotel_level_changed(new_level: int) -> void:
	label_level.text = str(new_level)
	if is_instance_valid(bottom_bar):
		if bottom_bar.has_method("set_staff_locked"):
			bottom_bar.set_staff_locked(new_level < 2)
		if bottom_bar.has_method("set_techtree_locked"):
			bottom_bar.set_techtree_locked(new_level < 5)


# =============================================================================
func _on_hotel_money_changed(new_money: int) -> void:
	label_money.text = GameState.format_money(new_money)


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
	var reward_money = 1500
	var reward_fp = 250
	var unlock_text = ""
	
	match new_level:
		2:
			unlock_text = "Personalverwaltung"
			reward_money = 1500
			reward_fp = 250
		5:
			unlock_text = "Forschung & Technologie"
			reward_money = 2500
			reward_fp = 500
		_:
			reward_money = 1000 * new_level
			reward_fp = 100 * new_level

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
		FinanceManager.add_transaction(money, "reward", "Level-Up Bonus")

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

	if not reset_view or not bottom_bar or not music_ctrl:
		return

	match position_setting.to_lower():
		"left":
			lower_hbox.move_child(bottom_bar, 0)
			_set_inner_alignment(bottom_bar, BoxContainer.ALIGNMENT_BEGIN)
			lower_hbox.move_child(reset_view, 1)
			_set_inner_alignment(reset_view, BoxContainer.ALIGNMENT_CENTER)
			lower_hbox.move_child(music_ctrl, 2)
			_set_inner_alignment(music_ctrl, BoxContainer.ALIGNMENT_END)

		"right":
			lower_hbox.move_child(reset_view, 0)
			_set_inner_alignment(reset_view, BoxContainer.ALIGNMENT_BEGIN)
			lower_hbox.move_child(music_ctrl, 1)
			_set_inner_alignment(music_ctrl, BoxContainer.ALIGNMENT_CENTER)
			lower_hbox.move_child(bottom_bar, 2)
			_set_inner_alignment(bottom_bar, BoxContainer.ALIGNMENT_END)

		"center", _:
			lower_hbox.move_child(reset_view, 0)
			_set_inner_alignment(reset_view, BoxContainer.ALIGNMENT_BEGIN)
			lower_hbox.move_child(bottom_bar, 1)
			_set_inner_alignment(bottom_bar, BoxContainer.ALIGNMENT_CENTER)
			lower_hbox.move_child(music_ctrl, 2)
			_set_inner_alignment(music_ctrl, BoxContainer.ALIGNMENT_END)

	if bottom_bar.has_method("update_build_menu_position"):
		bottom_bar.update_build_menu_position()


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
