# Changelog v0.1.48
**Datum:** 2026-07-29

## 🌟 Neue Features
- **ANG-325 & ANG-326 (Gäste-Quests):** Komplett neue Aufgaben-Kategorie "Gäste" integriert.
  - Das System generiert automatisch für jeden der 8 Gasttypen Meilenstein-Aufgaben: 10, 25, 50 und 100 Gäste bedienen.
  - Die Ziele sind logisch über die Quest-Ränge 1 bis 5 verteilt, passend zur Freischaltung der jeweiligen Gasttypen, um Blocker zu vermeiden.
  - Der Aufgaben-Fortschritt zählt automatisch bei jedem regulären Check-out am Empfang mit.
  - Fortschritte werden dauerhaft in der `quests.json`-Struktur des Savegames gesichert.
  - Neue Strings in der `language.csv` inkl. Korrektur der Währungssymbole (€/$) bei Quest-Belohnungen.

## 🐛 Bugfixes & Anpassungen
- **ANG-324 (Abriss-Blockade für Personalräume):** Es wurde ein Fix implementiert, sodass Personalräume nicht abgerissen werden können, wenn dadurch die Maximalkapazität unter die Anzahl der aktuell eingestellten Mitarbeiter fallen würde (Blockade via Toast-Message).
- Fehlende Währungssymbole und Float-Rundungsfehler bei den Forschungspunkt-Belohnungen im Aufgabenbuch behoben.
- Fehlerhafte Tooltips im Techtree korrigiert (doppelte Präfixe "Feature: Feature:" entfernt).
