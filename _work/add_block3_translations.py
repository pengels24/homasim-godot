import csv

new_rows = [
    ["ui.tutorial.no_desc", "Keine Beschreibung verfügbar.", "No description available."],
    ["ui.tutorial.no_desc_room", "Für diesen Raum ist noch kein detaillierter Codex-Eintrag vorhanden.", "No detailed codex entry is available for this room yet."],
    ["ui.techtree.tooltip.reqs_title", "Voraussetzungen:", "Requirements:"],
    ["ui.techtree.tooltip.cost_title", "Kosten:", "Cost:"],
    ["ui.techtree.tooltip.cost_fp", "%d / %d FP", "%d / %d RP"],
    ["ui.techtree.tooltip.cost_money", "%s / %s %s", "%s / %s %s"],
    ["settings.ui.monitor_idx", "Monitor %s", "Monitor %s"],
    ["settings.controls.bind_title", "Taste belegen", "Bind Key"],
    ["settings.controls.bind_desc", "Bitte drücke jetzt eine Taste für:\\n%s\\n\\n(ESC zum Abbrechen)", "Please press a key for:\\n%s\\n\\n(ESC to cancel)"],
    ["settings.controls.collision_title", "Taste bereits belegt", "Key already bound"],
    ["settings.controls.collision_desc", "Die Taste ist bereits für '%s' belegt. Überschreiben?", "The key is already bound to '%s'. Overwrite?"]
]

csv_path = r"d:\game-dev\homasim-godot\translations\language.csv"

with open(csv_path, 'a', encoding='utf-8', newline='') as f:
    writer = csv.writer(f, quoting=csv.QUOTE_MINIMAL)
    for row in new_rows:
        writer.writerow(row)

print("Block 3 translations added successfully.")
