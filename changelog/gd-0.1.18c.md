## Version: 0.1.18c
**Datum: 2026-04-27**

### Features & Verbesserungen

- **ANG-177** – MainMenu visuelles Redesign: Text-Stil statt Gold-Boxen.
  - Alle 6 Grid-Buttons + BtnQuit: StyleBoxFlat entfernt, StyleBoxEmpty als Basis; `font_size=34`, schwarzer Outline (`outline_size=5`) für Lesbarkeit auf wechselndem Hintergrund
  - Hover-Farbe Gold `#EAB308` (aktive Buttons) bzw. Rot `#dc2626` (Beenden); `font_pressed_color` abgedunkelt
  - Disabled-Buttons (`Spiel starten`, `Kontobindung`): `CURSOR_FORBIDDEN`, `font_disabled_color` 28 % grau
  - `size_flags_horizontal=4` (SHRINK_CENTER) für GridContainer + alle Buttons – Hover-Bereich entspricht jetzt der Textbreite, kein unsichtbarer Rand mehr
  - `v_separation` 16 → 28 für mehr Luft zwischen den Button-Reihen
  - `MainMenu.gd`: `_update_manager_state()` setzt `CURSOR_POINTING_HAND` / `CURSOR_FORBIDDEN` dynamisch

- **ANG-152 (Erweiterung)** – SettingsManager: Gesamtlautstärke + Audio-Bus-Verwaltung.
  - `master_volume`-Variable ergänzt; `_apply_audio()` steuert Master-, Music- und Sound-Bus via `AudioServer`
  - `_ensure_bus()` legt fehlende Busse dynamisch an (kein Absturz wenn Projekt ohne Audio-Busse gestartet)
  - `SettingsModal.gd`: Gesamtlautstärke-Slider als erster Eintrag im Audio-Tab
  - `translations/de.csv`: Key `settings.audio.master` = „Gesamtlautstärke"

### Bugfixes

- **LoadScreen-Crash** (`Node not found: "Overlay/Card/VBox/Header/TitleLbl"`): Root-Cause war Godot-Szenen-Cache – `LoadScreen` als `instance=ExtResource` in `Dashboard.tscn` eingebettet verwendete veraltete Node-Struktur aus dem Editor-Cache. Fix: `LoadScreen` aus `Dashboard.tscn` entfernt, Lazy-Instantiation in `Dashboard.gd` (`_open_load_screen()`), identisch zum SettingsModal-Pattern.
- **Dashboard – Gold-Button weißer Text**: `_apply_gold_style()` ergänzt um `font_color = Color(0.08, 0.06, 0)` – dunkler Text auf gelbem Hintergrund, analog zu den anderen Gold-Buttons.
- **Fan-Menü – Lock-Emoji zu präsent**: `_make_fan_btn()` in `IngameHud.gd` entfernt das `🔒`-Label-Overlay; gesperrter Zustand wird nur noch durch `icon_node.modulate = Color(1,1,1,0.35)` signalisiert.
- **Fan-Menü – Leerer Slot zeigte `F5` im Tooltip**: `"key": "F5"` → `"key": ""` im leeren Button-Slot; Tooltip-Formatierung prüft jetzt `if def["key"] != ""` bevor `"· "` gesetzt wird.
- **Ingame – `_load_hotel()` hardcoded Profile-ID**: `SaveManager.get_hotels(1)` → `SaveManager.get_hotels(GameState.active_profile_id)` – lädt Hotels des tatsächlich eingeloggten Profils.

### Offene Backlog-Issues

- **ANG-174** – Dev-Konsole Ingame (Todo)
- **ANG-175** – Save-System: Raum-Persistenz + Save-Slots (getestet, stabil)
- **ANG-178** – Toast-Notification: Mini-Modal bei F5/F9, auto-dismiss (Backlog)
- **ANG-179** – Neues-Hotel-Dialog Redesign: Zweispaltig, Modal-Stil wie SettingsModal (Backlog)
- **ANG-180** – MainMenu Footer: Version + „Made with Godot" (Backlog)
