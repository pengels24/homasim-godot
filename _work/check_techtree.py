import json
with open('config/techtree.json', encoding='utf-8') as f:
    data = json.load(f)
nodes = data if isinstance(data, list) else data.get('nodes', [])
tier1 = [n for n in nodes if n.get('req_level', 0) <= 9]
for n in tier1:
    locked = "LOCKED" if n.get('demo_locked') else "ok"
    print(f"{n.get('id','?'):<8} lvl:{str(n.get('req_level','?')):<3} {locked:<8} {n.get('name_key','?')}")
