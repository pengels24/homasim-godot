import os
import re

# 1. Update Changelog
changelog_path = 'changelog/gd-0.1.50.md'
changelog_text = """

### Session Update (Pool Fixes & Live Monitor)
- **Fix (GuestActor):** Beim Betreten eines Smart Rooms (wie dem Pool) wurde `_action_timer` auf 0.0 gesetzt, was sofort den `_process_waiting`-Loop lahmlegte. Gäste blieben dauerhaft im Eingang stehen (Timer auf 0.01 korrigiert).
- **Feature (Pool):** `PoolSmall` nutzt im Live-Monitor nun die Iteration über die Gruppe `guest_actors` anstatt der starren Auswertung von `_room_seats`, um wandernde/schwimmende Gäste korrekt zu erfassen.
- **Feature (Pool):** `get_available_interactions()` in `PoolSmall` überschrieben. `"wander"`-Aktionen werden gefiltert, damit Gäste am Pool entweder liegen oder schwimmen und nicht sinnlos in der Ecke stehen.
- **Feature (Pool):** Der Live-Monitor zeigt bei Gästen im Pool nun die verbleibende Aufenthaltszeit in Ingame-Minuten an (z.B. "Baden (74m)").
"""

if os.path.exists(changelog_path):
    with open(changelog_path, 'a', encoding='utf-8') as f:
        f.write(changelog_text)

# 2. Update Alpha Backlog
backlog_path = 'wiki/alpha_backlog.md'
if os.path.exists(backlog_path):
    with open(backlog_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_items = """- ✅ **GuestActor Smart Room Fix:** `_action_timer` Bug beim Betreten gefixed (verhinderte Interaktions-Claim).
- ✅ **Pool Live Monitor:** Erfasst nun alle Gäste der Gruppe `guest_actors` (nicht nur sitzende) inkl. verbleibender Ingame-Minuten-Anzeige ("Baden (Xm)").
- ✅ **Pool Interaktionen:** `get_available_interactions()` überschrieben, um `"wander"` im Pool zu unterbinden."""
    
    content = content.replace("## 🛠 Ungeplante Fixes & Features (Aktuelle Session)\n- (leer)", f"## 🛠 Ungeplante Fixes & Features (Aktuelle Session)\n{new_items}")
    with open(backlog_path, 'w', encoding='utf-8') as f:
        f.write(content)

# 3. Update pool_small.md
pool_doku_path = 'wiki/rooms/pool_small.md'
if os.path.exists(pool_doku_path):
    try:
        with open(pool_doku_path, 'r', encoding='utf-8') as f:
            pool_content = f.read()
    except UnicodeDecodeError:
        with open(pool_doku_path, 'r', encoding='latin-1') as f:
            pool_content = f.read()
        
    pool_update = """  - Überschreibt `get_available_interactions()`, um `"wander"`-Aktionen zu entfernen. Gäste nutzen ausschließlich Liegen oder das Wasser.
  - Der Live-Monitor (`get_live_details()`) iteriert über die Gruppe `guest_actors` (statt `_room_seats`), um auch nicht-sitzende Gäste (im Wasser) korrekt anzuzeigen.
  - Berechnet und zeigt die verbleibende Aufenthaltszeit in Minuten im Live-Monitor an."""
    
    if "get_available_interactions" not in pool_content:
        pool_content = pool_content.replace("- G", pool_update + "\n  - G")
        with open(pool_doku_path, 'w', encoding='utf-8') as f:
            f.write(pool_content)

print("Doku aktualisiert!")
