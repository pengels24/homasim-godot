## Version: 0.1.31
**Datum: 2026-06-28**

### Features & Verbesserungen

- **Gästeliste (F2)**: Der Aufenthaltsort von Gästen, die sich gerade in einer Aktivität befinden, wird nun detaillierter angezeigt (z.B. "in Bar/Lounge B0001" statt nur "Aktivität" oder "POI").
- **POI-Tooltips**: Beim Hovern über einen POI (z.B. Bar) wird nun die korrekte Anzahl der anwesenden Gäste sowie deren Namen aufgelistet. Der Bug, dass der Zähler trotz anwesender Gäste auf 0 blieb, wurde behoben.
- **Forschung & Technologie (F5)**: Bereits freigeschaltete Technologien zeigen in ihrem Tooltip nun übersichtlich den Text "- Bereits erforscht -" an, anstatt weiterhin die (bereits erfüllten) Kosten und Abhängigkeiten aufzulisten.

### Bugfixes

- `CustomTooltip.gd`: Fix für den POI-Gästezähler. Dieser suchte fälschlicherweise nach Gästen, deren Ziel-POI-ID der Raum-ID entsprach. Der Abgleich erfolgt nun korrekt über die ID der Raum-Definition.
- `ModalContentTechtree.gd`: Fallback für den `- Bereits erforscht -`-String implementiert, um Caching-Probleme der Godot-Übersetzungsengine beim Live-Reload abzufangen.

### Technische Änderungen

- `ModalContentGuestList.gd`: Anpassung der Status-Strings in `_refresh_live_data` und der initialen Listen-Generierung zur dynamischen Namensauflösung der POIs.
- `translations/de.csv`: Neuer Übersetzungsschlüssel `ui.techtree.tooltip.already_unlocked` hinzugefügt.
- Agenten-Regelwerk (`AGENTS.md`) bereinigt und von veralteten `Nächste Schritte`-Einträgen befreit, um saubere Folge-Sessions zu gewährleisten.
