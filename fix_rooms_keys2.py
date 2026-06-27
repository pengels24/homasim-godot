import os
import re

directory = r'd:\game-dev\homasim-godot\scenes\ingame\rooms'

for root, _, files in os.walk(directory):
    for file in files:
        if file.endswith('.gd'):
            file_path = os.path.join(root, file)
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Match "name": GameState.T(\"...\") -> "name": "..."
            new_content = re.sub(r'\"name\":\s*GameState\.T\(\\\"(.*?)\\\"\)', r'"name": "\1"', content)
            
            if new_content != content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Fixed {file}")

print('Finished setting name to translation key in rooms')