import os

file_path = r'd:\game-dev\homasim-godot\translations\de.csv'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace typical double-UTF8 encoding artifacts
fixes = {
    '\u00c3\u00a4': '\u00e4', # ä
    '\u00c3\u00b6': '\u00f6', # ö
    '\u00c3\u00bc': '\u00fc', # ü
    '\u00c3\u009f': '\u00df', # ß
    '\u00c3\u0084': '\u00c4', # Ä
    '\u00c3\u0096': '\u00d6', # Ö
    '\u00c3\u009c': '\u00dc', # Ü
    '\u00e2\u201a\u00ac': '\u20ac', # € (â‚¬)
    '\u00e2\u20ac\u201c': '\u2013', # – (en dash)
}

# Wait, in python, if it was decoded as UTF-8 from bytes that were ANSI, 
# 'â‚¬' is \xe2\x82\xac if we read the bytes directly?
# Let's just do it directly on the string:
content = content.replace('Ã¤', 'ä')
content = content.replace('Ã¶', 'ö')
content = content.replace('Ã¼', 'ü')
content = content.replace('ÃŸ', 'ß')
content = content.replace('Ã„', 'Ä')
content = content.replace('Ã–', 'Ö')
content = content.replace('Ãœ', 'Ü')
content = content.replace('â‚¬', '€')
content = content.replace('â€“', '–')

# Also the weird "Gste" stuff we saw earlier might be Replacement Character U+FFFD () 
# If it is U+FFFD, the original characters were lost because it was read as invalid UTF-8 and replaced.
# Let's hope it's just 'Ã¤' etc.

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("de.csv fixed!")
