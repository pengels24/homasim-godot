import os

csv_path = 'd:/game-dev/homasim-godot/translations/language.csv'

with open(csv_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Apply the user's manual fix for level 5
content = content.replace(
    'levelup.unlock.l5_milestone,"Level 5 erreicht!\\nDein Hotel wächst und gedeiht weiter.","Level 5 reached!\\nYour hotel continues to grow and thrive."',
    'levelup.unlock.l5_milestone,"Level 5 erreicht!\\nDu gehörst nun zu den etablierten Hoteliers. Halte die Augen offen nach VIPs und Events!","Level 5 reached!\\nYou are now an established hotelier. Keep an eye out for VIPs and events!"'
)

# Append the user's new strings and our tutorial strings
new_lines = """
roomdef.name.long.staff_small,Personalraum,Staff Room
room.tooltip.staff_present,Personal anwesend: %d,Staff present: %d
ui.techtree.feature.w11_bonus,+10 Start-Zufriedenheit,+10 Starting Satisfaction
techtree.wellness.w14,Ganzheitliche Wellness,Holistic Wellness
techtree.wellness.w14.desc,"Schaltet den kleinen Fitnessraum frei und erweitert die Öffnungszeiten für das Hallenbad. Ermöglicht später zudem lukrative All-Inclusive Wellness-Buchungen über das Online-Portal.\\n\\nVoraussetzungen: Level 3 | Hallenbad (W1.2), Premium-Spa (W1.3)\\nKosten: 750 FP | 7.500 €","Unlocks the small fitness room and extends the opening hours for the indoor pool. Also allows lucrative all-inclusive wellness bookings via the online portal later on.\\n\\nRequirements: Level 3 | Indoor Pool (W1.2), Premium Spa (W1.3)\\nCost: 750 FP | 7,500 $"
ui.techtree.feature.w12_pool,Raum: Hallenbad (Indoor-Pool),Room: Indoor Pool
ui.techtree.feature.w13_spa,Raum: Premium-Spa / Sauna,Room: Premium Spa / Sauna
ui.techtree.feature.w14_fitness,Raum: Fitnessraum (Klein),Room: Fitness Room (Small)
ui.techtree.feature.w14_hours,Erweiterte Öffnungszeiten für Hallenbad,Extended indoor pool hours
ui.techtree.feature.w14_package,Wellness-Paket (+30% Einnahmen),Wellness Package (+30% Income)
ui.techtree.feature.p11_events,Reisegruppen & Messe-Events,Travel Groups & Events
ui.techtree.feature.p12_conference,Konferenzraum,Conference Room
ui.techtree.feature.p13_vip,VIP-Gäste,VIP Guests
tutorial.room_lobby.title,Lobby,Lobby
tutorial.room_lobby.desc,"Das Herzstück und der zentrale Empfangsbereich des Hotels. Hier kommen neue Gäste an, werden empfangen, warten auf Zuweisung ihres Zimmers und checken bei Abreise wieder aus. Funktion: Die Rezeption wird anfangs vom Spieler bedient, im späteren Spielverlauf kann hier Personal (Rezeptionist) eingesetzt werden. Der Snack-Automat im Foyer dient als erste kleine Nahrungsquelle für Gäste. Die Lobby fungiert als zentraler Verteiler für alle Wegführungen im Hotel. Kosten: 0 € (Von Beginn an fest verbaut). Voraussetzungen: Keine (Standard).","The heart and central reception area of the hotel."
tutorial.room_bed_standard.title,Einzelzimmer (Standard),Single Room (Standard)
tutorial.room_bed_standard.desc,"Ein einfaches und günstiges Zimmer für preisbewusste Gäste und Alleinreisende. Funktion: Dient als grundlegender Schlaf- und Rückzugsort. Es ist die bevorzugte Wahl für Alleinreisende, Budget-Gäste, Geschäftsreisende, digitale Nomaden und Event-Gäste. Paare oder Familien buchen dieses Zimmer nicht. Kosten: 2.000 € (Basis-Einnahmen: 80 € / Nacht). Voraussetzungen: Keine (Standard).","A simple and affordable room for budget-conscious guests and solo travelers."
tutorial.room_bed_double.title,Doppelzimmer,Double Room
tutorial.room_bed_double.desc,"Ein geräumigeres Zimmer, das auf Paare ausgerichtet ist, aber auch als Ausweichzimmer für Singles genutzt werden kann. Funktion: Bietet Platz für zwei Personen und bringt durch den höheren Standard deutlich bessere Übernachtungseinnahmen als das Einzelzimmer (130 € / Nacht). Es ist die absolute Präferenz für Paare, kann aber auch von anderen Standard-Gästen gebucht werden. Dies führt an der Rezeption allerdings zu einer Rückfrage bezüglich des höheren Preises (Erfolgschance). Lehnt der Gast den Aufpreis ab, verlässt er das Hotel. Kosten: 3.500 €. Voraussetzungen: Keine (Standard).","A more spacious room geared towards couples, but can also be used as a fallback for singles."
tutorial.room_bed_family.title,Familienzimmer,Family Room
tutorial.room_bed_family.desc,"Ein großer Schlafraum, der exklusiv für Familien reserviert ist. Funktion: Bietet genug Platz für Familien (Eltern mit 1 bis 3 Kindern, also insgesamt 3 bis 5 Personen). Ist sehr lukrativ (200 € / Nacht). Referenzen zu anderen Räumen: Familien haben oftmals höhere Platzansprüche und verlangen nach einem Pool im Hotel, um Unzufriedenheit zu vermeiden. Kosten: 6.000 €. Voraussetzungen: Techtree Z1.2.","A large bedroom exclusively reserved for families."
tutorial.room_bed_superior.title,Superior-Zimmer,Superior Room
tutorial.room_bed_superior.desc,"Die gehobene Luxus-Klasse unter den Zimmern für VIP-Gäste und Luxusreisende. Funktion: Erfüllt hohe Ansprüche an Luxus und Privatsphäre. Bringt mit 400 € / Nacht mit die höchsten Einnahmen im Spiel, wird aber ausschließlich von den sehr seltenen Luxus-Gästen und VIPs gebucht. Kosten: 15.000 €. Voraussetzungen: Techtree Z1.3.","The upscale luxury class among rooms for VIP guests and luxury travelers."
tutorial.room_bar.title,Bar,Bar
tutorial.room_bar.desc,"Ein Treffpunkt für gesellige Gäste, der ab 12:00 Uhr mittags bis in die Nacht geöffnet ist (Adults only). Funktion: Generiert zusätzliche Einnahmen (15 € Basis) durch den Verkauf von Getränken. Die Bar erfordert zwingend einen Barkeeper (Personal), um überhaupt öffnen zu können. Referenzen zu anderen Räumen: Wenn im Hotel zusätzlich eine funktionierende kleine Küche (inklusive Koch) vorhanden ist, können Gäste an der Bar optional auch Essen bestellen, wofür allerdings eine zusätzliche Servicekraft (Bedienung) an der Bar eingeteilt werden muss. Kosten: 1.800 €. Voraussetzungen: Techtree G1.1.","A meeting place for sociable guests, open from noon into the night."
tutorial.room_kitchen_small.title,Kleine Küche,Small Kitchen
tutorial.room_kitchen_small.desc,"Das logistische Herz der Gastronomie. Hier essen keine Gäste, hier wird nur gearbeitet! Funktion: Die Küche bereitet Mahlzeiten zu. Sie erfordert zwingend einen Koch (Personal). Optional kann eine Bedienung eingeteilt werden, die die Kochgeschwindigkeit erhöht. Ohne eine aktive Küche können weder im Restaurant noch an der Bar Mahlzeiten verkauft werden. Kosten: 3.000 €. Voraussetzungen: Techtree G1.2.","The logistical heart of gastronomy. Guests don't eat here; this is exclusively a workspace!"
tutorial.room_restaurant_small.title,Kleines Restaurant,Small Restaurant
tutorial.room_restaurant_small.desc,"Ein Speisesaal für deine Gäste, der durch seine Öffnungszeiten (07:00 bis 22:00 Uhr) auch als Frühstücksraum genutzt wird, und in dem warme Mahlzeiten serviert werden. Funktion: Bietet Platz für bis zu 20 Gäste gleichzeitig. Gäste setzen sich hierher, um ihren Hunger zu stillen (generiert Einnahmen pro Gericht). Referenzen zu anderen Räumen: Ein Restaurant funktioniert niemals alleine! Es benötigt zwingend eine aktive Küche (mit Koch), die das Essen zubereitet, sowie eigenes Servicepersonal (Bedienung) im Restaurant, welches das Essen an die Tische bringt. Kosten: 5.000 €. Voraussetzungen: Techtree G1.3.","A dining room for your guests, which is also used as a breakfast room due to its opening hours."
tutorial.room_staff_small.title,Kleiner Personalraum,Small Staff Room
tutorial.room_staff_small.desc,"Ein zwingend notwendiger Rückzugsort für deine Angestellten. Funktion: Ohne Personalraum lässt sich gar kein Personal einstellen! Jeder gebaute Personalraum erhöht dein Limit für einstellbares Personal um 4. Zudem verliert Personal durch die Arbeit stetig an Moral. Im Personalraum machen erschöpfte Mitarbeiter Pause, um ihre Moral wieder aufzufüllen. Sinkt die Moral in den Keller, arbeiten sie ineffizient oder stellen die Arbeit komplett ein. Kosten: 2.500 €. Voraussetzungen: Level 2 (Personal-Freischaltung).","An absolutely necessary retreat for your employees."
"""

with open(csv_path, 'w', encoding='utf-8') as f:
    f.write(content.strip() + '\n' + new_lines.strip() + '\n')
