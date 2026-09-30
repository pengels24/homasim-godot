# Übergabeprotokoll (v0.2.2)
Datum: 29.09.2026

## Letzter Stand
- Wir befinden uns im **Pre-Alpha Tester-Feedback-Zyklus**. Der User arbeitet gerade eine Bug- und Polish-Liste durch. 
- Das Spiel läuft weiterhin unter `v0.2.2` (kein Versions-Bump, da wir mittendrin pausieren).

## Bearbeitete Systeme & Refactorings (Aktuelle Session)
- **Settings / Display:**
  - Standard-Monitor ID von `-1` auf `0` geändert.
  - Option für exklusiven Vollbildmodus (Exclusive Fullscreen) und Maus-Einsperren (`MOUSE_MODE_CONFINED`) implementiert, inklusive Lokalisierung.
- **UI & Lokalisierung:**
  - WipLabel in `NewHotelModal` behoben.
  - "Made with Godot"-Footer im Hauptmenü bereinigt.
  - `darkblue` Styling auf die "Weiter"-Buttons diverser Modals (LevelUp, StarAchieved) angewendet.
  - Quotes-Parsing-Bug in `language.csv` gefixt (`ui.tutorial.forschung.intro`).
  - Hardcodierte Texte für Tooltips (`RoomStatusIndicator.gd`) und den "Abbrechen"-Button (`ListModal.gd`) durch `GameState.T` ersetzt.
- **HUD & TechOverlay:**
  - Das RAM-Tracking im Debug-Overlay lieferte in Release-Builds immer `0 MB`. Daher zeigt das Panel in Release-Builds (mittels `OS.has_feature("debug")`) jetzt nur noch die FPS an und passt sich in der Höhe automatisch an.
- **Kamera & Steuerung:**
  - Ein Bug wurde behoben, bei dem sich die Kamera bei jedem Beenden des Bau/Abriss-Modus ungewollt zentrierte. Dies passiert nun nur noch, wenn der Parzellen-Kauf-Modus beendet wird.
  - Die Zimmer-Aktionen (`RoomContextMenu`) blockierten bisher das Navigieren der Map, da sie als `InputMode.MODAL` deklariert waren.
    - Neuer Zustand `InputMode.ROOM_SELECTED` wurde in `InputHandler.gd` integriert, der WASD und Zoom wieder freigibt.
    - Das Kontextmenü wurde umgebaut, sodass es bei bewegter Kamera dynamisch auf dem Bildschirm "mitfährt" und am Zimmer klebt (außer es wird vom Spieler via Drag and Drop gezogen).
  - Fehlende Feature-Unlocks (Personal) deaktivieren nun die Service/Maintenance Buttons (disabled status), statt Error-Toasts zu werfen. Sie erhielten Tooltips und das `darkblue` Disabled-Theme.

## Sofortige nächste Schritte
- Der User hat die Session nach Abarbeiten eines UI-Bug-Stapels unterbrochen. Wenn er in ~2 Stunden wiederkommt, wird er direkt mit dem **nächsten Punkt auf der Tester-Feedback-Liste** weitermachen.
- Höre dir an, was der Tester-Punkt ist, lies ggf. nochmal dieses Dokument, falls der Faden gerissen ist, und mache direkt weiter. Keine Versions-Bumps ohne ausdrückliche Freigabe.