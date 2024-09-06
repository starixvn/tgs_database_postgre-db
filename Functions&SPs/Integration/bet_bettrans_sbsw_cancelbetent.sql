-- PROCEDURE: dbo.bet_bettrans_sbsw_cancelbetent(character varying, character varying, timestamp without time zone, character varying, numeric, numeric, bigint, integer, integer)

-- DROP PROCEDURE IF EXISTS dbo.bet_bettrans_sbsw_cancelbetent(character varying, character varying, timestamp without time zone, character varying, numeric, numeric, bigint, integer, integer);

CREATE OR REPLACE PROCEDURE dbo.bet_bettrans_sbsw_cancelbetent(
	IN action character varying,
	IN operationid character varying,
	IN updatetime timestamp without time zone,
	IN refid character varying,
	IN creditamount numeric,
	IN debitamount numeric,
	IN txid bigint,
	INOUT sporttype integer DEFAULT NULL::integer,
	INOUT spresult integer DEFAULT 0)
LANGUAGE 'plpgsql'
AS $BODY$
	DECLARE _TicketType INT:= null;
	_sq bigint:= null;
BEGIN 
        SELECT SBSW.sportType, SBSW.TicketType, SBSW.SQ
        INTO bet_bettrans_sbsw_cancelbetent.SportType, _TicketType, _sq
        FROM dbo.Bettrans_SBSW_Bet AS SBSW WHERE SBSW.refId = bet_bettrans_sbsw_cancelbetent.refId
        ORDER BY SQ DESC 
        LIMIT 1;
        
        IF _TicketType IS NULL THEN --查無此交易
            SELECT -1 INTO SPResult;
            RETURN;
        END IF;
        
        IF _TicketType = 3 THEN --CancelBet
            SELECT -2 INTO SPResult;
            RETURN;
        END IF;
        
        IF _TicketType = 2 THEN --ConfirmBet
            SELECT -3 INTO SPResult;
            RETURN;
        END IF;
        
        
        UPDATE dbo.Bettrans_SBSW_Bet
        SET
            action = bet_bettrans_sbsw_cancelbetent.action,
            operationId = bet_bettrans_sbsw_cancelbetent.operationId,
            updateTime = bet_bettrans_sbsw_cancelbetent.updateTime,
            debitAmount = bet_bettrans_sbsw_cancelbetent.debitAmount,
            creditAmount = bet_bettrans_sbsw_cancelbetent.creditAmount,
            TicketType = _TicketType,
            txId = bet_bettrans_sbsw_cancelbetent.txId
        WHERE SQ = _sq;
            
        GET DIAGNOSTICS SPResult = ROW_COUNT;
END ;
$BODY$;
ALTER PROCEDURE dbo.bet_bettrans_sbsw_cancelbetent(character varying, character varying, timestamp without time zone, character varying, numeric, numeric, bigint, integer, integer)
    OWNER TO postgres;
