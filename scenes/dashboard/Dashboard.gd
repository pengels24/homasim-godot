extends Control

## Dashboard – Hotel-Übersicht mit Manager-Panel und Hotel-Kacheln

@onready var character_display: Control   = $MainArea/ManagerPanel/PanelVBox/CharacterDisplay
@onready var manager_name_lbl:  Label     = $MainArea/ManagerPanel/PanelVBox/ManagerName
@onready var manager_role_lbl:  Label     = $MainArea/ManagerPanel/PanelVBox/ManagerRole
@onready var hotel_count_lbl:   Label     = $MainArea/ManagerPanel/PanelVBox/HotelCount

@onready var title_label:       Label     = $MainArea/HotelSection/Header/TitleLabel
@onready var btn_main_menu:     Button    = $MainArea/HotelSection/Header/BtnMainMenu
@onready var btn_new_hotel:     Button    = $MainArea/HotelSection/Header/BtnNewHotel
@onready var status_label:      Label     = $MainArea/HotelSection/StatusLabel
@onready var hotel_container:   VBoxContainer = $MainArea/HotelSection/Scroll/HotelContainer

@onready var new_hotel_overlay: ColorRect = $NewHotelOverlay
@onready var hotel_name_field:  LineEdit  = $NewHotelOverlay/NewHotelPanel/VBox/HotelNameField
@onready var dialog_error:      Label     = $NewHotelOverlay/NewHotelPanel/VBox/DialogError
@onready var btn_create:        Button    = $NewHotelOverlay/NewHotelPanel/VBox/DialogButtons/BtnCreate
@onready var btn_cancel:        Button    = $NewHotelOverlay/NewHotelPanel/VBox/DialogButtons/BtnCancel

var _hotels: Array = []

const SKIN_COLORS := {
	"hell":   Color(0.95, 0.82, 0.70),
	"mittel": Color(0.76, 0.57, 0.38),
	"dunkel": Color(0.40, 0.26, 0.16),
}
const HAIR_COLORS := {
	"blond":     Color(0.95, 0.85, 0.40),
	"braun":     Color(0.45, 0.30, 0.15),
	"schwarz":   Color(0.12, 0.10, 0.10),
	"hellblond": Color(0.98, 0.95, 0.72),
	"rot":       Color(0.72, 0.22, 0.10),
	"grau":      Color(0.65, 0.65, 0.65),
}
const OUTFIT_COLORS := {
	"anzug_schwarz": Color(0.12, 0.12, 0.16),
	"anzug_grau":    Color(0.42, 0.42, 0.46),
	"casual":        Color(0.22, 0.45, 0.72),
	"uniform":       Color(0.10, 0.38, 0.22),
}


func _ready() -> void:
	_setup_manager_panel()
	btn_main_menu.pressed.connect(_on_main_menu_pressed)
	btn_new_hotel.pressed.connect(_on_new_hotel_pressed)
	btn_create.pressed.connect(_on_create_confirmed)
	btn_cancel.pressed.connect(_close_new_hotel_dialog)
	hotel_name_field.text_submitted.connect(func(_t): _on_create_confirmed())
	title_label.text = GameState.T("dashboard.title")
	btn_new_hotel.text = GameState.T("dashboard.btn.new_hotel")
	btn_main_menu.text = GameState.T("menu.btn.main_menu")
	_load_hotels()


func _setup_manager_panel() -> void:
	var m := GameState.current_manager
	if m.is_empty():
		return

	var skin:   String = m.get("appearance_skin",   "hell")
	var hair:   String = m.get("appearance_hair",   "braun")
	var outfit: String = m.get("appearance_outfit", "anzug_schwarz")
	var gender: String = m.get("gender", "m")
	var name_text: String = m.get("name", "")

	manager_name_lbl.text = name_text
	manager_role_lbl.text = "MANAGER · LEVEL 1"

	if is_instance_valid(character_display) and character_display.has_method("update_appearance"):
		character_display.update_appearance(
			gender,
			SKIN_COLORS.get(skin,   Color(0.95, 0.82, 0.70)),
			HAIR_COLORS.get(hair,   Color(0.45, 0.30, 0.15)),
			OUTFIT_COLORS.get(outfit, Color(0.12, 0.12, 0.16))
		)


func _load_hotels() -> void:
	status_label.text = GameState.T("hotel_select.status.loading")
	for child in hotel_container.get_children():
		child.queue_free()
	Api.get_json("/api/hotels", _on_hotels_loaded)


