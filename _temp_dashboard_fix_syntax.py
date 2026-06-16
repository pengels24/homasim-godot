import os
import re

path = r'd:\game-dev\homasim-godot\scenes\dashboard\DashboardHotelCard.tscn'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Fix literal \n
text = text.replace(r'\nmouse_filter = 2', '\nmouse_filter = 2')

# Fix panel style to button styles
text = text.replace('theme_override_styles/panel = SubResource("StyleBoxFlat_card")', '''mouse_default_cursor_shape = 2
theme_override_styles/normal = SubResource("StyleBoxFlat_card")
theme_override_styles/hover = SubResource("StyleBoxFlat_card_hover")
theme_override_styles/pressed = SubResource("StyleBoxFlat_card_hover")
theme_override_styles/focus = SubResource("StyleBoxEmpty_focus")''')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

print("DashboardHotelCard.tscn fixed!")
