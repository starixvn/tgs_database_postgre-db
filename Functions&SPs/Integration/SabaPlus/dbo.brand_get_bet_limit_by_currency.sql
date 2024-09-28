-- DROP FUNCTION brand_get_bet_limit_by_currency;

CREATE OR REPLACE FUNCTION dbo.brand_get_bet_limit_by_currency(brandid uuid, currencycode character varying)
 RETURNS TABLE("MinBet" integer, "MaxBet" integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT bl.min_bet AS MinBet,
        bl.max_bet AS MaxBet
    FROM dbo.brand_bet_limits as bbl
    INNER JOIN dbo.bet_limits as bl
        ON bbl.bet_limit_id = bl.id
    WHERE bl.currency_code = currencyCode
        AND bbl.brand_id = brandId;
END;
$function$