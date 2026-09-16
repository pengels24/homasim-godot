import csv

replacements = {
    "tutorial.room_lobby.desc": "The heart and central reception area of the hotel.\nHere, new guests arrive, are welcomed, wait to be assigned to their room, and check out upon departure.\n\nFunction: The reception is initially operated by the player; later in the game, staff (Receptionist) can be assigned here. The snack machine in the foyer serves as the first small food source for guests. The lobby acts as a central hub for all pathways in the hotel.\n\nCost: 0 € (Permanently built from the start)\n\nRequirements: None (Standard)",
    
    "tutorial.room_bed_standard.desc": "A simple and affordable room for budget-conscious guests and solo travelers.\n\nFunction: Serves as a basic sleeping and retreat area. It is the preferred choice for solo travelers, budget guests, business travelers, digital nomads, and event guests. Couples or families do not book this room.\n\nCost: 2,000 € (Base revenue: 80 € / Night)\n\nRequirements: None (Standard)",
    
    "tutorial.room_bed_double.desc": "A more spacious room geared towards couples, but can also be used as a fallback room for singles.\n\nFunction: Offers space for two people and generates significantly better overnight revenue than the single room (130 € / Night) due to its higher standard. It is the absolute preference for couples but can also be booked by other standard guests. However, this leads to an inquiry at the reception regarding the higher price (success chance). If the guest rejects the surcharge, they leave the hotel.\n\nCost: 3,500 €\n\nRequirements: None (Standard)",
    
    "tutorial.room_bed_family.desc": "A large bedroom exclusively reserved for families.\n\nFunction: Offers enough space for families (parents with 1 to 3 children, totaling 3 to 5 people). It is very lucrative (200 € / Night).\n\nReferences to other rooms: Families often have higher space requirements and demand a pool in the hotel to avoid dissatisfaction.\n\nCost: 6,000 €\n\nRequirements: Techtree Z1.2 (Family Room)",
    
    "tutorial.room_bed_superior.desc": "The upscale luxury class among rooms for VIP guests and luxury travelers.\n\nFunction: Fulfills high demands for luxury and privacy. Generates some of the highest revenues in the game at 400 € / Night, but is exclusively booked by very rare luxury guests and VIPs.\n\nCost: 15,000 €\n\nRequirements: Techtree Z1.3 (Superior Room)",
    
    "tutorial.room_bar.desc": "A meeting point for sociable guests, open from 12:00 PM until the night (Adults only).\n\nFunction: Generates additional revenue (15 € base) by selling drinks. The bar strictly requires a bartender (Staff) to open at all.\n\nReferences to other rooms: If the hotel also has a functioning small kitchen (including a chef), guests can optionally order food at the bar, which requires an additional service staff (Waiter) assigned to the bar.\n\nCost: 1,800 €\n\nRequirements: Techtree G1.1 (Basic Gastronomy)",
    
    "tutorial.room_kitchen_small.desc": "The logistical heart of gastronomy. No guests eat here, this is strictly a workspace!\n\nFunction: The kitchen prepares meals. It strictly requires a chef (Staff). Optionally, a waiter can be assigned to increase cooking speed. Without an active kitchen, meals cannot be sold in the restaurant or at the bar.\n\nCost: 3,000 €\n\nRequirements: Techtree G1.2 (Expanded Gastronomy)",
    
    "tutorial.room_restaurant_small.desc": "A dining hall for your guests, which is also used as a breakfast room due to its opening hours (07:00 AM to 10:00 PM) and serves warm meals.\n\nFunction: Provides seating for up to 20 guests simultaneously. Guests sit here to satisfy their hunger (generates revenue per dish).\n\nReferences to other rooms: A restaurant never functions alone! It strictly requires an active kitchen (with a chef) to prepare the food, as well as its own service staff (Waiter) in the restaurant to bring the food to the tables.\n\nCost: 5,000 €\n\nRequirements: Techtree G1.3 (Upscale Cuisine)",
    
    "tutorial.room_staff_small.desc": "An absolutely necessary retreat for your employees.\n\nFunction: Without a staff room, no staff can be hired at all! Each built staff room increases your limit for hireable staff by 4. Additionally, staff constantly lose morale from working. Exhausted employees take breaks in the staff room to replenish their morale. If morale hits rock bottom, they work inefficiently or stop working completely.\n\nCost: 2,500 €\n\nRequirements: Level 2 (Staff Unlock)"
}

