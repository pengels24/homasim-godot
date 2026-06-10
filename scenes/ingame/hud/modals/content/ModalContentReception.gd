extends PanelContainer

# --- PRELOADS (Pfade ggf. anpassen!) ---
const GUEST_CARD_SCENE = preload("res://scenes/ingame/hud/modals/content/cards/GuestCard.tscn")
const ROOM_CARD_SCENE = preload("res://scenes/ingame/hud/modals/content/cards/RoomCardAvailable.tscn")

# --- UI REFERENZEN ---
@onready var _list_waiting: VBoxContainer = %ListWaiting
@onready var _list_rooms: VBoxContainer = %ListRooms
@onready var _list_active: VBoxContainer = %ListActive
@onready var _list_checkout: VBoxContainer = %ListCheckout

@onready var _list_title_waiting: Label = %LabelVBCWaiting
@onready var _list_title_rooms: Label = %LabelVBCRooms
@onready var _list_title_active: Label = %LabelVBCActive
@onready var _list_title_checkout: Label = %LabelVBCCheckout

@onready var _btn_checkin: Button = %BtnCheckIn
@onready var _btn_checkout: Button = %BtnCheckout


# --- UI Styles ---
# Standard Rezeptions-Styles (aus deinem Screenshot)
var style_rec_normal = preload("res://assets/UI/menu_button_darkblue.tres")
var style_rec_disabled = preload("res://assets/UI/menu_button_darkblue_disabled.tres")

# Grüne Styles
var style_green_normal = preload("res://assets/UI/menu_button_green.tres")
var style_green_hover = preload("res://assets/UI/menu_button_green_hover.tres")
var style_green_pressed = preload("res://assets/UI/menu_button_green_pressed.tres")

# Goldene Styles (die du jetzt anlegst)
var style_gold_normal = preload("res://assets/UI/menu_button_golden.tres")
var style_gold_hover = preload("res://assets/UI/menu_button_golden_hover.tres")
var style_gold_pressed = preload("res://assets/UI/menu_button_golden_pressed.tres")

# --- BACKEND REFERENZEN ---
var _guest_mgr: GuestManager

# --- STATE (Auswahl) ---
var _sel_party: GuestParty = null
var _sel_room: Node2D = null
var _sel_checkout_party: GuestParty = null

# --- MATCHING STATE ---
var _match_type: String = ""
var _asked: bool = false
var _ask_accepted: bool = false

# =============================================================================
# SETUP
# =============================================================================

# =============================================================================
func configure(guest_mgr: GuestManager) -> void:
	_guest_mgr = guest_mgr

	if not _guest_mgr.parties_changed.is_connected(refresh):
		_guest_mgr.parties_changed.connect(refresh)


# =============================================================================
func _ready() -> void:
	_btn_checkin.pressed.connect(_on_checkin_pressed)
	_btn_checkout.pressed.connect(_on_checkout_pressed)

	_list_title_waiting.text = GameState.T("reception.list.title.waiting")
	_list_title_rooms.text = GameState.T("reception.list.title.rooms")
	_list_title_active.text = GameState.T("reception.list.title.active")
	_list_title_checkout.text = GameState.T("reception.list.title.checkout")


# =============================================================================
# UI AUFBAU
# =============================================================================


