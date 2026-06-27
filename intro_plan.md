# Intro-Sequenz

Dieses Feature fügt eine kurze Intro-Sequenz ein, bevor das eigentliche Hauptmenü geladen wird. Da Godot mit Video-Codecs (MP4) aus Lizenzgründen ohne Plugins manchmal zickig ist, können wir das Intro wunderbar direkt in der Engine "drehen" – das ist ohnehin viel performanter und schärfer!

## Proposed Changes

### [NEW] es://scenes/intro/Intro.tscn & Intro.gd
Eine völlig neue Szene, die als neue **Main Scene** in den Projekteinstellungen (project.godot) hinterlegt wird.

**Ablauf des Intros (Vorschlag):**
1. **Szene 1:** Schwarzer Bildschirm, sanftes Einblenden des Textes "Ein Spiel von Angelus2010" (oder dein Studio-Name).
2. **Szene 2:** Das Logo "Made with Godot 4" wird eingeblendet.
3. **Szene 3:** Das HOMASIM-Logo (logo.png) erscheint mit einem leichten "Zoom-In"-Effekt.
4. **Ende:** Das Intro blendet weich aus und wechselt ins Hauptmenü (MainMenu.tscn).

**Interaktion:**
- Ein Druck auf Leertaste, Enter, ESC oder ein linker Mausklick überspringt das Intro sofort und lädt das Hauptmenü (niemand mag nicht-überspringbare Intros!).

### Anpassung der Projekteinstellungen
- pplication/run/main_scene wird auf "res://scenes/intro/Intro.tscn" geändert.

## Open Questions
> [!IMPORTANT]
> **Ablauf des Intros:** Was hältst du von dem vorgeschlagenen 3-Schritt-Ablauf? Hast du spezielle Wünsche (z.B. einen bestimmten Text, der eingeblendet werden soll)? Sollen wir auch ein Audio-File abspielen (z.B. einen tiefen "Swoosh" oder Start-Sound)?

> [!WARNING]
> **Dashboard -> Ingame Übergang:** Du hast auch den Übergang vom Dashboard ins Hotel erwähnt. Soll ich hierfür auch eine kleine Blende (Fade to Black -> "Lade Hotel..." -> Fade to Ingame) einbauen, oder fokussieren wir uns jetzt rein auf das Start-Intro?

## Verification Plan
1. Spiel starten: Das Intro sollte ablaufen.
2. Spiel starten und direkt klicken: Das Intro sollte sofort übersprungen werden.
3. Nach dem Intro: Das Hauptmenü sollte normal laden (inklusive des neuen Disclaimers).