# Changelog v0.1.31gd
Datum: 2026-06-28

## Features & Verbesserungen
- **Neues Interaktives Handbuch**: Das Tutorial-System wurde massiv überarbeitet! Es gibt nun ein dreiteiliges Tab-Layout für Tutorials, Tipps und den Codex. So hast du alle wichtigen Infos zur Hotel-Leitung auf einen Blick.
- **Smarte Gameplay-Tipps**: Das Spiel denkt jetzt mit und gibt dir an strategisch sinnvollen Punkten Hinweise:
  - **EXP-Cap Warnung**: Erreichst du in der Pause das Bau-EXP-Limit von 130 Punkten, erinnert dich das Spiel freundlich daran, den Hotelbetrieb zu starten, um weiter zu leveln.
  - **Schnellvorlauf**: Verstreicht die morgendliche Zeit (bis 06:15 Uhr) ungenutzt im Schneckentempo, ploppt der Tipp auf, dass man mit der "Vorlauf"-Taste auch mal Gas geben kann.
- **Tipps in den Settings**: Alle Gameplay-Tipps lassen sich auf Wunsch im Gameplay-Tab der Einstellungen abschalten.
- **Game-Balancing (Gäste)**: Der Check-in wurde entzerrt. Gäste treffen jetzt verlässlicher in drei großen Schwüngen am Tag ein (08:00, 12:00 und 16:00 Uhr).
- **UI-Polishing an der Rezeption**: Die leere Liste der abreisenden Gäste ("Keine abreisenden Gäste") sitzt nun endlich perfekt zentriert in ihrer Spalte.

## Bugfixes
- **Doppelter Pause-Klick**: Ein nerviger Fehler, bei dem die Leertaste zum Pausieren oft direkt wieder "Play" drückte (weil der Button noch markiert war), wurde durch das Entfernen des Fokus-Status (ocus_mode = 0) der Zeitsteuerungs-Buttons behoben.
- **Unscharfe Mini-Bilder**: Die Profil- und Raumbilder (Picture-in-Picture) in der Rezeption wurden durch die Umstellung des Texturfilters auf Nearest wieder auf "pixel-perfect" getrimmt.
- **Abgeschnittene Texte**: Längere Einträge im neuen Codex-Menü scrollen nun ordentlich, anstatt unsichtbar über den Rand hinauszuschießen.
- **Alte Dateileichen**: Das nicht mehr benötigte SettingsModal aus den Shared-Szenen wurde komplett entfernt und die letzten Reste in das neue ModalContentSettings migriert.
- **Encoding-Fehler behoben**: Ein versteckter Unicode-Fehler (verursacht durch deutsche Umlaute in einer Datei), der im Hintergrund zu "Byte 67" Parse Errors in Godot führte, wurde sauber auf UTF-8 umgestellt und eliminiert.

## Technische Änderungen
- **Code-Aufräumarbeiten**: Die alte SettingsModal-Szene (.tscn & .gd) wurde gelöscht. Das Spiel verlässt sich jetzt vollständig auf das neue ModalContentSettings-System innerhalb des StandardModal.
- Das Aufgabenbuch castet nun Float-Werte zu sauberen Integern, um Kommazahlen beim Quest-Fortschritt (z.B. "5.0") zu vermeiden.
