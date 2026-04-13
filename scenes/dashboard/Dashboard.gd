extends Control

@onready var username_label: Label = $TopBar/HBox/UsernameLabel
@onready var btn_logout: Button = $TopBar/HBox/BtnLogout
@onready var title_label: Label = $Content/TitleLabel
@onready var status_label: Label = $Content/StatusLabel
@onready var hotel_list: ItemList = $Content/HotelList
@onready var btn_new_hotel: Button = $Content/ActionButtons/BtnNewHotel
@onready var btn_tutorial: Button = $Content/ActionButtons/BtnTutorial
@onready var btn_play_hotel: Button = $Content/ActionButtons/BtnPlayHotel
@onready var btn_delete_hotel: Button = $Content/ActionButtons/BtnDeleteHotel
@onready var new_hotel_overlay: ColorRect = $NewHotelOverlay
@onready var hotel_name_field: LineEdit = $NewHotelOverlay/NewHotelPanel/VBox/HotelNameField
@onready var dialog_error: Label = $NewHotelOverlay/NewHotelPanel/VBox/DialogError
@onready var btn_create: Button = $NewHotelOverlay/NewHotelPanel/VBox/DialogButtons/BtnCreate
@onready var btn_cancel: Button = $NewHotelOverlay/NewHotelPanel/VBox/DialogButtons/BtnCancel

var _hotels: Array = []


func _ready() -> void:
	_apply_translations()
	username_label.text = GameState.current_user.get("username", "")
	btn_logout.pressed.connect(_on_main_menu_pressed)
	btn_new_hotel.pressed.connect(_on_new_hotel_pressed)
	btn_tutorial.pressed.connect(_on_tutorial_pressed)
	btn_play_hotel.pressed.connect(_on_play_hotel_pressed)
	btn_delete_hotel.pressed.connect(_on_delete_hotel_pressed)
	btn_create.pressed.connect(_on_create_confirmed)
	btn_cancel.pressed.connect(_close_new_hotel_dialog)
	hotel_name_field.text_submitted.connect(func(_t): _on_create_confirmed())
	hotel_list.item_selected.connect(_on_hotel_selected)
	hotel_list.item_activated.connect(_on_hotel_activated)
	_set_hotel_buttons_state(false)
	_load_hotels()


func _apply_translations() -> void:
	title_label.text = GameState.T("dashboard.title")
	btn_new_hotel.text = GameState.T("dashboard.btn.new_hotel")
	btn_tutorial.text = GameState.T("dashboard.btn.tutorial")
	btn_play_hotel.text = GameState.T("dashboard.btn.play_hotel")
	btn_delete_hotel.text = GameState.T("dashboard.btn.delete_hotel")
	btn_logout.text = GameState.T("menu.btn.main_menu")


func _load_hotels() -> void:
	status_label.text = GameState.T("hotel_select.status.loading")
	hotel_list.clear()
	_set_hotel_buttons_state(false)
	Api.get_json("/api/hotels", _on_hotels_loaded)


func _on_hotels_loaded(success: bool, data: Dictionary) -> void:
	if not success:
		status_label.text = GameState.T("api.error.network")
		return

	var hotels_raw: Variant = data.get("hotels", data.get("data", []))
	_hotels = hotels_raw if hotels_raw is Array else []

	hotel_list.clear()
	if _hotels.is_empty():
		status_label.text = GameState.T("dashboard.status.no_hotels")
		return

	status_label.text = ""
	for hotel in _hotels:
		var entry := "%s  •  Level %d  •  %s Gold" % [
			hotel.get("name", "?"),
			int(hotel.get("level", 1)),
			_format_money(int(hotel.get("money", 0)))
		]
		hotel_list.add_item(entry)


func _on_hotel_selected(_index: int) -> void:
	_set_hotel_buttons_state(true)


func _on_hotel_activated(index: int) -> void:
	_start_hotel(index)


func _set_hotel_buttons_state(enabled: bool) -> void:
	btn_play_hotel.disabled = not enabled
	btn_delete_hotel.disabled = not enabled


func _on_new_hotel_pressed() -> void:
	hotel_name_field.text = ""
	dialog_error.text = ""
	new_hotel_overlay.visible = true
	hotel_name_field.grab_focus()


func _close_new_hotel_dialog() -> void:
	new_hotel_overlay.visible = false


func _on_create_confirmed() -> void:
	var hotel_name := hotel_name_field.text.strip_edges()
	if hotel_name.is_empty():
		dialog_error.text = GameState.T("dashboard.new_hotel.error.name_empty")
		return

	btn_create.disabled = true
	Api.post_json("/api/hotels", {
		"name": hotel_name,
		"start_plot_x": 2,
		"start_plot_y": 4
	}, _on_hotel_created)


func _on_hotel_created(success: bool, data: Dictionary) -> void:
	btn_create.disabled = false
	if not success or not data.get("success", false):
		dialog_error.text = data.get("message", GameState.T("api.error.network"))
		return

	_close_new_hotel_dialog()
	_load_hotels()


func _on_delete_hotel_pressed() -> void:
	var selected := hotel_list.get_selected_items()
	if selected.is_empty():
		return
	var index := selected[0]
	if index >= _hotels.size():
		return

	var hotel_id: int = _hotels[index].get("id", -1)
	btn_delete_hotel.disabled = true
	Api.post_json("/api/hotel/delete", {"hotel_id": hotel_id}, _on_hotel_deleted)


func _on_hotel_deleted(success: bool, data: Dictionary) -> void:
	btn_delete_hotel.disabled = false
	if not success or not data.get("success", false):
		status_label.text = data.get("message", GameState.T("api.error.network"))
		return
	_load_hotels()


func _on_play_hotel_pressed() -> void:
	var selected := hotel_list.get_selected_items()
	if selected.is_empty():
		return
	_start_hotel(selected[0])


func _start_hotel(index: int) -> void:
	if index >= _hotels.size():
		return
	GameState.select_hotel(_hotels[index])
	# TODO: get_tree().change_scene_to_file("res://scenes/ingame/Ingame.tscn")


func _on_tutorial_pressed() -> void:
	pass # TODO: Tutorial-Szene


func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")


func _format_money(amount: int) -> String:
	var s := str(amount)
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "." + result
		result = s[i] + result
		count += 1
	return result