func _on_hotels_loaded(success: bool, data: Dictionary) -> void:
	if not success:
		status_label.text = GameState.T("api.error.network")
		return

	var hotels_raw: Variant = data.get("hotels", data.get("data", []))
	_hotels = hotels_raw if hotels_raw is Array else []
	hotel_count_lbl.text = "%d Hotel%s" % [_hotels.size(), "s" if _hotels.size() != 1 else ""]

	for child in hotel_container.get_children():
		child.queue_free()

	if _hotels.is_empty():
		status_label.text = GameState.T("dashboard.status.no_hotels")
		return

	status_label.text = ""
	for i in _hotels.size():
		hotel_container.add_child(_create_hotel_card(_hotels[i], i))


func _create_hotel_card(hotel: Dictionary, index: int) -> Control:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color        = Color(0.10, 0.10, 0.13, 1)
	style.corner_radius_top_left    = 8
	style.corner_radius_top_right   = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left   = 24.0
	style.content_margin_right  = 24.0
	style.content_margin_top    = 20.0
	style.content_margin_bottom = 20.0
	card.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	card.add_child(row)

	# Info-Spalte
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 10)
	row.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = hotel.get("name", "?")
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	info.add_child(name_lbl)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 32)
	info.add_child(stats)
	_add_stat(stats, "LEVEL",   str(int(hotel.get("level",  1))))
	_add_stat(stats, "TAG",     str(int(hotel.get("day",    1))))
	_add_stat(stats, "GÄSTE",   str(int(hotel.get("guests", 0))))
	_add_stat(stats, "KAPITAL", "€ " + _format_money(int(hotel.get("money", 0))))
	_add_stat(stats, "RUF",     str(int(hotel.get("reputation", 0))))

	# Button-Spalte
	var btns := VBoxContainer.new()
	btns.add_theme_constant_override("separation", 8)
	btns.custom_minimum_size = Vector2(160, 0)
	row.add_child(btns)

	var btn_play := Button.new()
	btn_play.text = GameState.T("dashboard.btn.play_hotel")
	btn_play.custom_minimum_size = Vector2(0, 44)
	btn_play.add_theme_color_override("font_color", Color(0.08, 0.06, 0))
	_apply_gold_style(btn_play)
	btn_play.pressed.connect(_start_hotel.bind(index))
	btns.add_child(btn_play)

	var btn_del := Button.new()
	btn_del.text = GameState.T("dashboard.btn.delete_hotel")
	btn_del.custom_minimum_size = Vector2(0, 44)
	btn_del.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	_apply_danger_style(btn_del)
	btn_del.pressed.connect(_delete_hotel.bind(hotel.get("id", -1), btn_del))
	btns.add_child(btn_del)

	return card


func _add_stat(parent: HBoxContainer, key: String, value: String) -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	parent.add_child(col)
	var k := Label.new()
	k.text = key
	k.add_theme_font_size_override("font_size", 11)
	k.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	col.add_child(k)
	var v := Label.new()
	v.text = value
	v.add_theme_font_size_override("font_size", 18)
	v.add_theme_color_override("font_color", Color(0.90, 0.90, 0.90))
	col.add_child(v)


func _apply_gold_style(btn: Button) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.918, 0.702, 0.031)
	s.corner_radius_top_left    = 6
	s.corner_radius_top_right   = 6
	s.corner_radius_bottom_left = 6
	s.corner_radius_bottom_right = 6
	s.content_margin_left   = 16.0
	s.content_margin_right  = 16.0
	s.content_margin_top    = 8.0
	s.content_margin_bottom = 8.0
	btn.add_theme_stylebox_override("normal", s)
	var h := s.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.97, 0.80, 0.15)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", s)


func _apply_danger_style(btn: Button) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.25, 0.08, 0.08)
	s.corner_radius_top_left    = 6
	s.corner_radius_top_right   = 6
	s.corner_radius_bottom_left = 6
	s.corner_radius_bottom_right = 6
	s.content_margin_left   = 16.0
	s.content_margin_right  = 16.0
	s.content_margin_top    = 8.0
	s.content_margin_bottom = 8.0
	btn.add_theme_stylebox_override("normal", s)
	var h := s.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.40, 0.10, 0.10)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", s)


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


func _delete_hotel(hotel_id: int, btn: Button) -> void:
	btn.disabled = true
	Api.post_json("/api/hotel/delete", {"hotel_id": hotel_id}, _on_hotel_deleted)


func _on_hotel_deleted(success: bool, data: Dictionary) -> void:
	if not success or not data.get("success", false):
		status_label.text = data.get("message", GameState.T("api.error.network"))
		return
	_load_hotels()


func _start_hotel(index: int) -> void:
	if index >= _hotels.size():
		return
	GameState.select_hotel(_hotels[index])
	# TODO: get_tree().change_scene_to_file("res://scenes/ingame/Ingame.tscn")


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