# =============================================================================
func refresh() -> void:
	_clear_selection()
	_clear_all_lists()

	if not is_instance_valid(_guest_mgr): return

		# Spalte 1: Wartende Gäste spawnen
	var waiting_guests = _guest_mgr.get_waiting()

	if waiting_guests.is_empty():
		_add_empty_state_label(_list_waiting, GameState.T("reception.list.waiting.empty"))

	else:
		for party in waiting_guests:
			var card = GUEST_CARD_SCENE.instantiate()
			_list_waiting.add_child(card)

			var is_new = not party.has_been_seen
			card.populate(party, card.Mode.WAITING, is_new)
			card.sig_clicked.connect(_on_waiting_guest_clicked)

			# ---> NEU: Das Reject-Signal für wartende Gäste anbinden
			card.sig_reject_requested.connect(_on_guest_reject_requested)

	# Spalte 2: Freie Zimmer spawnen
	var free_rooms = _guest_mgr.get_free_rooms()

	if free_rooms.is_empty():
		_add_empty_state_label(_list_rooms, GameState.T("reception.list.rooms.empty"))

	else:
		for room in free_rooms:
			var card = ROOM_CARD_SCENE.instantiate()
			_list_rooms.add_child(card)
			card.populate(room)
			card.sig_clicked.connect(_on_room_clicked)

	# Spalte 3: Aktive Gäste
	var active_guests = _guest_mgr.get_active()

	if active_guests.is_empty():
		_add_empty_state_label(_list_active, GameState.T("reception.list.active.empty"))

	else:
		for party in active_guests:
			var card = GUEST_CARD_SCENE.instantiate()

			_list_active.add_child(card)
			card.populate(party, card.Mode.ACTIVE)

	# Spalte 4: Checkout
	var checkout_guests = _guest_mgr.get_checkout()

	if checkout_guests.is_empty():
		_add_empty_state_label(_list_checkout, GameState.T("reception.list.checkout.empty"))

	else:
		for party in checkout_guests:
			var card = GUEST_CARD_SCENE.instantiate()
			_list_checkout.add_child(card)
			card.populate(party, card.Mode.CHECKOUT)
			card.sig_clicked.connect(_on_checkout_guest_clicked)


# =============================================================================
func _add_empty_state_label(list: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.7))
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.set("custom_minimum_size", Vector2(0, 40))
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	list.add_child(lbl)


# =============================================================================
func _clear_all_lists() -> void:
	for list in [_list_waiting, _list_rooms, _list_active, _list_checkout]:
		for child in list.get_children():
			child.queue_free()


# =============================================================================
func _clear_selection() -> void:
	_sel_party = null
	_sel_room = null
	_sel_checkout_party = null
	_match_type = ""
	_asked = false
	_ask_accepted = false
	_update_checkin_button()

	_btn_checkout.disabled = true
	_btn_checkout.text = "Check-out bestätigen"


# =============================================================================
# KLICKS & LOGIK
# =============================================================================


# =============================================================================
func _on_waiting_guest_clicked(party: GuestParty) -> void:
	if _sel_party == party:
		_sel_party = null

	else:
		_sel_party = party
		_sel_party.has_been_seen = true
		_asked = false
		_ask_accepted = false

	_highlight_cards(_list_waiting, _sel_party)
	_highlight_cards(_list_rooms, _sel_room)
	_evaluate_match()


# =============================================================================
func _on_guest_reject_requested(party: GuestParty) -> void:
	# Falls dieser Gast gerade ausgewählt war, heben wir die Auswahl auf
	if _sel_party == party:
		_clear_selection()

	# Gast über den Manager ablehnen
	_guest_mgr.reject_party(party)

	# ---> NEU: Dynamischen Ruf-Verlust abfragen
	var rep_loss = GameState.calc_reject_rep_penalty(party)
	GameState.add_rep(-rep_loss)
	Toast.show(GameState.T("toast.guest.declined", str(rep_loss)))

	# UI neu laden
	refresh()


# =============================================================================
func _on_room_clicked(room: Node2D) -> void:
	if _sel_room == room:
		_sel_room = null
	else:
		_sel_room = room
		_asked = false
		_ask_accepted = false

	_highlight_cards(_list_rooms, _sel_room)
	_evaluate_match()


# =============================================================================
func _on_checkout_guest_clicked(party: GuestParty) -> void:
	_sel_checkout_party = party
	_highlight_cards(_list_checkout, _sel_checkout_party)
	_btn_checkout.disabled = (_sel_checkout_party == null)


# =============================================================================
# CHECK-IN / CHECK-OUT FLOW
# =============================================================================


