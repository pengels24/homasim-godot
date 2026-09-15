import csv

new_rows = [
    ["toast.room.pending_demolish", "%s für Abriss vorgemerkt.", "%s marked for demolition."],
    ["ui.confirm.demolish_pending_title", "Abriss vormerken?", "Mark for Demolition?"],
    ["ui.confirm.demolish_pending_desc", "%s ist aktuell belegt!\nFür automatischen Abriss nach Abreise der Gäste vormerken?", "%s is currently occupied!\nMark for automatic demolition after guests depart?"],
    ["ui.confirm.demolish_pending_btn", "Vormerken", "Mark"],
    ["ui.confirm.demolish_title", "Zimmer abreißen?", "Demolish Room?"],
    ["ui.confirm.demolish_desc", "Möchtest du %s wirklich abreißen?\nDu erhältst %d € zurück.", "Do you really want to demolish %s?\nYou will receive %d € in return."]
]

csv_path = r"d:\game-dev\homasim-godot\translations\language.csv"

with open(csv_path, 'a', encoding='utf-8', newline='') as f:
    writer = csv.writer(f, quoting=csv.QUOTE_MINIMAL)
    for row in new_rows:
        writer.writerow(row)

print("Translations added successfully.")
