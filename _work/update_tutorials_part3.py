# -*- coding: utf-8 -*-
import csv

raw_data_de = """
codex.guest_single.title = "Neuer Gästetyp: Single"
codex.guest_single.desc = "Bleibt meist 1-3 Nächte. Erwartet ein einfaches Standard-Zimmer. Hat keine besonderen Ansprüche, zahlt aber auch nicht so viel."

codex.guest_couple.title = "Neuer Gästetyp: Paar"
codex.guest_couple.desc = "Paare bleiben meist 1-4 Nächte. Brauchen ein Doppel- oder Superior-Zimmer und schätzen Komfort."

codex.guest_business.title = "Neuer Gästetyp: Geschäftsreisender"
codex.guest_business.desc = "Bleibt 1-3 Nächte. Benötigt zwingend WLAN und einen Schreibtisch (Desk). Hohe Ausgaben-Bereitschaft!"

codex.guest_family.title = "Neuer Gästetyp: Familie"
codex.guest_family.desc = "Bleiben 2-5 Nächte. Brauchen ein großes Familienzimmer, schätzen Platz und lieben den Pool."

codex.guest_budget.title = "Neuer Gästetyp: Budgetreisender"
codex.guest_budget.desc = "Bleibt 1-2 Nächte. Sehr genügsam, bucht einfache Standard-Zimmer, gibt aber abseits davon kaum Geld aus."

codex.guest_nomad.title = "Neuer Gästetyp: Digitaler Nomade"
codex.guest_nomad.desc = "Bleibt sehr lange (7-14 Nächte). Benötigt WLAN, verbringt den ganzen Tag im Zimmer. Freut sich über Zimmer-Service."

codex.guest_event.title = "Neuer Gästetyp: Event-Teilnehmer"
codex.guest_event.desc = "Bleibt nur kurz (1-2 Nächte) für ein Event. Keine besonderen Ansprüche, recht profitabel in der Masse."

codex.guest_luxury.title = "Neuer Gästetyp: Luxus-Gast"
codex.guest_luxury.desc = "Bleibt 2-5 Nächte. Braucht unbedingt Superior-Zimmer, viel Privatsphäre und Luxus. Extrem hohes Budget, aber sehr kritisch! Liebt Zimmer-Service."
"""

raw_data_en = """
codex.guest_single.title = "New Guest Type: Single"
codex.guest_single.desc = "Usually stays 1-3 nights. Expects a simple standard room. Has no special demands, but doesn't pay as much either."

codex.guest_couple.title = "New Guest Type: Couple"
codex.guest_couple.desc = "Couples usually stay 1-4 nights. Need a double or superior room and appreciate comfort."

codex.guest_business.title = "New Guest Type: Business Traveler"
codex.guest_business.desc = "Stays 1-3 nights. Mandatory need for Wi-Fi and a desk. High spending willingness!"

codex.guest_family.title = "New Guest Type: Family"
codex.guest_family.desc = "Stay 2-5 nights. Need a large family room, appreciate space and love the pool."

codex.guest_budget.title = "New Guest Type: Budget Traveler"
codex.guest_budget.desc = "Stays 1-2 nights. Very frugal, books simple standard rooms, but hardly spends money otherwise."

codex.guest_nomad.title = "New Guest Type: Digital Nomad"
codex.guest_nomad.desc = "Stays very long (7-14 nights). Needs Wi-Fi, spends the whole day in the room. Happy about room service."

codex.guest_event.title = "New Guest Type: Event Attendee"
codex.guest_event.desc = "Stays only briefly (1-2 nights) for an event. No special demands, quite profitable in mass."

codex.guest_luxury.title = "New Guest Type: Luxury Guest"
codex.guest_luxury.desc = "Stays 2-5 nights. Absolutely needs superior room, lots of privacy and luxury. Extremely high budget, but very critical! Loves room service."
"""

data_dict_de = {}
data_dict_en = {}

for data_str, out_dict in [(raw_data_de, data_dict_de), (raw_data_en, data_dict_en)]:
    lines = data_str.strip().split('\n')
    for line in lines:
        if " = \"" in line:
            k, v = line.split(" = \"", 1)
            k = k.strip()
            v = v.strip()
            if v.endswith('"'):
                v = v[:-1]
            out_dict[k] = v.replace("\\n", "\n")

def update_csv(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        rows = list(reader)
        
    for row in rows:
        if len(row) >= 3 and row[0] in data_dict_de:
            row[1] = data_dict_de[row[0]]
            row[2] = data_dict_en[row[0]]
            
    with open(filepath, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f, quoting=csv.QUOTE_ALL)
        writer.writerows(rows)

update_csv('translations/language.csv')
print("Part 3 translations applied successfully!")
