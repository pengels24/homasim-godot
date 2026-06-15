# HO·MA·SIM – Gästeliste & Follow-Cam (Picture-in-Picture)

_Planungsdokument – UI & Systemarchitektur_ 
_Stand: 15.06.2026_

## 1. Grundprinzip & Vision

Das Gästelisten-Modal dient nicht nur als schnöde Tabelle, sondern als lebendiges Beobachtungsinstrument.

- **Picture-in-Picture (PiP):** Ein Bereich des UI zeigt einen Live-Video-Feed des ausgewählten Gastes.
- **Synergie / Wiederverwendbarkeit:** Die hierfür gebaute `SubViewport`-Technik wird später im Spiel (ab Level 20) 1:1 für die "Sicherheitszentrale" (Überwachungskameras) recycelt.
- **Non-Blocking:** Der Spieler kann die Liste öffnen und den Gast im Mini-Fenster beobachten, während im Hauptspiel die Zeit normal weiterläuft.

## 2. Datenstruktur (Active Guest Registry)

Das UI muss wissen, wer sich aktuell im Hotel befindet. Da Gäste (im Gegensatz zu Räumen) dynamisch spawnen und despawnen, brauchen wir eine Liste der _aktiven_ Instanzen.

- **Das Array:** Ein globales Array im `GameState` oder `GuestManager` (z. B. `active_guests`), in das sich jeder Gast beim Spawnen (Check-in) einträgt und beim Despawnen (Check-out) wieder austrägt.
- **Benötigte Gast-Daten für das UI:**
    - `guest_name` (z. B. "Max Mustermann")
    - `assigned_room_id` (z. B. "EZ-04")
    - `current_state` (z. B. "Schläft", "Isst", "Wartet")
    - `satisfaction_level` (0-100, für das Sterne-Rating)
    - `node_reference` (Der direkte Link zum Gast-Node in der Spielwelt, zwingend nötig für die Kamera!)

## 3. Das UI-Layout (Das Modal)

Das Modal (Fenster) teilt sich grob in zwei Hauptbereiche auf:

### Linke Seite: Die Liste

- Eine `ScrollContainer` + `VBoxContainer` Kombination.
- Listet alle `active_guests` auf.
- **Filter/Sortierung:** Dropdowns, um Gäste z. B. nach "Niedrigste Zufriedenheit" oder "Zimmernummer" zu sortieren.
- Ein Klick auf einen Listeneintrag lädt die Daten in die rechte Seite.

### Rechte Seite: Das Dossier & Der Monitor

- Zeigt die genauen Attribute, Vorlieben und aktuellen Gedanken (`morale`-Einflüsse) des Gastes.
- **Der Monitor (Das PiP-Fenster):** Ein quadratischer oder rechteckiger Bereich, der den Live-Feed der Kamera zeigt.

## 4. Die SubViewport-Technik (Godot 4)

Um den Live-Feed zu realisieren, nutzen wir Godots Viewport-System.

- **Der Node-Baum im UI:**
    ```text
    MarginContainer (Rahmen für den Monitor)
    └── SubViewportContainer (Streckt den Viewport)
        └── SubViewport (Das eigentliche Fenster in die Welt)
            └── Camera2D (Die Follow-Cam)
    ```
    
- **Das Kamera-Skript (Follow-Logic):** Wenn ein Gast links in der Liste angeklickt wird, bekommt die `Camera2D` im `SubViewport` die `node_reference` dieses Gastes übergeben. In der `_process(delta)` Funktion der Kamera updatet sie stetig ihre eigene globale Position auf die des Gastes: `global_position = global_position.lerp(target_guest.global_position, 5.0 * delta)` (Sorgt für weiche Kamerafahrten).

## 5. Performance & Edge Cases (Wichtig für die Umsetzung!)

**1. Performance-Schutz (Rendering):** Zwei Viewports zu rendern (Hauptspiel + Mini-Monitor) kostet Leistung. _Lösung:_ Der `SubViewport` wird im Code komplett deaktiviert (`render_target_update_mode = UPDATE_DISABLED`), solange das Gästelisten-Modal geschlossen ist. Er rendert nur, wenn das UI sichtbar ist.

**2. Der "Ghost-Follow" (Gast verschwindet):** Was passiert, wenn der Spieler den Gast im Monitor beobachtet und dieser exakt in dem Moment das Hotel verlässt (Check-out) und despawnt (`queue_free()`)? Die Kamera würde ins Nichts referenzieren und das Spiel zum Absturz bringen (Null-Reference-Exception). 
_Lösung:_ 
- Die Kamera lauscht auf das `tree_exiting` Signal des Gastes.
- Despawnt der Gast, wird das Target der Kamera auf `null` gesetzt.
- Als visuelles "Easter Egg" könnte der Monitor in diesem Moment auf ein "No Signal" (Rauschen / Colorbars) umschalten.
