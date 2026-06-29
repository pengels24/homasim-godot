import os

path = 'd:/game-dev/homasim-godot/translations/language.csv'
with open(path, 'r', encoding='utf-8') as f:
    data = f.read()

# Replace the literal backslash+n with an actual newline
data = data.replace('critical!"\\n"finances.time.today"', 'critical!"\n"finances.time.today"')

with open(path, 'w', encoding='utf-8') as f:
    f.write(data)
print("Fixed missing newline!")
