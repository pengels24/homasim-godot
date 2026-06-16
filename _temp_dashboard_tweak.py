import os
import re

card_path = r'd:\game-dev\homasim-godot\scenes\dashboard\DashboardHotelCard.tscn'
with open(card_path, 'r', encoding='utf-8') as f:
    card_text = f.read()

# 1. Change CardMargin margin_top from 2 to 8
card_text = card_text.replace('theme_override_constants/margin_top = 2', 'theme_override_constants/margin_top = 8')

# 2. Add font_size = 15 to all labels inside StatsGrid
# We can find all [node name="..." type="Label" parent="CardMargin/VBox/CenterStats/StatsGrid"]
# and insert theme_override_font_sizes/font_size = 15 right after layout_mode = 2

def insert_font_size(match):
    return match.group(0) + '\ntheme_override_font_sizes/font_size = 15'

pattern = r'\[node name="[^"]+" type="Label" parent="CardMargin/VBox/CenterStats/StatsGrid"(?: unique_id=\d+)?\]\n(?:unique_name_in_owner = true\n)?layout_mode = 2'

card_text = re.sub(pattern, insert_font_size, card_text)

with open(card_path, 'w', encoding='utf-8') as f:
    f.write(card_text)

print("Adjustments done!")
