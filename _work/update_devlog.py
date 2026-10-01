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
        # Check if the last entry is indeed 0.2.2
        if "0.2.2" in data[-1].get("title", ""):
            data[-1]["text"] = new_text
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=4)
            print(f"Updated formatting in {file_path}")
        else:
            print(f"Last entry in {file_path} is not 0.2.2")

desc_de = (
    "Ein weiteres Hotfix-Update, das sich auf das Balancing, einige Logik-Aussetzer bei unseren Gästen und eine ordentliche Portion \"Quality of Life\" für die Bedienung konzentriert. Danke an alle fürs Testen und Melden!\n\n"
    "Bugfixes & Verbesserungen:\n"
    "- Gäste & Tagesablauf: Die erste Gästeankunft an Tag 1 ist nun fest auf 07:00-07:30 Uhr getaktet. Business-Gäste spawnen ab sofort erst, wenn ein Superior-Zimmer existiert.\n"
    "- QoL (Zeitsteuerung): Die Zeitsteuerung hat nun 4 Buttons (1x, 5x, 10x) plus die Pause-Taste (Leertaste). Die Pause merkt sich jetzt eure letzte Spielgeschwindigkeit.\n"
    "- QoL (Menüs & Sounds): Monitor-Fenster schließen sich jetzt logisch nacheinander mit ESC (LIFO). Kassen- und Menü-Töne können in den Audio-Optionen abgeschaltet werden.\n"
    "- Tutorials & Hilfen: Ein neuer Tipp erinnert an Reinigungs- und Wartungspersonal. Raum-Status-Icons haben nun dynamische Tooltips (z.B. \"angefordert\" vs. \"dringend nötig\").\n"
    "- Aufräumarbeiten: Hart codierte Texte entfernt, Bar-Öffnungszeiten korrigiert (12:00 bis 23:30 Uhr) und störende Code-Warnungen bereinigt."
)

desc_en = (
    "Another hotfix update that focuses on balancing, some logic hiccups with our guests, and a hefty dose of \"Quality of Life\" for the UI and controls. Thanks to everyone for testing and reporting!\n\n"
    "Bugfixes & Improvements:\n"
    "- Guests & Daily Routine: The first guest arrival on day 1 is now strictly timed to 07:00-07:30. Business guests will now only spawn if you have physically built a superior room.\n"
    "- QoL (Time Control): The time control now features 4 buttons (1x, 5x, 10x) plus the pause button (spacebar). The pause state now remembers your last game speed.\n"
    "- QoL (Menus & Sounds): Monitor windows now close logically one after the other when pressing ESC (LIFO). Annoying cash register and menu sounds can be disabled in the audio options.\n"
    "- Tutorials & Helpers: A fresh tutorial tip reminds you about the cleaning and maintenance staff just in time. Room status icons now have dynamic tooltips (e.g. \"requested\" vs \"urgently needed\").\n"
    "- Clean-up: Removed some hardcoded texts, corrected the bar opening hours (12:00 to 23:30) and cleaned up annoying engine code warnings."
)

format_last_devlog_entry(r"D:\entwicklung\homa\src\data\devlog.json", desc_de)
format_last_devlog_entry(r"D:\entwicklung\homa\src\data\devlog_en.json", desc_en)
