# GameState - autoload

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

# interaktion
@warning_ignore("unused_signal")
signal sig_room_hovered(room: Node2D, is_hovered: bool)
@warning_ignore("unused_signal")
signal sig_room_clicked(room: Node2D)

# globale signale
@warning_ignore("unused_signal")
signal sig_dev_spawn_guests(count: int)

signal sig_configs_reloaded()

# REGISTRY - Zentrales Verzeichnis aller geladenen Räume.
## Struktur: { "room_id": { "scene_path": String, "def": Dictionary } }
var room_registry: Dictionary = {}
## Zentrales Verzeichnis aller Bau-Kategorien.
var room_category_registry: Dictionary = {}
## Zentrales Verzeichnis für den Master-Tagesplan.
var daily_schedule_registry: Array = []

# =============================================================================

var current_user:      Dictionary = {}
var current_manager:   Dictionary = {}
var selected_hotel:    Dictionary = {}   # Legacy – PHP-API, wird schrittweise ersetzt
var active_hotel_id:   int        = -1   # SaveManager-Hotel-ID; -1 = kein Hotel gewählt
var active_profile_id: int        = -1   # SaveManager-Profil-ID; -1 = kein Profil gewählt
var active_profile:    Dictionary = {}   # Aktives Manager-Profil
var snap_to_grid:      bool       = true  # Tile-Snap im Baumodus (Settings-Toggle)


# =============================================================================
func _ready() -> void:
	load_room_category_config()
	load_room_config()
	load_daily_schedule_config()
	# Das macht diesen Autoload immun gegen die Godot-Pause!
	process_mode = Node.PROCESS_MODE_ALWAYS


# =============================================================================
## Lädt die room_categories.json und baut das room_category_registry auf.
func load_room_category_config() -> void:
	var config_path := "res://config/room_categories.json"

	if not FileAccess.file_exists(config_path):
		push_error("GameState: config/room_categories.json nicht gefunden!")
		return

	var file := FileAccess.open(config_path, FileAccess.READ)
	var parsed_data = JSON.parse_string(file.get_as_text())

	if type_string(typeof(parsed_data)) != "Dictionary" or not parsed_data.has("room_categories"):
		push_error("GameState: Fehler beim Parsen der room_categories.json!")
		return

	room_category_registry = parsed_data["room_categories"]
	print("GameState: Room Category Registry geladen. ", room_category_registry.size(), " Kategorien registriert.")


# =============================================================================
## Lädt die rooms.json und baut das room_registry auf.
## Kann zur Laufzeit erneut aufgerufen werden (z.B. über die Entwickler-Konsole).
func load_room_config() -> void:
	var config_path := "res://config/rooms.json"

	if not FileAccess.file_exists(config_path):
		push_error("GameState: config/rooms.json nicht gefunden!")
		return

	var file := FileAccess.open(config_path, FileAccess.READ)
	var json_string := file.get_as_text()
	var parsed_data = JSON.parse_string(json_string)

	if type_string(typeof(parsed_data)) != "Dictionary" or not parsed_data.has("rooms"):
		push_error("GameState: Fehler beim Parsen der rooms.json!")
		return

	room_registry.clear()

	for room_entry in parsed_data["rooms"]:
		var r_id: String = room_entry.get("id", "")
		var scene_path: String = room_entry.get("scene_path", "")
		var script_path: String = room_entry.get("script_path", "")

		if r_id.is_empty() or script_path.is_empty():
			continue

		# Skript laden, um die get_definition() abzurufen
		var room_script = load(script_path)
		if room_script and room_script.has_method("get_definition"):
			var def: Dictionary = room_script.get_definition()

			# Im Registry speichern
			room_registry[r_id] = {
				"scene_path": scene_path,
				"def": def
			}

	print("GameState: Room Registry geladen. ", room_registry.size(), " Räume registriert.")


