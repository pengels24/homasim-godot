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
