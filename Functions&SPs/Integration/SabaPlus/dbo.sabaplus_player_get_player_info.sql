-- DROP FUNCTION sabaplus_player_get_player_info;

CREATE OR REPLACE FUNCTION dbo.sabaplus_player_get_player_info(playercode character varying)
 RETURNS TABLE("PlayerCode" character varying, "Username" character varying, "CurrencyCode" character varying, "BrandId" uuid)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT p.player_code AS PlayerCode,
				p.username AS Username,
				p.default_wallet_currency_code AS CurrencyCode,
				p.brand_id AS BrandId
    FROM dbo.players as p
    WHERE p.player_code = playerCode;
END;
$function$