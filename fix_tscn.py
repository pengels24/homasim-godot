import re

with open(r'd:\game-dev\homasim-godot\scenes\ingame\hud\modals\content\ModalContentEndOfDay.tscn', 'r', encoding='utf8') as f:
    lines = f.readlines()

out = []
node_type = ""
node_name = ""

for line in lines:
    if line.startswith('[node'):
        node_name_match = re.search(r'name="([^"]+)"', line)
        node_type_match = re.search(r'type="([^"]+)"', line)
        if node_name_match: node_name = node_name_match.group(1)
        if node_type_match: node_type = node_type_match.group(1)
        out.append(line)
        
        if node_type == "Label":
            if "Title" in node_name:
                out.append('theme_type_variation = &"HeaderLarge"\n')
            elif node_name == "Desc":
                out.append('theme_type_variation = &"DescLabel"\n')
            elif node_name == "LblProfit":
                out.append('theme_type_variation = &"ValueLabel"\n')
            elif node_name in ["LblRageQuits", "LblTimeouts", "LblRejected", "LblDeclined"]:
                out.append('theme_type_variation = &"ValueLabelRed"\n')
            elif node_name.startswith("Lbl"):
                out.append('theme_type_variation = &"ValueLabel"\n')
        continue
        
    if "theme_override_" in line:
        if "margin" in line or "separation" in line or "styles" in line:
            out.append(line)
        else:
            pass
    elif line.strip() == "horizontal_alignment = 2":
        out.append(line)
    elif line.strip() == "horizontal_alignment = 1":
        out.append(line)
    else:
        out.append(line)

with open(r'd:\game-dev\homasim-godot\scenes\ingame\hud\modals\content\ModalContentEndOfDay.tscn', 'w', encoding='utf8') as f:
    f.writelines(out)
