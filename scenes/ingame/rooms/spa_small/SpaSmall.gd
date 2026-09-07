extends "res://scenes/ingame/rooms/Room.gd"

# =============================================================================
static func get_definition() -> Dictionary:
	return {
		"id": "spa_small",
		"build_cost": 4500,
		"exp_reward": 450,
		"prefix": "W",
		"label": "SPA",
		"name": "roomdef.name.long.spa_small",
		"category": "wellness",
		"icon": "res://assets/icons/angelus2010/Rooms/ang-spa-small.aseprite",
		"nightly_price": 0,
		"locked": false,
		"max_guests": 6,
		"in_build_menu": true,
		"req_level": 4,
		"req_tech": "W1.3",
		"max_beds": 0,
		"is_poi": true,
		"is_guest_poi": true,
		"visit_income": 45,
		"visit_exp": 20,
		"supply_cost_per_visit": 8,
		"adults_only": true,
		"required_role": "wellness_counselor",
		"allowed_roles": ["wellness_counselor"],
		"min_staff": 1,
		"max_staff": 1,
		"need_restoration": {"energy": 60, "fun": 30},
		"open_from": 540,   # 09:00
		"open_to": 1260,    # 21:00
		"valid_door_slots": ["L2"],
		"cleanliness_level": 100,
		"maintenance_level": 100,
		"is_service_requested": false
	}

# =============================================================================
# Visuals (3x3)
# =============================================================================
const FLOOR_W := 44.0
const FLOOR_H := 44.0
const FLOOR_TEX_W := 256.0

## Zaehler fuer get_work_position - steuert ServicePoint vs. Patrouille
var _work_call_count: int = 0

func set_floor_neighbors(top: bool, right: bool, bottom: bool, left: bool) -> void:
	var w: Array[bool] = [top, right, bottom, left]
	var l_top    := w[(0 + room_rotation) % 4]
	var l_right  := w[(1 + room_rotation) % 4]
	var l_bottom := w[(2 + room_rotation) % 4]
	var l_left   := w[(3 + room_rotation) % 4]
	var ext_l := 1.0 if l_left  else 0.0
	var ext_r := 1.0 if l_right else 0.0
	var ext_t := 1.0 if l_top   else 0.0
	var ext_b := 1.0 if l_bottom else 0.0

	var f := $Interior/Floor as Sprite2D
	if f:
		f.scale    = Vector2((FLOOR_W + ext_l + ext_r) / FLOOR_TEX_W, FLOOR_H + ext_t + ext_b)
		f.position = Vector2(24.0 + (ext_r - ext_l) * 0.5, 24.0 + (ext_b - ext_t) * 0.5)

func _apply_visuals() -> void:
	if not is_node_ready():
		return
		
	var interior := $Interior as Node2D
	if interior:
		if room_rotation == 1:
			interior.position = Vector2(48, 0)
			interior.rotation = PI / 2.0
		elif room_rotation == 2:
			interior.position = Vector2(48, 48)
			interior.rotation = PI
		elif room_rotation == 3:
			interior.position = Vector2(0, 48)
			interior.rotation = -PI / 2.0
		else:
			interior.position = Vector2(0, 0)
			interior.rotation = 0.0
	
	super._apply_visuals()



# =============================================================================
# STAFF: Wellness-Fachkraft navigiert zum ServicePoint (Empfangsbereich)
# oder patrouilliert den Raum (jeder 4. Aufruf)
# =============================================================================
func get_work_position(_staff_id: String) -> Vector2:
	_work_call_count += 1
	# Jeder 10. Aufruf (~20 Sek): Patrouille statt ServicePoint
	if _work_call_count % 10 == 0:
		return get_patrol_target()
	var sp_pos := get_service_position()
	if sp_pos != Vector2.INF:
		return sp_pos
	return Vector2.INF

## Zufaellige Patrouille-Position innerhalb des Spa-Raums
func get_patrol_target() -> Vector2:
	var sz := get_tile_size() * 32.0
	return global_position + Vector2(
		randf_range(12.0, sz.x - 12.0),
		randf_range(12.0, sz.y - 12.0))

# =============================================================================


# =============================================================================
# LIVE-MONITOR
# =============================================================================
func get_available_interactions(actor: Node2D) -> Array[Dictionary]:
	var interactions = super.get_available_interactions(actor)
	# Im Spa sollen die Gäste nur sitzen oder liegen, nicht dumm herumstehen!
	return interactions.filter(func(i): return i.type != "wander")

func claim_interaction(actor_id: String, interaction_id: String) -> Dictionary:
	# Spa: längere Aufenthaltsdauer (90-180 Min)
	var stay_dur := randf_range(90.0, 180.0)
	var def = get_definition()
	if def.has("open_to"):
		var open_to: int = def.get("open_to")
		if open_to < 1440:
			var now := TimeManager.get_game_time() if TimeManager else 0
			var time_left := open_to - now
			if time_left > 0:
				stay_dur = min(stay_dur, float(time_left))
			else:
				stay_dur = 1.0
	var result := super.claim_interaction(actor_id, interaction_id)
	if result.has("target_pos"):
		result["duration"] = stay_dur
	return result

func get_live_details() -> Array[Dictionary]:
	var details: Array[Dictionary] = []
	
	for actor in get_tree().get_nodes_in_group("guest_actors"):
		var valid_states = [3, 6, 7, 8, 9] # IN_POI, STUDYING_MENU, WAITING_FOR_FOOD, EATING, SITTING
		if actor.get("current_state") in valid_states and actor.get("_current_poi_id") == "spa_small":
			var gm = actor.get("_guest_member")
			if gm:
				var time_left_sec = actor.get("_action_timer")
				var time_left_mins = 0
				if time_left_sec != null:
					time_left_mins = int(time_left_sec / 4.0)
				
				var status_text = GameState.T("poi.spa.relaxing")
				var color = Color("#3b82f6")
				
				# Check if actor is in a bed
				for b in _room_beds:
					if b["occupied_by"] == actor.get("actor_id"):
						status_text = GameState.T("poi.spa.lying_down")
						color = Color("#818cf8")
						break
					
				if time_left_mins > 0:
					status_text += " (%dm)" % time_left_mins
					
				details.append({
					"left": gm.name,
					"right": status_text,
					"color": color
				})
			
	return details
