import os

file_path = r'd:\game-dev\homasim-godot\changelog\gd-0.1.29.md'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix mojibake
replacements = {
    '"': 'Ä',
    'o': 'Ü',
    'Ǭ': 'ü',
    '': 'ä'
}
for k, v in replacements.items():
    content = content.replace(k, v)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed Mojibake")