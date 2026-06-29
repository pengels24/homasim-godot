# -*- coding: utf-8 -*-
import csv
import io

raw_data = """
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
tutorial.finances.desc = "Dies ist diee Übersicht deiner Einnahmen und Ausgaben.\nDu kannst alle Einträge sortieren und filtern. Dies verschafft dir den Überblick über deine finanzielle Situation."

tutorial.sim_browser.title = "SimBrowser"
tutorial.sim_browser.desc = "Dein persönliches In-Game Web-Portal. Hier findest du Bewertungen, Statistiken und Lieferanten. Neuigkeiten aus dem HO·MA·SIM-Universum werden hier genauso veröffentlicht, wie Bekanntmachungen zu Events und anderen Spielern.\nTipp: Achte auf versteckte URLs!"
"""

data_dict = {}
lines = raw_data.strip().split('\n')
for i, line in enumerate(lines):
    if " = \"" in line:
        k, v = line.split(" = \"", 1)
        k = k.strip()
        v = v.strip()
        if v.endswith('"'):
            v = v[:-1]
        data_dict[k] = v.replace("\\n", "\n")

def update_csv(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        rows = list(reader)
        
    found_keys = set()
    for row in rows:
        if len(row) >= 2 and row[0] in data_dict:
            row[1] = data_dict[row[0]]
            found_keys.add(row[0])
            
    # Add missing keys
    for k, v in data_dict.items():
        if k not in found_keys:
            rows.append([k, v, ""])
            
    with open(filepath, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f, quoting=csv.QUOTE_ALL)
        writer.writerows(rows)

update_csv('translations/language.csv')
print("Updated successfully!")
