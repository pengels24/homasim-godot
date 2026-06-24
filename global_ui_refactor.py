import os
import glob
import re

scenes_dir = r"d:\game-dev\homasim-godot\scenes"
tscn_files = glob.glob(os.path.join(scenes_dir, "**/*.tscn"), recursive=True)

for filepath in tscn_files:
    try:
        with open(filepath, "r", encoding="utf8") as f:
            lines = f.readlines()
    except Exception as e:
        print(f"Skipping {filepath}: {e}")
        continue

    out = []
    modified = False
    in_label = False
    node_name = ""
    node_type = ""

    for line in lines:
        if line.startswith("[node "):
            name_m = re.search(r'name="([^"]+)"', line)
            type_m = re.search(r'type="([^"]+)"', line)
            if name_m: node_name = name_m.group(1)
            if type_m: node_type = type_m.group(1)
            in_label = (node_type == "Label")
            
            out.append(line)
            
            # Inject Type Variations for Labels based on naming conventions
            if in_label:
                lower_name = node_name.lower()
                if "title" in lower_name or "header" in lower_name or "lblfin" in lower_name or "lblguest" in lower_name:
                    out.append('theme_type_variation = &"HeaderLarge"\n')
                    modified = True
                elif "sub" in lower_name or "labelvbc" in lower_name or "headline" in lower_name:
                    out.append('theme_type_variation = &"HeaderMedium"\n')
                    modified = True
            
            continue
            
        # Strip old overrides
        if "theme_override_font_sizes/font_size" in line:
            modified = True
            continue # drop line
        if "theme_override_fonts/font" in line:
            modified = True
            continue # drop line
        if "theme_override_colors/font_color" in line:
            modified = True
            continue # drop line
            
        # Optional: Replace hardcoded panel styles with ModalPanel ONLY if it's the main PanelContainer
        # We skip this for now to avoid breaking inner scrollboxes, we'll do panels manually if needed.
        
        out.append(line)

    if modified:
        with open(filepath, "w", encoding="utf8") as f:
            f.writelines(out)
        print(f"Refactored: {filepath}")

print("Done!")
