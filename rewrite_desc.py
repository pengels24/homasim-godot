import csv
import os

path = 'd:/game-dev/homasim-godot/translations/language.csv'

# New descriptions mapped by key
new_descriptions = {
    'techtree.zimmer.z1_1.desc': [
        'Eine solide Basis für jedes gute Hotel. Zufriedenes Personal arbeitet effizienter und legt den Grundstein für deinen Erfolg.',
        'A solid foundation for any good hotel. Satisfied staff work more efficiently and lay the groundwork for your success.'
    ],
    'techtree.zimmer.z1_2.desc': [
        'Mehr Platz für die ganze Familie. Ein größeres Raumangebot lockt Reisegruppen an, die Wert auf gemeinsame Zeit legen.',
        'More space for the whole family. A larger room offering attracts travel groups who value time together.'
    ],
    'techtree.zimmer.z1_3.desc': [
        'Für Gäste mit gehobenen Ansprüchen. Bessere Ausstattung bedeutet höhere Einnahmen, aber auch kritischere Blicke beim Service.',
        'For guests with high standards. Better amenities mean higher income, but also a more critical eye on the service.'
    ],
    'techtree.gastro.g1_1.desc': [
        'Der perfekte Ort, um den Abend ausklingen zu lassen. Exzellente Drinks an der Bar lockern den Geldbeutel der Gäste spürbar.',
        'The perfect place to end the evening. Excellent drinks at the bar noticeably loosen the guests wallets.'
    ],
    'techtree.gastro.g1_2.desc': [
        'Ein hungriger Gast ist ein unzufriedener Gast. Mit einer grundlegenden Verpflegung aus der eigenen Küche sicherst du das Überleben – und die Laune – deiner Kundschaft.',
        'A hungry guest is a dissatisfied guest. With basic catering from your own kitchen, you ensure the survival - and the mood - of your clientele.'
    ],
    'techtree.gastro.g1_3.desc': [
        'Mehr Platz, mehr Tische. Ein eigenes kleines Restaurant bewältigt den Ansturm zur Stoßzeit deutlich besser und bringt das Hotel auf die kulinarische Landkarte.',
        'More space, more tables. A dedicated small restaurant handles the rush hour crowd much better and puts the hotel on the culinary map.'
    ],
    'techtree.gastro.g1_4.desc': [
        'Ein Paradies für Feinschmecker. Wer hier speist, erwartet Perfektion – und verteilt bei entsprechendem Service begehrte Gourmetsterne.',
        'A paradise for foodies. Those who dine here expect perfection - and award coveted gourmet stars for appropriate service.'
    ],
    'techtree.wellness.w1_1.desc': [
        'Eine Oase der Ruhe. Ein hauseigenes Spa bietet den Gästen die nötige Entspannung, sodass sie ihren Aufenthalt direkt mit einem Lächeln beginnen.',
        'An oasis of tranquility. An in-house spa offers guests the necessary relaxation, allowing them to start their stay with a smile.'
    ],
    'techtree.wellness.w1_2.desc': [
        'Wasser marsch! Ein eigenes Hallenbad ist ein absoluter Publikumsmagnet, ganz unabhängig von Wind und Wetter.',
        'Water ahoy! A dedicated indoor pool is an absolute crowd magnet, regardless of wind and weather.'
    ],
    'techtree.wellness.w1_3.desc': [
        'Heiß begehrt. Eine großzügige Sauna ergänzt das Spa-Angebot perfekt und erfüllt selbst die höchsten Erwartungen gestresster Gäste.',
        'Highly sought after. A spacious sauna perfectly complements the spa offering and meets even the highest expectations of stressed guests.'
    ],
    'techtree.wellness.w1_4.desc': [
        'Körper und Geist im Einklang. Moderne Fitnessgeräte und umfassende Wellness-Pakete runden das Erholungsangebot ab und machen dein Hotel zur ersten Wahl für Aktivurlauber.',
        'Body and mind in harmony. Modern fitness equipment and comprehensive wellness packages complete the recreational offering and make your hotel the first choice for active vacationers.'
    ],
    'techtree.management.m1_1.desc': [
        'Die Digitalisierung hält Einzug. Mit dem SimBrowser öffnet sich die Tür zum Online-Markt für Buchungen, Gästebewertungen und gezieltes Marketing.',
        'Digitalization has arrived. The SimBrowser opens the door to the online market for bookings, guest reviews, and targeted marketing.'
    ],
    'techtree.management.m1_2.desc': [
        'Investiere in dein wichtigstes Gut. Regelmäßige Schulungen machen deine Mitarbeiter effizienter und stressresistenter.',
        'Invest in your most important asset. Regular training makes your employees more efficient and stress-resistant.'
    ],
    'techtree.management.m1_3.desc': [
        'Perfekt abgestimmte Laufwege und Handgriffe. Jeder im Team weiß genau, was zu tun ist, was den gesamten Hotelbetrieb beschleunigt.',
        'Perfectly coordinated paths and movements. Everyone in the team knows exactly what to do, which accelerates the entire hotel operation.'
    ],
    'techtree.management.m1_4.desc': [
        'Ein straffes Management wirkt Wunder. Selbst in Stoßzeiten bleibt das Personal ruhig, was sich direkt auf die Geduld wartender Gäste überträgt.',
        'Tight management works wonders. Even during rush hours, the staff remains calm, which directly transfers to the patience of waiting guests.'
    ],
    'techtree.prestige.p1_1.desc': [
        'Mach dein Hotel zum Dreh- und Angelpunkt der Region. Ob Reisegruppen oder Messen – hier ist immer etwas los.',
        'Make your hotel the hub of the region. Whether travel groups or trade fairs – there is always something going on here.'
    ],
    'techtree.prestige.p1_2.desc': [
        'Große Reden, großes Publikum. Ein eigener Eventsaal ist ein Magnet für Business-Gäste und spült massiv Prestige in die Kassen.',
        'Big speeches, big audience. A dedicated event hall is a magnet for business guests and flushes massive prestige into the coffers.'
    ],
    'techtree.prestige.p1_3.desc': [
        'Roter Teppich und Champagner. Lockt Gäste mit exklusivem Geschmack und extrem hohen Budgets an – Diskretion vorausgesetzt!',
        'Red carpet and champagne. Attracts guests with exclusive taste and extremely high budgets - discretion required!'
    ]
}

rows = []
with open(path, 'r', encoding='utf-8') as f:
    reader = csv.reader(f)
    for row in reader:
        if len(row) >= 3:
            key = row[0]
            if key in new_descriptions:
                # Replace DE and EN texts
                row[1] = new_descriptions[key][0]
                row[2] = new_descriptions[key][1]
        rows.append(row)

with open(path, 'w', encoding='utf-8', newline='') as f:
    writer = csv.writer(f)
    writer.writerows(rows)

print("Done updating descriptions.")
