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
		"icon": "res://assets/icons/angelus2010/Rooms/ang-kitchen-small.aseprite",
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
	if TimeManager and TimeManager.is_paused(): return
	
	var speed = TimeManager.user_speed if TimeManager else 1.0
	var scaled_delta = delta * speed
	
	_process_cooking(scaled_delta)
	
	_check_timer -= scaled_delta
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
		if not StaffManager.is_staff_available(s):
			continue
			
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
		if not StaffManager.is_staff_available(s):
			continue
			
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

func get_work_position(_staff_id: String) -> Vector2:
	# 1. Unique Name
	var marker = get_node_or_null("%ChefWorkArea")
	if marker:
		return marker.global_position + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
		
	# 2. Suche ohne %
	var markers = find_children("ChefWorkArea", "Marker2D")
	if markers.is_empty():
		markers = find_children("ChefWorkArea", "Node2D")
		
	for m in markers:
		var is_marker_active = true
		var parent = m.get_parent()
		while parent != self and is_instance_valid(parent):
			if "visible" in parent and not parent.visible:
				is_marker_active = false
				break
			parent = parent.get_parent()
		if is_marker_active:
			return m.global_position + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
	
	# Fallback, falls der Marker falsch geschrieben wurde oder nicht existiert:
	var interior = get_node_or_null("Interior")
	if interior:
		return interior.global_position + Vector2(16, 16) # Mitte der Küche
	
	return global_position + Vector2(16, 16)

func get_service_position() -> Vector2:
	var marker = get_node_or_null("%PickupPoint")
	if marker:
		return marker.global_position
		
	var markers = find_children("PickupPoint", "Marker2D")
	if not markers.is_empty():
		return markers[0].global_position
		
	# Fallback
	var interior = get_node_or_null("Interior")
	if interior:
		return interior.global_position + Vector2(16, 16)
	
	return global_position + Vector2(16, 16)


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
			
		if QuestManager.has_method("on_food_cooked"):
			QuestManager.on_food_cooked(1)

# =============================================================================
# Live-Details für Gastro-Monitor
# =============================================================================
func get_live_details() -> Array[Dictionary]:
	var details: Array[Dictionary] = []
	var assigned = []
	
	if Engine.is_editor_hint() == false:
		if _room_id == "":
			_room_id = GuestManager._room_key(self)
			
		assigned = StaffManager.get_staff_for_room(_room_id)
		
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
			guest_name = guest_node.get("_guest_member").name if guest_node.get("_guest_member") else "Gast"
			
		for r in GameState.recipes:
			if r.get("id") == order_data.get("recipe_id"):
				r_name = GameState.T(r.get("name_key", ""))
				break
				
		var right_text = GameState.T("room.kitchen.waiting")
		if status == "cooking" and _active_cook_timers.has(order_id):
			right_text = GameState.T("room.kitchen.time_left", int(_active_cook_timers[order_id]))
			var has_helper = false
			if typeof(assigned) == TYPE_ARRAY:
				for s in assigned:
					if typeof(s) == TYPE_DICTIONARY and s.get("role") == "kitchen_helper":
						has_helper = true
						break
			if has_helper:
				right_text += " ⚡"
		elif status == "ready":
			right_text = GameState.T("room.kitchen.ready")
			
		var rest_id = order_data.get("restaurant_id", "")
		var rest_node = gm._get_room_node(rest_id) if gm else null
		var custom_col = Color.WHITE
		if is_instance_valid(rest_node):
			if "custom_color" in rest_node and typeof(rest_node.custom_color) == TYPE_COLOR and rest_node.custom_color != Color.WHITE:
				custom_col = rest_node.custom_color
				
		details.append({
			"left": guest_name + " (" + r_name + ")",
			"right": right_text,
			"color": custom_col
		})
		
	if details.is_empty():
		details.append({
			"left": GameState.T("room.kitchen.status"),
			"right": GameState.T("room.kitchen.empty")
		})
		
	return details
