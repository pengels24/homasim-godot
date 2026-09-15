import csv

new_rows = [
    ["ui.quests.req_tech", " (Benötigt Forschung: ###)", " (Requires Research: ###)"]
]

csv_path = r"d:\game-dev\homasim-godot\translations\language.csv"

with open(csv_path, 'a', encoding='utf-8', newline='') as f:
    writer = csv.writer(f, quoting=csv.QUOTE_MINIMAL)
    for row in new_rows:
        writer.writerow(row)

print("Quest tech translations added successfully.")
