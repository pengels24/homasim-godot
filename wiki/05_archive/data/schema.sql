-- Database Schema Draft for Homa
-- Dialect: MySQL / MariaDB

SET FOREIGN_KEY_CHECKS = 0;

-- 1. Core User Data
CREATE TABLE IF NOT EXISTS `users` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `username` VARCHAR(64) NOT NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL,
  `email` VARCHAR(128),
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 2. Savegoods / Hotels
-- Ein User kann mehrere Spielstände (Hotels) haben
CREATE TABLE IF NOT EXISTS `hotels` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL,
  `name` VARCHAR(64) NOT NULL,
  `money` DECIMAL(15, 2) DEFAULT 50000.00,
  `reputation` INT DEFAULT 0,
  `day_counter` INT DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 3. The Grid / Rooms
-- Speichert, was wo gebaut wurde.
CREATE TABLE IF NOT EXISTS `rooms` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `hotel_id` INT UNSIGNED NOT NULL,
  `room_type_id` VARCHAR(32) NOT NULL, -- Key from Config (e.g., 'bed_standard', 'kueche_small')
  `x_pos` INT NOT NULL,
  `y_pos` INT NOT NULL,
  `floor` INT DEFAULT 1,
  `rotation` TINYINT DEFAULT 0,
  `condition` TINYINT DEFAULT 100, -- Zustand 0-100%
  `custom_name` VARCHAR(64),
  FOREIGN KEY (`hotel_id`) REFERENCES `hotels`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 4. Staff (Mitarbeiter)
CREATE TABLE IF NOT EXISTS `staff` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `hotel_id` INT UNSIGNED NOT NULL,
  `name` VARCHAR(64) NOT NULL,
  `role` ENUM('cleaning', 'reception', 'kitchen', 'maintenance', 'service') NOT NULL,
  `salary` DECIMAL(10, 2) NOT NULL,
  `mood` TINYINT DEFAULT 100,
  `energy` TINYINT DEFAULT 100,
  -- Assignments (Macro Management)
  `assigned_floor` INT DEFAULT NULL, -- NULL = Überall einsetzbar
  `assigned_room_id` BIGINT UNSIGNED DEFAULT NULL, -- Spezielle Zuweisung (z.B. Rezeptionist an Desk)
  FOREIGN KEY (`hotel_id`) REFERENCES `hotels`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`assigned_room_id`) REFERENCES `rooms`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 5. Staff Skills
-- Da Skills sehr dynamisch sind, eigene Tabelle
CREATE TABLE IF NOT EXISTS `staff_skills` (
  `staff_id` BIGINT UNSIGNED NOT NULL,
  `skill_name` VARCHAR(32) NOT NULL, -- e.g., 'speed', 'charisma', 'cooking'
  `level` INT DEFAULT 1,
  `xp` INT DEFAULT 0,
  PRIMARY KEY (`staff_id`, `skill_name`),
  FOREIGN KEY (`staff_id`) REFERENCES `staff`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 6. Research / Unlocks
CREATE TABLE IF NOT EXISTS `research_state` (
  `hotel_id` INT UNSIGNED NOT NULL,
  `tech_id` VARCHAR(64) NOT NULL, -- Key from Config
  `unlocked_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`hotel_id`, `tech_id`),
  FOREIGN KEY (`hotel_id`) REFERENCES `hotels`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 7. Manager / Character
-- Der Avatar des Spielers in diesem Hotel
CREATE TABLE IF NOT EXISTS `managers` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `hotel_id` INT UNSIGNED NOT NULL UNIQUE, -- 1 Manager pro Hotel
  `name` VARCHAR(64) NOT NULL,
  `gender` ENUM('m', 'f', 'd') DEFAULT 'm',
  -- Appearance (JSON keys for customizer)
  `appearance_skin` VARCHAR(32) DEFAULT 'default',
  `appearance_hair` VARCHAR(32) DEFAULT 'default',
  `appearance_outfit` VARCHAR(32) DEFAULT 'suit_black',
  `appearance_hat` VARCHAR(32) DEFAULT NULL, -- "green_hat"
  FOREIGN KEY (`hotel_id`) REFERENCES `hotels`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;
