extends "res://scenes/ingame/rooms/Room.gd"

# ANG-310: Bar – Sitz-Logik, Küchen-Anbindung & Bedienung

# =============================================================================
static func get_definition() -> Dictionary:
	return {
		"id": "bar",
		"build_cost": 1800,
		"exp_reward": 180,
		"prefix": "B",
		"label": "BA",
		"name": "roomdef.name.long.bar",
		"category": "gastro",
		"icon": "res://assets/icons/angelus2010/Rooms/ang-bar.aseprite",
		"nightly_price": 0,
		"locked": false,
		"in_build_menu": true,
		"req_level": 3,
		"req_tech": "G1.1",
		"max_beds": 0,
		"is_poi": true,
		"visit_income": 15,  # Basis-Eintritt (Getränke)
		"visit_exp": 10,
		"supply_cost_per_visit": 5,
		"adults_only": true,
		"required_role": "bartender",
		"allowed_roles": ["bartender", "waiter"],
		"min_staff": 1,
		"max_staff": 2,  # Slot 1: bartender (Pflicht), Slot 2: waiter (optional)
		"max_role_limits": {"bartender": 1, "waiter": 1},  # Je max. 1 pro Rolle
		"open_from": 720,   # 12:00
		"open_to": 1410,    # 23:30
		"valid_door_slots": ["R1"],
		"cleanliness_level": 100,
		"maintenance_level": 100,
		"is_service_requested": false
	}

# =============================================================================
# VARIABLES
# =============================================================================

# { node: Node2D, occupied_by: guest_id, status: "clean"|"dirty", order_id: "" }
var _seats: Array = []
var _room_id: String = ""

# =============================================================================
func _ready() -> void:
	if not is_inside_tree(): return
	super._ready()
	
	# Alle Stühle aus Interior/Furniture/Chairs einlesen
	var chairs_node = get_node_or_null("Interior/Furniture/Chairs")
	if chairs_node:
		for child in chairs_node.get_children():
			if "Chair" in child.name:
				_seats.append({
					"node": child,
					"occupied_by": "",
					"status": "clean",
					"order_id": ""
				})

# =============================================================================
# BARKEEPER WALKING-AREA
# =============================================================================

## Gibt die globale Standposition für den Barkeeper zurück (hinter dem Tresen)
func get_bartender_stand_pos() -> Vector2:
	var area = get_node_or_null("Interior/Furniture/BartenderArea")
	if is_instance_valid(area):
		return area.global_position
	# Fallback: Counter-Position wenn kein BartenderArea-Node vorhanden
	var counter = get_node_or_null("Interior/Furniture/Counter")
	if is_instance_valid(counter):
		return counter.global_position + Vector2(0, -8)
	return global_position

## Gibt die Blickrichtung für den Barkeeper zurück (zur Tür)
func get_bartender_look_dir() -> Vector2:
	var door = get_node_or_null("Door")
	if is_instance_valid(door):
		var dir = get_bartender_stand_pos().direction_to(door.global_position)
		# Auf die nächste der 4 Achsen (Up, Down, Left, Right) einrasten
		if abs(dir.x) > abs(dir.y):
			return Vector2(sign(dir.x), 0)
		else:
			return Vector2(0, sign(dir.y))
	return Vector2.DOWN

## Gibt die globale Standposition für die Bedienung zurück (mittig im Gastraum)
func get_waiter_stand_pos() -> Vector2:
	var area = get_node_or_null("Interior/Furniture/WaiterArea")
	if is_instance_valid(area):
		return area.global_position
	# Fallback: Mitte des Raums (ca. 8, 16)
	var door = get_node_or_null("Door")
	var counter = get_node_or_null("Interior/Furniture/Counter")
	if is_instance_valid(door) and is_instance_valid(counter):
		return door.global_position.lerp(counter.global_position, 0.5)
	return global_position + Vector2(16, 16)

# =============================================================================
# SEAT MANAGEMENT
# =============================================================================

## Prüft ob ein freier, sauberer Platz existiert
func has_free_seat() -> bool:
	for seat in _seats:
		if seat["occupied_by"] == "" and seat["status"] == "clean":
			return true
	return false

## Belegt einen Platz für einen Gast, gibt globale Position des Stuhls zurück
func claim_seat(guest_id: String) -> Vector2:
	for seat in _seats:
		if seat["occupied_by"] == "" and seat["status"] == "clean":
			seat["occupied_by"] = guest_id
			return seat["node"].global_position
	return Vector2.ZERO

