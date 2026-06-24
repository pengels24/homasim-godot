import re

file_path = r"d:\game-dev\homasim-godot\scenes\manager_select\ManagerSelect.tscn"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Make "Name" labels HeaderMedium
content = re.sub(
    r'(\[node name="Name" type="Label"[^\]]*\]\nlayout_mode = 2\n)',
    r'\1theme_type_variation = &"HeaderMedium"\n',
    content
)

# Make "Plus" labels HeaderLarge
content = re.sub(
    r'(\[node name="Plus" type="Label"[^\]]*\]\nlayout_mode = 2\n)',
    r'\1theme_type_variation = &"HeaderLarge"\n',
    content
)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Patched ManagerSelect.tscn")
