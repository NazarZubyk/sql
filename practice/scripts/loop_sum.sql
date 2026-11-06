DROP PROCEDURE IF EXISTS taxi.sumLoop;

DELIMITER $
CREATE PROCEDURE taxi.sumLoop(IN x INT UNSIGNED)
DETERMINISTIC
BEGIN
    DECLARE res BIGINT UNSIGNED DEFAULT 0;
    DECLARE curValue INT UNSIGNED DEFAULT 0;

    summation: LOOP
        SET curValue := curValue + 1;
        IF curValue > x THEN LEAVE summation; END IF;
        SET res := res + curValue;
    END LOOP;

    SELECT res;
END$
DELIMITER ;

CALL taxi.sumLoop(10);
