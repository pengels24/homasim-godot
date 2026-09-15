import csv

new_rows = [
    ["ui.staff.no_workplace", "Kein Arbeitsplatz", "No Workplace"],
    ["ui.staff.no_workplace_desc", "Dieser Beruf benötigt einen entsprechenden Arbeitsplatz (POI), der noch nicht gebaut wurde.", "This profession requires a corresponding workplace (POI) which has not been built yet."],
    ["ui.staff.assign_title", "Personal Zuweisen", "Assign Staff"],
    ["ui.staff.assign_empty", "Kein passendes Personal verfügbar.", "No suitable staff available."],
    ["ui.staff.assign_desc", "Wähle einen Mitarbeiter aus, der diesem Raum zugewiesen werden soll:", "Select a staff member to assign to this room:"],
    ["ui.staff.workplace_title", "Arbeitsplatz Wählen", "Select Workplace"],
    ["ui.staff.workplace_empty", "Kein Raum mit freiem Slot für diesen Beruf vorhanden.", "No room with a free slot for this profession is available."],
    ["ui.staff.workplace_desc", "Wähle den Raum, in dem %s %s arbeiten soll:", "Select the room where %s %s should work:"],
    ["toast.reception.accepts", "%s akzeptiert und bleibt!", "%s accepts and stays!"],
    ["toast.reception.declines", "%s lehnt ab und verlässt das Hotel!", "%s declines and leaves the hotel!"],
    ["toast.reception.checkout_money", "Checkout: %s %s erhalten", "Checkout: %s %s received"]
]

csv_path = r"d:\game-dev\homasim-godot\translations\language.csv"

with open(csv_path, 'a', encoding='utf-8', newline='') as f:
    writer = csv.writer(f, quoting=csv.QUOTE_MINIMAL)
    for row in new_rows:
        writer.writerow(row)

print("Block 2 translations added successfully.")
