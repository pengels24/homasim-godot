## Version: 0.1.20
**Datum: 2026-05-01**

### Features & Verbesserungen

- **ANG-191** – Kapital-Abzug beim Bauen: `build_cost` wird vom Hotel-Kapital abgezogen; Prüfung ob Kapital ausreicht (sonst Toast "Nicht genug Kapital!"). Kapital wird in `_save_progress()` persistiert.
- **ANG-191** – XP-Gutschrift beim Bauen: `xp_reward` aus Raumdefinition wird dem Hotel-XP addiert und in der HUD-Anzeige aktualisiert. XP wird gespeichert.
- **ANG-191** – Floating Value Animationen: Beim Bauen fliegen animierte Labels vom Raum-Mittelpunkt zur HUD (`-X €` rot links, `+X XP` grün rechts). Animation: fade-in → aufsteigen → halten → zur HUD fliegen → im letzten Drittel ausblenden. Laufzeit ~2.4s.
- **ANG-191** – `SettingsManager`: `demolition_refund_rate: float = 0.5` als Vorbereitung für Abreiß-Rückgabe (50% Default), persistiert in settings.cfg.
- **ROOM_REGISTRY + get_definition()**: Jeder Raumtyp beschreibt sich via `static func get_definition()` selbst (id, build_cost, xp_reward, icon, category, locked, in_build_menu). `BuildMenu` baut seinen Inhalt dynamisch aus der Registry. `BuildMenu.find_definition()` als zentrale Lookup-Funktion für andere Systeme (DRY).
- Erstes Howto-Dokument: `_dev/howto/neuen-raum-hinzufuegen.md` – vollständige Anleitung inkl. Prefix-Tabelle und Checklist.

### Bugfix – BedStandard Wände nicht sichtbar

- **Ursache:** BGTopLeft/Right/BottomLeft/BottomRight waren Kinder von Ground → Kinder rendern über dem Parent → BG-Interieurtiles überdeckten Ground-Wandtiles.
- **Fix:** BG-Layer in neuen `Interior`-Node2D ausgelagert, der **vor** Ground in der Szenen-Hierarchie steht. Dadurch rendert Ground (Wände) nach Interior (Interieur) → Wandtiles liegen oben, transparente Mitte der Wall-PNGs lässt Interieur durchscheinen.
- **Ergebnis:** Wände und Interieur gleichzeitig sichtbar, vollständige Steuerbarkeit erhalten.

### Features & Verbesserungen (Fortsetzung)

- **Skip-Logik für fehlende Türpositionen:** `Room.gd` hat neue Methode `get_valid_door_combos() -> Array[Vector2i]` (Default: alle 8 Rotation/Offset-Kombos). Räume mit weniger Türpositionen überschreiben sie. `BedStandard` gibt nur `[(0,0),(0,1)]` zurück (LeftTop + LeftBottom).
- **BuildCursor R/T-Tasten** respektieren jetzt valide Kombos: R wechselt nur zwischen vorhandenen Rotationen, T nur zwischen vorhandenen Offsets der aktuellen Rotation. Kein Sprung mehr in nicht existente Türpositionen.

### Technische Änderungen

- **`autoload/FloatingValues.gd`** – neuer CanvasLayer-Autoload (layer=99); `spawn(text, amount, world_pos, target_node, screen_offset)` konvertiert Weltkoordinaten via `get_viewport().get_canvas_transform()` zu Bildschirmkoordinaten.
- **`scenes/shared/FloatingValue.gd` + `.tscn`** – animiertes Label-Node; zwei parallele Tweens (Positions-Tween + verzögerter Fade-Tween).
- **`BuildCursor.gd`** – Signal `room_placed` um `world_center: Vector2` erweitert; neue Kombo-Navigation (`_advance_rotation()`, `_advance_offset()`, `_valid_combos`).
- **`IngameBuild.gd`** – `_apply_build_costs()` als eigene Funktion; nutzt `BUILD_MENU_SCRIPT.find_definition()`.
- **`IngameHud.gd`** – `update_exp()`, `get_stat_money_node()`, `get_stat_exp_node()`, `get_stat_fp_node()` als neue Public-API.
- **`Room.gd`** – `get_valid_door_combos()` als überschreibbare Methode.
- **`BedStandard.gd`** – `get_valid_door_combos()` Override + `get_definition()`.
- **`Bed_Standard.tscn`** – neue Hierarchie: `Interior` (Node2D) → BGTopLeft/Right/BottomLeft/BottomRight vor `Ground`; BG-Layer sichtbar.
- **`Room.gd`**, **`BedStandard.gd`**, **`BedDouble.gd`**, **`Lobby.gd`** – `static func get_definition()` implementiert.

### Offene Backlog-Issues

- **ANG-192** – Wand-Austausch: Zimmer-Wände ersetzen Parzellen-Außenwände (neue Grafiken als Voraussetzung)
- **ANG-191** – Abreiß-Funktion (Refund-Logik vorhanden, Cursor + MapGrid fehlen noch)
- **ANG-191** – Zimmernummern-System (sequenziell, prefix-basiert, anti-cheat für XP + FP)
- **ANG-191** – XP-Level-Kurve + Level-Up-Mechanik
- **ANG-191** – FP-Quellen (kommen mit Techtree-Sprint)
