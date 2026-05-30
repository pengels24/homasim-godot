extends Node

## Shared Game State – speichert spielübergreifende Daten wie den eingeloggten User
## und das aktuell ausgewählte Hotel.

signal hotel_selected(hotel_data: Dictionary)
signal user_logged_in(user_data: Dictionary)
signal user_logged_out()

signal sig_hotel_name_changed(new_name: String)
signal sig_hotel_level_changed(new_level: int)
signal sig_hotel_stars_changed(stars: int)
signal sig_hotel_money_changed(new_money: int)
signal sig_hotel_guests_active_changed(guests_active: int)
signal sig_hotel_guests_checkin_changed(guests_checkin: int)
signal sig_hotel_guests_checkout_changed(guests_checkout: int)
signal sig_hotel_exp_changed(exp: int, exp_max: int)
signal sig_hotel_rep_changed(rep: int, rep_max: int)
signal sig_hotel_fp_changed(new_fp: String)
signal sig_hotel_day_changed(day_number: int)
signal sig_hotel_time_changed(time_string: String)

signal sig_hotel_level_up(new_level: int)

# =============================================================================

var current_user:      Dictionary = {}
var current_manager:   Dictionary = {}
var selected_hotel:    Dictionary = {}   # Legacy – PHP-API, wird schrittweise ersetzt
var active_hotel_id:   int        = -1   # SaveManager-Hotel-ID; -1 = kein Hotel gewählt
var active_profile_id: int        = -1   # SaveManager-Profil-ID; -1 = kein Profil gewählt
var active_profile:    Dictionary = {}   # Aktives Manager-Profil
var snap_to_grid:      bool       = true  # Tile-Snap im Baumodus (Settings-Toggle)


# =============================================================================
func is_logged_in() -> bool:
	return not current_user.is_empty()


# =============================================================================
func has_manager() -> bool:
	return not current_manager.is_empty()


# =============================================================================
func login(user_data: Dictionary) -> void:
	current_user = user_data
	var manager = user_data.get("manager", null)
	current_manager = manager if manager is Dictionary else {}
	user_logged_in.emit(user_data)


# =============================================================================
## Übersetzung mit optionalen Platzhaltern – identisch zu window.T() im Web.
## Beispiel: T("dayend.btn.next_day", 5)  →  "Weiter zu Tag 5"
func T(key: String, val1: Variant = null, val2: Variant = null) -> String:
	var text := TranslationServer.translate(key)
	if val1 != null:
		text = text.replace("###", str(val1))
	if val2 != null:
		text = text.replace("***", str(val2))
	return text


# =============================================================================
func logout() -> void:
	current_user = {}
	current_manager = {}
	selected_hotel = {}
	SessionManager.clear()
	user_logged_out.emit()


# =============================================================================
func select_profile(profile: Dictionary) -> void:
	active_profile    = profile
	active_profile_id = profile.get("id", -1)
	SettingsManager.last_profile_id = active_profile_id
	SettingsManager.save()


# =============================================================================
func select_hotel(hotel_data: Dictionary) -> void:
	selected_hotel  = hotel_data
	active_hotel_id = hotel_data.get("id", -1)
	hotel_selected.emit(hotel_data)

	# vars
	var hotel_name = hotel_data.get("name", "Unbekannt")
	var hotel_level: int = int(hotel_data.get("level", 1))
	var hotel_stars: int = int(hotel_data.get("stars", 0))
	var hotel_money: int = int(hotel_data.get("money", 0))
	var hotel_guests_active: int = int(hotel_data.get("guests_active", 10))
	var hotel_guests_checkin: int = int(hotel_data.get("guests_checkin", 20))
	var hotel_guests_checkout: int = int(hotel_data.get("guests_checkout", 30))
	var hotel_exp: int = int(hotel_data.get("exp", 25))
	var hotel_exp_max: int  = int(hotel_data.get("exp_max", 100))
	var hotel_rep: int = int(hotel_data.get("rep", 200))
	var hotel_rep_max: int  = int(hotel_data.get("rep_max", 1000))
	var hotel_fp: int   = int(hotel_data.get("fp", 0))
	var hotel_day: int   = int(hotel_data.get("day", 0))
	var hotel_time: int  = int(hotel_data.get("game_time", 0))

	# signals
	sig_hotel_name_changed.emit(hotel_name)
	sig_hotel_level_changed.emit(hotel_level)
	sig_hotel_stars_changed.emit(hotel_stars)
	sig_hotel_money_changed.emit(hotel_money)
	sig_hotel_guests_active_changed.emit(hotel_guests_active)
	sig_hotel_guests_checkin_changed.emit(hotel_guests_checkin)
	sig_hotel_guests_checkout_changed.emit(hotel_guests_checkout)
	sig_hotel_exp_changed.emit(hotel_exp, hotel_exp_max)
	sig_hotel_rep_changed.emit(hotel_rep, hotel_rep_max)
	sig_hotel_fp_changed.emit(hotel_fp)
	sig_hotel_day_changed.emit(hotel_day)
	sig_hotel_time_changed.emit(format_game_time(hotel_time))


