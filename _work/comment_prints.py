import os
import re

files_to_modify = [
    "scenes/ingame/guest/GuestActor.gd",
    "scenes/ingame/map/MapGrid.gd"
]

patterns = [
    r'^(\s*)print\("\[GuestActor\](.*)$',
    r'^(\s*)print\("\[MapGrid\](.*)$',
    r'^(\s*)print\("\[LOBBY DEBUG\](.*)$'
]

log_entries = []

for filepath in files_to_modify:
    if not os.path.exists(filepath):
        continue
    
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    modified = False
    for i, line in enumerate(lines):
        for pattern in patterns:
            match = re.search(pattern, line)
            if match:
                # Comment out the line
                new_line = match.group(1) + "# " + line[len(match.group(1)):]
                log_entries.append(f"- **{filepath}** (Line {i+1}):\n  - Old: `{line.strip()}`\n  - New: `{new_line.strip()}`")
                lines[i] = new_line
                modified = True
                break
                
    if modified:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(lines)

with open('_work/debug_prints.md', 'w', encoding='utf-8') as f:
    f.write("# Auskommentierte Debug-Prints\n\n")
    if log_entries:
        f.write("\n\n".join(log_entries))
    else:
        f.write("Keine Prints gefunden.")
        
print("Prints wurden auskommentiert und geloggt.")
