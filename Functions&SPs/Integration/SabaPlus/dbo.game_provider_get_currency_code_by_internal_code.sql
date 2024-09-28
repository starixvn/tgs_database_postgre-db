-- DROP FUNCTION game_provider_get_currency_code_by_internal_code;

CREATE OR REPLACE FUNCTION dbo.game_provider_get_currency_code_by_internal_code(game_provider_code character varying, internal_code character varying)
 RETURNS character varying
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    currency_code character varying;
BEGIN
    SELECT gpc.game_provider_currency_code INTO currency_code
    FROM dbo.game_provider_currencies as gpc
    INNER JOIN dbo.game_providers as gp 
        ON gp.id = gpc.game_provider_id
    WHERE gpc.currency_code = internal_code AND gp.code = game_provider_code;

    RETURN currency_code;
END;
$function$