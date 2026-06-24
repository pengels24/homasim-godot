import re

with open(r'd:\game-dev\homasim-godot\scenes\shared\SettingsModal.tscn', 'r', encoding='utf8') as f:
    content = f.read()

# Add theme to root node
content = content.replace('[ext_resource type="Script"', '[ext_resource type="Theme" uid="uid://m7vvlxrl4xfq" path="res://assets/UI/default_theme.tres" id="1_theme"]\n[ext_resource type="StyleBox" uid="uid://cxh0s5seikuc5" path="res://assets/UI/menu_button_green.tres" id="2_green"]\n[ext_resource type="Script"')

content = re.sub(r'(\[node name="SettingsModal" type="Control".*?\n)', r'\1theme = ExtResource("1_theme")\n', content)

# Card -> ModalPanel
content = re.sub(r'(\[node name="Card" type="PanelContainer".*?\n.*?)(theme_override_styles/panel = SubResource\("StyleBoxFlat_card"\))', r'\1theme_type_variation = &"ModalPanel"', content)

# TitleLbl -> HeaderLarge
content = re.sub(r'(\[node name="TitleLbl" type="Label".*?\n.*?)(theme_override_colors/font_color = Color\(0.918, 0.702, 0.031, 1\)\n)?(theme_override_font_sizes/font_size = 32\n)?', r'\1theme_type_variation = &"HeaderLarge"\n', content)

# BtnTab -> HeaderMedium (or just remove font sizes to let theme dictate)
content = re.sub(r'theme_override_font_sizes/font_size = 13\n', r'', content)

# BtnSave -> menu_button_green
content = re.sub(r'theme_override_colors/font_[a-z_]+_color = Color\(.*?\)\n', '', content)
content = re.sub(r'theme_override_font_sizes/font_size = 15\n', '', content)
content = re.sub(r'theme_override_styles/normal = SubResource\("StyleBoxFlat_save"\)', 'theme_override_styles/normal = ExtResource("2_green")', content)
content = re.sub(r'theme_override_styles/pressed = SubResource\("StyleBoxFlat_save"\)', 'theme_override_styles/pressed = ExtResource("2_green")', content)
content = re.sub(r'theme_override_styles/hover = SubResource\("StyleBoxFlat_save_hover"\)', 'theme_override_styles/hover = ExtResource("2_green")', content)

with open(r'd:\game-dev\homasim-godot\scenes\shared\SettingsModal.tscn', 'w', encoding='utf8') as f:
    f.write(content)
