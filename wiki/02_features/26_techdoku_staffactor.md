# TechDoku: StaffActor (Personal-Verhalten)
*Stand: v0.1.42*

Der `StaffActor` repräsentiert einen Angestellten im Hotel. Im Gegensatz zu Gästen, die stark bedürfnisgetrieben (Hunger, Schlaf) agieren, sind StaffActors primär **Aufgaben-getrieben (Task-driven)** und reagieren dynamisch auf das Hotel-Geschehen.

## 1. Lebenszyklus & Zuweisung
- **Spawn**: Wird vom `StaffController` in der Szene platziert, sobald ein Mitarbeiter eingestellt wird oder das Spiel lädt.
- **Datenhaltung**: Die persistenten Daten (Level, Gehalt, Skills, Moral, Training-Status) liegen im `StaffManager` (Autoload). Der `StaffActor` holt sich dort seine Vorgaben.
- **Zuweisung (Assignments)**: Ein Mitarbeiter kann einem spezifischen Raum (z.B. Bar, Küche) zugewiesen werden.
  - Wenn *nicht zugewiesen*, übernimmt er globale Aufgaben (z.B. Hotel putzen, Hotel reparieren).
  - Wenn *zugewiesen*, bleibt er primär in seinem Raum und wartet dort auf Kunden (z.B. Barkeeper, Koch).

## 2. State-Machine (Zustände)
Die internen States (`_state`) sind simpel gehalten, da die Komplexität in den Tasks liegt:
- `idle`: Der Mitarbeiter hat aktuell nichts zu tun und sucht nach neuen Aufgaben.
- `walking`: Bewegt sich auf dem MapGrid zu einem Zielraum oder Zielobjekt.
- `working`: Führt eine Aufgabe vor Ort aus (z.B. Putzen, Kochen, Servieren).
- `returning`: Kehrt an seinen Stammplatz (oder in die Lobby) zurück, wenn es nichts mehr zu tun gibt.

## 3. Task-System (Wie Arbeit gefunden wird)
Die Methode `_process_idle()` ist das Gehirn des Angestellten. Sie triggert, wenn der Mitarbeiter frei ist:
1. **Schulung (Training)**: Hat der Mitarbeiter `training_state == "in_training"`, verlässt er sofort seinen Arbeitsplatz und geht ins "Off" (despawnt bzw. wird unsichtbar), bis die Schulung beendet ist. Er kann in dieser Zeit weder arbeiten noch gekündigt werden.
2. **POI-Jobs (Kochen / Servieren)**:
   Ist der Mitarbeiter z.B. Koch oder Bedienung und seinem Restaurant/Küche zugewiesen, prüft er über den `GastroManager`, ob es Bestellungen gibt, die zubereitet oder serviert werden müssen.
3. **Globale Tasks (Putzen / Reparieren)**:
   Für Zimmermädchen (`cleaner`) oder Hausmeister (`handyman`) fragt der Actor beim `StaffController` nach dem nächsten freien Job. Der Controller verwaltet eine Liste an offenen Tasks (Dreckige Zimmer, kaputte Betten).
4. **Feierabend / Warten**:
   Gibt es absolut nichts zu tun, läuft der Mitarbeiter an seinen zugewiesenen Platz (z.B. hinter den Tresen der Bar) oder in die Lobby und wartet (`returning` -> `idle`).

## 4. Moral-System (Morale)
Jeder Mitarbeiter hat einen `morale`-Wert (0–100).
- **Abbau**: Zu viele Überstunden, Dauerstress oder unbezahlter Lohn (zukünftig) senken die Moral.
- **Auswirkungen**: 
  - Sinkt die Moral unter 50%, erhält der Mitarbeiter einen Malus auf seine Arbeits- und Laufgeschwindigkeit (bis zu -30%).
  - Sinkt die Moral auf 0, kündigt der Mitarbeiter sofort.
- **Regeneration**: Jede Stunde Ingame-Zeit (`TimeManager.sig_hour_passed`) regeneriert sich die Moral um 5%, **vorausgesetzt** der Mitarbeiter befindet sich gerade im `idle`-Status (also im Leerlauf).

## 5. Arbeitsgeschwindigkeit (Working Speed)
Die tatsächliche Dauer eines Tasks (z.B. "Wie lange dauert es, das Zimmer zu putzen?") wird berechnet aus:
- **Basis-Zeit** des Tasks (z.B. 20 Sekunden Ingame).
- **Mitarbeiter-Skill**: Ein Level-1-Zimmermädchen putzt langsamer als ein Level-5-Zimmermädchen.
- **Moral-Malus**: Schlecht gelauntes Personal trödelt.
- **Techtree-Boni**: Features wie "Prozessoptimierung" (M1.3) geben einen globalen Speed-Boost von +15%.
Die Formel wird in `_process_working()` über `speed_mult` angewandt.
