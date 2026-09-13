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
