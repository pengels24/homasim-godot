import os

# Append translations to language.csv with the weird € encoding
csv_path = 'd:/game-dev/homasim-godot/translations/language.csv'

lines_to_add = [
    '"finances.time.today","Heute",""',
    '"finances.time.yesterday","Gestern",""',
    '"finances.time.all","Alle",""',
    '"finances.cat.all","Alle",""',
    '"finances.cat.construction","Bau & Abriss",""',
    '"finances.cat.personal","Personal",""',
    '"finances.cat.gastro","Gäste/Gastro",""',
    '"finances.cat.quest","Quests/Bonus",""',
    '"finances.cat.research","Forschung",""',
    '"finances.type.all","Alle",""',
    '"finances.type.income","Nur Einnahmen",""',
    '"finances.type.expense","Nur Ausgaben",""',
    '"finances.title.income.today","Einnahmen Heute",""',
    '"finances.title.expense.today","Ausgaben Heute",""',
    '"finances.title.total.today","Saldo Heute",""',
    '"finances.title.income.yesterday","Einnahmen Gestern",""',
    '"finances.title.expense.yesterday","Ausgaben Gestern",""',
    '"finances.title.total.yesterday","Saldo Gestern",""',
    '"finances.title.income.all","Einnahmen Gesamt",""',
    '"finances.title.expense.all","Ausgaben Gesamt",""',
    '"finances.title.total.all","Gesamtsaldo",""',
    '"finances.header.time","Zeitpunkt",""',
    '"finances.header.cat","Kategorie",""',
    '"finances.header.desc","Beschreibung",""',
    '"finances.header.amount","Betrag",""',
    '"sim.title.sub","Dein persönlicher Simulations-Browser",""',
    '"sim.tip","Tipp: Gib eine URL in die Adressleiste ein und drücke Enter.",""',
    '"sim.error.404","404 - Not Found\\n\\nDie gewuenschte URL \'%s\' ist derzeit (noch) nicht verfuegbar.",""',
    '"sim.easter.angelus","Hallo Peter! Schoen dich hier hinter dem Vorhang zu treffen.",""',
    '"sim.easter.claude","Ich wusste, dass du hier suchst. Hallo vom anderen Ende der Leitung.",""',
    '"sim.site.hc.title","HotelCheck",""',
    '"sim.site.hc.desc","Bewertungsportal",""',
    '"sim.site.hb.title","HotelBooking",""',
    '"sim.site.hb.desc","Online-Buchungen",""',
    '"sim.site.ne.title","SimNews",""',
    '"sim.site.ne.desc","Welt-Nachrichten",""',
    '"sim.site.li.title","Lieferanten",""',
    '"sim.site.li.desc","Lieferanten-Katalog",""',
    '"sim.site.mi.title","Michelin",""',
    '"sim.site.mi.desc","Stern-Fortschritt",""',
    '"tutorial.sim_browser.title","SimBrowser",""',
    '"tutorial.sim_browser.desc","Dein persönliches In-Game Web-Portal. Hier findest du Bewertungen, Statistiken und Lieferanten. Tipp: Achte auf versteckte URLs!",""'
]

def to_euro(s):
    return ''.join('€' + c for c in s)

# check if we need to append a newline first
with open(csv_path, 'rb') as f:
    f.seek(0, 2)
    size = f.tell()
    f.seek(size - 2)
    last_bytes = f.read()

with open(csv_path, 'ab') as f:
    if b'\\n' not in last_bytes and b'\\r' not in last_bytes:
        f.write(to_euro('\r\n').encode('utf-8'))
    for line in lines_to_add:
        f.write(to_euro(line + '\r\n').encode('utf-8'))

print("Appended with € encoding.")
