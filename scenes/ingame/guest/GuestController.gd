extends Node
class_name GuestController

const GUEST_ACTOR_SCENE = preload("res://scenes/ingame/guest/GuestActor.tscn")

var _guest_manager: GuestManager
var _map_grid: Node # MapGrid Referenz
var _actors: Dictionary = {} # guest_id: GuestActor

# =============================================================================
func setup(guest_manager: GuestManager, map_grid: Node) -> void:
	_guest_manager = guest_manager
	_map_grid = map_grid
	
	if is_instance_valid(_guest_manager):
		_guest_manager.sig_party_checked_in.connect(_on_party_checked_in)
		_guest_manager.sig_party_moving_to_checkout.connect(_on_party_moving_to_checkout)
		_guest_manager.sig_party_checked_out_physically.connect(_on_party_checked_out_physically)


# =============================================================================
func spawn_active_guests() -> void:
	for party in _guest_manager._active:
		var room = _find_room_by_id(party.room_id)
		for member in party.members:
			var guest_id = member.id  # Stabile ID aus dem Savegame
			if not _actors.has(guest_id):
				_create_actor(member, party.room_id, room)
				
	# Auch Gäste spawnen, die bereits im Checkout sind (nach Reload)
	for party in _guest_manager._checkout:
		var room = _find_room_by_id(party.room_id)
		for member in party.members:
			var guest_id = member.id
			if not _actors.has(guest_id):
				var actor = _create_actor(member, party.room_id, room)
				# Da sie schon im Checkout sind, müssen sie direkt loslaufen
				actor.start_checkout()


# =============================================================================
func _on_party_checked_in(party: GuestParty, room: Node2D) -> void:
	if not is_instance_valid(room):
		return
		
	var entry_parcel: Node2D = _map_grid._grid[_map_grid._entry_plot.y][_map_grid._entry_plot.x]
	var base_pos = Vector2.ZERO
	if is_instance_valid(entry_parcel) and entry_parcel.has_method("get_lobby"):
		var lobby = entry_parcel.get_lobby()
		if is_instance_valid(lobby) and lobby.has_method("get_target_tile"):
			base_pos = _map_grid.tile_to_world(lobby.get_target_tile(_map_grid))
	
	if base_pos == Vector2.ZERO:
		base_pos = _map_grid.tile_to_world(Vector2i(_map_grid._entry_plot.x * _map_grid.PARCEL_SZ, _map_grid._entry_plot.y * _map_grid.PARCEL_SZ))
	
	
	# room_id extrahieren, da _create_actor diese braucht falls room mal invalid wird
	var rnum: String = str(room.get("room_number"))
	var rkey = rnum
	if rnum == "" or rnum == "null":
		rkey = "%s_%d_%d" % [str(room.get("room_type_id")), int(room.get("x_pos")), int(room.get("y_pos"))]
	
	for i in range(party.members.size()):
		var member = party.members[i]
		
		var actor = _create_actor(member, rkey, null) # null als start_room -> Startet an Rezeption
		
		var offset := Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
		actor.start_checkin(room, base_pos + offset, i * 0.8)


# =============================================================================
func _on_party_moving_to_checkout(party: GuestParty, _room_id: String) -> void:
	for member in party.members:
		var guest_id = member.id  # Stabile ID
		if _actors.has(guest_id):
			var actor = _actors[guest_id]
			actor.start_checkout()
			# NICHT manuell aus _actors löschen!
			# tree_exiting räumt auf wenn der Actor queue_free() ruft.
			# So kann der Tooltip noch "Abreisend" anzeigen.


# =============================================================================
## Spieler hat Checkout bestätigt: Gast erscheint vor der Lobby und läuft raus.
func _on_party_checked_out_physically(party: GuestParty) -> void:
	var spawn_pos = _get_lobby_spawn_pos()
	for member in party.members:
		var guest_id = member.id
		var actor = _actors.get(guest_id, null)
		if not is_instance_valid(actor):
			# Gast hatte keinen Actor (z.B. nach Reload und er stand im Checkout)
			actor = _create_actor(member, party.room_id, null)
		
		if is_instance_valid(actor):
			actor.complete_checkout(spawn_pos)


