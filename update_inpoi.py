import os

filepath = r"d:\game-dev\homasim-godot\scenes\ingame\guest\GuestActor.gd"
with open(filepath, "r", encoding="utf-8") as f:
    content = f.read()

old_logic = '''\t\telif current_state == State.IN_POI and (_current_poi_id == "pool_small" or _current_poi_id == "gym_small" or _current_poi_id == "spa_small"):
\t\t\t# Gast bleibt im Wellnessbereich, wechselt aber den Platz (Liege <-> Wasser <-> Fahrrad)
\t\t\tvar room_node = _get_poi_room_node(_current_poi_id)
\t\t\tif is_instance_valid(room_node) and room_node.has_method("claim_seat"):
\t\t\t\tif room_node.has_method("leave_seat"):
\t\t\t\t\troom_node.leave_seat(_guest_member.id)
\t\t\t\tvar new_pos = room_node.claim_seat(_guest_member.id)
\t\t\t\tif new_pos != Vector2.ZERO and new_pos != Vector2.INF:
\t\t\t\t\t_execute_poi_move(new_pos, room_node)
\t\t\t\t\t\t
\t\t\t\t\t_action_timer = randf_range(15.0, 30.0) * TimeManager.SECONDS_PER_GAME_MINUTE # Nächster Wechsel in 15-30 Ingame-Minuten
\t\t\t\t\treturn
\t\t\t
\t\t\t# Wenn kein Platz frei ist, um zu wechseln -> wir gehen vorzeitig.
\t\t\tif is_instance_valid(room_node) and room_node.has_method("leave_seat"):
\t\t\t\troom_node.leave_seat(_guest_member.id)
\t\t\t_decide_next_action()
\t\telif current_state == State.IN_POI and _current_poi_id == "conference_small":
\t\t\tvar room_node = _get_poi_room_node(_current_poi_id)
\t\t\tif is_instance_valid(room_node):
\t\t\t\tvar was_speaker = (room_node.get("current_speaker_id") == _guest_member.id)
\t\t\t\tif was_speaker:
\t\t\t\t\tif room_node.has_method("leave_podium"):
\t\t\t\t\t\troom_node.leave_podium(_guest_member.id)
\t\t\t\t\tvar new_pos = room_node.claim_seat(_guest_member.id)
\t\t\t\t\tif new_pos != Vector2.INF and new_pos != Vector2.ZERO:
\t\t\t\t\t\t_execute_poi_move(new_pos, room_node)
\t\t\t\t\t\t# Pause nach dem Reden, damit man nicht sofort wieder ans Pult rennt
\t\t\t\t\t\t_action_timer = randf_range(10.0, 15.0) * TimeManager.SECONDS_PER_GAME_MINUTE
\t\t\t\t\telse:
\t\t\t\t\t\t_decide_next_action()
\t\t\t\t\treturn
\t\t\t\telse:
\t\t\t\t\treturn
\t\telse:
\t\t\tif current_state == State.IN_POI:
\t\t\t\tvar room_node = _get_poi_room_node(_current_poi_id)
\t\t\t\tif is_instance_valid(room_node) and room_node.has_method("leave_seat"):
\t\t\t\t\troom_node.leave_seat(_guest_member.id)
\t\t\t_decide_next_action()'''

new_logic = '''\t\telif current_state == State.IN_POI:
\t\t\tvar room_node = _get_poi_room_node(_current_poi_id)
\t\t\tif is_instance_valid(room_node):
\t\t\t\t# SMART ROOM: Gibt es verfügbare Interaktionen?
\t\t\t\tvar interactions = room_node.get_available_interactions(self)
\t\t\t\tif interactions.size() > 0:
\t\t\t\t\tvar choice = interactions.pick_random()
\t\t\t\t\troom_node.release_interaction(_guest_member.id) # Alten Platz freigeben
\t\t\t\t\tvar claim_result = room_node.claim_interaction(_guest_member.id, choice.get("id", ""))
\t\t\t\t\tif claim_result.has("target_pos"):
\t\t\t\t\t\t_execute_poi_move(claim_result.target_pos, room_node)
\t\t\t\t\t\tvar dur = claim_result.get("duration", randf_range(15.0, 30.0))
\t\t\t\t\t\t_action_timer = dur * TimeManager.SECONDS_PER_GAME_MINUTE
\t\t\t\t\t\treturn
\t\t\t\t
\t\t\t\t# Wenn keine Interaktionen verfügbar sind oder der Raum kein Smart Room ist (Fallback):
\t\t\t\troom_node.release_interaction(_guest_member.id)
\t\t\t\t# Fallback für alte Räume
\t\t\t\tif room_node.has_method("leave_seat"):
\t\t\t\t\troom_node.leave_seat(_guest_member.id)
\t\t\t
\t\t\t_decide_next_action()
\t\telse:
\t\t\t_decide_next_action()'''

if old_logic in content:
    content = content.replace(old_logic, new_logic)
    print("Successfully replaced IN_POI logic")
else:
    print("FAILED to replace IN_POI logic")

with open(filepath, "w", encoding="utf-8") as f:
    f.write(content)

