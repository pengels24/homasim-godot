import re

with open(r'd:\game-dev\homasim-godot\scenes\ingame\staff\StaffActor.gd', 'r', encoding='utf-8') as f:
    content = f.read()

old_code = """		elif _world_path.size() == 1:
			# Das ist der ALLERLETZTE Punkt auf dem Pfad!
			# Wir haben ihn quasi fast erreicht (dist < 5.0).
			# Damit wir nicht vorzeitig aufhören und ihn wegwerfen, tun wir HIER noch nichts,
			# SONDERN lassen den unteren Code-Block (Snap) greifen!
			pass
		else:
			if _room_entry_pos != Vector2.INF:
				_target_world_pos = _room_entry_pos
				_room_entry_pos = Vector2.INF
			elif _extra_target_pos != Vector2.INF:
				_target_world_pos = _extra_target_pos
				_extra_target_pos = Vector2.INF"""

new_code = """		elif _world_path.size() == 1:
			# Das ist der ALLERLETZTE Punkt auf dem Pfad!
			# Wenn wir ihn wirklich (fast) berühren (dist < 1.0) poppen wir ihn!
			# Dann greift der Snap Block unten!
			if dist_to_target < 1.0:
				_world_path.pop_front()
		else:
			if _room_entry_pos != Vector2.INF:
				_target_world_pos = _room_entry_pos
				_room_entry_pos = Vector2.INF
			elif _extra_target_pos != Vector2.INF:
				_target_world_pos = _extra_target_pos
				_extra_target_pos = Vector2.INF"""

content = content.replace(old_code, new_code)

with open(r'd:\game-dev\homasim-godot\scenes\ingame\staff\StaffActor.gd', 'w', encoding='utf-8') as f:
    f.write(content)
print("Replaced successfully!")
