import os
import codecs

with codecs.open("wiki/02_features/25_techdoku_guestactor.md", "r", encoding="utf-8", errors="ignore") as f:
    content = f.read()

content += "\n\n### Zwangspause nach POI-Besuch (ANG-361)\nUm zu verhindern, dass Gäste hektisch von POI zu POI rennen, wurde eine Zwangspause implementiert. Beim Verlassen eines beliebigen POIs (inklusive Lobby) wird `_poi_rest_until` gesetzt. Solange dieser Timer aktiv ist, werden alle `open_pois` blockiert, wodurch der Gast zwingend auf sein Zimmer geht und dort über `_wander_in_room()` die Zeit absitzt. Einzig enormer Hunger (`< HUNGER_THRESHOLD`) kann diese Zwangspause überschreiben, sofern sich der Gast noch eine Mahlzeit leisten kann.\n"

with codecs.open("wiki/02_features/25_techdoku_guestactor.md", "w", encoding="utf-8") as f:
    f.write(content)

print("Tech-Doku updated!")
