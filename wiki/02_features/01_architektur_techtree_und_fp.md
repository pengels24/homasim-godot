# HO·MA·SIM – Techtree Architektur & FP-System

_Planungsdokument – Technische Basis & Implementierungs-Leitfaden_

_Stand: 19.09.2026 (v0.1.62)_

## 1. Grundprinzip der Implementierung

- **Instant-Unlock:** Freischaltungen erfolgen sofort per Klick (keine Forschungs-Timer), sofern die Bedingungen erfüllt sind und die FP (Forschungspunkte) ausreichen. Dies hält das Pacing konsistent mit dem Bausystem (Instant-Build).
- **Entkopplung:** Das "Erforschen" (Erlaubnis) und das "Bauen" (Kosten & Platz) sind getrennte Systeme.

## 2. Die Datenstruktur (Tech-Registry)

Das System nutzt ein zentrales Register (Dictionary), das alle Technologien starr definiert.
Jeder Eintrag in der JSON nutzt folgende Felder:
- `id` (z. B. "Z1.1")
- `name` (Translation-Key, z. B. "techtree.zimmer.z1_1")
- `category` (z. B. "zimmer" / "gastronomie")
- `col` & `row` (Grid-Koordinaten für die Darstellung im UI)
- `cost_fp` (z. B. 100)
- `cost_money` (z. B. 1000 - Zusätzliche monetäre Kosten für Forschung)
- `req_level` (Hotel-Level-Gate, z. B. 5 – **NEU ab v0.1.62** – pro Node individuell, nicht mehr zentral in `UNLOCK_LEVELS`)
- `req_stars` (optional, Gourmet-Sterne-Gate)
- `dependencies` (Array aus IDs der zwingenden Vorgänger, z.B. `["Z1.1"]` oder leer `[]`)
- `unlocks_emojis` (Optischer Indikator für das UI, z. B. "🛏️ 🚿")
- `demo_locked` (Boolean-Flag, ob die Forschung in der Demo gesperrt ist)

**Wichtig zur Freischaltung (Inverted Dependency):**
Im Gegensatz zu früheren Planungen gibt es im Techtree **kein `unlocks`-Array** und keine zentrale `UNLOCK_LEVELS`-Konstante mehr (entfernt in v0.1.62). Stattdessen prüfen die Räume selbst ihre Vorbedingungen. In den Basis-Daten der Raum-Skripte (z.B. `BedFamily.gd`) wird dafür die Eigenschaft `"req_tech": "Z1.5"` definiert. Das Hotel-Level-Gate steht direkt als `req_level` im Node der `techtree.json`.

## 3. Der Progression-Manager (Hintergrund-Logik)

Ein unsichtbarer Verwalter speichert den Fortschritt und prüft Freigaben.
- **Unlocked Techs:** Ein Array speichert alle bereits erforschten `id`s.
- **Validierung:** Bevor ein Techtree-Knoten freigeschaltet werden kann, checkt `is_tech_available(tech_id)` in `TechtreeManager.gd`:
    1. Ist das globale Tier-Gate offen?
    2. Hat das Hotel den Node-eigenen `req_level` (aus techtree.json) erreicht?
    3. Sind alle IDs aus `dependencies` bereits im Unlocked-Array?
    4. Ist der aktuelle FP-Kontostand ≥ `cost_fp`?
    5. Ist der Geldstand ≥ `cost_money`?

## 4. Die FP-Engine (Forschungspunkte-Generierung)

Forschungspunkte werden nicht gekauft, sondern passiv durch **aktives Spielen** generiert.
- **Der Startschuss:** Das FP-System ist komplett inaktiv, bis das Hotel **Level 5** erreicht hat und der Vertrag mit dem Forschungsinstitut unterzeichnet wurde (Einführungsevent der Forschung).
- **Der Ticker:** Ein stündlicher Zyklus (gekoppelt an den Ingame-TimeManager). Zu Beginn jeder neuen Ingame-Stunde wird der Zähler ausgewertet.

### Anti-Exploit (Definition von "Aktivität")
Um AFK-Farming (Spiel über Nacht laufen lassen) zu verhindern, zählen nur bewusste, spielverändernde Management-Entscheidungen als Aktivität:
- **Gültige Aktionen (+1 auf Zähler):**
    - Raum bauen, umbauen, abreißen.
    - Personal einstellen, kündigen, schulen.
    - Preise anpassen.
    - Techtree-Items freischalten.
    - Pop-ups / Events aktiv bestätigen.
- **Ignorierte Aktionen (Zählen nicht):**
    - Kamera bewegen (WASD/Maus).
    - Menüs nur öffnen/schließen.
    - Spiel pausieren/entpausieren.
    - Automatische Vorgänge (Gäste laufen, Personal putzt).

### FP-Ausschüttung (Stündlicher Reset)
Die gesammelten Aktionen der letzten Ingame-Stunde definieren den Bonus:

| Aktionen/Stunde | Stufe       | FP-Gewinn |
|-----------------|-------------|-----------|
| 0 – 5           | Idle        | +5 FP     |
| 6 – 20          | Moderat     | +10 FP    |
| 21 – 50         | Aktiv       | +20 FP    |
| 50+             | Sehr aktiv  | +35 FP    |

_Nach der Ausschüttung springt der Aktionszähler für die nächste Ingame-Stunde wieder auf exakt 0._

## 5. Das Techtree-UI (Visualisierung)

Angelehnt an das Master-Layout besteht das UI aus 5 parallelen Bahnen (Kategorien).
Jeder Knoten (Button) hat einen von drei optischen Zuständen (v0.1.62):
1. **Gesperrt / Ausgegraut** (`btn.disabled = true`, `modulate = 0.4`): Tier-Gate nicht offen, `req_level` nicht erreicht oder Dependencies fehlen.
2. **Verfügbar (Klickbar):** Alle Bedingungen erfüllt, genug FP/Geld vorhanden. Kein dauerhafter Glow – nativer Gold-Border des Buttons (aus `menu_button_darkblue.tres`) sichtbar.
3. **Erforscht:** Bereits im Unlocked-Array. Grüner Font-Color (`#366e4d`). Glow-Overlay erscheint nur bei Hover via `_highlight_dependencies()`.

**Hover-Verhalten:** Beim Überfahren eines Nodes leuchten der Node und seine Dependencies kurz auf (GlowOverlay mit grünem/rotem Border, animiertes Pulsieren bei nicht-erforschten Deps).
