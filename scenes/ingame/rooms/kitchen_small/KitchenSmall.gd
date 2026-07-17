extends "res://scenes/ingame/rooms/Room.gd"

# =============================================================================
static func get_definition() -> Dictionary:
	return {
		"id": "kitchen_small",
		"build_cost": 3000,
		"exp_reward": 300,
		"prefix": "K",
		"label": "KÜ",
		"name": "roomdef.name.long.kitchen_small",
		"category": "gastro",
		"icon": "res://assets/icons/angelus2010/Rooms/ang-kitchen.aseprite",
		"nightly_price": 0,
		"locked": false,
		"in_build_menu": true,
		"req_level": 3,
		"req_tech": "G1.2",
		"max_beds": 0,
		"is_poi": true, # Muss true sein für Personal-Zuweisung
		"is_guest_poi": false, # Gäste dürfen nicht in die Küche
		"visit_income": 0,
		"visit_exp": 10,
		"supply_cost_per_visit": 5,
		"adults_only": false,
		"required_role": "chef",
		"allowed_roles": ["chef", "kitchen_helper"],
		"max_role_limits": {"chef": 2, "kitchen_helper": 1},
		"min_staff": 1,
		"max_staff": 3,
		"open_from": 420, # 07:00
		"open_to": 1320,  # 22:00
		"valid_door_slots": ["R1"],
		"cleanliness_level": 100,
		"maintenance_level": 100,
		"is_service_requested": false
	}

# =============================================================================
# VARIABLES
# =============================================================================
var _room_id: String = ""
var _active_cook_timers: Dictionary = {} # order_id -> time_left
var _check_timer: float = 0.0

func _ready() -> void:
	if not is_instance_valid(self): return
	if not is_inside_tree(): return
	super._ready()

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	_process_cooking(delta)
	
	_check_timer -= delta
	if _check_timer <= 0:
		_check_timer = 1.0 # Einmal pro Sekunde prüfen
		_check_for_new_orders()

func _check_for_new_orders() -> void:
	if not GastroManager: return
	
	if _room_id == "":
		_room_id = GuestManager._room_key(self)
	
	var assigned = StaffManager.get_staff_for_room(_room_id)
	var has_chef = false
	var chef_speed = 1.0
	
	for s in assigned:
		if s.get("role") == "chef":
			has_chef = true
			chef_speed += (s.get("skills", {}).get("speed", 5) * 0.05)
		if s.get("role") == "kitchen_helper":
			chef_speed += 0.5 # Küchenhilfe gibt 50% Speed-Boost
			
	# Küche arbeitet nur, wenn mindestens ein Koch da ist
	if not has_chef: return
	
	# Wie viele Gerichte können wir gleichzeitig kochen? (1 pro Koch)
	var max_concurrent = 1
	for s in assigned:
		if s.get("role") == "chef" and max_concurrent == 1:
			pass # Der erste Koch ist schon in max_concurrent=1 enthalten
		elif s.get("role") == "chef":
			max_concurrent += 1

	if _active_cook_timers.size() >= max_concurrent:
		return # Wir kochen schon auf Hochtouren
		
	var pending = GastroManager.get_pending_orders()
	for order_id in pending:
		if _active_cook_timers.size() >= max_concurrent:
			break
			
		var order_data = GastroManager.active_orders.get(order_id, {})
		var r_id = order_data.get("recipe_id", "")
		var prep_time = 10.0
		
		# Rezept-Dauer aus GameState holen
		for r in GameState.recipes:
			if r.get("id") == r_id:
				prep_time = float(r.get("prep_time", 10.0))
				break
				
		# Bestellung claimen und Timer starten
		GastroManager.claim_order(order_id, _room_id)
		_active_cook_timers[order_id] = prep_time / chef_speed

func _process_cooking(delta: float) -> void:
	var finished_orders = []
	for order_id in _active_cook_timers.keys():
		_active_cook_timers[order_id] -= delta
		if _active_cook_timers[order_id] <= 0:
			finished_orders.append(order_id)
			
	for order_id in finished_orders:
		_active_cook_timers.erase(order_id)
		
		if EffectManager: EffectManager.spawn_exp_text(5, global_position + Vector2(0, -32))
		GameState.add_exp(5)
			
		if GastroManager:
			GastroManager.finish_order(order_id)

# =============================================================================
# Live-Details für Gastro-Monitor
# =============================================================================
func get_live_details() -> Array[Dictionary]:
	var details: Array[Dictionary] = []
	
	if Engine.is_editor_hint() == false:
		if _room_id == "":
			_room_id = GuestManager._room_key(self)
			
		var assigned = StaffManager.get_staff_for_room(_room_id)
		
	# Alle an diese Küche zugewiesenen Bestellungen anzeigen (oder pending)
	var all_orders = GastroManager.active_orders.keys()
	for order_id in all_orders:
		var order_data = GastroManager.active_orders.get(order_id)
		if not order_data:
			continue
			
		var status = order_data.get("status", "")
		var k_id = order_data.get("kitchen_id", "")
		
		# Entweder gehört sie mir, oder sie ist noch komplett offen
		if k_id != _room_id and status != "pending":
			continue
			
		if status == "served":
			continue
			
		var r_name = "?"
		var guest_name = GameState.T("room.kitchen.guest")
		
		var gm = get_tree().get_first_node_in_group("guest_manager")
		var guest_node = gm.get_guest(order_data.get("guest_id", "")) if gm else null
		if is_instance_valid(guest_node) or guest_node != null:
			guest_name = guest_node.name
			
		for r in GameState.recipes:
			if r.get("id") == order_data.get("recipe_id"):
				r_name = GameState.T(r.get("name_key", ""))
				break
				
		var right_text = GameState.T("room.kitchen.waiting")
		if status == "cooking" and _active_cook_timers.has(order_id):
			right_text = GameState.T("room.kitchen.time_left", int(_active_cook_timers[order_id]))
		elif status == "ready":
			right_text = GameState.T("room.kitchen.ready")
			
		details.append({
			"left": guest_name + " (" + r_name + ")",
			"right": right_text
		})
		
	if details.is_empty():
		details.append({
			"left": GameState.T("room.kitchen.status"),
			"right": GameState.T("room.kitchen.empty")
		})
		
	return details
