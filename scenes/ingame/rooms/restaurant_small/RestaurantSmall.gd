extends "res://scenes/ingame/rooms/Room.gd"

# =============================================================================
static func get_definition() -> Dictionary:
	return {
		"id": "restaurant_small",
		"build_cost": 5000,
		"exp_reward": 500,
		"prefix": "R",
		"label": "RE",
		"name": "roomdef.name.long.restaurant_small",
		"category": "gastro",
		"icon": "res://assets/icons/angelus2010/Rooms/ang-restaurant.aseprite",
		"nightly_price": 0,
		"locked": false,
		"in_build_menu": true,
		"req_level": 3,
		"req_tech": "G1.3",
		"max_beds": 0,
		"is_poi": true,
		"visit_income": 0, # Wird durch Rezepte bestimmt
		"visit_exp": 15,
		"supply_cost_per_visit": 10,
		"adults_only": false,
		"required_role": "waiter",
		"min_staff": 1,
		"max_staff": 3,
		"open_from": 420, # 07:00
		"open_to": 1320,  # 22:00
		"capacity": 20,   # Max. gleichzeitige Gäste (2 Familien-Tische + 5 kleine Tische = 20 Plätze)
		"valid_door_slots": ["R2"],
		"cleanliness_level": 100,
		"maintenance_level": 100,
		"is_service_requested": false
	}

## Gibt die globale Standposition für die Bedienung zurück (mittig im Gastraum)
func get_waiter_stand_pos() -> Vector2:
	var area = get_node_or_null("Interior/Furniture/WaiterArea")
	if is_instance_valid(area):
		return area.global_position
	# Fallback: Mitte des Raums (ca. 24, 24)
	return global_position + Vector2(24, 24)

# =============================================================================
# VARIABLES
# =============================================================================

# =============================================================================
# SEAT MANAGEMENT
# =============================================================================

# { chair_node: Node2D, occupied_by: guest_id, status: "clean"|"dirty", order_id: "" }
var _seats: Array = []
var _room_id: String = ""

# =============================================================================
func _ready() -> void:
	if not is_inside_tree(): return
	super._ready()
	
	# Alle Stühle aus den Gruppen auslesen
	var furniture = get_node_or_null("Interior/Furniture")
	if not furniture: return
	
	var groups = ["Chairs1", "Chairs2", "Fam1", "Fam2"]
	for g in groups:
		var parent_node = furniture.get_node_or_null(g)
		if parent_node:
			for child in parent_node.get_children():
				if "Chair" in child.name:
					_seats.append({
						"node": child,
						"occupied_by": "",
						"status": "clean",
						"order_id": ""
					})

# =============================================================================
# GUEST INTERACTION
# =============================================================================

## Prüft ob ein freier, sauberer Platz existiert
func has_free_seat() -> bool:
	for seat in _seats:
		if seat["occupied_by"] == "" and seat["status"] == "clean":
			return true
	return false

## Belegt einen Platz für einen Gast und gibt die globale Position des Stuhls zurück
func claim_seat(guest_id: String) -> Vector2:
	for seat in _seats:
		if seat["occupied_by"] == "" and seat["status"] == "clean":
			seat["occupied_by"] = guest_id
			# Die Stühle sind in verschiedenen Parent-Nodes, get_global_position() ist am sichersten
			return seat["node"].global_position
	return Vector2.ZERO

## Gast verlässt den Platz - Tisch wird dreckig
func leave_seat(guest_id: String) -> void:
	for seat in _seats:
		if seat["occupied_by"] == guest_id:
			seat["occupied_by"] = ""
			seat["status"] = "dirty"
			seat["order_id"] = ""
			if TaskManager:
				TaskManager.add_task("clean_table", {"room": self, "pos": seat["node"].global_position})
			break

