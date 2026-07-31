import os

path = 'd:/game-dev/homasim-godot/translations/language.csv'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix W1.1 bonus
content = content.replace(
    "ui.techtree.feature.w1_1_bonus,+10 Start-Zufriedenheit,+10 Starting Satisfaction",
    "ui.techtree.feature.w1_1_bonus,+5% Start-Zufriedenheit,+5% Starting Satisfaction"
)

# Fix W1.2 title
content = content.replace(
    "techtree.wellness.w1_2,Außenbereich,Outdoor Area",
    "techtree.wellness.w1_2,Hallenbad,Indoor Pool"
)

# Fix W1.3 title
content = content.replace(
    "techtree.wellness.w1_3,Premium-Spa,Premium Spa",
    "techtree.wellness.w1_3,Premium-Spa / Sauna,Premium Spa / Sauna"
)

# Fix WLAN and Klima descriptions
content = content.replace(
    "techtree.zimmer.wlan.desc,Schaltet das WLAN-Upgrade für Gästezimmer frei.,Unlocks the WIFI upgrade for guest rooms.",
    "techtree.zimmer.wlan.desc,Bleibe immer verbunden. Schnelles Internet ist heutzutage ein Muss. Kann als Upgrade in Gästezimmern und öffentlichen Räumen (POI) installiert werden.,Always stay connected. Fast internet is a must nowadays. Can be installed as an upgrade in guest rooms and public areas (POI)."
)

content = content.replace(
    "techtree.zimmer.klima.desc,Schaltet das Klimaanlagen-Upgrade für Gästezimmer frei.,Unlocks the Air Conditioning upgrade for guest rooms.",
    "techtree.zimmer.klima.desc,Ein kühler Kopf an heißen Tagen. Eine angenehme Raumtemperatur sorgt für Höchstwertungen. Kann als Upgrade in Gästezimmern und öffentlichen Räumen (POI) installiert werden.,A cool head on hot days. A pleasant room temperature ensures top ratings. Can be installed as an upgrade in guest rooms and public areas (POI)."
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Leftovers fixed.")