# =============================================================================
## Lädt die daily_schedule.json und baut das daily_schedule_registry auf.
func load_daily_schedule_config() -> void:
	var config_path := "res://config/daily_schedule.json"

	if not FileAccess.file_exists(config_path):
		push_error("GameState: config/daily_schedule.json nicht gefunden!")
		return

	var file := FileAccess.open(config_path, FileAccess.READ)
	var content := file.get_as_text()
	file.close()

	var parsed_data = JSON.parse_string(content)
	if typeof(parsed_data) == TYPE_ARRAY:
		daily_schedule_registry.clear()

		for entry in parsed_data:
			if typeof(entry) == TYPE_DICTIONARY and entry.has("hour") and entry.has("event"):
				var h: int = int(entry["hour"])
				var m: int = int(entry.get("minute", 0))
				var trigger_time: int = (h * 60) + m

				daily_schedule_registry.append({
					"trigger_time": trigger_time,
					"event": entry["event"]
				})
			else:
				push_error("GameState: Ungültiges Event-Format in daily_schedule.json.")

		daily_schedule_registry.sort_custom(func(a, b): return a["trigger_time"] < b["trigger_time"])
		print("GameState: Daily Schedule geladen. ", daily_schedule_registry.size(), " Events registriert.")

	else:
		push_error("GameState: Ungültiges JSON-Format (kein Array) in: " + config_path)


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
func T(key: String, val1: Variant = null, val2: Variant = null, val3: Variant = null) -> String:
	var text := TranslationServer.translate(key)
	if val1 != null:
		text = text.replace("###", str(val1))
	if val2 != null:
		text = text.replace("***", str(val2))
	if val3 != null:
		text = text.replace("+++", str(val3))
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
	var hotel_rep: int = int(hotel_data.get("rep", 500))
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

	if TechtreeManager:
		var techtree_data = hotel_data.get("techtree", {"techs": hotel_data.get("unlocked_techs", []), "tiers": ["1"]})
		TechtreeManager.load_state(techtree_data)
		
	if TutorialManager:
		var tutorials_data = hotel_data.get("tutorials", [])
		TutorialManager.load_state(tutorials_data)
		
	if QuestManager:
		QuestManager.check_and_activate_quests()


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
## Prüft anhand der Raum-Definition, ob eine Einrichtung aktuell geöffnet ist.
## open_from = 0 und open_to = 0 bedeutet 24/7 geöffnet.
func is_facility_open(def: Dictionary) -> bool:
	var open_from: int = def.get("open_from", 0)
	var open_to: int = def.get("open_to", 0)

	if open_from == 0 and open_to == 0:
		return true

	var current_time: int = TimeManager.get_game_time()

	if open_from < open_to:
		# Regulärer Tag (z.B. 07:00 bis 22:00)
		return current_time >= open_from and current_time < open_to

	else:
		# Nachtbetrieb über Mitternacht (z.B. 22:00 bis 04:00)
		return current_time >= open_from or current_time < open_to


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
	var base_exp = 500 # <--- NEU: Vorher 100. Das erste Level dauert nun 5x so lang.

	if level <= 1:
		return base_exp
	elif level <= 5:
		return int(base_exp * pow(1.5, level - 1))
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

@warning_ignore("unused_signal")
signal sig_room_built(room_id: String)


# =============================================================================
func add_rep(amount: int) -> void:
	var current_rep: int = selected_hotel.get("rep", 500)
	var rep_max: int = selected_hotel.get("rep_max", 1000)

	current_rep += amount

	# Begrenzung: Ruf sinkt nicht unter 0 und steigt nicht über Max
	current_rep = clamp(current_rep, 0, rep_max)

	selected_hotel["rep"] = current_rep
	sig_hotel_rep_changed.emit(current_rep, rep_max)


# =============================================================================
# BALANCING & BERECHNUNGEN
# =============================================================================

# =============================================================================
## Berechnet die EXP beim Check-in.
func calc_checkin_exp(party: GuestParty) -> int:
	var def: Dictionary = GuestDefinitions.ALL.get(party.type, {})
	var base_exp: int = def.get("base_exp", 10)

	# Wir geben fürs Erste NUR den flachen Basiswert aus der Definition.
	# Eine Familie gibt also genau 15 EXP, ein Single genau 10.
	# (Die Nächte belohnen wir später lieber separat beim Check-out!)
	return base_exp


# =============================================================================
## Berechnet den Ruf-Verlust beim Rauswurf.
func calc_reject_rep_penalty(party: GuestParty) -> int:
	# Werte aus der Definition holen, mit Fallback auf 5, falls noch nicht eingetragen
	var def: Dictionary = GuestDefinitions.ALL.get(party.type, {})
	var penalty: int = def.get("rep_penalty", 5)

	# Hier reicht meist der reine Basiswert der Gruppe ohne Formel
	return penalty


# =============================================================================
## Hilfsfunktion für MapGrid.gd und das Bau-Menü, um den Szenen-Pfad zu holen.
func get_room_scene_path(room_type_id: String) -> String:
	if room_registry.has(room_type_id):
		return room_registry[room_type_id].get("scene_path", "")
	return ""


# =============================================================================
func reload_all_configs() -> void:
	load_room_category_config()
	load_room_config()
	load_daily_schedule_config()
	sig_configs_reloaded.emit()