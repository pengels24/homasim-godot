csv_path = r'D:\game-dev\homasim-godot\translations\language.csv'

with open(csv_path, 'r', encoding='utf-8-sig') as f:
    content = f.read()

fixes = {
    # Kaputte Zeile 614 - fehlende Umlaute
    '"bugreporter.email.placeholder","Deine E-Mail (Optional fr Rckfragen)","Your Email (Optional for questions)"':
        '"bugreporter.email.placeholder","Deine E-Mail (Optional fuer Rueckfragen)","Your Email (Optional, for follow-up questions)"',
}

# Fix description label - broken umlaut in angehaengt
import re
content = re.sub(
    r'"bugreporter\.description\.label","[^"]*","([^"]*)"',
    lambda m: '"bugreporter.description.label","Was ist passiert?\\n(Ein Screenshot & Systemdaten werden automatisch angehaengt)","' + m.group(1) + '"',
    content
)

for old, new in fixes.items():
    if old in content:
        content = content.replace(old, new)
        print(f"Fixed: {old[:60]}")
    else:
        print(f"Not found (checking raw)...")
        # Try to find and show what's actually there
        for line in content.split('\n'):
            if 'bugreporter.email' in line:
                print(f"  Found: {repr(line[:100])}")

with open(csv_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done.")
