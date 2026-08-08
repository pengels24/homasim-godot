import sys

path = r'd:\game-dev\homasim-godot\translations\language.csv'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('Ã¤', 'ä')
text = text.replace('Ã¶', 'ö')
text = text.replace('Ã¼', 'ü')
text = text.replace('Ã„', 'Ä')
text = text.replace('Ã–', 'Ö')
text = text.replace('Ãœ', 'Ü')
text = text.replace('ÃŸ', 'ß')
text = text.replace('Ã©', 'é')
text = text.replace('Ã ', 'à')
text = text.replace('Ã¡', 'á')
text = text.replace('Ã¨', 'è')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
print("Done!")
