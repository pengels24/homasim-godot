# v0.1.42gd (2026-07-23)

## Features & Verbesserungen
- **24/7 Lobby:** Die Lobby ist ab sofort rund um die Uhr geöffnet! Gäste können sich dort jederzeit aufhalten, während die Rezeption weiterhin eigene, feste Öffnungszeiten hat (07:00 - 22:00 Uhr).
- **Checkout-Warteschlange:** Frühaufsteher, die vor 07:00 Uhr auschecken möchten, warten ab sofort brav in der Lobby, bis die Rezeption öffnet.
- **Sinnvolle POI-Upgrades:** Investitionen lohnen sich! WLAN (+1%) und Klimaanlagen (+1%) in POIs (wie Restaurant oder Bar) erhöhen ab sofort bei jedem Besuch passiv die Zufriedenheit der Gäste.
- **Zufriedenheits-Balancing:** Um zu verhindern, dass Gäste zu schnell wunschlos glücklich werden, wurde der Basis-Zufriedenheitsgewinn bei POI-Besuchen leicht gesenkt. (Maximal +4% pro Besuch mit allen Upgrades).
- **Personal-UI Update:** Mitarbeiter, die sich aktuell auf Fortbildung befinden, werden im Personalmenü nun mit einem Buch-Symbol `[📖]` hervorgehoben und für Zuweisungen gesperrt.

## Bugfixes
- **Geister-Küche behoben:** Küchen und Restaurants ignorieren nun korrekt Mitarbeiter, die gerade in Schulung sind. Keine magisch kochenden Pfannen mehr, wenn der Koch im Seminar sitzt!
- **Bestell-Stop:** Gäste können im Restaurant keine Speisen mehr bestellen, wenn die Küche aufgrund von Personalmangel (z.B. Fortbildung) nicht arbeitsfähig ist.
- **Korrektes Map-Icon:** POIs auf der Map leuchten nun sofort rot (unbesetzt) auf, sobald das erforderliche Personal den Raum für eine Schulung verlässt.

## Technische Änderungen
- **Generische Personalprüfung:** Neue zentrale Methode `StaffManager.is_staff_available(staff)`, um Verfügbarkeiten (Training, und zukünftig Krankheit/Urlaub) für alle POIs einheitlich zu prüfen.
- **Rezeptions-Zeiten entkoppelt:** Trennung der Öffnungszeiten-Logik zwischen dem Raum "Lobby" (`open_from: 0`) und der Funktion "Rezeption" (`reception_open_from`).
- **Umfangreiche Tech-Dokus:** 5 neue Wiki-Dokumente für GuestActor, StaffActor, Restaurant, Küche und Bar hinzugefügt, um das KI-Verhalten transparent zu dokumentieren.
