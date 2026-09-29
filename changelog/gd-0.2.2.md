# HO·MA·SIM - Changelog v0.2.2

## Bugfixes & Polishing (Tutorial)
- **Kamera-Bewegung (Step 2):** Fortschritt misst nun exakt 5 Sekunden *reale* Kamerabewegung (via Maus oder WASD). Unabhängig von Klicks.
- **Kamera-Zoom (Step 3):** Spieler muss nun komplett hinein- und herauszoomen (Grenzen `0.5` und `4.0` erreicht).
- **Rezeption öffnen (Step 15):** Bug gefixt, bei dem das Öffnen per Hotkey (F1) nicht erkannt wurde. Die Überprüfung läuft nun sicher über `_process`, sodass der Schritt sofort weitergeht, sobald das Fenster offen ist.
- **Personalraum Bau-Tutorial (Step 21):**
  - Blaupause (Blueprint) um 4 Tiles nach links, 1 nach oben verschoben und um 180 Grad gedreht.
  - Tür der Blaupause (`door_offset`) wird nun spezifisch angepasst (`offset = 1`), sodass sie direkt Richtung Lobby zeigt.
  - Ghost-Validierung (`BuildCursor.gd`) wurde für Step 21 verschärft: Erlaubt das Bauen (grüner Ghost) nur noch, wenn auch Tür-Offset und Tür-Rotation zu 100% stimmen.
  - Assistenten-Dialog wird nun nach rechts geschoben (`_slide_assistant`), um das Baumenü nicht zu verdecken.
  - Text angepasst: Kategorie "Management" statt "Dienstleistung" (`language.csv`).
- **Texte & UI:**
  - Dialogfenster (`TutorialAssistant`) etwas nach rechts verschoben (ca. 70px), um Schließen-Buttons nicht zu überlagern.
  - Tutorial-Texte ergänzt (Tipp zum Vorspulen der Zeit in Step 10).
  - Der grüne Tür-Indikator ist nun am Ghost-Cursor zu 50% transparent und bleibt als dauerhaftes Komfort-Feature (auch außerhalb des Tutorials) bestehen.

## Bugfixes & Polishing (UI & Controls)
- **Settings / Display:**
  - Standard-Monitor Erkennung auf den Hauptbildschirm (ID 0) korrigiert, falls `-1` als Fallback genutzt wird.
  - Exklusiven Vollbildmodus (Exclusive Fullscreen) und Maus-Einsperren (`MOUSE_MODE_CONFINED`) implementiert, damit man nicht aus Versehen auf den zweiten Monitor klickt.
- **Kamera & Steuerung:**
  - Kamera-Zentrierung beim Schließen des Baumenüs gefixt: Zentriert sich nun nur noch, wenn man explizit den "Parzelle kaufen"-Tab beendet. Beim normalen Bauen oder Abreißen bleibt die Kamera dort, wo sie ist.
  - `InputMode.ROOM_SELECTED` hinzugefügt: Wenn man nun ein Zimmer anklickt, blockiert das Spiel nicht länger die WASD- und Zoom-Tasten.
- **Kontextmenü (Zimmer):**
  - Folgt ab sofort dynamisch dem Zimmer, wenn man die Karte (Kamera) mit WASD verschiebt.
  - Löst sich vom Zimmer und bleibt fix am Bildschirm stehen, sobald man es oben an der Leiste manuell wegschiebt.
  - **Service / Maintenance Buttons:** Sind nun `disabled`, solange das Staff-Feature (Hotellevel < 2) nicht freigeschaltet ist. Es erscheint per Tooltip ein erklärender Text (statt eines Toasts). 
  - Die deaktivierten (grauen) Buttons haben nun im Theme das korrekte "Darkblue" Styling zugewiesen bekommen.
- **Texte & Übersetzungen:**
  - Hardcoded Texte für "Kein Personal" und "Unterbesetzt" auf dem Zimmer-Hover (`RoomStatusIndicator.gd`) entfernt und in `language.csv` aufgenommen.
  - "Abbrechen"-Button beim Personal-Zuweisen nutzt nun ordnungsgemäß `GameState.T("btn.cancel")`.
  - Fehlerhaft formatierter String in der CSV (`ui.tutorial.forschung.intro`) durch korrekte Quotes gerettet.
  - Wording im Main Menü Footer bereinigt ("Made with Godot").
- **Tech-Overlay (F3 / Settings):**
  - In Release-Builds (Tester) zeigt das Overlay nun ausschließlich die FPS an, anstatt "0.0 MB" RAM. Das Panel passt sich in der Höhe dynamisch an (shrinks to fit).
