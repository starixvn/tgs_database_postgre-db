-- FUNCTION: dbo.game_provider_get_provider_id_by_code(character varying)

-- DROP FUNCTION IF EXISTS dbo.game_provider_get_provider_id_by_code(character varying);

CREATE OR REPLACE FUNCTION dbo.game_provider_get_provider_id_by_code(
	provider_code character varying)
    RETURNS uuid
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    game_provider_id uuid;
BEGIN
    SELECT ga.id INTO game_provider_id
    FROM dbo.game_providers ga
    WHERE ga.code = $1;

    RETURN game_provider_id;
END;
$BODY$;

ALTER FUNCTION dbo.game_provider_get_provider_id_by_code(character varying)
    OWNER TO tgs_migration;

GRANT EXECUTE ON FUNCTION dbo.game_provider_get_provider_id_by_code(character varying) TO PUBLIC;

GRANT EXECUTE ON FUNCTION dbo.game_provider_get_provider_id_by_code(character varying) TO tgs_app;

GRANT EXECUTE ON FUNCTION dbo.game_provider_get_provider_id_by_code(character varying) TO tgs_migration;

