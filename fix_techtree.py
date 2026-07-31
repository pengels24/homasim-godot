import os

csv_path = 'd:/game-dev/homasim-godot/translations/language.csv'

with open(csv_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if line.strip() == '':
        new_lines.append(line)
        continue
        
    parts = line.strip().split(',')
    
    # Skip lines that are already quoted
    if len(parts) > 1 and parts[1].startswith('"'):
        new_lines.append(line)
        continue
        
    # If the line has exactly 3 parts, it's already correct
    if len(parts) == 3:
        new_lines.append(line)
        continue
        
    if line.startswith('techtree.') or line.startswith('ui.techtree.'):
        key = parts[0]
        # Heuristic: Find where English starts. English starts with a capital letter and is usually the last or last few parts.
        # But wait, we can just look at the specific lines we know are broken.
        if key == 'techtree.zimmer.z11.desc':
            new_lines.append(f'{key},"Schaltet den Zimmer-Zweig frei. Der Basis-Komfort sorgt zudem dafür, dass dein Service-Personal 5% schneller arbeitet.","Unlocks the room branch. Base comfort also allows your service staff to work 5% faster."\n')
        elif key == 'techtree.zimmer.z12.desc':
            new_lines.append(f'{key},"Schaltet Familienzimmer frei. Diese sind lukrativer und erfordern ein Doppelbett sowie ein Einzelbett.","Unlocks family rooms. More lucrative and require a double bed and a single bed."\n')
        elif key == 'techtree.zimmer.z13.desc':
            new_lines.append(f'{key},"Schaltet Superior-Zimmer frei. Diese bringen mehr Einnahmen, benötigen aber einen TV und ein Sofa.","Unlocks superior rooms. Generates more income but requires a TV and a sofa."\n')
        elif key == 'techtree.gastro.g13.desc':
            new_lines.append(f'{key},"Schaltet die Bar frei. Eine zusätzliche Einnahmequelle für den Abend, bei der Gäste Cocktails genießen können.","Unlocks the bar. An additional evening income source where guests can enjoy cocktails."\n')
        elif key == 'techtree.gastro.g14.desc':
            new_lines.append(f'{key},"Erweitert die Küche zur Gourmetküche. Zieht Gastro-Kritiker an, die bei gutem Service lukrative Gourmetsterne vergeben.","Upgrades to a gourmet kitchen. Attracts food critics who award lucrative gourmet stars for good service."\n')
        elif key == 'techtree.wellness.w11.desc':
            new_lines.append(f'{key},"Schaltet das Spa / den Massageraum frei. Ein neuer Bereich, der die Zufriedenheit und das Luxusbedürfnis deiner Gäste drastisch steigert.","Unlocks the spa/massage room. A new area that drastically increases the satisfaction and luxury needs of your guests."\n')
        elif key == 'techtree.wellness.w12.desc':
            new_lines.append(f'{key},"Schaltet den Pool-Bereich frei. Ein absolutes Muss für Familien, um Punktabzüge bei der Zufriedenheit zu vermeiden.","Unlocks the pool area. An absolute must for families to avoid satisfaction penalties."\n')
        elif key == 'techtree.management.m11.desc':
            new_lines.append(f'{key},"Schaltet das Planungsbüro frei. Der Arbeitsplatz deiner Manager, um Forschungspunkte (FP) für den Techtree zu generieren.","Unlocks the planning office. The workplace for your managers to generate research points (RP) for the tech tree."\n')
        elif key == 'techtree.management.m12.desc':
            new_lines.append(f'{key},"Schaltet das Schulungssystem für Personal frei. Mitarbeiter können gegen Bezahlung weitergebildet werden, um ihre Skills zu erhöhen.","Unlocks the staff training system. Employees can be trained for a fee to increase their skills."\n')
        elif key == 'techtree.prestige.p11.desc':
            new_lines.append(f'{key},"Schaltet das Zufallsereignis-System frei. Es können spontane Reisegruppen oder Messe-Gäste auftauchen, die Zimmer suchen.","Unlocks the random event system. Spontaneous tour groups or trade fair guests looking for rooms can appear."\n')
        elif key == 'techtree.prestige.p12.desc':
            new_lines.append(f'{key},"Schaltet Großveranstaltungen frei. Errichte einen Eventsaal, um massive Mengen an Kurzzeit-Gästen und Prestige anzulocken.","Unlocks large events. Build an event hall to attract massive amounts of short-term guests and prestige."\n')
        else:
            # For any others, we just assume parts[1:-1] is German and parts[-1] is English
            de_text = ",".join(parts[1:-1])
            en_text = parts[-1]
            new_lines.append(f'{key},"{de_text}","{en_text}"\n')
    else:
        new_lines.append(line)

with open(csv_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
