# Balancing: Die Levelkurve

Die Levelkurve bestimmt das Pacing des Spiels und regelt, wann der Spieler neue Mechaniken (Personal, Forschung, neue Zimmer) freischaltet.

## Mechanik der Erfahrungspunkte (EXP)
Erfahrungspunkte werden im Spiel auf zwei Arten generiert:
1. **Einmalig beim ersten Bau:** Jedes Mal, wenn der Spieler einen Raumtyp zum *allersten* Mal baut, erhält er den im Raum definierten `exp_reward` (z.B. 50 EXP beim ersten Standardzimmer).
2. **Laufend durch Gäste-Checkouts:** Das ist die primäre EXP-Quelle. Die Formel lautet: `base_exp * Übernachtungen * Zufriedenheits-Modifikator`. 
   - *Beispiel:* Ein Standard-Gast bringt ca. 10 EXP pro Nacht bei 100% Zufriedenheit.

## Benötigte EXP pro Level
Die benötigten EXP steigen exponentiell an.
- **Level 2:** 150 EXP
- **Level 3:** 225 EXP (kumuliert 375 EXP)
- **Level 4:** 337 EXP (kumuliert 712 EXP)
- **Level 5:** 506 EXP (kumuliert 1.218 EXP)

## Pacing & Auswirkung auf das Gameplay
Durch die Kombination aus relativ leicht erreichbaren ersten Leveln und den Baukosten der Gebäude entsteht ein dynamischer Flow:

* **Level 1 auf Level 2:** Geht sehr schnell (ca. 2 Ingame-Tage bei voll belegten 6 Standardzimmern). Der Spieler schaltet Personal frei.
* **Level 2 auf Level 3:** Geht ebenfalls recht fix. Es schalten sich Familienzimmer und Forschung frei.
* **Ab Level 4:** Die benötigten EXP schießen stark nach oben. Ab hier verlangsamt sich das Spieltempo spürbar. Da der Spieler bis zu diesem Punkt sein Startkapital (meist 50.000 €) fast vollständig in Baukosten investiert hat, beginnt ab hier die Phase, in der er aus dem **laufenden Cashflow** heraus wirtschaften und seine Expansion sorgfältig planen muss.
