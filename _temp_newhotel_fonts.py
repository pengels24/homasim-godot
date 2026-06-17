import os
import re

modal_path = r'd:\game-dev\homasim-godot\scenes\shared\NewHotelModal.tscn'
with open(modal_path, 'r', encoding='utf-8') as f:
    text = f.read()

# Function to replace font_size directly after a specific node definition
def update_font_size(node_name, old_size, new_size, content):
    pattern = r'(\[node name="' + node_name + r'".*?font_size = )' + str(old_size)
    return re.sub(pattern, r'\g<1>' + str(new_size), content, flags=re.DOTALL)

text = update_font_size('NameLabel', 14, 20, text)
text = update_font_size('HotelNameField', 16, 24, text)
text = update_font_size('EntranceLbl', 14, 20, text)
text = update_font_size('ErrorLbl', 13, 18, text)
text = update_font_size('GridLabel', 14, 20, text)
text = update_font_size('BtnCreate', 15, 20, text)
text = update_font_size('TitleLbl', 32, 42, text)

with open(modal_path, 'w', encoding='utf-8') as f:
    f.write(text)

print("Font sizes updated in NewHotelModal!")
