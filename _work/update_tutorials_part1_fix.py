# -*- coding: utf-8 -*-
import csv

raw_data_de = r"""
tutorial.welcome.title = "Die Benutzeroberfläche HUD" 
tutorial.welcome.desc = "Willkommen in deinem neuen Hotel - hier ein kurzer Überblick:\nOben: Deine wichtigsten Laufdaten wie Finanzen und Gäste, sowie die Zeitsteuerung.\nUnten rechts: Die Steuerung für die Musik.\nUnten mittig: Die zentralen Hauptfunktionen (Bauen, Rezeption, Personal, etc.).\nUnten links: Der Ansichtsmerker zum Zwischenspeichern der Kameraposition.\nKamera-Steuerung: Mit WASD bewegst du die Kamera und mit dem Mausrad steuerst du den Zoom."

tutorial.build_mode.title = "Bau-Modus"
tutorial.build_mode.desc = "Klicke auf einen Raum um ihn zu bauen. Es erscheint ein Geistabbild des Raumes an deiner Maus. Mit [R] rotierst du den Raum, mit [.] kannst du die Türe verschieben.\nManche Räume müssen erst erforscht werden!"

tutorial.reception.title = "Die Rezeption"
tutorial.reception.desc = "Im Herzstück deines Hotels erledigst du den Check-in wartender Gäste (die Zuweisung in entsprechende Zimmer) und rechnest sie nach Ende ihres Aufenthaltes ab."

tutorial.staff.title = "Die Personal-Agentur"
tutorial.staff.desc = "Über diesen externen Dienstleister kannst du Personal einstellen, kündigen und den Arbeitsbereichen zuweisen.\nJeder Mitarbeiter erledigt seine Aufgaben automatisch. Einige Räume bieten auch die Möglichkeit Personal manuell zu rufen."

tutorial.tech_tree.title = "Forschung & Technologie"
tutorial.tech_tree.desc = "Über den Technologiebaum (Techtree) kannst du neue Räume und Upgrades mit Forschungspunkten (FP) freischalten. Welche Forschungen möglich sind bestimmt der Lauf der Zeit."

tutorial.questbook.title = "Das Aufgabenbuch"
tutorial.questbook.desc = "Jeder neue Raum und viele der erforschten Upgrades füllen dein Aufgabenbuch und sorgen so dafür, dass du bei Erfüllung der Quests Belohnungen wie EXP, FP und Geld erhälst."

tutorial.guest_list.title = "Die Gästeliste"
tutorial.guest_list.desc = "Dies ist die Übersicht aller aktiven Gäste. Hier siehst du unter anderem die Zufriedenheit, den Aufenthaltsort und das Budget auf einen Blick.\nÜber die Pip-Cam kannst du jeden aktiven Gast verfolgen und auch zu ihm springen."

tutorial.room_list.title = "Die Raumliste"
tutorial.room_list.desc = "Diese Liste zeigt den Status aller Zimmer: Sauberkeit, Belegung und Zustand.\nMit der Pip-Cam kannst du den Raum sehen und auch zu ihm springen."

tutorial.finances.title = "Finanzen"
tutorial.finances.desc = "Dies ist die Übersicht deiner Einnahmen und Ausgaben.\nDu kannst alle Einträge sortieren und filtern. Dies verschafft dir den Überblick über deine finanzielle Situation."

tutorial.sim_browser.title = "SimBrowser"
tutorial.sim_browser.desc = "Dein persönliches In-Game Web-Portal. Hier findest du Bewertungen, Statistiken und Lieferanten. Neuigkeiten aus dem HO·MA·SIM-Universum werden hier genauso veröffentlicht, wie Bekanntmachungen zu Events und anderen Spielern.\nTipp: Achte auf versteckte URLs!"
"""

raw_data_en = r"""
tutorial.welcome.title = "The User Interface HUD" 
tutorial.welcome.desc = "Welcome to your new hotel - here is a brief overview:\nTop: Your most important running data like finances and guests, as well as the time control.\nBottom right: The music controls.\nBottom center: The main core functions (Building, Reception, Staff, etc.).\nBottom left: The view indicator to temporarily save the camera position.\nCamera control: Use WASD to move the camera and the mouse wheel to control the zoom."

tutorial.build_mode.title = "Build Mode"
tutorial.build_mode.desc = "Click on a room to build it. A ghost image of the room will appear at your mouse cursor. Use [R] to rotate the room, and [.] to move the door.\nSome rooms must be researched first!"

tutorial.reception.title = "The Reception"
tutorial.reception.desc = "At the heart of your hotel, you handle the check-in of waiting guests (assigning them to appropriate rooms) and check them out at the end of their stay."

tutorial.staff.title = "The Staffing Agency"
tutorial.staff.desc = "Through this external service provider, you can hire, fire, and assign staff to their working areas.\nEvery employee performs their tasks automatically. Some rooms also offer the option to call staff manually."

tutorial.tech_tree.title = "Research & Technology"
tutorial.tech_tree.desc = "Through the technology tree (Techtree), you can unlock new rooms and upgrades using research points (RP). Which researches are available is determined by the passage of time."

tutorial.questbook.title = "The Quest Book"
tutorial.questbook.desc = "Every new room and many of the researched upgrades fill your quest book, ensuring that completing these quests rewards you with EXP, RP, and money."

tutorial.guest_list.title = "The Guest List"
tutorial.guest_list.desc = "This is the overview of all active guests. Here you can see, among other things, their satisfaction, location, and budget at a glance.\nUsing the Pip-Cam, you can track any active guest and also jump directly to them."

tutorial.room_list.title = "The Room List"
tutorial.room_list.desc = "This list shows the status of all rooms: cleanliness, occupancy, and condition.\nUsing the Pip-Cam, you can view the room and also jump directly to it."

tutorial.finances.title = "Finances"
tutorial.finances.desc = "This is the overview of your income and expenses.\nYou can sort and filter all entries. This gives you a clear overview of your financial situation."

tutorial.sim_browser.title = "SimBrowser"
tutorial.sim_browser.desc = "Your personal in-game web portal. Here you will find reviews, statistics, and suppliers. News from the HO·MA·SIM universe is published here, as well as announcements about events and other players.\nTip: Watch out for hidden URLs!"
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
print("Part 1 fixed successfully with raw strings!")