# =============================================================================
func _evaluate_match() -> void:
	if _sel_party != null and _sel_room == null:
		# --- STATUS 1: NUR GAST GEWÄHLT ---
		# Zimmer bewerten und einsortieren
		var perfect_rooms := []
		var ask_rooms := []
		var disabled_rooms := []

		for card in _list_rooms.get_children():
			if not card.has_method("populate"): continue
			var mt = _guest_mgr.get_match_type(_sel_party, card.current_room)
			if mt == "disabled":
				card.modulate = Color(0.5, 0.5, 0.5, 0.5)
				card.mouse_filter = Control.MOUSE_FILTER_IGNORE
				disabled_rooms.append(card)
			elif mt == "perfect":
				card.modulate = Color.WHITE
				card.mouse_filter = Control.MOUSE_FILTER_STOP
				perfect_rooms.append(card)
			else:
				card.modulate = Color.WHITE
				card.mouse_filter = Control.MOUSE_FILTER_STOP
				ask_rooms.append(card)

		var sort_by_room = func(a, b): return a.current_room.room_number < b.current_room.room_number
		perfect_rooms.sort_custom(sort_by_room)
		ask_rooms.sort_custom(sort_by_room)
		disabled_rooms.sort_custom(sort_by_room)

		var new_index = 0
		for card in perfect_rooms: _list_rooms.move_child(card, new_index); new_index += 1
		for card in ask_rooms: _list_rooms.move_child(card, new_index); new_index += 1
		for card in disabled_rooms: _list_rooms.move_child(card, new_index); new_index += 1

		# Gäste-Liste resetten (falls vorher ein Zimmer den Filter aktiviert hatte)
		for card in _list_waiting.get_children():
			if card.has_method("populate"):
				card.modulate = Color.WHITE
				card.mouse_filter = Control.MOUSE_FILTER_STOP

	elif _sel_room != null and _sel_party == null:
		# --- STATUS 2: NUR ZIMMER GEWÄHLT ---
		# Gäste filtern (NICHT sortieren!)
		for card in _list_waiting.get_children():
			if not card.has_method("populate"): continue
			var mt = _guest_mgr.get_match_type(card.current_party, _sel_room)
			if mt == "disabled":
				card.modulate = Color(0.5, 0.5, 0.5, 0.5)
				card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			else:
				card.modulate = Color.WHITE
				card.mouse_filter = Control.MOUSE_FILTER_STOP

		# Zimmer-Liste resetten (alle wieder klickbar machen)
		for card in _list_rooms.get_children():
			if card.has_method("populate"):
				card.modulate = Color.WHITE
				card.mouse_filter = Control.MOUSE_FILTER_STOP

	elif _sel_party == null and _sel_room == null:
		# --- STATUS 3: NICHTS GEWÄHLT ---
		# 1. Zimmer resetten UND wieder in die Standard-Reihenfolge bringen
		var all_rooms := []
		for card in _list_rooms.get_children():
			if card.has_method("populate"):
				card.modulate = Color.WHITE
				card.mouse_filter = Control.MOUSE_FILTER_STOP
				all_rooms.append(card)

		# Standard-Sortierung (nur nach Zimmernummer)
		all_rooms.sort_custom(func(a, b): return a.current_room.room_number < b.current_room.room_number)

		var r_index = 0
		for card in all_rooms:
			_list_rooms.move_child(card, r_index)
			r_index += 1

		# 2. Gäste resetten
		for card in _list_waiting.get_children():
			if card.has_method("populate"):
				card.modulate = Color.WHITE
				card.mouse_filter = Control.MOUSE_FILTER_STOP

	# --- STATUS 4: BEIDES GEWÄHLT ---
	# Wir tun absichtlich gar nichts mit den Listen. Sie bleiben so, wie sie sind.


	# --- MATCH BERECHNEN & BUTTON UPDATEN ---
	if _sel_party != null and _sel_room != null:
		_match_type = _guest_mgr.get_match_type(_sel_party, _sel_room)
	else:
		_match_type = ""

	_update_checkin_button()


