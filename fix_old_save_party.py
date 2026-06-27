import os

file_path = r'd:\game-dev\homasim-godot\scenes\ingame\guest\GuestParty.gd'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    'p.daily_budget = int(d.get("daily_budget", 0))',
    'p.daily_budget = int(d.get("daily_budget", p.members.reduce(func(acc, m): return acc + m.daily_budget, 0) if "members" in d else 20))'
)
# Wait, p.members.reduce might fail if p.members is not populated yet.
# Let's just do:
content = content.replace(
    'p.daily_budget = int(d.get("daily_budget", 0))',
    'p.daily_budget = int(d.get("daily_budget", 20))'
)
content = content.replace(
    'p.spending_budget = int(d.get("spending_budget", 0))',
    'p.spending_budget = int(d.get("spending_budget", p.daily_budget))'
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Fixed old savegame budget loading for party')