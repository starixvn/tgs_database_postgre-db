-- FUNCTION: dbo.player_get_player_info_by_player_code(character varying)
-- DROP FUNCTION IF EXISTS dbo.player_get_player_info_by_player_code(character varying);

CREATE OR REPLACE FUNCTION dbo.player_get_player_info_by_player_code(
	player_code character varying)
    RETURNS TABLE(
        "PlayerResellerId" uuid, 
        "PlayerResellerCode" character varying, 
        "PlayerLicenseeId" uuid, 
        "PlayerLicenseeCode" character varying, 
        "PlayerBrandId" uuid, 
        "PlayerBrandCode" character varying, 
        "PlayerCode" character varying, 
        "PlayerUsername" character varying, 
        "PlayerWalletId" uuid, 
        "PlayerCurrencyCode" character varying
    ) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1

AS $BODY$
BEGIN
	RETURN QUERY		
	SELECT
		r.id AS "PlayerResellerId",
		r.code AS "PlayerResellerCode",
		l.id AS "PlayerLicenseeId",
		l.code AS "PlayerLicenseeCode",
		b.id AS "PlayerBrandId",
		b.code AS "PlayerBrandCode",
		p.player_code AS "PlayerCode",
		p.username AS "PlayerUsername",
		p.default_wallet_id AS "PlayerWalletId",
		p.default_wallet_currency_code AS "PlayerCurrencyCode"
	FROM dbo.players p
	INNER JOIN dbo.brands b ON p.brand_id = b.id
	INNER JOIN dbo.licensees l ON b.licensee_id = l.id
	INNER JOIN dbo.resellers r ON l.reseller_id = r.id
	WHERE p.player_code = $1;

END;
$BODY$;

ALTER FUNCTION dbo.player_get_player_info_by_player_code(character varying)
    OWNER TO tgs_migration;

GRANT EXECUTE ON FUNCTION dbo.player_get_player_info_by_player_code(character varying) TO PUBLIC;

GRANT EXECUTE ON FUNCTION dbo.player_get_player_info_by_player_code(character varying) TO tgs_app;

GRANT EXECUTE ON FUNCTION dbo.player_get_player_info_by_player_code(character varying) TO tgs_migration;

