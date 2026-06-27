import os

file_path = r'd:\game-dev\homasim-godot\translations\language.csv'

with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

# Fix common corrupted characters
content = content.replace('ǽ\'', '€')
content = content.replace('ǽ\'', '€')
content = content.replace('â‚¬', '€')
content = content.replace('\'', '€')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('CSV fixed')