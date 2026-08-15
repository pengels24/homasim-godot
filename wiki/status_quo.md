# Status Quo - HO·MA·SIM Godot
> Übersicht über alle integrierten und fertiggestellten Systeme im Spiel. Dies ist KEIN Changelog, sondern eine Inventar-Liste des aktuellen Funktionsumfangs.

## 🏢 Räume & Einrichtungen
- [x] **Lobby / Rezeption:** Gäste checken ein und aus.
- [x] **Gästezimmer:** Funktionieren. 4 Kategorien integriert (`Standard`, `Double`, `Family`, `Superior`). Inklusive Betten, Bad, Schmutz, Reparatur-Status und Gästebedürfnissen.
- [x] **Personalraum:** Funktioniert (`staff_small`). Personal regeneriert Moral.
- [x] **Küche:** Funktioniert (`kitchen_small`). Nimmt Bestellungen an und kocht.
- [x] **Restaurant:** Funktioniert (`restaurant_small`). Gäste essen und zahlen.
- [x] **Bar:** Funktioniert (`bar`). Gastro-Loop aktiv.
- [x] **Pool:** Funktioniert (`pool_small`). Gäste entspannen und baden. Bademeister patrouilliert.
- [x] **Gym:** Funktioniet (`gym_small`). Fitness-Angebote mit Intervall-Platzwechsel.
- [x] **Spa / Sauna:** Funktioniert (`spa_small`). Wellness-Angebote mit Intervall-Platzwechsel.
- [] **Konferenzraum:** Funktioniert (`conference_small`). Tagesgäste (Business) halten und hören Vorträge.

## 🧑‍🤝‍🧑 Akteure & KI
- [x] **Gäste:** Checken ein, nutzen POIs (Essen/Trinken), haben Bedürfnisse (WLAN etc.), zahlen, checken aus.
- [x] **Geduldssystem:** Gäste haben einen Geduldsfaden. Warten sie zu lange (z. B. auf Essen), brechen sie die Aktion ab und verlieren Zufriedenheit.
- [x] **Reinigungskraft:** Putzt Zimmer automatisch nach Checkout (`housekeeping`).
- [x] **Hausmeister:** Repariert kaputte Objekte (`maintenance`).
- [x] **Barkeeper:** Betreut die Bar und mixt Getränke (`bartender`).
- [x] **Koch:** Bereitet Mahlzeiten in der Küche zu (`chef`).
- [x] **Küchenhilfe:** Unterstützt den Koch (`kitchen_helper`).
- [x] **Bedienung:** Bringt Essen von der Küche ins Restaurant/Bar (`waiter`).
- [x] **BademeisterIn:** Beobchtet den Pool und sorgt für Ordnung (`lifeguard`).
- [x] **Spa-Fachkraft:** Bedient die Gäste im Spa / Sauna (`wellness_counselor`).

## ⚙️ Core-Systeme & Mechaniken
- [x] **Visuelle Simulation (Wusel-Faktor):** Keine reine Tabellen-Verwaltung! Alle Gäste und Mitarbeiter bewegen sich physisch durch das Hotel, navigieren durch Räume, nutzen Objekte und füllen das Spiel sichtbar mit Leben.
- [x] **Finanzen:** Einnahmen (Gastro/Zimmer) & Ausgaben (Gehalt/Baukosten) werden abgerechnet.
- [x] **Zeit-System:** Tag/Nacht-Zyklus, Fast-Forward, Pausieren funktioniert.
- [x] **Bausystem:** Räume können platziert und abgerissen werden.
- [x] **Parzellen / Map-Expansion:** Kauf neuer Map-Flächen funktioniert (inkl. Bau-Timer und Screen-Space-UI).
- [x] **Techtree:** Grundgerüst (Forschungspunkte, Level-Gates) steht und schaltet Features frei.
- [x] **Moral-System:** Personal verliert Moral bei Überarbeitung, kündigt bei 0, regeneriert im Personalraum.
- [x] **Level & EXP:** EXP-Bedarf steigt exponentiell bis Level 10. Startschwierigkeit (Boost) ist wählbar.
- [x] **Soundsystem:** Hintergrundmusik (Playlist via JSON) und situative Sounds (Türklappern, Besen, Schraubenschlüssel, etc.) sind implementiert.

## 📊 UI & Management-Tools
- [x] **Gästeliste:** Übersicht aller aktuellen Gäste inkl. Filter, Live-Vorschau (PiP) und Kamera-Sprung zum Gast.
- [x] **Raumliste:** Übersicht aller Räume (Zustand, Sauberkeit) inkl. Live-Vorschau (PiP) und Kamera-Sprung.
- [x] **Personalverwaltung:** Übersichtliches Menü zum Einstellen, Entlassen, Weiterbilden und Zuweisen von Mitarbeitern auf bestimmte Räume.
- [x] **Questbook:** Verfolgt und belohnt aktive Meilensteine und Ziele (z. B. "Beherberge 25 Geschäftsreisende").
- [x] **Tutorialsystem & Codex:** Kontext-sensitive Erklärungen bei neuen Features sowie ein Lexikon zum Nachschlagen aller Mechaniken.
- [x] **Activity Log:** Chronologisches Protokoll aller wichtigen Ereignisse im Hotel (Level-Ups, Defekte, Abreisen).
- [x] **Live-Monitore für POI:** Separate verschiebbare Fenster mit Aktivitäten und Gästelisten des jeweiligen POI.
