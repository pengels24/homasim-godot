# Übergabeprotokoll - Version 0.2.1

## Letzter Stand (Session Ende)
Der User steht kurz davor, einen neuen Web-Export für Godot zu erstellen und die neue Version über Butlers hochzuladen. Zuvor wurden Bugfixes für das Baumenü und die Personalübersicht entwickelt und live in der Session erfolgreich getestet.

## Bearbeitete Systeme & Fixes
- **BuildMenu / IngameUIManager:** Ein roter Close-Button (X) wurde im BuildMenu hinzugefügt und der Breadcrumb-Pfeil (>) für Parzellenkauf/Abriss entfernt. Die UIManager Logik wurde angepasst, damit bei einem Close (egal ob per Button oder ESC) das MapGrid den Kauf-Modus (Grid Overlay) zuverlässig abräumt.
- **Personal-System (StaffManager & UI):**
  - Fix für die Fehlermeldung "Personal-Limit", die durch fehlende Formatierung von %s Artefakte anzeigte.
  - Das Einstellen neuen Personals triggert jetzt `StaffManager.sig_staff_hired_or_fired`, was im Personal-Modal die Tab-Header-Anzeige ("Aktuelles Personal (6/8)") in Echtzeit aktualisiert.
- **Lokalisierung:** "Beherberge insgesamt..." Quests wurden sprachlich sauber auf "Checke insgesamt ... aus" korrigiert, um Zähl-Verwirrungen bei Tobis Sohn zu verhindern.

## Sofortige nächste Schritte
- Warten, ob der User Feedback zum Export / dem Upload hat.
- Falls Tobi nach dem Upload noch weitere Bugs meldet (oder der "Butler-Prozess" selbst besprochen wird), diese aufgreifen.
- Nächster regulärer Fokus laut Backlog wäre wahrscheinlich das Social Media (Itch.io PDF / Godot Forum) Announcement für den TechDemo Release oder Alpha-Tasks aus dem Backlog, sobald der aktuelle Build stabil läuft.