# HO·MA·SIM – Personal & Aufgabensystem (Modding-Zusatz)

_Zusatzdokument: Externe Datenstruktur & Mod-Support_ 
_Stand: 15.06.2026_

## 1. Datenarchitektur: Core vs. Mod

Alle Berufe und Personaltypen werden über eine zentrale Registry (`StaffRegistry`) verwaltet. Um Modding zu ermöglichen und gleichzeitig die Systemstabilität zu garantieren, wird strikt zwischen internen und externen Daten getrennt.

- **Core-Daten (`is_core: true`):** Werden zuerst geladen. Stammen aus dem Hauptspiel.
- **Mod-Daten (`is_core: false`):** Werden in Ladestufe 2 aus dem Ordner `user://mods/` geladen.

## 2. Struktur einer externen Personal-JSON (`staff.json`)

Ein Modder kann über eine JSON-Datei neue Berufe definieren. Das System parst diese Datei und fügt sie der Registry hinzu.

**Beispiel-JSON (Mod):**

```json
{
  "mod_id": "my_spa_expansion",
  "staff_types": [
    {
      "id": "staff_yoga_instructor",
      "name": "Yoga-Lehrkraft",
      "category": "wellness",
      "daily_salary": 115,
      "unlocked_by_tech": "W_MOD_YOGA_1", 
      "base_skills": {
        "charisma": 5,
        "motivation": 3,
        "stress_resistance": 8
      },
      "department_skills": [
        "relaxation_technique",
        "guest_animation"
      ],
      "tasks_handled": ["yoga_class", "meditation_session"]
    }
  ]
}
```

## 3. Sicherheitsregeln beim Parsen

1. **ID-Validierung:** Das System prüft beim Einlesen der Mod, ob die Job-ID bereits in den Core-Daten existiert. Ist das der Fall, wird der Mod-Eintrag ignoriert und ein Konsolen-Fehler ausgeworfen (verhindert das Überschreiben von System-Berufen).
2. **Kategorien-Erweiterung:** Gibt ein Modder eine `category` an, die noch nicht existiert (z.B. `security`), erstellt das UI dynamisch einen neuen Reiter in der Personalverwaltung.
