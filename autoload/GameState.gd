extends Node

## Shared Game State – speichert spielübergreifende Daten wie den eingeloggten User
## und das aktuell ausgewählte Hotel.

signal hotel_selected(hotel_data: Dictionary)
signal user_logged_in(user_data: Dictionary)
signal user_logged_out()

var current_user:      Dictionary = {}
var current_manager:   Dictionary = {}
var selected_hotel:    Dictionary = {}   # Legacy – PHP-API, wird schrittweise ersetzt
var active_hotel_id:   int        = -1   # SaveManager-Hotel-ID; -1 = kein Hotel gewählt
var active_profile_id: int        = -1   # SaveManager-Profil-ID; -1 = kein Profil gewählt
var active_profile:    Dictionary = {}   # Aktives Manager-Profil
var snap_to_grid:      bool       = true  # Tile-Snap im Baumodus (Settings-Toggle)


func is_logged_in() -> bool:
	return not current_user.is_empty()


func has_manager() -> bool:
	return not current_manager.is_empty()


func login(user_data: Dictionary) -> void:
	current_user = user_data
	var manager = user_data.get("manager", null)
	current_manager = manager if manager is Dictionary else {}
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


func logout() -> void:
	current_user = {}
	current_manager = {}
	selected_hotel = {}
	SessionManager.clear()
	user_logged_out.emit()


func select_profile(profile: Dictionary) -> void:
	active_profile    = profile
	active_profile_id = profile.get("id", -1)


func select_hotel(hotel_data: Dictionary) -> void:
	selected_hotel  = hotel_data
	active_hotel_id = hotel_data.get("id", -1)
	hotel_selected.emit(hotel_data)
