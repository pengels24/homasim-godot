extends MarginContainer

@onready var val_stars: Label = %ValStars
@onready var val_rep: Label = %ValRep
@onready var val_money: Label = %ValMoney
@onready var val_balance: Label = %ValBalance
@onready var val_occupancy: Label = %ValOccupancy
@onready var val_cleanliness: Label = %ValCleanliness
@onready var val_satisfaction: Label = %ValSatisfaction

func _ready() -> void:
	pass

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
	val_money.text = "%d €" % money
	
	var balance = 0
	if FinanceManager:
		var record = FinanceManager.get_daily_record(TimeManager.get_day())
		balance = record["income"] - record["expense"]
		var prefix = "+" if balance >= 0 else ""
		val_balance.text = "Heute: %s%d €" % [prefix, balance]
	
	# Auslastung & Sauberkeit
	var total_beds = 0
	var used_beds = 0
	var total_cleanliness = 0.0
	var clean_rooms = 0
	
	if GameState.room_registry:
		for room_id in GameState.room_registry:
			var room_data = GameState.room_registry[room_id].get("def", {})
			var cat_id = room_data.get("category_id", "")
			if cat_id.begins_with("guest_"):
				var beds = room_data.get("bed_count", 0)
				total_beds += beds
				if room_data.get("is_occupied", false):
					used_beds += beds
				
				total_cleanliness += room_data.get("cleanliness", 100.0)
				clean_rooms += 1
				
	if total_beds > 0:
		val_occupancy.text = "Auslastung: %d%% (%d/%d Betten)" % [round((float(used_beds)/float(total_beds))*100.0), used_beds, total_beds]
	else:
		val_occupancy.text = "Auslastung: 0% (0 Betten)"
		
	if clean_rooms > 0:
		val_cleanliness.text = "Ø Sauberkeit: %d%%" % round(total_cleanliness / float(clean_rooms))
	else:
		val_cleanliness.text = "Ø Sauberkeit: 100%"
		
	# Gästezufriedenheit
	var total_sat = 0.0
	var parties = 0
	if get_tree().root.has_node("Ingame/Managers/GuestManager"):
		var guest_mgr = get_tree().root.get_node("Ingame/Managers/GuestManager")
		parties = guest_mgr.guest_parties.size()
		for party in guest_mgr.guest_parties:
			total_sat += party.satisfaction
			
	if parties > 0:
		val_satisfaction.text = "Ø Zufriedenheit: %d%% (%d Gruppen)" % [round(total_sat / float(parties)), parties]
	else:
		val_satisfaction.text = "Ø Zufriedenheit: Keine Gäste"
