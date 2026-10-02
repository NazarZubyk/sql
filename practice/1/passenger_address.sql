-- taxi.passenger_address definition

CREATE TABLE taxi.passenger_address (
	id INT UNSIGNED auto_increment NOT NULL,
	passenger_id INT UNSIGNED NULL,
	house_id INT UNSIGNED NOT NULL,
	CONSTRAINT passenger_address_pk PRIMARY KEY (id),
	CONSTRAINT passenger_address_house_FK FOREIGN KEY (house_id) REFERENCES taxi.house(id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT passenger_address_passenger_FK FOREIGN KEY (passenger_id) REFERENCES taxi.passenger(id) ON DELETE CASCADE ON UPDATE CASCADE
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;