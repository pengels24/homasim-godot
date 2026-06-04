extends Node

## ANG-143 – Zentrale Session-Persistenz.
## Verantwortlich für: Cookie + Username in user://session.cfg lesen/schreiben,
## Session-Validierung via API.

const _SAVE_PATH := "user://session.cfg"

var saved_username: String = ""


# =============================================================================
func _ready() -> void:
	_load()


# =============================================================================
## Lädt Cookie und Username aus der Datei und setzt Api.session_cookie.
func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(_SAVE_PATH) != OK:
		return
	Api.session_cookie = cfg.get_value("session", "cookie", "")
	saved_username = cfg.get_value("session", "username", "")


# =============================================================================
## Speichert den Session-Cookie persistent.
func save_cookie(cookie: String) -> void:
	var cfg := ConfigFile.new()
	cfg.load(_SAVE_PATH)
	cfg.set_value("session", "cookie", cookie)
	cfg.save(_SAVE_PATH)


# =============================================================================
## Speichert den Username für den nächsten Login.
func save_username(username: String) -> void:
	saved_username = username
	var cfg := ConfigFile.new()
	cfg.load(_SAVE_PATH)
	cfg.set_value("session", "username", username)
	cfg.save(_SAVE_PATH)


# =============================================================================
## Löscht Cookie + Username aus Datei und setzt Api.session_cookie zurück.
func clear() -> void:
	saved_username = ""
	Api.session_cookie = ""
	var cfg := ConfigFile.new()
	cfg.save(_SAVE_PATH)


# =============================================================================
## Prüft ob die gespeicherte Session noch gültig ist.
## callback: func(logged_in: bool)
func check_session(callback: Callable) -> void:
	if Api.session_cookie == "":
		callback.call(false)
		return
	Api.get_json("/api/auth/me", func(success: bool, data: Dictionary):
		if success and data.get("success", false):
			GameState.current_user = data
			var manager = data.get("manager", null)
			GameState.current_manager = manager if manager is Dictionary else {}
			callback.call(true)
		else:
			callback.call(false)
	)
