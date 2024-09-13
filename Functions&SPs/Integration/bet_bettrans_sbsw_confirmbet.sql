-- PROCEDURE: dbo.bet_bettrans_sbsw_confirmbet_sabasw(character varying, character varying, timestamp with time zone, timestamp with time zone, character varying, bigint, bigint, numeric, integer, numeric, boolean, numeric, numeric, timestamp with time zone, integer, integer)

-- DROP PROCEDURE IF EXISTS dbo.bet_bettrans_sbsw_confirmbet_sabasw(character varying, character varying, timestamp with time zone, timestamp with time zone, character varying, bigint, bigint, numeric, integer, numeric, boolean, numeric, numeric, timestamp with time zone, integer, integer);

CREATE OR REPLACE PROCEDURE dbo.bet_bettrans_sbsw_confirmbet_sabasw(
	IN action character varying DEFAULT NULL,
	IN operationid character varying DEFAULT NULL,
	IN updatetime timestamp with time zone DEFAULT NULL,
	IN transactiontime timestamp with time zone DEFAULT NULL,
	IN refid character varying DEFAULT NULL,
	IN txid bigint DEFAULT NULL,
	IN licenseetxid bigint DEFAULT NULL,
	IN odds numeric DEFAULT NULL,
	IN oddstype integer DEFAULT NULL,
	IN actualamount numeric DEFAULT NULL,
	IN isoddschanged boolean DEFAULT NULL,
	IN creditamount numeric DEFAULT NULL,
	IN debitamount numeric DEFAULT NULL,
	IN winlostdate timestamp with time zone DEFAULT NULL,
	INOUT statuscode character varying DEFAULT '0',
	INOUT errmsg TEXT DEFAULT ''
	)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN    
    IF NOT EXISTS (SELECT 1 FROM dbo.Bettrans_SBSW_Bet b WHERE b.SQ = bet_bettrans_sbsw_confirmbet_sabasw.licenseeTxId AND b.refId = bet_bettrans_sbsw_confirmbet_sabasw.refId)
	THEN 
		statuscode := '102';
		errmsg := 'No Data';
		RETURN;
	ELSE
		IF bet_bettrans_sbsw_confirmbet_sabasw.action IN ('ConfirmBet', 'ConfirmBetParlay') THEN
			UPDATE dbo.Bettrans_SBSW_Bet
			SET
				action = bet_bettrans_sbsw_confirmbet_sabasw.action,
				operationId = bet_bettrans_sbsw_confirmbet_sabasw.operationId,
				updateTime = bet_bettrans_sbsw_confirmbet_sabasw.updateTime,
				transactionTime = bet_bettrans_sbsw_confirmbet_sabasw.transactionTime,
				txId = bet_bettrans_sbsw_confirmbet_sabasw.txId,
				licenseeTxId = bet_bettrans_sbsw_confirmbet_sabasw.licenseeTxId,
				odds = bet_bettrans_sbsw_confirmbet_sabasw.odds,
				oddsType = bet_bettrans_sbsw_confirmbet_sabasw.oddsType,
				actualAmount = bet_bettrans_sbsw_confirmbet_sabasw.actualAmount,
				AdjustAmount = bet_bettrans_sbsw_confirmbet_sabasw.creditAmount - bet_bettrans_sbsw_confirmbet_sabasw.debitAmount,
				isOddsChanged = bet_bettrans_sbsw_confirmbet_sabasw.isOddsChanged,
				winlostDate = bet_bettrans_sbsw_confirmbet_sabasw.winlostDate
			WHERE Bettrans_SBSW_Bet.SQ = bet_bettrans_sbsw_confirmbet_sabasw.licenseeTxId AND Bettrans_SBSW_Bet.refId = bet_bettrans_sbsw_confirmbet_sabasw.refId;
		ELSE
			UPDATE dbo.Bettrans_SBSW_Bet
			SET
				action = bet_bettrans_sbsw_confirmbet_sabasw.action,
				operationId = bet_bettrans_sbsw_confirmbet_sabasw.operationId,
				updateTime = bet_bettrans_sbsw_confirmbet_sabasw.updateTime,
				transactionTime = bet_bettrans_sbsw_confirmbet_sabasw.transactionTime,
				txId = bet_bettrans_sbsw_confirmbet_sabasw.txId,
				licenseeTxId = bet_bettrans_sbsw_confirmbet_sabasw.licenseeTxId,
				AdjustAmount = bet_bettrans_sbsw_confirmbet_sabasw.creditAmount - bet_bettrans_sbsw_confirmbet_sabasw.debitAmount,
				winlostDate = bet_bettrans_sbsw_confirmbet_sabasw.winlostDate
			WHERE Bettrans_SBSW_Bet.SQ = bet_bettrans_sbsw_confirmbet_sabasw.licenseeTxId AND Bettrans_SBSW_Bet.refId = bet_bettrans_sbsw_confirmbet_sabasw.refId;
		END IF;
	END IF;
END ; 
$BODY$;
ALTER PROCEDURE dbo.bet_bettrans_sbsw_confirmbet_sabasw(character varying, character varying, timestamp with time zone, timestamp with time zone, character varying, bigint, bigint, numeric, integer, numeric, boolean, numeric, numeric, timestamp with time zone, integer, integer)
    OWNER TO postgres;