new_rows = [
    ["tutorial.room_pool_small.title", "Hallenbad", "Indoor Pool"],
    ["tutorial.room_pool_small.desc", "Ein erfrischendes Hallenbad zur Entspannung und körperlichen Ertüchtigung.\n\nFunktion: Bietet Gästen (insbesondere Familien) eine Möglichkeit, ihre Bedürfnisse nach Erholung zu stillen. Erfordert zwingend einen Bademeister (Personal), um zu funktionieren.\n\nKosten: 8.000 €\n\nVoraussetzungen: Techtree W1.2 (Hallenbad)", "A refreshing indoor pool for relaxation and physical exercise.\n\nFunction: Offers guests (especially families) a way to satisfy their need for recreation. Strictly requires a lifeguard (Staff) to function.\n\nCost: 8,000 €\n\nRequirements: Techtree W1.2 (Indoor Pool)"],
    
    ["tutorial.room_spa_small.title", "Wellness-Oase", "Wellness Oasis"],
    ["tutorial.room_spa_small.desc", "Eine Wellness-Oase für maximale Entspannung und Luxus.\n\nFunktion: Zieht besonders Paare und VIPs an, die nach Erholung suchen. Ein Spa lindert den Stress der Gäste und erhöht ihre Zufriedenheit. Erfordert eine Spa-Fachkraft (Personal), um zu funktionieren.\n\nKosten: 12.000 €\n\nVoraussetzungen: Techtree W1.3 (Wellness-Oase)", "A wellness oasis for maximum relaxation and luxury.\n\nFunction: Particularly attracts couples and VIPs looking for recreation. A spa relieves guests' stress and increases their satisfaction. Requires a wellness counselor (Staff) to function.\n\nCost: 12,000 €\n\nRequirements: Techtree W1.3 (Wellness Oasis)"],
    
    ["tutorial.room_gym_small.title", "Fitnessstudio", "Fitness Studio"],
    ["tutorial.room_gym_small.desc", "Ein voll ausgestattetes Fitnessstudio für sportliche Gäste.\n\nFunktion: Ideal für aktive Gäste, die ihr Trainingsprogramm auch im Urlaub nicht unterbrechen wollen. Gäste nutzen die Geräte selbstständig, es wird kein spezielles Personal benötigt.\n\nKosten: 4.500 €\n\nVoraussetzungen: Techtree W1.1 (Basis-Wellness)", "A fully equipped fitness studio for athletic guests.\n\nFunction: Ideal for active guests who do not want to interrupt their workout routine while on vacation. Guests use the equipment independently; no special staff is required.\n\nCost: 4,500 €\n\nRequirements: Techtree W1.1 (Basic Wellness)"],
    
    ["tutorial.room_conference_small.title", "Konferenzraum", "Conference Room"],
    ["tutorial.room_conference_small.desc", "Ein repräsentativer Raum für geschäftliche Tagungen und Vorträge.\n\nFunktion: Schaltet lukrative Firmen-Events frei. Tagungsgäste buchen keine Zimmer, sondern besuchen tagsüber die Konferenz, hören Vorträge und konsumieren in den Pausen Speisen und Getränke in deinen Gastro-Einrichtungen.\n\nKosten: 10.000 €\n\nVoraussetzungen: Techtree P1.2 (Tagungsräume)", "A representative room for business meetings and lectures.\n\nFunction: Unlocks lucrative corporate events. Conference guests do not book rooms; instead, they attend the conference during the day, listen to lectures, and consume food and drinks in your gastronomy facilities during breaks.\n\nCost: 10,000 €\n\nRequirements: Techtree P1.2 (Conference Rooms)"]
]

csv_path = r"d:\game-dev\homasim-godot\translations\language.csv"

updated_rows = []
modified_count = 0

with open(csv_path, 'r', encoding='utf-8') as f:
    reader = csv.reader(f)
    for row in reader:
        if len(row) >= 3 and row[0] in replacements:
            row[2] = replacements[row[0]]
            modified_count += 1
        updated_rows.append(row)

# Append new ones
updated_rows.extend(new_rows)

with open(csv_path, 'w', encoding='utf-8', newline='') as f:
    writer = csv.writer(f, quoting=csv.QUOTE_MINIMAL)
    for row in updated_rows:
        writer.writerow(row)

print(f"Updated {modified_count} existing room tutorials and added {len(new_rows)//2} new room tutorials.")
