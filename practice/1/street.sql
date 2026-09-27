-- taxi.street definition

CREATE TABLE `street` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(140) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `geographicAreaID` int unsigned DEFAULT NULL,
  `drivable` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `street_geographicArea_FK` (`geographicAreaID`),
  CONSTRAINT `street_geographicArea_FK` FOREIGN KEY (`geographicAreaID`) REFERENCES `geographicArea` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='List of streets in a town';