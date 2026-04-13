extends Control

@onready var hotel_list: ItemList = $CenterContainer/VBoxContainer/HotelList
@onready var select_button: Button = $CenterContainer/VBoxContainer/SelectButton
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel

var _hotels: Array = []


func _ready() -> void:
	select_button.pressed.connect(_on_select_pressed)
	hotel_list.item_selected.connect(_on_item_selected)
	_load_hotels()


func _load_hotels() -> void:
	status_label.text = "Lade Hotels..."
	select_button.disabled = true
	Api.get_json("/api/hotels", _on_hotels_loaded)


func _on_hotels_loaded(success: bool, data: Dictionary) -> void:
	if not success:
		status_label.text = "Fehler: " + data.get("error", "Hotels konnten nicht geladen werden.")
		return

	# Erwartet: {"hotels": [...]} oder direkt ein Array in data["data"]
	var hotels_raw: Variant = data.get("hotels", data.get("data", []))
	if hotels_raw is Array:
		_hotels = hotels_raw
	else:
		_hotels = []

	if _hotels.is_empty():
		status_label.text = "Keine Hotels gefunden."
		return

	status_label.text = ""
	hotel_list.clear()
	for hotel in _hotels:
		var name: String = hotel.get("name", "Unbekanntes Hotel")
		hotel_list.add_item(name)


func _on_item_selected(_index: int) -> void:
	select_button.disabled = false


func _on_select_pressed() -> void:
	var selected_items := hotel_list.get_selected_items()
	if selected_items.is_empty():
		return

	var index := selected_items[0]
	if index >= _hotels.size():
		return

	GameState.select_hotel(_hotels[index])
	# TODO: Zur Ingame-Szene wechseln
	# get_tree().change_scene_to_file("res://scenes/ingame/Ingame.tscn")
