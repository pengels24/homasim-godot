extends PanelContainer # (Oder MarginContainer, je nachdem was dein Root ist)

signal closed() # Sagt der Ingame.gd, dass wir zumachen wollen

# --- PRELOADS (Pfade ggf. anpassen!) ---
const GUEST_CARD_SCENE = preload("res://scenes/ingame/hud/modals/content/cards/GuestCard.tscn")
const ROOM_CARD_SCENE = preload("res://scenes/ingame/hud/modals/content/cards/RoomCardAvailable.tscn")

# --- UI REFERENZEN ---
@onready var _list_waiting: VBoxContainer = %ListWaiting
@onready var _list_rooms: VBoxContainer = %ListRooms
@onready var _list_active: VBoxContainer = %ListActive
@onready var _list_checkout: VBoxContainer = %ListCheckout

@onready var _btn_checkin: Button = %BtnCheckIn
@onready var _btn_checkout: Button = %BtnCheckout
# Optional: Falls du einen Info-Text neben/über dem Button hast für "Gast fragen"
# @onready var _action_info: Label = %ActionInfo

# --- BACKEND REFERENZEN ---
var _guest_mgr: GuestManager
var _clock: IngameClock

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
func configure(guest_mgr: GuestManager, clock: IngameClock) -> void:
	_guest_mgr = guest_mgr
	_clock = clock

	# Wenn sich im Backend was ändert (z.B. Geduld abgelaufen), updaten wir das UI
	if not _guest_mgr.parties_changed.is_connected(refresh):
		_guest_mgr.parties_changed.connect(refresh)

func _ready() -> void:
	_btn_checkin.pressed.connect(_on_checkin_pressed)
	_btn_checkout.pressed.connect(_on_checkout_pressed)

	# GLOBALER INPUT: Wir nutzen deinen InputHandler statt lokaler Abfragen!
	if InputHandler.has_signal("sig_hotkey_escape_pressed"):
		InputHandler.sig_hotkey_escape_pressed.connect(_on_escape_pressed)

# =============================================================================
# UI AUFBAU (Die Dirigenten-Arbeit)
# =============================================================================
func refresh() -> void:
	# 1. Alles leeren und Auswahl zurücksetzen
	_clear_selection()
	_clear_all_lists()

	if not is_instance_valid(_guest_mgr): return

	# 2. Spalte 1: Wartende Gäste spawnen
	for party in _guest_mgr.get_waiting():
		var card = GUEST_CARD_SCENE.instantiate()
		_list_waiting.add_child(card)
		card.populate(party, card.Mode.WAITING)
		card.clicked.connect(_on_waiting_guest_clicked)

	# 3. Spalte 2: Freie Zimmer spawnen
	for room in _guest_mgr.get_free_rooms():
		var card = ROOM_CARD_SCENE.instantiate()
		_list_rooms.add_child(card)
		card.populate(room)
		card.clicked.connect(_on_room_clicked)

	# 4. Spalte 3: Aktive Gäste
	for party in _guest_mgr.get_active():
		var card = GUEST_CARD_SCENE.instantiate()
		_list_active.add_child(card)
		card.populate(party, card.Mode.ACTIVE)
		# Keine Klick-Connection nötig im Active-Modus

	# 5. Spalte 4: Checkout
	for party in _guest_mgr.get_checkout():
		var card = GUEST_CARD_SCENE.instantiate()
		_list_checkout.add_child(card)
		card.populate(party, card.Mode.CHECKOUT)
		card.clicked.connect(_on_checkout_guest_clicked)

func _clear_all_lists() -> void:
	for list in [_list_waiting, _list_rooms, _list_active, _list_checkout]:
		for child in list.get_children():
			child.queue_free()

func _clear_selection() -> void:
	_sel_party = null
	_sel_room = null
	_sel_checkout_party = null
	_match_type = ""
	_asked = false
	_ask_accepted = false
	_update_checkin_button()
	_btn_checkout.disabled = true

# =============================================================================
# KLICKS & LOGIK
# =============================================================================

