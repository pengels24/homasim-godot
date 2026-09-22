# Changelog v0.2.0

## ðŸ› Bugfixes
- **TagungsgÃ¤ste Ãœbernachtungs-Fix:** TagungsgÃ¤ste wurden fÃ¤lschlicherweise mit `stay_days = 2` gespawnt. Dies wurde auf `0` korrigiert, damit sie nach dem Event (oder abendlichem Gastro-Besuch) zuverlÃ¤ssig das Hotel verlassen.
- **Konferenzraum Ping-Pong-Loop (Endlosschleife):** Behoben: GÃ¤ste haben nach dem Einnehmen eines Platzes im Konferenzraum das interne Flag `_has_claimed_seat` nicht richtig gesetzt bekommen. Beim Aufstehen wurde der Platz dadurch nicht freigegeben, sodass nach und nach alle PlÃ¤tze durch "Geister" blockiert waren. Neu eintreffende GÃ¤ste pendelten daher mangels freier PlÃ¤tze endlos zwischen Lobby und Konferenzraum.
- **Fehlender Durst/SpaÃŸ-Boost bei POIs:** Behoben: Bei POIs wie Pool, Spa oder Gym wurde das `need_restoration`-Dictionary beim Verlassen nicht ausgelesen. GÃ¤ste haben dort zwar Zeit verbracht, aber keinen SpaÃŸ oder ErschÃ¶pfung zurÃ¼ckbekommen. Diese Werte (sowie Durst) werden nun beim Verlassen von Non-Gastro-POIs korrekt angewandt.
- **Gastro-Bestellungen bei reinem Durst:** Behoben: Der `GastroManager` verweigerte Bestellungen an der Bar, wenn ein Gast zwar verdurstet, aber nicht hungrig (`saturation` war hoch) war. Bei der BestellprÃ¼fung wird nun der geringere Wert aus Hunger und Durst (`min(saturation, thirst)`) Ã¼bergeben, sodass auch reine DurstlÃ¶scher-Bestellungen erfolgreich sind.

## âœ¨ Features
- (Die Vorbereitungen fÃ¼r das Inspektor-System wurden weiter verifiziert und getestet, UI-Modals triggeren korrekt auf fehlende Sauberkeit)
