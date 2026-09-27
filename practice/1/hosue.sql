-- taxi.hosue definition

CREATE TABLE `hosue` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `streetID` int unsigned DEFAULT NULL,
  `address` varchar(100) DEFAULT NULL,
  `longitude` decimal(9,6) DEFAULT NULL,
  `latitude` decimal(9,6) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `hosue_street_FK` (`streetID`),
  CONSTRAINT `hosue_street_FK` FOREIGN KEY (`streetID`) REFERENCES `street` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='information about the address of a house';