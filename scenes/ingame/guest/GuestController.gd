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
	var clearance: Rect2i = entry_parcel.get_lobby_clearance_rect()
	var lx: int = int(_map_grid._entry_plot.x * _map_grid.PARCEL_SZ) + clearance.position.x + int(clearance.size.x / 2.0)
	var ly: int = int(_map_grid._entry_plot.y * _map_grid.PARCEL_SZ) + clearance.position.y + int(clearance.size.y / 2.0)
	
	var base_pos = _map_grid.tile_to_world(Vector2i(lx, ly))
	
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
	var clearance: Rect2i = entry_parcel.get_lobby_clearance_rect()
	var lx: int = int(_map_grid._entry_plot.x * _map_grid.PARCEL_SZ) + clearance.position.x + int(clearance.size.x / 2.0)
	var ly: int = int(_map_grid._entry_plot.y * _map_grid.PARCEL_SZ) + clearance.position.y + int(clearance.size.y / 2.0)
	return _map_grid.tile_to_world(Vector2i(lx, ly))


# =============================================================================
func _create_actor(member: GuestMember, room_id: String, start_room: Node2D) -> Node2D:
	var actor = GUEST_ACTOR_SCENE.instantiate()
	actor.z_index = 100
	_map_grid.get_node("WorldRoot").add_child(actor)
	
	# Fallback, falls start_room = null, aber er gespawnt werden soll
	if start_room == null and _map_grid != null:
		start_room = _find_room_by_id(room_id)
		
	actor.setup(member, _map_grid, start_room)
	
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
