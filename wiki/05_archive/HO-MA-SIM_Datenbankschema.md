# HO·MA·SIM – Datenbankschema

> Stand: 03.03.2026 | Basis: SQL-Dump vom 03.03.2026

---

## Übersicht der Tabellen

| Tabelle | Beschreibung | Status |
|---|---|---|
| `users` | Spieler-Accounts | ✅ Vorhanden |
| `hotels` | Hotel-Daten inkl. Level, XP, Geld | ✅ Vorhanden |
| `rooms` | Gebaute Räume auf dem Grid | ✅ Vorhanden |
| `guests` | Gäste mit Status und Zufriedenheit | ✅ Vorhanden |
| `managers` | Manager-Profil pro Hotel | ✅ Vorhanden |
| `staff` | Personal mit Rolle, Gehalt, Energie | ✅ Vorhanden |
| `staff_skills` | Skills des Personals | ✅ Vorhanden |
| `game_activities` | Aktivitätslog / Benachrichtigungen | ✅ Vorhanden |
| `research_state` | Freigeschaltete Technologien pro Hotel | ✅ Vorhanden (Basis) |
| `technologies` | Technologiebaum-Definitionen | ❌ Fehlt |
| `technology_unlocks` | Welche Raumtypen eine Technologie freischaltet | ❌ Fehlt |
| `research_log` | FP-Transaktionslog | ❌ Fehlt |

---

## Bestehende Tabellen

### `users`
| Feld | Typ | Beschreibung |
|---|---|---|
| `id` | int unsigned AI PK | |
| `username` | varchar(64) UNIQUE | |
| `password_hash` | varchar(255) | |
| `email` | varchar(128) | |
| `created_at` | timestamp | |

---

### `hotels`
| Feld | Typ | Beschreibung |
|---|---|---|
| `id` | int unsigned AI PK | |
| `user_id` | int unsigned FK→users | |
| `name` | varchar(64) | |
| `money` | decimal(15,2) | Startkapital: 20.000 |
| `reputation` | int | Ruf des Hotels (0–100) – *geplant, noch nicht implementiert* |
| `day_counter` | int | Aktueller Spieltag |
| `grid_size` | int | Größe des Grundrasters (Standard: 5) |
| `unlocked_plots` | JSON | Freigeschaltete Grundstücks-Plots |
| `level` | int | Hotel-Level (Start: 1) |
| `xp` | int | Aktuelle XP |
| `xp_needed` | int | XP bis nächstes Level |
| `game_time` | int | Aktuelle Spielzeit in Minuten (Start: 360 = 6:00 Uhr) |
| `entrance_direction` | enum('top','bottom','left','right') | Eingangsrichtung |
| `created_at` | timestamp | |
| `research_points` | int | **❌ Fehlt** – FP-Guthaben des Hotels |
| `research_unlocked` | tinyint(1) | **❌ Fehlt** – Flag: Forschungsbüro gebaut? |

---

### `rooms`
| Feld | Typ | Beschreibung |
|---|---|---|
| `id` | bigint unsigned AI PK | |
| `hotel_id` | int unsigned FK→hotels | |
| `room_type_id` | varchar(32) | Typ-Schlüssel (z.B. 'single', 'lobby') |
| `x_pos` | int | Position X auf dem Grid |
| `y_pos` | int | Position Y auf dem Grid |
| `floor` | int | Etage (Start: 1) |
| `rotation` | tinyint | Rotation des Raums |
| `condition` | tinyint | Zustand 0–100 – sinkt durch Nutzung, löst Service-Einsatz aus – *geplant, noch nicht implementiert* |
| `custom_name` | varchar(64) | Individueller Raumname |
| `room_number` | varchar(16) | Zimmernummer |
| `interior_data` | JSON | Inneneinrichtungsdaten |
| `door_rotation` | tinyint | Türrotation |
| `door_offset` | tinyint | Türversatz |

---

### `guests`
| Feld | Typ | Beschreibung |
|---|---|---|
| `id` | int AI PK | |
| `hotel_id` | int unsigned FK→hotels | |
| `room_id` | bigint unsigned FK→rooms (NULL=kein Zimmer) | |
| `name` | varchar(255) | |
| `guest_type` | varchar(50) | z.B. 'single', 'couple', 'family' |
| `status` | varchar(50) | 'waiting', 'checked_in', 'checked_out' |
| `arrived_at` | timestamp | |
| `checked_in_at` | timestamp | |
| `stay_duration` | int | Aufenthaltsdauer in Tagen |
| `budget` | int | Budget des Gastes |
| `satisfaction` | int | Zufriedenheit 0–100 |
| `checkin_day` | int | Spieltag des Check-ins |

---

### `managers`
| Feld | Typ | Beschreibung |
|---|---|---|
| `id` | int unsigned AI PK | |
| `hotel_id` | int unsigned FK→hotels UNIQUE | |
| `name` | varchar(64) | |
| `gender` | varchar(10) | |
| `appearance_skin` | varchar(32) | |
| `appearance_hair` | varchar(32) | |
| `appearance_outfit` | varchar(32) | Standard: 'suit_black' |
| `appearance_hat` | varchar(32) | nullable |

---

