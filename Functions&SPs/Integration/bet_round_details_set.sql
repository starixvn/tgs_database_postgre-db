-- PROCEDURE: bet.bet_round_details_set(uuid, text)

-- DROP PROCEDURE IF EXISTS bet.bet_round_details_set(uuid, text);

CREATE OR REPLACE PROCEDURE bet.bet_round_details_set(
	IN p_id uuid,
	IN p_data text)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    -- Try to update the existing row
    UPDATE bet.round_details
    SET additional_data = p_data
    WHERE round_id = p_id;

    -- If no rows were updated, insert a new row
    IF NOT FOUND THEN
        INSERT INTO bet.round_details (round_id, additional_data)
        VALUES (p_id, p_data);
    END IF;
END;
$BODY$;
ALTER PROCEDURE bet.bet_round_details_set(uuid, text)
    OWNER TO postgres;
