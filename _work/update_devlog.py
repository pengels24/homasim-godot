import json

def format_last_devlog_entry(file_path, new_text):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print("File not found")
        return

    # Update the text of the last entry
    if len(data) > 0:
        if "0.2.2" in data[-1].get("title", ""):
            data[-1]["text"] = new_text
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=4)
            print(f"Updated formatting in {file_path}")
        else:
            print(f"Last entry in {file_path} is not 0.2.2")

desc_de = (
    "Ich habe ordentlich an den Stellschrauben gedreht und bringe euch mit v0.2.2 ein massives Update in Sachen Balancing und Quality of Life! Vielen Dank an alle fleißigen Tester!\n\n"
    "Zeitsteuerung (HUD & Hotkeys):\n"
    "- Die Zeitsteuerung umfasst nun 4 Buttons: Pause (Leertaste), Normal (1x), Schnell (5x), Vorspulen (10x).\n"
    "- Die Pause merkt sich nun die vorherige Geschwindigkeit und kehrt bei erneutem Drücken dorthin zurück.\n\n"
    "UI & Controls:\n"
    "- Monitor & PiP Fenster: Die ESC-Taste schließt nun logisch das zuletzt geöffnete Fenster (LIFO).\n"
    "- Zimmer-Kontextmenü: Sobald das Kontextmenü eines Zimmers geöffnet wird, verschwindet der Hover-Tooltip augenblicklich. Das Kontextmenü folgt zudem der Kamera, solange es nicht manuell verschoben wird.\n"
    "- Exklusiver Vollbildmodus und \"Maus-Einsperren\" eingebaut, damit ihr nicht aus Versehen auf den zweiten Monitor klickt.\n"
    "- Neue Einstellungen: Zwei Audio-Toggles für Kassen-Sounds (\"Kasching\") und Menü-Sounds (\"Düdeldü\") hinzugefügt. Kamerazentrierung für \"Zum Raum\" deaktivierbar gemacht.\n\n"
    "Balancing & Gameplay:\n"
    "- Gäste-Spawn: Die erste Ankunft von Gästen wird an Tag 1 nun erzwungen auf 07:00-07:30 gelegt.\n"
    "- Business & Nomaden: Business-Gäste generieren sich erst, wenn physisch ein Superior-Zimmer gebaut wurde. Digitale Nomaden (Level 5) korrigiert.\n"
    "- Bar: Öffnungszeiten korrigiert (12:00 bis 23:30 Uhr).\n\n"
    "Polishing & Code-Cleanup:\n"
    "- Tooltips: Raum-Status-Icons (Reinigung/Wartung) haben nun dynamische und korrekte Tooltips (z.B. \"angefordert\" vs. \"dringend nötig\").\n"
    "- Warnungen: Etliche störende Code-Warnings des Godot-Analyzers und hart codierte Texte ausgebaut.\n"
    "- Tutorial: Ein neuer Tipp erinnert rechtzeitig an Reinigungs- und Wartungspersonal, wenn Räume dreckig werden."
)

desc_en = (
    "I have heavily tweaked the balancing and with v0.2.2 I am bringing you a massive update regarding Quality of Life! Thank you to all the hardworking testers!\n\n"
    "Time Control (HUD & Hotkeys):\n"
    "- The time control now features 4 buttons: Pause (Space), Normal (1x), Fast (5x), Fast Forward (10x).\n"
    "- The pause now remembers the previous speed and instantly returns to it when pressed again.\n\n"
    "UI & Controls:\n"
    "- Monitor & PiP Windows: The ESC key now logically closes the last opened window (LIFO).\n"
    "- Room Context Menu: As soon as a room context menu opens, the hover tooltip disappears instantly. The menu also follows the camera unless manually moved.\n"
    "- Added exclusive fullscreen and \"mouse confined\" modes to prevent accidental clicks on a second monitor.\n"
    "- New Settings: Added two audio toggles to mute cash register sounds and menu sounds. The camera zoom for \"Go to Room\" can now be disabled.\n\n"
    "Balancing & Gameplay:\n"
    "- Guest Spawn: The very first arrival of guests on day 1 is now strictly timed to 07:00-07:30.\n"
    "- Business & Nomads: Business guests now only generate if a superior room has actually been built. Corrected spawn for Digital Nomads.\n"
    "- Bar: Corrected opening hours (12:00 to 23:30).\n\n"
    "Polishing & Code Cleanup:\n"
    "- Tooltips: Room status icons (cleaning/maintenance) now have dynamic and correct tooltips (e.g. \"requested\" vs \"urgently needed\").\n"
    "- Warnings: Cleaned up numerous annoying Godot engine warnings and removed hardcoded texts.\n"
    "- Tutorial: A new tip reminds you about cleaning and maintenance staff just in time when rooms get dirty."
)

format_last_devlog_entry(r"D:\entwicklung\homa\src\data\devlog.json", desc_de)
format_last_devlog_entry(r"D:\entwicklung\homa\src\data\devlog_en.json", desc_en)
