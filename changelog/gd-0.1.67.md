# Changelog v0.1.67

## 🐛 Bugfixes
- **Tagungsgäste Übernachtungs-Fix:** Tagungsgäste wurden fälschlicherweise mit `stay_days = 2` gespawnt. Dies wurde auf `0` korrigiert, damit sie nach dem Event (oder abendlichem Gastro-Besuch) zuverlässig das Hotel verlassen.
- **Konferenzraum Ping-Pong-Loop (Endlosschleife):** Behoben: Gäste haben nach dem Einnehmen eines Platzes im Konferenzraum das interne Flag `_has_claimed_seat` nicht richtig gesetzt bekommen. Beim Aufstehen wurde der Platz dadurch nicht freigegeben, sodass nach und nach alle Plätze durch "Geister" blockiert waren. Neu eintreffende Gäste pendelten daher mangels freier Plätze endlos zwischen Lobby und Konferenzraum.
- **Fehlender Durst/Spaß-Boost bei POIs:** Behoben: Bei POIs wie Pool, Spa oder Gym wurde das `need_restoration`-Dictionary beim Verlassen nicht ausgelesen. Gäste haben dort zwar Zeit verbracht, aber keinen Spaß oder Erschöpfung zurückbekommen. Diese Werte (sowie Durst) werden nun beim Verlassen von Non-Gastro-POIs korrekt angewandt.
- **Gastro-Bestellungen bei reinem Durst:** Behoben: Der `GastroManager` verweigerte Bestellungen an der Bar, wenn ein Gast zwar verdurstet, aber nicht hungrig (`saturation` war hoch) war. Bei der Bestellprüfung wird nun der geringere Wert aus Hunger und Durst (`min(saturation, thirst)`) übergeben, sodass auch reine Durstlöscher-Bestellungen erfolgreich sind.

## ✨ Features
- (Die Vorbereitungen für das Inspektor-System wurden weiter verifiziert und getestet, UI-Modals triggeren korrekt auf fehlende Sauberkeit)