## Gast verlässt den Platz – Stuhl wird dreckig, Putztask wird erstellt
func leave_seat(guest_id: String) -> void:
	for seat in _seats:
		if seat["occupied_by"] == guest_id:
			seat["occupied_by"] = ""
			seat["status"] = "dirty"
			seat["order_id"] = ""
			if TaskManager:
				TaskManager.add_task("clean_table", {"room": self, "pos": seat["node"].global_position})
			break

## Bedienung räumt Tisch ab
func clean_dirty_seat() -> bool:
	for seat in _seats:
		if seat["status"] == "dirty" and seat["occupied_by"] == "":
			seat["status"] = "clean"
			return true
	return false

## Position eines schmutzigen Stuhls (für TaskManager)
func get_dirty_seat_position() -> Vector2:
	for seat in _seats:
		if seat["status"] == "dirty" and seat["occupied_by"] == "":
			return seat["node"].global_position
	return Vector2.ZERO

# =============================================================================
# ORDER LOGIC
# =============================================================================

## Gast bestellt – Speisen nur wenn eine Bedienung zugewiesen ist.
## Ohne Bedienung trinkt der Gast nur (kein GastroManager-Aufruf).
func place_order_for_seat(guest_id: String) -> bool:
	for seat in _seats:
		if seat["occupied_by"] == guest_id and seat["status"] == "clean":
			# Prüfen ob Bedienung vorhanden
			if _room_id == "":
				_room_id = GuestManager._room_key(self)
			var has_waiter = _has_waiter_assigned()
			
			if not has_waiter:
				# Kein Waiter → Gast trinkt nur (kein Küchenauftrag, kein GastroManager)
				# Gast bleibt kurz sitzen und geht dann
				return false
			
			# Bedienung vorhanden -> Speise bestellen
			# ZUERST PRÜFEN: Ist überhaupt eine Küche noch offen für Bestellungen?
			var kitchen_is_open = false
			var map_grid = get_tree().get_first_node_in_group("map_grid")
			if map_grid and map_grid.has_method("get_placed_rooms"):
				for room in map_grid.get_placed_rooms():
					if is_instance_valid(room) and room.has_method("get_definition"):
						var def = room.get_definition()
						if def.get("id") == "kitchen_small" and GameState.is_facility_open(def, 30):
							kitchen_is_open = true
							break
			
			if not kitchen_is_open:
				# Küche geschlossen -> Gast trinkt nur
				return false
				
			var possible_recipes: Array = []
			for r in GameState.recipes:
				if "bar" in r.get("served_in", []):
					possible_recipes.append(r)
			
			if not possible_recipes.is_empty() and GastroManager:
				var chosen = possible_recipes[randi() % possible_recipes.size()]
				var order_id = GastroManager.place_order(guest_id, chosen.get("id"), _room_id)
				seat["order_id"] = order_id
				return true
	return false

## Prüft ob ein Waiter (Bedienung) für diese Bar zugewiesen ist
func _has_waiter_assigned() -> bool:
	if _room_id == "":
		_room_id = GuestManager._room_key(self)
	var assigned = StaffManager.get_staff_for_room(_room_id)
	for s in assigned:
		if s.get("role", "") == "waiter":
			return true
	return false

# =============================================================================
# PROCESS – Prüft jede Sekunde ob fertig gekochte Bestellungen abgeholt werden müssen
# =============================================================================
func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	if _room_id == "":
		_room_id = GuestManager._room_key(self)
	
	if Engine.get_frames_drawn() % 60 == 0:
		if GastroManager and _room_id != "":
			var ready_orders = GastroManager.get_ready_orders_for_restaurant(_room_id)
			for order_id in ready_orders:
				var has_task = false
				if TaskManager:
					for t in TaskManager._tasks:
						if t.type == "serve_meal" and t.target.get("order_id") == order_id:
							has_task = true
							break
				if not has_task and TaskManager:
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

# =============================================================================
# LIVE-MONITOR
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
			
			var status_text = GameState.T("poi.bar.drinking")
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
					status_text = GameState.T("poi.restaurant.eating")
			
			var c = Color.WHITE
			if "custom_color" in self and custom_color != "":
				c = Color(custom_color)
			details.append({"left": guest_name, "right": status_text, "color": c})
	
	if details.is_empty():
		details.append({"left": GameState.T("room.kitchen.status"), "right": GameState.T("room.bar.empty")})
	
	return details
