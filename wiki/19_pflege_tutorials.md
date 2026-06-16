# 🎓 Wie pflege ich das Tutorial?

Das Tutorial-System in Homasim basiert auf einfachen JSON-Einträgen, CSV-Übersetzungen und Bildern.

## 1. Neuen Tutorial-Eintrag anlegen
Öffne die Datei `config/tutorials.json`. Füge einen neuen Block ins `tutorials`-Array ein:
```json
{
  "id": "mein_neues_tutorial",
  "title_key": "tutorial.mein_neues_tutorial.title",
  "desc_key": "tutorial.mein_neues_tutorial.desc",
  "image": "res://assets/images/tutorials/tutorial_mein_neues_tutorial.png"
}
```

## 2. Bild bereitstellen
Lege das zugehörige Bild unter folgendem Pfad ab:
`assets/images/tutorials/tutorial_mein_neues_tutorial.png`
*Empfohlene Auflösung: 1280x720 (16:9) oder 800x400 (2:1), damit es im Popup sauber skaliert wird ohne zu verzerren.*

## 3. Texte übersetzen
Öffne `translations/de.csv` und ergänze am Ende die beiden Keys:
```csv
"tutorial.mein_neues_tutorial.title","Titel des Tutorials",""
"tutorial.mein_neues_tutorial.desc","Langer Erklärungstext, der im Popup angezeigt wird.",""
```

## 4. Tutorial im Code triggern
Immer wenn der Spieler eine Aktion macht, für die das Tutorial relevant ist, rufst du im Code einfach auf:
```gdscript
if TutorialManager:
	TutorialManager.trigger("mein_neues_tutorial")
```
*Der Manager merkt sich automatisch, ob der Spieler das Tutorial schon gesehen hat und zeigt es nur beim ersten Mal!*
