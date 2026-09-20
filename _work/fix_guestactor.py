import sys

with open('scenes/ingame/guest/GuestActor.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix 1: Wachwerd-Phase
old_wach = """	if current_time >= 1380 or current_time < 360: # 1380 = 23:00, 360 = 06:00
		# Nachtruhe! Ab ins Zimmer und schlafen.
		open_pois.clear()
		if current_state == State.SLEEPING:
			_action_timer = randf_range(30.0, 60.0)
			return # Einfach weiterschlafen
		elif current_state == State.IN_ROOM or current_state == State.SITTING:
			if is_instance_valid(_target_room):
				_wander_in_room(_target_room, true) # true = force sleep
			return
		else:
			# Gast ist draußen: zurück ins Zimmer schicken
			send_back_to_room()
			return"""

new_wach = """	if current_time >= 1380 or current_time < 360: # 1380 = 23:00, 360 = 06:00
		# Nachtruhe! Ab ins Zimmer und schlafen.
		open_pois.clear()
		if current_state == State.SLEEPING:
			_action_timer = randf_range(30.0, 60.0)
			return # Einfach weiterschlafen
		elif current_state == State.IN_ROOM or current_state == State.SITTING:
			if is_instance_valid(_target_room):
				_wander_in_room(_target_room, true) # true = force sleep
			return
		else:
			# Gast ist draußen: zurück ins Zimmer schicken
			send_back_to_room()
			return
			
	# 2.5 Wachwerd-Phase (06:00 - 06:15)
	# Gäste bleiben auf ihren Zimmern und warten, bis das Restaurant öffnet.
	if current_time >= 360 and current_time < 375:
		if _current_poi_id.begins_with("bed_") or current_state == State.IN_ROOM or current_state == State.SLEEPING or current_state == State.SITTING:
			_action_timer = 5.0 # Checke regelmäßig ob 06:15 erreicht ist
			return # Nicht auf die Suche nach POIs gehen (würde bei Hunger zum Verlassen führen!)
		else:
			if is_instance_valid(_target_room):
				send_back_to_room()
			return"""

if old_wach in content:
    content = content.replace(old_wach, new_wach)
else:
    print("WARNING: Could not find old_wach block!")

# Fix 2: Hunger threshold
old_hunger = """			var def = _get_poi_def(poi_id)
			if not def.get("can_serve_solo", false) and (member.saturation > 50 or member.thirst > 50):
				return false"""

new_hunger = """			var def = _get_poi_def(poi_id)
			if not def.get("can_serve_solo", false) and (member.saturation > 80 or member.thirst > 80):
				return false"""
				
if old_hunger in content:
    content = content.replace(old_hunger, new_hunger)
else:
    print("WARNING: Could not find old_hunger block!")

with open('scenes/ingame/guest/GuestActor.gd', 'w', encoding='utf-8') as f:
    f.write(content)
print('Applied python fixes.')
