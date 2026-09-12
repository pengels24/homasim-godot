# gd-0.1.52 – Session 12.09.2026 (Nachmittag)

> Branch: `dev` | Umfang: Konferenz-Tests, Speaker-Swap-Fix, Inspector-Vorbereitung, Polishing-Fixes

---

## 🐛 Bugfixes

- **ConferenceSmall Speaker-Swap (ANG-346):** Reihenfolge in `_on_minute_passed()` getauscht – Phase wird nun VOR dem Speaker-Timer-Check gesetzt. Vorher: Phase noch auf `"wander"` wenn Swap-Check lief → `_speaker_time` zählte nie. Fix: Swap feuert jetzt korrekt nach 15 Ingame-Minuten ohne vorherigen Reload.
- **Tagungsgäste in Rezeption:** TG-Gäste (mit `event_poi_id != ""`) werden nun aus der Aktive-Gäste-Liste der Rezeption gefiltert (`ModalContentReception.gd`). Vorher: TG-Gäste erschienen als reguläre Übernachtungsgäste mit "Noch 2 Nächten".
- **Mittagspause Lobby-Hänger:** `go_conference_break()` in `GuestActor.gd` – Gastro-POIs jetzt 3× gewichtet vs. 1× Lobby. Vorher: ~33% Chance auf Lobby, obwohl Bar (8 Plätze) + Restaurant (20 Plätze) genug Kapazität für alle TG-Gäste bieten.
- **ModalContentFinances String-Format-Crash:** Guard in `_translate_tx_desc()` – wenn übersetzter Key kein `%s` enthält, wird Parameter via Leerzeichen angehängt statt Crash. Verhindert 163 Errors beim Öffnen des Kassenbuchs.
- **tx.construction fehlender Translation-Key:** `language.csv` ergänzt – `tx.construction,Ausstattung: %s,Equipment: %s`. Betrifft WLAN/Klima-Transaktionen aus `RoomContextMenu.gd`.

## ✨ Features / Verbesserungen

- **AGENTS.md Versions-Regl:** Neue Pflicht-Direktive – eine Dev-Session = eine Version. Tagesstart: bestehende Version weiterführen. Tagesende: `/update_doku +v`.
- **Konferenz-Pausenzeiten angepasst:** `TIME_BREAK_END` 13:45 → 13:15, `TIME_SESSION_PM_START` 14:00 → 13:30. Verhindert langes Lobby-Idle nach Mittagessen.
- **ConferenceSmall TIME_END-Handling:** `_on_minute_passed()` enthält jetzt expliziten `TIME_END`-Case mit `_broadcast_to_event_guests("end_conference_day")`.

## 📋 Neue Linear-Issues

- **ANG-346** (Done): Bug – ConferenceSmall Speaker-Swap löst nicht aus
- **ANG-347** (Done/Not-a-Bug): Bug – Luxury-Gast ohne Superior-Zimmer (Superior vorhanden aber belegt)
- **ANG-348**: Pre-Alpha Polishing – Sammel-Issue (Badge-Größe, Tagungszahlung, Tutorial, TG-Label)
- **ANG-349**: Feature – Tagungsraum-Limit (max. 1) + Techtree "Parallele Tagungen" (Tier 2)

## 📄 Doku / Infrastruktur

- **`wiki/_dev/test_review.md`** neu angelegt – Living-Checklist für offene Test- und Beobachtungspunkte
- **`.agents/skills/review/SKILL.md`** neu – `/review [text]` Skill zum Eintragen in test_review.md
- **`wiki/_dev/test_review.md`** aktualisiert – End-of-Day, TG-Label, Konferenz-Flow-Status

## ✅ Getestete Features (Session 12.09.2026)

- Wander-Vorpuffer (07:45–08:00) ✅
- Session-Start + Blickrichtung zum Speakertable ✅
- Speaker-Status im Live-Monitor ✅
- Mittagspause 12:00 (Entenmarsch) ✅
- Verteilung auf Bar/Restaurant ✅
- Rückkehr aus Pause (13:45, neu: 13:15) ✅
- Nachmittagssession + Speaker-Swap ✅
- End of Day 17:00 – Tagungsraum leer ✅
- TG-Gäste verteilen sich auf Bar/Ausgang ✅
