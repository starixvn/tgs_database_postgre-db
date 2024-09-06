-- PROCEDURE: dbo.bet_bettrans_sbsw_confirmbet(character varying, character varying, timestamp with time zone, timestamp with time zone, character varying, bigint, bigint, numeric, integer, numeric, boolean, numeric, numeric, timestamp with time zone, integer, integer)

-- DROP PROCEDURE IF EXISTS dbo.bet_bettrans_sbsw_confirmbet(character varying, character varying, timestamp with time zone, timestamp with time zone, character varying, bigint, bigint, numeric, integer, numeric, boolean, numeric, numeric, timestamp with time zone, integer, integer);

CREATE OR REPLACE PROCEDURE dbo.bet_bettrans_sbsw_confirmbet(
	IN action character varying,
	IN operationid character varying,
	IN updatetime timestamp with time zone,
	IN transactiontime timestamp with time zone,
	IN refid character varying,
	IN txid bigint,
	IN licenseetxid bigint,
	IN odds numeric,
	IN oddstype integer,
	IN actualamount numeric,
	IN isoddschanged boolean,
	IN creditamount numeric,
	IN debitamount numeric,
	IN winlostdate timestamp with time zone,
	INOUT sporttype integer DEFAULT NULL::integer,
	INOUT spresult integer DEFAULT 0)
LANGUAGE 'plpgsql'
AS $BODY$
 
	DECLARE _TicketType INT:= null;
BEGIN    
        SELECT SBSW.sportType, SBSW.TicketType
        INTO bet_bettrans_sbsw_confirmbet.SportType, _TicketType 
        FROM dbo.Bettrans_SBSW_Bet AS SBSW 
		WHERE SBSW.SQ = bet_bettrans_sbsw_confirmbet.licenseeTxId AND SBSW.refId = bet_bettrans_sbsw_confirmbet.refId;
        
        /*IF _TicketType IS NULL THEN --查無此交易
            SELECT -1 INTO SPResult;
            RETURN;
        END IF;
        
        IF (_TicketType = 2 OR _TicketType = 8 OR _TicketType = 10) THEN --Confirm完成
            SELECT -2 AS SPResult;
            RETURN;
        END IF;
        
        IF _TicketType = 3 THEN --CancelBet
            SELECT -3 INTO SPResult;
            RETURN;
        END IF; */
        
        IF _TicketType = 1 THEN --ConfirmBet  
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
                winlostDate = bet_bettrans_sbsw_confirmbet.winlostDate,
                TicketType = _TicketType
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
                winlostDate = bet_bettrans_sbsw_confirmbet.winlostDate,
                TicketType = _TicketType
            WHERE Bettrans_SBSW_Bet.SQ = bet_bettrans_sbsw_confirmbet.licenseeTxId AND Bettrans_SBSW_Bet.refId = bet_bettrans_sbsw_confirmbet.refId;
        END IF;         
        GET DIAGNOSTICS SPResult = ROW_COUNT;
END ; 
$BODY$;
ALTER PROCEDURE dbo.bet_bettrans_sbsw_confirmbet(character varying, character varying, timestamp with time zone, timestamp with time zone, character varying, bigint, bigint, numeric, integer, numeric, boolean, numeric, numeric, timestamp with time zone, integer, integer)
    OWNER TO postgres;
