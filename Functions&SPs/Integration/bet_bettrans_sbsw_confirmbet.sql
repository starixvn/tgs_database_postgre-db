-- PROCEDURE: dbo.bet_bettrans_sbsw_confirmbet(character varying, character varying, timestamp with time zone, timestamp with time zone, character varying, bigint, bigint, numeric, integer, numeric, boolean, numeric, numeric, timestamp with time zone, integer, integer)

-- DROP PROCEDURE IF EXISTS dbo.bet_bettrans_sbsw_confirmbet(character varying, character varying, timestamp with time zone, timestamp with time zone, character varying, bigint, bigint, numeric, integer, numeric, boolean, numeric, numeric, timestamp with time zone, integer, integer);

CREATE OR REPLACE PROCEDURE dbo.bet_bettrans_sbsw_confirmbet(
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
    IF NOT EXISTS (SELECT 1 FROM Bettrans_SBSW_Bet b WHERE b.SQ = bet_bettrans_sbsw_confirmbet.licenseeTxId AND b.refId = bet_bettrans_sbsw_confirmbet.refId)
	THEN 
		statuscode := '102';
		errmsg := 'No Data';
		RETURN;
	ELSE
		IF bet_bettrans_sbsw_confirmbet.action IN ('ConfirmBet', 'ConfirmBetParlay') THEN
			UPDATE dbo.Bettrans_SBSW_Bet
			SET
				action = bet_bettrans_sbsw_confirmbet.action,
				operationId = bet_bettrans_sbsw_confirmbet.operationId,
				updateTime = bet_bettrans_sbsw_confirmbet.updateTime,
				transactionTime = bet_bettrans_sbsw_confirmbet.transactionTime,
				txId = bet_bettrans_sbsw_confirmbet.txId,
				licenseeTxId = bet_bettrans_sbsw_confirmbet.licenseeTxId,
				odds = bet_bettrans_sbsw_confirmbet.odds,
				oddsType = bet_bettrans_sbsw_confirmbet.oddsType,
				actualAmount = bet_bettrans_sbsw_confirmbet.actualAmount,
				AdjustAmount = bet_bettrans_sbsw_confirmbet.creditAmount - bet_bettrans_sbsw_confirmbet.debitAmount,
				isOddsChanged = bet_bettrans_sbsw_confirmbet.isOddsChanged,
				winlostDate = bet_bettrans_sbsw_confirmbet.winlostDate
			WHERE Bettrans_SBSW_Bet.SQ = bet_bettrans_sbsw_confirmbet.licenseeTxId AND Bettrans_SBSW_Bet.refId = bet_bettrans_sbsw_confirmbet.refId;
		ELSE
			UPDATE dbo.Bettrans_SBSW_Bet
			SET
				action = bet_bettrans_sbsw_confirmbet.action,
				operationId = bet_bettrans_sbsw_confirmbet.operationId,
				updateTime = bet_bettrans_sbsw_confirmbet.updateTime,
				transactionTime = bet_bettrans_sbsw_confirmbet.transactionTime,
				txId = bet_bettrans_sbsw_confirmbet.txId,
				licenseeTxId = bet_bettrans_sbsw_confirmbet.licenseeTxId,
				AdjustAmount = bet_bettrans_sbsw_confirmbet.creditAmount - bet_bettrans_sbsw_confirmbet.debitAmount,
				winlostDate = bet_bettrans_sbsw_confirmbet.winlostDate
			WHERE Bettrans_SBSW_Bet.SQ = bet_bettrans_sbsw_confirmbet.licenseeTxId AND Bettrans_SBSW_Bet.refId = bet_bettrans_sbsw_confirmbet.refId;
		END IF;
	END IF;
END ; 
$BODY$;
ALTER PROCEDURE dbo.bet_bettrans_sbsw_confirmbet(character varying, character varying, timestamp with time zone, timestamp with time zone, character varying, bigint, bigint, numeric, integer, numeric, boolean, numeric, numeric, timestamp with time zone, integer, integer)
    OWNER TO postgres;
