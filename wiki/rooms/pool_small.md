# Pool (Klein)

## Beschreibung
Der kleine Pool bietet Gästen eine Erholungs- und Freizeitmöglichkeit im Hotel. Er erhöht die Zufriedenheit der Gäste und dient als POI (Point of Interest).

## Funktion & Logik
- **Gäste:** Gäste besuchen den Pool und verbringen Zeit im Wasser. Die Animation für das Schwimmen wird direkt abgespielt, während sie sich im Raum aufhalten.
- **Personal:** Ein Bademeister wird benötigt, um die Sicherheit zu gewährleisten. Der Bademeister patrouilliert am Rand des Pools (auf den trockenen Fliesen) und durchquert nicht das Wasser. Hierfür wird eine spezielle Navigationslogik (`get_patrol_target()`) verwendet.

## Technische Details
- **Raum-ID:** `pool_small`
- **Besonderheiten:**
  - Nutzt `has_method("get_patrol_target")`, um dem Bademeister sichere Wegpunkte am Beckenrand zuzuweisen (oben, unten, links, rechts vom Wasser).
  - Gäste, die den Pool betreten, überspringen das "Menü studieren" und gehen direkt in den Status `IN_POI` über.
