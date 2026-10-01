---
name: new_release
description: Automatisiert den administrativen Release-Workflow (Patch-Notes für Discord/Itch.io, Social Media Post, Website Devlog).
---

# New Release Workflow

Wenn der User diesen Skill aufruft, arbeite folgende Schritte **streng sequenziell** ab. 
Der Skill nimmt dem User die Erstellung aller Social-Media- und Changelog-Texte für ein neues Release ab.

1. **Versionierung & Changelog sichten:**
   - Lies die Datei `version.txt` aus dem Projekt-Root, um die Ziel-Version zu ermitteln (z.B. `v0.2.2`).
   - Öffne und lies die entsprechende Changelog-Datei unter `changelog/gd-<version>.md`, um den Kontext für die Texte zu erfassen.
   - Stelle sicher, dass der Ordner `_releases/` im Root existiert (falls nicht, anlegen).

2. **Discord Patch-Notes (Deutsch) erstellen:**
   - Erstelle eine zusammenfassende, lesefreundliche Markdown-Datei für Discord.
   - **Regeln:** Max 2000 Zeichen. Nutze stichpunktartige, knackige Bulletpoints. **WICHTIG: Tonfall ist immer Ego-Perspektive (Solo-Dev: "Ich", "Mein", "Mir" statt "Wir").** Nutze Emojis. Erwähne den Download-Link (`https://angelus2010.itch.io/homasim-hotel-manager-simulation`).
   - Speichere die Datei unter `_releases/discord_patchnotes_<version>.md`.

3. **Itch.io Patch-Notes (Englisch) erstellen:**
   - Erstelle eine detaillierte englische Version (kein Längenlimit). Der Text muss den kompletten Changelog widerspiegeln.
   - **WICHTIG: Tonfall ist Ego-Perspektive (Solo-Dev: "I", "My").**
   - Speichere die Datei unter `_releases/itch_patchnotes_<version>.md`.

4. **Social Media Post (X / Bluesky, Englisch) erstellen:**
   - Schreibe einen knackigen Teaser-Post für den Release (max. 280 Zeichen).
   - **Pflicht-Tags:** `#indiedev #gamedev #GodotEngine #godot4 #indiegame` (plus 2-3 thematisch passende wie `#tycoon` oder `#management`).
   - Nutze den Download-Link.
   - Speichere die Textdatei unter `_releases/social_post_<version>.txt`.

5. **Website Devlog updaten (DE & EN):**
   - Das Website-Projekt liegt in einem **anderen Pfad**: `D:\entwicklung\homa\src\data\`.
   - Schreibe ein Python-Skript im Ordner `_work/` (z.B. `update_devlog.py`), welches die beiden Dateien `devlog.json` und `devlog_en.json` einliest, jeweils ganz unten (per `append()`) den neuen Versionseintrag hinzufügt und wieder speichert.
   - Der Inhalt für die Website sollte den vollen Changelog (unbegrenzte Länge) in der Ich-Perspektive enthalten!
   - **JSON Format:**
     ```json
     {
         "date": "YYYY-MM-DD",
         "title": "Patch Notes - v0.2.2 (Hotfix & Polishing)",
         "text": "Intro-Text.\n\nBugfixes & Verbesserungen:\n- Bereich: Änderung 1\n- Bereich: Änderung 2",
         "youtube": "",
         "image": ""
     }
     ```
   - **Wichtig für die Formatierung:** Nutze im `"text"`-Feld echte Zeilenumbrüche per `\n` und gliedere die Änderungen in Bullet-Points (`- `), damit es professionell lesbar bleibt (keine Textblöcke!).
   - Führe das Python-Skript per `run_command` aus.

6. **Abschlussbericht:**
   - Melde dem User kurz und bündig zurück, dass alle Dateien im Ordner `_releases/` bereitliegen und die Webseite aktualisiert wurde.
