import os
import glob
import re

scenes_dir = r"d:\game-dev\homasim-godot\scenes"
tscn_files = glob.glob(os.path.join(scenes_dir, "**/*.tscn"), recursive=True)

overrides = set()
for f in tscn_files:
    with open(f, "r", encoding="utf8") as file:
        content = file.read()
        matches = re.findall(r'theme_override_([a-zA-Z0-9_]+)', content)
        for m in matches:
            overrides.add(m)

print("Found overrides:")
for o in sorted(overrides):
    print(o)