# =============================================================================
func _get_lobby_spawn_pos() -> Vector2:
	var entry_parcel: Node2D = _map_grid._grid[_map_grid._entry_plot.y][_map_grid._entry_plot.x]
	if entry_parcel and entry_parcel.has_method("get_lobby"):
		var lobby = entry_parcel.get_lobby()
		if is_instance_valid(lobby) and lobby.has_method("get_target_tile"):
			return _map_grid.tile_to_world(lobby.get_target_tile(_map_grid))
			
	return _map_grid.tile_to_world(Vector2i(_map_grid._entry_plot.x * _map_grid.PARCEL_SZ, _map_grid._entry_plot.y * _map_grid.PARCEL_SZ))


# =============================================================================
func _create_actor(member: GuestMember, room_id: String, start_room: Node2D) -> Node2D:
	var actor = GUEST_ACTOR_SCENE.instantiate()
	actor.z_index = 100
	_map_grid.get_node("WorldRoot").add_child(actor)
	
	# Fallback, falls start_room = null, aber er gespawnt werden soll
	if start_room == null and _map_grid != null:
		start_room = _find_room_by_id(room_id)
		
	actor.setup(member, _map_grid, start_room, _guest_manager)
	
	# FloatingValues: POI-Einnahmen via EffectManager visualisieren
	actor.sig_poi_income.connect(func(amount: int, world_pos: Vector2):
		EffectManager.spawn_money_text(amount, world_pos)
	)
	
	var guest_id = member.id  # Stabile ID – überlebt Save/Load!
	_actors[guest_id] = actor
	
	actor.tree_exiting.connect(func(): _actors.erase(guest_id))
	return actor


# =============================================================================
func _find_room_by_id(room_id: String) -> Node2D:
	for room in _map_grid.active_rooms:
		if not is_instance_valid(room): continue
		var rnum: String = str(room.get("room_number"))
		var rkey = rnum
		if rnum == "" or rnum == "null":
			rkey = "%s_%d_%d" % [str(room.get("room_type_id")), int(room.get("x_pos")), int(room.get("y_pos"))]
		if rkey == room_id:
			return room
	return null


# =============================================================================
## Wird um 22:00 Uhr aufgerufen: Alle Gäste in Lobby/Bar kehren ins Zimmer zurück
func send_lobby_guests_to_rooms() -> void:
	for actor in _actors.values():
		if is_instance_valid(actor):
			actor.send_back_to_room()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_T and event.ctrl_pressed:
		print("=========================================")
		print("  GUEST ACTOR DUMP (CTRL+T)  ")
		print("=========================================")
		print("Active Parties in Manager: ", _guest_manager._active.size())
		print("Checkout Parties in Manager: ", _guest_manager._checkout.size())
		
		for p in _guest_manager._active:
			print(" - Party %s (Room: %s) Nights: %d" % [p.id, p.room_id, p.stay_days])
			for m in p.members:
				var status = "No Actor!"
				if _actors.has(m.id):
					var a = _actors[m.id]
					status = "Actor State: %d, POI: %s, Pos: %s" % [a.current_state, a._current_poi_id, str(a.global_position)]
				print("   * Guest %s: %s" % [m.id, status])
				
		print("--- CHECKOUT PARTIES ---")
		for p in _guest_manager._checkout:
			print(" - Checkout Party %s (Room: %s)" % [p.id, p.room_id])
			for m in p.members:
				var status = "No Actor!"
				if _actors.has(m.id):
					var a = _actors[m.id]
					status = "Actor State: %d, POI: %s, Pos: %s" % [a.current_state, a._current_poi_id, str(a.global_position)]
				print("   * Guest %s: %s" % [m.id, status])
		print("=========================================")