# =============================================================================
# GLOBALE UTILITY FUNCTIONS (Überall aufrufbar via GameState.format_...)
# =============================================================================

# =============================================================================
## Formatiert Minuten des Tages (z.B. 360) in einen sauberen String ("06:00")
func format_game_time(total_minutes: int) -> String:
	# Wir erzwingen die Ganzzahl-Division, um die Godot-Warnung stumm zu schalten
	var hours: int = int(floor(total_minutes / 60.0))
	var minutes: int = total_minutes % 60
	return "%02d:%02d" % [hours, minutes]


# =============================================================================
## Formatiert einen Unix-Timestamp in einen lesbaren String ("29.05.2026 09:05")
## Inklusive automatischer Korrektur der lokalen Zeitzone des Spielers!
func format_timestamp(ts: int) -> String:
	if ts == 0:
		return ""

	# Zeitzonen-Abweichung (Bias) des aktuellen PCs in Minuten abfragen
	var tz_bias: int = Time.get_time_zone_from_system().get("bias", 0)

	# Die Minuten in Sekunden umrechnen und auf den UTC-Timestamp addieren
	var local_ts: int = ts + (tz_bias * 60)

	var dt = Time.get_datetime_dict_from_unix_time(local_ts)
	return "%02d.%02d.%04d %02d:%02d" % [dt["day"], dt["month"], dt["year"], dt["hour"], dt["minute"]]


# # =============================================================================
# ## Formatiert einen Unix-Timestamp in einen lesbaren String ("29.05.2026 09:05")
# func format_timestamp(ts: int) -> String:
# 	if ts == 0:
# 		return ""
# 	var dt = Time.get_datetime_dict_from_unix_time(ts)
# 	return "%02d.%02d.%04d %02d:%02d" % [dt["day"], dt["month"], dt["year"], dt["hour"], dt["minute"]]


# =============================================================================
## Formatiert rohes Geld (z.B. 44900) mit Tausendertrennzeichen ("44.900")
func format_money(amount: int) -> String:
	var s := str(amount)
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "." + result
		result = s[i] + result
		count += 1
	return result


# =============================================================================
func add_money(amount: int) -> void:
	selected_hotel["money"] += amount
	sig_hotel_money_changed.emit(selected_hotel["money"])


# =============================================================================
func add_fp(amount: int) -> void:
	selected_hotel["fp"] += amount
	sig_hotel_fp_changed.emit(selected_hotel["fp"])


# =============================================================================
## Berechnet die benötigte EXP für ein bestimmtes Level basierend auf dem Modell.
func get_xp_needed_for_level(level: int) -> int:
	if level <= 1:
		return 100
	elif level <= 5:
		return int(100 * pow(1.5, level - 1))
	elif level <= 10:
		return int(get_xp_needed_for_level(5) * pow(1.4, level - 5))
	else:
		return int(get_xp_needed_for_level(10) * pow(1.3, level - 10))


# =============================================================================
## Aktualisierte add_exp Funktion mit Level-Up Logik und Überschuss-Transfer
func add_exp(amount: int) -> void:
	var current_exp: int = selected_hotel.get("exp", 0)
	var current_level: int = selected_hotel.get("level", 1)
	var exp_max: int = selected_hotel.get("exp_max", 100)

	current_exp += amount

	# Prüfen, ob ein Level-Up stattgefunden hat (kann auch mehrfach sein)
	while current_exp >= exp_max:
		current_exp -= exp_max
		current_level += 1
		exp_max = get_xp_needed_for_level(current_level)

		# Speichern der neuen Werte im Dictionary
		selected_hotel["level"] = current_level
		selected_hotel["exp"] = current_exp
		selected_hotel["exp_max"] = exp_max

		# Signal für das UI (feuert das levelup-modal)
		sig_hotel_level_up.emit(current_level)

	# Update der Standard-EXP-Anzeige und des Levels im HUD
	selected_hotel["exp"] = current_exp
	sig_hotel_exp_changed.emit(current_exp, exp_max)
	sig_hotel_level_changed.emit(current_level)