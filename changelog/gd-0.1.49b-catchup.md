# Changelog – gd-0.1.49b (Catch-up 03.09. – 08.09.2026)

> Branch: `dev` | Umfang: Konferenz-Flow, Gastro-Bugfixes, Wellness-Overhaul, Smart-Room-Unification Architektur

---

## 🐛 Bugfixes

- **Gastro-Flow-Totalausfall (07.09.2026):** `return`-Statements am Ende der `EATING`- und `STUDYING_MENU`-Branches in `_process_waiting()` fehlten. Ausführung fiel auf `_decide_next_action()` durch. Fix: `return` eingebaut, Restaurant, Bar und Post-Essen-Walk funktionieren wieder.
- **Snackautomat repariert (07.09.2026):** `_current_poi_id` Überschreibung in der Lobby behoben, direkter Tween mit `lobby.get_local_path()` für Weg zum Essplatz implementiert.
- **HUD Gästezähler (07.09.2026):** `parties_changed.emit()` in `spawn_conference_guests()` eingebaut, damit TG-Gäste sofort gezählt werden.
- **Check-in POI-Sperre:** Nach Check-in bleiben Gäste im Zimmer (60 Ingame-Min). Fix: in `start_checkin()` statt `setup()` gesetzt.
- **QuestManager Fixes:** `QuestManager.on_poi_used` Trigger in `GuestActor` eingebaut. Logikfehler beim Abgleich generischer Quests (leere `target_id`) korrigiert.
- **Konferenzraum Quest:** Veralteten Forschungs-Node `B1.1` durch `P1.2` ersetzt.
- **Room Key Fixes:** Restliche `instance_id`-Überbleibsel durch sicheren `GuestManager._room_key` ersetzt.

---

## ✨ Features & Verbesserungen

### Conference Flow Overhaul (03.09. – 04.09.2026)
- **Speaker-Swap:** Atomarer Wechsel implementiert (kein release/claim Umweg mehr).
- **Flow & Pathing:** Wander-Vorpuffer 07:45–08:00 implementiert. Raum öffnet um 07:45. Blickrichtung zum Speakertable für alle Stühle.
- **Mittagspause:** `go_conference_break()` / `return_from_conference_break()` implementiert (Rückkehr 13:45). TG-Gäste besuchen in der Pause Bar/Restaurant. End of Day: 50% direkt nach Hause, 50% bleiben noch.
- **Infinite EXP-Loop Fix:** `ConferenceSmall.get_available_interactions` gibt jetzt eigenen Sitz zurück. Fallthrough-Guard in `_process_waiting` eingebaut.
- **Live-Monitor / Tooltip:** "Wartet"-Anzeige statt "...". Zählt WALKING-State korrekt für Raum-Tooltip.

### Wellness-System Overhaul (08.09.2026)
- **Cooldowns & Timer:** Session-Timer-Reset bei Spot-Wechsel behoben. Doppelbelegung von Sitzen gefixt (`_process()`-Hack entfernt). Sofort-Wechsel nach Ankunft behoben.
- **Spa & Pool:** Spa Bed-Lookup-Fix (`gm.id`). Wellness POI-Präferenzen (70/30). Spot-Wechsel Alternation (sit<->sleep) mit 5-12 Min Timer.
- **Live-Monitor:** Zeigt jetzt "Badet/Entspannt" (Pool), "Liegt/Entspannt" (Spa). Sortierung nach Restzeit.

### Smart-Room-Unification Architektur (07.09.2026)
- **Room.gd:** Neue Basis-Methoden `is_gastro()` und `can_serve_solo()`.
- **GastroManager.gd:** Neue zentrale Methode `try_gastro_order()` für alle Gastro-Räume.
- **GuestActor.gd:** `_poi_stay_timer`, `is_smart_room`, `is_bar_gastro_loop` und 21+ hardcodierte Raum-ID Checks vollständig entfernt. Neue Gastro-Räume benötigen keine Actor-Code-Änderungen mehr.

### Weitere Verbesserungen
- **Pool Live Monitor:** Erfasst nun alle Gäste der Gruppe `guest_actors` inkl. verbleibender Ingame-Minuten.
- **Pool Interaktionen:** `wander` im Pool unterbunden.
- **GuestActor Pathfinding (Checkout):** Ghost-Walking durch Wände bei Abreise verhindert.

---

## 🏆 Test-Ergebnis (08.09.2026)
- Bar-Flow, Restaurant-Flow, Küche, Zimmer (DZ), Personalraum – alle grün.
