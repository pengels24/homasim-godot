# Dev-Konsole (Debug & Cheats)

Die Dev-Konsole (`DevConsole.gd`) ist ein Ingame-Werkzeug, um während des Testens und der Entwicklung schnelle Spielstands-Manipulationen vorzunehmen (z.B. Geld erzeugen, Zeit springen, Gäste spawnen). Sie läuft komplett unabhängig vom restlichen UI und wird per Tastenkürzel getoggelt.

## Öffnen der Konsole
- **Shortcut:** `Alt + D`
- Funktioniert nur, wenn das Spiel als *Debug-Build* läuft (`OS.is_debug_build()`).

## Funktionsweise
Die Konsole nutzt ein einfaches Command-Parsing, welches nach dem Muster `befehl:wert` arbeitet (Bsp: `set-money:50000`).

### Wichtige Befehle

| Befehl | Parameter | Beschreibung |
|---|---|---|
| `help` | - | Listet alle verfügbaren Befehle im Logfenster auf. |
| `set-money` | `int` (z.B. 50000) | Setzt das Kapital des Hotels auf den angegebenen Wert. |
| `set-day` | `int` (z.B. 10) | Setzt den aktuellen Spieltag (Aktualisiert HUD & Savegame). |
| `set-time` | `int` (360-1439) | Setzt die Ingame-Zeit in Spielminuten (z.B. `360` = 06:00 Uhr). |
| `get-time` | `string` (z.B. 2200) | Konvertiert eine HHMM Eingabe in Spielminuten, um sie z.B. für `set-time` zu verwenden. |
| `save` | - | Erzwingt einen sofortigen Quicksave. |
| `spawn-guests`| `int` (z.B. 3) | Löst das Spawnen von x neuen Gast-Parteien an der Rezeption aus. |
| `add-guest-budget`| `int` (z.B. 150) | Addiert das angegebene Budget auf das Taschengeld aller *derzeit aktiven* Gäste und deren Party-Mitglieder (gut, wenn Gäste arm auf dem Zimmer verhungern). |
| `reload-config` | - | Lädt alle JSON-Basisdaten neu ein (z.B. ohne Neustart des Spiels Werte tunen). |
| `add-exp` | `int` (z.B. 500) | Addiert dem Hotel sofort EXP hinzu. |
| `set-level` | `int` (z.B. 5) | Hebt das Hotel auf das angegebene Level (EXP wird auf 0 für dieses Level resettet). |
| `set-fp` | `int` (z.B. 1000) | Setzt die Forschungspunkte auf den angegebenen Wert. |
| `unlock-all-tutorials`| - | Schaltet alle Tutorials im Codex sofort frei. |
| `reset-tutorial` | - | Setzt den Fortschritt der angesehenen Tutorials zurück (Tutorial-Popups erscheinen wieder). |

## Integration in den Code

Die Befehle werden in `DevConsole.gd` im `_execute(cmd)` Block über eine Match-Anweisung verarbeitet. 

**Beispiel `add-guest-budget`:**
1. Der Befehl wird empfangen und zerlegt.
2. Es wird validiert, ob `val_s` (der String hinter dem Doppelpunkt) ein valider Integer ist.
3. Die Konsole löst das globale Signal `GameState.sig_dev_add_guest_budget` aus.
4. Der `GuestManager`, welcher auf dieses Signal hört, iteriert durch sein `_active` Array und addiert das Budget auf jede Party und ihre `members`.

```gdscript
		"add-guest-budget":
			if not val_s.is_valid_int():
				_log("Fehler: Wert muss eine ganze Zahl sein.", CLR_ERR)
				return
			
			var amount := int(val_s)
			GameState.sig_dev_add_guest_budget.emit(amount)
			_log("Budget aller aktiven Gäste um %d erhöht." % amount, CLR_OK)
```
