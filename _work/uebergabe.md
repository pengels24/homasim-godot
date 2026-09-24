# Übergabeprotokoll (Ende v0.2.0)

## Exakter letzter Stand
- **Inspektor-System (Gourmetsterne):** Das Inspektor-Event wurde auf Funktionalität geprüft und triggert korrekt (UI Modal öffnet sich). Text-Probleme im UI-Modal wurden behoben (`language.csv` Strings angepasst). Die Inspektorin prüft das Hotel und scheitert momentan am Sauberkeitswert (wie erwartet).
- **Tagungsgäste-Bugfixes:**
  - Tagungsgäste hatten bisher fälschlicherweise `stay_days = 2`. Das wurde auf `0` gesetzt, damit sie das Hotel nicht mehr über Nacht blockieren.
  - Im Konferenzraum (`ConferenceSmall.gd` / `GuestActor.gd`) haben Tagungsgäste beim Hinsetzen ihr `_has_claimed_seat` Flag nicht mehr gesetzt, weshalb die Plätze nach dem Aufstehen nicht freigegeben wurden. Das führte zu "Geister"-Belegungen und einer Endlosschleife (Ping-Pong-Gehen zwischen Lobby und Tür), wenn Gäste zurück in den Raum wollten. Dies ist repariert.
- **POI Restoration Bug (Wellness/Pool/Gym):**
  - Die `need_restoration` Werte für Erschöpfung, Spaß und Durst wurden bisher in `GuestActor.gd` nur für Gastro-Räume (via `sat` von Recipes) angewendet. Dies wurde repariert, sodass Gäste nun beim Verlassen von z.B. Pool oder Gym ihren Boost bekommen.
- **Gastro-Bestellungen (Bar):**
  - Gäste, die nur durstig, aber nicht hungrig waren, konnten nichts bestellen, da `GastroManager.try_gastro_order` nur den `saturation` Wert ausgewertet hat. `GuestActor.gd` übergibt nun `min(saturation, thirst)`, wodurch reine "Durstlöscher"-Bestellungen wieder funktionieren.

## Betroffene Systeme (Refactored/Bearbeitet)
- `GuestActor.gd`: POI-Restoration-Logik, Gastro-Parameter, Claim-Seat-Flag.
- `GuestManager.gd`: Tagungsgäste Spawn-Logik (`stay_days`).
- Techdokus (`25_techdoku_guestactor.md`) & `alpha_backlog.md` aktualisiert.

## Nächste Schritte für den Agenten
1. **Inspektor-Anforderungen (Balancing):** Der User plant wahrscheinlich, die Sauberkeit oder weitere Anforderungen für den Inspektor zu balancen oder das Feature weiter auszubauen. Da der Inspektor wegen 73,9% Sauberkeit abgelehnt hat, könnte dies das nächste Thema sein.
2. **Weitere Alpha-Backlog Tasks:** Es gibt noch einige verbleibende Bugs oder Features im `alpha_backlog.md`, die aus Phase 5 angegangen werden können (z.B. Zufallsereignisse).
3. **Keine offenen kritischen Bugs bekannt.** Die Dev-Session kann mit einem neuen Feature gestartet werden. Lese bei Start den `alpha_backlog.md` und `status_quo.md` ein, falls du eine Übersicht brauchst.