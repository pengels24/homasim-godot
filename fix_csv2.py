import os

path = 'd:/game-dev/homasim-godot/translations/language.csv'

with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
for i, line in enumerate(lines):
    if line.strip() == '':
        new_lines.append(line)
        continue
        
    parts = line.strip().split(',')
    key = parts[0]
    
    if key == 'levelup.unlock.l8_wellness':
        new_lines.append('levelup.unlock.l8_wellness,"Wellness-Forschung verfügbar!\\nErforsche Spa, Pool & Co. im Techtree.","Wellness research available!\\nUnlock Spa, Pool & more in the Tech Tree."\n')
    elif key == 'tutorial.guest_list.desc':
        new_lines.append('tutorial.guest_list.desc,"Dies ist die Übersicht aller aktiven Gäste. Hier siehst du unter anderem die Zufriedenheit, den Aufenthaltsort und das Budget auf einen Blick.\\nÜber die Pip-Cam kannst du jeden aktiven Gast verfolgen und auch zu ihm springen.","This is the overview of all active guests. Here you can see, among other things, their satisfaction, location, and budget at a glance.\\nUsing the Pip-Cam, you can view the room and also jump directly to it."\n')
    elif key == 'codex.guest_luxury.desc':
        new_lines.append('codex.guest_luxury.desc,"Prominente und schwerreiche Gäste. Sie zahlen astronomische Summen für Übernachtungen und Services, sind aber extrem schnell verärgert, wenn die Qualität nicht ihren perfekten Standards entspricht. Sie erwarten eine hohe Luxus-Bewertung der Zimmer.\\n\\nBudget: Hoch\\nGeduld: Sehr niedrig\\nAnspruch: Perfektion\\nPlatzbedarf: Einzel- oder Doppelzimmer (Suite bevorzugt)","Guest Type: VIP & Luxury\\n\\nCelebrities and ultra-rich guests. They pay astronomical sums for stays and services but are extremely quick to anger if the quality doesn\'t meet their perfect standards. They expect a high luxury rating for rooms.\\n\\nBudget: High\\nPatience: Very low\\nExpectations: Perfection\\nSpace Needs: Single or Double room (Suite preferred)"\n')
    elif key == 'codex.guest_groups.desc':
        new_lines.append('codex.guest_groups.desc,"In HOMA SIM wird unterschieden zwischen Gästen (Köpfe) und Reisegruppen (Partien). Gäste repräsentieren die absolute Anzahl an Personen in deinem Hotel. Eine Gruppe kann jedoch aus mehreren Gästen (z.B. Familie oder Pärchen) bestehen.\\n\\nBeispiel: Ein Pärchen teilt sich ein Doppelzimmer. Es zählt als 1 Check-In (Gruppe), bringt aber 2 Gäste (Köpfe) in dein Hotel.","In HOMA SIM, there is a distinction between guests (heads) and travel groups (parties). Guests represent the total number of people in your hotel. However, a group can consist of multiple guests (e.g., a family or a couple).\\n\\nExample: A couple shares a double room. They count as 1 check-in (group) but bring 2 guests (heads) to your hotel."\n')
    elif key == 'ui.tutorial.forschung.intro':
        new_lines.append('ui.tutorial.forschung.intro,"Wähle links eine Kategorie aus, um Details zu den einzelnen Forschungsprojekten zu sehen.","Select a category on the left to see details about the individual research projects."\n')
    elif key == 'tutorial.room_lobby.desc':
        new_lines.append('tutorial.room_lobby.desc,"Das Herzstück und der zentrale Empfangsbereich des Hotels. Hier kommen neue Gäste an, werden empfangen, warten auf Zuweisung ihres Zimmers und checken bei Abreise wieder aus.\\n\\nFunktion: Die Rezeption wird anfangs vom Spieler bedient, im späteren Spielverlauf kann hier Personal (Rezeptionist) eingesetzt werden. Der Snack-Automat im Foyer dient als erste kleine Nahrungsquelle für Gäste. Die Lobby fungiert als zentraler Verteiler für alle Wegführungen im Hotel.\\n\\nKosten: 0 € (Von Beginn an fest verbaut).","The heart and central reception area of the hotel."\n')
    elif key == 'tutorial.room_bed_standard.desc':
        new_lines.append('tutorial.room_bed_standard.desc,"Ein einfaches und günstiges Zimmer für preisbewusste Gäste und Alleinreisende.\\n\\nFunktion: Dient als grundlegender Schlaf- und Rückzugsort. Es ist die bevorzugte Wahl für Alleinreisende, Budget-Gäste, Geschäftsreisende, digitale Nomaden und Event-Gäste. Paare oder Familien buchen dieses Zimmer nicht.\\n\\nKosten: 2.000 € (Basis-Einnahmen: 80 € / Nacht).","A simple and affordable room for budget-conscious guests and solo travelers."\n')
    elif key == 'tutorial.room_bed_double.desc':
        new_lines.append('tutorial.room_bed_double.desc,"Ein geräumigeres Zimmer, das auf Paare ausgerichtet ist, aber auch als Ausweichzimmer für Singles genutzt werden kann.\\n\\nFunktion: Bietet Platz für zwei Personen und bringt durch den höheren Standard deutlich bessere Übernachtungseinnahmen als das Einzelzimmer (130 € / Nacht). Es ist die absolute Präferenz für Paare, kann aber auch von anderen Standard-Gästen gebucht werden. Dies führt an der Rezeption allerdings zu einer Rückfrage bezüglich des höheren Preises (Erfolgschance). Lehnt der Gast den Aufpreis ab, verlässt er das Hotel.\\n\\nKosten: 3.500 €.","A more spacious room geared towards couples, but can also be used as a fallback for singles."\n')
    elif key == 'tutorial.room_bed_family.desc':
        new_lines.append('tutorial.room_bed_family.desc,"Ein großer Schlafraum, der exklusiv für Familien reserviert ist.\\n\\nFunktion: Bietet genug Platz für Familien (Eltern mit 1 bis 3 Kindern, also insgesamt 3 bis 5 Personen). Ist sehr lukrativ (200 € / Nacht).\\n\\nReferenzen zu anderen Räumen: Familien haben oftmals höhere Platzansprüche und verlangen nach einem Pool im Hotel, um Unzufriedenheit zu vermeiden.\\n\\nKosten: 6.000 €.\\n\\nVoraussetzungen: Techtree Z1.2.","A large bedroom exclusively reserved for families."\n')
    elif key == 'tutorial.room_bed_superior.desc':
        new_lines.append('tutorial.room_bed_superior.desc,"Die gehobene Luxus-Klasse unter den Zimmern für VIP-Gäste und Luxusreisende.\\n\\nFunktion: Erfüllt hohe Ansprüche an Luxus und Privatsphäre. Bringt mit 400 € / Nacht mit die höchsten Einnahmen im Spiel, wird aber ausschließlich von den sehr seltenen Luxus-Gästen und VIPs gebucht.\\n\\nKosten: 15.000 €.\\n\\nVoraussetzungen: Techtree Z1.3.","The upscale luxury class among rooms for VIP guests and luxury travelers."\n')
    elif key == 'tutorial.room_bar.desc':
        new_lines.append('tutorial.room_bar.desc,"Ein Treffpunkt für gesellige Gäste, der ab 12:00 Uhr mittags bis in die Nacht geöffnet ist (Adults only).\\n\\nFunktion: Generiert zusätzliche Einnahmen (15 € Basis) durch den Verkauf von Getränken. Die Bar erfordert zwingend einen Barkeeper (Personal), um überhaupt öffnen zu können.\\n\\nReferenzen zu anderen Räumen: Wenn im Hotel zusätzlich eine funktionierende kleine Küche (inklusive Koch) vorhanden ist, können Gäste an der Bar optional auch Essen bestellen, wofür allerdings eine zusätzliche Servicekraft (Bedienung) an der Bar eingeteilt werden muss.\\n\\nKosten: 1.800 €.\\n\\nVoraussetzungen: Techtree G1.1.","A meeting place for sociable guests, open from noon into the night."\n')
    elif key == 'tutorial.room_kitchen_small.desc':
        new_lines.append('tutorial.room_kitchen_small.desc,"Das logistische Herz der Gastronomie. Hier essen keine Gäste, hier wird nur gearbeitet!\\n\\nFunktion: Die Küche bereitet Mahlzeiten zu. Sie erfordert zwingend einen Koch (Personal). Optional kann eine Bedienung eingeteilt werden, die die Kochgeschwindigkeit erhöht. Ohne eine aktive Küche können weder im Restaurant noch an der Bar Mahlzeiten verkauft werden.\\n\\nKosten: 3.000 €.\\n\\nVoraussetzungen: Techtree G1.2.","The logistical heart of gastronomy. Guests don\'t eat here; this is exclusively a workspace!"\n')
    elif key == 'tutorial.room_restaurant_small.desc':
        new_lines.append('tutorial.room_restaurant_small.desc,"Ein Speisesaal für deine Gäste, der durch seine Öffnungszeiten (07:00 bis 22:00 Uhr) auch als Frühstücksraum genutzt wird, und in dem warme Mahlzeiten serviert werden.\\n\\nFunktion: Bietet Platz für bis zu 20 Gäste gleichzeitig. Gäste setzen sich hierher, um ihren Hunger zu stillen (generiert Einnahmen pro Gericht).\\n\\nReferenzen zu anderen Räumen: Ein Restaurant funktioniert niemals alleine! Es benötigt zwingend eine aktive Küche (mit Koch), die das Essen zubereitet, sowie eigenes Servicepersonal (Bedienung) im Restaurant, welches das Essen an die Tische bringt.\\n\\nKosten: 5.000 €.\\n\\nVoraussetzungen: Techtree G1.3.","A dining room for your guests, which is also used as a breakfast room due to its opening hours."\n')
    elif key == 'tutorial.room_staff_small.desc':
        new_lines.append('tutorial.room_staff_small.desc,"Ein zwingend notwendiger Rückzugsort für deine Angestellten.\\n\\nFunktion: Ohne Personalraum lässt sich gar kein Personal einstellen! Jeder gebaute Personalraum erhöht dein Limit für einstellbares Personal um 4. Zudem verliert Personal durch die Arbeit stetig an Moral. Im Personalraum machen erschöpfte Mitarbeiter Pause, um ihre Moral wieder aufzufüllen. Sinkt die Moral in den Keller, arbeiten sie ineffizient oder stellen die Arbeit komplett ein.\\n\\nKosten: 2.500 €.\\n\\nVoraussetzungen: Level 2 (Personal-Freischaltung).","An absolutely necessary retreat for your employees."\n')
    elif key.startswith('# Toast Messages'):
        new_lines.append('# Toast Messages,,\n')
    elif key.startswith('tutorial.room_list.title'):
        new_lines.append('tutorial.room_list.title,Die Raumliste,The Room List\n')
    elif key.startswith('tutorial.room_list.desc'):
        new_lines.append('tutorial.room_list.desc,"Diese Liste zeigt den Status aller Zimmer: Sauberkeit, Belegung und Zustand.\\nMit der Pip-Cam kannst du den Raum sehen und auch zu ihm springen.","This list shows the status of all rooms: cleanliness, occupancy, and condition.\\nUsing the Pip-Cam, you can view the room and also jump directly to it."\n')
    else:
        new_lines.append(line)

# Remove the bad lines that have no keys but are just trailing text
final_lines = []
for line in new_lines:
    if line.strip() == '' or line.startswith('Funktion:') or line.startswith('Kosten:') or line.startswith('Referenzen zu') or line.startswith('Mit der Pip-Cam') or line.startswith(' Belegung'):
        pass
    else:
        final_lines.append(line)

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(final_lines)
