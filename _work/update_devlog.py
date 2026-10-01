import json
import datetime
import sys

def add_devlog_entry(file_path, version, date_str, tags, description):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        data = []

    new_entry = {
        "version": version,
        "date": date_str,
        "tags": tags,
        "description": description
    }
    
    # insert at the beginning
    data.insert(0, new_entry)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=4)
    print(f"Updated {file_path}")

today = datetime.datetime.now().strftime("%d.%m.%Y")

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

add_devlog_entry(r"D:\entwicklung\homa\src\data\devlog.json", "0.2.2", today, ["balancing", "hotfix", "qol"], desc_de)
add_devlog_entry(r"D:\entwicklung\homa\src\data\devlog_en.json", "0.2.2", today, ["balancing", "hotfix", "qol"], desc_en)