# =============================================================================
func _update_checkin_button() -> void:
	# Fall 1: Nichts ausgewählt
	if _match_type == "":
		_btn_checkin.disabled = true
		_btn_checkin.text = GameState.T("checkin.btn.confirm")
		# Setzt den Button auf den Standard-Rezeptions-Look zurück
		_apply_btn_styles(style_rec_normal, style_rec_normal, style_rec_normal, style_rec_disabled)
		return

	_btn_checkin.disabled = false

	# Fall 2: Visuelles Feedback auf Basis des Match-Typs
	match _match_type:
		"perfect":
			_btn_checkin.text = GameState.T("checkin.btn.confirm")
			_apply_btn_styles(style_green_normal, style_green_hover, style_green_pressed, style_rec_disabled)

		"ask_price", "ask_requirements":
			if _asked and _ask_accepted:
				_btn_checkin.text = GameState.T("checkin.btn.confirm")
				_apply_btn_styles(style_green_normal, style_green_hover, style_green_pressed, style_rec_disabled)
			else:
				_btn_checkin.text = GameState.T("checkin.btn.roll")
				_apply_btn_styles(style_gold_normal, style_gold_hover, style_gold_pressed, style_rec_disabled)

		"disabled", _:
			_btn_checkin.disabled = true
			_btn_checkin.text = GameState.T("checkin.btn.other_room")
			_apply_btn_styles(style_rec_normal, style_rec_normal, style_rec_normal, style_rec_disabled)


# =============================================================================
func _on_checkin_pressed() -> void:
	if _sel_party == null or _sel_room == null: return

	# FALL 1: Perfektes Match ODER bereits erfolgreich verhandelt
	if _match_type == "perfect" or (_asked and _ask_accepted):

		if _match_type != "perfect":
			_sel_party.pays_surcharge = true

		# ---> NEU: Dynamische EXP berechnen und vergeben
		var exp_gain = GameState.calc_checkin_exp(_sel_party)
		GameState.add_exp(exp_gain)

		_guest_mgr.do_checkin(_sel_party, _sel_room)
		Toast.show(GameState.T("toast.reception.checkin.success"))

		_clear_selection()
		refresh()

	# FALL 2 & 3: Verhandlung starten
	else:
		_asked = true
		var roll_result = _guest_mgr.roll_ask(_sel_party, _sel_room)

		if roll_result["accepted"]:
			_ask_accepted = true
			Toast.show(GameState.T("toast.surcharge.accepted", roll_result["roll_val"], roll_result["target_val"]))
			_update_checkin_button()

		else:
			_guest_mgr.reject_party(_sel_party)
			Toast.show(GameState.T("toast.surcharge.rejected", roll_result["roll_val"], roll_result["target_val"]))

			_clear_selection()
			refresh()


# =============================================================================
func _on_checkout_pressed() -> void:
	if _sel_checkout_party == null: return

	var payout = _guest_mgr.do_checkout(_sel_checkout_party)

	if has_node("/root/Toast"):
		Toast.show("Checkout: %.0f € erhalten" % payout)

	refresh()


# =============================================================================
# HILFSFUNKTIONEN
# =============================================================================


# =============================================================================
func _highlight_cards(list: VBoxContainer, selected_target) -> void:
	for card in list.get_children():
		var is_selected = false
		if card.has_method("populate"):
			if "current_party" in card:
				is_selected = (card.current_party == selected_target)
			elif "current_room" in card:
				is_selected = (card.current_room == selected_target)

		if card.has_method("set_highlight"):
			card.set_highlight(is_selected)


# =============================================================================
func _apply_btn_styles(normal: StyleBox, hover: StyleBox, pressed: StyleBox, disabled: StyleBox) -> void:
	# Entfernt zuerst den unschönen modulate-Filter, falls noch einer aktiv ist
	_btn_checkin.modulate = Color.WHITE

	_btn_checkin.add_theme_stylebox_override("normal", normal)
	_btn_checkin.add_theme_stylebox_override("hover", hover)
	_btn_checkin.add_theme_stylebox_override("pressed", pressed)
	_btn_checkin.add_theme_stylebox_override("disabled", disabled)

	# Optional: Fokus-Style gleichsetzen, damit nach dem Klicken kein Rand bleibt
	_btn_checkin.add_theme_stylebox_override("focus", normal)
