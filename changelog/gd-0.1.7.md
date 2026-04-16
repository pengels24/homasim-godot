## Version: 0.1.7
**Datum: 2026-04-16**

### Features & Verbesserungen

- **ANG-150** – Credits-Seite Schritt 2 komplett fertiggestellt:
  - **Hintergrund-Slideshow**: 3 home-background-PNGs, 5s Interval, 1.2s Crossfade-Tween (identisch zu MainMenu)
  - **Linkes Panel extra abdunkeln**: zusätzlicher schwarzer Overlay (0.58 Alpha) über linkem Drittel für Tiefentrennung
  - **Trennlinie-Schatten**: 40px Gradient-TextureRect nach rechts simuliert Schlagschatten
  - **Social-Icons**: Bootstrap Icons SVGs (fill="currentColor" → fill="white") + PNGs für alle 5 Plattformen (YouTube, Discord, Instagram, Tipeee, Ko-fi); Icon-Zentrierung via CenterContainer
  - **Zickzack-Layout**: Social-Buttons in alternierender Einzelspalte (links/rechts), Rounded-Square-Style (10px Radius statt rund)
  - **Logo**: `logo-transparent-80.png` (375×79px, TopBar-Größe), zentriert im linken Panel
  - **Musik-Infrastruktur**: `AudioStreamPlayer` lädt `credits_music.ogg/.mp3/.wav` automatisch wenn vorhanden; `credits_music.mp3` = Kevin MacLeod „Raving Energy" (CC BY 4.0)
  - **Play/Stop-Button**: kleiner Rundbutton (♪/▶/■) oben rechts, dimmt bei Stop; neben Zurück-Button verschoben
  - **Gradient-Fades**: Scroll-Bereich oben/unten mit schwarz-transparentem GradientTexture2D (funktioniert mit jedem Hintergrund)
  - **Eingangs-Animation**: linkes Panel fadet nach 0.3s Delay in 0.8s ein (modulate.a 0→1)
  - **Schriftgrößen**: alle Lauftext-Größen erhöht (Section 15, Name 30, Detail 18, Titel 42, Version 19, Danke 36)
  - **credits.txt**: Musik-Sektion (Kevin MacLeod), GitHub, Bootstrap Icons ergänzt
  - **Zurück-Button**: content-sized (kein fixed width), via `call_deferred` zentriert; Audio-Button sitzt rechts daneben auf gleicher Höhe

- **MainMenu-Polishing**:
  - Button „Credits" → „Info" umbenannt
  - Großtitel-Schlagschatten: 3px/4px Offset, 85% Alpha
  - Subtext-Hintergrund: StyleBoxFlat, 45% Schwarz, 10px Radius, 12% weißer Border – verbessert Lesbarkeit über Hintergrundbild
  - „Beenden" aus GridContainer herausgelöst, volle Breite (800px) als eigene Zeile → symmetrisches Layout auch bei ungerader Button-Anzahl
  - GridContainer + alle Grid-Buttons auf `SIZE_EXPAND_FILL` → rechter Buttonblock bündig mit Subtitle und Beenden
  - Outfit Bold Font auf alle Buttons ausgeweitet (`btn_tutorial`, `btn_character`, `btn_credits` fehlten bisher)

### Technische Änderungen

- `scenes/credits/Credits.gd`: komplett überarbeitet (Schritt 2), +`_build_background()`, `_add_scroll_fade()`, `_animate_entrance()`, `_start_music()`, `_toggle_music()`, `_next_slide()`
- `scenes/credits/Credits.tscn`: zurück auf plain ColorRect (Slideshow per Code)
- `scenes/main_menu/MainMenu.tscn`: Subtitle-StyleBox, Titelschatten, BtnQuit in Content-VBox verschoben, GridContainer SIZE_EXPAND_FILL
- `scenes/main_menu/MainMenu.gd`: BtnQuit-Pfad angepasst, Font-Loop auf alle Buttons erweitert
- `assets/icons/`: ic_youtube/discord/instagram (.png + .svg), ic_kofi.png, ic_tipeee.png
- `assets/images/logo-transparent-80.png`: neues Logo-Asset (375×79px)
- `assets/audio/credits_music.mp3`: Kevin MacLeod „Raving Energy" (CC BY 4.0)
- `assets/credits.txt`: Musik-Abschnitt, GitHub, Bootstrap Icons

### Offene Backlog-Issues

- **ANG-149** – Tutorial-Szene
- **ANG-151** – Button-Font-Polishing (weitere Szenen)
- **ANG-152** – Settings-Screen (ALT+S)
- **ANG-153** – Lucide-Icons für verbleibende BottomBar-Buttons
