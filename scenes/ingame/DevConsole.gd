extends CanvasLayer
class_name DevConsole
## ANG-174 – Dev-Konsole. Nur im Debug-Build aktiv (OS.is_debug_build()).
## Toggle: F12. Befehlsformat: name:wert (z.B. set-money:50000).

@onready var _panel:     PanelContainer  = $Panel
@onready var _header:    HBoxContainer   = $Panel/Margin/VBox/Header
@onready var _log_vbox:  VBoxContainer   = $Panel/Margin/VBox/LogScroll/LogVBox
@onready var _scroll:    ScrollContainer = $Panel/Margin/VBox/LogScroll
@onready var _input:     LineEdit        = $Panel/Margin/VBox/InputRow/InputField
@onready var _close_btn: Button          = $Panel/Margin/VBox/Header/CloseBtn

var _hotel:       Dictionary = {}
var _hud:         IngameHud
var _clock:       IngameClock
var _was_paused:  bool    = true
var _dragging:    bool    = false
var _drag_offset: Vector2 = Vector2.ZERO

const CLR_OK   := Color(0.15, 0.90, 0.30, 1.0)
const CLR_ERR  := Color(0.95, 0.25, 0.20, 1.0)
const CLR_INFO := Color(0.55, 0.75, 0.55, 1.0)
const CLR_CMD  := Color(0.90, 0.90, 0.90, 1.0)


func configure(hotel: Dictionary, hud: IngameHud, clock: IngameClock) -> void:
	_hotel = hotel
	_hud   = hud
	_clock = clock
	_close_btn.pressed.connect(_close)
	_input.text_submitted.connect(_on_input_submitted)
	_header.gui_input.connect(_on_header_gui_input)
	_header.mouse_default_cursor_shape = Control.CURSOR_MOVE
	_log("Dev-Konsole bereit. Tippe \"help\" für alle Befehle.", CLR_INFO)


func toggle() -> void:
	if visible:
		_close()
	else:
		_open()


# ── Öffnen / Schließen ────────────────────────────────────────────────────────

func _open() -> void:
	_was_paused = _clock.is_paused()
	_clock.pause()
	visible = true
	_input.grab_focus()


func _close() -> void:
	visible = false
	if not _was_paused:
		_clock.resume()


func _on_header_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_dragging    = true
				_drag_offset = _panel.position - get_viewport().get_mouse_position()
			else:
				_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		var new_pos := get_viewport().get_mouse_position() + _drag_offset
		var vp      := get_viewport().get_visible_rect().size
		new_pos.x    = clampf(new_pos.x, 0.0, vp.x - _panel.size.x)
		new_pos.y    = clampf(new_pos.y, 0.0, vp.y - _panel.size.y)
		_panel.position = new_pos


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


# ── Eingabe ───────────────────────────────────────────────────────────────────

func _on_input_submitted(cmd: String) -> void:
	_input.clear()
	_execute(cmd.strip_edges())


# ── Befehlsverarbeitung ───────────────────────────────────────────────────────

func _execute(cmd: String) -> void:
	if cmd.is_empty():
		return
	_log("> " + cmd, CLR_CMD)

	var hotel_id: int = _hotel.get("id", -1)
	var parts         := cmd.split(":", false, 1)
	var cmd_name      := parts[0].to_lower().strip_edges()
	var val_s         := parts[1].strip_edges() if parts.size() > 1 else ""

	match cmd_name:
		"help":
			_log("Verfügbare Befehle:", CLR_INFO)
			_log("  set-money:50000   – Setzt Kapital", CLR_INFO)
			_log("  set-day:10        – Setzt Tag", CLR_INFO)
			_log("  set-time:1320     – Setzt Uhrzeit (360=06:00 bis 1439=23:59)", CLR_INFO)
			_log("  get-time:2200     – HHMM → Spielminuten", CLR_INFO)
			_log("  save              – Quicksave auslösen", CLR_INFO)

		"set-money":
			if not val_s.is_valid_int():
				_log("Fehler: Wert muss eine ganze Zahl sein.", CLR_ERR)
				return
			var amount := int(val_s)
			if amount < 0:
				_log("Fehler: Wert muss >= 0 sein.", CLR_ERR)
				return
			_hotel["money"] = float(amount)
			SaveManager.update_hotel(hotel_id, { "money": float(amount) })
			_hud.update_money(float(amount))
			_log("Kapital gesetzt auf %s €." % _fmt_money(amount), CLR_OK)

		"set-day":
			if not val_s.is_valid_int():
				_log("Fehler: Wert muss eine ganze Zahl sein.", CLR_ERR)
				return
			var day := int(val_s)
			if day < 1:
				_log("Fehler: Tag muss >= 1 sein.", CLR_ERR)
				return
			_hotel["day"] = day
			SaveManager.update_hotel(hotel_id, { "day": day })
			_hud.update_day(day)
			_log("Tag gesetzt auf %d." % day, CLR_OK)

		"set-time":
			if not val_s.is_valid_int():
				_log("Fehler: Wert muss eine ganze Zahl (360–1439) sein.", CLR_ERR)
				return
			var mins := int(val_s)
			if mins < 360 or mins > 1439:
				_log("Fehler: Wert muss zwischen 360 (06:00) und 1439 (23:59) liegen.", CLR_ERR)
				return
			_clock.set_game_time(mins)
			_log("Uhrzeit gesetzt auf %02d:%02d." % [int(mins / 60.0), mins % 60], CLR_OK)

		"get-time":
			if val_s.is_empty() or not val_s.is_valid_int():
				_log("Fehler: Format HHMM, z.B. get-time:2200", CLR_ERR)
				return
			var padded := val_s.lpad(4, "0")
			var h      := int(padded.left(2))
			var m      := int(padded.right(2))
			if h > 23 or m > 59:
				_log("Fehler: Ungültige Uhrzeit.", CLR_ERR)
				return
			_log("%02d:%02d = %d Spielminuten" % [h, m, h * 60 + m], CLR_INFO)

		"save":
			if hotel_id < 0:
				_log("Fehler: Kein Hotel geladen.", CLR_ERR)
				return
			SaveManager.update_hotel(hotel_id, {
				"day":       _hotel.get("day",   1),
				"money":     _hotel.get("money", 0.0),
				"game_time": _clock.get_game_time(),
			})
			SaveManager.save_quick(hotel_id)
			Toast.show(GameState.T("toast.quicksave"))
			_log("Quicksave gespeichert.", CLR_OK)

		_:
			_log("Unbekannter Befehl: \"%s\". Tippe \"help\"." % cmd_name, CLR_ERR)


# ── Hilfsfunktionen ───────────────────────────────────────────────────────────

func _log(text: String, color: Color = CLR_OK) -> void:
	var lbl := Label.new()
	lbl.text             = text
	lbl.autowrap_mode    = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", color)
	_log_vbox.add_child(lbl)
	call_deferred("_scroll_to_bottom")


func _scroll_to_bottom() -> void:
	if is_instance_valid(_scroll):
		_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)


func _fmt_money(amount: int) -> String:
	var s      := str(amount)
	var result := ""
	var count  := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "." + result
		result = s[i] + result
		count += 1
	return result
