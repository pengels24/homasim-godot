extends PanelContainer

signal sig_clicked(party: GuestParty)
signal sig_reject_requested(party: GuestParty) # <--- NEU: Das Signal für die Rezeption

enum Mode { WAITING, ACTIVE, CHECKOUT }

var current_mode: Mode = Mode.WAITING
var current_party: GuestParty = null
var _pulse_tween: Tween = null
var _is_new: bool = false # Für deine späteren Settings

@onready var _name_label: Label = %GuestName
@onready var _details_label: Label = %GuestDetails
@onready var _icon: TextureRect = %Icon

# Die neuen edlen Rahmen
@onready var _selection_border: Panel = %SelectionBorder
@onready var _pulse_border: Panel = %PulseBorder

# Der neue Reject-Button - und Aufpreis-Symbol
@onready var _btn_reject: TextureButton = %RejectButton
@onready var surcharge_icon: TextureRect = %SurchargeIcon


# =============================================================================
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_selection_border.hide()
	_pulse_border.hide()

	# Setup für den Hover-Button
	_btn_reject.modulate.a = 0.0
	_btn_reject.self_modulate = Color("e53935")
	_btn_reject.tooltip_text = GameState.T("reception.btn.decline")
	_btn_reject.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_btn_reject.pressed.connect(_on_reject_pressed)


# =============================================================================
func populate(party: GuestParty, mode: Mode, is_new: bool = false) -> void:
	current_party = party
	current_mode = mode
	_is_new = is_new

	_name_label.text = party.get_display_name()

	# Icon aus DB laden
	var def: Dictionary = GuestDefinitions.ALL.get(party.type, {})
	var icon_path: String = def.get("icon", "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		_icon.texture = load(icon_path)

	if surcharge_icon:
		surcharge_icon.visible = party.pays_surcharge

	match current_mode:
		Mode.WAITING:
			var night_str = "1 Nacht" if party.stay_days == 1 else str(party.stay_days) + " Nächte"
			_details_label.text = night_str + " | " + party.get_type_name()
			_build_waiting_tooltip(def)

			if _is_new:
				_start_golden_pulse()

		Mode.ACTIVE:
			var night_str = "1 Nacht" if party.stay_days == 1 else str(party.stay_days) + " Nächte"
			_details_label.text = "Noch " + night_str
			mouse_filter = Control.MOUSE_FILTER_IGNORE
			_build_active_tooltip()

		Mode.CHECKOUT:
			var est_price = party.base_price * float(party.total_stay_days) * (party.satisfaction / 100.0)
			_details_label.text = "Zimmer " + party.room_id + " | " + "%.0f" % est_price + " €"
			tooltip_text = ""


# =============================================================================
# INTERAKTION
# =============================================================================

# =============================================================================
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:

		# SETTINGS-VORBEREITUNG: Puls bei Klick abbrechen
		if _is_new and _pulse_tween:
			_stop_golden_pulse()
			_is_new = false # Gilt jetzt als "gesehen"

		if current_mode in [Mode.WAITING, Mode.CHECKOUT]:
			sig_clicked.emit(current_party)


# ---> NEU: Hover- und Klick-Logik für den Reject-Button
# =============================================================================
func _on_mouse_entered() -> void:
	# Den Button nur zeigen, wenn der Gast in der Warteschlange steht
	if current_mode == Mode.WAITING:
		_btn_reject.modulate.a = 1.0


# =============================================================================
func _on_mouse_exited() -> void:
	# Blendet den Button nur aus, wenn die Maus WIRKLICH die gesamte Kachel verlassen hat
	if not get_global_rect().has_point(get_global_mouse_position()):
		_btn_reject.modulate.a = 0.0


# =============================================================================
func _on_reject_pressed() -> void:
	if _btn_reject.modulate.a > 0.0:
		sig_reject_requested.emit(current_party)


# =============================================================================
func set_highlight(active: bool) -> void:
	# Edel: Nur den Rahmen umschalten, nicht die Karte einfärben!
	_selection_border.visible = active


# =============================================================================
# PULS LOGIK
# =============================================================================

# =============================================================================
func _start_golden_pulse() -> void:
	_pulse_border.show()
	if EffectManager.has_method("start_ui_pulse"):
		_pulse_tween = EffectManager.start_ui_pulse(_pulse_border)


# =============================================================================
func _stop_golden_pulse() -> void:
	if _pulse_tween:
		if EffectManager.has_method("stop_ui_pulse"):
			EffectManager.stop_ui_pulse(_pulse_border, _pulse_tween)
		_pulse_tween = null
	_pulse_border.hide()


# =============================================================================
# TOOLTIPS
# =============================================================================

# =============================================================================
func _build_waiting_tooltip(def: Dictionary) -> void:
	var tt := "Gruppe:\n"

	# 1. Rollen sauber über das Translation-System auflösen
	for member in current_party.members:
		var role_key: String = "guest.member.type." + str(member.role)
		var display_role: String = GameState.T(role_key)
		tt += "• %s (%s)\n" % [member.name, display_role]

	var budget_min: int = def.get("min_base_price", 0)
	var budget_max: int = def.get("max_base_price", 0)
	tt += "\nBudget: %d - %d € / Nacht" % [budget_min, budget_max]

	# 2. Anforderungen (z.B. WLAN)
	var reqs: Array = def.get("requirements", [])
	if not reqs.is_empty():
		tt += "\nAnforderungen: " + ", ".join(reqs)

	# 3. Bevorzugte Zimmer über das Translation-System auflösen
	var pref: Array = def.get("preferred_rooms", [])
	if not pref.is_empty():
		var pref_names := []
		for r_id in pref:
			var room_key: String = "room.type." + str(r_id)
			pref_names.append(GameState.T(room_key))

		tt += "\nBevorzugt: " + ", ".join(pref_names)

	tooltip_text = tt


# =============================================================================
func _build_active_tooltip() -> void:
	# 1. Allgemeine Infos zum Aufenthalt
	var tt := "🏨 " + GameState.T("reception.tooltip.room") + " " + current_party.room_id + "\n"
	tt += "👥 " + GameState.T("reception.tooltip.group", current_party.members.size()) + "\n"
	tt += "🌙 " + GameState.T("reception.tooltip.nights", current_party.stay_days) + "\n"
	tt += "😊 " + GameState.T("reception.tooltip.satisfaction", round(current_party.satisfaction * 100)) + "\n\n"

	if current_party.pays_surcharge:
		tt += "🪙 " + GameState.T("reception.tooltip.surcharge") + "\n\n"

	# 2. Die Namen der Gäste auflisten (wie im Waiting-Tooltip)
	tt += GameState.T("reception.tooltip.guests") + "\n"
	for member in current_party.members:
		var role_key: String = "guest.member.type." + str(member.role)
		var display_role: String = GameState.T(role_key)
		tt += "• %s (%s)\n" % [member.name, display_role]

	tooltip_text = tt


# =============================================================================
func _exit_tree() -> void:
	_stop_golden_pulse()
