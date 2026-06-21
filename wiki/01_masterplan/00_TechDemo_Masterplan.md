# 00 - TechDemo Masterplan (Fokus: 30k Streamer First-Impression)

> **Zieldatum:** In ca. 14 Tagen.
> **Oberstes Gebot:** "Scope Creep" vermeiden! Keine neuen Mega-Features mehr. Fokus auf Polish, Core-Loop und Stabilität, damit der erste Eindruck beim Streamer absolut fehlerfrei ist.

---

## 🎨 1. UI / UX Refactoring (Der erste Eindruck)
Das Hauptmenü und die Settings sehen bereits AAA aus. Die alten Menüs müssen auf dieses Niveau gehoben werden.
- [x] **Dashboard / Hotelliste:** 
  - [x] Altes UI entfernen/deaktivieren.
  - [x] Neues Design konsistent zu den Modal-Designs implementieren.
  - [x] Thumbnails der Savegames korrekt einbinden (Der `SaveManager` speichert sie bereits!).
- [x] **Charakter-Editor:** 
  - [x] Optisches Upgrade durchgeführt. (Nur noch individuelles Polishing durch den Dev nötig).
- [ ] **Settings - Keybindings:** 
  - [ ] Fake-Buttons im UI durch interaktive Input-Listener ersetzen.
  - [ ] Godots `InputMap` anbinden (Speichern & Laden der Tastenbelegungen).

## 🎓 2. Onboarding & Spielfluss (Der Streamer darf nicht feststecken)
Die Systeme dafür haben wir gebaut, jetzt müssen die Inhalte rein.
- [ ] **Tutorial-Inhalte:** 
  - [ ] `tutorials.json` finalisieren (Welche Popups erscheinen wann?).
  - [ ] Texte für Tutorials in der CSV-Übersetzung hinterlegen.
  - [ ] Trigger-Events im Code für die Tutorials sicherstellen (z.B. "Erster Raum gebaut").
- [ ] **Techtree-Inhalte (Balancing):** 
  - [ ] Kosten (Geld/FP) in der `techtree.json` für den frühen Spielverlauf anpassen.
  - [ ] Voraussetzungen (Zimmer) so anpassen, dass man nicht feststeckt.
  - [x] Abgleich mit dem Konzept (via ANG-204 erledigt).

## 🏨 3. Core-Loop & Wuselfaktor (Das eigentliche Spiel)
- [x] **Gäste-Lebenszyklus:** 
  - [x] Check-In (Zuweisung zu einem freien Zimmer).
  - [x] Navigation (Pathfinding) vom Spawner zum Zimmer.
  - [x] Zimmernutzung (Zeit im Zimmer verbringen).
  - [x] Check-Out (Zimmer verlassen, Geld & EXP generieren, Despawn).
- [x] **Gäste-Wuselfaktor (Füllmaterial):** 
  - [x] Idle-Logik: Gäste verlassen tagsüber zufällig ihr Zimmer.
  - [x] Navigation zu einem Point of Interest (Lobby / Garten).
  - [x] Kurze Wartezeit am Zielort und anschließende Rückkehr aufs Zimmer.
- [x] **Personal-Loop (Reinigungskraft):** 
  - [x] Trigger: Check-Out setzt Zimmer-Sauberkeit herunter (`is_service_requested = true`).
  - [x] TaskManager generiert eine Reinigungs-Aufgabe am schwarzen Brett.
  - [x] KI: Personal (Servicekraft) geht zum Zimmer.
  - [x] KI: Personal führt Reinigung durch (Timer) -> Zimmer wieder grün.
- [x] **Save / Load Stabilität:** 
  - [x] Gäste-Zustände beim Speichern/Laden sauber wiederherstellen (inkl. korrekter Position auf dem Flur oder an der Rezeption).
  - [x] Laufende Tasks und das Schwarze Brett (Tickets) korrekt speichern/laden (Ticket-Duplikate beseitigt).

## 🐞 4. QA & Polishing (Die Kirsche auf der Torte)
- [x] **Bug-Reporter:** Globaler Ingame-Button mit Discord-Webhook-Anbindung. *(Erledigt!)*
- [ ] **Sound & Feedback:** 
  - [ ] "Kaching"-Sound beim Check-Out / Geldeingang einbauen.
  - [ ] Klick-Sounds für die wichtigsten UI-Buttons.
  - [ ] Atmosphärischer Background-Loop (leises Murmeln in der Lobby).
- [ ] **Balancing Feinschliff:** 
  - [ ] Test-Run: Kann der Streamer in 45 Minuten ein ordentliches Hotel mit 3-4 Zimmertypen und erster Forschung aufbauen?

---
*Dieser Plan ist unser Filter. Wenn wir eine neue Idee haben, fragen wir uns: "Steht es auf dem Masterplan für die Demo?" Wenn nicht -> auf die Post-Release Ideenliste!*
