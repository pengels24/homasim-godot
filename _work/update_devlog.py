import json
import datetime
import sys

def fix_and_add_devlog_entry(file_path, title, text_content):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print("File not found")
        return

    # Remove the bad entry if it exists
    if len(data) > 0 and "version" in data[0]:
        print(f"Removing bad entry from {file_path}")
        data.pop(0)

    # Add the new correct entry at the end
    today_str = datetime.datetime.now().strftime("%Y-%m-%d")
    
    new_entry = {
        "date": today_str,
        "title": title,
        "text": text_content,
        "youtube": "",
        "image": ""
    }
    
    # Append at the end
    data.append(new_entry)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=4)
    print(f"Updated {file_path}")

desc_de = (
    "Wir haben ordentlich an den Stellschrauben gedreht! "
    "Die erste Gästeankunft erfolgt nun pünktlich zum Start des Tages, "
    "Business-Gäste sind strikt an Superior-Zimmer gebunden und das Tutorial "
    "erinnert jetzt rechtzeitig an Reinigungspersonal. Zudem gibt es 4 neue "
    "Geschwindigkeits-Buttons (inkl. dynamischer Pause), und störende Menü-Sounds "
    "können in den Optionen deaktiviert werden. Ein reines Polish & Balancing Update!"
)

desc_en = (
    "We've tweaked the balancing! "
    "The first guests now arrive right at the start of the day, "
    "business guests are strictly tied to superior rooms, and the tutorial "
    "now reminds you of cleaning staff just in time. In addition, there are 4 new "
    "speed buttons (including dynamic pause), and annoying menu sounds "
    "can be disabled in the options. A pure polish & balancing update!"
)

fix_and_add_devlog_entry(r"D:\entwicklung\homa\src\data\devlog.json", "Patch Notes - v0.2.2 (Hotfix & Polishing)", desc_de)
fix_and_add_devlog_entry(r"D:\entwicklung\homa\src\data\devlog_en.json", "Patch Notes - v0.2.2 (Hotfix & Polishing)", desc_en)
