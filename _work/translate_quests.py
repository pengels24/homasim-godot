import csv
import json
import os

translations = {
    "Einsamer Wolf": "Lone Wolf",
    "Beherberge insgesamt 10 Single-Gäste.": "Host a total of 10 single guests.",
    "Solo-Reisende": "Solo Travelers",
    "Beherberge insgesamt 25 Single-Gäste.": "Host a total of 25 single guests.",
    "Unabhängigkeit": "Independence",
    "Beherberge insgesamt 50 Single-Gäste.": "Host a total of 50 single guests.",
    "Die Single-Hochburg": "The Single Stronghold",
    "Beherberge insgesamt 100 Single-Gäste.": "Host a total of 100 single guests.",
    
    "Zweisamkeit": "Togetherness",
    "Beherberge insgesamt 10 Paare.": "Host a total of 10 couples.",
    "Romantische Auszeit": "Romantic Getaway",
    "Beherberge insgesamt 25 Paare.": "Host a total of 25 couples.",
    "Liegt Liebe in der Luft?": "Is Love in the Air?",
    "Beherberge insgesamt 50 Paare.": "Host a total of 50 couples.",
    "Flitterwochen-Ziel": "Honeymoon Destination",
    "Beherberge insgesamt 100 Paare.": "Host a total of 100 couples.",

    "Schmales Budget": "Tight Budget",
    "Beherberge insgesamt 10 Budgetreisende.": "Host a total of 10 budget travelers.",
    "Sparfüchse": "Bargain Hunters",
    "Beherberge insgesamt 25 Budgetreisende.": "Host a total of 25 budget travelers.",
    "Günstig & Gut": "Cheap & Good",
    "Beherberge insgesamt 50 Budgetreisende.": "Host a total of 50 budget travelers.",
    "Backpacker-Paradies": "Backpacker Paradise",
    "Beherberge insgesamt 100 Budgetreisende.": "Host a total of 100 budget travelers.",

    "Familienausflug": "Family Trip",
    "Beherberge insgesamt 10 Familien.": "Host a total of 10 families.",
    "Bunter Trubel": "Colorful Bustle",
    "Beherberge insgesamt 25 Familien.": "Host a total of 25 families.",
    "Großfamilien": "Large Families",
    "Beherberge insgesamt 50 Familien.": "Host a total of 50 families.",
    "Familien-Resort": "Family Resort",
    "Beherberge insgesamt 100 Familien.": "Host a total of 100 families.",

    "Geschäftig": "Busy",
    "Beherberge insgesamt 10 Geschäftsreisende.": "Host a total of 10 business travelers.",
    "Im Auftrag der Firma": "On Company Business",
    "Beherberge insgesamt 25 Geschäftsreisende.": "Host a total of 25 business travelers.",
    "Business Class": "Business Class",
    "Beherberge insgesamt 50 Geschäftsreisende.": "Host a total of 50 business travelers.",
    "Das Konferenz-Zentrum": "The Conference Center",
    "Beherberge insgesamt 100 Geschäftsreisende.": "Host a total of 100 business travelers.",

    "Digitaler Nomade": "Digital Nomad",
    "Beherberge insgesamt 10 Digitale Nomaden.": "Host a total of 10 digital nomads.",
    "Remote Worker": "Remote Worker",
    "Beherberge insgesamt 25 Digitale Nomaden.": "Host a total of 25 digital nomads.",
    "Workation": "Workation",
    "Beherberge insgesamt 50 Digitale Nomaden.": "Host a total of 50 digital nomads.",
    "Kreativ-Hub": "Creative Hub",
    "Beherberge insgesamt 100 Digitale Nomaden.": "Host a total of 100 digital nomads.",

    "Feierlaune": "Party Mood",
    "Beherberge insgesamt 10 Event-Gäste.": "Host a total of 10 event guests.",
    "Event-Gäste": "Event Guests",
    "Beherberge insgesamt 25 Event-Gäste.": "Host a total of 25 event guests.",
    "Die große Party": "The Big Party",
    "Beherberge insgesamt 50 Event-Gäste.": "Host a total of 50 event guests.",
    "Festival-Stimmung": "Festival Vibe",
    "Beherberge insgesamt 100 Event-Gäste.": "Host a total of 100 event guests.",

    "Gehobene Ansprüche": "High Standards",
    "Beherberge insgesamt 10 Luxus-Gäste.": "Host a total of 10 luxury guests.",
    "VIP Gäste": "VIP Guests",
    "Beherberge insgesamt 25 Luxus-Gäste.": "Host a total of 25 luxury guests.",
    "High Society": "High Society",
    "Beherberge insgesamt 50 Luxus-Gäste.": "Host a total of 50 luxury guests.",
    "Die Elite": "The Elite",
    "Beherberge insgesamt 100 Luxus-Gäste.": "Host a total of 100 luxury guests.",

    "Baue eine Bar": "Build a Bar",
    "Errichte eine Bar (min. 1 Tresen und Platz zum Stehen).": "Construct a bar (min. 1 counter and space to stand).",
    "Baue eine Küche": "Build a Kitchen",
    "Errichte eine funktionale Küche für dein Hotel.": "Construct a functional kitchen for your hotel.",
    "Baue ein Restaurant": "Build a Restaurant",
    "Biete deinen Gästen Tische und Stühle für Mahlzeiten.": "Provide tables and chairs for your guests to eat.",

    "Küchen-Lehrling": "Kitchen Apprentice",
    "Koche 25 Gerichte.": "Cook 25 dishes.",
    "Küchen-Chef": "Head Chef",
    "Koche 100 Gerichte.": "Cook 100 dishes.",
    "Sterne-Koch": "Star Chef",
    "Koche 250 Gerichte.": "Cook 250 dishes.",

    "Guter Service": "Good Service",
    "Erledige 50 Bestellungen im Restaurant oder an der Bar.": "Fulfill 50 orders in the restaurant or bar.",
    "Routinierter Service": "Experienced Service",
    "Erledige 100 Bestellungen.": "Fulfill 100 orders.",
    "Perfekter Service": "Perfect Service",
    "Erledige 250 Bestellungen.": "Fulfill 250 orders.",

    "Baue einen Pool": "Build a Pool",
    "Errichte einen Poolbereich für deine Gäste.": "Construct a pool area for your guests.",
    "Baue ein Gym": "Build a Gym",
    "Errichte einen Fitnessraum mit Laufband oder Hantelbank.": "Construct a fitness room with a treadmill or weight bench.",
    "Baue ein Spa": "Build a Spa",
    "Errichte einen Spa-Bereich mit Sauna oder Massage.": "Construct a spa area with sauna or massage.",

    "Kühles Nass": "Cool Water",
    "Lass 5 Gäste den Pool nutzen.": "Have 5 guests use the pool.",
    "Wasserratten": "Water Rats",
    "Lass 25 Gäste den Pool nutzen.": "Have 25 guests use the pool.",
    "Schwimmfest": "Swim Festival",
    "Lass 50 Gäste den Pool nutzen.": "Have 50 guests use the pool.",
    "Aqua-Aerobic": "Aqua Aerobics",
    "Lass 100 Gäste den Pool nutzen.": "Have 100 guests use the pool.",

    "Aufwärmen": "Warm Up",
    "Lass 5 Gäste das Gym nutzen.": "Have 5 guests use the gym.",
    "Muskelkater": "Sore Muscles",
    "Lass 25 Gäste das Gym nutzen.": "Have 25 guests use the gym.",
    "Pumpen": "Pumping Iron",
    "Lass 50 Gäste das Gym nutzen.": "Have 50 guests use the gym.",
    "Ironman": "Ironman",
    "Lass 100 Gäste das Gym nutzen.": "Have 100 guests use the gym.",

    "Durchatmen": "Take a Breath",
    "Lass 5 Gäste das Spa nutzen.": "Have 5 guests use the spa.",
    "Entspannung pur": "Pure Relaxation",
    "Lass 25 Gäste das Spa nutzen.": "Have 25 guests use the spa.",
    "Wellness-Oase": "Wellness Oasis",
    "Lass 50 Gäste das Spa nutzen.": "Have 50 guests use the spa.",
    "Nirvana": "Nirvana",
    "Lass 100 Gäste das Spa nutzen.": "Have 100 guests use the spa.",

    "Baue Konferenzraum": "Build Conference Room",
    "Errichte einen Raum für Meetings und Vorträge.": "Construct a room for meetings and lectures.",
    "Kleines Meeting": "Small Meeting",
    "Habe 5 Konferenz-Teilnehmer.": "Host 5 conference attendees.",
    "Workshop": "Workshop",
    "Habe 25 Konferenz-Teilnehmer.": "Host 25 conference attendees.",
    "Symposium": "Symposium",
    "Habe 50 Konferenz-Teilnehmer.": "Host 50 conference attendees.",
    "Großer Kongress": "Major Congress",
    "Habe 100 Konferenz-Teilnehmer.": "Host 100 conference attendees.",

    "100 Gäste": "100 Guests",
    "Empfange insgesamt 100 Gäste.": "Receive a total of 100 guests.",
    "200 Gäste": "200 Guests",
    "Empfange insgesamt 200 Gäste.": "Receive a total of 200 guests.",
    "500 Gäste": "500 Guests",
    "Empfange insgesamt 500 Gäste.": "Receive a total of 500 guests.",
    "1000 Gäste": "1000 Guests",
    "Empfange insgesamt 1000 Gäste.": "Receive a total of 1000 guests.",

    "2.500€ Tagesumsatz": "2,500€ Daily Revenue",
    "Erreiche einen Tagesumsatz von 2.500€.": "Achieve a daily revenue of 2,500€.",
    "5.000€ Tagesumsatz": "5,000€ Daily Revenue",
    "Erreiche einen Tagesumsatz von 5.000€.": "Achieve a daily revenue of 5,000€.",
    "7.500€ Tagesumsatz": "7,500€ Daily Revenue",
    "Erreiche einen Tagesumsatz von 7.500€.": "Achieve a daily revenue of 7,500€.",
    "10.000€ Tagesumsatz": "10,000€ Daily Revenue",
    "Erreiche einen Tagesumsatz von 10.000€.": "Achieve a daily revenue of 10,000€.",

    "75% Zufriedenheit": "75% Satisfaction",
    "Beende einen Tag mit min. 75% durchschnittlicher Gästezufriedenheit.": "End a day with at least 75% average guest satisfaction.",
    "90% Zufriedenheit": "90% Satisfaction",
    "Beende einen Tag mit min. 90% durchschnittlicher Gästezufriedenheit.": "End a day with at least 90% average guest satisfaction.",
    "100% Zufriedenheit": "100% Satisfaction",
    "Beende einen Tag mit 100% durchschnittlicher Gästezufriedenheit.": "End a day with 100% average guest satisfaction.",

    "Volle Hütte": "Full House",
    "Erreiche 100% Zimmerbelegung (alle verfügbaren Zimmer sind gebucht).": "Reach 100% room occupancy (all available rooms are booked).",

    "Roter Teppich": "Red Carpet",
    "Beherberge insgesamt 10 VIP-Gäste.": "Host a total of 10 VIP guests.",
    "Sterne-Status": "Star Status",
    "Beherberge insgesamt 25 VIP-Gäste.": "Host a total of 25 VIP guests."
}

csv_path = r"d:\game-dev\homasim-godot\translations\language.csv"

updated_rows = []
modified_count = 0

with open(csv_path, 'r', encoding='utf-8') as f:
    reader = csv.reader(f)
    for row in reader:
        if len(row) >= 3 and row[0].startswith("quest."):
            if row[1] == row[2]:
                # Find translation
                if row[1] in translations:
                    row[2] = translations[row[1]]
                    modified_count += 1
        updated_rows.append(row)

with open(csv_path, 'w', encoding='utf-8', newline='') as f:
    writer = csv.writer(f, quoting=csv.QUOTE_MINIMAL)
    for row in updated_rows:
        writer.writerow(row)

print(f"Successfully updated {modified_count} quest translations.")
