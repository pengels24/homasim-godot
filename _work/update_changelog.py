import os

changelog_path = 'd:/game-dev/homasim-godot/changelog/gd-0.1.51.md'
with open(changelog_path, 'a', encoding='utf-8') as f:
    f.write('\n## ✨ Features & Verbesserungen (11.09.2026: Pre-Alpha & Inspector Update)\n\n')
    f.write('- **Pre-Alpha Demo Ende:** Nach Erreichen des ersten Sterns wird das `exp_frozen`-Flag aktiviert. Es gibt keine neuen Erfahrungspunkte mehr, stattdessen wird das `ModalContentDemoEnd` (früher TechDemoEnd) mit dem Hinweis auf den Pre-Alpha Status angezeigt.\n')
    f.write('- **Hotelübersicht (WiSim-Metriken):** Neues Modal `ModalContentHotelOverview` hinzugefügt, aufrufbar über F9 oder den HUD-Button. Zeigt aktuelle Sterne, Finanzen, Gästezufriedenheit und Zimmerauslastung an.\n')
    f.write('- **Anonyme Inspektoren:** Der Gourmet-Inspektor spawnt nun komplett getarnt (`is_inspector = true`, `cover_type = "single"`) ohne Benachrichtigung im Activity Log. Er ist äußerlich nicht von einem normalen Gast zu unterscheiden.\n')
    f.write('- **Inspektor-Bericht:** Beim Checkout des Inspektors öffnet sich ein neues Modal (`ModalContentInspectorReport`), das die erreichten Werte den geforderten Werten detailliert gegenüberstellt, bevor es zu einer Sterne-Verleihung (oder Aberkennung) kommt.\n')
    f.write('- **Startup Disclaimer Update:** `dont_show_disclaimer` im `SettingsManager` in `dont_show_prealpha_disclaimer` umbenannt, um die Checkbox zurückzusetzen. Texte und Key (`ui.disclaimer.prealpha.*`) in `language.csv` aktualisiert.\n')
    f.write('\n## 📁 Geänderte Dateien (11.09.2026)\n\n')
    f.write('| `autoload/GameState.gd` | `exp_frozen` Logik für Pre-Alpha Ende. |\n')
    f.write('| `scenes/ingame/GuestManager.gd` | `spawn_inspector` (getarnt), `evaluate_gourmet_stars` sendet `sig_inspector_report_ready` Signal. |\n')
    f.write('| `scenes/ingame/guest/GuestParty.gd` | `is_inspector` und `cover_type` mit Tarnungslogik. |\n')
    f.write('| `scenes/ingame/scripts/managers/IngameUIManager.gd` | Aufruf für Hotelübersicht und Inspektor-Bericht. |\n')
    f.write('| `scenes/ingame/hud/modals/content/ModalContentHotelOverview.tscn / .gd` | NEU: Hotelübersicht. |\n')
    f.write('| `scenes/ingame/hud/modals/content/ModalContentInspectorReport.tscn / .gd` | NEU: Inspektor-Bericht. |\n')
    f.write('| `autoload/InputHandler.gd` / `keybindings.json` | F9 für Hotelübersicht hinzugefügt. |\n')
    f.write('| `translations/language.csv` | Neue Keys für Modale und Pre-Alpha. |\n')
