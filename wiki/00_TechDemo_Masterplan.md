# 00 - TechDemo Masterplan (Fokus: 30k Streamer First-Impression)

> **Zieldatum:** In ca. 14 Tagen.
> **Oberstes Gebot:** "Scope Creep" vermeiden! Keine neuen Mega-Features mehr. Fokus auf Polish, Core-Loop und Stabilität, damit der erste Eindruck beim Streamer absolut fehlerfrei ist.

---

## 🎨 1. UI / UX Refactoring (Der erste Eindruck)
Das Hauptmenü und die Settings sehen bereits AAA aus. Die alten Menüs müssen auf dieses Niveau gehoben werden.
- [ ] **Dashboard / Hotelliste:** Das alte UI komplett überarbeiten. (Konsistent zu den neuen Modal-Designs machen).
- [x] **Charakter-Editor:** Optisches Upgrade durchgeführt. (Nur noch individuelles Polishing durch den Dev nötig).
- [ ] **Settings - Keybindings:** Die Fake-Buttons mit dem echten `InputMap`-System von Godot verdrahten (WASD umlegen etc.).

## 🎓 2. Onboarding & Spielfluss (Der Streamer darf nicht feststecken)
Die Systeme dafür haben wir gebaut, jetzt müssen die Inhalte rein.
- [ ] **Tutorial-Inhalte:** `tutorials.json` und die CSV-Übersetzungen final befüllen. (Die kontextbasierten Popups reichen für die Demo als Guide völlig aus!)
- [ ] **Techtree-Inhalte:** Die `techtree.json` (oder Tiers) balancen, sodass der Streamer in den ersten 30-60 Minuten einen klaren Fortschritt erlebt.

## 🏨 3. Core-Loop & Wuselfaktor (Das eigentliche Spiel)
- [ ] **Gäste-Lebenszyklus:** Check-In -> Zimmernutzung -> Check-Out -> Geld erhalten. (Sicherstellen, dass das flüssig und ohne Wegfindungs-Hänger funktioniert).
- [ ] **Gäste-Wuselfaktor (Füllmaterial):** Gäste sollen tagsüber zeitversetzt (z.B. alle 10 Ingame-Minuten) kurz ihre Zimmer verlassen und in die Lobby / andere Bereiche gehen, damit das Hotel lebendig wirkt, während die Zeit läuft.
- [ ] **Personal-Loop (Reinigungskraft):** Wenn der Gast geht, wird das Zimmer schmutzig. Eine Reinigungskraft muss es putzen, bevor es neu vergeben wird. (Zeigt dem Streamer perfekt, wie das Personal-System funktioniert!).
- [ ] **Save / Load Stabilität:** Ausführlich testen, ob wirklich *alles* (Zimmer, Türen, Tutorials, Quests, FP) fehlerfrei speichert und lädt.

## 🐞 4. QA & Polishing (Die Kirsche auf der Torte)
- [x] **Bug-Reporter:** Globaler Ingame-Button mit Discord-Webhook-Anbindung. *(Erledigt!)*
- [ ] **Sound & Feedback:** Zufriedene "Kaching"-Sounds beim Geldverdienen, Klick-Sounds im UI, leises Murmeln in der Lobby. (Unglaublich wichtig für Stream-Atmosphäre!).
- [ ] **Balancing:** Geld- und FP-Kosten so einstellen, dass man in der Demo weder nach 5 Minuten unendlich reich ist, noch stundenlang warten muss.

---
*Dieser Plan ist unser Filter. Wenn wir eine neue Idee haben, fragen wir uns: "Steht es auf dem Masterplan für die Demo?" Wenn nicht -> auf die Post-Release Ideenliste!*
