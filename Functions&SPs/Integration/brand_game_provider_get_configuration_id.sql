-- FUNCTION: dbo.brand_game_provider_get_configuration_id(uuid, uuid)

-- DROP FUNCTION IF EXISTS dbo.brand_game_provider_get_configuration_id(uuid, uuid);

CREATE OR REPLACE FUNCTION dbo.brand_game_provider_get_configuration_id(
    game_provider_id uuid,
    brand_id uuid)
    RETURNS uuid
    LANGUAGE plpgsql
    COST 100
    VOLATILE 
    PARALLEL UNSAFE

AS $BODY$
DECLARE
    config_id uuid;
BEGIN
    SELECT bgp.game_provider_configuration_id INTO config_id
    FROM dbo.brand_game_providers AS bgp
    WHERE bgp.game_provider_id = $1
      AND bgp.brand_id = $2;

    RETURN config_id;
END;
$BODY$;

ALTER FUNCTION dbo.brand_game_provider_get_configuration_id(uuid, uuid)
    OWNER TO tgs_migration;

GRANT EXECUTE ON FUNCTION dbo.brand_game_provider_get_configuration_id(uuid, uuid) TO PUBLIC;

GRANT EXECUTE ON FUNCTION dbo.brand_game_provider_get_configuration_id(uuid, uuid) TO tgs_app;

GRANT EXECUTE ON FUNCTION dbo.brand_game_provider_get_configuration_id(uuid, uuid) TO tgs_migration;