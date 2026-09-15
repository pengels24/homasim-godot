# Changelog v0.1.55

## Features & Polishing
- **ANG-353:** Feature PIP-Kamera / Gast-Follow-Modus - Fenster lassen sich snappen (Shift) und gruppieren. Ecken und Ränder (1px, Gold) wurden passend korrigiert. 
- **ANG-362:** HUD Gourmet-Sterne auf 5 einzelne Sterne (`ang-star-filled.aseprite` / `ang-star-outline.aseprite`) umgestellt, inklusive dynamischer Umfärbung zu Gold (`#EAB308`).

## Bugfixes & Cleanup
- **Cleanup:** Alte `GuestFollowTooltip`-Szene und -Skript komplett gelöscht und Referenzen in `HUD.gd` bereinigt.
- **Debugger-Cleanup:** Alle angesammelten Warnungen im Projekt entfernt (u.a. Ternary-Typisierungs-Fixes in `HUD.gd`, ungenutzte Variablen in `SpaSmall.gd` und `StaffActor.gd` gelöscht, Shadowing-Error von `result` in `PoolSmall.gd` gefixt).
- **Crashfix:** Absturz beim Spielstart wegen inkorrektem Zugriff auf `GameState.hotel_stars` behoben (jetzt `GameState.selected_hotel.get("stars", 0)`).
