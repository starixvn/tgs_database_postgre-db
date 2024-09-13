-- PROCEDURE: dbo.bet_bettrans_sbsw_settle_sabasw(character varying, character varying, character varying, character varying, bigint, timestamp with time zone, timestamp with time zone, character varying, numeric, numeric, numeric, character varying, integer, integer, integer)

-- DROP PROCEDURE IF EXISTS dbo.bet_bettrans_sbsw_settle_sabasw(character varying, character varying, character varying, character varying, bigint, timestamp with time zone, timestamp with time zone, character varying, numeric, numeric, numeric, character varying, integer, integer, integer);

CREATE OR REPLACE PROCEDURE dbo.bet_bettrans_sbsw_settle_sabasw(
	IN action character varying DEFAULT NULL::character varying,
	IN operationid character varying DEFAULT NULL::character varying,
	IN userid character varying DEFAULT NULL::character varying,
	IN refid character varying DEFAULT NULL::character varying,
	IN txid bigint DEFAULT NULL::bigint,
	IN updatetime timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN winlostdate timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN status character varying DEFAULT NULL::character varying,
	IN payout numeric DEFAULT NULL::numeric,
	IN creditamount numeric DEFAULT NULL::numeric,
	IN debitamount numeric DEFAULT NULL::numeric,
	IN extrastatus character varying DEFAULT NULL::character varying,
	IN isonlywinlostdatechanged boolean default null,
	INOUT StatusCode character varying DEFAULT '0',
	INOUT ErrMsg text DEFAULT '')
LANGUAGE 'plpgsql'
AS $BODY$
	DECLARE _sq BIGINT;
			_rc BIGINT;
BEGIN
	IF action != 'SettleEnt' THEN 
		SELECT null INTO _sq;
		SELECT SBSW.SQ
		INTO _sq
		FROM dbo.Bettrans_SBSW_Settle AS SBSW 
		WHERE  SBSW.refId = bet_bettrans_sbsw_settle_sabasw.refId AND SBSW.operationId = bet_bettrans_sbsw_settle_sabasw.operationId;
	
		IF _sq IS NOT NULL THEN --已完成此交易
			StatusCode := '101';
			ErrMsg := 'Duplicate Transaction';
			RETURN;
		END IF;
	END IF;

	INSERT INTO dbo.Bettrans_SBSW_Settle
	(
		action,
		operationId,
		userId,
		refId,
		txId,
		updateTime,
		winlostDate,
		status,
		payout,
		creditAmount,
		debitAmount,
		extraStatus,
		isonlywinlostdatechanged
	)
	VALUES
	(
		action,
		operationId,
		userId,
		refId,
		txId,
		updateTime,
		winlostDate,
		status,
		payout,
		creditAmount,
		debitAmount,
		extraStatus,
		isonlywinlostdatechanged
	);
END ;
$BODY$;