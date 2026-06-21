/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

CREATE TABLE IF NOT EXISTS `game_activities` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `hotel_id` int(11) NOT NULL,
  `type` varchar(50) DEFAULT 'info',
  `message` text NOT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `guests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `hotel_id` int(10) unsigned NOT NULL,
  `room_id` bigint(20) unsigned DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `guest_type` varchar(50) DEFAULT 'single',
  `status` varchar(50) DEFAULT 'waiting',
  `arrived_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `checked_in_at` timestamp NULL DEFAULT NULL,
  `stay_duration` int(11) DEFAULT 1,
  `budget` int(11) DEFAULT 0,
  `satisfaction` int(11) DEFAULT 100,
  `checkin_day` int(11) DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `hotel_id` (`hotel_id`),
  KEY `room_id` (`room_id`),
  CONSTRAINT `guests_ibfk_1` FOREIGN KEY (`hotel_id`) REFERENCES `hotels` (`id`) ON DELETE CASCADE,
  CONSTRAINT `guests_ibfk_2` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=77 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `hotels` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `name` varchar(64) NOT NULL,
  `money` decimal(15,2) DEFAULT 20000.00,
  `reputation` int(11) DEFAULT 0,
  `day_counter` int(11) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `grid_size` int(11) DEFAULT 5,
  `unlocked_plots` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT '[]' CHECK (json_valid(`unlocked_plots`)),
  `level` int(11) DEFAULT 1,
  `xp` int(11) DEFAULT 0,
  `xp_needed` int(11) DEFAULT 100,
  `game_time` int(11) NOT NULL DEFAULT 360,
  `entrance_direction` enum('top','bottom','left','right') NOT NULL DEFAULT 'bottom',
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `hotels_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `managers` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `hotel_id` int(10) unsigned NOT NULL,
  `name` varchar(64) NOT NULL,
  `gender` varchar(10) DEFAULT 'm',
  `appearance_skin` varchar(32) DEFAULT 'default',
  `appearance_hair` varchar(32) DEFAULT 'default',
  `appearance_outfit` varchar(32) DEFAULT 'suit_black',
  `appearance_hat` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `hotel_id` (`hotel_id`),
  CONSTRAINT `managers_ibfk_1` FOREIGN KEY (`hotel_id`) REFERENCES `hotels` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `research_state` (
  `hotel_id` int(10) unsigned NOT NULL,
  `tech_id` varchar(64) NOT NULL,
  `unlocked_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`hotel_id`,`tech_id`),
  CONSTRAINT `research_state_ibfk_1` FOREIGN KEY (`hotel_id`) REFERENCES `hotels` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `rooms` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `hotel_id` int(10) unsigned NOT NULL,
  `room_type_id` varchar(32) NOT NULL,
  `x_pos` int(11) NOT NULL,
  `y_pos` int(11) NOT NULL,
  `floor` int(11) DEFAULT 1,
  `rotation` tinyint(4) DEFAULT 0,
  `condition` tinyint(4) DEFAULT 100,
  `custom_name` varchar(64) DEFAULT NULL,
  `room_number` varchar(16) DEFAULT NULL,
  `interior_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`interior_data`)),
  `door_rotation` tinyint(4) DEFAULT 0,
  `door_offset` tinyint(4) DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `hotel_id` (`hotel_id`),
  CONSTRAINT `rooms_ibfk_1` FOREIGN KEY (`hotel_id`) REFERENCES `hotels` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=137 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `staff` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `hotel_id` int(10) unsigned NOT NULL,
  `name` varchar(64) NOT NULL,
  `role` varchar(32) NOT NULL,
  `salary` decimal(10,2) NOT NULL,
  `mood` tinyint(4) DEFAULT 100,
  `energy` tinyint(4) DEFAULT 100,
  `assigned_floor` int(11) DEFAULT NULL,
  `assigned_room_id` bigint(20) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `hotel_id` (`hotel_id`),
  KEY `assigned_room_id` (`assigned_room_id`),
  CONSTRAINT `staff_ibfk_1` FOREIGN KEY (`hotel_id`) REFERENCES `hotels` (`id`) ON DELETE CASCADE,
  CONSTRAINT `staff_ibfk_2` FOREIGN KEY (`assigned_room_id`) REFERENCES `rooms` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `staff_skills` (
  `staff_id` bigint(20) unsigned NOT NULL,
  `skill_name` varchar(32) NOT NULL,
  `level` int(11) DEFAULT 1,
  `xp` int(11) DEFAULT 0,
  PRIMARY KEY (`staff_id`,`skill_name`),
  CONSTRAINT `staff_skills_ibfk_1` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `users` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `email` varchar(128) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
