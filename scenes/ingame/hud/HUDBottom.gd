extends Control

signal sig_reception_toggled
signal sig_staff_toggled
signal sig_tech_tree_toggled
signal sig_sim_browser_toggled
signal sig_quest_book_toggled
signal sig_guest_list_toggled
signal sig_room_list_toggled
signal sig_finances_toggled
signal sig_tutorial_toggled

@onready var reception: Button = %Reception
@onready var staff: Button = %Staff
@onready var tech_tree: Button = %TechTree
@onready var sim_browser: Button = %SimBrowser
@onready var quest_book: Button = %QuestBook
@onready var tutorial: Button = %Tutorial
@onready var guest_list: Button = %GuestList
@onready var room_list: Button = %RoomList
@onready var finances: Button = %Finances
@onready var ind_reception: Panel = %IndReception
@onready var ind_sim_browser: Panel = %IndSimBrowser
@onready var ind_quest_book: Panel = %IndQuestBook
@onready var ind_tutorial: Panel = %IndTutorial


# =============================================================================
func _ready() -> void:
	reception.pressed.connect(func():
		sig_reception_toggled.emit()
	)

	staff.pressed.connect(func():
		sig_staff_toggled.emit()
	)

	tech_tree.pressed.connect(func():
		sig_tech_tree_toggled.emit()
	)

	sim_browser.pressed.connect(func():
		sig_sim_browser_toggled.emit()
	)

	quest_book.pressed.connect(func():
		sig_quest_book_toggled.emit()
	)

	tutorial.pressed.connect(func():
		sig_tutorial_toggled.emit()
	)

	guest_list.pressed.connect(func():
		sig_guest_list_toggled.emit()
	)

	room_list.pressed.connect(func():
		sig_room_list_toggled.emit()
	)
	finances.pressed.connect(func():
		sig_finances_toggled.emit()
	)

	_update_quest_book_indicator()
	
	# Events
	GameState.hotel_selected.connect(func(_data): _update_quest_book_indicator())
	
	if QuestManager:
		QuestManager.sig_quest_claimable.connect(func(_id): _update_quest_book_indicator())
		QuestManager.sig_quest_claimed.connect(func(_id): _update_quest_book_indicator())
		QuestManager.sig_rank_claimable.connect(func(_id): _update_quest_book_indicator())
		QuestManager.sig_rank_claimed.connect(func(_id): _update_quest_book_indicator())

	reception.tooltip_text  = GameState.T("hud.bottom.reception_tt", _get_action_key_string("ui_reception"))
	staff.tooltip_text      = GameState.T("hud.bottom.staff_tt", _get_action_key_string("ui_staff"))
	tech_tree.tooltip_text  = GameState.T("hud.bottom.tech_tree_tt", _get_action_key_string("ui_tech_tree"))
	sim_browser.tooltip_text = GameState.T("hud.bottom.sim_browser_tt", _get_action_key_string("ui_sim_browser"))
	quest_book.tooltip_text = GameState.T("hud.bottom.quest_book_tt", _get_action_key_string("ui_quest_book"))
	guest_list.tooltip_text = GameState.T("hud.bottom.guest_list_tt", _get_action_key_string("ui_guest_list"))
	room_list.tooltip_text = GameState.T("hud.bottom.room_list_tt", _get_action_key_string("ui_room_list"))
	finances.tooltip_text = GameState.T("hud.bottom.finances_tt", _get_action_key_string("ui_finances"))
	tutorial.tooltip_text = GameState.T("hud.bottom.tutorials_tt", _get_action_key_string("ui_tutorial"))

	ind_reception.hide()
	ind_sim_browser.modulate = Color.GREEN
	ind_sim_browser.hide()
	ind_quest_book.modulate = Color.GREEN
	_update_quest_book_indicator()


# =============================================================================
func set_reception_locked(is_locked: bool) -> void:
	reception.disabled = is_locked
	if is_locked:
		ind_reception.visible = false


# =============================================================================
func set_reception_alert(has_waiting_guests: bool) -> void:
	ind_reception.modulate = Color.RED
	if not reception.disabled:
		ind_reception.visible = has_waiting_guests


# =============================================================================
func set_staff_locked(is_locked: bool) -> void:
	staff.disabled = is_locked


# =============================================================================
func set_techtree_locked(is_locked: bool) -> void:
	tech_tree.disabled = is_locked

# =============================================================================
func set_browser_locked(is_locked: bool) -> void:
	sim_browser.disabled = is_locked



# =============================================================================
func set_browser_alert(has_news: bool) -> void:
	ind_sim_browser.modulate = Color.DARK_ORANGE if has_news else Color.GREEN

# =============================================================================
func set_quest_alert(has_claimable: bool) -> void:
	ind_quest_book.visible = has_claimable


# =============================================================================
# Wird von Ingame.gd aufgerufen, um die Position des Baumenü-Panels anzupassen
func sync_button_state(active_menu: String = "") -> void:
	_update_quest_book_indicator()
	# Alle Buttons sicherheitshalber ausschalten und Fokus entfernen
	for btn in [reception, staff, tech_tree, sim_browser, quest_book, guest_list, room_list, finances, tutorial]:
		btn.set_pressed_no_signal(false)
		btn.release_focus()

	# Nur den aktuell gewünschten Button wieder "eindrücken"
	match active_menu:
		"reception":
			reception.set_pressed_no_signal(true)
		"sim_browser":
			sim_browser.set_pressed_no_signal(true)
		"quest_book":
			quest_book.set_pressed_no_signal(true)
		"tutorial":
			tutorial.set_pressed_no_signal(true)
		"staff":
			staff.set_pressed_no_signal(true)
		"tech_tree":
			tech_tree.set_pressed_no_signal(true)
		"guest_list":
			guest_list.set_pressed_no_signal(true)
		"room_list":
			room_list.set_pressed_no_signal(true)
		"finances":
			finances.set_pressed_no_signal(true)


# =============================================================================

# =============================================================================
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

func _update_quest_book_indicator() -> void:
	if QuestManager and QuestManager.has_any_claimable():
		ind_quest_book.show()
	else:
		ind_quest_book.hide()
