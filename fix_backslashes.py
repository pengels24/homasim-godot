import os
import re

directory = r'd:\game-dev\homasim-godot\scenes\ingame'

for root, _, files in os.walk(directory):
    for file in files:
        if file.endswith('.gd'):
            file_path = os.path.join(root, file)
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Replace GameState.T(\"key\") with GameState.T("key")
            new_content = re.sub(r'GameState\.T\(\\\"([^\"]+)\\\"\)', r'GameState.T("\1")', content)
            
            if new_content != content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Fixed {file}")

print('Finished fixing literal backslashes')