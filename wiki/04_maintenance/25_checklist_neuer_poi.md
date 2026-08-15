# Checkliste: Neuer Raum (POI) & Neuer Gasttyp

Diese Checkliste dient als Qualitätssicherung, um sicherzustellen, dass neue Points of Interest (POIs) wie Bar, Pool oder Restaurant sowie neue Gasttypen reibungslos mit den zentralen Systemen (Wegfindung, State-Machine, UI) zusammenarbeiten.

---

## 🏗️ 1. Raumerstellung (Level-Design in `.tscn`)

- [ ] **NavBlocker Spacing:** Sind die `NavBlocker`-Rechtecke so gesetzt, dass Flure und Durchgänge **mindestens 4 Pixel** (die `LOCAL_NAV_CELL_SIZE`) breit sind? (Sonst berechnet das AStar-Netz den Durchgang als blockiert und der Raum wird nicht vollständig erschlossen).
- [ ] **Door Node:** Besitzt der Raum einen `Door`-Marker/Sprite, an dem sich Gäste beim Betreten und Verlassen orientieren können?
- [ ] **Möbel-Struktur:** Befinden sich alle Möbelstücke (und deren Blocker) sauber unter dem `Interior`-Node? (Nur so greift die automatische Rotation).
- [ ] **RoomStatusIndicator:** Hat der Raum **keinen** manuell platzierten `RoomStatusIndicator` im Szenenbaum? (Das zentrale System in `Room.gd` übernimmt die Erstellung automatisch).

## 🛠️ 2. Raum-Logik (`.gd` Skript)

- [ ] **Target-Marker auslesen:** Nutzt der Code zum Finden von Arbeits- oder Sitzplätzen (z. B. `get_bartender_stand_pos`) zuerst die tatsächlichen `Marker2D` / `Node2D` (z. B. `%ServicePoint` oder `WaiterArea`)?
- [ ] **Rotationssichere Fallbacks:** Wenn ein Marker fehlt und ein Fallback (z. B. Raummitte oder Theke) berechnet wird: Wird **unbedingt `to_global()`** verwendet anstelle von `global_position + Vector2(...)`? (Letzteres bricht, sobald der Raum im Spiel gedreht wird!).
- [ ] **Status-Handling:** Setzen Aktionen am POI (z. B. Essen, Trinken) die genutzten Plätze korrekt auf `status = "dirty"` und informieren den TaskManager über Aufräum-Jobs?

## 🏃‍♂️ 3. Akteure & Wegfindung (`StaffActor.gd` / `GuestActor.gd`)

- [ ] **Keine Luftlinien-Bypasses:** Ruft das Verhalten des Akteurs (z. B. Barkeeper geht zur Arbeit) zwingend `_current_room.get_local_path()` auf? **Niemals** direkt `_path = [target_pos]` setzen, da dies die NavBlocker ignoriert!
- [ ] **State-Machine Updates:** Wenn der POI eigene Aktionen erfordert (z. B. `State.DRINKING_AT_BAR`):
  - Wurde der neue State in den `enum State` aufgenommen?
  - Wird der State im `match _state:` Block (sowohl `_process_walking` als auch `_process_working`) behandelt?
  - Wird der Gast beim Betreten des States auf dem Ziel-Stuhl positioniert (Snap) und **sichtbar** gelassen? (Verstecken/Fade wird nur für Räume wie "Schlafen" verwendet, bei denen der Avatar optisch verschwindet).

## 🧠 4. UI, Codex & Techtree

- [ ] **UI-Texte:** Sind alle neuen Status-Texte (z. B. "Trinkt an der Bar") sauber in der `language.csv` hinterlegt und werden über `GameState.T(...)` geladen?
- [ ] **Techtree Freischaltung:** Wurde der Raum in den `techtree.json` (Phase & Node) eingetragen und (falls er fertig ist) das `"demo_locked": true` Flag entfernt?
- [ ] **Codex:** Ist der neue Gast oder Raum in den `tutorials.json` als POI hinterlegt, damit der Codex ihn automatisch generieren und erklären kann?

---
*Zuletzt generiert nach Analyse der Restaurant- und Bar-Systematik.*