### `staff`
| Feld | Typ | Beschreibung |
|---|---|---|
| `id` | bigint unsigned AI PK | |
| `hotel_id` | int unsigned FK→hotels | |
| `name` | varchar(64) | |
| `role` | varchar(32) | z.B. 'receptionist', 'cleaner' |
| `salary` | decimal(10,2) | |
| `mood` | tinyint | 0–100 |
| `energy` | tinyint | 0–100 |
| `assigned_floor` | int | Zugewiesene Etage/Bereich – *Vorbereitung für ANG-20 Personalverwaltung* |
| `assigned_room_id` | bigint unsigned FK→rooms (nullable) | |

---

### `staff_skills`
| Feld | Typ | Beschreibung |
|---|---|---|
| `staff_id` | bigint unsigned FK→staff PK | |
| `skill_name` | varchar(32) PK | |
| `level` | int | Skill-Level (Start: 1) |
| `xp` | int | Skill-XP |

---

### `game_activities`
| Feld | Typ | Beschreibung |
|---|---|---|
| `id` | int AI PK | |
| `user_id` | int | |
| `hotel_id` | int | |
| `type` | varchar(50) | z.B. 'info', 'warning', 'success' |
| `message` | text | |
| `is_read` | tinyint(1) | Gelesen-Flag |
| `created_at` | timestamp | |

---

### `research_state` *(Basis vorhanden)*
| Feld | Typ | Beschreibung |
|---|---|---|
| `hotel_id` | int unsigned FK→hotels PK | |
| `tech_id` | varchar(64) PK | Technologie-Schlüssel (z.B. 'zimmer_1') |
| `unlocked_at` | timestamp | |

> ⚠️ Derzeit nur ein einfacher Key-Value-Store. Wird durch die neue `technologies`-Tabelle ergänzt – `tech_id` referenziert dann `technologies.key`.

---

## Fehlende Tabellen (neu anlegen)

### `technologies` ❌
Definiert alle Knoten im Technologiebaum.

```sql
CREATE TABLE `technologies` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `key` varchar(64) NOT NULL,
  `name_de` varchar(100) NOT NULL,
  `description_de` text DEFAULT NULL,
  `branch` enum('zimmer','gastronomie','wellness','management','prestige') NOT NULL,
  `branch_level` tinyint(4) NOT NULL COMMENT 'Stufe innerhalb des Astes (1-4)',
  `fp_cost` int(11) NOT NULL DEFAULT 100,
  `min_hotel_level` int(11) NOT NULL DEFAULT 1,
  `required_tech_id` int(11) DEFAULT NULL COMMENT 'Vorherige Technologie im Ast (FK)',
  `cross_required_tech_id` int(11) DEFAULT NULL COMMENT 'Quer-Abhängigkeit aus anderem Ast (FK)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `key` (`key`),
  KEY `required_tech_id` (`required_tech_id`),
  KEY `cross_required_tech_id` (`cross_required_tech_id`),
  CONSTRAINT `tech_ibfk_1` FOREIGN KEY (`required_tech_id`) REFERENCES `technologies` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tech_ibfk_2` FOREIGN KEY (`cross_required_tech_id`) REFERENCES `technologies` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

### `technology_unlocks` ❌
n:m – welche Raumtypen eine Technologie freischaltet.

```sql
CREATE TABLE `technology_unlocks` (
  `technology_id` int(11) NOT NULL,
  `room_type_key` varchar(32) NOT NULL,
  PRIMARY KEY (`technology_id`, `room_type_key`),
  CONSTRAINT `tu_ibfk_1` FOREIGN KEY (`technology_id`) REFERENCES `technologies` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

### `research_log` ❌
Protokolliert alle FP-Transaktionen.

```sql
CREATE TABLE `research_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `hotel_id` int(10) unsigned NOT NULL,
  `amount` int(11) NOT NULL COMMENT 'Positiv = gewonnen, Negativ = ausgegeben',
  `source` varchar(50) NOT NULL COMMENT 'z.B. passive, checkin, levelup, research',
  `tech_id` varchar(64) DEFAULT NULL COMMENT 'Nur bei source=research',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `hotel_id` (`hotel_id`),
  CONSTRAINT `rl_ibfk_1` FOREIGN KEY (`hotel_id`) REFERENCES `hotels` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

## Änderungen an bestehenden Tabellen

### `hotels` – zwei Felder ergänzen

```sql
ALTER TABLE `hotels`
  ADD COLUMN `research_points` int(11) NOT NULL DEFAULT 0 COMMENT 'Aktuelle Forschungspunkte',
  ADD COLUMN `research_unlocked` tinyint(1) NOT NULL DEFAULT 0 COMMENT '1 = Forschungsbüro gebaut, FP aktiv';
```

---

## Migrations-Reihenfolge

1. `ALTER TABLE hotels` – research_points + research_unlocked
2. `CREATE TABLE technologies` – Kern-Definitionen
3. `CREATE TABLE technology_unlocks` – Freischaltungs-Mapping
4. `CREATE TABLE research_log` – FP-Transaktionslog
5. Seed-Daten: `technologies` mit allen 5 Ästen befüllen
6. Seed-Daten: `technology_unlocks` mit Raumtyp-Mappings befüllen

---

*Dokument erstellt: März 2026 | HO·MA·SIM Entwicklungsdokumentation*
