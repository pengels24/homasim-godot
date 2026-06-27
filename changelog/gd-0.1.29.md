## Version: 0.1.29
**Datum: 2026-06-27**

### Features & Verbesserungen

- **Erklärbär-Popup (Disclaimer)**: Beim Start des Spiels wird nun ein Popup eingeblendet, das den Spieler darüber aufklärt, dass es sich um eine frühe Tech-Demo handelt (Bugs, fehlendes Balancing, Platzhalter etc. zu erwarten). Eine "Nicht mehr anzeigen"-Option speichert die Entscheidung dauerhaft im Profil.
- **TechDemo-Wasserzeichen**: Das Hauptmenü zeigt nun ein rotierendes, halbtransparentes "TECHDEMO"-Wasserzeichen unten rechts an.
- **Vollständige Ingame-Lokalisierung**: Das Übersetzungssystem wurde massiv überarbeitet. Raumnamen, Beschreibungen und Tooltips greifen nun dynamisch auf GameState.T() zu, anstatt beim Laden der Skripte fest übersetzt zu werden. Dadurch wird ein Sprachwechsel im Hauptmenü sofort und überall im Spiel fehlerfrei übernommen.
- **Konsistente Raumnamen**: Das veraltete Feld label in Raum-Definitionen wurde komplett durch 
ame ersetzt, um eine einheitliche Namensgebung im MapGrid, Baumenü und in den Tooltips sicherzustellen.
- **Neue Übersetzungen & UI-Strings**: Fehlende Texte wie "Aktuelle FP" (Forschungsbaum), "nur im Hauptmenü" (Einstellungen) sowie die Personal-Besetzungszustände ("Kein Personal", "Teilbesetzt", "Vollbesetzt") wurden ins Übersetzungssystem (language.csv) aufgenommen.

### Bugfixes

- **Platzhalter-Fehler in CSV**: Falsche Platzhalter (*** und +++) in der Übersetzungsdatei (language.csv) korrigiert. Questbook- und Techtree-Texte zeigen nun korrekte Werte für Forschungspunkte, Geld und Ränge an (statt kryptischer Sonderzeichen).
- **Alte Spielstände & Budget (---)**: Ein Kompatibilitätsfix sorgt dafür, dass alte Spielstände (die vor Einführung des individuellen Budgets erstellt wurden) nun korrekt geladen werden. Gäste ohne definiertes Budget erhalten beim Laden automatisch ein Standardbudget von 20, damit sie Geld ausgeben können und in der Gästeliste nicht mehr --- angezeigt wird.
- **Backslash-Korruption**: Literale Backslashes in GameState.T()-Aufrufen in diversen UI-Skripten, die einen Syntax-Fehler auslösten, wurden behoben.

### Technische Änderungen

- BedStandard.gd & Co.: Alle get_definition()-Funktionen der Räume geben unübersetzte Keys für 
ame und description zurück. Die Übersetzung passiert erst in den UI-Klassen (BuildMenu.gd, GuestActor.gd, CustomTooltip.gd).
- ModalContentTechtree.gd & SettingsModal.gd: Hardcodierte Texte aus den .tscn-Szenen extrahiert und als übersetzbare Strings per Code (_ready) zugewiesen.
- language.csv: Über 10 Zeilen bereinigt (Encoding, Platzhalter, Währungssymbole).
- GuestMember.gd / GuestParty.gd: _from_dict() weist nun beim Fehlen von daily_budget im Savegame den Wert 20 als Fallback zu.