-- DROP FUNCTION sabaplus_get_provider_code_by_game_type;

CREATE OR REPLACE FUNCTION dbo.sabaplus_get_provider_code_by_game_type(game_type text)
 RETURNS character varying
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    provider_code character varying;
BEGIN
    SELECT gp.code INTO provider_code
    FROM dbo.sub_game_providers as sgp
    INNER JOIN dbo.game_providers as gp
        ON sgp.game_provider_id = gp.id
    WHERE UPPER(sgp.code) = UPPER(game_type)
        AND gp.code LIKE 'SABAPLUS%';

    RETURN provider_code;
END;
$function$