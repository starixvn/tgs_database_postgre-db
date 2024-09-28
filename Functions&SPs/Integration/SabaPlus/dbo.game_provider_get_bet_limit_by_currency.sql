-- DROP FUNCTION game_provider_get_bet_limit_by_currency;

CREATE OR REPLACE FUNCTION dbo.game_provider_get_bet_limit_by_currency(gameprovidercode character varying, currencycode character varying)
 RETURNS TABLE("MinBet" integer, "MaxBet" integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        gpbl.min_bet AS MinBet,
        gpbl.max_bet AS MaxBet
    FROM dbo.game_provider_bet_limits as gpbl
    INNER JOIN dbo.game_providers as gp
        ON gp.id = gpbl.game_provider_id
    WHERE gpbl.currency_code = currencyCode
        AND gp.code = gameProviderCode;
END;
$function$