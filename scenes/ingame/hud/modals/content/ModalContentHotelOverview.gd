extends MarginContainer

@onready var val_stars: Label = %ValStars
@onready var val_rep: Label = %ValRep
@onready var val_money: Label = %ValMoney
@onready var val_balance: Label = %ValBalance
@onready var val_occupancy: Label = %ValOccupancy
@onready var val_cleanliness: Label = %ValCleanliness
@onready var val_satisfaction: Label = %ValSatisfaction

var _guest_mgr: GuestManager = null

func _ready() -> void:
	pass

func setup(guest_mgr: GuestManager) -> void:
	_guest_mgr = guest_mgr

func _process(_delta: float) -> void:
	if not visible: return
	_update_stats()

func _update_stats() -> void:
	# Sterne & Ruf
	var stars = GameState.selected_hotel.get("stars", 0)
	var rep = GameState.selected_hotel.get("rep", 0)
	var rep_max = GameState.selected_hotel.get("rep_max", 100)
	val_stars.text = "%d / 5 Sterne" % stars
	val_rep.text = "%d / %d Rufpunkte" % [rep, rep_max]

	# Finanzen
	var money = GameState.selected_hotel.get("money", 0)
	val_money.text = "%d \u20ac" % money

	# Tagesbilanz aus Transaktionen berechnen
	var today = GameState.selected_hotel.get("day", 1)
	var txs = GameState.selected_hotel.get("transactions", [])
	var income = 0
	var expense = 0
	for tx in txs:
		if tx.get("day", 0) == today:
			var amt: int = tx.get("amount", 0)
			if amt > 0:
				income += amt
			else:
				expense += amt
	var balance = income + expense
	var prefix = "+" if balance >= 0 else ""
	val_balance.text = "Heute: %s%d \u20ac" % [prefix, balance]

	# Auslastung via GuestManager: aktive Parties = belegte Zimmer
	if is_instance_valid(_guest_mgr):
		var active = _guest_mgr.get_active()
		var occupied_ids: Dictionary = {}
		for p in active:
			if p.room_id != "":
				occupied_ids[p.room_id] = true

		# Gesamtzahl Gastzimmer: belegte + freie (get_free_rooms filtert korrekt)
		var free_rooms = _guest_mgr.get_free_rooms().size()
		var occupied_rooms = occupied_ids.size()
		var total_rooms = occupied_rooms + free_rooms

		# Gesamtbetten: nur Raeume mit max_beds > 0 (= Gastzimmer)
		var total_beds = 0
		if is_instance_valid(_guest_mgr._map_grid):
			for room in _guest_mgr._map_grid.get_placed_rooms():
				if room.has_method("get_definition"):
					var beds: int = room.get_definition().get("max_beds", 0)
					if beds > 0:
						total_beds += beds

		if total_rooms > 0:
			var pct = int(round((float(occupied_rooms) / float(total_rooms)) * 100.0))
			val_occupancy.text = "Auslastung: %d%% (%d/%d Zimmer \u00b7 %d Betten)" % [pct, occupied_rooms, total_rooms, total_beds]
		else:
			val_occupancy.text = "Auslastung: 0% (0 Zimmer)"

	# Sauberkeit via GuestManager API
	if is_instance_valid(_guest_mgr):
		var avg_clean = _guest_mgr.get_average_cleanliness()
		val_cleanliness.text = "\u00d8 Sauberkeit: %d%%" % round(avg_clean)
	else:
		val_cleanliness.text = "\u00d8 Sauberkeit: 100%"

	# Gaestezufriedenheit via GuestManager API
	if is_instance_valid(_guest_mgr):
		var active = _guest_mgr.get_active()
		var waiting = _guest_mgr.get_waiting()
		var total_parties = active.size() + waiting.size()
		var avg_sat = _guest_mgr.get_average_satisfaction()
		if total_parties > 0:
			val_satisfaction.text = "\u00d8 Zufriedenheit: %d%% (%d Gruppen)" % [round(avg_sat), total_parties]
		else:
			val_satisfaction.text = "\u00d8 Zufriedenheit: Keine G\u00e4ste"
	else:
		val_satisfaction.text = "\u00d8 Zufriedenheit: \u2013"
