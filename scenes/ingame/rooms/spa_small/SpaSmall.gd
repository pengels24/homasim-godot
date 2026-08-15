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

## Merkt sich pro Gast ob er zuletzt auf einem Chair oder Bed sass
var _last_seat_type: Dictionary = {}

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

## Wechselt zwischen Chair (Lounge/Sauna) und Bed (Liege) ab.
## Nutzt _last_seat_type um den Wechsel auch nach leave_seat korrekt durchzufuehren.
func claim_seat(guest_id: String) -> Vector2:
	# Schon belegt? Aktuelle Position zurueckgeben
	for s in _room_seats:
		if s["occupied_by"] == guest_id:
			return s["node"].global_position
	for b in _room_beds:
		if b["occupied_by"] == guest_id:
			return b["node"].global_position
	# Letzten Typ lesen: von Chair -> Bed, von Bed -> Chair, erstes Mal -> Chair
	var last_type: String = _last_seat_type.get(guest_id, "chair")
	var use_beds := last_type == "chair"
	var free: Array = []
	for s in (_room_beds if use_beds else _room_seats):
		if s["occupied_by"] == "":
			free.append(s)
	# Fallback: wenn Zieltyp voll ist
	if free.is_empty():
		for s in (_room_seats if use_beds else _room_beds):
			if s["occupied_by"] == "":
				free.append(s)
		use_beds = not use_beds # Fallback-Typ merken
	if free.is_empty():
		return Vector2.INF
	free.shuffle()
	var chosen = free[0]
	chosen["occupied_by"] = guest_id
	_last_seat_type[guest_id] = "bed" if use_beds else "chair"
	return chosen["node"].global_position
	
func leave_seat(guest_id: String) -> void:
	for s in _room_seats:
		if s["occupied_by"] == guest_id:
			s["occupied_by"] = ""
			_last_seat_type[guest_id] = "chair" # War auf Chair
	for b in _room_beds:
		if b["occupied_by"] == guest_id:
			b["occupied_by"] = ""
			_last_seat_type[guest_id] = "bed" # War auf Bed

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
# LIVE-MONITOR
# =============================================================================
func get_live_details() -> Array[Dictionary]:
	var details: Array[Dictionary] = []
	var gm = get_tree().get_first_node_in_group("guest_manager")
	
	for seat in _room_seats:
		if seat["occupied_by"] != "":
			var guest_name = "Gast"
			if gm:
				var guest_node = gm.get_guest(seat["occupied_by"])
				if guest_node:
					guest_name = guest_node.name
			details.append({"left": guest_name, "right": "Entspannt sich", "color": Color("#3b82f6")})
	
	for bed in _room_beds:
		if bed["occupied_by"] != "":
			var guest_name = "Gast"
			if gm:
				var guest_node = gm.get_guest(bed["occupied_by"])
				if guest_node:
					guest_name = guest_node.name
			details.append({"left": guest_name, "right": "Liegt", "color": Color("#818cf8")})
	
	return details
