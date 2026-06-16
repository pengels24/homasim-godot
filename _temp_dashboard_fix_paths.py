import os

card_path = r'd:\game-dev\homasim-godot\scenes\dashboard\DashboardHotelCard.tscn'
with open(card_path, 'r', encoding='utf-8') as f:
    card_text = f.read()

# Fix the child node parent paths
card_text = card_text.replace('parent="VBox/', 'parent="CardMargin/VBox/')

with open(card_path, 'w', encoding='utf-8') as f:
    f.write(card_text)

print("DashboardHotelCard paths fixed!")
