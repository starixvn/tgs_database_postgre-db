CREATE OR REPLACE PROCEDURE dbo.bet_bettrans_sbsw_cancelbet_sabasw(
	IN action character varying,
	IN operationid character varying,
	IN updatetime timestamp with time zone,
	IN refid character varying,
	IN creditamount numeric,
	IN debitamount numeric,
	INOUT statuscode character varying DEFAULT '0',
	INOUT errmsg text default '')
LANGUAGE 'plpgsql'
AS $BODY$
	DECLARE _sq bigint:= null;
BEGIN   
	IF NOT EXISTS (SELECT 1 FROM dbo.Bettrans_SBSW_Bet b WHERE b.refId = bet_bettrans_sbsw_cancelbet_sabasw.refId)
	THEN 
		statuscode := '102';
		errmsg := 'No Data';
		RETURN;
	ELSE	
		SELECT SBSW.SQ
		INTO _sq
		FROM dbo.Bettrans_SBSW_Bet AS SBSW WHERE SBSW.refId = bet_bettrans_sbsw_cancelbet_sabasw.refId
		ORDER BY SQ DESC 
		LIMIT 1;
		
		UPDATE dbo.Bettrans_SBSW_Bet
		SET
			action = bet_bettrans_sbsw_cancelbet_sabasw.action,
			operationId = bet_bettrans_sbsw_cancelbet_sabasw.operationId,
			updateTime = bet_bettrans_sbsw_cancelbet_sabasw.updateTime,
			AdjustAmount = bet_bettrans_sbsw_cancelbet_sabasw.creditAmount - bet_bettrans_sbsw_cancelbet_sabasw.debitAmount
		WHERE SQ = _sq;
	END IF;
END ;
$BODY$;