# Auskommentierte Debug-Prints

- **scenes/ingame/guest/GuestActor.gd** (Line 254):
  - Old: `print("[GuestActor] %s: Timeout erreicht beim Warten auf Essen! Breche ab." % [(_guest_member.name if _guest_member else "?")])`
  - New: `# print("[GuestActor] %s: Timeout erreicht beim Warten auf Essen! Breche ab." % [(_guest_member.name if _guest_member else "?")])`

- **scenes/ingame/guest/GuestActor.gd** (Line 296):
  - Old: `print("[GuestActor] NIGHT RESCUE: %s → walk to room (state=%s)" % [`
  - New: `# print("[GuestActor] NIGHT RESCUE: %s → walk to room (state=%s)" % [`

- **scenes/ingame/guest/GuestActor.gd** (Line 390):
  - Old: `print("[GuestActor] %s: Raum nicht funktional. Warte %s Minuten." % [(_guest_member.name if _guest_member else "?"), POI_WAIT_TIME_MINUTES])`
  - New: `# print("[GuestActor] %s: Raum nicht funktional. Warte %s Minuten." % [(_guest_member.name if _guest_member else "?"), POI_WAIT_TIME_MINUTES])`

- **scenes/ingame/guest/GuestActor.gd** (Line 664):
  - Old: `print("[LOBBY DEBUG] %s started _decide_next_action. state=%s, target_room=%s, open_pois=%s" % [_guest_member.get("name") if _guest_member else "?", get_state_name(current_state), "VALID" if is_instance_valid(_target_room) else "INVALID", str(open_pois)])`
  - New: `# print("[LOBBY DEBUG] %s started _decide_next_action. state=%s, target_room=%s, open_pois=%s" % [_guest_member.get("name") if _guest_member else "?", get_state_name(current_state), "VALID" if is_instance_valid(_target_room) else "INVALID", str(open_pois)])`

- **scenes/ingame/guest/GuestActor.gd** (Line 681):
  - Old: `print("[GuestActor] %s beendet POI-Besuch (%s). Zwangspause bis %s gesetzt." % [(_guest_member.name if _guest_member else "?"), _current_poi_id, _poi_rest_until])`
  - New: `# print("[GuestActor] %s beendet POI-Besuch (%s). Zwangspause bis %s gesetzt." % [(_guest_member.name if _guest_member else "?"), _current_poi_id, _poi_rest_until])`

- **scenes/ingame/guest/GuestActor.gd** (Line 748):
  - Old: `print("[GuestActor] Fallback (No POIs active) -> _wander_in_room(lobby) for %s" % [_guest_member.get("name") if _guest_member else "?"])`
  - New: `# print("[GuestActor] Fallback (No POIs active) -> _wander_in_room(lobby) for %s" % [_guest_member.get("name") if _guest_member else "?"])`

- **scenes/ingame/guest/GuestActor.gd** (Line 751):
  - Old: `print("[GuestActor] Fallback (No POIs active) -> _walk_to_poi(lobby) for %s" % [_guest_member.get("name") if _guest_member else "?"])`
  - New: `# print("[GuestActor] Fallback (No POIs active) -> _walk_to_poi(lobby) for %s" % [_guest_member.get("name") if _guest_member else "?"])`

- **scenes/ingame/guest/GuestActor.gd** (Line 761):
  - Old: `print("[GuestActor] %s -> _walk_to_room(State.IN_ROOM) via open_pois empty (not idle/walking)" % [_guest_member.get("name") if _guest_member else "?"])`
  - New: `# print("[GuestActor] %s -> _walk_to_room(State.IN_ROOM) via open_pois empty (not idle/walking)" % [_guest_member.get("name") if _guest_member else "?"])`

- **scenes/ingame/guest/GuestActor.gd** (Line 766):
  - Old: `print("[GuestActor] %s -> _walk_to_poi(lobby) via open_pois empty (event)" % [_guest_member.get("name") if _guest_member else "?"])`
  - New: `# print("[GuestActor] %s -> _walk_to_poi(lobby) via open_pois empty (event)" % [_guest_member.get("name") if _guest_member else "?"])`

- **scenes/ingame/guest/GuestActor.gd** (Line 781):
  - Old: `print("[GuestActor] Fallback -> _walk_to_room(_target_room=%s) for %s" % [r_name, _guest_member.get("name") if _guest_member else "?"])`
  - New: `# print("[GuestActor] Fallback -> _walk_to_room(_target_room=%s) for %s" % [r_name, _guest_member.get("name") if _guest_member else "?"])`

