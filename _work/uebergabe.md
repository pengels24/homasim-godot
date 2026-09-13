# Übergabeprotokoll – Session 12.09.2026 (Nachmittag)
> Version: v0.1.52 | Commit: 62360c1 | Nächste Session: Inspector-Test

---

## Letzter Stand

Vollständiger Konferenz-Flow getestet und als stabil bestätigt. Mehrere Bugs gefixt. Inspector-Test steht als nächstes an.

---

## Getestete und bestätigte Features

- ✅ Wander-Vorpuffer, Session-Start, Blickrichtung
- ✅ Speaker-Swap (nach Fix: auch ohne Reload)
- ✅ Mittagspause (Entenmarsch, Bar/Restaurant-Verteilung)
- ✅ Rückkehr aus Pause (13:15), Nachmittagssession
- ✅ End of Day (17:00) – Tagungsraum leer, Gäste verteilen sich/gehen

---

## Was wurde in dieser Session gefixt

1. **ConferenceSmall.gd** – `_on_minute_passed()`: Phase-Setzen jetzt VOR Speaker-Timer-Check (ANG-346)
2. **GuestActor.gd** – `go_conference_break()`: Gastro 3× gewichtet vs. Lobby 1× (weniger Lobby-Hänger)
3. **ModalContentReception.gd** – TG-Gäste (event_poi_id != "") aus Aktive-Gäste-Liste gefiltert
4. **ModalContentFinances.gd** – String-Format-Guard in `_translate_tx_desc()`
5. **language.csv** – `tx.construction,Ausstattung: %s,Equipment: %s` hinzugefügt
6. **ConferenceSmall.gd** – Pausenzeiten: 13:15 Rückkehr, 13:30 Nachmittagsstart
7. **AGENTS.md** – Versions-Regl Direktive (eine Session = eine Version)

---

## Sofortige nächste Schritte (morgen)

### 1. Inspector testen (höchste Priorität)
- Game neu starten (alle heutigen Code-Änderungen laden)
- Neue Tagung starten → nach Tagungsende in DevConsole: `start-inspector`
- Erwarteter Flow: Check-in → POI-Besuche (Restaurant!) → Checkout → Bericht-Modal → Sterne

### 2. Offene Verifikationen nach Reload
- Tagungsgäste in Rezeption: Sollten NICHT mehr auftauchen (event_poi_id-Filter)
- Speaker-Swap: Ohne Reload nach 15 Min testen (frische Tagung, kein Save/Reload dazwischen)
- Mittagspause: Lobby-Hänger sollten deutlich weniger sein (Gastro 3×)

### 3. Offene Issues
- ANG-348: Pre-Alpha Polishing (Badge-Größe, Tagungszahlung, Tutorial)
- ANG-349: Tagungsraum-Limit (max. 1) + Techtree "Parallele Tagungen"
- ANG-345: Hotel-Übersicht (F9) Redesign
- ANG-344: Main Menu Disclaimer-Button

---

## Neue Infrastruktur

- **`wiki/_dev/test_review.md`**: Living-Checklist für offene Testpunkte – immer aktuell halten!
- **`.agents/skills/review/SKILL.md`**: `/review [text]` → trägt Beobachtungen in test_review.md ein
