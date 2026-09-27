-- taxi.geographicArea definition

CREATE TABLE `geographicArea` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(150) DEFAULT NULL,
  `geographicAreaTypeID` int unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `geographicArea_geographicAreaType_FK` (`geographicAreaTypeID`),
  CONSTRAINT `geographicArea_geographicAreaType_FK` FOREIGN KEY (`geographicAreaTypeID`) REFERENCES `geographicAreaType` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Represents a geographic area used to divide locations, such as a village, town, city, or district within a larger city.';