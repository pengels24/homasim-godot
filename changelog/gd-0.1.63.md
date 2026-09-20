# Changelog – gd-0.1.63
> Branch: `dev` | Datum: 20.09.2026

## 🐛 Bugfixes

- **fix: Queue-Free-Save-Bug (MapGrid.remove_room)** – `remove_child()` wird jetzt synchron vor `queue_free()` aufgerufen, damit `save_all_rooms_to_db()` den Node nicht mehr als Parcel-Kind sieht und re-speichert. Verhindert "Ghost-Rooms" nach dem Abriss.
- **fix: _sanitize_restored_rooms()** – Neue Funktion in `MapGrid.gd`. Wird am Ende von `_restore_rooms()` aufgerufen. Erkennt überzählige Raum-Instanzen bei Typen mit `max_count:1` und entfernt die Extras inkl. Grid-Cleanup und sofortigem Re-Save.
- **fix: rebuild_occ_from_active_rooms() – Exit-Tiles (v==2) clearen** – `repair-grid` DevConsole-Befehl baut OCC-Grid komplett neu auf. Ghost-Exit-Tiles (Wert 2) blieben vorher stehen und blockierten `_occ_free_for_room()`. Jetzt werden auch Wert-2-Zellen vor dem Rebuild gecleart.
- **fix: _draw() early-return für occ-overlay** – `if not _show_debug_grid: return` verhinderte das Zeichnen des OCC-Overlays. Fixed auf `if not _show_debug_grid and not _show_occ_overlay: return`.

## 🏗️ Features / Tools

- **feat: max_count:1 für POIs (Pre-Alpha Workaround, ANG-366)** – Gym, Pool, Spa, Bar, Restaurant und Küche können in der Pre-Alpha nur 1x gebaut werden. Verhindert den Mehrstanz-Deduplication-Bug bei POI-IDs.
- **feat: repair-grid DevConsole-Befehl** – Ruft `rebuild_occ_from_active_rooms()` auf MapGrid auf. Bereinigt Ghost-Room OCC-Blocking ohne Reload.
- **feat: occ-overlay DevConsole-Befehl** – Zeigt alle OCC-Werte als farbige Kacheln mit Zahl direkt auf der Map. Rot=1(Raum), Blau=2(Exit), Grau=3(Wand), Orange=4(Clearance).

## 📋 Linear Issues

- **ANG-366:** angelegt – Architekturschuld POI-IDs & Multi-Instanz-Support (Post-Alpha).

## ⚠️ Offene Punkte

- **Ghost-Room Bug:** `occ-overlay` hatte Early-Return-Bug (`_show_debug_grid` Guard). Erst in v0.1.63 gefixt. Ursache des Blocking noch nicht visuell bestätigt – nächste Session.
- **HUD Event-Panel:** Bleibt 2-zeilig nach Tagungsende. Fix steht noch aus.
