extends Node

## Shared Game State – speichert spielübergreifende Daten wie den eingeloggten User
## und das aktuell ausgewählte Hotel.

signal hotel_selected(hotel_data: Dictionary)
signal user_logged_in(user_data: Dictionary)
signal user_logged_out()

var current_user: Dictionary = {}
var selected_hotel: Dictionary = {}


func is_logged_in() -> bool:
	return not current_user.is_empty()


func login(user_data: Dictionary) -> void:
	current_user = user_data
	user_logged_in.emit(user_data)


func logout() -> void:
	current_user = {}
	selected_hotel = {}
	Api.session_cookie = ""
	user_logged_out.emit()


func select_hotel(hotel_data: Dictionary) -> void:
	selected_hotel = hotel_data
	hotel_selected.emit(hotel_data)
