# Changelog v0.1.30gd
Datum: 2026-06-29

## Features & Verbesserungen
- **Bollywood-Blockbuster Intro**: Das Stop-Motion-Intro hat ein riesiges Upgrade erhalten! Es ist jetzt eine echte "Kino-Fassung":
  - Es startet mit einem stylischen Fade-in des Angelus2010-Avatars inklusive "presents"-Schriftzug auf schwarzem Grund.
  - Ein komplett schwarzer Blur-Fade in der Mitte trennt den Aufbau elegant vom HOMASIM-Logo, das episch aus dem Nichts auftaucht.
  - Das Intro wird nun stimmungsvoll vom Credits-Song begleitet, der samtweich ein- und ausfadet.
  - Die Kamera fährt am Ende noch weiter nach hinten, um das fertige Hotel in seiner vollen Pracht majestätisch in Szene zu setzen.
- **Kino-Atmosphäre (Cinematic Bars)**: Tiefe, schwarze Balken am oberen und unteren Bildschirmrand überdecken im Intro komplett das UI. Das sorgt nicht nur für echtes Widescreen-Feeling, sondern hält auch den Bugmelder stilvoll unter Verschluss!
- **Knackscharfe Auflösung**: Die Bilder des Intros werden nicht mehr künstlich vergrößert, sondern sitzen als 1920x1080-Texturen pixelgenau und zentriert in der Mitte, was fiese Verzerrungen beim finalen Kamera-Zoom verhindert.
- **Vorbereitung TechDemo**: Umfangreiche Code-Aufräumaktion, um eine fehlerfreie TechDemo abliefern zu können.
## Bugfixes
- **Parse Error im Skript**: Ein kleiner Schönheitsfehler (Einrückung) im neuen Intro-Ablauf wurde behoben, sodass die Szene wieder fehlerfrei startet.
- **Invalid UIDs beim Start behoben**: Ungültige Dummy-UIDs in verschiedenen UI- und Hauptszenen (Intro, Dashboard, ManagerSelect) entfernt. Godot generiert diese nun wieder fehlerfrei neu, sodass der "Invalid UID" Spam beim Start der Engine Geschichte ist.
## Technische Änderungen
- **Intro-Logik komplett umstrukturiert**: Die Intro-Szene verwendet nun `TextureRect` anstatt `Sprite2D`, um bei allen Fenstergrößen eine absolut fehlerfreie Zentrierung und Skalierung der 1080p-Screenshots zu garantieren.
- Dynamische Tween-Sequenzen für parallele Fade-Ins, Text-Bewegungen und Audio-Fades hinzugefügt.
- Veraltete Test-Skripte (`test_save.gd` etc.) und temporäre Ordner (`_temp`) restlos entfernt.
- Veralteten Debug-Code (z.B. EXP-Logs) und riesige alte Kommentar-Blöcke bereinigt.
- Fehlerhafte Laufzeitwarnungen bei fehlschlagenden Wegfindungen und fehlenden Sounds stummgeschaltet, um die Entwicklerkonsole während der TechDemo sauber zu halten.
