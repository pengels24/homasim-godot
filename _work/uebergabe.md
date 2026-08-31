# Übergabeprotokoll (2026-08-31)

## Letzter Stand
Der Hotelbetrieb läuft absolut stabil. Die "Smart Room"-Architektur (wo Räume eigenständig ihre `is_functional()` Logik prüfen) wurde erfolgreich über alle Leisure-Räume (Pool, Spa, Gym, Restaurant, Bar) ausgerollt. 

## Bearbeitete Systeme
- **Room.gd / is_functional():** Prüft nun, ob Personal im Raum steht ODER einen Task für den Raum (`_current_task.target.room`) ausführt.
- **GuestActor.gd:** `stay_dur` für das Gym auf 60-90 Min isoliert.
- **UI & Translations:** `language.csv` wurde streng nach Direktive ergänzt. Live-Monitore (Pool, Spa, Gym, Conference) nutzen nun `GameState.T()`.

## Nächste Schritte
Der User möchte als Nächstes wahrscheinlich mit dem **Konferenzraum** (Conference room) weitermachen oder den nächsten Raum im Tech-Tree freischalten. Die Basis ist dafür nun maximal stabil!
