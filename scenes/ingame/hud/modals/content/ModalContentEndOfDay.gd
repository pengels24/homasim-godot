extends Control
class_name ModalContentEndOfDay

signal sig_continue_requested

# --- FINANZEN LABELS ---
@onready var _lbl_room_income: Label = %LblRoomIncome
@onready var _lbl_restaurant: Label = %LblRestaurant
@onready var _lbl_services: Label = %LblServices

@onready var _lbl_total_income: Label = %LblTotalIncome
@onready var _lbl_total_expenses: Label = %LblTotalExpenses
@onready var _lbl_profit: Label = %LblProfit

# --- GÄSTE LABELS (Erfolg) ---
@onready var _lbl_checkins: Label = %LblCheckins
@onready var _lbl_checkouts: Label = %LblCheckouts
@onready var _lbl_in_house: Label = %LblInHouse
@onready var _lbl_leaving_tomorrow: Label = %LblLeavingTomorrow

# --- GÄSTE LABELS (Verluste - optional im UI, aber hier verfügbar) ---
@onready var _lbl_rage_quits: Label = %LblRageQuits
@onready var _lbl_timeouts: Label = %LblTimeouts
@onready var _lbl_rejected: Label = %LblRejected
@onready var _lbl_declined: Label = %LblDeclined

@onready var _btn_next_day: Button = %BtnNextDay

var _guest_mgr: GuestManager


# =============================================================================
func _ready() -> void:
	var today: int = GameState.selected_hotel.get("day", 1)

	_fill_finance_data(today)
	_fill_guest_data()

	if is_instance_valid(_btn_next_day):
		_btn_next_day.text = "WEITER ZU TAG %d" % (today + 1)
		_btn_next_day.pressed.connect(_on_next_day_pressed)

# =============================================================================
func _fill_finance_data(day: int) -> void:
	var room_inc := 0
	var rest_inc := 0
	var serv_inc := 0
	var other_inc := 0
	var expenses := 0

	var transactions: Array = GameState.selected_hotel.get("transactions", [])

	for tx: Dictionary in transactions:
		if tx.get("day", -1) == day:
			var amount: int = tx.get("amount", 0)
			var category: String = tx.get("category", "")
			var time: int = tx.get("time", 0)

			if amount > 0:
				match category:
					"room": room_inc += amount
					"restaurant": rest_inc += amount
					"service": serv_inc += amount
					_: other_inc += amount
			else:
				expenses += amount # Ausgaben sind bereits negativ

	var total_inc := room_inc + rest_inc + serv_inc + other_inc
	var profit := total_inc + expenses # expenses ist negativ, also + (-) = -

	# UI befüllen
	if is_instance_valid(_lbl_room_income): _lbl_room_income.text = "Übernachtungen: %d €" % room_inc
	if is_instance_valid(_lbl_restaurant): _lbl_restaurant.text = "Restaurant: %d €" % rest_inc
	if is_instance_valid(_lbl_services): _lbl_services.text = "Services: %d €" % serv_inc

	if is_instance_valid(_lbl_total_income): _lbl_total_income.text = "Einnahmen gesamt: %d €" % total_inc
	if is_instance_valid(_lbl_total_expenses): _lbl_total_expenses.text = "Ausgaben gesamt: %d €" % expenses
	if is_instance_valid(_lbl_profit): _lbl_profit.text = "Tagesgewinn: %d €" % profit

# =============================================================================
func _fill_guest_data() -> void:
	# Erfolge: Format "Partien / Köpfe"
	if is_instance_valid(_lbl_checkins):
		_lbl_checkins.text = "Check-ins: %d / %d" % [_guest_mgr.daily_checkin_parties, _guest_mgr.daily_checkin_heads]

	if is_instance_valid(_lbl_checkouts):
		_lbl_checkouts.text = "Check-outs: %d / %d" % [_guest_mgr.daily_checkout_parties, _guest_mgr.daily_checkout_heads]

	# Verluste / Abbrüche
	if is_instance_valid(_lbl_rage_quits):
		_lbl_rage_quits.text = "Wütend abgereist (Wartezeit): %d / %d" % [_guest_mgr.daily_rage_parties, _guest_mgr.daily_rage_heads]

	if is_instance_valid(_lbl_timeouts):
		_lbl_timeouts.text = "Vor Check-in gegangen: %d / %d" % [_guest_mgr.daily_timeout_parties, _guest_mgr.daily_timeout_heads]

	if is_instance_valid(_lbl_rejected):
		_lbl_rejected.text = "An der Tür abgewiesen: %d / %d" % [_guest_mgr.daily_reject_parties, _guest_mgr.daily_reject_heads]

	if is_instance_valid(_lbl_declined):
		_lbl_declined.text = "Angebot abgelehnt: %d / %d" % [_guest_mgr.daily_declined_parties, _guest_mgr.daily_declined_heads]

	var total_parties := _guest_mgr._active.size()
	var total_heads := 0
	for p: GuestParty in _guest_mgr._active:
		total_heads += p.members.size()

	var leaving_parties := 0
	var leaving_heads := 0
	for p: GuestParty in _guest_mgr._active:
		if p.stay_days <= 1:
			leaving_parties += 1
			leaving_heads += p.members.size()

	if is_instance_valid(_lbl_in_house):
		_lbl_in_house.text = "Aktuell im Hotel: %d / %d" % [total_parties, total_heads]

	if is_instance_valid(_lbl_leaving_tomorrow):
		_lbl_leaving_tomorrow.text = "Abreise morgen: %d / %d" % [leaving_parties, leaving_heads]

# =============================================================================
func _on_next_day_pressed() -> void:
	sig_continue_requested.emit()