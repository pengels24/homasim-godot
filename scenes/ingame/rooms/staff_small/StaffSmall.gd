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
		"capacity": 4,
		"is_poi": false,
		"is_staff_poi": true,
		"adults_only": false,
		"valid_door_slots": ["L3"],
		"cleanliness_level": 100,
		"maintenance_level": 100
	}

# =============================================================================
# SMART ROOM OVERRIDE
# =============================================================================

func get_available_interactions(actor: Node2D) -> Array[Dictionary]:
	var current_occupants = 0
	var actor_id = ""
	if is_instance_valid(actor):
		actor_id = actor.get("id") if actor.get("id") else actor.name
	
	for b in _room_beds:
		if b["occupied_by"] != "" and b["occupied_by"] != actor_id:
			current_occupants += 1
	for s in _room_seats:
		if s["occupied_by"] != "" and s["occupied_by"] != actor_id:
			current_occupants += 1
			
	var def = get_definition()
	var cap = def.get("capacity", 4)
	
	if current_occupants >= cap:
		return [] # Raum ist voll
		
	return super.get_available_interactions(actor)

# =============================================================================
# LEGACY STAFF BREAK ROOM API (wird von StaffActor._process_idle genutzt)
# =============================================================================

func has_free_seat() -> bool:
	for s in _room_seats:
		if s["occupied_by"] == "":
			return true
	for b in _room_beds:
		if b["occupied_by"] == "":
			return true
	return false

## Gibt einen freien Sitz zurück und belegt ihn.
## prefer_bed=true → Bett bevorzugen (Nacht/erschöpft)
func claim_seat(staff_id: String, prefer_bed: bool = false) -> Dictionary:
	# Zuerst Bett wenn bevorzugt
	if prefer_bed:
		for b in _room_beds:
			if b["occupied_by"] == "":
				b["occupied_by"] = staff_id
				var look = b["node"].global_position + Vector2(0, -8)
				return {"pos": b["node"].global_position, "look_at": look, "type": "bed"}
	# Dann Stuhl
	for s in _room_seats:
		if s["occupied_by"] == "":
			s["occupied_by"] = staff_id
			var look = s["node"].global_position + Vector2(0, -8)
			return {"pos": s["node"].global_position, "look_at": look, "type": "chair"}
	# Fallback: Bett auch wenn nicht bevorzugt
	for b in _room_beds:
		if b["occupied_by"] == "":
			b["occupied_by"] = staff_id
			var look = b["node"].global_position + Vector2(0, -8)
			return {"pos": b["node"].global_position, "look_at": look, "type": "bed"}
	return {}

## Gibt den Platz frei
func leave_seat(staff_id: String) -> void:
	for s in _room_seats:
		if s["occupied_by"] == staff_id:
			s["occupied_by"] = ""
			return
	for b in _room_beds:
		if b["occupied_by"] == staff_id:
			b["occupied_by"] = ""
			return


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
