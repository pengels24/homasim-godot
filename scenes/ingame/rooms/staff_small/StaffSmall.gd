extends "res://scenes/ingame/rooms/Room.gd"

# =============================================================================
static func get_definition() -> Dictionary:
	return {
		"id": "staff_small",
		"build_cost": 2500,
		"exp_reward": 300,
		"prefix": "S",
		"label": "ST",
		"name": "roomdef.name.long.staff_small",
		"category": "management",
		"icon": "res://assets/icons/angelus2010/Rooms/ang-sraff-small.aseprite",
		"nightly_price": 0,
		"locked": false,
		"in_build_menu": true,
		"req_level": 2, # Personal wird ab Level 2 freigeschaltet
		"req_tech": "",
		"max_beds": 0,
		"is_poi": false,
		"is_staff_poi": true,
		"adults_only": false,
		"valid_door_slots": ["L3"],
		"cleanliness_level": 100,
		"maintenance_level": 100
	}

# =============================================================================
# SEAT MANAGEMENT
# =============================================================================

# Format: { node: Node2D, occupied_by: String (staff_id), type: "bed"|"chair" }
var _seats: Array = []

# =============================================================================
func _ready() -> void:
	if not is_inside_tree(): return
	super._ready()
	
	var furniture = get_node_or_null("Interior/Furniture")
	if not furniture: return
	
	# Stühle (Chairs) sammeln
	var living = furniture.get_node_or_null("Living")
	if living:
		var chairs_group = living.get_node_or_null("Chairs")
		if chairs_group:
			for child in chairs_group.get_children():
				if "Chair" in child.name:
					_seats.append({
						"node": child,
						"occupied_by": "",
						"type": "chair"
					})
	
	# Betten (Beds) aus Room1 und Room2 sammeln
	var rooms = ["Room1", "Room2"]
	for r in rooms:
		var room_node = furniture.get_node_or_null(r)
		if room_node:
			for child in room_node.get_children():
				if child.name.begins_with("Bed") and not child.name.begins_with("BedTable") and not child.name.begins_with("BedCase"):
					_seats.append({
						"node": child,
						"occupied_by": "",
						"type": "bed"
					})

# =============================================================================
# STAFF INTERACTION
# =============================================================================

func get_occupied_count() -> int:
	var unique = {}
	for seat in _seats:
		if seat["occupied_by"] != "":
			unique[seat["occupied_by"]] = true
	return unique.size()

func has_free_seat() -> bool:
	var def = get_definition()
	var cap = def.get("capacity", 4)
	if get_occupied_count() >= cap:
		return false
		
	for seat in _seats:
		if seat["occupied_by"] == "":
			return true
	return false

## Belegt einen freien Platz und gibt Position und Blickrichtung zurück.
func claim_seat(staff_id: String, prefer_bed: bool = false) -> Dictionary:
	leave_seat(staff_id) # Falls er schon einen Platz hat, diesen freigeben
	
	var def = get_definition()
	var cap = def.get("capacity", 4)
	if get_occupied_count() >= cap:
		return {}
		
	var target_seat = null
	
	# 1. Bevorzugten Typ suchen
	var preferred_type = "bed" if prefer_bed else "chair"
	for seat in _seats:
		if seat["occupied_by"] == "" and seat["type"] == preferred_type:
			target_seat = seat
			break
			
	# 2. Fallback auf den anderen Typ, falls Wunschplatz voll ist
	if target_seat == null:
		for seat in _seats:
			if seat["occupied_by"] == "":
				target_seat = seat
				break
				
	if target_seat != null:
		target_seat["occupied_by"] = staff_id
		
		# Blickrichtung bestimmen
		var look_at_pos = Vector2.ZERO
		if target_seat["type"] == "chair":
			var table = get_node_or_null("Interior/Furniture/Living/Table")
			if table: look_at_pos = table.global_position
			else: look_at_pos = get_node("Interior").global_position
		else:
			# Betten schauen in die Raummitte
			var interior = get_node_or_null("Interior")
			if interior: look_at_pos = interior.global_position
			
		return {
			"pos": target_seat["node"].global_position,
			"type": target_seat["type"],
			"look_at": look_at_pos
		}
		
	return {}

func leave_seat(staff_id: String) -> void:
	for seat in _seats:
		if seat["occupied_by"] == staff_id:
			seat["occupied_by"] = ""
			break

func get_waypoints() -> Array[Vector2]:
	var wps: Array[Vector2] = []
	var waypoints_node = get_node_or_null("Interior/WayPoints")
	if waypoints_node:
		for i in range(1, 10):
			var wp = waypoints_node.get_node_or_null("WayPoint" + str(i))
			if wp:
				wps.append(wp.global_position)
	return wps

func get_live_details() -> Array[Dictionary]:
	var details: Array[Dictionary] = []
	
	if Engine.is_editor_hint():
		return details
		
	var staff_actors = get_tree().get_nodes_in_group("staff_actors")
	for actor in staff_actors:
		if is_instance_valid(actor) and actor.get("_current_room") == self:
			var s_data = actor.get("_staff_data")
			if s_data:
				var job = actor.get_job_type()
				var job_name = GameState.T("staff.role." + job)
				var staff_name = s_data.get("first_name", "") + " " + s_data.get("last_name", "") + " (" + job_name + ")"
				
				var state = actor.get("_state")
				var status_txt = ""
				if state == "resting":
					status_txt = "Pausiert"
				elif state == "idle" or state == "returning":
					status_txt = GameState.T("staff.tooltip.state.idle")
				elif state == "walking_to_break" or state == "walking":
					status_txt = GameState.T("staff.tooltip.state.walking")
				elif state == "working":
					status_txt = GameState.T("staff.tooltip.state.working")
				else:
					status_txt = state
					
				var morale = s_data.get("morale", 100)
				var right_text = status_txt + " - " + GameState.T("ui.staff.morale") + ": " + str(int(morale)) + "%"
				
				var c_color = Color.WHITE
				if "custom_color" in self:
					var col = self.get("custom_color")
					if typeof(col) == TYPE_COLOR:
						c_color = col
					elif typeof(col) == TYPE_STRING and col != "":
						c_color = Color(col)
				
				details.append({
					"left": staff_name,
					"right": right_text,
					"color": c_color
				})
				
	return details
