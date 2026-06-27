import csv
import io
import re

file_path = r'd:\game-dev\homasim-godot\translations\language.csv'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# First, fix *** / +++ -> ### / ***
content = content.replace('*** / +++', '### / ***')
content = content.replace('***/+++', '###/***')

# Also fix *** FP | +++ € -> ### FP | *** €
content = content.replace('*** FP | +++ €', '### FP | *** €')
content = content.replace('*** RP | +++ €', '### RP | *** €')

# Now process line by line to fix cases where *** is the ONLY placeholder
lines = content.splitlines()
new_lines = []

for line in lines:
    if '***' in line and '###' not in line:
        line = line.replace('***', '###')
    new_lines.append(line)

new_content = '\n'.join(new_lines) + '\n'

with open(file_path, 'w', encoding='utf-8', newline='') as f:
    f.write(new_content)

print('Fixed *** placeholders')