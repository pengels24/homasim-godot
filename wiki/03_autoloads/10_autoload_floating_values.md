# 🌐 Autoload: FloatingValues.gd

### 🎯 Zweck (TL;DR)

Die Fabrik für fliegendes Feedback. Dieses Skript spawnt animierte Text-Labels (wie "+500 €" oder "-50 EXP") über dem Spielgeschehen. Es übernimmt die mathematisch komplexe Aufgabe, Koordinaten aus der 2D-Spielwelt in statische Bildschirm-Koordinaten umzurechnen, damit die Zahlen zielsicher ins HUD fliegen.

### 🛡️ Zuständigkeiten

- **Szenen-Instanziierung:** Lädt und spawnt die eigentliche Anzeige-Szene (`FloatingValue.tscn`).
- **Koordinaten-Transformation:** Übersetzt Punkte aus dem Kamera-Raum (`world_pos`) in fixe HUD-Koordinaten (`screen_pos`).
- **Farb-Logik:** Weist Beträgen automatisch das grüne (Positiv) oder rote (Negativ) Farbschema zu.
- **Rendering-Priorität:** Sorgt durch `layer = 99` dafür, dass fliegende Zahlen _immer_ über allem anderen (Map, Räume, UI-Fenster) gezeichnet werden.
- _(Nicht zuständig für: Die eigentliche Flug-Animation und das anschließende Löschen der Zahl. Das macht das Skript der instanziierten `FloatingValue.tscn` Szene selbst)._

### 💾 Zentrale Variablen (State)

- `SCENE` _(PackedScene)_: Vorgeladene Referenz auf die physische Text-Szene, um beim Spawnen keine Ladezeiten zu erzeugen.
- `COLOR_POS` / `COLOR_NEG` _(Color)_: Zentral definierte Godot-Farbwerte (Grün/Rot) für ein einheitliches visuelles Design im ganzen Spiel.
- `layer` _(int)_: Wird in `_ready()` hart auf 99 gesetzt, um Clipping-Fehler mit anderen CanvasLayers zu verhindern.
- `process_mode` _(Enum)_: Wird in `_ready()` auf `Node.PROCESS_MODE_ALWAYS` gesetzt. Dadurch fliegen die Zahlen weiter, selbst wenn das Hauptspiel pausiert ist.

### 📡 Wichtige Signale

- **Keine!** Es handelt sich um ein reines "Fire & Forget"-System. Es spawnt die Szene, übergibt die Flugdaten und kümmert sich danach nicht weiter darum.

### ⚙️ Kern-Funktionen

- **`spawn(text, amount, world_pos, target_node, screen_offset)`:** Die Hauptfunktion.
    1. Bricht sofort ab, falls der UI-Zielnode (z.B. die Geldbörse im HUD) nicht mehr existiert.
    2. Berechnet die Start-Koordinate auf dem Monitor.
    3. Holt sich per `get_global_rect().get_center()` exakt die Bildschirmmitte des Ziel-UI-Elements.
    4. Spawnt die Node und ruft deren eigene `spawn()`-Funktion für den Flug auf.
- **`_world_to_screen(world_pos)`:** Ein extrem wichtiges Mathematik-Helferlein. Es multipliziert die Weltkoordinate mit der `canvas_transform` des Viewports. Dadurch weiß das Spiel exakt, an welchem Monitor-Pixel sich z.B. Raum 3 befindet, egal wie weit die Kamera gerade rausgezoomt oder verschoben ist!

### ⚠️ Architektur-Hinweise (Gotchas)

1. **Der CanvasLayer-Trick:** Dass dieses Autoload von `CanvasLayer` erbt, ist ein bewusster Architektur-Kniff. Dadurch unterliegen die gespawnten Zahlen _nicht_ mehr der Ingame-Kamera. Wenn der Spieler während des Flugs scrollt oder zoomt, fliegen die Zahlen trotzdem unbeirrt auf ihrem geraden Monitor-Pfad zum UI-Ziel weiter.
2. **Kollisions-Vermeidung durch Offset:** Der optionale Parameter `screen_offset` (den der `EffectManager` z.B. mit `Vector2(48, 0)` befüllt) ist essenziell. Er sorgt dafür, dass, wenn ein Gast zeitgleich Geld _und_ EXP abwirft, die Zahlen nebeneinander starten und sich auf dem Flug nicht überlappen und unlesbar machen.
3. **Aufgabentrennung (Delegation):** Dieses Skript ist nur die Startrampe. Wenn du die Kurve oder Geschwindigkeit des Fluges ändern willst, musst du das Skript in `res://scenes/shared/FloatingValue.gd` anpassen.
