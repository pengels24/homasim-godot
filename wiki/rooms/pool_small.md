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
    - Überschreibt `get_available_interactions()`, um `"wander"`-Aktionen zu entfernen. Gäste nutzen ausschließlich Liegen oder das Wasser.
  - Der Live-Monitor (`get_live_details()`) iteriert über die Gruppe `guest_actors` (statt `_room_seats`), um auch nicht-sitzende Gäste (im Wasser) korrekt anzuzeigen.
  - Berechnet und zeigt die verbleibende Aufenthaltszeit in Minuten im Live-Monitor an.
  - Gäste, die den Pool betreten, überspringen das "Menü studieren" und gehen direkt in den Status `IN_POI` über.
