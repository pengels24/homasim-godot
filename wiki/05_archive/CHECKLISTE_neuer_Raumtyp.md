# HO·MA·SIM – Checkliste: Neuen Raumtyp hinzufügen

> Jedes Mal wenn ein neuer Raumtyp angelegt wird, müssen diese Dateien angefasst werden.
> Beispiel-Key: `bed_deluxe`

---

## Pflicht (immer)

### 1. `src/Config/RoomDefinitions.php`
Hauptdefinition des Raumtyps. Hier wird alles festgelegt.

```php
'bed_deluxe' => [
  'name'            => T('roomdef.name.long.bed_deluxe'),
  'label'           => T('roomdef.name.short.bed_deluxe'),
  'cost'            => 2000,
  'price_per_night' => 200,
  'width'           => 2,
  'height'          => 2,
  'capacity'        => 2,
  'has_door'        => true,
  'requires_access' => true,
  'icon'            => 'star',
  'style_class'     => 'bed_deluxe',
  'number_prefix'   => 'Z',
  'sleeping_room'   => true,
  'is_walkable'     => true,
  'is_buildable'    => true,  // false = nur system-intern, nicht baubar
  'xp_reward'       => 30
],
```

---

### 2. `src/Language/homasim_de.php`
Übersetzungen für langen und kurzen Namen.

```php
'roomdef.name.long.bed_deluxe'  => 'Deluxe-Zimmer',
'roomdef.name.short.bed_deluxe' => 'DX',
```

---

### 3. `src/scss/_tiles.scss`
CSS-Klasse für die visuelle Darstellung auf dem Grid.

```scss
.tile.bed_deluxe {
  background-color: #c0a060;
  // weitere Styles...
}
```

---

### 4. Datenbank: `technology_unlocks`
Eintrag welche Technologie diesen Raumtyp freischaltet.

```sql
INSERT INTO `technology_unlocks` (`technology_id`, `room_type_key`)
SELECT id, 'bed_deluxe' FROM `technologies` WHERE `key` = 'zimmer_2';
```

→ Migration-Datei anlegen unter `migrations/` oder direkt eintragen.

---

## Bedingt (je nach Raumtyp)

### 5. `src/Config/GuestDefinitions.php`
Nur wenn Gäste diesen Raumtyp bevorzugen sollen.

```php
'preferred_rooms' => ['bed_deluxe', 'bed_superior'],
```

---

### 6. `src/Controllers/HotelController.php`
Nur wenn der Raumtyp spezielle Logik braucht, z.B.:
- Zufriedenheits-Berechnung beim Check-out (`$guestType === 'couple' && $roomType === 'bed_deluxe'`)
- Spezielle Buchungsregeln
- Sonderbehandlung beim Bau

---

### 7. `assets/js/modules/BuildManager.js`
Nur wenn der Raumtyp spezielle Bau-Logik braucht, z.B.:
- Kompatibilitätsprüfung mit Gast-Typen
- Spezielle Platzierungsregeln

---

## Kurzübersicht

| Datei | Immer? | Wofür |
|---|---|---|
| `RoomDefinitions.php` | ✅ | Definition, Größe, Kosten, Eigenschaften |
| `homasim_de.php` | ✅ | Name (lang + kurz) |
| `_tiles.scss` | ✅ | Visuelle Darstellung auf dem Grid |
| `technology_unlocks` (DB) | ✅ | Freischaltung via Technologiebaum |
| `GuestDefinitions.php` | ⚠️ | Nur wenn Gäste den Raum bevorzugen |
| `HotelController.php` | ⚠️ | Nur bei spezieller Buchungs-/Check-out-Logik |
| `BuildManager.js` | ⚠️ | Nur bei spezieller Bau-Logik |

---

## Hinweis zu `is_buildable`

- `true` → Raumtyp erscheint im Bau-Menü (nach Freischaltung via Technobaum)
- `false` → Raumtyp ist system-intern (z.B. `foundation`, `sidewalk`) – nie im Bau-Menü

---

*Stand: März 2026 | HO·MA·SIM Entwicklungsdokumentation*
