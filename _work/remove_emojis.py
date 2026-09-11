import json, re

path = 'config/techtree.json'
with open(path, encoding='utf-8') as f:
    content = f.read()

# Alle "unlocks_emojis": "..." Zeilen entfernen (inkl. trailing Komma oder fehlend)
# Greedy-sicher: entfernt ganze Zeile mit Komma davor oder danach
content = re.sub(r',?\s*"unlocks_emojis":\s*"[^"]*"', '', content)

# Leere Zeilen aufräumen (doppelte \n)
content = re.sub(r'\n\s*\n\s*\n', '\n\n', content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done - unlocks_emojis entfernt.")

# Verify
with open(path, encoding='utf-8') as f:
    data = json.load(f)
print("JSON valide.")