# =============================================================================
# Live-Details für Gastro-Monitor
# =============================================================================
func get_live_details() -> Array[Dictionary]:
	var details: Array[Dictionary] = []
	
	if Engine.is_editor_hint() == false:
		if _room_id == "":
			_room_id = GuestManager._room_key(self)
			
	for seat in _seats:
		if seat["occupied_by"] != "":
			var guest_name = GameState.T("room.kitchen.guest")
			var gm = get_tree().get_first_node_in_group("guest_manager")
			var guest_node = gm.get_guest(seat["occupied_by"]) if gm else null
			if is_instance_valid(guest_node) or guest_node != null:
				guest_name = guest_node.name
				
			var status_text = GameState.T("poi.restaurant.studying_menu")
			var order_id = seat.get("order_id", "")
			
			if order_id != "":
				var order_data = GastroManager.active_orders.get(order_id)
				if order_data:
					var r_name = "?"
					for r in GameState.recipes:
						if r.get("id") == order_data.get("recipe_id"):
							r_name = GameState.T(r.get("name_key", ""))
							break
					var s = order_data.get("status", "")
					if s == "pending":
						status_text = GameState.T("poi.restaurant.ordered") + ": " + r_name
					elif s == "cooking":
						status_text = GameState.T("poi.restaurant.cooking") + ": " + r_name
					elif s == "ready":
						status_text = GameState.T("poi.restaurant.waiting_service")
				else:
					# Wenn order_id gesetzt ist, aber nicht in active_orders -> Serviert
					status_text = GameState.T("poi.restaurant.eating")
					
			var c = Color.WHITE
			if "custom_color" in self and typeof(custom_color) == TYPE_COLOR and custom_color != Color.WHITE:
				c = custom_color
			details.append({
				"left": guest_name,
				"right": status_text,
				"color": c
			})
			
	if details.is_empty():
		details.append({
			"left": GameState.T("room.kitchen.status"),
			"right": GameState.T("room.restaurant.empty")
		})
	return details

## Bedienung räumt Tisch ab
func clean_dirty_seat() -> bool:
	for seat in _seats:
		if seat["status"] == "dirty" and seat["occupied_by"] == "":
			seat["status"] = "clean"
			return true
	return false

## Sucht einen schmutzigen Stuhl (für TaskManager)
func get_dirty_seat_position() -> Vector2:
	for seat in _seats:
		if seat["status"] == "dirty" and seat["occupied_by"] == "":
			return seat["node"].global_position
	return Vector2.ZERO

## Gast bestellt etwas, sobald er sitzt
func place_order_for_seat(guest_id: String, budget: int = 9999, missing_sat: int = 100) -> bool:
	for seat in _seats:
		if seat["occupied_by"] == guest_id and seat["status"] == "clean":
			if _room_id == "":
				_room_id = GuestManager._room_key(self)
				
			var has_waiter = _has_waiter_assigned()
			if not has_waiter:
				return false
				
			var kitchen_is_open = false
			var map_grid = get_tree().get_first_node_in_group("map_grid")
			if map_grid and map_grid.has_method("get_placed_rooms"):
				for room in map_grid.get_placed_rooms():
					if is_instance_valid(room) and room.has_method("get_definition"):
						var def = room.get_definition()
						if def.get("id") == "kitchen_small" and GameState.is_facility_open(def, 30):
							var k_id = GuestManager._room_key(room)
							if StaffManager.is_poi_staffed(def, k_id):
								kitchen_is_open = true
								break
			
			if not kitchen_is_open:
				return false
				
			var possible_recipes = []
			for r in GameState.recipes:
				if "restaurant_small" in r.get("served_in", []) and r.get("price", 0) <= budget and r.get("saturation", 0) <= missing_sat:
					possible_recipes.append(r)
			
			if not possible_recipes.is_empty():
				if _room_id == "":
					_room_id = GuestManager._room_key(self)
				var chosen = possible_recipes[randi() % possible_recipes.size()]
				if GastroManager:
					var order_id = GastroManager.place_order(guest_id, chosen.get("id"), _room_id)
					seat["order_id"] = order_id
					return true
	return false

## Prüft ob ein Waiter (Bedienung) für dieses Restaurant zugewiesen ist
func _has_waiter_assigned() -> bool:
	if _room_id == "":
		_room_id = GuestManager._room_key(self)
	var assigned = StaffManager.get_staff_for_room(_room_id)
	for s in assigned:
		if not StaffManager.is_staff_available(s):
			continue
		if s.get("role", "") == "waiter":
			return true
	return false

func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	if _room_id == "":
		_room_id = GuestManager._room_key(self)
		
	if Engine.get_frames_drawn() % 60 == 0:
		if GastroManager:
			if _room_id == "":
				_room_id = GuestManager._room_key(self)
				
			var ready_orders = GastroManager.get_ready_orders_for_restaurant(_room_id)
			for order_id in ready_orders:
				# Prüfen ob wir schon einen serve_task dafür haben
				var has_task = false
				if TaskManager:
					for t in TaskManager._tasks:
						if t.type == "serve_meal" and t.target.get("order_id") == order_id:
							has_task = true
							break
				if not has_task and TaskManager:
					# Find seat
					var target_seat_pos = Vector2.ZERO
					for seat in _seats:
						if seat["order_id"] == order_id:
							target_seat_pos = seat["node"].global_position
							break
					TaskManager.add_task("serve_meal", {"room": self, "pos": target_seat_pos, "order_id": order_id})

## Essen wird von der Bedienung an den Tisch gebracht
func serve_order_to_seat(order_id: String) -> void:
	for seat in _seats:
		if seat["order_id"] == order_id:
			if GastroManager:
				GastroManager.serve_order(order_id)
			break
