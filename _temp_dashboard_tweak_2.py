import os
import re

# --- DashboardHotelCard.tscn ---
card_path = r'd:\game-dev\homasim-godot\scenes\dashboard\DashboardHotelCard.tscn'
with open(card_path, 'r', encoding='utf-8') as f:
    card_text = f.read()

# Remove the font_size = 15 override from all labels
card_text = card_text.replace('\ntheme_override_font_sizes/font_size = 15', '')

# We also need to increase the custom_minimum_size of the Button if it has one?
# Wait, DashboardHotelCard's root Button doesn't have custom_minimum_size hardcoded?
# Let's check if it does. If it does, we change 340 to 360.
card_text = card_text.replace('custom_minimum_size = Vector2(360, 340)', 'custom_minimum_size = Vector2(360, 360)')

with open(card_path, 'w', encoding='utf-8') as f:
    f.write(card_text)

# --- Dashboard.tscn ---
dash_path = r'd:\game-dev\homasim-godot\scenes\dashboard\Dashboard.tscn'
with open(dash_path, 'r', encoding='utf-8') as f:
    dash_text = f.read()

# Change NewHotelCard height from 340 to 360
dash_text = dash_text.replace('custom_minimum_size = Vector2(360, 340)', 'custom_minimum_size = Vector2(360, 360)')

with open(dash_path, 'w', encoding='utf-8') as f:
    f.write(dash_text)

print("Font reverted and card height increased!")
