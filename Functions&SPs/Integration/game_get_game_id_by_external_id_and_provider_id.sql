 --FUNCTION: dbo.game_get_game_id_by_external_id_and_provider_id(character varying, uuid)

 --DROP FUNCTION IF EXISTS dbo.game_get_game_id_by_external_id_and_provider_id(character varying, uuid);

CREATE OR REPLACE FUNCTION dbo.game_get_game_id_by_external_id_and_provider_id(
    external_id character varying,
    game_provider_id uuid)
	RETURNS int
    LANGUAGE plpgsql
    COST 100
    VOLATILE 
    PARALLEL UNSAFE
AS $BODY$
DECLARE GameId int;
BEGIN
    SELECT
        g.id INTO GameId
    FROM
        dbo.games as g
    WHERE
        g.external_id = $1
        AND g.game_provider_id = $2
		order by g.external_id desc
		limit 1;
    RETURN GameId;
END;
$BODY$;

ALTER FUNCTION dbo.game_get_game_id_by_external_id_and_provider_id(character varying, uuid)
    OWNER TO tgs_migration;

GRANT EXECUTE ON FUNCTION dbo.game_get_game_id_by_external_id_and_provider_id(character varying, uuid) TO PUBLIC;

GRANT EXECUTE ON FUNCTION dbo.game_get_game_id_by_external_id_and_provider_id(character varying, uuid) TO tgs_app;

GRANT EXECUTE ON FUNCTION dbo.game_get_game_id_by_external_id_and_provider_id(character varying, uuid) TO tgs_migration;
