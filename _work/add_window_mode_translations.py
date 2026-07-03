csv_path = r'D:\game-dev\homasim-godot\translations\language.csv'

new_keys = [
    '"settings.ui.window_mode.move_hint","Fenster verschieben, dann ALT+ENTER zum Bestaetigen","Move window to your monitor, then press ALT+ENTER to confirm"',
    '"settings.ui.window_mode.restored","Fenstermodus wiederhergestellt","Window mode restored"',
]

with open(csv_path, 'r', encoding='utf-8-sig') as f:
    content = f.read()

to_add = [k for k in new_keys if k.split(',')[0].strip('"') not in content]

if not to_add:
    print("All keys already present.")
else:
    with open(csv_path, 'a', encoding='utf-8') as f:
        for line in to_add:
            f.write('\n' + line)
    print(f"Added {len(to_add)} key(s).")
