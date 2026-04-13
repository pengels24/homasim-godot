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


## Übersetzung mit optionalen Platzhaltern – identisch zu window.T() im Web.
## Beispiel: T("dayend.btn.next_day", 5)  →  "Weiter zu Tag 5"
func T(key: String, val1: Variant = null, val2: Variant = null) -> String:
	var text := TranslationServer.translate(key)
	if val1 != null:
		text = text.replace("###", str(val1))
	if val2 != null:
		text = text.replace("***", str(val2))
	return text


## Prüft ob die gespeicherte Session noch gültig ist.
## callback: func(logged_in: bool)
func check_session(callback: Callable) -> void:
	if Api.session_cookie == "":
		callback.call(false)
		return
	Api.get_json("/api/auth/me", func(success: bool, data: Dictionary):
		if success and data.get("success", false):
			current_user = data
			callback.call(true)
		else:
			callback.call(false)
	)


func logout() -> void:
	current_user = {}
	selected_hotel = {}
	Api.clear_session()
	user_logged_out.emit()


func select_hotel(hotel_data: Dictionary) -> void:
	selected_hotel = hotel_data
	hotel_selected.emit(hotel_data)
