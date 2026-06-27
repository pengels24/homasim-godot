## Version: 0.1.29
**Datum: 2026-06-27**

### Features & Verbesserungen

- **Erklärbär-Popup (Disclaimer)**: Beim Start des Spiels wird nun ein Popup eingeblendet, das den Spieler darüber aufklärt, dass es sich um eine frühe Tech-Demo handelt (Bugs, fehlendes Balancing, Platzhalter etc. zu erwarten). Eine "Nicht mehr anzeigen"-Option speichert die Entscheidung dauerhaft im Profil.
- **TechDemo-Wasserzeichen**: Das Hauptmenü zeigt nun ein rotierendes, halbtransparentes "TECHDEMO"-Wasserzeichen unten rechts an.
- **Vollständige Ingame-Lokalisierung**: Das Übersetzungssystem wurde massiv überarbeitet. Raumnamen, Beschreibungen und Tooltips greifen nun dynamisch auf GameState.T() zu, anstatt beim Laden der Skripte fest übersetzt zu werden. Dadurch wird ein Sprachwechsel im Hauptmenü sofort und überall im Spiel fehlerfrei übernommen.
- **Konsistente Raumnamen**: Das veraltete Feld label in Raum-Definitionen wurde komplett durch name ersetzt, um eine einheitliche Namensgebung im MapGrid, Baumenü und in den Tooltips sicherzustellen.
- **Neue Übersetzungen & UI-Strings**: Fehlende Texte wie "Aktuelle FP" (Forschungsbaum), "nur im Hauptmenü" (Einstellungen) sowie die Personal-Besetzungszustände ("Kein Personal", "Teilbesetzt", "Vollbesetzt") wurden ins Übersetzungssystem (language.csv) aufgenommen.
- **Filmreifes Start-Intro**: Eine neue Stop-Motion-Sequenz ("Zeitraffer") wurde für den Spielstart implementiert. Das Intro blendet weich durch 22 handgemachte Aufbau-Phasen des Hotels, während das Ingame-HUD (Menüleisten und "Spiel pausiert"-Banner) dynamisch ausgeblendet wird.
- **Cinematic Camera**: Nach Abschluss des Hotel-Aufbaus im Intro fährt die Kamera mit einem sanften Zoom näher an das Geschehen heran, bevor über einen Schwarz-Fade das HOMASIM-Logo präsentiert wird und der nahtlose Übergang ins Hauptmenü erfolgt.

### Bugfixes

- **Start-Zimmer Requirements**: Ein Fehler in den Forschungs-Abhängigkeiten der Startzimmer wurde behoben. Das Einzelzimmer (EZ) und das Doppelzimmer (DZ) sind nun wieder korrekterweise von Spielbeginn an verfügbar (`req_level: 0`, `req_tech: ""`) und benötigen keine vorherige Forschung mehr.
- **Platzhalter-Fehler in CSV**: Falsche Platzhalter (*** und +++) in der Übersetzungsdatei (language.csv) korrigiert. Questbook- und Techtree-Texte zeigen nun korrekte Werte für Forschungspunkte, Geld und Ränge an (statt kryptischer Sonderzeichen).
- **Alte Spielstände & Budget (---)**: Ein Kompatibilitätsfix sorgt dafür, dass alte Spielstände (die vor Einführung des individuellen Budgets erstellt wurden) nun korrekt geladen werden. Gäste ohne definiertes Budget erhalten beim Laden automatisch ein Standardbudget von 20, damit sie Geld ausgeben können und in der Gästeliste nicht mehr --- angezeigt wird.
- **Backslash-Korruption**: Literale Backslashes in GameState.T()-Aufrufen in diversen UI-Skripten, die einen Syntax-Fehler auslösten, wurden behoben.

### Technische Änderungen

- BedStandard.gd & Co.: Alle get_definition()-Funktionen der Räume geben unübersetzte Keys für name und description zurück. Die Übersetzung passiert erst in den UI-Klassen (BuildMenu.gd, GuestActor.gd, CustomTooltip.gd).
- ModalContentTechtree.gd & SettingsModal.gd: Hardcodierte Texte aus den .tscn-Szenen extrahiert und als übersetzbare Strings per Code (_ready) zugewiesen.
- language.csv: Über 10 Zeilen bereinigt (Encoding, Platzhalter, Währungssymbole).
- GuestMember.gd / GuestParty.gd: _from_dict() weist nun beim Fehlen von daily_budget im Savegame den Wert 20 als Fallback zu.
- `Intro.tscn` und `Intro.gd`: Komplett auf die neue bildbasierte 22-Frame Sequenz (`seq_01.png` bis `seq_22.png`) umgestellt. Dynamisches UI-Cropping über `region_rect` in `Sprite2D` implementiert, um Roh-Screenshots aus dem Spiel direkt als Intro-Material ohne sichtbares HUD verwenden zu können.