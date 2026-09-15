import csv

new_rows = [
    ["modal.overview.title", "Hotel Status", "Hotel Status"],
    ["modal.overview.stars_rep", "Sterne & Ruf", "Stars & Rep"],
    ["modal.overview.finances", "Finanzen", "Finances"],
    ["modal.overview.rooms", "Zimmer & Belegung", "Rooms & Occupancy"],
    ["modal.overview.satisfaction", "Gästezufriedenheit", "Guest Satisfaction"],
    ["modal.overview.format_stars", "%d / 5 Sterne", "%d / 5 Stars"],
    ["modal.overview.format_rep", "%d / %d Rufpunkte", "%d / %d Reputation"],
    ["modal.overview.today", "Heute: %s%s €", "Today: %s%s €"],
    ["modal.overview.occupancy", "Auslastung: %d%% (%d/%d Zimmer · %d Betten)", "Occupancy: %d%% (%d/%d Rooms · %d Beds)"],
    ["modal.overview.occupancy_zero", "Auslastung: 0% (0 Zimmer)", "Occupancy: 0% (0 Rooms)"],
    ["modal.overview.cleanliness", "Ø Sauberkeit: %d%%", "Ø Cleanliness: %d%%"],
    ["modal.overview.satisfaction_fmt", "Ø Zufriedenheit: %d%% (%d Gruppen)", "Ø Satisfaction: %d%% (%d Parties)"],
    ["modal.overview.satisfaction_none", "Ø Zufriedenheit: Keine Gäste", "Ø Satisfaction: No Guests"],
    ["modal.overview.satisfaction_empty", "Ø Zufriedenheit: –", "Ø Satisfaction: –"],
    ["ui.guest_list.pip", "Beobachten (PIP)", "Watch (PIP)"],
    ["guest.state.day_guest", "Tagesgast", "Day Guest"]
]

csv_path = r"d:\game-dev\homasim-godot\translations\language.csv"

with open(csv_path, 'a', encoding='utf-8', newline='') as f:
    writer = csv.writer(f, quoting=csv.QUOTE_MINIMAL)
    for row in new_rows:
        writer.writerow(row)

print("Block 1 translations added successfully.")
