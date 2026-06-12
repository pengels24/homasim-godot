extends Control
class_name ModalContentEndOfDay

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
  if is_instance_valid(_lbl_room_income): _lbl_room_income.text = "%d €" % room_inc
  if is_instance_valid(_lbl_restaurant): _lbl_restaurant.text = "%d €" % rest_inc
  if is_instance_valid(_lbl_services): _lbl_services.text = "%d €" % serv_inc

  if is_instance_valid(_lbl_total_income): _lbl_total_income.text = "%d €" % total_inc
  if is_instance_valid(_lbl_total_expenses): _lbl_total_expenses.text = "%d €" % expenses
  if is_instance_valid(_lbl_profit): _lbl_profit.text = "%d €" % profit

# =============================================================================
func _fill_guest_data() -> void:
  # Erfolge: Format "Partien / Köpfe"
  if is_instance_valid(_lbl_checkins):
    _lbl_checkins.text = "%d / %d" % [_guest_mgr.daily_checkin_parties, _guest_mgr.daily_checkin_heads]

  if is_instance_valid(_lbl_checkouts):
    _lbl_checkouts.text = "%d / %d" % [_guest_mgr.daily_checkout_parties, _guest_mgr.daily_checkout_heads]

  # Verluste / Abbrüche
  if is_instance_valid(_lbl_rage_quits):
    _lbl_rage_quits.text = "%d / %d" % [_guest_mgr.daily_rage_parties, _guest_mgr.daily_rage_heads]

  if is_instance_valid(_lbl_timeouts):
    _lbl_timeouts.text = "%d / %d" % [_guest_mgr.daily_timeout_parties, _guest_mgr.daily_timeout_heads]

  if is_instance_valid(_lbl_rejected):
    _lbl_rejected.text = "%d / %d" % [_guest_mgr.daily_reject_parties, _guest_mgr.daily_reject_heads]

  if is_instance_valid(_lbl_declined):
    _lbl_declined.text = "%d / %d" % [_guest_mgr.daily_declined_parties, _guest_mgr.daily_declined_heads]

  # Live-Werte (Im Haus / Abreisend morgen)
  var total_parties := 0
  var total_heads := 0
  var leaving_parties := 0
  var leaving_heads := 0

  for party: GuestParty in _guest_mgr.get_active():
    total_parties += 1
    total_heads += party.members.size()

    if party.stay_days <= 1:
      leaving_parties += 1
      leaving_heads += party.members.size()

  if is_instance_valid(_lbl_in_house):
    _lbl_in_house.text = "%d / %d" % [total_parties, total_heads]

  if is_instance_valid(_lbl_leaving_tomorrow):
    _lbl_leaving_tomorrow.text = "%d / %d" % [leaving_parties, leaving_heads]

# =============================================================================
func _on_next_day_pressed() -> void:
  TimeManager.start_next_day()

  # TODO: Modal über deinen ModalManager schließen