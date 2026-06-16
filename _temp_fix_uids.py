import re
import glob

files = [
    r'd:\game-dev\homasim-godot\scenes\dashboard\DashboardHotelCard.tscn',
    r'd:\game-dev\homasim-godot\scenes\dashboard\Dashboard.tscn'
]

for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        text = file.read()
    
    text = re.sub(r' uid="uid://[^"]+"', '', text)
    
    with open(f, 'w', encoding='utf-8') as file:
        file.write(text)

print("UIDs removed successfully.")
