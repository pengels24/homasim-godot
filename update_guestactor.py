import os

filepath = r"d:\game-dev\homasim-godot\scenes\ingame\guest\GuestActor.gd"
with open(filepath, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Update _get_open_pois
old_poi_logic = '''\t\t# Kinder dürfen nicht in adults_only POIs
\t\tif def.get("adults_only", false) and _guest_member.is_child:
\t\t\tcontinue
\t\t
\t\t# Erlaubte Gäste-Typen prüfen (z.B. Konferenzraum nur für Business)
\t\tvar allowed_types = def.get("allowed_guest_types", [])
\t\tvar party = _get_my_party()
\t\tif not allowed_types.is_empty():
\t\t\tif not is_instance_valid(party) or not allowed_types.has(party.type):
\t\t\t\tcontinue
\t\t\t\t
\t\tvar room_id: String = def.get("id", "")
\t\t\t\t
\t\t# Tagesgäste (ohne Zimmer) dürfen keine exklusiven Hotel-Annehmlichkeiten nutzen!
\t\tif is_instance_valid(party) and party.room_id == "":
\t\t\tif room_id in ["pool_small", "gym_small", "spa_small"]:
\t\t\t\tcontinue'''

new_poi_logic = '''\t\tvar room_id: String = def.get("id", "")
\t\t
\t\t# SMART ROOM: Der Raum entscheidet selbst, ob der Gast rein darf!
\t\tif room.has_method("is_guest_allowed") and not room.is_guest_allowed(self):
\t\t\tcontinue'''

if old_poi_logic in content:
    content = content.replace(old_poi_logic, new_poi_logic)
    print("Replaced _get_open_pois logic")
else:
    print("FAILED to replace _get_open_pois logic")

# 2. Update _execute_walk
old_walk_logic = '''\t# NEU: Animierter "Walk out of Room", statt Teleportation
\t# Nur nach draußen laufen, wenn wir auch wirklich den Raum verlassen (path_tiles > 0) ODER das Hotel verlassen
\tif path_tiles.size() > 0 or finish_state == State.LEAVING:
\t\tif (previous_state == State.IN_ROOM or previous_state == State.SITTING or previous_state == State.SLEEPING) and is_instance_valid(_target_room):
\t\t\tif _target_room.has_method("get_local_path") and _target_room.has_method("get_room_entry_pos"):
\t\t\t\tvar entry_pos = _target_room.get_room_entry_pos(_map_grid)
\t\t\t\tvar local_path_out = _target_room.get_local_path(global_position, entry_pos)
\t\t\t\tworld_path.append_array(local_path_out)
\t\telif (previous_state == State.IDLE or previous_state == State.IN_POI or previous_state == State.AWAITING_CHECKOUT or previous_state == State.EATING or previous_state == State.STUDYING_MENU or previous_state == State.WAITING_FOR_FOOD or previous_state == State.WAITING_IN_LINE) and not _current_poi_id.is_empty():
\t\t\tvar poi_room = _get_poi_room_node(_current_poi_id)
\t\t\tif is_instance_valid(poi_room) and poi_room.has_method("get_local_path") and poi_room.has_method("get_room_entry_pos"):
\t\t\t\tvar entry_pos = poi_room.get_room_entry_pos(_map_grid)
\t\t\t\t
\t\t\t\t# Wenn wir das Hotel verlassen, gehen wir zum Haupteingang statt zur Innentür!
\t\t\t\tif finish_state == State.LEAVING and _current_poi_id == "lobby":
\t\t\t\t\tentry_pos = face_pos
\t\t\t\t\t
\t\t\t\tvar local_path_out = poi_room.get_local_path(global_position, entry_pos)
\t\t\t\tworld_path.append_array(local_path_out)
\t\t\t\tprint("[GuestActor] Generated local_path_out from POI: ", local_path_out.size(), " points. poi_id=", _current_poi_id)
\t\t\telse:
\t\t\t\tprint("[GuestActor] POI Room invalid or missing methods! poi_id=", _current_poi_id)
\t\telse:
\t\t\tprint("[GuestActor] Skipped local_path_out. prev_state=", previous_state, " poi_id=", _current_poi_id)
\t\t\t
\tif _map_grid and "is_miniature" in _map_grid and not _map_grid.is_miniature:
\t\t_map_grid._debug_paths.append(path_tiles)
\t\t\t
\tvar door_index_out := -1
\tif world_path.size() > 0:
\t\tdoor_index_out = world_path.size() - 1

\tfor tile in path_tiles:
\t\tworld_path.append(_map_grid.tile_to_world(tile))
\t\t
\tvar door_index_in := -1
\tif extra_target_pos != Vector2.INF:
\t\tdoor_index_in = world_path.size() - 1
\t\tif is_instance_valid(target_room) and target_room.has_method("get_local_path"):
\t\t\tvar local_path = target_room.get_local_path(face_pos, extra_target_pos)
\t\t\tworld_path.append_array(local_path)
\t\telse:
\t\t\tworld_path.append(extra_target_pos)'''

new_walk_logic = '''\t# --- SMART ROOM NAVIGATION HANDSHAKE ---
\t# PHASE 1: Local Path Out (Raum verlassen)
\tvar is_leaving_hotel = (finish_state == State.LEAVING)
\tvar current_room = _get_current_room_node()
\t
\tif is_instance_valid(current_room) and current_room.has_method("get_local_path") and current_room.has_method("get_door_world_inside"):
\t\t# Wenn wir den Raum wirklich verlassen (Pfad ist nicht leer) ODER das Hotel verlassen
\t\tif path_tiles.size() > 0 or is_leaving_hotel:
\t\t\tvar door_inside = current_room.get_door_world_inside(_map_grid, is_leaving_hotel)
\t\t\tvar local_path_out = current_room.get_local_path(global_position, door_inside)
\t\t\tworld_path.append_array(local_path_out)
\t\t\t
\tif _map_grid and "is_miniature" in _map_grid and not _map_grid.is_miniature:
\t\t_map_grid._debug_paths.append(path_tiles)

\t# PHASE 2: Global Path (Flur)
\tfor tile in path_tiles:
\t\tworld_path.append(_map_grid.tile_to_world(tile))
\t\t
\t# PHASE 3: Local Path In (Ziel-Raum betreten)
\tif extra_target_pos != Vector2.INF:
\t\tif is_instance_valid(target_room) and target_room.has_method("get_local_path") and target_room.has_method("get_door_world_inside"):
\t\t\tvar door_inside_target = target_room.get_door_world_inside(_map_grid, false)
\t\t\tvar local_path_in = target_room.get_local_path(door_inside_target, extra_target_pos)
\t\t\tworld_path.append_array(local_path_in)
\t\telse:
\t\t\tworld_path.append(extra_target_pos)'''

if old_walk_logic in content:
    content = content.replace(old_walk_logic, new_walk_logic)
    print("Replaced _execute_walk logic")
else:
    print("FAILED to replace _execute_walk logic")
    # debug
    with open("debug_old_walk.txt", "w", encoding="utf-8") as df:
        df.write(old_walk_logic)


# 3. Add _get_current_room_node helper
helper = '''
# =============================================================================
func _get_current_room_node() -> Node2D:
\tif current_state == State.IN_ROOM or current_state == State.SITTING or current_state == State.SLEEPING:
\t\treturn _target_room
\tif current_state == State.IDLE or current_state == State.IN_POI or current_state == State.EATING or current_state == State.STUDYING_MENU or current_state == State.WAITING_FOR_FOOD or current_state == State.WAITING_IN_LINE or current_state == State.AWAITING_CHECKOUT:
\t\tif not _current_poi_id.is_empty():
\t\t\tif _current_poi_id == "lobby":
\t\t\t\treturn _get_lobby_room()
\t\t\treturn _get_poi_room_node(_current_poi_id)
\treturn null

func _get_open_pois()'''

if "func _get_open_pois()" in content:
    content = content.replace("func _get_open_pois()", helper)
    print("Replaced _get_current_room_node helper")
else:
    print("FAILED to replace _get_current_room_node helper")

with open(filepath, "w", encoding="utf-8") as f:
    f.write(content)