# -- Spalte 1: Gast gewählt --
func _on_waiting_guest_clicked(party: GuestParty) -> void:
	# Gleicher Gast nochmal = Abwählen
	if _sel_party == party:
		_sel_party = null
	else:
		_sel_party = party
		_asked = false
		_ask_accepted = false

	_highlight_cards(_list_waiting, _sel_party)
	_evaluate_match()

# -- Spalte 2: Zimmer gewählt --
func _on_room_clicked(room: Node2D) -> void:
	if _sel_room == room:
		_sel_room = null
	else:
		_sel_room = room
		_asked = false
		_ask_accepted = false

	_highlight_cards(_list_rooms, _sel_room)
	_evaluate_match()

# -- Spalte 4: Abreisender gewählt --
func _on_checkout_guest_clicked(party: GuestParty) -> void:
	_sel_checkout_party = party
	_highlight_cards(_list_checkout, _sel_checkout_party)
	_btn_checkout.disabled = (_sel_checkout_party == null)

# =============================================================================
# CHECK-IN / CHECK-OUT FLOW
# =============================================================================

func _evaluate_match() -> void:
	# Visuelles Highlight für Zimmer anpassen basierend auf gewähltem Gast
	# (Dein Konzept B: Ausgrauen von unpassenden Zimmern)
	if _sel_party != null:
		for card in _list_rooms.get_children():
			var room_node = card.current_room
			var mt = _guest_mgr.get_match_type(_sel_party, room_node)
			if mt == "disabled":
				card.modulate = Color(0.5, 0.5, 0.5, 0.5) # Ausgrauen
				card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			else:
				card.modulate = Color.WHITE
				card.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		# Reset, wenn kein Gast gewählt
		for card in _list_rooms.get_children():
			card.modulate = Color.WHITE
			card.mouse_filter = Control.MOUSE_FILTER_STOP

	# Wenn beides gewählt ist, prüfen wir den Match über den Backend-Manager
	if _sel_party != null and _sel_room != null:
		_match_type = _guest_mgr.get_match_type(_sel_party, _sel_room)
	else:
		_match_type = ""

	_update_checkin_button()

func _update_checkin_button() -> void:
	if _match_type == "":
		_btn_checkin.disabled = true
		_btn_checkin.text = "CHECK-IN BESTÄTIGEN"
		return

	_btn_checkin.disabled = false

	match _match_type:
		"perfect":
			_btn_checkin.text = "CHECK-IN BESTÄTIGEN"
		"ask_price":
			_btn_checkin.text = "Check-in" if (_asked and _ask_accepted) else "Gast fragen (Preis)"
		"ask_requirements":
			_btn_checkin.text = "Check-in" if (_asked and _ask_accepted) else "Gast fragen (Ausstattung)"
		"disabled":
			_btn_checkin.disabled = true
			_btn_checkin.text = "Passt nicht!"

func _on_checkin_pressed() -> void:
	if _sel_party == null or _sel_room == null: return

	if _match_type == "perfect" or (_asked and _ask_accepted):
		_guest_mgr.do_checkin(_sel_party, _sel_room)
		refresh() # UI komplett neu laden
	else:
		# Würfeln! (Fragen)
		_asked = true
		var accepted = _guest_mgr.roll_ask(_sel_party, _sel_room)
		if accepted:
			_ask_accepted = true
			# Optional: Hier einen kurzen EffectManager Toast für "Gast akzeptiert!" spawnen
			_update_checkin_button()
		else:
			# Gast lehnt ab und verlässt das Hotel
			_guest_mgr.reject_party(_sel_party)
			refresh()

func _on_checkout_pressed() -> void:
	if _sel_checkout_party == null: return

	var payout = _guest_mgr.do_checkout(_sel_checkout_party)
	Toast.show("Checkout: %.0f € erhalten" % payout)
	refresh()

# =============================================================================
# HILFSFUNKTIONEN
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

func _on_escape_pressed() -> void:
	# Wird nur gefeuert, wenn das Modal sichtbar ist
	if is_visible_in_tree():
		closed.emit()