- **scenes/ingame/guest/GuestActor.gd** (Line 900):
  - Old: `print("[GuestActor] %s -> _wander_in_room(lobby) (Same POI fallback)" % [_guest_member.get("name") if _guest_member else "?"])`
  - New: `# print("[GuestActor] %s -> _wander_in_room(lobby) (Same POI fallback)" % [_guest_member.get("name") if _guest_member else "?"])`

- **scenes/ingame/guest/GuestActor.gd** (Line 903):
  - Old: `print("[GuestActor] %s -> _walk_to_poi(lobby) (Same POI fallback)" % [_guest_member.get("name") if _guest_member else "?"])`
  - New: `# print("[GuestActor] %s -> _walk_to_poi(lobby) (Same POI fallback)" % [_guest_member.get("name") if _guest_member else "?"])`

- **scenes/ingame/guest/GuestActor.gd** (Line 907):
  - Old: `print("[GuestActor] %s -> chosen = room (Same POI fallback)" % [_guest_member.get("name") if _guest_member else "?"])`
  - New: `# print("[GuestActor] %s -> chosen = room (Same POI fallback)" % [_guest_member.get("name") if _guest_member else "?"])`

- **scenes/ingame/guest/GuestActor.gd** (Line 982):
  - Old: `print("[GuestActor] %s changed state: %s -> %s%s" % [g_name, get_state_name(old_state), get_state_name(new_state), poi_info])`
  - New: `# print("[GuestActor] %s changed state: %s -> %s%s" % [g_name, get_state_name(old_state), get_state_name(new_state), poi_info])`

- **scenes/ingame/guest/GuestActor.gd** (Line 1046):
  - Old: `print("[GuestActor] %s betritt STUDYING_MENU. Wartet %s Sekunden..." % [(_guest_member.name if _guest_member else "?"), _action_timer])`
  - New: `# print("[GuestActor] %s betritt STUDYING_MENU. Wartet %s Sekunden..." % [(_guest_member.name if _guest_member else "?"), _action_timer])`

- **scenes/ingame/guest/GuestActor.gd** (Line 1429):
  - Old: `print("[GuestActor] Checkout failed for ", _guest_member.id, ". Path empty from ", start_tile, " to ", exit_tile, ". current_state=", current_state)`
  - New: `# print("[GuestActor] Checkout failed for ", _guest_member.id, ". Path empty from ", start_tile, " to ", exit_tile, ". current_state=", current_state)`

- **scenes/ingame/guest/GuestActor.gd** (Line 1726):
  - Old: `print("[GuestActor] %s kann sich %s nicht leisten. Geht aufs Zimmer." % [(_guest_member.name if _guest_member else "?"), poi_id])`
  - New: `# print("[GuestActor] %s kann sich %s nicht leisten. Geht aufs Zimmer." % [(_guest_member.name if _guest_member else "?"), poi_id])`

- **scenes/ingame/guest/GuestActor.gd** (Line 1737):
  - Old: `print("[GuestActor] %s kann sich Automaten-Snack nicht leisten. Geht aufs Zimmer." % [(_guest_member.name if _guest_member else "?")])`
  - New: `# print("[GuestActor] %s kann sich Automaten-Snack nicht leisten. Geht aufs Zimmer." % [(_guest_member.name if _guest_member else "?")])`

- **scenes/ingame/guest/GuestActor.gd** (Line 2000):
  - Old: `print("[GuestActor] Safety fallback: ", _guest_member.get("name") if _guest_member else "?",`
  - New: `# print("[GuestActor] Safety fallback: ", _guest_member.get("name") if _guest_member else "?",`

- **scenes/ingame/guest/GuestActor.gd** (Line 2123):
  - Old: `print("[GuestActor] %s tween finished. changing to next_state=%s (%d)" % [_guest_member.get("name") if _guest_member else "Unknown", get_state_name(next_state), next_state])`
  - New: `# print("[GuestActor] %s tween finished. changing to next_state=%s (%d)" % [_guest_member.get("name") if _guest_member else "Unknown", get_state_name(next_state), next_state])`

- **scenes/ingame/map/MapGrid.gd** (Line 145):
  - Old: `print("[MapGrid] Path failed: NO PATH FOUND by AStar. start: ", start_tile, " end: ", end_tile)`
  - New: `# print("[MapGrid] Path failed: NO PATH FOUND by AStar. start: ", start_tile, " end: ", end_tile)`

- **scenes/ingame/map/MapGrid.gd** (Line 160):
  - Old: `print("[MapGrid] Path OK: ", lbl, " | ", start_tile, " -> ", end_tile, " len=", path.size())`
  - New: `# print("[MapGrid] Path OK: ", lbl, " | ", start_tile, " -> ", end_tile, " len=", path.size())`