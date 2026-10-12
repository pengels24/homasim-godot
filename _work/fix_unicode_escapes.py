"""Ersetzt wörtliche \\uXXXX-Sequenzen in einer UTF-8-Datei durch die echten Zeichen.
Aufruf: python _work/fix_unicode_escapes.py <datei>
"""
import re
import sys

path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

new_text, count = re.subn(
    r'\\u([0-9a-fA-F]{4})',
    lambda m: chr(int(m.group(1), 16)),
    text,
)

with open(path, 'w', encoding='utf-8', newline='') as f:
    f.write(new_text)

print(f'{count} Ersetzungen in {path}')
