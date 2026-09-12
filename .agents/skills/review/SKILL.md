---
name: review
description: >-
  Fügt einen Beobachtungs- oder Testergebnis-Eintrag in wiki/_dev/test_review.md ein.
  Aufruf: /review [text] – der Agent formatiert den Eintrag und trägt ihn in die
  passende Sektion ein (oder legt eine neue Sektion an).
---

# Review-Eintrag hinzufügen

Du wurdest mit `/review [text]` aufgerufen. Der Nutzer möchte einen Beobachtungspunkt, ein Testergebnis oder eine Notiz in `wiki/_dev/test_review.md` eintragen.

## Schritt 1 – Datei lesen

Lies zuerst den aktuellen Stand der Datei:
```
view_file: d:\game-dev\homasim-godot\wiki\_dev\test_review.md
```

## Schritt 2 – Eintrag analysieren

Interpretiere den Text des Nutzers und bestimme:
- **Status:** `[x]` = bestätigt/erledigt | `[~]` = in Beobachtung/läuft | `[ ]` = offen/fehlt
- **Sektion:** Zu welchem Feature-Bereich gehört der Eintrag? (Konferenz, Inspektor, Hotel-Übersicht, Bau, Polishing – oder neue Sektion anlegen)
- **Formulierung:** Schreibe den Eintrag präzise im Stil der vorhandenen Einträge:
  - Fett: Kurzer Titel (max. 5 Wörter)
  - Danach: kurze Erklärung + ggf. Datum (TT.MM.JJJJ) + ggf. Issue-Referenz (ANG-xxx)
  - Beispiel: `- [x] **Speaker-Swap ohne Reload:** Fix bestätigt, feuert nach 15 Min. (12.09.2026)`

## Schritt 3 – Eintrag einfügen

Füge den Eintrag in die passende Sektion ein via `replace_file_content` oder `multi_replace_file_content`.
- Neue bestätigte Einträge (`[x]`) ans Ende der Sektion.
- Offene Einträge (`[ ]`) ans Ende der Sektion.
- In-Beobachtung (`[~]`) direkt nach dem verwandten `[x]` Eintrag.

## Schritt 4 – Bestätigung

Antworte kurz mit dem eingefügten Eintrag (1 Zeile) damit der Nutzer weiss was eingetragen wurde.
Kein langer Text, keine Erklärungen – nur die Bestätigung.

## Stil-Regeln

- Immer Datum in Klammern wenn ein Test heute stattgefunden hat
- ANG-Referenz wenn ein Issue existiert
- Keine langen Sätze – Stichpunkte
- Wenn der Nutzer Status-Keyword nennt ("ok", "geht", "funktioniert", "bestätigt" → `[x]`; "problem", "fehler", "bug" → `[ ]`; "beobachte", "nächste tagung" → `[~]`)
