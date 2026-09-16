import json

json_path = r"d:\game-dev\homasim-godot\config\tutorials.json"

with open(json_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

inspector_entry = {
    "id": "guest_inspector",
    "category": "codex",
    "title_key": "codex.guest_inspector.title",
    "desc_key": "codex.guest_inspector.desc",
    "image": "res://assets/icons/guests/user-star.svg"
}

# Find index of guest_groups to insert before it
insert_idx = len(data["tutorials"])
for i, item in enumerate(data["tutorials"]):
    if item.get("id") == "guest_groups":
        insert_idx = i
        break

data["tutorials"].insert(insert_idx, inspector_entry)

with open(json_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=4)

print("Inspector added to tutorials.json!")
