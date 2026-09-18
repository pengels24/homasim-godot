import os

changelog_path = 'changelog/gd-0.1.59.md'
content = '''
- **[KRITISCH] Parzellen-Bau-Timer Bug (Savegame)**
  - Root-Cause: Timer von Parzellen blieben beim Laden eines Savegames fälschlicherweise bei 720 Minuten hängen. Zudem wurden die Wände nach Bauende nicht korrekt rekonfiguriert, wodurch sie visuell im Weg standen.
  - Fix: Runtime-Check in Parzelle.gd::_process hinzugefügt, der korrupte Timer (>= 720) erkennt und den Status auf gebaut setzt. Zudem wird _configure_walls() nach Abschluss nun zuverlässig aufgerufen.
  - Betrifft: scenes/ingame/map/Parzelle.gd

- **Toast-Translation Bug (Gast wütend abgereist)**
  - Root-Cause: Hardcodierter String im Code für Timeout-Toasts.
  - Fix: Der Toast für wütend abreisende Gäste greift nun auf GameState.T("toast.guest.angry_leave") zu. In der language.csv wurden die Platzhalter von %d auf %s korrigiert.
  - Betrifft: scenes/ingame/GuestManager.gd, 	ranslations/language.csv

## ✨ Features / Verbesserungen

- **Animiertes Bau-Overlay (Parzellen)**
  - Implementierung eines neuen Custom-Shaders (construction_hatch.gdshader), der auf zu bauenden Parzellen ein 50% transparentes, orangefarbenes Schraffurmuster ("Hazard Stripes") projiziert, das sich sanft bewegt. Das Muster lässt einen 10px Rand ringsrum, wie vom Design gefordert.
  - Betrifft: scenes/ingame/map/Parzelle.gd, ssets/shaders/construction_hatch.gdshader
'''

with open(changelog_path, 'a', encoding='utf-8') as f:
    f.write(content)

print("Changelog updated.")
