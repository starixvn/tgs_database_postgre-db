CREATE OR REPLACE PROCEDURE dbo.bet_bettrans_sbsw_cancelbet(
	IN action character varying,
	IN operationid character varying,
	IN updatetime timestamp with time zone,
	IN refid character varying,
	IN creditamount numeric,
	IN debitamount numeric,
	INOUT spresult integer DEFAULT 0,
	INOUT sporttype integer DEFAULT NULL::integer)
LANGUAGE 'plpgsql'
AS $BODY$
	DECLARE _TicketType INT:= null;
	_sq bigint:= null;
BEGIN    
        SELECT SBSW.sportType, SBSW.TicketType, SBSW.SQ
        INTO bet_bettrans_sbsw_cancelbet.SportType, _TicketType, _sq
        FROM dbo.Bettrans_SBSW_Bet AS SBSW WHERE SBSW.refId = bet_bettrans_sbsw_cancelbet.refId
        ORDER BY SQ DESC 
        LIMIT 1;
        
        /*IF _TicketType IS NULL THEN --查無此交易
            SELECT -1 INTO SPResult;
            RETURN;
        END IF;
        
        IF _TicketType = 3 THEN --CancelBet
            SELECT -2 INTO SPResult;
            RETURN;
        END IF;
        
        IF _TicketType = 2 THEN --ConfirmBet
            SELECT -3 AS SPResult;
            RETURN;
        END IF;*/
        
        UPDATE dbo.Bettrans_SBSW_Bet
        SET
            action = bet_bettrans_sbsw_cancelbet.action,
           operationId = bet_bettrans_sbsw_cancelbet.operationId,
            updateTime = bet_bettrans_sbsw_cancelbet.updateTime,
            debitAmount = bet_bettrans_sbsw_cancelbet.debitAmount,
            creditAmount = bet_bettrans_sbsw_cancelbet.creditAmount,
            TicketType = _TicketType
        WHERE SQ = _sq;
          
        GET DIAGNOSTICS SPResult = ROW_COUNT;
END ;
$BODY$;