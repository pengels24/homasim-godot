import re

file_path = 'wiki/alpha_backlog.md'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

new_fixes = '''- [x] **Bugfix:** Parzellen-Bau-Timer Bug behoben (Savegame Restore & korrekte Wand-Generierung).
- [x] **Bugfix:** Hardcoded Toast-Translation Fehler "wütend abgereist" behoben.
- [x] **Feature:** Animierter Schraffur-Shader für im Bau befindliche Parzellen.
'''

if '## 🛠️ Ungeplante Fixes & Features (Aktuelle Session)' in content:
    content = content.replace('## 🛠️ Ungeplante Fixes & Features (Aktuelle Session)\n', '## 🛠️ Ungeplante Fixes & Features (Aktuelle Session)\n' + new_fixes)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print('alpha_backlog.md updated.')
