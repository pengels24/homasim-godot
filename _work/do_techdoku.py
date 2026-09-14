import os

# Append to GuestActor techdoku
path = "wiki/02_features/25_techdoku_guestactor.md"
with open(path, "a", encoding="utf-8") as f:
    f.write("\n## Gastro Consumption Type\n")
    f.write("- **`consumption_type`**: Gibt an, ob der Gast gerade ein Getränk (`\"drink\"`) oder eine Mahlzeit (`\"food\"`) zu sich nimmt. Wird in `_on_order_served` anhand des Rezept-Typs gesetzt oder auf `\"drink\"` bei Solo-Bestellungen an der Bar.\n")
    f.write("- **Live-Monitor:** Räume wie Bar und Restaurant lesen diesen Typ aus (während der Gast im `State.EATING` ist), um korrekt zwischen *Trinkt gerade* und *Isst gerade* zu unterscheiden.\n")

print("Techdoku updated!")
