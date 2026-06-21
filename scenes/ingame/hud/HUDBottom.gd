extends Control

signal sig_build_menu_toggled
signal sig_reception_toggled
signal sig_staff_toggled
signal sig_tech_tree_toggled
signal sig_sim_browser_toggled
signal sig_quest_book_toggled
signal sig_guest_list_toggled
signal sig_room_list_toggled
signal sig_tutorials_toggled

@onready var build_menu: Button = %BuildMenu
@onready var reception: Button = %Reception
@onready var staff: Button = %Staff
@onready var tech_tree: Button = %TechTree
@onready var sim_browser: Button = %SimBrowser
@onready var quest_book: Button = %QuestBook
@onready var guest_list: Button = %GuestList
@onready var room_list: Button = %RoomList
@onready var tutorials: Button = %Tutorials
@onready var ind_reception: Panel = %IndReception
@onready var ind_sim_browser: Panel = %IndSimBrowser
@onready var ind_quest_book: Panel = %IndQuestBook


# =============================================================================
func _ready() -> void:
	build_menu.pressed.connect(func():
		sig_build_menu_toggled.emit()
	)

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

	guest_list.pressed.connect(func():
		sig_guest_list_toggled.emit()
	)

	room_list.pressed.connect(func():
		sig_room_list_toggled.emit()
	)

	tutorials.pressed.connect(func():
		sig_tutorials_toggled.emit()
	)

	_update_quest_book_indicator()
	
	# Events
	if QuestManager:
		QuestManager.sig_quest_claimable.connect(func(_id): _update_quest_book_indicator())
		QuestManager.sig_quest_claimed.connect(func(_id): _update_quest_book_indicator())
		QuestManager.sig_rank_claimable.connect(func(_id): _update_quest_book_indicator())
		QuestManager.sig_rank_claimed.connect(func(_id): _update_quest_book_indicator())

	# todo - zugewiesene tasten aus settings in den ttoltip setzen
	build_menu.tooltip_text = GameState.T("hud.bottom.build_menu_tt", "F2")
	reception.tooltip_text  = GameState.T("hud.bottom.reception_tt", "F3")
	staff.tooltip_text      = GameState.T("hud.bottom.staff_tt", "F4")
	tech_tree.tooltip_text  = GameState.T("hud.bottom.tech_tree_tt", "F6")
	sim_browser.tooltip_text = GameState.T("hud.bottom.sim_browser_tt", "F7")
	quest_book.tooltip_text = GameState.T("hud.bottom.quest_book_tt", "Aufgaben (J)")
	guest_list.tooltip_text = GameState.T("hud.bottom.guest_list_tt", "Gästeliste (F10)")
	room_list.tooltip_text = GameState.T("hud.bottom.room_list_tt", "Raumliste (F11)")
	tutorials.tooltip_text = GameState.T("hud.bottom.tutorials_tt", "Tutorials (F1)")

	ind_reception.hide()
	ind_sim_browser.modulate = Color.GREEN
	ind_sim_browser.hide()
	ind_quest_book.modulate = Color.GREEN
	ind_quest_book.hide()


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
func set_browser_alert(has_news: bool) -> void:
	ind_sim_browser.modulate = Color.DARK_ORANGE if has_news else Color.GREEN

# =============================================================================
func set_quest_alert(has_claimable: bool) -> void:
	ind_quest_book.visible = has_claimable


# =============================================================================
# Wird von Ingame.gd aufgerufen, um die Position des Baumenü-Panels anzupassen
func update_build_menu_position() -> void:
	if not has_node("BuildMenu") or not has_node("HBoxContainer/Panel1"):
		return

	var target_button = $HBoxContainer/Panel1
	var build_menu_box = $BuildMenu
	build_menu_box.top_level = true

	await get_tree().process_frame

	var offset_x = 10
	var new_x = target_button.global_position.x - offset_x
	var new_y = target_button.global_position.y - build_menu_box.size.y - 10

	build_menu_box.global_position = Vector2(new_x, new_y)


# =============================================================================
# Synchronisiert die visuelle Anzeige der Buttons mit dem aktuellen Menü-Status
func sync_button_state(active_menu: String = "") -> void:
	# Alle Buttons sicherheitshalber ausschalten und Fokus entfernen
	for btn in [build_menu, reception, staff, tech_tree, sim_browser, quest_book, guest_list, room_list, tutorials]:
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
		"build":
			build_menu.set_pressed_no_signal(true)
		"staff":
			staff.set_pressed_no_signal(true)
		"tech_tree":
			tech_tree.set_pressed_no_signal(true)
		"guest_list":
			guest_list.set_pressed_no_signal(true)
		"room_list":
			room_list.set_pressed_no_signal(true)
		"tutorials":
			tutorials.set_pressed_no_signal(true)


# =============================================================================
func _update_quest_book_indicator() -> void:
	if QuestManager and QuestManager.has_any_claimable():
		ind_quest_book.show()
	else:
		ind_quest_book.hide()