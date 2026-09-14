# Changelog – gd-0.1.53
**Datum:** 2026-09-13
**Session:** Inspector-Bericht Polishing + ANG-361 Ruhepause-Fix

---

## ✅ Bugfixes

- **ANG-361 (Ruhepause):** Implementiert und verifiziert – Gäste bleiben nachts im Zimmer, verlassen es erst nach 6:00 Uhr
- **Crash-Fix:** `ModalLayer`-Node existierte nicht in HUD.tscn – `ModalStarAchieved` wird nun direkt als `_hud`-Child hinzugefügt (IngameUIManager.gd, beide Stellen `result==up` und `result==down`)
- **Crash-Fix:** `party.get_primary_name()` → `party.get_display_name()` korrigiert (GuestManager.gd:945)
- **Inspector-Titel:** `open()` bricht ab wenn Modal bereits sichtbar (Reception war offen) → `set_title()` wird jetzt zusätzlich direkt aufgerufen (IngameUIManager.gd)

---

## 🎨 UI / Inspector-Bericht (ANG-360 Polishing)

- **Größe:** Modal auf 80% Breite × 75% Höhe skaliert via `custom_minimum_size` in `_ready()`
- **Titel:** "Gourmet-Sterne – Prüfbericht" (vorher: "Inspektor-Bericht") – language.csv + IngameUIManager.gd
- **Float-Formatierung:** `%.1f%%` für avg_sat, avg_clean (max 1 Nachkommastelle)
- **Button:** Blue-Styles (`menu_button_blue.tres` / hover / pressed) auf BtnClose in ModalContentInspectorReport.tscn
- **Signatur:** "Gez. [Inspector-Name]" in kursiv, font_size=26, unten links via SignatureLabel (RichTextLabel)
- **Inspector-Name:** `party.get_display_name()` ins Stats-Dict aufgenommen (`inspector_name`-Key)
- **Ergebnis-Text:** 4 Varianten (up/down/held/none) via `GameState.T()` statt hardcoded ASCII-Strings
- **Ergebnis-Text Logik:** Bei 0 Sternen + result==none → "Anforderungen noch nicht erfüllt" statt "Stern konnte gehalten werden"
- **Grid-Font:** Per Editor auf Labels gesetzt (theme_override_font_sizes propagiert in Godot 4 nicht auf Kinder)

---

## 🌐 Übersetzungen (language.csv)

Neue Keys hinzugefügt:
- `ui.modal.inspector_report.title` → "Gourmet-Sterne – Prüfbericht" / "Gourmet Stars – Inspection Report"
- `event.inspector.result_up` → "Prüfung erfolgreich! ..."
- `event.inspector.result_down` → "Prüfung nicht bestanden! Aufgrund gravierender Mängel..."
- `event.inspector.result_held` → "Prüfung nicht bestanden. Aktueller Stern konnte gehalten werden."
- `event.inspector.result_none` → "Anforderungen noch nicht erfüllt. Weiter so – der erste Stern wartet!"

---

## ⚙️ Config / Balance

- `config/gourmet_stars.json`: Rufpunkte-Anforderungen auf 1-1000 Skala normalisiert (vorher >1000 für höhere Sterne)

---

## 🎫 Neue Issues

- **ANG-362:** HUD Gourmet-Sterne – star-progress_overlay.png auf gefüllte Sterne (★) umstellen (140×24px, Gold #EAB308)

---

## 🏆 Test-Ergebnis

**Erster Gourmet-Stern erfolgreich vergeben!**
Dominik Hinz (Inspektor) bestand die Prüfung: 88% Sat / 81.2% GästeZuf / 83.7% Sauberkeit / 491 Rep / 27 Zimmer

## 🐛 Bar / Restaurant Fixes (Gastro-Flow)

- **ANG-356 (Room-Tooltip Bug):** Ankommende Gäste (Walking) werden nicht mehr als anwesend gezählt. `Rect2.has_point` Logik hinzugefügt.
- **ANG-359 & ANG-360 (Bar Live-Monitor):** Status-Texte (Wartet auf Service, Wird serviert) gefixt.
- **Lobby Bugfix:** Tagungsgäste `(TG)` Tag wird nur noch gesetzt wenn das Event-POI existiert.
- **Scope Bugfix:** Godot 4 `for a in ...` Scope-Fehler in Bar.gd und RestaurantSmall.gd Live-Monitoren behoben.
- **Consumption Type Logic:** Gäste (`GuestActor.gd`) speichern nun ihren `consumption_type` (food oder drink) basierend auf dem Rezept oder ob es ein Solo-Drink war.
- **Trinken vs Essen Fix:** Live-Monitor in Bar und Restaurant unterscheidet nun via `consumption_type` korrekt zwischen `Isst gerade` und `Trinkt gerade`.

## ?? Bugfixes & Gameplay (Lobby Loop Fix)

- **ANG-357 (Lobby Endlos-Loop):** G�ste blieben in der Lobby h�ngen und wechselten unendlich oft die Sitzpl�tze, ohne jemals in ihr Zimmer oder zu einem anderen POI zu gehen. Grund war eine Endlosschleife in _process_waiting, da die Lobby als POI mit Sitzpl�tzen gewertet wurde und _decide_next_action() durch ein eturn nie erreicht wurde. Fix: G�ste in der Lobby d�rfen nach einer Interaktion nun regul�r weiterziehen.
