-- taxi.passenger definition

CREATE TABLE `passenger` (
  `client` int unsigned NOT NULL,
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`),
  KEY `passenger_client_FK` (`client`),
  CONSTRAINT `passenger_client_FK` FOREIGN KEY (`client`) REFERENCES `client` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;