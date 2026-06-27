import os

file_path = r'd:\game-dev\homasim-godot\scenes\ingame\guest\GuestMember.gd'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    'm.daily_budget    = int(d.get("daily_budget",    0))',
    'm.daily_budget    = int(d.get("daily_budget",    20))'
)
content = content.replace(
    'm.spending_budget = int(d.get("spending_budget", 0))',
    'm.spending_budget = int(d.get("spending_budget", m.daily_budget))'
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Fixed old savegame budget loading')