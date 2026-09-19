import os, re

rooms_path = r'd:\game-dev\homasim-godot\scenes\ingame\rooms'
keywords = ['req_level', 'traits', 'pool', 'wlan', 'luxury', 'comfort', 'space', 'desk',
            'req_tech', 'allowed_guest_types', 'is_poi', 'unlock_required', 'provides']

for root, dirs, files in os.walk(rooms_path):
    for f in files:
        if not f.endswith('.gd'):
            continue
        path = os.path.join(root, f)
        with open(path, 'r', encoding='utf-8', errors='ignore') as fh:
            for i, line in enumerate(fh, 1):
                low = line.lower()
                if any(k in low for k in keywords):
                    print(f'{f}:{i}: {line.rstrip()}')
